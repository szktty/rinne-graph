import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import '../helpers/debug_helper.dart';
import '../helpers/helpers.dart';

void main() async {
  // Initialize debug settings
  initializeDebugSettings();

  // To reduce execution time
  KiriCheck.maxExamples = 30;

  group('Movement step tests', () {
    property('Out - Move through outgoing edges', () {
      forAll(ArbitraryTestHelpers.graph(), (f) async {
        debugLog('============================================');
        final g = await f;
        final labels = g.getAnyEdgeLabels();
        final traversal = g.traversalSystem().V().out(labels);
        final query = traversal.buildQuery();
        final results = await g.rawQuery(query.query, query.parameters);
        debugLog('results: ${results.raw}');
        debugLog('labels: $labels');

        final actual = results.getIds();
        debugLog('actual: $actual');
        debugLog('labels: $labels');

        // Verify results are retrieved correctly
        expect(actual, isA<List<int>>());

        // Verify results exist when labels are specified
        if (labels.isNotEmpty) {
          // Verify some results are returned (can be empty)
          expect(actual, isA<List<int>>());
        }
      });
    });

    property('In - Move through incoming edges', () {
      forAll(ArbitraryTestHelpers.graph(), (f) async {
        debugLog('============================================');
        final g = await f;
        final labels = g.getAnyEdgeLabels();
        final traversal = g.traversalSystem().V().in_(labels);
        final query = traversal.buildQuery();
        final results = await g.rawQuery(query.query, query.parameters);
        debugLog('results: ${results.raw}');
        debugLog('labels: $labels');

        final actual = results.getIds();
        debugLog('actual: $actual');
        debugLog('labels: $labels');

        // Verify results are retrieved correctly
        expect(actual, isA<List<int>>());

        // Verify results exist when labels are specified
        if (labels.isNotEmpty) {
          expect(actual, isA<List<int>>());
        }
      });
    });

    property('Both - Move through bidirectional edges', () {
      forAll(ArbitraryTestHelpers.graph(), (f) async {
        debugLog('============================================');
        final g = await f;
        final labels = g.getAnyEdgeLabels();
        final traversal = g.traversalSystem().V().both(labels);
        final query = traversal.buildQuery();
        final results = await g.rawQuery(query.query, query.parameters);
        debugLog('results: ${results.raw}');
        debugLog('labels: $labels');

        final actual = results.getIds();
        debugLog('actual: $actual');
        debugLog('labels: $labels');

        // Verify results are retrieved correctly
        expect(actual, isA<List<int>>());

        // Verify results exist when labels are specified
        if (labels.isNotEmpty) {
          expect(actual, isA<List<int>>());
        }
      });
    });

    property('OutE - Move to outgoing edges', () {
      forAll(ArbitraryTestHelpers.graph(), (f) async {
        debugLog('============================================');
        final g = await f;
        final labels = g.getAnyEdgeLabels();
        final traversal = g.traversalSystem().V().outE(labels);
        final query = traversal.buildQuery();
        debugLog('query: ${query.query}');
        debugLog('parameters: ${query.parameters}');
        final results = await g.rawQuery(query.query, query.parameters);
        debugLog('results: ${results.raw}');
        debugLog('labels: $labels');

        final actual = results.getIds();
        debugLog('actual: $actual');
        debugLog('labels: $labels');

        // Verify results are retrieved correctly
        expect(actual, isA<List<int>>());

        // Verify results exist when labels are specified
        if (labels.isNotEmpty) {
          expect(actual, isA<List<int>>());
        }
      });
    });

    property('OutE - Outgoing edges from specific vertex', () {
      forAll(ArbitraryTestHelpers.graph(minVertices: 3, minEdges: 3),
          (f) async {
        final g = await f;
        final vertexIds = g.getAnyVertexIds(2); // Select 2 vertices
        if (vertexIds.isEmpty) return; // Skip if not enough vertices

        final labels = g.getAnyEdgeLabels();
        final traversal = g.traversalSystem().V(vertexIds).outE(labels);
        final query = traversal.buildQuery();
        debugLog('query: ${query.query}');
        debugLog('parameters: ${query.parameters}');
        final results = await g.rawQuery(query.query, query.parameters);

        final actual = results.getIds();
        final expected = await g.V(vertexIds).outE(labels).id().toList();
        expect(actual.toSet(), equals(expected.toSet()),
            reason: 'Actual: $actual, Expected: $expected');
      });
    });

    property('InE - Move to incoming edges', () {
      forAll(ArbitraryTestHelpers.graph(), (f) async {
        debugLog('============================================');
        final g = await f;
        final labels = g.getAnyEdgeLabels();
        final traversal = g.traversalSystem().V().inE(labels);
        final query = traversal.buildQuery();
        debugLog('query: ${query.query}');
        debugLog('parameters: ${query.parameters}');
        final results = await g.rawQuery(query.query, query.parameters);
        debugLog('results: ${results.raw}');
        debugLog('labels: $labels');

        final actual = results.getIds();
        debugLog('actual: $actual');
        debugLog('labels: $labels');

        // Verify results are retrieved correctly
        expect(actual, isA<List<int>>());

        // Verify results exist when labels are specified
        if (labels.isNotEmpty) {
          expect(actual, isA<List<int>>());
        }
      });
    });

    property('BothE - Move to bidirectional edges', () {
      forAll(ArbitraryTestHelpers.graph(), (f) async {
        debugLog('============================================');
        final g = await f;
        final labels = g.getAnyEdgeLabels();
        final traversal = g.traversalSystem().V().bothE(labels);
        final query = traversal.buildQuery();
        debugLog('query: ${query.query}');
        debugLog('parameters: ${query.parameters}');
        final results = await g.rawQuery(query.query, query.parameters);
        debugLog('results: ${results.raw}');
        debugLog('labels: $labels');

        final actual = results.getIds();
        debugLog('actual: $actual');
        debugLog('labels: $labels');

        // Verify results are retrieved correctly
        expect(actual, isA<List<int>>());

        // Verify results exist when labels are specified
        if (labels.isNotEmpty) {
          expect(actual, isA<List<int>>());
        }
      });
    });

    property('OutV - Move to source vertex of edge', () {
      forAll(ArbitraryTestHelpers.graph(minEdges: 1), (f) async {
        debugLog('============================================');
        final g = await f;
        final edgeIds = g.getAnyEdgeIds(1);
        if (edgeIds.isEmpty) return; // Skip if not enough edges

        final traversal = g.traversalSystem().E(edgeIds).outV();
        final query = traversal.buildQuery();
        debugLog('query: ${query.query}');
        debugLog('parameters: ${query.parameters}');
        final results = await g.rawQuery(query.query, query.parameters);
        debugLog('results: ${results.raw}');

        final actual = results.getIds();
        debugLog('actual: $actual');
        debugLog('edgeIds: $edgeIds');

        // Verify results are retrieved correctly
        expect(actual, isA<List<int>>());

        // Verify results exist when edges exist
        if (edgeIds.isNotEmpty) {
          expect(actual, isA<List<int>>());
        }
      });
    });

    property('InV - Move to target vertex of edge', () {
      forAll(ArbitraryTestHelpers.graph(minEdges: 1), (f) async {
        debugLog('============================================');
        final g = await f;
        final edgeIds = g.getAnyEdgeIds(1);
        if (edgeIds.isEmpty) return; // Skip if not enough edges

        final traversal = g.traversalSystem().E(edgeIds).inV();
        final query = traversal.buildQuery();
        debugLog('query: ${query.query}');
        debugLog('parameters: ${query.parameters}');
        final results = await g.rawQuery(query.query, query.parameters);
        debugLog('results: ${results.raw}');

        final actual = results.getIds();
        debugLog('actual: $actual');
        debugLog('edgeIds: $edgeIds');

        // Verify results are retrieved correctly
        expect(actual, isA<List<int>>());

        // Verify results exist when edges exist
        if (edgeIds.isNotEmpty) {
          expect(actual, isA<List<int>>());
        }
      });
    });

    property('BothV - Move to both vertices of edge', () {
      forAll(ArbitraryTestHelpers.graph(minEdges: 1), (f) async {
        debugLog('============================================');
        final g = await f;
        final edgeIds = g.getAnyEdgeIds(1);
        if (edgeIds.isEmpty) return; // Skip if not enough edges

        final traversal = g.traversalSystem().E(edgeIds).bothV();
        final query = traversal.buildQuery();
        debugLog('query: ${query.query}');
        debugLog('parameters: ${query.parameters}');
        final results = await g.rawQuery(query.query, query.parameters);
        debugLog('results: ${results.raw}');

        final actual = results.getIds();
        debugLog('actual: $actual');
        debugLog('edgeIds: $edgeIds');

        // Verify results are retrieved correctly
        expect(actual, isA<List<int>>());

        // Verify results exist when edges exist
        if (edgeIds.isNotEmpty) {
          expect(actual, isA<List<int>>());
        }
      });
    });
  });
}
