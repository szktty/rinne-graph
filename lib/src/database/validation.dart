/// Class representing database validation results
class DatabaseValidationResult {
  const DatabaseValidationResult({
    required this.isValid,
    required this.isInitialized,
    required this.missingTables,
    required this.missingIndexes,
    required this.missingTriggers,
    required this.schemaVersion,
    this.errorMessage,
  });

  /// Whether the database is valid
  final bool isValid;

  /// Whether the database is initialized for this library
  final bool isInitialized;

  /// List of missing tables
  final List<String> missingTables;

  /// List of missing indexes
  final List<String> missingIndexes;

  /// List of missing triggers
  final List<String> missingTriggers;

  /// Schema version (null if not available)
  final int? schemaVersion;

  /// Error message (if any error occurred)
  final String? errorMessage;

  /// Whether the database is fully initialized
  bool get isFullyInitialized =>
      isValid &&
      isInitialized &&
      missingTables.isEmpty &&
      missingIndexes.isEmpty &&
      missingTriggers.isEmpty;

  /// Get detailed description of validation results
  String get description {
    if (isFullyInitialized) {
      return 'Database is properly initialized (version: $schemaVersion)';
    }

    final issues = <String>[];

    if (!isValid) {
      issues.add('Database file is invalid');
    }

    if (!isInitialized) {
      issues.add('Not initialized for RinneGraph');
    }

    if (missingTables.isNotEmpty) {
      issues.add('Missing tables: ${missingTables.join(', ')}');
    }

    if (missingIndexes.isNotEmpty) {
      issues.add('Missing indexes: ${missingIndexes.join(', ')}');
    }

    if (missingTriggers.isNotEmpty) {
      issues.add('Missing triggers: ${missingTriggers.join(', ')}');
    }

    if (errorMessage != null) {
      issues.add('Error: $errorMessage');
    }

    return issues.join('\n');
  }

  @override
  String toString() => 'DatabaseValidationResult(isValid: $isValid, '
      'isInitialized: $isInitialized, '
      'missingTables: $missingTables, '
      'missingIndexes: $missingIndexes, '
      'missingTriggers: $missingTriggers, '
      'schemaVersion: $schemaVersion, '
      'errorMessage: $errorMessage)';
}

/// Detailed settings for database validation
class DatabaseValidationOptions {
  const DatabaseValidationOptions({
    this.checkTables = true,
    this.checkIndexes = true,
    this.checkTriggers = true,
    this.checkSchemaVersion = true,
    this.strictMode = false,
  });

  /// Whether to check table existence
  final bool checkTables;

  /// Whether to check index existence
  final bool checkIndexes;

  /// Whether to check trigger existence
  final bool checkTriggers;

  /// Whether to check schema version
  final bool checkSchemaVersion;

  /// Strict mode (all elements must match exactly)
  final bool strictMode;

  /// Default validation options
  static const DatabaseValidationOptions defaultOptions =
      DatabaseValidationOptions();

  /// Options for basic validation only
  static const DatabaseValidationOptions basic = DatabaseValidationOptions(
    checkIndexes: false,
    checkTriggers: false,
    checkSchemaVersion: false,
  );

  /// Options for strict validation
  static const DatabaseValidationOptions strict = DatabaseValidationOptions(
    strictMode: true,
  );
}
