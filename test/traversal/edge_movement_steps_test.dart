import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Edge Movement Steps Tests', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('outE() - get outgoing edges', () async {
      late int aliceId;
      late int bobId;
      late int charlieId;

      await graph.transaction((txn) async {
        final alice = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        final bob = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
        final charlie = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Charlie'}));

        aliceId = alice.id!;
        bobId = bob.id!;
        charlieId = charlie.id!;

        await txn.createEdge(
            Edge(fromVertexId: aliceId, toVertexId: bobId, labels: {'knows'}));
        await txn.createEdge(Edge(
            fromVertexId: aliceId, toVertexId: charlieId, labels: {'likes'}));
        await txn.createEdge(Edge(
            fromVertexId: bobId, toVertexId: charlieId, labels: {'knows'}));
      });

      // Get outgoing edges from Alice
      final traversal = graph.traversal().V([aliceId]).outE();
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify 2 outgoing edges from Alice are retrieved
      expect(results, hasLength(2));
    });

    test('inE() - get incoming edges', () async {
      late int aliceId;
      late int bobId;
      late int charlieId;

      await graph.transaction((txn) async {
        final alice = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        final bob = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
        final charlie = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Charlie'}));

        aliceId = alice.id!;
        bobId = bob.id!;
        charlieId = charlie.id!;

        await txn.createEdge(Edge(
            fromVertexId: aliceId, toVertexId: charlieId, labels: {'knows'}));
        await txn.createEdge(Edge(
            fromVertexId: bobId, toVertexId: charlieId, labels: {'likes'}));
      });

      // Get incoming edges to Charlie
      final traversal = graph.traversal().V([charlieId]).inE();
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify 2 incoming edges to Charlie are retrieved
      expect(results, hasLength(2));
    });

    test('bothE() - get all connected edges', () async {
      late int aliceId;
      late int bobId;
      late int charlieId;

      await graph.transaction((txn) async {
        final alice = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        final bob = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));
        final charlie = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Charlie'}));

        aliceId = alice.id!;
        bobId = bob.id!;
        charlieId = charlie.id!;

        await txn.createEdge(
            Edge(fromVertexId: aliceId, toVertexId: bobId, labels: {'knows'}));
        await txn.createEdge(Edge(
            fromVertexId: charlieId, toVertexId: bobId, labels: {'likes'}));
      });

      // Get all edges connected to Bob
      final traversal = graph.traversal().V([bobId]).bothE();
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify 2 edges connected to Bob are retrieved
      expect(results, hasLength(2));
    });

    test('outV() - get source vertex from edge', () async {
      late int edgeId;

      await graph.transaction((txn) async {
        final alice = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        final bob = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));

        final edge = await txn.createEdge(Edge(
            fromVertexId: alice.id!, toVertexId: bob.id!, labels: {'knows'}));

        edgeId = edge.id!;
      });

      // Get source vertex from edge
      final traversal = graph.traversal().E([edgeId]).outV();
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify 1 vertex is retrieved
      expect(results, hasLength(1));
    });

    test('inV() - get target vertex from edge', () async {
      late int edgeId;

      await graph.transaction((txn) async {
        final alice = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        final bob = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));

        final edge = await txn.createEdge(Edge(
            fromVertexId: alice.id!, toVertexId: bob.id!, labels: {'knows'}));

        edgeId = edge.id!;
      });

      // Get target vertex from edge
      final traversal = graph.traversal().E([edgeId]).inV();
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify 1 vertex is retrieved
      expect(results, hasLength(1));
    });

    test('bothV() - get both vertices from edge', () async {
      late int edgeId;

      await graph.transaction((txn) async {
        final alice = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        final bob = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));

        final edge = await txn.createEdge(Edge(
            fromVertexId: alice.id!, toVertexId: bob.id!, labels: {'knows'}));

        edgeId = edge.id!;
      });

      // Get both vertices from edge
      final traversal = graph.traversal().E([edgeId]).bothV();
      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify 2 vertices are retrieved
      expect(results, hasLength(2));
    });

    test('simple edge traversal chain', () async {
      late int aliceId;

      await graph.transaction((txn) async {
        final alice = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
        final bob = await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob'}));

        aliceId = alice.id!;

        await txn.createEdge(Edge(
            fromVertexId: alice.id!, toVertexId: bob.id!, labels: {'knows'}));
      });

      // Alice -> outE -> inV (Alice -> Bob)
      final traversal = graph.traversal().V([aliceId]).outE(['knows']).inV();

      final query = traversal.buildQuery();
      final results =
          await graph.database.rawQuery(query.query, query.parameters);

      // Verify edge traversal chain works correctly
      expect(results, hasLength(1)); // Bob
    });
  });
}
