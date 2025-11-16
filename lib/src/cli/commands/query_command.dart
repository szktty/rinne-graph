import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/cli/commands/base_command.dart';
import 'package:rinne_graph/src/cli/config/cli_config.dart';
import 'package:rinne_graph/src/graph/graph_impl.dart';

/// クエリ実行コマンド
class QueryCommand extends CliCommand {
  QueryCommand() : super('query', 'トラバーサルクエリを実行');

  @override
  void setupArguments() {
    argParser.addOption(
      'database',
      help: '対象データベースファイル（必須）',
      mandatory: true,
    );
    argParser.addOption(
      'traversal',
      abbr: 't',
      help: 'トラバーサルクエリ（必須）',
      mandatory: true,
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: '結果出力ファイル',
    );
    argParser.addOption(
      'format',
      help: '出力形式（json/csv/text）',
      allowed: ['json', 'csv', 'text'],
      defaultsTo: 'json',
    );
    argParser.addOption(
      'limit',
      help: '結果件数制限',
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
    final traversalQuery = results['traversal'] as String;
    final outputFile = results['output'] as String?;
    final format = results['format'] as String;
    final limitStr = results['limit'] as String?;

    final limit = limitStr != null ? int.parse(limitStr) : config.defaultLimit;

    try {
      config.logVerbose('データベースを開いています: $databasePath');
      // 相対パスを絶対パスに解決
      final fullPath = _resolveAbsolutePath(databasePath);
      final graph = await GraphImpl.openWithAbsolutePath(fullPath);

      try {
        config.logVerbose('クエリを実行中: $traversalQuery');

        // TODO(szktty): Implement full traversal query parsing and execution.
        final results =
            await _executeQuery(graph, traversalQuery, limit, config);

        // 結果の出力
        if (outputFile != null) {
          await _writeResults(outputFile, results, format, config);
          config.log('結果を出力しました: $outputFile');
        } else {
          _printResults(results, format, config);
        }

        config.log('クエリが正常に実行されました（${results.length}件）');
      } finally {
        await graph.close();
      }
    } on Exception catch (e) {
      config.logError('クエリの実行に失敗しました: $e');
      exit(1);
    }
  }

  Future<List<dynamic>> _executeQuery(
    Graph graph,
    String query,
    int limit,
    CliConfig config,
  ) async {
    // 簡易的なクエリ解析
    if (query.startsWith('g.V()')) {
      return _executeVertexQuery(graph, query, limit, config);
    } else if (query.startsWith('g.E()')) {
      return _executeEdgeQuery(graph, query, limit, config);
    } else {
      throw ArgumentError('サポートされていないクエリ形式: $query');
    }
  }

  Future<List<dynamic>> _executeVertexQuery(
    Graph graph,
    String query,
    int limit,
    CliConfig config,
  ) async {
    config.logVerbose('頂点クエリを実行中...');

    final g = graph.traversal();
    var traversal = g.V();

    // 簡易的なクエリ解析
    if (query.contains('.hasLabel(')) {
      final labelMatch = RegExp(r"\.hasLabel\('([^']+)'\)").firstMatch(query);
      if (labelMatch != null) {
        final label = labelMatch.group(1)!;
        traversal = traversal.hasLabel([label]);
        config.logVerbose('ラベルフィルタを適用: $label');
      }
    }

    if (query.contains('.values(')) {
      final valuesMatch = RegExp(r"\.values\('([^']+)'\)").firstMatch(query);
      if (valuesMatch != null) {
        final property = valuesMatch.group(1)!;
        final results = await traversal.values([property]).toList();
        return results.take(limit).toList();
      }
    }

    if (query.contains('.valueMap()')) {
      final results = await traversal.valueMap().toList();
      return results.take(limit).toList();
    }

    // デフォルトは頂点そのものを返す
    final results = await traversal.toList();
    return results.take(limit).toList();
  }

  Future<List<dynamic>> _executeEdgeQuery(
    Graph graph,
    String query,
    int limit,
    CliConfig config,
  ) async {
    config.logVerbose('エッジクエリを実行中...');

    final g = graph.traversal();
    var traversal = g.E();

    // 簡易的なクエリ解析
    if (query.contains('.hasLabel(')) {
      final labelMatch = RegExp(r"\.hasLabel\('([^']+)'\)").firstMatch(query);
      if (labelMatch != null) {
        final label = labelMatch.group(1)!;
        traversal = traversal.hasLabel([label]);
        config.logVerbose('ラベルフィルタを適用: $label');
      }
    }

    final results = await traversal.toList();
    return results.take(limit).toList();
  }

  Future<void> _writeResults(
    String outputFile,
    List<dynamic> results,
    String format,
    CliConfig config,
  ) async {
    final file = File(outputFile);

    switch (format) {
      case 'json':
        final jsonData = const JsonEncoder.withIndent('  ').convert(results);
        await file.writeAsString(jsonData);
      case 'csv':
        await _writeCsvResults(file, results, config);
      case 'text':
        await _writeTextResults(file, results, config);
    }
  }

  Future<void> _writeCsvResults(
      File file, List<dynamic> results, CliConfig config) async {
    if (results.isEmpty) {
      await file.writeAsString('');
      return;
    }

    final buffer = StringBuffer();

    // ヘッダーの生成（最初の結果から推測）
    final first = results.first;
    if (first is Map<String, dynamic>) {
      buffer.writeln(first.keys.join(','));

      // データ行の出力
      for (final result in results) {
        if (result is Map<String, dynamic>) {
          final values =
              result.values.map((v) => _escapeCsvValue(v.toString()));
          buffer.writeln(values.join(','));
        }
      }
    } else {
      // 単純な値の場合
      buffer.writeln('value');
      for (final result in results) {
        buffer.writeln(_escapeCsvValue(result.toString()));
      }
    }

    await file.writeAsString(buffer.toString());
  }

  String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<void> _writeTextResults(
      File file, List<dynamic> results, CliConfig config) async {
    final buffer = StringBuffer();

    for (var i = 0; i < results.length; i++) {
      buffer.writeln('[$i] ${results[i]}');
    }

    await file.writeAsString(buffer.toString());
  }

  void _printResults(List<dynamic> results, String format, CliConfig config) {
    switch (format) {
      case 'json':
        print(const JsonEncoder.withIndent('  ').convert(results));
      case 'text':
        for (var i = 0; i < results.length; i++) {
          config.log('[$i] ${results[i]}');
        }
      case 'csv':
        // CSV形式での標準出力は複雑なので、JSONで代替
        print(const JsonEncoder.withIndent('  ').convert(results));
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
