import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import '../helpers/debug_helper.dart';
import '../helpers/helpers.dart';

void main() async {
  // Initialize debug settings
  initializeDebugSettings();

  // To reduce execution time
  KiriCheck.maxExamples = 30;

  group('Filtering step tests', () {
    property('HasLabel - Filter by label', () {
      const maxLabels = 10;
      forAll(ArbitraryTestHelpers.graph(minLabels: 1, maxLabels: maxLabels),
          (f) async {
        final g = await f;
        final labels = g.getAnyVertexLabels(maxLabels);
        final traversal = g.traversalSystem().V().hasLabel(labels);
        final query = traversal.buildQuery();
        debugLog('query: ${query.query}, ${query.parameters}');
        final results = await g.rawQuery(query.query, query.parameters);

        final actual = await g.V().hasId(results.getIds()).toList();
        final expected = await g.V().hasLabel(labels).toList();
        debugLog('labels: $labels');
        debugLog('results: ${results.raw}');
        debugLog('actual: $actual');
        debugLog('expected: $expected');
        expect(actual.toSet(), equals(expected.toSet()));
      });
    });

    property('Has - Filter by property', () {
      forAll(ArbitraryTestHelpers.graph(), (f) async {
        final g = await f;
        final property = g.anyProperty;
        if (property == null) {
          return;
        }
        debugLog('=====');
        final (key, value) = property;
        debugLog('key: $key, value: $value');
        final traversal = g.traversalSystem().V().hasKey(key, value);
        final query = traversal.buildQuery();
        final results = await g.rawQuery(query.query, query.parameters);
        debugLog('results: ${results.raw}');

        final actual = results.getIds();
        final expected = await g.V().hasKey(key, value).id().toList();
        debugLog('actual: $actual');
        debugLog('expected: $expected');
        expect(actual.toSet(), equals(expected.toSet()));
      });
    });
  });
}
