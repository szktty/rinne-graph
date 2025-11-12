import 'package:rinne_graph/src/model/model.dart';
import 'package:rinne_graph/src/traversal/traversal_intf.dart';

/// Traversal source for use within transactions
abstract class TransactionalTraversalSource {
  Traversal V([List<int>? ids]);
  Traversal E([List<int>? ids]);
}

/// Transaction interface for graph database
abstract class Transaction {
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]);

  Future<void> execute(
    String sql, [
    List<dynamic>? arguments,
  ]);

  Future<Vertex> createVertex(Vertex vertex);

  Future<Vertex?> getVertex(int vertexId);

  Future<void> updateVertex(Vertex vertex);

  Future<void> deleteVertex(int vertexId);

  Future<Edge> createEdge(Edge edge);

  Future<Edge?> getEdge(int edgeId);

  Future<void> updateEdge(Edge edge);

  Future<void> deleteEdge(int edgeId);

  Future<List<Vertex>> getVerticesWithLabel(String label);

  Future<List<Edge>> getEdgesWithLabel(String label);

  Future<List<Edge>> getEdgesFromVertex(int vertexId);

  Future<List<Edge>> getEdgesToVertex(int vertexId);

  Stream<Vertex> vertices({
    List<int>? ids,
    List<String>? labels,
  });

  Stream<Edge> edges({
    List<int>? ids,
    List<String>? labels,
    int? fromVertexId,
    int? toVertexId,
  });

  /// Get traversal source for using traversal API within transaction
  TransactionalTraversalSource traversal();
}
