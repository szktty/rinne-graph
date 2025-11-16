import 'package:rinne_graph/src/database/database.dart';
import 'package:rinne_graph/src/model/model.dart';
import 'package:rinne_graph/src/traversal/sql_traversal/sql_query.dart';

class GraphLoader {
  GraphLoader({this.db, this.getVertex, this.getEdge}) {
    if (db == null && (getVertex == null || getEdge == null)) {
      throw ArgumentError(
        'Either db or both getVertex and getEdge must be provided',
      );
    }
  }

  final Database? db;
  final Future<Vertex?> Function(int)? getVertex;
  final Future<Edge?> Function(int)? getEdge;

  Future<List<dynamic>> loadFromQueryResult(
    List<Map<String, dynamic>> queryResult,
    SqlQueryResultType resultType,
  ) async {
    if (db != null) {
      return db!.transaction((txn) async {
        return _loadFromQueryResult(
          queryResult,
          resultType,
          getVertex: txn.getVertex,
          getEdge: txn.getEdge,
        );
      });
    } else {
      return _loadFromQueryResult(
        queryResult,
        resultType,
        getVertex: getVertex!,
        getEdge: getEdge!,
      );
    }
  }

  Future<List<dynamic>> _loadFromQueryResult(
    List<Map<String, dynamic>> queryResult,
    SqlQueryResultType resultType, {
    required Future<Vertex?> Function(int) getVertex,
    required Future<Edge?> Function(int) getEdge,
  }) async {
    switch (resultType) {
      case SqlQueryResultType.vertex:
        return _loadVertices(getVertex, queryResult);
      case SqlQueryResultType.edge:
        return _loadEdges(getEdge, queryResult);
      case SqlQueryResultType.mixed:
        return _loadMixed(getVertex, getEdge, queryResult);
      case SqlQueryResultType.raw:
        return queryResult;
    }
  }

  Future<List<Vertex>> _loadVertices(
    Future<Vertex?> Function(int) getVertex,
    List<Map<String, dynamic>> rows,
  ) async {
    final vertices = <Vertex>[];
    for (final row in rows) {
      final vertex = await getVertex(row['id'] as int);
      if (vertex != null) {
        vertices.add(vertex);
      }
    }
    return vertices;
  }

  Future<List<Edge>> _loadEdges(
    Future<Edge?> Function(int) getEdge,
    List<Map<String, dynamic>> rows,
  ) async {
    final edges = <Edge>[];
    for (final row in rows) {
      final edge = await getEdge(row['id'] as int);
      if (edge != null) {
        edges.add(edge);
      }
    }
    return edges;
  }

  Future<List<dynamic>> _loadMixed(
    Future<Vertex?> Function(int) getVertex,
    Future<Edge?> Function(int) getEdge,
    List<Map<String, dynamic>> rows,
  ) async {
    final results = <dynamic>[];
    for (final row in rows) {
      if (row.containsKey('from_vertex_id')) {
        final edge = await getEdge(row['id'] as int);
        if (edge != null) {
          results.add(edge);
        }
      } else {
        final vertex = await getVertex(row['id'] as int);
        if (vertex != null) {
          results.add(vertex);
        }
      }
    }
    return results;
  }
}
