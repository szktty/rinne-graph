import 'package:rinne_graph/src/util/command_line_options.dart';
import 'package:rinne_graph/src/util/debug_logger.dart';

import 'helpers/debug_helper.dart';

/// Entry point for test execution
///
/// Parses command line options and initializes debug settings.
///
/// Usage examples:
/// ```dart
/// dart test --debug
/// dart test -d
/// dart test --verbose
/// dart test -v
/// ```
void main(List<String> args) {
  // Parse command line options
  commandLineOptions.parse(args);

  // Initialize debug settings
  initializeDebugSettings();

  // Display message if debug mode is enabled
  if (debugLogger.isEnabled) {
    print('Debug mode enabled');
  }

  // Run tests
  // Note: This file is not executed directly,
  // but each test file is executed individually by the test package.
  // This file is for common settings before test execution.
}
