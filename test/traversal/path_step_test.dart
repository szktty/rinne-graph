import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import '../helpers/debug_helper.dart';
import '../helpers/helpers.dart';

void main() async {
  // Initialize debug settings
  initializeDebugSettings();

  // To reduce execution time
  KiriCheck.maxExamples = 30;

  group('Path step tests', () {
    property('traversal path basic', () {
      forAll(
        ArbitraryTestHelpers.graph(
          minVertices: 10,
          minEdges: 10,
          maxProperties: 0,
        ),
        (f) async {
          final g = await f;
          //final traversal = g.traversalSystem().V().out();
          //final traversal = g.traversalSystem().V().out().path();
          final traversal = g.traversalSystem().V().out().id().path();
          //final traversal = g.traversalSystem().V().out().id();
          final querySet = traversal.buildQuerySet();

          final results = await g.rawQuerySet(querySet);
          debugLog('results: ${results.raw}');

          final paths = results.getTraversalPaths();
          debugLog('paths: $paths');

          // Verify paths are retrieved correctly
          expect(paths, isNotEmpty);

          // Verify each path has appropriate structure
          for (final path in paths) {
            expect(path.length, greaterThan(0));
            expect(path.objects, isNotEmpty);
          }
        },
        maxShrinkingTries: 0,
      );
    });
  });
}
