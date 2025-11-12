import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import '../helpers/debug_helper.dart';
import '../helpers/helpers.dart';

void main() async {
  // Initialize debug settings
  initializeDebugSettings();

  // To reduce execution time
  KiriCheck.maxExamples = 30;

  group('Start step tests', () {
    property('V - Select vertices', () {
      forAll(
        ArbitraryTestHelpers.graph(),
        (f) async {
          final g = await f;
          final vertexIds = g.getAnyVertexIds();
          final traversal = g.traversalSystem().V(vertexIds);
          final query = traversal.buildQuery();
          final results = await g.rawQuery(query.query, query.parameters);

          debugLog('vertexIds: $vertexIds, results: ${results.getIds()}');
          final actual = await g.V(results.getIds()).toList();
          final expected = await g.V(vertexIds).toList();
          debugLog('actual: $actual, expected: $expected');
          expect(actual.toSet(), equals(expected.toSet()));
        },
        maxShrinkingTries: 0,
      );
    });

    property('E - Select edges', () {
      forAll(ArbitraryTestHelpers.graph(), (f) async {
        final g = await f;
        final edgeIds = g.getAnyEdgeIds();
        final traversal = g.traversalSystem().E(edgeIds);
        final query = traversal.buildQuery();
        final results = await g.rawQuery(query.query, query.parameters);

        final actual = await g.E(results.getIds()).toList();
        final expected = await g.E(edgeIds).toList();
        expect(actual.toSet(), equals(expected.toSet()));
      });
    });
  });
}
