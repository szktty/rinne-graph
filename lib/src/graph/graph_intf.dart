import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/graph/graph_impl.dart';

abstract class Graph {
  static Future<Graph> open(String path) async => GraphImpl.open(path);

  static Future<Graph> openInMemory() async => GraphImpl.openInMemory();

  static Graph fromDatabase(Database database) =>
      GraphImpl(database, inMemory: false);

  Database get database;

  Future<void> close();

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action);

  TraversalSource traversal();

  Future<GraphStatistics> getStatistics();

  // Index Management API

  /// Creates a property index.
  ///
  /// [propertyKey] The property key to create an index on.
  /// [entityType] The entity type to create the index on (default: vertices).
  /// [indexName] The name of the index (auto-generated if omitted).
  Future<void> createPropertyIndex(
    String propertyKey, {
    IndexEntityType entityType = IndexEntityType.vertices,
    String? indexName,
  });

  /// Drops a property index.
  ///
  /// [indexName] The name of the index to drop.
  Future<void> dropPropertyIndex(String indexName);

  /// Gets a list of all created property indexes.
  Future<List<PropertyIndexInfo>> listPropertyIndexes();

  /// Checks if an index exists for the specified property.
  ///
  /// [propertyKey] The property key to check.
  /// [entityType] The entity type to check (default: vertices).
  Future<bool> hasPropertyIndex(
    String propertyKey, {
    IndexEntityType entityType = IndexEntityType.vertices,
  });

  // Event Management API

  /// Gets the event manager.
  GraphEventManager get eventManager;

  /// Registers a label event listener (convenience method).
  void onLabelEvent(GraphEventCallback<LabelEvent> callback) {
    eventManager.addEventListener<LabelEvent>(callback);
  }

  /// Registers a vertex label event listener.
  void onVertexLabelEvent(GraphEventCallback<VertexLabelEvent> callback) {
    eventManager.addEventListener<VertexLabelEvent>(callback);
  }

  /// Registers an edge label event listener.
  void onEdgeLabelEvent(GraphEventCallback<EdgeLabelEvent> callback) {
    eventManager.addEventListener<EdgeLabelEvent>(callback);
  }

  // Label Analysis API

  /// Gets the label analyzer.
  ///
  /// Returns a [LabelAnalyzer] instance for detailed analysis of label usage,
  /// combinations, and relationships.
  ///
  /// Example:
  /// ```dart
  /// final analyzer = graph.labelAnalyzer;
  /// final report = await analyzer.generateReport();
  /// final popularLabels = await analyzer.findPopularLabels();
  /// ```
  LabelAnalyzer get labelAnalyzer;

  // Data Clear API

  /// Clears all data in the database.
  ///
  /// Deletes all vertices, edges, properties, and labels.
  /// This is executed within a transaction and will be rolled back on error.
  Future<void> clearAll();

  /// Clears all vertices and their related data.
  ///
  /// Deletes all vertices, vertex properties, vertex labels, and their associated edges.
  Future<void> clearVertices();

  /// Clears all edges and their related data.
  ///
  /// Deletes all edges, edge properties, and edge labels.
  /// Vertices are not deleted.
  Future<void> clearEdges();
}
