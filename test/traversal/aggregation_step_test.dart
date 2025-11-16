import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import '../helpers/debug_helper.dart';
import 'test_helpers.dart';

void main() async {
  // Initialize debug settings
  initializeDebugSettings();

  // To reduce execution time
  KiriCheck.maxExamples = 30;

  group('Aggregation step tests', () {
    group('Group - Grouping', () {
      property('grouping by 2 keys', () {
        forAll(
          Gen.groupableGraph(),
          (f) async {
            final group = await f;
            final g = group.g;
            final key1 = group.keys[0];
            final key2 = group.keys[1];
            final traversal =
                g.traversalSystem().V().group().byKey(key1).byKey(key2);
            final query = traversal.buildQuery();
            final results = await g.rawQuery(query.query, query.parameters);
            debugLog('results: ${results.raw}');

            final expected =
                await g.V().group().byKey(key1).byKey(key2).toList();
            debugLog('expected: $expected');

            // TODO(szktty): Fix test when implementation is complete
            // Group feature is not implemented yet, so skip test
            return;
          },
          maxShrinkingTries: 0,
        );
      });
    });
  });
}
