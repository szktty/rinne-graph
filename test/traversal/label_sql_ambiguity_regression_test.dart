import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('SQL label ambiguity regression', () {
    late DatabaseManager dbManager;

    setUp(() {
      dbManager = DatabaseManager();
    });

    test('V([id]).in_(edgeLabel).hasLabel(vertexLabel) should not be ambiguous',
        () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      addTearDown(graph.close);

      await graph.transaction((txn) async {
        final entity = await txn.createVertex(Vertex(labels: {'Entity'}));
        final task = await txn.createVertex(
          Vertex(labels: {'Task'}, properties: {'updatedAt': 2, 'name': 'T1'}),
        );
        await txn.createEdge(
          Edge(
            fromVertexId: task.id!,
            toVertexId: entity.id!,
            labels: {'HAS_ENTITY'},
          ),
        );

        final q = txn
            .traversal()
            .V([entity.id!])
            .in_(['HAS_ENTITY'])
            .hasLabel(['Task'])
            .hasNot('deleted')
            .order()
            .byKey('updatedAt', SortOrder.desc)
            .limit(200);

        final res = await q.toList();
        expect(res, isNotEmpty);
        final v = res.first as Vertex;
        expect(v.labels.contains('Task'), isTrue);
        expect(v.id, equals(task.id));
      });
    });

    test('V().out(edgeLabel).hasLabel(vertexLabel) executes without SQL error',
        () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      addTearDown(graph.close);

      await graph.transaction((txn) async {
        final a = await txn.createVertex(Vertex(labels: {'Y'}));
        final b = await txn.createVertex(Vertex(labels: {'Y'}));
        await txn.createEdge(
            Edge(fromVertexId: a.id!, toVertexId: b.id!, labels: {'X'}));

        final res =
            await txn.traversal().V().out(['X']).hasLabel(['Y']).toList();
        expect(res, isA<List<dynamic>>());
      });
    });

    test(
        'E().hasLabel(edgeLabel).inV().hasLabel(vertexLabel) executes without SQL error',
        () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      addTearDown(graph.close);

      await graph.transaction((txn) async {
        final a = await txn.createVertex(Vertex(labels: {'Y'}));
        final b = await txn.createVertex(Vertex(labels: {'Y'}));
        await txn.createEdge(
            Edge(fromVertexId: a.id!, toVertexId: b.id!, labels: {'X'}));

        final res = await txn
            .traversal()
            .E()
            .hasLabel(['X'])
            .inV()
            .hasLabel(['Y'])
            .toList();
        expect(res, isA<List<dynamic>>());
      });
    });
  });
}
