import 'dart:math';

import 'package:kiri_check/kiri_check.dart';
import 'package:rinne_graph/rinne_graph.dart';
import '../helpers/helpers.dart';

/// Common constants used in traversal step tests
const propertyKeysWithSameTypes = [
  'prop_null',
  'prop_boolean',
  'prop_integer',
  'prop_float',
  'prop_string',
  'prop_datetime',
];

/// Create vertices with same property keys and types
Future<List<int>> createVertexWithSamePropertyKeysAndTypes(
  GraphModel g, {
  int? count,
}) async {
  count ??= 5;

  final vertices = <Vertex>[];
  for (var i = 0; i < count; i++) {
    final vertex = Vertex(
      id: ArbitraryTestHelpers.elementId().example(),
      properties: {
        'prop_null': null,
        'prop_boolean': boolean().example(),
        'prop_integer': integer().example(),
        'prop_float': float().example(),
        'prop_string': ArbitraryTestHelpers.propertyString().example(),
        'prop_datetime': dateTime().example().toUtc(),
      },
    );
    await g.addVertex(vertex);
    vertices.add(vertex);
  }
  return vertices.map((e) => e.id!).toList();
}

/// Create vertices with random type properties
Future<List<int>> createVertexWithSamePropertyKeysAndRandomTypes(
  GraphModel g, {
  int? count,
}) async {
  count ??= 5;

  final vertices = <Vertex>[];
  for (var i = 0; i < count; i++) {
    final vertex = Vertex(
      id: ArbitraryTestHelpers.elementId().example(),
      properties: {
        'value': ArbitraryTestHelpers.propertyValue().example(),
      },
    );
    await g.addVertex(vertex);
    vertices.add(vertex);
  }
  return vertices.map((e) => e.id!).toList();
}

/// Class representing a groupable graph
final class GroupableGraph {
  GroupableGraph({
    required this.g,
    required this.labels,
    required this.keys,
  });

  final GraphModel g;
  final List<String> labels;
  final List<String> keys;
}

/// Graph generation class for testing
abstract class Gen {
  /// Generate a groupable graph
  static Arbitrary<Future<GroupableGraph>> groupableGraph() => build(() async {
        final db = await DatabaseHelper.openInMemory();
        final g = Graph.fromDatabase(db);
        final idGen = ArbitraryTestHelpers.identifierString();
        const propValues = ['a', 'b', 'c', 'd', 'e'];
        final propGen = constantFrom(propValues);
        final random = Random();

        final labels = List.generate(5, (_) => idGen.example()).toList();
        final keys = List.generate(5, (_) => idGen.example()).toList();
        final vertices = List.generate(
          20,
          (i) => Vertex(
            // Set to null to auto-generate ID
            labels: labels.toSet(),
            properties: Map.fromEntries(
              keys.map((key) => MapEntry(key, propGen.example())),
            ),
          ),
        );

        // Create vertices and get IDs
        final createdVertices = <Vertex>[];
        for (final vertex in vertices) {
          final created =
              await db.transaction((txn) => txn.createVertex(vertex));
          createdVertices.add(created);
        }

        final edges = List.generate(
          20,
          (i) => Edge(
            fromVertexId:
                createdVertices[random.nextInt(createdVertices.length)].id!,
            toVertexId:
                createdVertices[random.nextInt(createdVertices.length)].id!,
            // Set to null to auto-generate ID
            labels: labels.toSet(),
            properties: Map.fromEntries(
              keys.map((key) => MapEntry(key, propGen.example())),
            ),
          ),
        );
        final createdEdges = <Edge>[];
        for (final edge in edges) {
          final created = await db.transaction((txn) => txn.createEdge(edge));
          createdEdges.add(created);
        }
        final model = GraphModel(
            system: g, vertices: createdVertices, edges: createdEdges);
        return GroupableGraph(
          g: model,
          labels: labels.toList(),
          keys: keys.toList(),
        );
      });
}
