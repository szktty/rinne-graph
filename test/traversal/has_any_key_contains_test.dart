import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('hasAnyKeyContains()', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('いずれかのプロパティに値が含まれる頂点を返す', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Alice Johnson', 'email': 'alice@example.com'}));
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Bob Smith', 'email': 'bob@company.com'}));
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Charlie Brown', 'email': 'charlie@example.com'}));
      });

      // name に "Alice" が含まれる → 1件
      final results1 =
          await graph.traversal().V().hasAnyKeyContains('Alice').toList();
      expect(results1, hasLength(1));

      // email に "example" が含まれる → 2件
      final results2 =
          await graph.traversal().V().hasAnyKeyContains('example').toList();
      expect(results2, hasLength(2));
    });

    test('複数のプロパティがマッチしても同一頂点は1件のみ返る', () async {
      await graph.transaction((txn) async {
        // name と email の両方に "alice" が含まれる
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {
              'name': 'alice',
              'email': 'alice@example.com',
              'note': 'nothing here',
            }));
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Bob', 'email': 'bob@example.com'}));
      });

      final results =
          await graph.traversal().V().hasAnyKeyContains('alice').toList();
      expect(results, hasLength(1));
    });

    test('どのプロパティにも含まれない場合は空を返す', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Alice', 'email': 'alice@example.com'}));
      });

      final results =
          await graph.traversal().V().hasAnyKeyContains('zzz').toList();
      expect(results, isEmpty);
    });

    test('数値プロパティはマッチ対象にならない', () async {
      await graph.transaction((txn) async {
        // age は数値型なので LIKE の対象外
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Alice', 'age': 30}));
      });

      // "30" という文字列で検索しても数値プロパティにはマッチしない
      final results =
          await graph.traversal().V().hasAnyKeyContains('30').toList();
      expect(results, isEmpty);
    });

    test('hasLabel と組み合わせられる', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'},
            properties: {'name': 'Alice', 'email': 'alice@example.com'}));
        await txn.createVertex(Vertex(
            labels: {'product'},
            properties: {'name': 'Alice Speaker', 'description': 'Smart speaker'}));
      });

      // person ラベルかつ "alice" を含む → 1件
      final results = await graph
          .traversal()
          .V()
          .hasLabel(['person'])
          .hasAnyKeyContains('alice')
          .toList();
      expect(results, hasLength(1));
    });

    test('頂点が0件のグラフでは空を返す', () async {
      final results =
          await graph.traversal().V().hasAnyKeyContains('Alice').toList();
      expect(results, isEmpty);
    });
  });
}
