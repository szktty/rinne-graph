import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/traversal/traversal_base/traversal_base_class.dart';
import 'package:test/test.dart';

void main() {
  group('Debug Count Step Tests', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('debug hasLabel query', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Alice', 'age': 30}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob', 'age': 25}));
        await txn.createVertex(
            Vertex(labels: {'animal'}, properties: {'name': 'Fluffy'}));
      });

      // Debug hasLabel query
      final traversal1 = graph.traversal().V().hasLabel(['person']);
      final query1 = traversal1.buildQuery();
      print('hasLabel query: ${query1.query}');
      print('hasLabel parameters: ${query1.parameters}');
      final results1 =
          await graph.database.rawQuery(query1.query, query1.parameters);
      print('hasLabel results: $results1');

      // Debug count query
      final traversal2 = graph.traversal().V().hasLabel(['person']).count();
      print('Steps in traversal2:');
      final traversalBase = traversal2 as TraversalBase;
      for (var i = 0; i < traversalBase.steps.length; i++) {
        final step = traversalBase.steps[i];
        print('  Step $i: ${step.name}, inputType: ${step.inputType}, '
            'outputType: ${step.outputType}');
      }
      final query2 = traversal2.buildQuery();
      print('count query: ${query2.query}');
      print('count parameters: ${query2.parameters}');
      final results2 =
          await graph.database.rawQuery(query2.query, query2.parameters);
      print('count results: $results2');
    });

    test('debug hasKey query', () async {
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Alice', 'age': 30}));
        await txn.createVertex(
            Vertex(labels: {'person'}, properties: {'name': 'Bob', 'age': 25}));
        await txn.createVertex(Vertex(
            labels: {'person'}, properties: {'name': 'Charlie', 'age': 35}));
      });

      // Debug hasKey query
      final traversal1 = graph.traversal().V().hasKey('age', 30);
      final query1 = traversal1.buildQuery();
      print('hasKey query: ${query1.query}');
      print('hasKey parameters: ${query1.parameters}');
      final results1 =
          await graph.database.rawQuery(query1.query, query1.parameters);
      print('hasKey results: $results1');

      // Debug count query
      final traversal2 = graph.traversal().V().hasKey('age', 30).count();
      final query2 = traversal2.buildQuery();
      print('count query: ${query2.query}');
      print('count parameters: ${query2.parameters}');
      final results2 =
          await graph.database.rawQuery(query2.query, query2.parameters);
      print('count results: $results2');
    });
  });
}
