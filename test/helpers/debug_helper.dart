import 'package:logging/logging.dart';
import 'package:rinne_graph/src/util/command_line_options.dart';

void initializeDebugSettings() {
  final debugFromEnv = bool.tryParse(
        const String.fromEnvironment('RINNE_DEBUG', defaultValue: 'false'),
      ) ??
      false;

  final debugFromCli = commandLineOptions.isDebugEnabled;

  if (debugFromEnv || debugFromCli) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('[${record.level.name}] ${record.loggerName}: ${record.message}');
    });
  }
}

void debugLog(Object? message) {
  Logger('rinne_graph').fine(message?.toString());
}

void debugSql(String sql, [List<dynamic>? arguments]) {
  Logger('rinne_graph.database').fine(
    'SQL: $sql${arguments != null && arguments.isNotEmpty ? '\nArguments: $arguments' : ''}',
  );
}

void debugTraversal(Object? message) {
  Logger('rinne_graph.traversal').fine(message?.toString());
}
