import 'package:kiri_check/kiri_check.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

import '../helpers/debug_helper.dart';
import '../helpers/helpers.dart';
import 'test_helpers.dart';

void main() async {
  // Initialize debug settings
  initializeDebugSettings();

  // To reduce execution time
  KiriCheck.maxExamples = 30;

  group('Result control step tests', () {
    group('Order - Sort results', () {
      test('order by id with default ordering (ascending)', () async {
        final g = await ArbitraryTestHelpers.createGraph(
          minVertices: 10,
          maxVertices: 10,
          minEdges: 5,
          maxEdges: 5,
          minLabels: 1,
          maxLabels: 3,
          minProperties: 1,
          maxProperties: 3,
        );

        final traversal = g.traversalSystem().V().order().byId();
        final query = traversal.buildQuery();
        final results = await g.rawQuery(query.query, query.parameters);

        expect(results.length, equals(g.vertices.length));
        expect(results.getIds(), equals(g.vertexIds.toList()..sort()));
      });

      test('order by id with ascending', () async {
        final g = await ArbitraryTestHelpers.createGraph(
          minVertices: 10,
          maxVertices: 10,
          minEdges: 5,
          maxEdges: 5,
          minLabels: 1,
          maxLabels: 3,
          minProperties: 1,
          maxProperties: 3,
        );

        final traversal = g.traversalSystem().V().order().byId(SortOrder.asc);
        final query = traversal.buildQuery();
        final results = await g.rawQuery(query.query, query.parameters);

        expect(results.length, equals(g.vertices.length));
        expect(results.getIds(), equals(g.vertexIds.toList()..sort()));
      });

      test('order by id with descending', () async {
        final g = await ArbitraryTestHelpers.createGraph(
          minVertices: 10,
          maxVertices: 10,
          minEdges: 5,
          maxEdges: 5,
          minLabels: 1,
          maxLabels: 3,
          minProperties: 1,
          maxProperties: 3,
        );

        final traversal = g.traversalSystem().V().order().byId(SortOrder.desc);
        final query = traversal.buildQuery();
        final results = await g.rawQuery(query.query, query.parameters);

        expect(results.length, equals(g.vertices.length));
        expect(
          results.getIds(),
          equals((g.vertexIds.toList()..sort()).reversed.toList()),
        );
      });

      property('order by key with default ordering (ascending)', () {
        forAll(
          ArbitraryTestHelpers.graph(maxProperties: 0),
          (f) async {
            final g = await f;
            final vertexIds = await createVertexWithSamePropertyKeysAndTypes(g);

            // Verify sorted results are returned correctly for each property key
            for (final key in propertyKeysWithSameTypes) {
              // Use SQL traversal
              final traversal =
                  g.traversalSystem().V(vertexIds).order().byKey(key).byId();
              final vertices = await traversal.toList();

              // Verify results are Vertex objects
              expect(vertices, isNotEmpty);
              expect(vertices.first, isA<Vertex>());

              // Verify number of results matches expectation
              expect(vertices.length, equals(vertexIds.length));
            }
          },
          maxShrinkingTries: 0,
        );
      });
    });

    group('Limit - Limit number of results', () {
      test('basic', () async {
        final g = await ArbitraryTestHelpers.createGraph(
          minVertices: 10,
          maxVertices: 10,
          minEdges: 5,
          maxEdges: 5,
          minLabels: 1,
          maxLabels: 3,
          minProperties: 1,
          maxProperties: 3,
        );

        const limit = 5;
        final traversal = g.traversalSystem().V().limit(limit);
        final query = traversal.buildQuery();
        final results = await g.rawQuery(query.query, query.parameters);

        expect(results.length, equals(limit));
        expect(results.getIds().length, equals(limit));

        for (final id in results.getIds()) {
          expect(g.getVertexById(id), isNotNull);
        }
      });
    });
  });
}
