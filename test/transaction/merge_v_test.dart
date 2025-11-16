import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('mergeV (transactional, terminal step)', () {
    late DatabaseManager dbManager;

    setUp(() {
      dbManager = DatabaseManager();
    });

    test(
        'creates new vertex when no match, then updates same vertex on re-run (onMatch)',
        () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      try {
        Vertex first;
        Vertex second;
        await graph.transaction((txn) async {
          final now = DateTime.now().toUtc();
          final list1 = await txn.traversal().V().mergeV(
            labels: {'person'},
            match: {'name': 'Alice'},
            onCreate: {'age': 30},
          ).toList();
          expect(list1.length, 1);
          first = list1.first as Vertex;
          expect(first.labels.contains('person'), isTrue);
          expect(first.properties['name'], 'Alice');
          expect(first.properties['age'], 30);

          final list2 = await txn.traversal().V().mergeV(
            labels: {'person'},
            match: {'name': 'Alice'},
            onMatch: {'seenAt': now},
          ).toList();
          expect(list2.length, 1);
          second = list2.first as Vertex;
          expect(second.id, first.id); // same vertex
          expect(second.properties['age'], 30); // unchanged property remains
          expect(second.properties['seenAt'], isA<DateTime>());
        });
      } finally {
        await graph.close();
      }
    });

    test('matches with NullValue in match map', () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      try {
        Vertex v1;
        Vertex v2;
        await graph.transaction((txn) async {
          final list1 = await txn.traversal().V().mergeV(
            labels: {'person'},
            match: {'name': 'Carol', 'nickname': NullValue()},
            onCreate: {},
          ).toList();
          v1 = list1.first as Vertex;
          expect(v1.properties.containsKey('nickname'), isTrue);
          expect(v1.properties['nickname'], isA<NullValue>());

          final list2 = await txn.traversal().V().mergeV(
            labels: {'person'},
            match: {'name': 'Carol', 'nickname': NullValue()},
            onMatch: {'age': 40},
          ).toList();
          v2 = list2.first as Vertex;
          expect(v2.id, v1.id);
          expect(v2.properties['age'], 40);
        });
      } finally {
        await graph.close();
      }
    });

    test('multiple labels are applied on create and preserved on re-merge',
        () async {
      final db = await dbManager.openInMemory();
      final graph = Graph.fromDatabase(db);
      try {
        Vertex v1;
        Vertex v2;
        await graph.transaction((txn) async {
          final list1 = await txn.traversal().V().mergeV(
            labels: {'person', 'engineer'},
            match: {'name': 'Dave'},
            onCreate: {},
          ).toList();
          v1 = list1.first as Vertex;
          expect(v1.labels.contains('person'), isTrue);
          expect(v1.labels.contains('engineer'), isTrue);

          final list2 = await txn.traversal().V().mergeV(
            labels: {'person', 'engineer'},
            match: {'name': 'Dave'},
            onMatch: {'age': 22},
          ).toList();
          v2 = list2.first as Vertex;
          expect(v2.id, v1.id);
          expect(v2.labels.containsAll({'person', 'engineer'}), isTrue);
          expect(v2.properties['age'], 22);
        });
      } finally {
        await graph.close();
      }
    });
  });
}
