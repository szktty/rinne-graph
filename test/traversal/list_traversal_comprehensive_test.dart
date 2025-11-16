import 'package:kiri_check/kiri_check.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

import '../helpers/arbitrary.dart';
import '../helpers/debug_helper.dart';

void main() {
  group('List Traversal Comprehensive Tests', () {
    test('Search list with complex conditions', () async {
      final graph = await Graph.openInMemory();
      try {
        // Create complex test data
        final vertices = await graph.transaction((txn) async {
          final v1 = await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {
              'name': 'Alice',
              'skills': ['dart', 'flutter', 'python'],
              'experience_years': [3, 2, 5],
              'active': true,
            },
          ));

          final v2 = await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {
              'name': 'Bob',
              'skills': ['java', 'spring', 'kotlin'],
              'experience_years': [7, 4, 2],
              'active': true,
            },
          ));

          final v3 = await txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {
              'name': 'Charlie',
              'skills': ['dart', 'go', 'rust'],
              'experience_years': [2, 1, 1],
              'active': false,
            },
          ));

          return [v1, v2, v3];
        });

        // Search for people with dart skill and active status
        final traversal = graph
            .traversal()
            .V()
            .hasKey('active', true)
            .listContains('skills', 'dart');

        final query = traversal.buildQuery();
        debugLog('Complex Query: ${query.query}');
        debugLog('Complex Parameters: ${query.parameters}');

        final results =
            await graph.database.rawQuery(query.query, query.parameters);
        final resultIds = results.map((r) => r['id'] as int).toList();

        // Alice and Charlie have dart skill, but only Alice is active, so only Alice should match
        expect(resultIds.length, equals(1));
        expect(resultIds, contains(vertices[0].id));
      } finally {
        await graph.close();
      }
    });

    test('Combined search by list length and content', () async {
      final graph = await Graph.openInMemory();
      try {
        final vertices = await graph.transaction((txn) async {
          final v1 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'tags': ['a', 'b', 'c'], // Length 3, contains 'b'
            },
          ));

          final v2 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'tags': ['x', 'y'], // Length 2, doesn't contain 'b'
            },
          ));

          final v3 = await txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'tags': ['p', 'b', 'q'], // Length 3, contains 'b'
            },
          ));

          return [v1, v2, v3];
        });

        // Search for lists with length 3 and containing 'b'
        final traversal = graph
            .traversal()
            .V()
            .listLength('tags', 3)
            .listContains('tags', 'b');

        final query = traversal.buildQuery();
        final results =
            await graph.database.rawQuery(query.query, query.parameters);
        final resultIds = results.map((r) => r['id'] as int).toList();

        // v1 and v3 should match the conditions
        expect(resultIds.length, equals(2));
        expect(resultIds, containsAll([vertices[0].id, vertices[2].id]));
      } finally {
        await graph.close();
      }
    });

    test('List search for edges', () async {
      final graph = await Graph.openInMemory();
      try {
        final (edges) = await graph.transaction((txn) async {
          final v1 = await txn.createVertex(Vertex(labels: {'Person'}));
          final v2 = await txn.createVertex(Vertex(labels: {'Person'}));
          final v3 = await txn.createVertex(Vertex(labels: {'Person'}));

          final e1 = await txn.createEdge(Edge(
            fromVertexId: v1.id!,
            toVertexId: v2.id!,
            labels: {'KNOWS'},
            properties: {
              'contexts': ['work', 'school'],
              'years': [2020, 2021],
            },
          ));

          final e2 = await txn.createEdge(Edge(
            fromVertexId: v2.id!,
            toVertexId: v3.id!,
            labels: {'KNOWS'},
            properties: {
              'contexts': ['hobby', 'travel'],
              'years': [2022],
            },
          ));

          return [e1, e2];
        });

        // Search for edges with 'work' context
        final traversal =
            graph.traversal().E().listContains('contexts', 'work');

        final query = traversal.buildQuery();
        final results =
            await graph.database.rawQuery(query.query, query.parameters);
        final resultIds = results.map((r) => r['id'] as int).toList();

        // Only e1 should match the conditions
        expect(resultIds.length, equals(1));
        expect(resultIds, contains(edges[0].id));
      } finally {
        await graph.close();
      }
    });

    test('Search for mixed-type lists', () async {
      final graph = await Graph.openInMemory();
      try {
        final vertex = await graph.transaction((txn) async {
          return txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'mixed': ['text', 42, true, 3.14],
            },
          ));
        });

        // Search for values of each type
        final tests = [
          ('text', 'text'),
          ('number', 42),
          ('boolean', true),
          ('float', 3.14),
        ];

        for (final (description, value) in tests) {
          final traversal = graph.traversal().V().listContains('mixed', value);

          final query = traversal.buildQuery();
          final results =
              await graph.database.rawQuery(query.query, query.parameters);
          final resultIds = results.map((r) => r['id'] as int).toList();

          expect(resultIds.length, equals(1),
              reason: 'Failed for $description');
          expect(resultIds, contains(vertex.id),
              reason: 'Failed for $description');
        }
      } finally {
        await graph.close();
      }
    });

    test('LIKE search limitation test', () async {
      final graph = await Graph.openInMemory();
      try {
        await graph.transaction((txn) async {
          return txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'numbers': [-4716, 123, 789],
            },
          ));
        });

        // LIKE search may cause partial matches
        final likeTraversal = graph.traversal().V().listContains('numbers', 6);
        final likeQuery = likeTraversal.buildQuery();
        final likeResults = await graph.database.rawQuery(
          likeQuery.query,
          likeQuery.parameters,
        );

        // LIKE search matches the 6 in -4716
        expect(likeResults.length, equals(1));

        // JSON1 extension allows exact search
        final exactTraversal =
            graph.traversal().V().listContainsExact('numbers', 6);
        final exactQuery = exactTraversal.buildQuery();
        final exactResults = await graph.database.rawQuery(
          exactQuery.query,
          exactQuery.parameters,
        );

        // JSON1 extension returns exactly 0 results
        expect(exactResults.length, equals(0));
      } finally {
        await graph.close();
      }
    });

    property('Property-based test for JSON1 extension list search', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.listProperty(),
          ArbitraryTestHelpers.propertyString(),
          oneOf([
            ArbitraryTestHelpers.propertyString(),
            integer(),
            boolean(),
          ]),
        ),
        (testData) async {
          final (listProperty, key, searchValue) = testData;
          final graph = await Graph.openInMemory();
          try {
            final vertex = await graph.transaction((txn) async {
              return txn.createVertex(Vertex(
                labels: {'Test'},
                properties: {key: listProperty},
              ));
            });

            final shouldFind = listProperty.contains(searchValue);

            // Test only exact search using JSON1 extension
            final exactTraversal =
                graph.traversal().V().listContainsExact(key, searchValue);

            final exactQuery = exactTraversal.buildQuery();
            final exactResults = await graph.database.rawQuery(
              exactQuery.query,
              exactQuery.parameters,
            );

            if (shouldFind) {
              expect(exactResults.length, greaterThan(0));
              expect(exactResults.map((r) => r['id']), contains(vertex.id));
            } else {
              expect(
                  exactResults.map((r) => r['id']), isNot(contains(vertex.id)));
            }
          } finally {
            await graph.close();
          }
        },
      );
    });
  });
}
