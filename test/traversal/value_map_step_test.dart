import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('ValueMap Step Tests', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('valueMap with specific keys', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Alice', 'age': 30, 'city': 'Tokyo'}));
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Bob', 'age': 25, 'city': 'Osaka'}));
      });

      // Get property map for specific keys
      final traversal = graph.traversal().V().valueMap(['name', 'age']);
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify query is built correctly
      expect(results, isNotEmpty);
    });

    test('valueMap with all properties', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Alice', 'age': 30}));
      });

      // Get map of all properties (empty key list)
      final traversal = graph.traversal().V().valueMap([]);
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify query is built correctly
      expect(results, isNotEmpty);
    });

    test('valueMap with edges', () async {
      await graph.transaction((txn) async {
        final alice = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        final bob = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));

        await txn.createEdge(Edge(
            fromVertexId: alice.id!,
            toVertexId: bob.id!,
            labels: {'knows'},
            properties: {'since': 2020, 'strength': 'strong'}));
      });

      // Get property map for edges
      final traversal = graph.traversal().E().valueMap(['since', 'strength']);
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify query is built correctly
      expect(results, isNotEmpty);
    });
  });
}
