import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('mergeE (transactional, terminal step)', () {
    late DatabaseManager dbManager;

    setUp(() {
      dbManager = DatabaseManager();
    });

    test(
        'creates new edge when no match, then updates same edge on re-run (onMatch)',
        () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      try {
        await graph.transaction((txn) async {
          final v1 = await txn.createVertex(
              Vertex(labels: {'person'}, properties: {'name': 'Alice'}));
          final v2 = await txn.createVertex(
              Vertex(labels: {'person'}, properties: {'name': 'Bob'}));

          final list1 = await txn
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
                onCreate: {'weight': 0.5},
              )
              .toList();

          expect(list1.length, 1);
          final e1 = list1.first as Edge;
          expect(e1.labels.contains('knows'), isTrue);
          expect(e1.fromVertexId, v1.id);
          expect(e1.toVertexId, v2.id);
          expect(e1.properties['since'], 2020);
          expect(e1.properties['weight'], 0.5);

          final list2 = await txn
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
                onMatch: {'updated': true},
              )
              .toList();

          final e2 = list2.first as Edge;
          expect(e2.id, e1.id);
          expect(e2.properties['since'], 2020);
          expect(e2.properties['weight'], 0.5);
          expect(e2.properties['updated'], true);
        });
      } finally {
        await graph.close();
      }
    });

    test('matches with NullValue in match map (edge property)', () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      try {
        await graph.transaction((txn) async {
          final v1 = await txn.createVertex(
              Vertex(labels: {'p'}, properties: {'name': 'Carol'}));
          final v2 = await txn.createVertex(
              Vertex(labels: {'p'}, properties: {'name': 'Dave'}));

          final list1 = await txn
              .traversal()
              .V([v1.id!])
              .as('a')
              .V([v2.id!])
              .as('b')
              .mergeE(
                labels: {'link'},
                match: {'note': NullValue()},
                fromAlias: 'a',
                toAlias: 'b',
                onCreate: {},
              )
              .toList();

          final e1 = list1.first as Edge;
          expect(e1.properties.containsKey('note'), isTrue);
          expect(e1.properties['note'], isA<NullValue>());

          final list2 = await txn
              .traversal()
              .V([v1.id!])
              .as('a')
              .V([v2.id!])
              .as('b')
              .mergeE(
                labels: {'link'},
                match: {'note': NullValue()},
                fromAlias: 'a',
                toAlias: 'b',
                onMatch: {'age': 40},
              )
              .toList();

          final e2 = list2.first as Edge;
          expect(e2.id, e1.id);
          expect(e2.properties['age'], 40);
        });
      } finally {
        await graph.close();
      }
    });

    test(
        'multiple labels are applied on create and preserved on re-merge (edge)',
        () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      try {
        await graph.transaction((txn) async {
          final v1 = await txn
              .createVertex(Vertex(labels: {'p'}, properties: {'name': 'Eve'}));
          final v2 = await txn.createVertex(
              Vertex(labels: {'p'}, properties: {'name': 'Frank'}));

          final list1 = await txn
              .traversal()
              .V([v1.id!])
              .as('a')
              .V([v2.id!])
              .as('b')
              .mergeE(
                labels: {'friend', 'colleague'},
                match: {'kind': 'work'},
                fromAlias: 'a',
                toAlias: 'b',
                onCreate: {},
              )
              .toList();

          final e1 = list1.first as Edge;
          expect(e1.labels.containsAll({'friend', 'colleague'}), isTrue);

          final list2 = await txn
              .traversal()
              .V([v1.id!])
              .as('a')
              .V([v2.id!])
              .as('b')
              .mergeE(
                labels: {'friend', 'colleague'},
                match: {'kind': 'work'},
                fromAlias: 'a',
                toAlias: 'b',
                onMatch: {'level': 2},
              )
              .toList();

          final e2 = list2.first as Edge;
          expect(e2.id, e1.id);
          expect(e2.labels.containsAll({'friend', 'colleague'}), isTrue);
          expect(e2.properties['level'], 2);
        });
      } finally {
        await graph.close();
      }
    });
  });
}
