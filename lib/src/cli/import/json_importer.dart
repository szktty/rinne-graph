import 'dart:convert';
import 'dart:io';

import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';

/// JSONファイルからのデータインポート機能
class JsonImporter {
  JsonImporter(this.config);

  final CliConfig config;

  /// JSONファイルからグラフデータをインポート
  Future<ImportResult> importFromFile(
    Graph graph,
    String filePath, {
    bool append = false,
    bool validate = true,
    String onError = 'warn',
    bool dryRun = false,
  }) async {
    config.logVerbose('JSONファイルを読み込み中: $filePath');

    final file = File(filePath);
    final content = await file.readAsString();
    final jsonData = jsonDecode(content) as Map<String, dynamic>;

    return importFromJson(
      graph,
      jsonData,
      append: append,
      validate: validate,
      onError: onError,
      dryRun: dryRun,
    );
  }

  /// JSON形式のデータからグラフデータをインポート
  Future<ImportResult> importFromJson(
    Graph graph,
    Map<String, dynamic> jsonData, {
    bool append = false,
    bool validate = true,
    String onError = 'warn',
    bool dryRun = false,
  }) async {
    final result = ImportResult();

    try {
      // メタデータの確認
      final metadata = jsonData['metadata'] as Map<String, dynamic>?;
      if (metadata != null) {
        config.logVerbose('メタデータ: ${metadata['description'] ?? 'なし'}');
        result.metadata = metadata;
      }

      // 既存データのクリア（appendでない場合）
      if (!append && !dryRun) {
        config.logVerbose('既存データをクリア中...');
        await _clearExistingData(graph);
      }

      // ノードのインポート
      final nodes = jsonData['nodes'] as List<dynamic>? ?? [];
      config.logVerbose('ノードをインポート中: ${nodes.length}件');

      for (var i = 0; i < nodes.length; i++) {
        try {
          final nodeData = nodes[i] as Map<String, dynamic>;
          await _importNode(graph, nodeData, result, dryRun);

          if (i % 100 == 0) {
            config.logVerbose('ノード処理中: ${i + 1}/${nodes.length}');
          }
        } catch (e) {
          result.addError('ノード[$i]', e.toString());
          if (onError == 'error') {
            throw Exception('ノードインポートエラー: $e');
          }
        }
      }

      // リンクのインポート
      final links = jsonData['links'] as List<dynamic>? ?? [];
      config.logVerbose('リンクをインポート中: ${links.length}件');

      for (var i = 0; i < links.length; i++) {
        try {
          final linkData = links[i] as Map<String, dynamic>;
          await _importLink(graph, linkData, result, dryRun);

          if (i % 100 == 0) {
            config.logVerbose('リンク処理中: ${i + 1}/${links.length}');
          }
        } catch (e) {
          result.addError('リンク[$i]', e.toString());
          if (onError == 'error') {
            throw Exception('リンクインポートエラー: $e');
          }
        }
      }

      result.success = true;
      config.log('JSONインポートが完了しました');
      config.log('  ノード: ${result.importedNodes}件');
      config.log('  リンク: ${result.importedEdges}件');
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

  Future<void> _clearExistingData(Graph graph) async {
    await graph.transaction((txn) async {
      // すべてのエッジを削除
      await txn.rawQuery('DELETE FROM edges');
      await txn.rawQuery('DELETE FROM edge_labels');
      await txn.rawQuery('DELETE FROM edge_properties');

      // すべての頂点を削除
      await txn.rawQuery('DELETE FROM vertices');
      await txn.rawQuery('DELETE FROM vertex_labels');
      await txn.rawQuery('DELETE FROM vertex_properties');
    });
  }

  Future<void> _importNode(
    Graph graph,
    Map<String, dynamic> nodeData,
    ImportResult result,
    bool dryRun,
  ) async {
    final id = nodeData['id'] as String;
    final labels = (nodeData['labels'] as List<dynamic>).cast<String>().toSet();
    final properties = nodeData['properties'] as Map<String, dynamic>? ?? {};

    if (dryRun) {
      result.importedNodes++;
      return;
    }

    await graph.transaction((txn) async {
      final vertex = Vertex(
        labels: labels,
        properties: _convertProperties(properties),
      );

      final created = await txn.createVertex(vertex);
      result.nodeIdMapping[id] = created.id!;
      result.importedNodes++;
    });
  }

  Future<void> _importLink(
    Graph graph,
    Map<String, dynamic> linkData,
    ImportResult result,
    bool dryRun,
  ) async {
    final sourceId = linkData['source_id'] as String;
    final targetId = linkData['target_id'] as String;
    final type = linkData['type'] as String;
    final labels =
        (linkData['labels'] as List<dynamic>?)?.cast<String>().toSet() ??
            <String>{};
    final properties = linkData['properties'] as Map<String, dynamic>? ?? {};

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
      final allLabels = {type, ...labels};
      final edge = Edge(
        labels: allLabels,
        properties: _convertProperties(properties),
        fromVertexId: fromVertexId,
        toVertexId: toVertexId,
      );

      await txn.createEdge(edge);
      result.importedEdges++;
    });
  }

  Map<String, dynamic> _convertProperties(Map<String, dynamic> properties) {
    final converted = <String, dynamic>{};

    for (final entry in properties.entries) {
      final key = entry.key;
      final value = entry.value;

      // 日時文字列の変換
      if (value is String && _isIsoDateString(value)) {
        converted[key] = DateTime.parse(value);
      } else {
        converted[key] = value;
      }
    }

    return converted;
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

/// インポート結果を表すクラス
class ImportResult {
  bool success = false;
  int importedNodes = 0;
  int importedEdges = 0;
  Map<String, dynamic>? metadata;
  Map<String, int> nodeIdMapping = {};
  List<ImportError> errors = [];

  void addError(String location, String message) {
    errors.add(ImportError(location, message));
  }
}

/// インポートエラーを表すクラス
class ImportError {
  ImportError(this.location, this.message);

  final String location;
  final String message;

  @override
  String toString() => '$location: $message';
}
