import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Issue Fixes Tests', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    group('Skip/Limit OFFSET syntax fix', () {
      test('skip() with limit() should work without SQL errors', () async {
        // Add test data
        await graph.transaction((txn) async {
          for (var i = 0; i < 5; i++) {
            await txn.createVertex(Vertex(
              labels: {'Person'},
              properties: {'name': 'Person$i', 'index': i},
            ));
          }
        });

        final g = graph.traversal();

        // Test skip without limit
        final skipResults = await g.V().skip(2).toList();
        expect(skipResults.length, equals(3));

        // Test skip with limit
        final skipLimitResults = await g.V().skip(1).limit(2).toList();
        expect(skipLimitResults.length, equals(2));

        // Test limit with skip (order matters)
        final limitSkipResults = await g.V().limit(3).skip(1).toList();
        expect(limitSkipResults.length, equals(2));
      });

      test('skip() with offset should generate correct LIMIT OFFSET syntax',
          () async {
        // Add test data
        await graph.transaction((txn) async {
          for (var i = 0; i < 5; i++) {
            await txn.createVertex(Vertex(
              labels: {'Test'},
              properties: {'order': i},
            ));
          }
        });

        final g = graph.traversal();

        // Test various skip/limit combinations
        final results1 =
            await g.V().hasLabel(['Test']).skip(0).limit(2).toList();
        expect(results1.length, equals(2));

        final results2 =
            await g.V().hasLabel(['Test']).skip(2).limit(2).toList();
        expect(results2.length, equals(2));

        final results3 =
            await g.V().hasLabel(['Test']).skip(4).limit(2).toList();
        expect(results3.length, equals(1)); // Only 1 remaining
      });
    });

    group('String search methods fix', () {
      setUp(() async {
        // Add test data with various names
        await graph.transaction((txn) async {
          await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'John', 'email': 'john@example.com'},
          ));
          await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'Jane', 'email': 'jane@test.org'},
          ));
          await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'Bob', 'email': 'bob@company.com'},
          ));
          await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'Alice', 'email': 'alice@example.com'},
          ));
        });
      });

      test('hasKeyStartsWith should find names starting with specific prefix',
          () async {
        final g = graph.traversal();

        // Test names starting with 'J'
        final jResults = await g.V().hasKeyStartsWith('name', 'J').toList();
        expect(jResults.length, equals(2)); // John and Jane

        // Test names starting with 'B'
        final bResults = await g.V().hasKeyStartsWith('name', 'B').toList();
        expect(bResults.length, equals(1)); // Bob

        // Test non-existent prefix
        final zResults = await g.V().hasKeyStartsWith('name', 'Z').toList();
        expect(zResults.length, equals(0));
      });

      test('hasKeyEndsWith should find names ending with specific suffix',
          () async {
        final g = graph.traversal();

        // Test emails ending with '.com'
        final comResults = await g.V().hasKeyEndsWith('email', '.com').toList();
        expect(comResults.length, equals(3)); // john, bob, alice

        // Test emails ending with '.org'
        final orgResults = await g.V().hasKeyEndsWith('email', '.org').toList();
        expect(orgResults.length, equals(1)); // jane

        // Test non-existent suffix
        final netResults = await g.V().hasKeyEndsWith('email', '.net').toList();
        expect(netResults.length, equals(0));
      });

      test('hasKeyContains should find names containing specific substring',
          () async {
        final g = graph.traversal();

        // Test names containing 'o'
        final oResults = await g.V().hasKeyContains('name', 'o').toList();
        expect(oResults.length, equals(2)); // John and Bob

        // Test emails containing 'example'
        final exampleResults =
            await g.V().hasKeyContains('email', 'example').toList();
        expect(exampleResults.length, equals(2)); // john and alice

        // Test non-existent substring
        final xResults = await g.V().hasKeyContains('name', 'xyz').toList();
        expect(xResults.length, equals(0));
      });

      test('string search methods should work with str: prefix in database',
          () async {
        final g = graph.traversal();

        // Verify that the fix handles the str: prefix correctly
        final allNames = await g.V().hasKeyStartsWith('name', '').toList();
        expect(
            allNames.length, equals(4)); // Empty string should match all names

        // Test case insensitivity (SQLite LIKE is case-insensitive by default)
        final lowerResults = await g.V().hasKeyStartsWith('name', 'j').toList();
        expect(lowerResults.length, equals(2)); // Should match John and Jane

        final upperResults = await g.V().hasKeyStartsWith('name', 'J').toList();
        expect(upperResults.length, equals(2)); // John and Jane
      });
    });

    group('Database clear functionality', () {
      test('clearAll should remove all vertices and edges', () async {
        // Add test data
        await graph.transaction((txn) async {
          final v1 = await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'Alice'},
          ));
          final v2 = await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'Bob'},
          ));
          await txn.createEdge(Edge(
            fromVertexId: v1.id!,
            toVertexId: v2.id!,
            labels: {'knows'},
          ));
        });

        // Verify data exists
        var stats = await graph.getStatistics();
        expect(stats.totalVertices, equals(2));
        expect(stats.totalEdges, equals(1));

        // Clear all data
        await graph.clearAll();

        // Verify all data is removed
        stats = await graph.getStatistics();
        expect(stats.totalVertices, equals(0));
        expect(stats.totalEdges, equals(0));
        expect(stats.vertexLabelCounts, isEmpty);
        expect(stats.edgeLabelCounts, isEmpty);
      });

      test('clearVertices should remove all vertices and related edges',
          () async {
        // Add test data
        await graph.transaction((txn) async {
          final v1 = await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'Alice'},
          ));
          final v2 = await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'Bob'},
          ));
          await txn.createEdge(Edge(
            fromVertexId: v1.id!,
            toVertexId: v2.id!,
            labels: {'knows'},
          ));
        });

        // Verify data exists
        var stats = await graph.getStatistics();
        expect(stats.totalVertices, equals(2));
        expect(stats.totalEdges, equals(1));

        // Clear vertices
        await graph.clearVertices();

        // Verify all data is removed (edges are also removed due to FK constraints)
        stats = await graph.getStatistics();
        expect(stats.totalVertices, equals(0));
        expect(stats.totalEdges, equals(0));
      });

      test('clearEdges should remove only edges, keeping vertices', () async {
        // Add test data
        await graph.transaction((txn) async {
          final v1 = await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'Alice'},
          ));
          final v2 = await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'Bob'},
          ));
          await txn.createEdge(Edge(
            fromVertexId: v1.id!,
            toVertexId: v2.id!,
            labels: {'knows'},
          ));
        });

        // Verify data exists
        var stats = await graph.getStatistics();
        expect(stats.totalVertices, equals(2));
        expect(stats.totalEdges, equals(1));

        // Clear only edges
        await graph.clearEdges();

        // Verify vertices remain but edges are removed
        stats = await graph.getStatistics();
        expect(stats.totalVertices, equals(2));
        expect(stats.totalEdges, equals(0));
        expect(stats.vertexLabelCounts.isNotEmpty, isTrue);
        expect(stats.edgeLabelCounts, isEmpty);
      });

      test('clear methods should work in transactions', () async {
        // Test that clear methods work properly within the transaction system
        await graph.transaction((txn) async {
          await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {'value': 'test'},
          ));
        });

        var stats = await graph.getStatistics();
        expect(stats.totalVertices, equals(1));

        // Clear in a separate transaction
        await graph.clearAll();

        stats = await graph.getStatistics();
        expect(stats.totalVertices, equals(0));
      });
    });

    group('Integration tests for fixes', () {
      test('combined skip/limit with string search should work', () async {
        // Add test data
        await graph.transaction((txn) async {
          for (var i = 0; i < 10; i++) {
            await txn.createVertex(Vertex(
              labels: {'Person'},
              properties: {'name': 'User$i', 'index': i},
            ));
          }
        });

        final g = graph.traversal();

        // Combine string search with skip/limit
        final results = await g
            .V()
            .hasKeyStartsWith('name', 'User')
            .skip(2)
            .limit(3)
            .toList();

        expect(results.length, equals(3));
      });

      test('string search after clear and repopulate should work', () async {
        // Add initial data
        await graph.transaction((txn) async {
          await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'John'},
          ));
        });

        final g = graph.traversal();

        // Verify data exists
        var results = await g.V().hasKeyStartsWith('name', 'J').toList();
        expect(results.length, equals(1));

        // Clear and repopulate
        await graph.clearAll();
        await graph.transaction((txn) async {
          await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'Jane'},
          ));
          await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {'name': 'Jack'},
          ));
        });

        // Test string search again
        results = await g.V().hasKeyStartsWith('name', 'J').toList();
        expect(results.length, equals(2));
      });
    });
  });
}
