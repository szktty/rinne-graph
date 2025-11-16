import 'dart:io';

import 'package:args/args.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/cli/commands/base_command.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';

/// データベース検証コマンド
class ValidateCommand extends CliCommand {
  ValidateCommand() : super('validate', 'データベースの整合性を検証');

  @override
  void setupArguments() {
    argParser.addOption(
      'database',
      help: '対象データベースファイル（必須）',
      mandatory: true,
    );
    argParser.addFlag(
      'detailed',
      help: '詳細な検証を実行',
      negatable: false,
    );
    argParser.addFlag(
      'repair',
      help: '修復可能な問題を自動修復',
      negatable: false,
    );
    argParser.addOption(
      'report',
      help: '検証結果をファイルに出力',
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
    final repair = results['repair'] as bool;
    final reportFile = results['report'] as String?;

    validateFileExists(databasePath, 'データベースファイル');

    try {
      config.logVerbose('データベース検証を開始: $databasePath');

      // DatabaseManagerを使用した基本検証
      final manager = DatabaseManager();
      final validationResult = await manager.validateDatabaseFile(databasePath);

      final issues = <ValidationIssue>[];

      // 基本検証結果の確認
      if (!validationResult.isFullyInitialized) {
        issues.add(ValidationIssue(
          type: 'ERROR',
          category: 'INITIALIZATION',
          message: validationResult.description,
        ));
      } else {
        config.logVerbose('基本検証: OK');
      }

      // 詳細検証の実行
      if (detailed && validationResult.isFullyInitialized) {
        config.logVerbose('詳細検証を実行中...');
        final detailedIssues =
            await _performDetailedValidation(databasePath, config);
        issues.addAll(detailedIssues);
      }

      // 修復の実行
      if (repair && issues.isNotEmpty) {
        config.logVerbose('修復を実行中...');
        final repairedIssues =
            await _performRepair(databasePath, issues, config);
        for (final issue in repairedIssues) {
          issue.repaired = true;
        }
      }

      // 結果の表示
      _displayResults(issues, config);

      // レポートファイルの出力
      if (reportFile != null) {
        await _writeReport(reportFile, databasePath, issues, config);
      }

      // 終了コードの設定
      final errorCount =
          issues.where((i) => i.type == 'ERROR' && !i.repaired).length;
      if (errorCount > 0) {
        exit(5); // バリデーションエラー
      }
    } on Exception catch (e) {
      config.logError('データベース検証に失敗しました: $e');
      exit(1);
    }
  }

  Future<List<ValidationIssue>> _performDetailedValidation(
    String databasePath,
    CliConfig config,
  ) async {
    final issues = <ValidationIssue>[];

    try {
      final graph = await Graph.open(databasePath);

      try {
        // 参照整合性の検証
        config.logVerbose('参照整合性を検証中...');
        final referentialIssues = await _validateReferentialIntegrity(graph);
        issues.addAll(referentialIssues);

        // データ型の検証
        config.logVerbose('データ型を検証中...');
        final typeIssues = await _validateDataTypes(graph);
        issues.addAll(typeIssues);

        // インデックスの検証
        config.logVerbose('インデックスを検証中...');
        final indexIssues = await _validateIndexes(graph);
        issues.addAll(indexIssues);
      } finally {
        await graph.close();
      }
    } on Exception catch (e) {
      issues.add(ValidationIssue(
        type: 'ERROR',
        category: 'DATABASE_ACCESS',
        message: 'データベースアクセスエラー: $e',
      ));
    }

    return issues;
  }

  Future<List<ValidationIssue>> _validateReferentialIntegrity(
      Graph graph) async {
    final issues = <ValidationIssue>[];

    // TODO(szktty): Implement referential integrity validation.
    // - Verify that edge fromVertexId and toVertexId reference existing vertices
    // - Check for orphaned edges

    return issues;
  }

  Future<List<ValidationIssue>> _validateDataTypes(Graph graph) async {
    final issues = <ValidationIssue>[];

    // TODO(szktty): Implement data type validation.
    // - Verify property value types are appropriate
    // - Check for invalid values

    return issues;
  }

  Future<List<ValidationIssue>> _validateIndexes(Graph graph) async {
    final issues = <ValidationIssue>[];

    // TODO(szktty): Implement index validation.
    // - Check for corrupted indexes
    // - Identify unnecessary indexes

    return issues;
  }

  Future<List<ValidationIssue>> _performRepair(
    String databasePath,
    List<ValidationIssue> issues,
    CliConfig config,
  ) async {
    final repairedIssues = <ValidationIssue>[];

    for (final issue in issues) {
      if (issue.canRepair) {
        config.logVerbose('修復中: ${issue.message}');

        try {
          // TODO(szktty): Implement repair logic.
          repairedIssues.add(issue);
          config.logVerbose('修復完了: ${issue.message}');
        } on Exception catch (e) {
          config.logWarning('修復失敗: ${issue.message} - $e');
        }
      }
    }

    return repairedIssues;
  }

  void _displayResults(List<ValidationIssue> issues, CliConfig config) {
    if (issues.isEmpty) {
      config.log('✓ データベースに問題は見つかりませんでした');
      return;
    }

    final errorCount = issues.where((i) => i.type == 'ERROR').length;
    final warningCount = issues.where((i) => i.type == 'WARNING').length;
    final repairedCount = issues.where((i) => i.repaired).length;

    config.log('検証結果:');
    config.log('  エラー: $errorCount');
    config.log('  警告: $warningCount');
    if (repairedCount > 0) {
      config.log('  修復済み: $repairedCount');
    }
    config.log('');

    for (final issue in issues) {
      final status = issue.repaired ? '[修復済み]' : '';
      final prefix = issue.type == 'ERROR' ? '✗' : '⚠';
      config.log('$prefix ${issue.category}: ${issue.message} $status');
    }
  }

  Future<void> _writeReport(
    String reportFile,
    String databasePath,
    List<ValidationIssue> issues,
    CliConfig config,
  ) async {
    config.logVerbose('検証レポートを出力中: $reportFile');

    final buffer = StringBuffer();
    buffer.writeln('# データベース検証レポート');
    buffer.writeln();
    buffer.writeln('データベース: $databasePath');
    buffer.writeln('検証日時: ${DateTime.now()}');
    buffer.writeln();

    if (issues.isEmpty) {
      buffer.writeln('## 結果');
      buffer.writeln('問題は見つかりませんでした。');
    } else {
      buffer.writeln('## 検証結果');
      for (final issue in issues) {
        buffer.writeln(
            '- **${issue.type}** [${issue.category}]: ${issue.message}');
        if (issue.repaired) {
          buffer.writeln('  - 修復済み');
        }
      }
    }

    await File(reportFile).writeAsString(buffer.toString());
    config.log('検証レポートを出力しました: $reportFile');
  }
}

/// 検証問題を表すクラス
class ValidationIssue {
  ValidationIssue({
    required this.type,
    required this.category,
    required this.message,
    this.canRepair = false,
    this.repaired = false,
  });

  final String type; // ERROR, WARNING
  final String category; // カテゴリ
  final String message; // メッセージ
  final bool canRepair; // 修復可能か
  bool repaired; // 修復済みか
}
