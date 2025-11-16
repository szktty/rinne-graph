import 'package:rinne_graph/src/graph/graph.dart';
import 'package:rinne_graph/src/model/model.dart';

Future<Graph> createMoviesGraph() async {
  final graph = await Graph.openInMemory();

  await graph.transaction((txn) async {
    for (final vertex in movies + persons + genres) {
      await txn.createVertex(vertex);
    }
    for (final edge in edges) {
      await txn.createEdge(edge);
    }
  });

  return graph;
}

final movies = [
  Vertex(
    id: 1,
    labels: {'Movie'},
    properties: {'title': 'Casablanca', 'year': 1942},
  ),
  Vertex(
    id: 2,
    labels: {'Movie'},
    properties: {'title': 'Citizen Kane', 'year': 1941},
  ),
  Vertex(
    id: 3,
    labels: {'Movie'},
    properties: {'title': '12 Angry Men', 'year': 1957},
  ),
  Vertex(
    id: 4,
    labels: {'Movie'},
    properties: {'title': 'Psycho', 'year': 1960},
  ),
  Vertex(
    id: 5,
    labels: {'Movie'},
    properties: {'title': 'Some Like It Hot', 'year': 1959},
  ),
];

final persons = [
  Vertex(
    id: 6,
    labels: {'Person'},
    properties: {'name': 'Humphrey Bogart', 'born': 1899, 'died': 1957},
  ),
  Vertex(
    id: 7,
    labels: {'Person'},
    properties: {'name': 'Ingrid Bergman', 'born': 1915, 'died': 1982},
  ),
  Vertex(
    id: 8,
    labels: {'Person'},
    properties: {'name': 'Orson Welles', 'born': 1915, 'died': 1985},
  ),
  Vertex(
    id: 9,
    labels: {'Person'},
    properties: {'name': 'Sidney Lumet', 'born': 1924, 'died': 2011},
  ),
  Vertex(
    id: 10,
    labels: {'Person'},
    properties: {'name': 'Henry Fonda', 'born': 1905, 'died': 1982},
  ),
  Vertex(
    id: 11,
    labels: {'Person'},
    properties: {'name': 'Alfred Hitchcock', 'born': 1899, 'died': 1980},
  ),
  Vertex(
    id: 12,
    labels: {'Person'},
    properties: {'name': 'Anthony Perkins', 'born': 1932, 'died': 1992},
  ),
  Vertex(
    id: 13,
    labels: {'Person'},
    properties: {'name': 'Billy Wilder', 'born': 1906, 'died': 2002},
  ),
  Vertex(
    id: 14,
    labels: {'Person'},
    properties: {'name': 'Marilyn Monroe', 'born': 1926, 'died': 1962},
  ),
];

final genres = [
  Vertex(id: 15, labels: {'Genre'}, properties: {'name': 'Romance'}),
  Vertex(id: 16, labels: {'Genre'}, properties: {'name': 'Drama'}),
  Vertex(id: 17, labels: {'Genre'}, properties: {'name': 'Mystery'}),
  Vertex(id: 18, labels: {'Genre'}, properties: {'name': 'Thriller'}),
  Vertex(id: 19, labels: {'Genre'}, properties: {'name': 'Comedy'}),
];

final edges = [
  Edge(id: 21, fromVertexId: 6, toVertexId: 1, labels: {'ACTED_IN'}),
  Edge(id: 22, fromVertexId: 7, toVertexId: 1, labels: {'ACTED_IN'}),
  Edge(id: 23, fromVertexId: 8, toVertexId: 2, labels: {'ACTED_IN'}),
  Edge(id: 24, fromVertexId: 8, toVertexId: 2, labels: {'DIRECTED'}),
  Edge(id: 25, fromVertexId: 9, toVertexId: 3, labels: {'DIRECTED'}),
  Edge(id: 26, fromVertexId: 10, toVertexId: 3, labels: {'ACTED_IN'}),
  Edge(id: 27, fromVertexId: 11, toVertexId: 4, labels: {'DIRECTED'}),
  Edge(id: 28, fromVertexId: 12, toVertexId: 4, labels: {'ACTED_IN'}),
  Edge(id: 29, fromVertexId: 13, toVertexId: 5, labels: {'DIRECTED'}),
  Edge(id: 30, fromVertexId: 14, toVertexId: 5, labels: {'ACTED_IN'}),
  Edge(id: 31, fromVertexId: 1, toVertexId: 15, labels: {'HAS_GENRE'}),
  Edge(id: 32, fromVertexId: 1, toVertexId: 16, labels: {'HAS_GENRE'}),
  Edge(id: 33, fromVertexId: 2, toVertexId: 16, labels: {'HAS_GENRE'}),
  Edge(id: 34, fromVertexId: 2, toVertexId: 17, labels: {'HAS_GENRE'}),
  Edge(id: 35, fromVertexId: 3, toVertexId: 16, labels: {'HAS_GENRE'}),
  Edge(id: 36, fromVertexId: 4, toVertexId: 18, labels: {'HAS_GENRE'}),
  Edge(id: 37, fromVertexId: 4, toVertexId: 17, labels: {'HAS_GENRE'}),
  Edge(id: 38, fromVertexId: 5, toVertexId: 19, labels: {'HAS_GENRE'}),
  Edge(id: 39, fromVertexId: 5, toVertexId: 15, labels: {'HAS_GENRE'}),
];
