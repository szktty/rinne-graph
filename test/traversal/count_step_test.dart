import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Count Step Tests', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('count vertices', () async {
      await graph.transaction((txn) async {
        // Create 3 vertices
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Charlie'}));
      });

      final traversal = graph.traversal().V().count();
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);
      expect(results, hasLength(1));
      expect(results.first['count_value'], equals(3));
    });

    test('count edges', () async {
      await graph.transaction((txn) async {
        final alice = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        final bob = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
        final charlie = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Charlie'}));

        await txn.createEdge(Edge(
            fromVertexId: alice.id!, toVertexId: bob.id!, labels: {'knows'}));
        await txn.createEdge(Edge(
            fromVertexId: bob.id!, toVertexId: charlie.id!, labels: {'knows'}));
      });

      final traversal = graph.traversal().E().count();
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);
      expect(results, hasLength(1));
      expect(results.first['count_value'], equals(2));
    });

    test('count filtered vertices', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Alice', 'age': 30}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob', 'age': 25}));
        await txn.createVertex(
            Vertex(labels: {'animal'}, properties: {'name': 'Fluffy'}));
      });

      final traversal = graph.traversal().V().hasLabel(['person']).count();
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);
      expect(results, hasLength(1));
      expect(results.first['count_value'], equals(2));
    });

    test('count empty result', () async {
      final traversal = graph.traversal().V().count();
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);
      expect(results, hasLength(1));
      expect(results.first['count_value'], equals(0));
    });

    test('count with property filter', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Alice', 'age': 30}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob', 'age': 25}));
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Charlie', 'age': 35}));
      });

      final traversal = graph.traversal().V().hasKey('age', 30).count();
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);
      expect(results, hasLength(1));
      expect(results.first['count_value'], equals(1));
    });
  });
}
