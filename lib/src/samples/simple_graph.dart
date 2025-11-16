// TODO(szktty): Copy samples from online Gremlin documentation.

import 'package:rinne_graph/src/graph/graph.dart';
import 'package:rinne_graph/src/samples/builder.dart';

Future<Graph> createSimpleGraph() async {
  final graph = await Graph.openInMemory();
  final builder = SampleGraphBuilder(graph);
  await builder.addAll(_sampleVertices, _sampleEdges);
  return graph;
}

Map<String, (Set<String>, Map<String, dynamic>)> _sampleVertices = {
  'peter': ({'person'}, {'name': 'peter', 'age': 35}),
  'marko': ({'person'}, {'name': 'marko', 'age': 29}),
  'josh': ({'person'}, {'name': 'josh', 'age': 32}),
  'vadas': ({'person'}, {'name': 'vadas', 'age': 27}),
  'ripple': ({'software'}, {'name': 'ripple', 'lang': 'java'}),
  'lop': ({'software'}, {'name': 'lop', 'lang': 'java'}),
};

List<(String, String, Set<String>, Map<String, dynamic>)> _sampleEdges = [
  ('peter', 'lop', {'created'}, {'weight': 0.2}),
  ('marko', 'lop', {'created'}, {'weight': 0.4}),
  ('marko', 'josh', {'knows'}, {'weight': 1.0}),
  ('marko', 'vadas', {'knows'}, {'weight': 0.5}),
  ('josh', 'ripple', {'created'}, {'weight': 1.0}),
];
