import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('hasAnyKeyContains()', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('returns vertices where any property contains the value', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Alice Johnson', 'email': 'alice@example.com'}));
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Bob Smith', 'email': 'bob@company.com'}));
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Charlie Brown', 'email': 'charlie@example.com'}));
      });

      // "Alice" is in name → 1 result
      final results1 =
          await graph.traversal().V().hasAnyKeyContains('Alice').toList();
      expect(results1, hasLength(1));

      // "example" is in email → 2 results
      final results2 =
          await graph.traversal().V().hasAnyKeyContains('example').toList();
      expect(results2, hasLength(2));
    });

    test('returns each vertex only once even when multiple properties match', () async {
      await graph.transaction((txn) async {
        // both name and email contain "alice"
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {
              'name': 'alice',
              'email': 'alice@example.com',
              'note': 'nothing here',
            }));
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Bob', 'email': 'bob@example.com'}));
      });

      final results =
          await graph.traversal().V().hasAnyKeyContains('alice').toList();
      expect(results, hasLength(1));
    });

    test('returns empty when no property contains the value', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Alice', 'email': 'alice@example.com'}));
      });

      final results =
          await graph.traversal().V().hasAnyKeyContains('zzz').toList();
      expect(results, isEmpty);
    });

    test('does not match numeric properties', () async {
      await graph.transaction((txn) async {
        // age is numeric and excluded from LIKE matching
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Alice', 'age': 30}));
      });

      // searching "30" should not match numeric properties
      final results =
          await graph.traversal().V().hasAnyKeyContains('30').toList();
      expect(results, isEmpty);
    });

    test('can be combined with hasLabel', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Alice', 'email': 'alice@example.com'}));
        await txn.createVertex(Vertex(
            labels: {'product'},
            properties: {'name': 'Alice Speaker', 'description': 'Smart speaker'}));
      });

      // person label and contains "alice" → 1 result
      final results = await graph
          .traversal()
          .V()
          .hasLabel(['person'])
          .hasAnyKeyContains('alice')
          .toList();
      expect(results, hasLength(1));
    });

    test('returns empty for a graph with no vertices', () async {
      final results =
          await graph.traversal().V().hasAnyKeyContains('Alice').toList();
      expect(results, isEmpty);
    });
  });
}
