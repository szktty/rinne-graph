import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/exception.dart';
import 'package:test/test.dart';

void main() {
  group('mergeV errors and edge cases', () {
    late DatabaseManager dbManager;

    setUp(() {
      dbManager = DatabaseManager();
    });

    test('throws ArgumentError when labels is empty', () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      addTearDown(graph.close);

      await graph.transaction((txn) async {
        expect(
          () =>
              txn.traversal().V().mergeV(labels: {}, match: {'k': 1}).toList(),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    test('onCreate overrides match on create when keys overlap', () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      addTearDown(graph.close);

      await graph.transaction((txn) async {
        final list = await txn.traversal().V().mergeV(
          labels: {'person'},
          match: {'name': 'Alice', 'age': 20},
          onCreate: {'age': 30},
        ).toList();
        final v = list.first as Vertex;
        expect(v.properties['age'], 30);
      });
    });

    test('throws VertexException when match is ambiguous (multiple vertices)',
        () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      addTearDown(graph.close);

      await graph.transaction((txn) async {
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Dup'}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Dup'}));

        expect(
          () => txn
              .traversal()
              .V()
              .mergeV(labels: {'person'}, match: {'name': 'Dup'}).toList(),
          throwsA(isA<VertexException>()),
        );
      });
    });
  });
}
