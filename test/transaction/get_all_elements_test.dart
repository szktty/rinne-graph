import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import '../helpers/arbitrary.dart';

void main() {
  group('get all elements', () {
    property('vertices', () {
      forAll(ArbitraryTestHelpers.graph(), (f) async {
        final g = await f;
        await g.system!.transaction((txn) async {
          final verticesStream = txn.vertices();
          final retrievedVertices = await verticesStream.toList();

          // Verify the number of retrieved vertices matches the original data
          expect(retrievedVertices.length, equals(g.vertices.length));

          // Verify the IDs of retrieved vertices match the original data
          final retrievedIds = retrievedVertices.map((v) => v.id).toSet();
          final originalIds = g.vertices.map((v) => v.id).toSet();
          expect(retrievedIds, equals(originalIds));

          // Compare each vertex in detail
          for (final originalVertex in g.vertices) {
            final retrievedVertex = retrievedVertices.firstWhere(
              (v) => v.id == originalVertex.id,
              orElse: () => throw StateError('Vertex not found'),
            );

            // Compare labels
            expect(retrievedVertex.labels, equals(originalVertex.labels));

            // Compare properties
            expect(
              retrievedVertex.properties,
              equals(originalVertex.properties),
            );

            // Compare timestamps
            //expect(retrievedVertex.createdAt, equals(originalVertex.createdAt));
            //expect(retrievedVertex.updatedAt, equals(originalVertex.updatedAt));
          }
        });
      });
    });
  });
}
