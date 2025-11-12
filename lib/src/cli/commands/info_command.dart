import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/cli/commands/base_command.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';
import 'package:rinne_graph/src/graph/graph_impl.dart';

/// データベース情報表示コマンド
class InfoCommand extends CliCommand {
  InfoCommand() : super('info', 'データベースの基本情報と統計を表示');

  @override
  void setupArguments() {
    argParser.addOption(
      'database',
      help: '対象データベースファイル（必須）',
      mandatory: true,
    );
    argParser.addFlag(
      'detailed',
      help: '詳細統計を表示',
      negatable: false,
    );
    argParser.addFlag(
      'labels',
      help: 'ラベル別統計を表示',
      negatable: false,
    );
    argParser.addOption(
      'format',
      help: '出力形式（text/json）',
      allowed: ['text', 'json'],
      defaultsTo: 'text',
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
    final detailed = results['detailed'] as bool;
    final showLabels = results['labels'] as bool;
    final format = results['format'] as String;

    try {
      config.logVerbose('データベースを開いています: $databasePath');

      // 相対パスを絶対パスに解決
      final fullPath = _resolveAbsolutePath(databasePath);
      final graph = await GraphImpl.openWithAbsolutePath(fullPath);

      try {
        // 基本統計情報の取得
        final stats = await graph.getStatistics();

        // ラベル統計情報の取得（必要に応じて）
        Map<String, dynamic>? labelStats;
        if (showLabels) {
          config.logVerbose('ラベル統計を取得中...');
          // TODO(szktty): Implement label statistics retrieval API.
          labelStats = await _getLabelStatistics(graph);
        }

        // 詳細情報の取得（必要に応じて）
        Map<String, dynamic>? detailedInfo;
        if (detailed) {
          config.logVerbose('詳細情報を取得中...');
          detailedInfo = await _getDetailedInfo(graph);
        }

        // 出力形式に応じて表示
        if (format == 'json') {
          _printJsonFormat(databasePath, stats, labelStats, detailedInfo);
        } else {
          _printTextFormat(
              databasePath, stats, labelStats, detailedInfo, config);
        }
      } finally {
        await graph.close();
      }
    } on Exception catch (e) {
      config.logError('データベース情報の取得に失敗しました: $e');
      exit(1);
    }
  }

  Future<Map<String, dynamic>> _getLabelStatistics(Graph graph) async {
    final stats = await graph.getStatistics();
    return {
      'vertex_labels': stats.vertexLabelCounts,
      'edge_labels': stats.edgeLabelCounts,
    };
  }

  Future<Map<String, dynamic>> _getDetailedInfo(Graph graph) async {
    final stats = await graph.getStatistics();

    // プロパティキーの収集
    final vertexPropertyKeys = stats.vertexPropertyCounts.keys.toList();
    final edgePropertyKeys = stats.edgePropertyCounts.keys.toList();
    final allPropertyKeys =
        {...vertexPropertyKeys, ...edgePropertyKeys}.toList();

    return {
      'database_size': 0, // TODO(szktty): Implement file size retrieval.
      'index_count': 0, // TODO(szktty): Implement index count retrieval.
      'property_keys': allPropertyKeys,
      'vertex_property_keys': vertexPropertyKeys,
      'edge_property_keys': edgePropertyKeys,
    };
  }

  void _printJsonFormat(
    String databasePath,
    GraphStatistics stats,
    Map<String, dynamic>? labelStats,
    Map<String, dynamic>? detailedInfo,
  ) {
    final info = {
      'database_path': databasePath,
      'statistics': {
        'vertex_count': stats.totalVertices,
        'edge_count': stats.totalEdges,
        'vertex_label_count': stats.vertexLabelCounts.length,
        'edge_label_count': stats.edgeLabelCounts.length,
        'vertex_property_count': stats.vertexPropertyCounts.length,
        'edge_property_count': stats.edgePropertyCounts.length,
      },
      if (labelStats != null) 'label_statistics': labelStats,
      if (detailedInfo != null) 'detailed_info': detailedInfo,
    };

    print(const JsonEncoder.withIndent('  ').convert(info));
  }

  void _printTextFormat(
    String databasePath,
    GraphStatistics stats,
    Map<String, dynamic>? labelStats,
    Map<String, dynamic>? detailedInfo,
    CliConfig config,
  ) {
    config.log('=== RinneGraph データベース情報 ===');
    config.log('');
    config.log('ファイル: $databasePath');
    config.log('');
    config.log('基本統計:');
    config.log('  頂点数: ${stats.totalVertices}');
    config.log('  エッジ数: ${stats.totalEdges}');
    final totalLabels =
        stats.vertexLabelCounts.length + stats.edgeLabelCounts.length;
    final totalPropertyKeys =
        stats.vertexPropertyCounts.length + stats.edgePropertyCounts.length;
    config.log('  ラベル数: $totalLabels');
    config.log('  プロパティキー数: $totalPropertyKeys');

    if (labelStats != null) {
      config.log('');
      config.log('ラベル別統計:');
      final vertexLabels = labelStats['vertex_labels'] as Map<String, int>;
      final edgeLabels = labelStats['edge_labels'] as Map<String, int>;

      if (vertexLabels.isNotEmpty) {
        config.log('  頂点ラベル:');
        for (final entry in vertexLabels.entries) {
          config.log('    ${entry.key}: ${entry.value}');
        }
      }

      if (edgeLabels.isNotEmpty) {
        config.log('  エッジラベル:');
        for (final entry in edgeLabels.entries) {
          config.log('    ${entry.key}: ${entry.value}');
        }
      }
    }

    if (detailedInfo != null) {
      config.log('');
      config.log('詳細情報:');
      config.log('  データベースサイズ: ${detailedInfo['database_size']} bytes');
      config.log('  インデックス数: ${detailedInfo['index_count']}');

      final propertyKeys = detailedInfo['property_keys'] as List<String>;
      if (propertyKeys.isNotEmpty) {
        config.log('  プロパティキー: ${propertyKeys.join(', ')}');
      }
    }
  }

  /// 相対パスを絶対パスに解決する
  String _resolveAbsolutePath(String path) {
    if (path.startsWith('/') || path.contains(r':\')) {
      // 既に絶対パスの場合はそのまま返す
      return path;
    } else {
      // 相対パスの場合は現在のワーキングディレクトリと結合
      final currentDir = Directory.current.path;
      return '$currentDir/$path';
    }
  }
}
