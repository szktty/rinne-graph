import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Values Step Tests', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('values with specific keys', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Alice', 'age': 30, 'city': 'Tokyo'}));
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Bob', 'age': 25, 'city': 'Osaka'}));
      });

      // Get property values for specific keys
      final traversal = graph.traversal().V().values(['name', 'age']);
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify query is built correctly
      expect(results, isNotEmpty);
      // 4 results expected as 2 properties (name, age) are retrieved from each vertex
      expect(results.length, equals(4));
    });

    test('values with all properties', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Alice', 'age': 30}));
      });

      // Get all property values (empty key list)
      final traversal = graph.traversal().V().values([]);
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify query is built correctly
      expect(results, isNotEmpty);
      // 2 properties (name, age) are retrieved
      expect(results.length, equals(2));
    });

    test('values with edges', () async {
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

      // Get property values for edges
      final traversal = graph.traversal().E().values(['since', 'strength']);
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify query is built correctly
      expect(results, isNotEmpty);
      // 2 properties are retrieved from 1 edge
      expect(results.length, equals(2));
    });

    test('values with single key', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Alice', 'age': 30}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob', 'age': 25}));
      });

      // Get property values for single key
      final traversal = graph.traversal().V().values(['name']);
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify query is built correctly
      expect(results, isNotEmpty);
      // 1 property is retrieved from each of 2 vertices
      expect(results.length, equals(2));
    });
  });
}
