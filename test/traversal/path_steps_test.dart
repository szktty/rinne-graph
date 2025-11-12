import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Path Steps Tests', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('as() step basic functionality', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
      });

      // as() step does nothing in basic implementation, but verify query is built correctly
      final traversal = graph.traversal().V().as('people');
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);
      expect(results, hasLength(2));
    });

    test('select() step basic functionality', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
      });

      // select() step does nothing in basic implementation, but verify query is built correctly
      final traversal = graph.traversal().V().as('people').select(['people']);
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);
      expect(results, hasLength(2));
    });

    test('as() and select() combined', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        await txn.createVertex(
            Vertex(labels: {'animal'}, properties: {'name': 'Fluffy'}));
      });

      // Basic test combining multiple as() and select()
      final traversal = graph
          .traversal()
          .V()
          .hasLabel(['person'])
          .as('people')
          .select(['people']);
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);
      expect(results, hasLength(1));
    });
  });
}
