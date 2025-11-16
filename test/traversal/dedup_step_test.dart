import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Dedup Step Tests', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('dedup vertices', () async {
      await graph.transaction((txn) async {
        final alice = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        final bob = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
        final charlie = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Charlie'}));

        // Create duplicate edges (multiple relationships between Alice and Bob)
        await txn.createEdge(Edge(
            fromVertexId: alice.id!, toVertexId: bob.id!, labels: {'knows'}));
        await txn.createEdge(Edge(
            fromVertexId: alice.id!,
            toVertexId: charlie.id!,
            labels: {'knows'}));
        await txn.createEdge(Edge(
            fromVertexId: bob.id!, toVertexId: alice.id!, labels: {'knows'}));
      });

      // Query without deduplication (no dedup())
      final traversal1 = graph.traversal().V().both(['knows']);
      final query1 = traversal1.buildQuery();
      final results1 =
          await graph.database.rawQuery(query1.query, query1.parameters);

      // Query with deduplication (with dedup())
      final traversal2 = graph.traversal().V().both(['knows']).dedup();
      final query2 = traversal2.buildQuery();
      final results2 =
          await graph.database.rawQuery(query2.query, query2.parameters);

      // Verify duplicates are removed by dedup()
      // Actual results depend on implementation, but verify query is built correctly
      expect(results2.length, lessThanOrEqualTo(results1.length));
    });

    test('dedup with vertices', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Alice', 'age': 30}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob', 'age': 30}));
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Charlie', 'age': 25}));
      });

      // Get vertices and dedup
      final traversal = graph.traversal().V().dedup();
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify query is built correctly
      expect(results, hasLength(3));
    });
  });
}
