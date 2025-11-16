import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import '../helpers/debug_helper.dart';
import '../helpers/helpers.dart';

void main() async {
  // Initialize debug settings
  initializeDebugSettings();

  // To reduce execution time
  KiriCheck.maxExamples = 30;

  group('Property step tests', () {
    property('Values - Get property values', () {
      forAll(
        ArbitraryTestHelpers.graph(minVertices: 1, minProperties: 1),
        (f) async {
          // TODO(dev): first may cause error
          // May be empty
          final g = await f;
          debugLog('vertiecs count: ${g.vertices.length}');
          final vertex = g.getAnyVertices(1).first;
          final keys = vertex.properties.keys.toList();
          final traversal = g.traversalSystem().V([vertex.id!]).values(keys);
          final query = traversal.buildQuery();
          final results = await g.rawQuery(
            query.query,
            query.parameters,
            query.propertyKeyMap,
          );
          debugLog('results: ${results.raw}');
          //expect(results.length, equals(keys.length));
          //expect(setEquals(results.raw., b))

          final propertiesList = results.getPropertiesList();
          debugLog('propertiesList: $propertiesList');
          final properties = propertiesList.first;
          debugLog('vertex id: ${vertex.id}');
          debugLog('actual: $properties');
          debugLog('expected: ${vertex.properties}');
          expect(properties, equals(vertex.properties));
          /*
          expect(ComparisonHelper.deepEquals(properties, vertex.properties),
              isTrue);
           */
        },
        maxShrinkingTries: 0,
      );
    });
  });
}
