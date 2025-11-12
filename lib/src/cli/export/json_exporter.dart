import 'dart:convert';
import 'dart:io';

import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';

/// JSON形式でのデータエクスポート機能
class JsonExporter {
  JsonExporter(this.config);

  final CliConfig config;

  /// グラフデータをJSONファイルにエクスポート
  Future<ExportResult> exportToFile(
    Graph graph,
    String filePath, {
    bool includeMetadata = true,
    bool pretty = true,
    List<String>? filterLabels,
    int? limit,
  }) async {
    config.logVerbose('JSONエクスポートを開始: $filePath');

    final jsonData = await exportToJson(
      graph,
      includeMetadata: includeMetadata,
      filterLabels: filterLabels,
      limit: limit,
    );

    final file = File(filePath);
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();

    await file.writeAsString(encoder.convert(jsonData));

    final result = ExportResult()
      ..success = true
      ..outputFile = filePath;

    config.log('JSONエクスポートが完了しました: $filePath');
    return result;
  }

  /// グラフデータをJSON形式に変換
  Future<Map<String, dynamic>> exportToJson(
    Graph graph, {
    bool includeMetadata = true,
    List<String>? filterLabels,
    int? limit,
  }) async {
    final result = <String, dynamic>{};

    // メタデータの追加
    if (includeMetadata) {
      final stats = await graph.getStatistics();
      result['metadata'] = {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
        'description': 'RinneGraphからエクスポートされたデータ',
        'generator': 'RinneGraph CLI',
        'node_count': stats.totalVertices,
        'edge_count': stats.totalEdges,
      };
    }

    // ノードのエクスポート
    config.logVerbose('ノードをエクスポート中...');
    final nodes = await _exportNodes(graph, filterLabels, limit);
    result['nodes'] = nodes;

    // リンクのエクスポート
    config.logVerbose('リンクをエクスポート中...');
    final links = await _exportLinks(graph, filterLabels, limit);
    result['links'] = links;

    config.logVerbose('エクスポート完了: ノード=${nodes.length}, リンク=${links.length}');
    return result;
  }

  Future<List<Map<String, dynamic>>> _exportNodes(
    Graph graph,
    List<String>? filterLabels,
    int? limit,
  ) async {
    final nodes = <Map<String, dynamic>>[];

    await graph.transaction((txn) async {
      // 全頂点を取得
      final vertexStream = txn.vertices(labels: filterLabels);
      var count = 0;

      await for (final vertex in vertexStream) {
        if (limit != null && count >= limit) break;

        final nodeData = <String, dynamic>{
          'id': 'node_${vertex.id}',
          'labels': vertex.labels.toList(),
          'properties': await _convertProperties(vertex.properties),
        };
        nodes.add(nodeData);
        count++;

        if (nodes.length % 100 == 0) {
          config.logVerbose('ノード処理中: ${nodes.length}');
        }
      }
    });

    return nodes;
  }

  Future<List<Map<String, dynamic>>> _exportLinks(
    Graph graph,
    List<String>? filterLabels,
    int? limit,
  ) async {
    final links = <Map<String, dynamic>>[];

    await graph.transaction((txn) async {
      // 全エッジを取得
      final edgeStream = txn.edges(labels: filterLabels);
      var count = 0;

      await for (final edge in edgeStream) {
        if (limit != null && count >= limit) break;

        // 主要ラベル（TYPE）と追加ラベルを分離
        final labelsList = edge.labels.toList();
        final type = labelsList.isNotEmpty ? labelsList.first : 'UNKNOWN';
        final additionalLabels =
            labelsList.length > 1 ? labelsList.skip(1).toList() : <String>[];

        final linkData = <String, dynamic>{
          'id': 'link_${edge.id}',
          'source_id': 'node_${edge.fromVertexId}',
          'target_id': 'node_${edge.toVertexId}',
          'type': type,
          'labels': additionalLabels,
          'properties': await _convertProperties(edge.properties),
        };
        links.add(linkData);
        count++;

        if (links.length % 100 == 0) {
          config.logVerbose('リンク処理中: ${links.length}');
        }
      }
    });

    return links;
  }

  Future<Map<String, dynamic>> _convertProperties(
      Map<String, dynamic> properties) async {
    final converted = <String, dynamic>{};

    for (final entry in properties.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is DateTime) {
        // DateTimeをISO 8601文字列に変換
        converted[key] = value.toIso8601String();
      } else if (value is NullValue) {
        // NullValueをnullに変換
        converted[key] = null;
      } else {
        converted[key] = value;
      }
    }

    return converted;
  }
}

/// エクスポート結果を表すクラス
class ExportResult {
  bool success = false;
  String? outputFile;
  int exportedNodes = 0;
  int exportedEdges = 0;
  List<String> warnings = [];

  void addWarning(String message) {
    warnings.add(message);
  }
}
