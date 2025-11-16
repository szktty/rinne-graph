import 'package:rinne_graph/src/graph/graph.dart';
import 'package:rinne_graph/src/model/model.dart';

// TODO(szktty): Enable graph construction using only literals.
// vertex [{alias:element}], edge [{alias:element}]
final class SampleGraphBuilder {
  SampleGraphBuilder(this.graph);

  Graph graph;
  int nextId = 0;

  Map<String, Vertex> vertexMap = {};

  Vertex vertex(Set<String> labels, Map<String, dynamic> properties) {
    return Vertex(id: nextId++, labels: labels, properties: properties);
  }

  Edge edge(Set<String> labels, Map<String, dynamic> properties,
      {required Vertex from, required Vertex to}) {
    return Edge(
        id: nextId++,
        labels: labels,
        properties: properties,
        fromVertexId: from.id!,
        toVertexId: to.id!);
  }

  Future<void> addAll(
      Map<String, (Set<String>, Map<String, dynamic>)> vertexMap,
      List<(String, String, Set<String>, Map<String, dynamic>)>
          edgeList) async {
    await graph.transaction((txn) async {
      for (final entry in vertexMap.entries) {
        final v = vertex(entry.value.$1, entry.value.$2);
        final created = await txn.createVertex(v);
        this.vertexMap[entry.key] = created;
      }
      for (final desc in edgeList) {
        final e = edge(desc.$3, desc.$4,
            from: this.vertexMap[desc.$1]!, to: this.vertexMap[desc.$2]!);
        await txn.createEdge(e);
      }
    });
  }
}
