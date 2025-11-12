import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Map Step Tests', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('map vertices with simple transformation', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Alice', 'age': 30}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob', 'age': 25}));
      });

      // Convert each row to string
      final traversal = graph.traversal().V().map((row) => 'Vertex: $row');

      final results = await traversal.toList();

      // Verify transformation is applied
      expect(results, hasLength(2));
      expect(
          results.every((r) => r is String && r.startsWith('Vertex:')), isTrue);
    });

    test('map with numeric transformation', () async {
      await graph.transaction((txn) async {
        await txn
            .createVertex(Vertex(labels: {'item'}, properties: {'value': 10}));
        await txn
            .createVertex(Vertex(labels: {'item'}, properties: {'value': 20}));
        await txn
            .createVertex(Vertex(labels: {'item'}, properties: {'value': 30}));
      });

      // Get hash code of each row
      final traversal = graph.traversal().V().map((row) => row.hashCode);

      final results = await traversal.toList();

      // Verify transformation is applied
      expect(results, hasLength(3));
      expect(results.every((r) => r is int), isTrue);
    });

    test('map with conditional transformation', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        await txn.createVertex(
            Vertex(labels: {'animal'}, properties: {'name': 'Fluffy'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
      });

      // Conditional transformation
      var counter = 0;
      final traversal = graph.traversal().V().map((row) {
        counter++;
        return counter.isOdd ? 'odd-$counter' : 'even-$counter';
      });

      final results = await traversal.toList();

      // Verify transformation is applied
      expect(results, hasLength(3));
      expect(results, contains('odd-1'));
      expect(results, contains('even-2'));
      expect(results, contains('odd-3'));
    });

    test('map with edges', () async {
      await graph.transaction((txn) async {
        final alice = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        final bob = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));

        await txn.createEdge(Edge(
            fromVertexId: alice.id!, toVertexId: bob.id!, labels: {'knows'}));
        await txn.createEdge(Edge(
            fromVertexId: bob.id!, toVertexId: alice.id!, labels: {'likes'}));
      });

      // Transform edges
      final traversal = graph.traversal().E().map((row) => 'Edge: $row');

      final results = await traversal.toList();

      // Verify transformation is applied
      expect(results, hasLength(2));
      expect(
          results.every((r) => r is String && r.startsWith('Edge:')), isTrue);
    });

    test('map combined with filter', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
        await txn.createVertex(
            Vertex(labels: {'animal'}, properties: {'name': 'Fluffy'}));
      });

      // Combine filter and transformation
      final traversal = graph
          .traversal()
          .V()
          .hasLabel(['person']).map((row) => 'Person: $row');

      final results = await traversal.toList();

      // Verify filter and transformation are applied
      expect(results, hasLength(2));
      expect(
          results.every((r) => r is String && r.startsWith('Person:')), isTrue);
    });

    test('map with multiple transformations', () async {
      await graph.transaction((txn) async {
        await txn
            .createVertex(Vertex(labels: {'item'}, properties: {'value': 5}));
      });

      // Apply multiple transformations consecutively
      final traversal = graph
          .traversal()
          .V()
          .map((row) => row.toString())
          .map((str) => 'Transformed: $str');

      final results = await traversal.toList();

      // Verify multiple transformations are applied
      expect(results, hasLength(1));
      expect(results.first, isA<String>());
      expect(results.first.toString().startsWith('Transformed:'), isTrue);
    });
  });
}
