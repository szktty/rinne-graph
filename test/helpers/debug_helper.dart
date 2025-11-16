import 'package:rinne_graph/src/util/command_line_options.dart';
import 'package:rinne_graph/src/util/debug_logger.dart';

/// Initialize debug settings for test execution
///
/// Called during test execution to configure debug logging.
/// Enables/disables debug logging based on command line options.
///
/// Usage example:
/// ```dart
/// void main() {
///   initializeDebugSettings();
///   // Test code
/// }
/// ```
void initializeDebugSettings() {
  // Get debug flag from environment variable
  final debugFromEnv = bool.tryParse(
        const String.fromEnvironment('RINNE_DEBUG', defaultValue: 'false'),
      ) ??
      false;

  // Get debug flag from command line options
  final debugFromCli = commandLineOptions.isDebugEnabled;

  // Enable debug logging if either is true
  if (debugFromEnv || debugFromCli) {
    debugLogger.enable();
  } else {
    debugLogger.disable();
  }
}

/// Output debug log
///
/// [message] Message to output
void debugLog(Object? message) {
  debugLogger.log(message);
}

/// Output SQL query debug log
///
/// [sql] SQL query
/// [arguments] Query parameters
void debugSql(String sql, [List<dynamic>? arguments]) {
  debugLogger.logSql(sql, arguments);
}

/// Output traversal debug log
///
/// [message] Message to output
void debugTraversal(Object? message) {
  debugLogger.logTraversal(message);
}
