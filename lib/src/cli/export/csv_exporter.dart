import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';
import 'package:rinne_graph/src/cli/export/json_exporter.dart';

/// CSV形式でのデータエクスポート機能
class CsvExporter {
  CsvExporter(this.config);

  final CliConfig config;

  /// グラフデータをCSVファイルにエクスポート
  Future<ExportResult> exportToFiles(
    Graph graph, {
    required String nodesFile,
    required String edgesFile,
    bool includeHeader = true,
    List<String>? filterLabels,
    int? limit,
    String encoding = 'utf-8',
  }) async {
    config.logVerbose('CSVエクスポートを開始');
    config.logVerbose('  ノード出力: $nodesFile');
    config.logVerbose('  エッジ出力: $edgesFile');

    final result = ExportResult();

    try {
      // ノードのエクスポート
      await _exportNodes(
        graph,
        nodesFile,
        includeHeader,
        filterLabels,
        limit,
        encoding,
        result,
      );

      // エッジのエクスポート
      await _exportEdges(
        graph,
        edgesFile,
        includeHeader,
        filterLabels,
        limit,
        encoding,
        result,
      );

      result.success = true;
      config.log('CSVエクスポートが完了しました');
      config.log('  ノード: ${result.exportedNodes}件 -> $nodesFile');
      config.log('  エッジ: ${result.exportedEdges}件 -> $edgesFile');
    } catch (e) {
      result.success = false;
      rethrow;
    }

    return result;
  }

  Future<void> _exportNodes(
    Graph graph,
    String nodesFile,
    bool includeHeader,
    List<String>? filterLabels,
    int? limit,
    String encoding,
    ExportResult result,
  ) async {
    config.logVerbose('ノードデータを収集中...');

    final vertices = <Vertex>[];
    final propertyKeys = <String>{};

    await graph.transaction((txn) async {
      // 全頂点を取得
      final vertexStream = txn.vertices(labels: filterLabels);
      var count = 0;

      await for (final vertex in vertexStream) {
        if (limit != null && count >= limit) break;

        vertices.add(vertex);
        propertyKeys.addAll(vertex.properties.keys.cast<String>());
        count++;
      }
    });

    final sortedPropertyKeys = propertyKeys.toList()..sort();

    // CSVデータの構築
    final csvData = <List<String>>[];

    // ヘッダー行
    if (includeHeader) {
      csvData.add(['NODE_ID', 'LABELS', ...sortedPropertyKeys]);
    }

    // データ行
    for (final vertex in vertices) {
      final row = <String>[
        'node_${vertex.id}',
        vertex.labels.join(';'),
      ];

      // プロパティ値の追加
      for (final key in sortedPropertyKeys) {
        final value = vertex.properties[key];
        row.add(_formatValue(value));
      }

      csvData.add(row);
      result.exportedNodes++;

      if (result.exportedNodes % 100 == 0) {
        config.logVerbose('ノード処理中: ${result.exportedNodes}');
      }
    }

    // ファイルに書き込み
    final csvString = const ListToCsvConverter().convert(csvData);
    final file = File(nodesFile);
    await file.writeAsString(csvString,
        encoding: Encoding.getByName(encoding)!);
  }

  Future<void> _exportEdges(
    Graph graph,
    String edgesFile,
    bool includeHeader,
    List<String>? filterLabels,
    int? limit,
    String encoding,
    ExportResult result,
  ) async {
    config.logVerbose('エッジデータを収集中...');

    final edges = <Edge>[];
    final propertyKeys = <String>{};

    await graph.transaction((txn) async {
      // 全エッジを取得
      final edgeStream = txn.edges(labels: filterLabels);
      var count = 0;

      await for (final edge in edgeStream) {
        if (limit != null && count >= limit) break;

        edges.add(edge);
        propertyKeys.addAll(edge.properties.keys.cast<String>());
        count++;
      }
    });

    final sortedPropertyKeys = propertyKeys.toList()..sort();

    // CSVデータの構築
    final csvData = <List<String>>[];

    // ヘッダー行
    if (includeHeader) {
      csvData.add([
        'EDGE_ID',
        'SOURCE_ID',
        'TARGET_ID',
        'TYPE',
        'LABELS',
        ...sortedPropertyKeys
      ]);
    }

    // データ行
    for (final edge in edges) {
      // 主要ラベル（TYPE）と追加ラベルを分離
      final labelsList = edge.labels.toList();
      final type = labelsList.isNotEmpty ? labelsList.first : 'UNKNOWN';
      final additionalLabels =
          labelsList.length > 1 ? labelsList.skip(1).join(';') : '';

      final row = <String>[
        'edge_${edge.id}',
        'node_${edge.fromVertexId}',
        'node_${edge.toVertexId}',
        type,
        additionalLabels,
      ];

      // プロパティ値の追加
      for (final key in sortedPropertyKeys) {
        final value = edge.properties[key];
        row.add(_formatValue(value));
      }

      csvData.add(row);
      result.exportedEdges++;

      if (result.exportedEdges % 100 == 0) {
        config.logVerbose('エッジ処理中: ${result.exportedEdges}');
      }
    }

    // ファイルに書き込み
    final csvString = const ListToCsvConverter().convert(csvData);
    final file = File(edgesFile);
    await file.writeAsString(csvString,
        encoding: Encoding.getByName(encoding)!);
  }

  String _formatValue(dynamic value) {
    if (value == null) {
      return '';
    } else if (value is DateTime) {
      return value.toIso8601String();
    } else if (value is NullValue) {
      return '';
    } else if (value is String) {
      // CSVエスケープ処理
      if (value.contains(',') ||
          value.contains('"') ||
          value.contains('\n') ||
          value.contains(';')) {
        return '"${value.replaceAll('"', '""')}"';
      }
      return value;
    } else {
      return value.toString();
    }
  }
}
