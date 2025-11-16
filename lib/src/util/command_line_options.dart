/// Utility class for parsing command-line options
///
/// This class provides functionality to parse command-line options and control
/// application behavior.
class CommandLineOptions {
  /// Get singleton instance
  factory CommandLineOptions() => _instance;

  /// Internal constructor
  CommandLineOptions._internal();

  /// Singleton instance
  static final CommandLineOptions _instance = CommandLineOptions._internal();

  /// Map to hold option values
  final Map<String, dynamic> _options = {};

  /// Parse options
  ///
  /// [args] Command-line arguments
  void parse(List<String> args) {
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg.startsWith('--')) {
        final option = arg.substring(2);
        if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
          _options[option] = args[i + 1];
          i++;
        } else {
          _options[option] = true;
        }
      } else if (arg.startsWith('-')) {
        final option = arg.substring(1);
        if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
          _options[option] = args[i + 1];
          i++;
        } else {
          _options[option] = true;
        }
      }
    }
  }

  /// Get option value
  ///
  /// [name] Option name
  /// [defaultValue] Default value
  T getOption<T>(String name, T defaultValue) {
    return _options.containsKey(name) ? _options[name] as T : defaultValue;
  }

  /// Check if option is specified
  ///
  /// [name] Option name
  bool hasOption(String name) {
    return _options.containsKey(name);
  }

  /// Check if debug logging is enabled
  bool get isDebugEnabled {
    return getOption<bool>('debug', false) ||
        getOption<bool>('d', false) ||
        getOption<bool>('verbose', false) ||
        getOption<bool>('v', false);
  }
}

/// Global command-line options instance
final commandLineOptions = CommandLineOptions();
