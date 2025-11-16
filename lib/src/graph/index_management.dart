/// Class and enum definitions for index management
library;

import 'package:meta/meta.dart';

/// Target entity type for index creation
enum IndexEntityType {
  /// Vertex properties only
  vertices,

  /// Edge properties only
  edges,

  /// Both (future implementation)
  both,
}

/// Property index information
@immutable
class PropertyIndexInfo {
  const PropertyIndexInfo({
    required this.name,
    required this.propertyKey,
    required this.entityType,
  });

  /// Index name
  final String name;

  /// Property key
  final String propertyKey;

  /// Target entity type
  final IndexEntityType entityType;

  @override
  String toString() {
    return 'PropertyIndexInfo(name: $name, propertyKey: $propertyKey, entityType: $entityType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PropertyIndexInfo &&
        other.name == name &&
        other.propertyKey == propertyKey &&
        other.entityType == entityType;
  }

  @override
  int get hashCode {
    return Object.hash(name, propertyKey, entityType);
  }
}

/// Utility class for index management
class IndexManagementUtils {
  /// Auto-generate index name
  static String generateIndexName(
      String propertyKey, IndexEntityType entityType) {
    switch (entityType) {
      case IndexEntityType.vertices:
        return 'idx_user_v_$propertyKey';
      case IndexEntityType.edges:
        return 'idx_user_e_$propertyKey';
      case IndexEntityType.both:
        return 'idx_user_both_$propertyKey';
    }
  }

  /// Generate index creation SQL
  static String generateCreateIndexSQL(
    String indexName,
    String propertyKey,
    IndexEntityType entityType,
  ) {
    switch (entityType) {
      case IndexEntityType.vertices:
        return '''
          CREATE INDEX $indexName ON vertex_properties(value)
          WHERE key = ?
        ''';
      case IndexEntityType.edges:
        return '''
          CREATE INDEX $indexName ON edge_properties(value)
          WHERE key = ?
        ''';
      case IndexEntityType.both:
        throw UnimplementedError('IndexEntityType.both is not yet implemented');
    }
  }

  /// Generate index deletion SQL
  static String generateDropIndexSQL(String indexName) {
    return 'DROP INDEX IF EXISTS $indexName';
  }

  /// Check property key validity
  static bool isValidPropertyKey(String propertyKey) {
    if (propertyKey.isEmpty) return false;
    if (propertyKey.contains("'") || propertyKey.contains('"')) return false;
    return true;
  }

  /// Check index name validity
  static bool isValidIndexName(String indexName) {
    if (indexName.isEmpty) return false;
    if (indexName.length > 64) return false; // SQLite limitation
    if (indexName.contains(' ') ||
        indexName.contains("'") ||
        indexName.contains('"')) {
      return false;
    }
    return true;
  }
}
