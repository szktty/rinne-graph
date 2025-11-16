import 'package:rinne_graph/src/database/database.dart';
import 'package:rinne_graph/src/graph/event_manager.dart';
import 'package:rinne_graph/src/graph/graph_intf.dart';
import 'package:rinne_graph/src/graph/graph_statistics.dart';
import 'package:rinne_graph/src/graph/index_management.dart';
import 'package:rinne_graph/src/graph/label_analyzer.dart';
import 'package:rinne_graph/src/traversal/sql_traversal/sql_traversal_impl.dart';
import 'package:rinne_graph/src/traversal/traversal_intf.dart';

final class GraphImpl extends Graph {
  GraphImpl(this.database, {required this.inMemory, this.databasePath}) {
    // Set Graph object for transaction-aware traversal
    database.setGraph(this);
  }

  @override
  final Database database;

  final String? databasePath;
  final bool inMemory;

  @override
  GraphEventManager get eventManager => database.eventManager;

  // Label analysis functionality (lazy initialization)
  LabelAnalyzer? _labelAnalyzer;

  @override
  LabelAnalyzer get labelAnalyzer {
    _labelAnalyzer ??= LabelAnalyzer(this);
    return _labelAnalyzer!;
  }

  static Future<Graph> open(String path) async {
    final db = await DatabaseManager().openFile(path);
    return GraphImpl(db, inMemory: false, databasePath: path);
  }

  static Future<Graph> openWithAbsolutePath(String absolutePath) async {
    final db = await DatabaseManager().openFileWithAbsolutePath(absolutePath);
    return GraphImpl(db, inMemory: false, databasePath: absolutePath);
  }

  static Future<Graph> openInMemory() async {
    final db = await DatabaseManager().openInMemory();
    return GraphImpl(db, inMemory: true);
  }

  @override
  Future<void> close() async {
    await database.close();
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) =>
      database.transaction(action);

  @override
  TraversalSource traversal() {
    return SqlTraversalSourceImpl(this);
  }

  @override
  Future<GraphStatistics> getStatistics() async {
    final stats = await transaction((txn) async {
      final totalVerticesResult =
          await txn.rawQuery('SELECT COUNT(*) as count FROM vertices');
      final totalVertices = totalVerticesResult[0]['count'] as int;

      final totalEdgesResult =
          await txn.rawQuery('SELECT COUNT(*) as count FROM edges');
      final totalEdges = totalEdgesResult[0]['count'] as int;

      final vertexLabelCounts = await txn.rawQuery('''
      SELECT label, COUNT(*) as count FROM vertex_labels GROUP BY label
    ''');

      final edgeLabelCounts = await txn.rawQuery('''
      SELECT label, COUNT(*) as count FROM edge_labels GROUP BY label
    ''');

      final vertexPropertyCounts = await txn.rawQuery('''
      SELECT key, COUNT(*) as count FROM vertex_properties GROUP BY key
    ''');

      final edgePropertyCounts = await txn.rawQuery('''
      SELECT key, COUNT(*) as count FROM edge_properties GROUP BY key
    ''');

      final lastModified = DateTime.now();

      return GraphStatistics(
        databasePath: databasePath ?? '<in-memory>',
        isInMemory: inMemory,
        totalVertices: totalVertices,
        totalEdges: totalEdges,
        vertexLabelCounts: Map.fromEntries(
          vertexLabelCounts
              .map((e) => MapEntry(e['label'] as String, e['count'] as int)),
        ),
        edgeLabelCounts: Map.fromEntries(
          edgeLabelCounts
              .map((e) => MapEntry(e['label'] as String, e['count'] as int)),
        ),
        vertexPropertyCounts: Map.fromEntries(
          vertexPropertyCounts
              .map((e) => MapEntry(e['key'] as String, e['count'] as int)),
        ),
        edgePropertyCounts: Map.fromEntries(
          edgePropertyCounts
              .map((e) => MapEntry(e['key'] as String, e['count'] as int)),
        ),
        lastModified: lastModified,
      );
    });

    return stats;
  }

  // Index management API implementation

  @override
  Future<void> createPropertyIndex(
    String propertyKey, {
    IndexEntityType entityType = IndexEntityType.vertices,
    String? indexName,
  }) async {
    // Input validation
    if (!IndexManagementUtils.isValidPropertyKey(propertyKey)) {
      throw ArgumentError('Invalid property key: $propertyKey');
    }

    final actualIndexName = indexName ??
        IndexManagementUtils.generateIndexName(propertyKey, entityType);

    if (!IndexManagementUtils.isValidIndexName(actualIndexName)) {
      throw ArgumentError('Invalid index name: $actualIndexName');
    }

    // TODO(szktty): Implement full property index creation functionality.
    throw UnimplementedError(
        'createPropertyIndex is not yet fully implemented');
  }

  @override
  Future<void> dropPropertyIndex(String indexName) async {
    // Input validation
    if (!IndexManagementUtils.isValidIndexName(indexName)) {
      throw ArgumentError('Invalid index name: $indexName');
    }

    // TODO(szktty): Implement full property index dropping functionality.
    throw UnimplementedError('dropPropertyIndex is not yet fully implemented');
  }

  @override
  Future<List<PropertyIndexInfo>> listPropertyIndexes() async {
    // TODO(szktty): Implement full property index listing functionality.
    return <PropertyIndexInfo>[];
  }

  @override
  Future<bool> hasPropertyIndex(
    String propertyKey, {
    IndexEntityType entityType = IndexEntityType.vertices,
  }) async {
    // Input validation
    if (!IndexManagementUtils.isValidPropertyKey(propertyKey)) {
      throw ArgumentError('Invalid property key: $propertyKey');
    }

    // TODO(szktty): Implement full property index checking functionality.
    return false;
  }

  @override
  Future<void> clearAll() async {
    await transaction((txn) async {
      // Delete edges (delete first due to foreign key constraints)
      await txn.execute('DELETE FROM edge_properties');
      await txn.execute('DELETE FROM edge_labels');
      await txn.execute('DELETE FROM edges');

      // Delete vertices
      await txn.execute('DELETE FROM vertex_properties');
      await txn.execute('DELETE FROM vertex_labels');
      await txn.execute('DELETE FROM vertices');
    });
  }

  @override
  Future<void> clearVertices() async {
    await transaction((txn) async {
      // Also delete edges related to vertices (due to foreign key constraints)
      await txn.execute('DELETE FROM edge_properties');
      await txn.execute('DELETE FROM edge_labels');
      await txn.execute('DELETE FROM edges');

      // Delete vertices
      await txn.execute('DELETE FROM vertex_properties');
      await txn.execute('DELETE FROM vertex_labels');
      await txn.execute('DELETE FROM vertices');
    });
  }

  @override
  Future<void> clearEdges() async {
    await transaction((txn) async {
      // Delete edges only
      await txn.execute('DELETE FROM edge_properties');
      await txn.execute('DELETE FROM edge_labels');
      await txn.execute('DELETE FROM edges');
    });
  }
}
