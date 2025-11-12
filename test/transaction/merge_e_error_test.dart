import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/exception.dart';
import 'package:test/test.dart';

void main() {
  group('mergeE errors and edge cases', () {
    late DatabaseManager dbManager;

    setUp(() {
      dbManager = DatabaseManager();
    });

    test('throws ArgumentError when alias is missing (no V([id]).as(label))',
        () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      addTearDown(graph.close);

      await graph.transaction((txn) async {
        // no alias defined
        expect(
          () => txn.traversal().V().mergeE(
            labels: {'x'},
            match: {},
            fromAlias: 'a',
            toAlias: 'b',
          ).toList(),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    test('throws EdgeException when match is ambiguous (multiple edges)',
        () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      addTearDown(graph.close);

      await graph.transaction((txn) async {
        final v1 = await txn
            .createVertex(Vertex(labels: {'p'}, properties: {'n': 'A'}));
        final v2 = await txn
            .createVertex(Vertex(labels: {'p'}, properties: {'n': 'B'}));
        // create two identical edges
        await txn.createEdge(Edge(
            fromVertexId: v1.id!,
            toVertexId: v2.id!,
            labels: {'knows'},
            properties: {'since': 2020}));
        await txn.createEdge(Edge(
            fromVertexId: v1.id!,
            toVertexId: v2.id!,
            labels: {'knows'},
            properties: {'since': 2020}));

        expect(
          () => txn
              .traversal()
              .V([v1.id!])
              .as('a')
              .V([v2.id!])
              .as('b')
              .mergeE(
                labels: {'knows'},
                match: {'since': 2020},
                fromAlias: 'a',
                toAlias: 'b',
              )
              .toList(),
          throwsA(isA<EdgeException>()),
        );
      });
    });

    test('onMatch with NullValue clears property to null', () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      addTearDown(graph.close);

      await graph.transaction((txn) async {
        final v1 = await txn
            .createVertex(Vertex(labels: {'p'}, properties: {'n': 'A'}));
        final v2 = await txn
            .createVertex(Vertex(labels: {'p'}, properties: {'n': 'B'}));

        final created = await txn
            .traversal()
            .V([v1.id!])
            .as('a')
            .V([v2.id!])
            .as('b')
            .mergeE(
              labels: {'knows'},
              match: {'since': 2020},
              fromAlias: 'a',
              toAlias: 'b',
              onCreate: {'note': 'str:hello'},
            )
            .toList();
        final e1 = created.first as Edge;
        expect(e1.properties['note'], 'str:hello');

        final updated = await txn
            .traversal()
            .V([v1.id!])
            .as('a')
            .V([v2.id!])
            .as('b')
            .mergeE(
              labels: {'knows'},
              match: {'since': 2020},
              fromAlias: 'a',
              toAlias: 'b',
              onMatch: {'note': NullValue()},
            )
            .toList();
        final e2 = updated.first as Edge;
        expect(e2.properties['note'], isA<NullValue>());
      });
    });
  });
}
