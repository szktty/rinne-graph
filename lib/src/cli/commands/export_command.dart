import 'dart:io';

import 'package:args/args.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/cli/commands/base_command.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';
import 'package:rinne_graph/src/cli/export/csv_exporter.dart';
import 'package:rinne_graph/src/cli/export/json_exporter.dart';

/// データエクスポートコマンド
class ExportCommand extends CliCommand {
  ExportCommand() : super('export', 'データベースからデータをエクスポート');

  @override
  void setupArguments() {
    argParser.addCommand('json', _createJsonParser());
    argParser.addCommand('csv', _createCsvParser());
  }

  ArgParser _createJsonParser() {
    final parser = ArgParser();
    parser.addOption(
      'database',
      help: '対象データベースファイル（必須）',
      mandatory: true,
    );
    parser.addOption(
      'output',
      abbr: 'o',
      help: '出力JSONファイル（必須）',
      mandatory: true,
    );
    parser.addFlag(
      'include-metadata',
      help: 'メタデータを含める',
      negatable: false,
    );
    parser.addFlag(
      'pretty',
      help: '整形された出力',
      negatable: false,
    );
    parser.addOption(
      'filter-labels',
      help: 'エクスポート対象ラベル（カンマ区切り）',
    );
    parser.addOption(
      'limit',
      help: 'エクスポート件数制限',
    );
    return parser;
  }

  ArgParser _createCsvParser() {
    final parser = ArgParser();
    parser.addOption(
      'database',
      help: '対象データベースファイル（必須）',
      mandatory: true,
    );
    parser.addOption(
      'nodes-output',
      help: 'ノードCSV出力ファイル（必須）',
      mandatory: true,
    );
    parser.addOption(
      'edges-output',
      help: 'エッジCSV出力ファイル（必須）',
      mandatory: true,
    );
    parser.addFlag(
      'no-header',
      help: 'ヘッダー行を出力しない',
      negatable: false,
    );
    parser.addOption(
      'filter-labels',
      help: 'エクスポート対象ラベル（カンマ区切り）',
    );
    parser.addOption(
      'limit',
      help: 'エクスポート件数制限',
    );
    parser.addOption(
      'encoding',
      help: '出力エンコーディング',
      defaultsTo: 'utf-8',
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

    switch (commandName) {
      case 'json':
        await _runJsonExport(commandResults, config);
      case 'csv':
        await _runCsvExport(commandResults, config);
      default:
        config.logError('Unknown export format: $commandName');
        exit(1);
    }
  }

  @override
  void printHelp() {
    print('export - データベースからデータをエクスポート');
    print('');
    print('使用方法:');
    print('  rinne export json [options]');
    print('  rinne export csv [options]');
    print('');
    print('サブコマンド:');
    print('  json    JSON形式でエクスポート');
    print('  csv     CSV形式でエクスポート');
    print('');
    print('詳細なヘルプ:');
    print('  rinne export json --help');
    print('  rinne export csv --help');
  }

  Future<void> _runJsonExport(ArgResults results, CliConfig config) async {
    final databasePath = results['database'] as String;
    final outputFile = results['output'] as String;
    final includeMetadata = results['include-metadata'] as bool;
    final pretty = results['pretty'] as bool;
    final filterLabels = results['filter-labels'] as String?;
    final limitStr = results['limit'] as String?;

    validateFileExists(databasePath, 'データベースファイル');

    final limit = limitStr != null ? int.parse(limitStr) : null;
    final labels = filterLabels?.split(',').map((l) => l.trim()).toList();

    // 出力ファイルの上書き確認
    if (!confirmOverwrite(outputFile, config)) {
      config.log('操作がキャンセルされました');
      return;
    }

    try {
      config.logVerbose('JSONエクスポートを開始: $databasePath -> $outputFile');

      if (labels != null) {
        config.logVerbose('ラベルフィルタ: ${labels.join(', ')}');
      }
      if (limit != null) {
        config.logVerbose('件数制限: $limit');
      }

      // JSONエクスポートの実行
      final graph = await Graph.open(databasePath);
      try {
        final exporter = JsonExporter(config);
        final result = await exporter.exportToFile(
          graph,
          outputFile,
          includeMetadata: includeMetadata,
          pretty: pretty,
          filterLabels: labels,
          limit: limit,
        );

        if (result.success) {
          config.log('JSONエクスポートが正常に完了しました');
          config.log('出力ファイル: ${result.outputFile}');
          if (result.warnings.isNotEmpty) {
            config.logWarning('警告: ${result.warnings.length}件');
            for (final warning in result.warnings.take(3)) {
              config.logWarning('  $warning');
            }
          }
        } else {
          config.logError('JSONエクスポートに失敗しました');
          exit(1);
        }
      } finally {
        await graph.close();
      }
    } on Exception catch (e) {
      config.logError('JSONエクスポートに失敗しました: $e');
      exit(1);
    }
  }

  Future<void> _runCsvExport(ArgResults results, CliConfig config) async {
    final databasePath = results['database'] as String;
    final nodesOutput = results['nodes-output'] as String;
    final edgesOutput = results['edges-output'] as String;
    final noHeader = results['no-header'] as bool;
    final filterLabels = results['filter-labels'] as String?;
    final limitStr = results['limit'] as String?;
    final encoding = results['encoding'] as String;

    validateFileExists(databasePath, 'データベースファイル');

    final limit = limitStr != null ? int.parse(limitStr) : null;
    final labels = filterLabels?.split(',').map((l) => l.trim()).toList();

    // 出力ファイルの上書き確認
    if (!confirmOverwrite(nodesOutput, config) ||
        !confirmOverwrite(edgesOutput, config)) {
      config.log('操作がキャンセルされました');
      return;
    }

    try {
      config.logVerbose('CSVエクスポートを開始:');
      config.logVerbose('  データベース: $databasePath');
      config.logVerbose('  ノード出力: $nodesOutput');
      config.logVerbose('  エッジ出力: $edgesOutput');

      if (labels != null) {
        config.logVerbose('ラベルフィルタ: ${labels.join(', ')}');
      }
      if (limit != null) {
        config.logVerbose('件数制限: $limit');
      }

      // CSVエクスポートの実行
      final graph = await Graph.open(databasePath);
      try {
        final exporter = CsvExporter(config);
        final result = await exporter.exportToFiles(
          graph,
          nodesFile: nodesOutput,
          edgesFile: edgesOutput,
          includeHeader: !noHeader,
          filterLabels: labels,
          limit: limit,
          encoding: encoding,
        );

        if (result.success) {
          config.log('CSVエクスポートが正常に完了しました');
          config.log('ノード出力: $nodesOutput (${result.exportedNodes}件)');
          config.log('エッジ出力: $edgesOutput (${result.exportedEdges}件)');
          if (result.warnings.isNotEmpty) {
            config.logWarning('警告: ${result.warnings.length}件');
            for (final warning in result.warnings.take(3)) {
              config.logWarning('  $warning');
            }
          }
        } else {
          config.logError('CSVエクスポートに失敗しました');
          exit(1);
        }
      } finally {
        await graph.close();
      }
    } on Exception catch (e) {
      config.logError('CSVエクスポートに失敗しました: $e');
      exit(1);
    }
  }
}
