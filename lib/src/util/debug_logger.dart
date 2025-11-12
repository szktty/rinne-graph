/// Utility class for controlling debug logging
///
/// This class provides functionality to control debug log output.
/// Log output can be enabled/disabled through environment variables or command-line options.
class DebugLogger {
  /// Get singleton instance
  factory DebugLogger() => _instance;

  /// Internal constructor
  DebugLogger._internal();

  /// Singleton instance
  static final DebugLogger _instance = DebugLogger._internal();

  /// Debug log enabled/disabled state
  bool _enabled = false;

  /// Get debug log enabled/disabled state
  bool get isEnabled => _enabled;

  /// Enable debug logging
  void enable() {
    _enabled = true;
  }

  /// Disable debug logging
  void disable() {
    _enabled = false;
  }

  /// Set debug log enabled/disabled state
  // Allow positional parameter for internal setter method
  // ignore: avoid_positional_boolean_parameters, use_setters_to_change_properties
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Output debug log
  ///
  /// [message] Message to output
  void log(Object? message) {
    if (_enabled) {
      print(message);
    }
  }

  /// Output debug log (with category)
  ///
  /// [category] Log category
  /// [message] Message to output
  void logWithCategory(String category, Object? message) {
    if (_enabled) {
      print('[$category] $message');
    }
  }

  /// Output SQL query debug log
  ///
  /// [sql] SQL query
  /// [arguments] Query parameters
  void logSql(String sql, [List<dynamic>? arguments]) {
    if (_enabled) {
      print('SQL: $sql');
      if (arguments != null && arguments.isNotEmpty) {
        print('Arguments: $arguments');
      }
    }
  }

  /// Output traversal debug log
  ///
  /// [message] Message to output
  void logTraversal(Object? message) {
    if (_enabled) {
      print('Traversal: $message');
    }
  }
}

/// Global debug logger instance
final debugLogger = DebugLogger();
