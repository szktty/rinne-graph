import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';
import 'package:rinne_graph/src/cli/import/json_importer.dart';

/// CSVファイルからのデータインポート機能
class CsvImporter {
  CsvImporter(this.config);

  final CliConfig config;

  /// CSVファイルからグラフデータをインポート
  Future<ImportResult> importFromFiles(
    Graph graph, {
    required String nodesFile,
    required String edgesFile,
    String? configFile,
    bool append = false,
    bool validate = true,
    String onError = 'warn',
    String encoding = 'utf-8',
    bool dryRun = false,
  }) async {
    final result = ImportResult();

    try {
      // 設定ファイルの読み込み
      CsvImportConfig? importConfig;
      if (configFile != null) {
        config.logVerbose('設定ファイルを読み込み中: $configFile');
        importConfig = await _loadConfig(configFile, encoding);
      }

      // 既存データのクリア（appendでない場合）
      if (!append && !dryRun) {
        config.logVerbose('既存データをクリア中...');
        await _clearExistingData(graph);
      }

      // ノードのインポート
      config.logVerbose('ノードCSVを読み込み中: $nodesFile');
      await _importNodes(
        graph,
        nodesFile,
        result,
        importConfig,
        encoding,
        onError,
        dryRun,
      );

      // エッジのインポート
      config.logVerbose('エッジCSVを読み込み中: $edgesFile');
      await _importEdges(
        graph,
        edgesFile,
        result,
        importConfig,
        encoding,
        onError,
        dryRun,
      );

      result.success = true;
      config.log('CSVインポートが完了しました');
      config.log('  ノード: ${result.importedNodes}件');
      config.log('  エッジ: ${result.importedEdges}件');
      if (result.errors.isNotEmpty) {
        config.logWarning('  エラー: ${result.errors.length}件');
      }
    } catch (e) {
      result.success = false;
      result.addError('全体', e.toString());
      rethrow;
    }

    return result;
  }

  Future<CsvImportConfig> _loadConfig(
      String configFile, String encoding) async {
    final file = File(configFile);
    final content =
        await file.readAsString(encoding: Encoding.getByName(encoding)!);
    final rows = const CsvToListConverter().convert(content);

    final config = CsvImportConfig();

    for (final row in rows.skip(1)) {
      // ヘッダーをスキップ
      if (row.length >= 2) {
        final setting = row[0] as String;
        final value = row[1] as String;
        config.setSetting(setting, value);
      }
    }

    return config;
  }

  Future<void> _clearExistingData(Graph graph) async {
    await graph.transaction((txn) async {
      await txn.rawQuery('DELETE FROM edges');
      await txn.rawQuery('DELETE FROM edge_labels');
      await txn.rawQuery('DELETE FROM edge_properties');
      await txn.rawQuery('DELETE FROM vertices');
      await txn.rawQuery('DELETE FROM vertex_labels');
      await txn.rawQuery('DELETE FROM vertex_properties');
    });
  }

  Future<void> _importNodes(
    Graph graph,
    String nodesFile,
    ImportResult result,
    CsvImportConfig? importConfig,
    String encoding,
    String onError,
    bool dryRun,
  ) async {
    final file = File(nodesFile);
    final content =
        await file.readAsString(encoding: Encoding.getByName(encoding)!);
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) {
      throw Exception('ノードCSVファイルが空です');
    }

    final headers = rows.first.cast<String>();
    final nodeIdIndex = headers.indexOf('NODE_ID');
    final labelsIndex = headers.indexOf('LABELS');

    if (nodeIdIndex == -1 || labelsIndex == -1) {
      throw Exception('必須カラム（NODE_ID, LABELS）が見つかりません');
    }

    for (var i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        await _importNodeRow(
          graph,
          headers,
          row,
          nodeIdIndex,
          labelsIndex,
          result,
          importConfig,
          dryRun,
        );

        if (i % 100 == 0) {
          config.logVerbose('ノード処理中: $i/${rows.length - 1}');
        }
      } catch (e) {
        result.addError('ノード行[$i]', e.toString());
        if (onError == 'error') {
          throw Exception('ノードインポートエラー: $e');
        }
      }
    }
  }

  Future<void> _importNodeRow(
    Graph graph,
    List<String> headers,
    List<dynamic> row,
    int nodeIdIndex,
    int labelsIndex,
    ImportResult result,
    CsvImportConfig? importConfig,
    bool dryRun,
  ) async {
    final nodeId = row[nodeIdIndex] as String;
    final labelsStr = row[labelsIndex] as String;
    final labels = labelsStr.split(';').map((l) => l.trim()).toSet();

    // プロパティの抽出
    final properties = <String, dynamic>{};
    for (var j = 0; j < headers.length; j++) {
      if (j != nodeIdIndex && j != labelsIndex && j < row.length) {
        final key = headers[j];
        final value = row[j];
        if (value != null && value.toString().isNotEmpty) {
          properties[key] = _convertValue(value.toString());
        }
      }
    }

    if (dryRun) {
      result.importedNodes++;
      return;
    }

    await graph.transaction((txn) async {
      final vertex = Vertex(
        labels: labels,
        properties: properties,
      );

      final created = await txn.createVertex(vertex);
      result.nodeIdMapping[nodeId] = created.id!;
      result.importedNodes++;
    });
  }

  Future<void> _importEdges(
    Graph graph,
    String edgesFile,
    ImportResult result,
    CsvImportConfig? importConfig,
    String encoding,
    String onError,
    bool dryRun,
  ) async {
    final file = File(edgesFile);
    final content =
        await file.readAsString(encoding: Encoding.getByName(encoding)!);
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) {
      throw Exception('エッジCSVファイルが空です');
    }

    final headers = rows.first.cast<String>();
    final edgeIdIndex = headers.indexOf('EDGE_ID');
    final sourceIdIndex = headers.indexOf('SOURCE_ID');
    final targetIdIndex = headers.indexOf('TARGET_ID');
    final typeIndex = headers.indexOf('TYPE');
    final labelsIndex = headers.indexOf('LABELS');

    if (edgeIdIndex == -1 ||
        sourceIdIndex == -1 ||
        targetIdIndex == -1 ||
        typeIndex == -1) {
      throw Exception('必須カラム（EDGE_ID, SOURCE_ID, TARGET_ID, TYPE）が見つかりません');
    }

    for (var i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        await _importEdgeRow(
          graph,
          headers,
          row,
          edgeIdIndex,
          sourceIdIndex,
          targetIdIndex,
          typeIndex,
          labelsIndex,
          result,
          importConfig,
          dryRun,
        );

        if (i % 100 == 0) {
          config.logVerbose('エッジ処理中: $i/${rows.length - 1}');
        }
      } catch (e) {
        result.addError('エッジ行[$i]', e.toString());
        if (onError == 'error') {
          throw Exception('エッジインポートエラー: $e');
        }
      }
    }
  }

  Future<void> _importEdgeRow(
    Graph graph,
    List<String> headers,
    List<dynamic> row,
    int edgeIdIndex,
    int sourceIdIndex,
    int targetIdIndex,
    int typeIndex,
    int labelsIndex,
    ImportResult result,
    CsvImportConfig? importConfig,
    bool dryRun,
  ) async {
    final sourceId = row[sourceIdIndex] as String;
    final targetId = row[targetIdIndex] as String;
    final type = row[typeIndex] as String;

    final labelsStr = labelsIndex != -1 && labelsIndex < row.length
        ? row[labelsIndex] as String?
        : null;
    final additionalLabels =
        labelsStr?.split(';').map((l) => l.trim()).toSet() ?? <String>{};

    // プロパティの抽出
    final properties = <String, dynamic>{};
    final skipIndices = {
      edgeIdIndex,
      sourceIdIndex,
      targetIdIndex,
      typeIndex,
      labelsIndex
    };

    for (var j = 0; j < headers.length; j++) {
      if (!skipIndices.contains(j) && j < row.length) {
        final key = headers[j];
        final value = row[j];
        if (value != null && value.toString().isNotEmpty) {
          properties[key] = _convertValue(value.toString());
        }
      }
    }

    if (dryRun) {
      result.importedEdges++;
      return;
    }

    // ノードIDのマッピングを確認
    final fromVertexId = result.nodeIdMapping[sourceId];
    final toVertexId = result.nodeIdMapping[targetId];

    if (fromVertexId == null || toVertexId == null) {
      throw Exception('参照されているノードが見つかりません: $sourceId -> $targetId');
    }

    await graph.transaction((txn) async {
      final allLabels = {type, ...additionalLabels};
      final edge = Edge(
        labels: allLabels,
        properties: properties,
        fromVertexId: fromVertexId,
        toVertexId: toVertexId,
      );

      await txn.createEdge(edge);
      result.importedEdges++;
    });
  }

  dynamic _convertValue(String value) {
    // 数値の変換
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return int.tryParse(value) ?? value;
    }
    if (RegExp(r'^\d+\.\d+$').hasMatch(value)) {
      return double.tryParse(value) ?? value;
    }

    // 真偽値の変換
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    // 日時の変換
    if (_isIsoDateString(value)) {
      try {
        return DateTime.parse(value);
      } on FormatException {
        // 変換に失敗した場合は文字列のまま
      }
    }

    return value;
  }

  bool _isIsoDateString(String value) {
    try {
      DateTime.parse(value);
      return value.contains('T') &&
          (value.contains('Z') || value.contains('+'));
    } on FormatException {
      return false;
    }
  }
}

/// CSV インポート設定
class CsvImportConfig {
  final Map<String, String> _settings = {};

  void setSetting(String key, String value) {
    _settings[key] = value;
  }

  String? getSetting(String key) {
    return _settings[key];
  }

  List<String> getRequiredProperties() {
    final required = _settings['validation.required'];
    return required?.split(';').map((s) => s.trim()).toList() ?? [];
  }

  List<String> getUniqueProperties() {
    final unique = _settings['validation.unique'];
    return unique?.split(';').map((s) => s.trim()).toList() ?? [];
  }

  bool get strictMode {
    return _settings['import.strict']?.toLowerCase() == 'true';
  }

  String get errorAction {
    return _settings['import.error.action'] ?? 'warn';
  }

  String get cycleCheck {
    return _settings['cycle_check'] ?? 'warn';
  }
}
