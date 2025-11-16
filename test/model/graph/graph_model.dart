import 'dart:math';

import 'package:collection/collection.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/database/transaction_impl.dart';
import 'package:rinne_graph/src/traversal/sql_traversal/sql_traversal_impl.dart';

import 'traversal_model.dart';

// Need to return this for method chaining
// ignore_for_file: avoid_returning_this

final class GraphModel {
  GraphModel({
    required this.vertices,
    required this.edges,
    this.system,
  });

  final Graph? system;
  final List<Vertex> vertices;
  final List<Edge> edges;

  List<int> get vertexIds => vertices.map((v) => v.id!).toList();

  List<int> get edgeIds => edges.map((e) => e.id!).toList();

  List<String> get vertexLabels => vertices.expand((v) => v.labels).toList();

  List<String> get edgeLabels => edges.expand((e) => e.labels).toList();

  TraversalSource traversalSystem() => SqlTraversalSourceImpl(system!);

  TraversalSource traversalModel() => TraversalSourceModel(graph: this);

  GraphModel copyWith({
    Graph? system,
    List<Vertex>? vertices,
    List<Edge>? edges,
  }) {
    return GraphModel(
      system: system ?? this.system,
      vertices: vertices ?? this.vertices,
      edges: edges ?? this.edges,
    );
  }

  Future<SqlResultSet> rawQuery(
    String sql, [
    List<dynamic>? arguments,
    Map<String, String> propertyKeyMap = const {},
  ]) async {
    return SqlResultSet(
      await system!.database.rawQuery(sql, arguments),
      propertyKeyMap,
    );
  }

  // TODO(szktty): Implement on Database side
  Future<SqlResultSet> rawQuerySet(SqlQuerySet querySet) async {
    return system!.transaction((txn) async {
      for (final query in querySet.initialQueries) {
        //await txn.rawQuery(query.query, query.parameters);
        await (txn as SQLiteTransaction).execute(query.query, query.parameters);
      }

      final resultQuery = querySet.resultQuery;
      List<Map<String, dynamic>>? result;
      if (resultQuery != null) {
        result = await txn.rawQuery(
          resultQuery.query,
          resultQuery.parameters,
        );
      }

      for (final query in querySet.cleanupQueries) {
        await txn.rawQuery(query.query, query.parameters);
      }

      final propertyAliases = querySet.resultQuery?.propertyKeyMap ?? {};
      return SqlResultSet(result ?? [], propertyAliases);
    });
  }

  Future<void> addVertex(Vertex vertex) async {
    vertices.add(vertex);
    await system?.transaction((txn) => txn.createVertex(vertex));
  }

  Future<void> addEdge(Edge edge) async {
    edges.add(edge);
    await system?.transaction((txn) => txn.createEdge(edge));
  }

  Vertex? getVertexById(int id) {
    return vertices.firstWhereOrNull((v) => v.id == id);
  }

  Edge? getEdgeById(int id) {
    return edges.firstWhereOrNull((e) => e.id == id);
  }

  Element? getElementByElementId(ElementId id) {
    return id.type == ElementIdType.vertex
        ? getVertexById(id.id)
        : getEdgeById(id.id);
  }

  Vertex? get anyVertex {
    return vertices.isNotEmpty
        ? vertices.elementAt(Random().nextInt(vertices.length))
        : null;
  }

  List<Vertex> getAnyVertices([int? count]) {
    if (vertices.isEmpty) {
      return [];
    }

    count ??= Random().nextInt(vertices.length);
    return vertices.isNotEmpty
        ? List.generate(
            count,
            (_) => anyVertex!,
          )
        : [];
  }

  List<int> getAnyVertexIds([int? count]) {
    if (vertices.isEmpty) {
      return [];
    }

    count ??= Random().nextInt(vertices.length);
    final vertexIds = this.vertexIds;
    if (vertexIds.length < count) {
      return vertexIds;
    } else {
      return List.generate(
        count,
        (_) => vertexIds.elementAt(Random().nextInt(vertexIds.length)),
      );
    }
  }

  List<String> getAnyVertexLabels([int? count]) {
    if (vertices.isEmpty) {
      return [];
    }

    count ??= Random().nextInt(vertices.length);
    final vertexLabels = this.vertexLabels;
    if (vertexLabels.length < count) {
      return vertexLabels;
    } else {
      return List.generate(
        count,
        (_) => vertexLabels.elementAt(Random().nextInt(vertexLabels.length)),
      );
    }
  }

  Edge? get anyEdge {
    return edges.isNotEmpty
        ? edges.elementAt(Random().nextInt(edges.length))
        : null;
  }

  List<Edge> getAnyEdges([int? count]) {
    if (edges.isEmpty) {
      return [];
    }

    count ??= Random().nextInt(edges.length);
    return edges.isNotEmpty
        ? List.generate(
            count,
            (_) => anyEdge!,
          )
        : [];
  }

  List<int> getAnyEdgeIds([int? count]) {
    if (edges.isEmpty) {
      return [];
    }

    count ??= Random().nextInt(edges.length);
    final edgeIds = this.edgeIds;
    if (edgeIds.length < count) {
      return edgeIds;
    } else {
      return List.generate(
        count,
        (_) => edgeIds.elementAt(Random().nextInt(edgeIds.length)),
      );
    }
  }

  List<String> getAnyEdgeLabels([int? count]) {
    if (edges.isEmpty) {
      return [];
    }

    count ??= Random().nextInt(edges.length);
    final edgeLabels = this.edgeLabels;
    //print('edgeLabels: $edgeLabels');
    if (edgeLabels.length < count) {
      return edgeLabels;
    } else {
      return List.generate(
        count,
        (_) => edgeLabels.elementAt(Random().nextInt(edgeLabels.length)),
      );
    }
  }

  Element? get anyElement {
    return Random().nextBool() ? anyVertex : anyEdge;
  }

  List<Element> getAnyElements([int? count]) {
    if (vertices.isEmpty && edges.isEmpty) {
      return [];
    }

    final elements = vertices.cast<Element>() + edges.cast<Element>();
    count ??= Random().nextInt(elements.length);
    if (elements.length < count) {
      return elements;
    } else {
      return List.generate(
        count,
        (_) => elements.elementAt(Random().nextInt(elements.length)),
      );
    }
  }

  (String, dynamic)? get anyProperty {
    final element = anyElement;
    if (element != null && element.properties.isNotEmpty) {
      final property = element.properties.entries
          .elementAt(Random().nextInt(element.properties.length));
      return (property.key, property.value);
    } else {
      return null;
    }
  }

  Set<String> get allLabels {
    return vertices
        .expand((v) => v.labels)
        .toSet()
        .union(edges.expand((e) => e.labels).toSet());
  }

  TraversalSourceModel traversal() => TraversalSourceModel(
        graph: this,
      );

  TraversalModel V([List<int>? ids]) => traversal().V(ids);

  TraversalModel E([List<int>? ids]) => traversal().E(ids);
}
