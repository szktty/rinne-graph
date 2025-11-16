import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('HasNot(key) Step', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('returns vertices without the key or with NullValue', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'v'}, properties: {'name': 'no_deleted'})); // missing
        await txn.createVertex(Vertex(labels: {
          'v'
        }, properties: {
          'name': 'null_deleted',
          'deleted': NullValue()
        })); // null
        await txn.createVertex(Vertex(
            labels: {'v'},
            properties: {'name': 'true_deleted', 'deleted': true})); // true
        await txn.createVertex(Vertex(
            labels: {'v'},
            properties: {'name': 'false_deleted', 'deleted': false})); // false
      });

      final traversal = graph.traversal().V().hasNot('deleted');
      final query = traversal.buildQuery();
      final rows = await graph.database.rawQuery(query.query, query.parameters);

      // Expect only the two vertices: missing key and explicit null
      // Collect their names to verify semantics clearly
      final ids = rows.map((r) => r['id'] as int).toList();
      final names = <String>[];
      await graph.transaction((txn) async {
        for (final id in ids) {
          final v = await txn.getVertex(id);
          if (v != null) names.add(v.properties['name'] as String);
        }
      });

      expect(names.toSet(), equals({'no_deleted', 'null_deleted'}));
    });
  });
}
