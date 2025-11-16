import 'dart:io';

import 'package:args/args.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/cli/commands/base_command.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';
import 'package:rinne_graph/src/graph/graph_impl.dart';

/// データベース作成コマンド
class CreateCommand extends CliCommand {
  CreateCommand() : super('create', '新しいRinneGraphデータベースを作成');

  @override
  void setupArguments() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: '出力ファイルパス（必須）',
    );
    argParser.addOption(
      'description',
      abbr: 'd',
      help: 'データベースの説明',
    );
    argParser.addFlag(
      'memory',
      help: 'インメモリデータベースとして作成',
      negatable: false,
    );
    argParser.addFlag(
      'overwrite',
      help: '既存ファイルを上書き',
      negatable: false,
    );
    argParser.addFlag(
      'help',
      abbr: 'h',
      help: 'ヘルプを表示',
      negatable: false,
    );
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: '詳細ログを出力',
      negatable: false,
    );
  }

  @override
  Future<void> run(ArgResults results, CliConfig config) async {
    if (results['help'] as bool) {
      printHelp();
      return;
    }

    final outputPath = results['output'] as String;
    final description = results['description'] as String?;
    final isMemory = results['memory'] as bool;
    final overwrite = results['overwrite'] as bool;

    // 既存ファイルの確認
    if (!isMemory && File(outputPath).existsSync() && !overwrite) {
      if (!confirmOverwrite(outputPath, config)) {
        config.log('操作がキャンセルされました');
        return;
      }
    }

    try {
      print('DEBUG: CreateCommand.run() started'); // デバッグ用
      config.logVerbose('データベースを作成中: $outputPath');

      Graph? graph;
      var fullPath = outputPath; // デフォルトは入力パス

      if (isMemory) {
        // インメモリデータベースの場合、ファイルに保存する必要がある
        graph = await Graph.openInMemory();
        config.logVerbose('インメモリデータベースを作成しました');

        // TODO(szktty): Implement functionality to save in-memory database to file.
        config.logWarning('インメモリデータベースのファイル保存は未実装です');
      } else {
        // ファイルベースのデータベース
        // 相対パスを絶対パスに解決
        fullPath = _resolveAbsolutePath(outputPath);
        graph = await GraphImpl.openWithAbsolutePath(fullPath);
        config.logVerbose('ファイルベースのデータベースを作成しました: $fullPath');
      }

      // データベースの基本情報を設定
      if (description != null) {
        // TODO(szktty): Implement database metadata storage functionality.
        config.logVerbose('説明を設定: $description');
      }

      // 統計情報の取得
      final stats = await graph.getStatistics();

      await graph.close();

      // 結果の表示
      config.log('データベースが正常に作成されました');
      config.log('ファイル: $fullPath');
      if (description != null) {
        config.log('説明: $description');
      }
      config.log('頂点数: ${stats.totalVertices}');
      config.log('エッジ数: ${stats.totalEdges}');

      if (config.verbose) {
        final totalLabels =
            stats.vertexLabelCounts.length + stats.edgeLabelCounts.length;
        final totalPropertyKeys =
            stats.vertexPropertyCounts.length + stats.edgePropertyCounts.length;
        config.logVerbose('ラベル数: $totalLabels');
        config.logVerbose('プロパティキー数: $totalPropertyKeys');
      }
    } on Exception catch (e) {
      config.logError('データベースの作成に失敗しました: $e');
      exit(1);
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
