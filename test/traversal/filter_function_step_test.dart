import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Filter Function Step Tests', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('filter vertices with true condition', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Alice', 'age': 30}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob', 'age': 25}));
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Charlie', 'age': 35}));
      });

      // Filter that passes all results
      final traversal = graph.traversal().V().filter((row) => true);

      final results = await traversal.toList();

      // Verify filter function is applied and all results are returned
      expect(results, hasLength(3));
    });

    test('filter vertices with false condition', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
      });

      // Filter that excludes all results
      final traversal = graph.traversal().V().filter((row) => false);

      final results = await traversal.toList();

      // Verify all results are excluded
      expect(results, isEmpty);
    });

    test('filter with conditional logic', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        await txn.createVertex(
            Vertex(labels: {'animal'}, properties: {'name': 'Fluffy'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
      });

      // Conditional filter (pass only odd-numbered rows)
      var counter = 0;
      final traversal = graph.traversal().V().filter((row) {
        counter++;
        return counter.isOdd; // Pass only odd-numbered
      });

      final results = await traversal.toList();

      // Verify 2 of 3 vertices pass (1st and 3rd, which are odd-numbered)
      expect(results, hasLength(2));
    });

    test('filter with edges', () async {
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
        await txn.createEdge(Edge(
            fromVertexId: alice.id!,
            toVertexId: charlie.id!,
            labels: {'likes'}));
      });

      // Filter half of edges
      var edgeCounter = 0;
      final traversal = graph.traversal().E().filter((row) {
        edgeCounter++;
        return edgeCounter <= 2; // Pass only first 2 edges
      });

      final results = await traversal.toList();

      // Verify first 2 of 3 edges pass
      expect(results, hasLength(2));
    });

    test('filter combined with other steps', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
        await txn.createVertex(
            Vertex(labels: {'animal'}, properties: {'name': 'Fluffy'}));
      });

      // Combine hasLabel() and filter()
      final traversal =
          graph.traversal().V().hasLabel(['person']).filter((row) => true);

      final results = await traversal.toList();

      // Verify 2 vertices with person label pass
      expect(results, hasLength(2));
    });
  });
}
