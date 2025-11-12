import 'package:rinne_graph/rinne_graph.dart';

/// Minimal console Quickstart example for RinneGraph.
///
/// Run: dart run example/example.dart
Future<void> main() async {
  // 1) Open an in-memory database
  final graph = await Graph.openInMemory();

  // 2) Create a tiny graph in a transaction
  await graph.transaction((txn) async {
    final marko = await txn.createVertex(
      Vertex(labels: {'person'}, properties: {'name': 'marko'}),
    );
    final josh = await txn.createVertex(
      Vertex(labels: {'person'}, properties: {'name': 'josh'}),
    );
    await txn.createEdge(
      Edge(
          labels: {'knows'},
          properties: {},
          fromVertexId: marko.id!,
          toVertexId: josh.id!),
    );
  });

  // 3) Run a simple traversal
  final g = graph.traversal();
  final names = await g
      .V()
      .hasLabel(['person'])
      .hasKey('name', 'marko')
      .out(['knows'])
      .values(['name'])
      .toList();

  print(names); // => ['josh']

  // 4) Close the database
  await graph.close();
}
