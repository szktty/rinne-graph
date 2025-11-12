import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Enhanced Filter Tests', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('hasKeyContains() - string contains search', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(labels: {
          'person'
        }, properties: {
          'name': 'Alice Johnson',
          'email': 'alice@example.com'
        }));
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Bob Smith', 'email': 'bob@company.com'}));
        await txn.createVertex(Vertex(labels: {
          'person'
        }, properties: {
          'name': 'Charlie Brown',
          'email': 'charlie@example.com'
        }));
      });

      // Search for names containing "Alice"
      final traversal1 = graph.traversal().V().hasKeyContains('name', 'Alice');
      final query1 = traversal1.buildQuery();
      final results1 =
          await graph.database.rawQuery(query1.query, query1.parameters);
      expect(results1, hasLength(1));

      // Search for emails containing "example"
      final traversal2 =
          graph.traversal().V().hasKeyContains('email', 'example');
      final query2 = traversal2.buildQuery();
      final results2 =
          await graph.database.rawQuery(query2.query, query2.parameters);
      expect(results2, hasLength(2));

      // Search for names containing "Smith"
      final traversal3 = graph.traversal().V().hasKeyContains('name', 'Smith');
      final query3 = traversal3.buildQuery();
      final results3 =
          await graph.database.rawQuery(query3.query, query3.parameters);
      expect(results3, hasLength(1));
    });

    test('hasKeyMatches() - regex pattern search', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Alice', 'phone': '123-456-7890'}));
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Bob', 'phone': '987-654-3210'}));
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Charlie', 'phone': 'invalid-phone'}));
      });

      // Note: SQLite's REGEXP requires loading an extension or custom function
      // For this test, we'll verify the query is generated correctly
      // In a real scenario, this would depend on SQLite configuration

      final traversal = graph
          .traversal()
          .V()
          .hasKeyMatches('phone', r'^[0-9]{3}-[0-9]{3}-[0-9]{4}$');
      final query = traversal.buildQuery();

      // Verify query contains REGEXP clause
      expect(query.query, contains('REGEXP'));
      expect(query.parameters, contains(r'^[0-9]{3}-[0-9]{3}-[0-9]{4}$'));
    });

    test('combined filtering with contains and exact match', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(labels: {
          'product'
        }, properties: {
          'name': 'iPhone 15 Pro',
          'category': 'electronics',
          'price': 999
        }));
        await txn.createVertex(Vertex(labels: {
          'product'
        }, properties: {
          'name': 'iPhone 15',
          'category': 'electronics',
          'price': 799
        }));
        await txn.createVertex(Vertex(labels: {
          'product'
        }, properties: {
          'name': 'Samsung Galaxy',
          'category': 'electronics',
          'price': 899
        }));
        await txn.createVertex(Vertex(labels: {
          'book'
        }, properties: {
          'name': 'iPhone Guide',
          'category': 'books',
          'price': 29
        }));
      });

      // Find electronics with "iPhone" in the name
      final traversal = graph
          .traversal()
          .V()
          .hasKey('category', 'electronics')
          .hasKeyContains('name', 'iPhone');

      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);
      expect(results, hasLength(2)); // iPhone 15 Pro and iPhone 15
    });

    test('case-insensitive contains search (SQLite LIKE behavior)', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'alice'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'ALICE'}));
      });

      // SQLite LIKE is case-insensitive by default, so all should match
      final traversal = graph.traversal().V().hasKeyContains('name', 'Alice');
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);
      expect(results, hasLength(3)); // All variants of "Alice"
    });

    test('empty string contains search', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        await txn
            .createVertex(Vertex(labels: {'person'}, properties: {'name': ''}));
      });

      // Search for empty string should match both (all strings contain empty string)
      final traversal = graph.traversal().V().hasKeyContains('name', '');
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);
      expect(results, hasLength(2));
    });

    test('no matches for contains search', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
      });

      // Search for non-existent substring
      final traversal = graph.traversal().V().hasKeyContains('name', 'Charlie');
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);
      expect(results, hasLength(0));
    });
  });
}
