import 'dart:io';

import 'package:args/args.dart';
import 'package:rinne_graph/src/cli/commands/base_command.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';
import 'package:rinne_graph/src/cli/import/csv_importer.dart';
import 'package:rinne_graph/src/cli/import/json_importer.dart';
import 'package:rinne_graph/src/graph/graph_impl.dart';

/// データインポートコマンド
class ImportCommand extends CliCommand {
  ImportCommand() : super('import', '外部ファイルからデータをインポート');

  @override
  void setupArguments() {
    argParser.addCommand('json', _createJsonParser());
    argParser.addCommand('csv', _createCsvParser());
  }

  ArgParser _createJsonParser() {
    final parser = ArgParser();
    parser.addFlag(
      'help',
      abbr: 'h',
      help: 'このヘルプを表示',
      negatable: false,
    );
    parser.addOption(
      'input',
      abbr: 'i',
      help: '入力JSONファイル（必須）',
      mandatory: true,
    );
    parser.addOption(
      'database',
      abbr: 'd',
      help: '対象データベースファイル（必須）',
      mandatory: true,
    );
    parser.addFlag(
      'append',
      help: '既存データに追加',
      negatable: false,
    );
    parser.addFlag(
      'no-validation',
      help: 'バリデーションをスキップ',
      negatable: false,
    );
    parser.addOption(
      'on-error',
      help: 'エラー時の動作（skip/warn/error）',
      allowed: ['skip', 'warn', 'error'],
      defaultsTo: 'warn',
    );
    parser.addFlag(
      'dry-run',
      help: '実際のインポートを行わず検証のみ',
      negatable: false,
    );
    return parser;
  }

  ArgParser _createCsvParser() {
    final parser = ArgParser();
    parser.addFlag(
      'help',
      abbr: 'h',
      help: 'このヘルプを表示',
      negatable: false,
    );
    parser.addOption(
      'nodes',
      abbr: 'n',
      help: 'ノードCSVファイル（必須）',
      mandatory: true,
    );
    parser.addOption(
      'edges',
      abbr: 'e',
      help: 'エッジCSVファイル（必須）',
      mandatory: true,
    );
    parser.addOption(
      'config',
      abbr: 'c',
      help: '設定CSVファイル（オプション）',
    );
    parser.addOption(
      'database',
      help: '対象データベースファイル（必須）',
      mandatory: true,
    );
    parser.addFlag(
      'append',
      help: '既存データに追加',
      negatable: false,
    );
    parser.addFlag(
      'no-validation',
      help: 'バリデーションをスキップ',
      negatable: false,
    );
    parser.addOption(
      'on-error',
      help: 'エラー時の動作（skip/warn/error）',
      allowed: ['skip', 'warn', 'error'],
      defaultsTo: 'warn',
    );
    parser.addOption(
      'encoding',
      help: 'ファイルエンコーディング',
      defaultsTo: 'utf-8',
    );
    parser.addFlag(
      'dry-run',
      help: '実際のインポートを行わず検証のみ',
      negatable: false,
    );
    return parser;
  }

  @override
  Future<void> run(ArgResults results, CliConfig config) async {
    if (results.command == null) {
      printHelp();
      exit(1);
    }

    final commandName = results.command!.name;
    final commandResults = results.command!;

    // サブコマンドのヘルプ処理
    if (commandResults['help'] as bool? ?? false) {
      if (commandName != null) {
        _printSubcommandHelp(commandName);
      } else {
        printHelp();
      }
      return;
    }

    switch (commandName) {
      case 'json':
        await _runJsonImport(commandResults, config);
      case 'csv':
        await _runCsvImport(commandResults, config);
      default:
        config.logError('Unknown import format: $commandName');
        exit(1);
    }
  }

  @override
  void printHelp() {
    print('import - 外部ファイルからデータをインポート');
    print('');
    print('使用方法:');
    print('  rinne import json [options]');
    print('  rinne import csv [options]');
    print('');
    print('サブコマンド:');
    print('  json    JSONファイルからインポート');
    print('  csv     CSVファイルからインポート');
    print('');
    print('詳細なヘルプ:');
    print('  rinne import json --help');
    print('  rinne import csv --help');
  }

  void _printSubcommandHelp(String subcommand) {
    switch (subcommand) {
      case 'json':
        printJsonHelp();
      case 'csv':
        printCsvHelp();
      default:
        printHelp();
    }
  }

  void printJsonHelp() {
    print('import json - JSONファイルからデータをインポート');
    print('');
    print('使用方法:');
    print('  rinne import json --input <file> --database <file> [options]');
    print('');
    print('必須オプション:');
    print('  -i, --input <file>      入力JSONファイル');
    print('  -d, --database <file>   対象データベースファイル');
    print('');
    print('オプション:');
    print('      --append            既存データに追加');
    print('      --no-validation     バリデーションをスキップ');
    print('      --on-error <action> エラー時の動作（skip/warn/error）');
    print('      --dry-run           実際のインポートを行わず検証のみ');
    print('  -h, --help              このヘルプを表示');
    print('');
    print('例:');
    print('  rinne import json -i data.json -d graph.db');
    print('  rinne import json -i data.json -d graph.db --append');
    print('  rinne import json -i data.json -d graph.db --dry-run');
  }

  void printCsvHelp() {
    print('import csv - CSVファイルからデータをインポート');
    print('');
    print('使用方法:');
    print('  rinne import csv --nodes <file> --edges <file> '
        '--database <file> [options]');
    print('');
    print('必須オプション:');
    print('  -n, --nodes <file>      ノードCSVファイル');
    print('  -e, --edges <file>      エッジCSVファイル');
    print('      --database <file>   対象データベースファイル');
    print('');
    print('オプション:');
    print('  -c, --config <file>     設定CSVファイル');
    print('      --append            既存データに追加');
    print('      --no-validation     バリデーションをスキップ');
    print('      --on-error <action> エラー時の動作（skip/warn/error）');
    print('      --encoding <enc>    ファイルエンコーディング');
    print('      --dry-run           実際のインポートを行わず検証のみ');
    print('  -h, --help              このヘルプを表示');
    print('');
    print('例:');
    print('  rinne import csv -n nodes.csv -e edges.csv --database graph.db');
    print(
        '  rinne import csv -n nodes.csv -e edges.csv --database graph.db --append');
    print(
        '  rinne import csv -n nodes.csv -e edges.csv --database graph.db --config import.csv');
  }

  Future<void> _runJsonImport(ArgResults results, CliConfig config) async {
    final inputFile = results['input'] as String;
    final databasePath = results['database'] as String;
    final append = results['append'] as bool;
    final noValidation = results['no-validation'] as bool;
    final onError = results['on-error'] as String;
    final dryRun = results['dry-run'] as bool;

    validateFileExists(inputFile, 'JSONファイル');
    // データベースファイルは存在しなくても作成されるため、チェックしない

    try {
      config.logVerbose('JSONインポートを開始: $inputFile -> $databasePath');

      if (dryRun) {
        config.log('ドライランモード: 実際のインポートは行いません');
      }

      // JSONインポートの実行
      // 相対パスを絶対パスに解決
      final fullPath = _resolveAbsolutePath(databasePath);
      final graph = await GraphImpl.openWithAbsolutePath(fullPath);
      try {
        final importer = JsonImporter(config);
        final result = await importer.importFromFile(
          graph,
          inputFile,
          append: append,
          validate: !noValidation,
          onError: onError,
          dryRun: dryRun,
        );

        if (result.success) {
          config.log('JSONインポートが正常に完了しました');
          if (result.errors.isNotEmpty) {
            config.logWarning('警告: ${result.errors.length}件のエラーがありました');
            for (final error in result.errors.take(5)) {
              config.logWarning('  $error');
            }
          }
        } else {
          config.logError('JSONインポートに失敗しました');
          exit(1);
        }
      } finally {
        await graph.close();
      }
    } on Exception catch (e) {
      config.logError('JSONインポートに失敗しました: $e');
      exit(1);
    }
  }

  Future<void> _runCsvImport(ArgResults results, CliConfig config) async {
    final nodesFile = results['nodes'] as String;
    final edgesFile = results['edges'] as String;
    final configFile = results['config'] as String?;
    final databasePath = results['database'] as String;
    final append = results['append'] as bool;
    final noValidation = results['no-validation'] as bool;
    final onError = results['on-error'] as String;
    final encoding = results['encoding'] as String;
    final dryRun = results['dry-run'] as bool;

    validateFileExists(nodesFile, 'ノードCSVファイル');
    validateFileExists(edgesFile, 'エッジCSVファイル');
    // データベースファイルは存在しなくても作成されるため、チェックしない

    if (configFile != null) {
      validateFileExists(configFile, '設定CSVファイル');
    }

    try {
      config.logVerbose('CSVインポートを開始:');
      config.logVerbose('  ノード: $nodesFile');
      config.logVerbose('  エッジ: $edgesFile');
      if (configFile != null) {
        config.logVerbose('  設定: $configFile');
      }
      config.logVerbose('  データベース: $databasePath');

      if (dryRun) {
        config.log('ドライランモード: 実際のインポートは行いません');
      }

      // CSVインポートの実行
      // 相対パスを絶対パスに解決
      final fullPath = _resolveAbsolutePath(databasePath);
      final graph = await GraphImpl.openWithAbsolutePath(fullPath);
      try {
        final importer = CsvImporter(config);
        final result = await importer.importFromFiles(
          graph,
          nodesFile: nodesFile,
          edgesFile: edgesFile,
          configFile: configFile,
          append: append,
          validate: !noValidation,
          onError: onError,
          encoding: encoding,
          dryRun: dryRun,
        );

        if (result.success) {
          config.log('CSVインポートが正常に完了しました');
          if (result.errors.isNotEmpty) {
            config.logWarning('警告: ${result.errors.length}件のエラーがありました');
            for (final error in result.errors.take(5)) {
              config.logWarning('  $error');
            }
          }
        } else {
          config.logError('CSVインポートに失敗しました');
          exit(1);
        }
      } finally {
        await graph.close();
      }
    } on Exception catch (e) {
      config.logError('CSVインポートに失敗しました: $e');
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
