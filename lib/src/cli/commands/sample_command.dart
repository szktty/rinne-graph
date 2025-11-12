import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/cli/commands/base_command.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';
import 'package:rinne_graph/src/samples/samples.dart';

/// サンプルデータ生成コマンド
class SampleCommand extends CliCommand {
  SampleCommand() : super('sample', 'テスト用のサンプルデータを生成');

  @override
  void setupArguments() {
    argParser.addOption(
      'database',
      help: '対象データベースファイル（必須）',
      mandatory: true,
    );
    argParser.addOption(
      'type',
      help: 'サンプルタイプ（simple/movies/large/custom）',
      allowed: ['simple', 'movies', 'large', 'custom'],
      defaultsTo: 'simple',
    );
    argParser.addOption(
      'nodes',
      help: 'ノード数（largeタイプ用）',
      defaultsTo: '1000',
    );
    argParser.addOption(
      'edges',
      help: 'エッジ数（largeタイプ用）',
      defaultsTo: '5000',
    );
    argParser.addOption(
      'config',
      help: 'カスタム設定ファイル（customタイプ用）',
    );
    argParser.addOption(
      'seed',
      help: '乱数シード',
    );
    argParser.addFlag(
      'help',
      abbr: 'h',
      help: 'ヘルプを表示',
      negatable: false,
    );
  }

  @override
  Future<void> run(ArgResults results, CliConfig config) async {
    if (results['help'] as bool) {
      printHelp();
      return;
    }

    final databasePath = results['database'] as String;
    final sampleType = results['type'] as String;
    final nodeCount = int.parse(results['nodes'] as String);
    final edgeCount = int.parse(results['edges'] as String);
    final configFile = results['config'] as String?;
    final seedStr = results['seed'] as String?;

    // 乱数シードの設定
    if (seedStr != null) {
      final seed = int.parse(seedStr);
      config.logVerbose('乱数シードを設定: $seed');
      // TODO(szktty): Implement random seed configuration.
    }

    try {
      config.logVerbose('データベースを開いています: $databasePath');
      final graph = await Graph.open(databasePath);

      try {
        config.log('サンプルデータを生成中...');

        switch (sampleType) {
          case 'simple':
            await _generateSimpleSample(graph, config);
          case 'movies':
            await _generateMoviesSample(graph, config);
          case 'large':
            await _generateLargeSample(graph, nodeCount, edgeCount, config);
          case 'custom':
            if (configFile == null) {
              config.logError('customタイプには--configオプションが必要です');
              exit(1);
            }
            await _generateCustomSample(graph, configFile, config);
        }

        // 結果の表示
        final stats = await graph.getStatistics();
        config.log('サンプルデータの生成が完了しました');
        config.log('頂点数: ${stats.totalVertices}');
        config.log('エッジ数: ${stats.totalEdges}');
        final totalLabels =
            stats.vertexLabelCounts.length + stats.edgeLabelCounts.length;
        config.log('ラベル数: $totalLabels');
      } finally {
        await graph.close();
      }
    } on Exception catch (e) {
      config.logError('サンプルデータの生成に失敗しました: $e');
      exit(1);
    }
  }

  Future<void> _generateSimpleSample(Graph graph, CliConfig config) async {
    config.logVerbose('シンプルサンプルを生成中...');

    // 既存のサンプルデータを使用
    final sampleGraph = await Samples.simpleGraph();

    try {
      // データをコピー
      await _copyGraphData(sampleGraph, graph, config);
    } finally {
      await sampleGraph.close();
    }
  }

  Future<void> _generateMoviesSample(Graph graph, CliConfig config) async {
    config.logVerbose('映画サンプルを生成中...');

    // 既存の映画サンプルデータを使用
    final sampleGraph = await Samples.movies();

    try {
      // データをコピー
      await _copyGraphData(sampleGraph, graph, config);
    } finally {
      await sampleGraph.close();
    }
  }

  Future<void> _generateLargeSample(
    Graph graph,
    int nodeCount,
    int edgeCount,
    CliConfig config,
  ) async {
    config.logVerbose('大規模サンプルを生成中: ノード=$nodeCount, エッジ=$edgeCount');

    final random = Random();
    final vertexIds = <int>[];

    await graph.transaction((txn) async {
      // 頂点の生成
      config.logVerbose('頂点を生成中...');
      for (var i = 0; i < nodeCount; i++) {
        if (i % 100 == 0) {
          showProgress('頂点生成中: ${i + 1}/$nodeCount', config);
        }

        final vertex = Vertex(
          labels: {'Node'},
          properties: {
            'id': i,
            'name': 'Node_$i',
            'value': random.nextDouble(),
            'category': random.nextInt(10),
          },
        );

        final created = await txn.createVertex(vertex);
        vertexIds.add(created.id!);
      }
      completeProgress(config);

      // エッジの生成
      config.logVerbose('エッジを生成中...');
      for (var i = 0; i < edgeCount; i++) {
        if (i % 100 == 0) {
          showProgress('エッジ生成中: ${i + 1}/$edgeCount', config);
        }

        final fromId = vertexIds[random.nextInt(vertexIds.length)];
        final toId = vertexIds[random.nextInt(vertexIds.length)];

        if (fromId != toId) {
          final edge = Edge(
            labels: {'Connection'},
            properties: {
              'weight': random.nextDouble(),
              'type': random.nextInt(5),
            },
            fromVertexId: fromId,
            toVertexId: toId,
          );

          await txn.createEdge(edge);
        }
      }
      completeProgress(config);
    });
  }

  Future<void> _generateCustomSample(
    Graph graph,
    String configFile,
    CliConfig config,
  ) async {
    config.logVerbose('カスタムサンプルを生成中: $configFile');

    validateFileExists(configFile, 'カスタム設定ファイル');

    // TODO(szktty): Implement custom configuration file loading and processing.
    config.logWarning('カスタムサンプル生成は未実装です');
  }

  /// グラフ間でのデータコピー
  Future<void> _copyGraphData(
      Graph sourceGraph, Graph targetGraph, CliConfig config) async {
    config.logVerbose('グラフデータをコピー中...');

    final vertexIdMapping = <int, int>{};

    await targetGraph.transaction((txn) async {
      // 頂点のコピー
      config.logVerbose('頂点をコピー中...');
      final sourceTraversal = sourceGraph.traversal();
      final vertices = await sourceTraversal.V().toList();

      for (final vertex in vertices) {
        if (vertex is Vertex) {
          final newVertex = Vertex(
            labels: vertex.labels,
            properties: Map<String, dynamic>.from(vertex.properties),
          );

          final created = await txn.createVertex(newVertex);
          vertexIdMapping[vertex.id!] = created.id!;
        }
      }

      // エッジのコピー
      config.logVerbose('エッジをコピー中...');
      final edges = await sourceTraversal.E().toList();

      for (final edge in edges) {
        if (edge is Edge) {
          final fromVertexId = vertexIdMapping[edge.fromVertexId];
          final toVertexId = vertexIdMapping[edge.toVertexId];

          if (fromVertexId != null && toVertexId != null) {
            final newEdge = Edge(
              labels: edge.labels,
              properties: Map<String, dynamic>.from(edge.properties),
              fromVertexId: fromVertexId,
              toVertexId: toVertexId,
            );

            await txn.createEdge(newEdge);
          }
        }
      }
    });

    config.logVerbose('グラフデータのコピーが完了しました');
  }
}
