import 'package:kiri_check/kiri_check.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

import '../helpers/arbitrary.dart';
import '../helpers/debug_helper.dart';

void main() {
  initializeDebugSettings();

  group('Result Type Determination', () {
    property('V().hasKey() should return Vertex objects', () {
      forAll(ArbitraryTestHelpers.graph(), (f) async {
        final g = await f;

        // Create test vertex
        await g.system!.transaction((txn) async {
          await txn.createVertex(Vertex(
            labels: {'test'},
            properties: {'custom_id': 'test123', 'name': 'Test Node'},
          ));
        });

        // Execute traversal
        final g2 = g.system!.traversal();
        final results = await g2.V().hasKey('custom_id', 'test123').toList();

        // Verify result is Vertex object
        expect(results, isNotEmpty);
        expect(results.first, isA<Vertex>());

        final vertex = results.first as Vertex;
        expect(vertex.properties['custom_id'], equals('test123'));
        expect(vertex.properties['name'], equals('Test Node'));
      });
    });

    test('V().id() should return raw values', () async {
      final g = await ArbitraryTestHelpers.createGraph(
        minVertices: 5,
        maxVertices: 5,
        minEdges: 3,
        maxEdges: 3,
        minLabels: 1,
        maxLabels: 2,
        minProperties: 1,
        maxProperties: 3,
      );

      // Create test vertex (using unique value)
      final uniqueValue = 'Test Node ${DateTime.now().millisecondsSinceEpoch}';
      int? vertexId;
      await g.system!.transaction((txn) async {
        final vertex = await txn.createVertex(Vertex(
          labels: {'test'},
          properties: {'name': uniqueValue},
        ));
        vertexId = vertex.id;
      });

      // Execute traversal
      final g2 = g.system!.traversal();
      final results = await g2.V().hasKey('name', uniqueValue).id().toList();

      // Verify result is int
      expect(results, isNotEmpty);
      expect(results.first, isA<int>());
      expect(results.first, equals(vertexId));
    });

    test('V().values() should return raw values', () async {
      final g = await ArbitraryTestHelpers.createGraph(
        minVertices: 5,
        maxVertices: 5,
        minEdges: 3,
        maxEdges: 3,
        minLabels: 1,
        maxLabels: 2,
        minProperties: 1,
        maxProperties: 3,
      );

      // Create test vertex (using unique value)
      final uniqueValue = 'Test Node ${DateTime.now().millisecondsSinceEpoch}';
      await g.system!.transaction((txn) async {
        await txn.createVertex(Vertex(
          labels: {'test'},
          properties: {'name': uniqueValue, 'age': 25},
        ));
      });

      // Execute traversal
      final g2 = g.system!.traversal();
      final results =
          await g2.V().hasKey('name', uniqueValue).values(['name']).toList();

      // Verify result is String
      expect(results, isNotEmpty);
      expect(results.first, isA<String>());
      expect(results.first, equals(uniqueValue));
    });

    test('E().hasLabel() should return Edge objects', () async {
      final g = await ArbitraryTestHelpers.createGraph(
        minVertices: 5,
        maxVertices: 5,
        minEdges: 3,
        maxEdges: 3,
        minLabels: 1,
        maxLabels: 2,
        minProperties: 1,
        maxProperties: 3,
      );

      // Create test vertices and edges
      await g.system!.transaction((txn) async {
        final v1 = await txn.createVertex(Vertex(labels: {'person'}));
        final v2 = await txn.createVertex(Vertex(labels: {'person'}));
        await txn.createEdge(Edge(
          fromVertexId: v1.id!,
          toVertexId: v2.id!,
          labels: {'knows'},
          properties: {'since': 2020},
        ));
      });

      // Execute traversal
      final g2 = g.system!.traversal();
      final results = await g2.E().hasLabel(['knows']).toList();

      // Verify result is Edge object
      expect(results, isNotEmpty);
      expect(results.first, isA<Edge>());

      final edge = results.first as Edge;
      expect(edge.labels, contains('knows'));
      expect(edge.properties['since'], equals(2020));
    });
  });
}
