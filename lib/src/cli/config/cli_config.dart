import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Configuration management class for CLI tool
class CliConfig {
  CliConfig();

  // Default settings
  String encoding = 'utf-8';
  String onError = 'warn';
  bool verbose = false;
  bool quiet = false;
  bool validation = true;
  bool append = false;
  int batchSize = 1000;
  bool includeMetadata = true;
  bool prettyJson = true;
  int defaultLimit = 1000;
  int timeout = 30;

  /// Load default configuration
  Future<void> loadDefault() async {
    final configDir = await _getConfigDirectory();
    final configFile = File(path.join(configDir, 'config.yaml'));

    if (configFile.existsSync()) {
      await loadFromFile(configFile.path);
    }
  }

  /// Load configuration from specified file
  Future<void> loadFromFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('Configuration file not found: $filePath');
    }

    final content = await file.readAsString();
    final yaml = loadYaml(content) as Map<String, dynamic>?;

    if (yaml == null) return;

    // Default settings
    final defaultConfig = yaml['default'] as Map<String, dynamic>?;
    if (defaultConfig != null) {
      encoding = defaultConfig['encoding'] as String? ?? encoding;
      onError = defaultConfig['on_error'] as String? ?? onError;
      verbose = defaultConfig['verbose'] as bool? ?? verbose;
    }

    // Import settings
    final importConfig = yaml['import'] as Map<String, dynamic>?;
    if (importConfig != null) {
      validation = importConfig['validation'] as bool? ?? validation;
      append = importConfig['append'] as bool? ?? append;
      batchSize = importConfig['batch_size'] as int? ?? batchSize;
    }

    // Export settings
    final exportConfig = yaml['export'] as Map<String, dynamic>?;
    if (exportConfig != null) {
      includeMetadata =
          exportConfig['include_metadata'] as bool? ?? includeMetadata;
      prettyJson = exportConfig['pretty_json'] as bool? ?? prettyJson;
    }

    // Query settings
    final queryConfig = yaml['query'] as Map<String, dynamic>?;
    if (queryConfig != null) {
      defaultLimit = queryConfig['default_limit'] as int? ?? defaultLimit;
      timeout = queryConfig['timeout'] as int? ?? timeout;
    }
  }

  /// Save configuration to file
  Future<void> saveToFile(String filePath) async {
    final config = {
      'default': {
        'encoding': encoding,
        'on_error': onError,
        'verbose': verbose,
      },
      'import': {
        'validation': validation,
        'append': append,
        'batch_size': batchSize,
      },
      'export': {
        'include_metadata': includeMetadata,
        'pretty_json': prettyJson,
      },
      'query': {
        'default_limit': defaultLimit,
        'timeout': timeout,
      },
    };

    final file = File(filePath);
    await file.parent.create(recursive: true);

    // Output as YAML (simple implementation)
    final buffer = StringBuffer();
    _writeYamlMap(buffer, config, 0);

    await file.writeAsString(buffer.toString());
  }

  void _writeYamlMap(
      StringBuffer buffer, Map<String, dynamic> map, int indent) {
    final indentStr = '  ' * indent;
    for (final entry in map.entries) {
      buffer.writeln('$indentStr${entry.key}:');
      if (entry.value is Map<String, dynamic>) {
        _writeYamlMap(buffer, entry.value as Map<String, dynamic>, indent + 1);
      } else {
        buffer.writeln('$indentStr  ${entry.value}');
      }
    }
  }

  /// Enable verbose logging
  // Allow positional parameters for internal setter method
  // ignore: avoid_positional_boolean_parameters
  void setVerbose(bool value) {
    verbose = value;
    if (value) quiet = false;
  }

  /// Enable quiet mode
  // Allow positional parameters for internal setter method
  // ignore: avoid_positional_boolean_parameters
  void setQuiet(bool value) {
    quiet = value;
    if (value) verbose = false;
  }

  /// Get configuration directory path
  Future<String> _getConfigDirectory() async {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return path.join(homeDir, '.rinne');
  }

  /// Create default configuration file
  Future<void> createDefaultConfig() async {
    final configDir = await _getConfigDirectory();
    final configFile = path.join(configDir, 'config.yaml');
    await saveToFile(configFile);
  }

  /// Log output
  void log(String message) {
    if (!quiet) {
      print(message);
    }
  }

  /// Verbose log output
  void logVerbose(String message) {
    if (verbose && !quiet) {
      print('[VERBOSE] $message');
    }
  }

  /// Error log output
  void logError(String message) {
    stderr.writeln('[ERROR] $message');
  }

  /// Warning log output
  void logWarning(String message) {
    if (!quiet) {
      stderr.writeln('[WARNING] $message');
    }
  }
}
