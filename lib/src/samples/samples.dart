import 'package:rinne_graph/src/graph/graph.dart';

import 'package:rinne_graph/src/samples/movies.dart';
import 'package:rinne_graph/src/samples/simple_graph.dart';

abstract class Samples {
  static Future<Graph> movies() => createMoviesGraph();

  static Future<Graph> simpleGraph() => createSimpleGraph();
}
