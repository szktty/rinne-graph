import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

import '../helpers/debug_helper.dart';

void main() {
  group('List search step tests', () {
    test('listContains - Basic string search', () async {
      final graph = await Graph.openInMemory();
      try {
        // Create test data
        final vertices = await graph.transaction((txn) async {
          final v1 = await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {
              'name': 'Alice',
              'tags': ['developer', 'engineer', 'tech'],
            },
          ));

          final v2 = await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {
              'name': 'Bob',
              'tags': ['manager', 'business'],
            },
          ));

          final v3 = await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {
              'name': 'Charlie',
              'tags': ['developer', 'frontend'],
            },
          ));

          return [v1, v2, v3];
        });

        // Search for vertices with 'developer' tag
        final traversal =
            graph.traversal().V().listContains('tags', 'developer');
        final query = traversal.buildQuery();
        debugLog('Query: ${query.query}');
        debugLog('Parameters: ${query.parameters}');

        final results =
            await graph.database.rawQuery(query.query, query.parameters);
        final resultIds = results.map((r) => r['id'] as int).toList();

        // Alice and Charlie should be found
        expect(resultIds.length, equals(2));
        expect(resultIds, containsAll([vertices[0].id, vertices[2].id]));
        expect(resultIds, isNot(contains(vertices[1].id)));
      } finally {
        await graph.close();
      }
    });

    test('listContains - Numeric search', () async {
      final graph = await Graph.openInMemory();
      try {
        // Create test data
        final vertices = await graph.transaction((txn) async {
          final v1 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'scores': [85, 92, 78],
            },
          ));

          final v2 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'scores': [70, 88, 95],
            },
          ));

          return [v1, v2];
        });

        // Search for vertices with score 92
        final traversal = graph.traversal().V().listContains('scores', 92);
        final query = traversal.buildQuery();

        final results =
            await graph.database.rawQuery(query.query, query.parameters);
        final resultIds = results.map((r) => r['id'] as int).toList();

        // Only v1 should be found
        expect(resultIds.length, equals(1));
        expect(resultIds, contains(vertices[0].id));
        expect(resultIds, isNot(contains(vertices[1].id)));
      } finally {
        await graph.close();
      }
    });

    test('listLength - Search by list length', () async {
      final graph = await Graph.openInMemory();
      try {
        // Create test data
        final vertices = await graph.transaction((txn) async {
          final v1 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'items': ['a', 'b', 'c'],
            },
          ));

          final v2 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'items': ['x', 'y'],
            },
          ));

          final v3 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'items': ['p', 'q', 'r', 's'],
            },
          ));

          return [v1, v2, v3];
        });

        // Search for vertices with list length 3
        final traversal = graph.traversal().V().listLength('items', 3);
        final query = traversal.buildQuery();

        final results =
            await graph.database.rawQuery(query.query, query.parameters);
        final resultIds = results.map((r) => r['id'] as int).toList();

        // Only v1 should be found
        expect(resultIds.length, equals(1));
        expect(resultIds, contains(vertices[0].id));
      } finally {
        await graph.close();
      }
    });

    test('listContains - Search for non-existent value', () async {
      final graph = await Graph.openInMemory();
      try {
        await graph.transaction((txn) async {
          await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'tags': ['a', 'b', 'c'],
            },
          ));
        });

        // Search for non-existent value
        final traversal =
            graph.traversal().V().listContains('tags', 'nonexistent');
        final query = traversal.buildQuery();

        final results =
            await graph.database.rawQuery(query.query, query.parameters);

        // Result should be empty
        expect(results.length, equals(0));
      } finally {
        await graph.close();
      }
    });

    test('listLength - Search for empty list', () async {
      final graph = await Graph.openInMemory();
      try {
        final vertex = await graph.transaction((txn) async {
          return txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'empty_list': <dynamic>[],
            },
          ));
        });

        // Search for list with length 0
        final traversal = graph.traversal().V().listLength('empty_list', 0);
        final query = traversal.buildQuery();

        final results =
            await graph.database.rawQuery(query.query, query.parameters);
        final resultIds = results.map((r) => r['id'] as int).toList();

        expect(resultIds.length, equals(1));
        expect(resultIds, contains(vertex.id));
      } finally {
        await graph.close();
      }
    });

    test('listContainsExact - Exact search using JSON1 extension', () async {
      final graph = await Graph.openInMemory();
      try {
        // Create test data
        final vertices = await graph.transaction((txn) async {
          final v1 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'scores': [85, 92, 78],
            },
          ));

          final v2 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'scores': [70, 88, 95],
            },
          ));

          final v3 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'scores': [92, 100, 85], // Contains 92 but different order
            },
          ));

          return [v1, v2, v3];
        });

        // Use JSON1 extension to search for score 92 exactly
        final traversal = graph.traversal().V().listContainsExact('scores', 92);
        final query = traversal.buildQuery();
        debugLog('JSON1 Query: ${query.query}');
        debugLog('JSON1 Parameters: ${query.parameters}');

        final results =
            await graph.database.rawQuery(query.query, query.parameters);
        final resultIds = results.map((r) => r['id'] as int).toList();

        // v1 and v3 should be found (both contain 92)
        expect(resultIds.length, equals(2));
        expect(resultIds, containsAll([vertices[0].id, vertices[2].id]));
        expect(resultIds, isNot(contains(vertices[1].id)));
      } finally {
        await graph.close();
      }
    });

    test('listContainsExact - Exact string search', () async {
      final graph = await Graph.openInMemory();
      try {
        // Create test data
        final vertices = await graph.transaction((txn) async {
          final v1 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'tags': ['dev', 'developer', 'development'],
            },
          ));

          final v2 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'tags': ['manager', 'business'],
            },
          ));

          return [v1, v2];
        });

        // Search for 'dev' exactly (exclude 'developer' and 'development')
        final traversal =
            graph.traversal().V().listContainsExact('tags', 'dev');
        final query = traversal.buildQuery();

        final results =
            await graph.database.rawQuery(query.query, query.parameters);
        final resultIds = results.map((r) => r['id'] as int).toList();

        // Only v1 should be found
        expect(resultIds.length, equals(1));
        expect(resultIds, contains(vertices[0].id));
      } finally {
        await graph.close();
      }
    });
  });
}
