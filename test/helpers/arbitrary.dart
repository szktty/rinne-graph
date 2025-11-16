import 'dart:math';

import 'package:kiri_check/kiri_check.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

import '../model/graph/graph_model.dart';
import 'database.dart';
import 'debug_helper.dart';

abstract class ArbitraryTestHelpers {
  static Arbitrary<int> smallCount() => integer(min: 0, max: 10);

  // integer() intentionally creates bias, so there can be duplicate cases
  // Since duplicate IDs cannot be added to the database, make it completely random
  static Arbitrary<int> elementId() =>
      build(() => Random().nextInt(1000000000));

  // static Arbitrary<int> autoElementId() => integer(min: 10001, max: 20000);

  static Arbitrary<NullValue> nullValue() => constant(NullValue());

  static Arbitrary<String> identifierString() => combine2(
        string(
          minLength: 1,
          maxLength: 1,
          characterSet: CharacterSet.lower(
            CharacterEncoding.ascii,
          ),
        ),
        string(
          minLength: 1,
          maxLength: 20,
          characterSet: CharacterSet.alphanum(CharacterEncoding.ascii),
        ),
      ).map((a) => a.$1 + a.$2);

  static Arbitrary<Vertex> vertex({
    required int minLabels,
    required int maxLabels,
    required int minProperties,
    required int maxProperties,
    required Arbitrary<dynamic> propertyValueGenerator,
    int? id,
  }) =>
      combine2(
        integer(min: minLabels, max: maxLabels),
        integer(min: minProperties, max: maxProperties),
      ).map(
        (a) {
          final (labelCount, propertyCount) = a;
          final id0 = id ?? elementId().example();
          final labels0 = labels(labelCount).example();
          debugLog('create vertex: $id0 <$labels0>');
          return Vertex(
            id: id0,
            labels: labels0,
            properties:
                properties(propertyValueGenerator, propertyCount).example(),
          );
        },
      );

  static Arbitrary<Edge> edge({
    required List<Vertex> vertices,
    required int minLabels,
    required int maxLabels,
    required int minProperties,
    required int maxProperties,
    required Arbitrary<dynamic> propertyValueGenerator,
    int? id,
  }) =>
      combine2(
        integer(min: minLabels, max: maxLabels),
        integer(min: minProperties, max: maxProperties),
      ).map((a) {
        final (labelCount, propertyCount) = a;
        final random = Random();
        final id0 = id ?? elementId().example();
        final labels0 = labels(labelCount).example();
        final fromVertex = vertices[random.nextInt(vertices.length)];
        final toVertex = vertices[random.nextInt(vertices.length)];
        debugLog(
          'create edge: $id0 <$labels0> from ${fromVertex.id} to ${toVertex.id}',
        );

        return Edge(
          fromVertexId: fromVertex.id!,
          toVertexId: toVertex.id!,
          id: id0,
          labels: labels0,
          properties:
              properties(propertyValueGenerator, propertyCount).example(),
        );
      });

  static Future<GraphModel> createGraph({
    required int minVertices,
    required int maxVertices,
    required int minEdges,
    required int maxEdges,
    required int minLabels,
    required int maxLabels,
    required int minProperties,
    required int maxProperties,
    Arbitrary<dynamic>? propertyValueGenerator,
    Database? db,
  }) async {
    propertyValueGenerator ??= ArbitraryTestHelpers.propertyValue();
    final db0 = db ?? await DatabaseHelper.openInMemory();
    // If minVertices == maxVertices, use fixed value, otherwise random
    final vertexCount = minVertices == maxVertices
        ? minVertices
        : integer(min: minVertices, max: maxVertices).example();
    final edgeCount = minEdges == maxEdges
        ? minEdges
        : integer(min: minEdges, max: maxEdges).example();
    final vertices = List.generate(
      vertexCount,
      (_) => vertex(
        minLabels: minLabels,
        maxLabels: maxLabels,
        minProperties: minProperties,
        maxProperties: maxProperties,
        propertyValueGenerator: propertyValueGenerator!,
      ).example(),
    );
    final edges = vertexCount > 0
        ? List.generate(
            edgeCount,
            (_) => edge(
              vertices: vertices,
              minLabels: minLabels,
              maxLabels: maxLabels,
              minProperties: minProperties,
              maxProperties: maxProperties,
              propertyValueGenerator: propertyValueGenerator!,
            ).example(),
          )
        : <Edge>[];
    await db0.transaction((txn) async {
      for (final vertex in vertices) {
        await txn.createVertex(vertex);
      }
      for (final edge in edges) {
        await txn.createEdge(edge);
      }
    });

    // Get actual vertices and edges from database and use objects with accurate IDs
    final actualVertices =
        await db0.transaction<List<Vertex>>((txn) => txn.vertices().toList());
    final actualEdges =
        await db0.transaction<List<Edge>>((txn) => txn.edges().toList());

    final g = GraphModel(
      system: Graph.fromDatabase(db0),
      vertices: actualVertices,
      edges: actualEdges,
    );

    return g;
  }

  static Arbitrary<Future<GraphModel>> graph({
    int minVertices = 0,
    int maxVertices = 10,
    int minEdges = 0,
    int maxEdges = 10,
    int minLabels = 0,
    int maxLabels = 5,
    int minProperties = 0,
    int maxProperties = 5,
    Arbitrary<dynamic>? propertyValueGenerator,
    Database? db,
    bool useInMemory = true,
  }) =>
      build(
        () async {
          final database = db ??
              (useInMemory
                  ? await DatabaseHelper.openInMemory()
                  : await DatabaseHelper.openTemporaryFile());
          return createGraph(
            minVertices: minVertices,
            maxVertices: maxVertices,
            minEdges: minEdges,
            maxEdges: maxEdges,
            minLabels: minLabels,
            maxLabels: maxLabels,
            minProperties: minProperties,
            maxProperties: maxProperties,
            propertyValueGenerator: propertyValueGenerator,
            db: database,
          );
        },
      );

  static Arbitrary<Set<String>> labels(int count) => build(
        () => Set<String>.from(
          List.generate(
            count,
            (_) => 'L${integer(min: 1, max: 100).example()}',
          ),
        ),
      );

  static Arbitrary<Map<String, dynamic>> properties(
    Arbitrary<dynamic> generator,
    int count,
  ) =>
      build(
        () => Map<String, dynamic>.fromEntries(
          List.generate(
            count,
            (_) => MapEntry(
              identifierString().example(),
              generator.example(),
            ),
          ),
        ),
      );

  static Arbitrary<String> propertyString({
    int minLength = 0,
    int maxLength = 100,
  }) =>
      string(
        minLength: minLength,
        maxLength: maxLength,
        // UTF-8 can fail in comparisons and other operations
        //characterSet: CharacterSet.alphanum(CharacterEncoding.utf8),
        characterSet: CharacterSet.alphanum(CharacterEncoding.ascii),
      );

  static Arbitrary<DateTime> propertyDateTime() =>
      dateTime().map((v) => v.copyWith());

  static Arbitrary<dynamic> propertyValue() => oneOf([
        nullValue(),
        ArbitraryTestHelpers.propertyString(),
        integer(),
        float(infinity: false, nan: false),
        boolean(),
        propertyDateTime(),
        listProperty(),
      ]);

  static Arbitrary<List<dynamic>> listProperty() =>
      integer(min: 0, max: 10).flatMap((length) {
        final valueArbitrary = oneOf([
          ArbitraryTestHelpers.propertyString(),
          integer(),
          float(infinity: false, nan: false),
          boolean(),
        ]);

        return list(valueArbitrary, minLength: length, maxLength: length);
      });
}

Matcher containsAny<T>(Iterable<T> expected) => predicate(
      (actual) =>
          actual is Iterable && expected.any((item) => actual.contains(item)),
      'contains any element from $expected',
    );
