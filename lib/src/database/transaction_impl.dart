import 'package:rinne_graph/src/database/helper.dart';
import 'package:rinne_graph/src/database/schema.dart';
import 'package:rinne_graph/src/database/transaction_intf.dart';
import 'package:rinne_graph/src/exception.dart';
import 'package:rinne_graph/src/graph/event_manager.dart';
import 'package:rinne_graph/src/graph/events.dart';
import 'package:rinne_graph/src/graph/graph_intf.dart';
import 'package:rinne_graph/src/model/model.dart';
import 'package:rinne_graph/src/traversal/sql_traversal/sql_transactional_traversal_impl.dart';
import 'package:rinne_graph/src/util/debug_logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite;

class SQLiteTransaction implements Transaction {
  SQLiteTransaction(this._txn, this._eventManager, this._graph)
      : _transactionId = DateTime.now().millisecondsSinceEpoch.toString();

  final sqflite.Transaction _txn;
  final GraphEventManager _eventManager;
  final Graph? _graph;
  final String _transactionId;

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) {
    debugLogger.logSql(sql, arguments);
    return _txn.rawQuery(sql, arguments);
  }

  @override
  Future<void> execute(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    debugLogger.logSql(sql, arguments);
    await _txn.execute(sql, arguments);
  }

  @override
  Future<Vertex> createVertex(Vertex vertex) async {
    try {
      int id;
      if (vertex.id != null) {
        id = vertex.id!;
        await _txn.insert('vertices', {'id': id});
      } else {
        id = await _txn.insert('vertices', {}, nullColumnHack: 'id');
      }

      for (final label in vertex.labels) {
        await _txn.insert('vertex_labels', {
          'vertex_id': id,
          'label': label,
        });

        // Fire label addition event
        if (_eventManager is GraphEventManagerImpl) {
          _eventManager.fireEvent(VertexLabelEvent(
            vertexId: id,
            allLabels: vertex.labels,
            label: label,
            eventType: LabelEventType.added,
            transactionId: _transactionId,
          ));
        }
      }

      await _insertVertexProperties(id, vertex.properties);

      return vertex.copyWith(id: id);
    } catch (e) {
      throw VertexException('Failed to create vertex: $e');
    }
  }

  @override
  Future<Vertex?> getVertex(int vertexId) async {
    try {
      final vertexResult =
          await _txn.query('vertices', where: 'id = ?', whereArgs: [vertexId]);
      if (vertexResult.isEmpty) return null;

      final labelsResult = await _txn.query(
        'vertex_labels',
        where: 'vertex_id = ?',
        whereArgs: [vertexId],
      );
      final labels = labelsResult.map((row) => row['label']! as String).toSet();

      final properties = await _getVertexProperties(vertexId);

      return Vertex(
        id: vertexId,
        labels: labels,
        properties: properties,
      );
    } catch (e) {
      throw VertexException('Failed to get vertex: $e');
    }
  }

  @override
  Future<void> updateVertex(Vertex vertex) async {
    try {
      await _txn.delete(
        'vertex_labels',
        where: 'vertex_id = ?',
        whereArgs: [vertex.id],
      );
      for (final label in vertex.labels) {
        await _txn.insert('vertex_labels', {
          'vertex_id': vertex.id,
          'label': label,
        });
      }

      await _txn.delete(
        'vertex_properties',
        where: 'vertex_id = ?',
        whereArgs: [vertex.id],
      );

      await _insertVertexProperties(vertex.id!, vertex.properties);
    } catch (e) {
      throw VertexException('Failed to update vertex: $e');
    }
  }

  @override
  Future<void> deleteVertex(int vertexId) async {
    try {
      await _txn.delete('vertices', where: 'id = ?', whereArgs: [vertexId]);
    } catch (e) {
      throw VertexException('Failed to delete vertex: $e');
    }
  }

  @override
  Future<Edge> createEdge(Edge edge) async {
    try {
      final baseProperties = {
        'from_vertex_id': edge.fromVertexId,
        'to_vertex_id': edge.toVertexId,
      };

      int id;
      if (edge.id != null) {
        id = edge.id!;
        await _txn.insert('edges', {'id': id, ...baseProperties});
      } else {
        id = await _txn.insert('edges', baseProperties, nullColumnHack: 'id');
      }

      for (final label in edge.labels) {
        await _txn.insert('edge_labels', {
          'edge_id': id,
          'label': label,
        });

        // Fire label addition event
        if (_eventManager is GraphEventManagerImpl) {
          _eventManager.fireEvent(EdgeLabelEvent(
            edgeId: id,
            allLabels: edge.labels,
            label: label,
            eventType: LabelEventType.added,
            transactionId: _transactionId,
          ));
        }
      }

      await _insertEdgeProperties(id, edge.properties);

      return edge.copyWith(id: id);
    } catch (e) {
      throw EdgeException('Failed to create edge: $e');
    }
  }

  @override
  Future<Edge?> getEdge(int edgeId) async {
    try {
      final edgeResult =
          await _txn.query('edges', where: 'id = ?', whereArgs: [edgeId]);
      if (edgeResult.isEmpty) return null;
      final edge = edgeResult.first;

      final labelsResult = await _txn.query(
        'edge_labels',
        where: 'edge_id = ?',
        whereArgs: [edgeId],
      );
      final labels = labelsResult.map((row) => row['label']! as String).toSet();

      final properties = await _getEdgeProperties(edgeId);

      return Edge(
        id: edgeId,
        fromVertexId: edge['from_vertex_id']! as int,
        toVertexId: edge['to_vertex_id']! as int,
        labels: labels,
        properties: properties,
      );
    } catch (e) {
      throw EdgeException('Failed to get edge: $e');
    }
  }

  @override
  Future<void> updateEdge(Edge edge) async {
    try {
      await _txn.update(
        'edges',
        {
          'from_vertex_id': edge.fromVertexId,
          'to_vertex_id': edge.toVertexId,
        },
        where: 'id = ?',
        whereArgs: [edge.id],
      );

      await _txn.delete(
        'edge_labels',
        where: 'edge_id = ?',
        whereArgs: [edge.id],
      );

      for (final label in edge.labels) {
        await _txn.insert('edge_labels', {
          'edge_id': edge.id,
          'label': label,
        });
      }

      await _txn.delete(
        'edge_properties',
        where: 'edge_id = ?',
        whereArgs: [edge.id],
      );

      await _insertEdgeProperties(edge.id!, edge.properties);
    } catch (e) {
      throw EdgeException('Failed to update edge: $e');
    }
  }

  @override
  Future<void> deleteEdge(int edgeId) async {
    try {
      await _txn.delete('edges', where: 'id = ?', whereArgs: [edgeId]);
    } catch (e) {
      throw EdgeException('Failed to delete edge: $e');
    }
  }

  @override
  Future<List<Vertex>> getVerticesWithLabel(String label) async {
    try {
      final verticesResult = await _txn.query(
        'vertex_labels',
        where: 'label = ?',
        whereArgs: [label],
      );
      final vertices = await Future.wait(
        verticesResult.map((row) => getVertex(row['vertex_id']! as int)),
      );
      return vertices.whereType<Vertex>().toList();
    } catch (e) {
      throw VertexException('Failed to get vertices with label: $e');
    }
  }

  @override
  Future<List<Edge>> getEdgesWithLabel(String label) async {
    try {
      final edgesResult = await _txn.query(
        'edge_labels',
        where: 'label = ?',
        whereArgs: [label],
      );
      final edges = await Future.wait(
        edgesResult.map((row) => getEdge(row['edge_id']! as int)),
      );
      return edges.whereType<Edge>().toList();
    } catch (e) {
      throw EdgeException('Failed to get edges with label: $e');
    }
  }

  @override
  Future<List<Edge>> getEdgesFromVertex(int vertexId) async {
    try {
      final results = await _txn.query(
        'edges',
        where: 'from_vertex_id = ?',
        whereArgs: [vertexId],
      );
      return await Future.wait(
        results.map((map) async {
          final edgeId = map['id']! as int;
          final labels = await _getEdgeLabels(edgeId);
          final properties = await _getEdgeProperties(edgeId);
          return Edge(
            id: edgeId,
            fromVertexId: map['from_vertex_id']! as int,
            toVertexId: map['to_vertex_id']! as int,
            labels: labels,
            properties: properties,
          );
        }),
      );
    } catch (e) {
      throw EdgeException('Failed to get edges from vertex: $e');
    }
  }

  @override
  Future<List<Edge>> getEdgesToVertex(int vertexId) async {
    try {
      final results = await _txn.query(
        'edges',
        where: 'to_vertex_id = ?',
        whereArgs: [vertexId],
      );
      return await Future.wait(
        results.map((map) async {
          final edgeId = map['id']! as int;
          final labels = await _getEdgeLabels(edgeId);
          final properties = await _getEdgeProperties(edgeId);
          return Edge(
            id: edgeId,
            fromVertexId: map['from_vertex_id']! as int,
            toVertexId: map['to_vertex_id']! as int,
            labels: labels,
            properties: properties,
          );
        }),
      );
    } catch (e) {
      throw EdgeException('Failed to get edges to vertex: $e');
    }
  }

  @override
  Stream<Vertex> vertices({
    List<int>? ids,
    List<String>? labels,
  }) async* {
    var query = 'SELECT v.id, v.created_at, v.updated_at FROM vertices v';
    final arguments = <dynamic>[];

    if (ids != null && ids.isNotEmpty) {
      query += ' WHERE v.id IN (${List.filled(ids.length, '?').join(', ')})';
      arguments.addAll(ids);
    }

    if (labels != null && labels.isNotEmpty) {
      final labelJoin = labels.map((_) => '?').join(', ');
      query += ids != null && ids.isNotEmpty ? ' AND' : ' WHERE';
      query +=
          ' v.id IN (SELECT vertex_id FROM vertex_labels WHERE label IN ($labelJoin))';
      arguments.addAll(labels);
    }

    final results = await _txn.rawQuery(query, arguments);

    // Optimize: Batch fetch all labels and properties to avoid N+1 queries
    if (results.isEmpty) {
      return;
    }

    final vertexIds = results.map((row) => row['id']! as int).toList();

    // Batch fetch all labels
    final labelsMap = await _getBatchVertexLabels(vertexIds);

    // Batch fetch all properties
    final propertiesMap = await _getBatchVertexProperties(vertexIds);

    for (final row in results) {
      final vertexId = row['id']! as int;
      final labels = labelsMap[vertexId] ?? <String>{};
      final properties = propertiesMap[vertexId] ?? <String, dynamic>{};

      yield Vertex(
        id: vertexId,
        labels: labels,
        properties: properties,
        createdAt: DateTime.parse(row['created_at']! as String),
        updatedAt: DateTime.parse(row['updated_at']! as String),
      );
    }
  }

  @override
  Stream<Edge> edges({
    List<int>? ids,
    List<String>? labels,
    int? fromVertexId,
    int? toVertexId,
  }) async* {
    var query = '''
    SELECT e.id, e.from_vertex_id, e.to_vertex_id, e.created_at, e.updated_at
    FROM edges e
  ''';
    final arguments = <dynamic>[];

    final conditions = <String>[];

    if (ids != null && ids.isNotEmpty) {
      conditions.add('e.id IN (${List.filled(ids.length, '?').join(', ')})');
      arguments.addAll(ids);
    }

    if (labels != null && labels.isNotEmpty) {
      final labelJoin = labels.map((_) => '?').join(', ');
      conditions.add(
        'e.id IN (SELECT edge_id FROM edge_labels WHERE label IN ($labelJoin))',
      );
      arguments.addAll(labels);
    }

    if (fromVertexId != null) {
      conditions.add('e.from_vertex_id = ?');
      arguments.add(fromVertexId);
    }

    if (toVertexId != null) {
      conditions.add('e.to_vertex_id = ?');
      arguments.add(toVertexId);
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }

    final results = await _txn.rawQuery(query, arguments);

    // Optimize: Batch fetch all labels and properties to avoid N+1 queries
    if (results.isEmpty) {
      return;
    }

    final edgeIds = results.map((row) => row['id']! as int).toList();

    // Batch fetch all labels
    final labelsMap = await _getBatchEdgeLabels(edgeIds);

    // Batch fetch all properties
    final propertiesMap = await _getBatchEdgeProperties(edgeIds);

    for (final row in results) {
      final edgeId = row['id']! as int;
      final labels = labelsMap[edgeId] ?? <String>{};
      final properties = propertiesMap[edgeId] ?? <String, dynamic>{};

      yield Edge(
        id: edgeId,
        fromVertexId: row['from_vertex_id']! as int,
        toVertexId: row['to_vertex_id']! as int,
        labels: labels,
        properties: properties,
        createdAt: DateTime.parse(row['created_at']! as String),
        updatedAt: DateTime.parse(row['updated_at']! as String),
      );
    }
  }

  Future<Set<String>> _getLabels(String table, String idColumn, int id) async {
    final results = await _txn.query(
      table,
      columns: ['label'],
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    return results.map((row) => row['label']! as String).toSet();
  }

  Future<Set<String>> _getVertexLabels(int vertexId) async {
    return _getLabels('vertex_labels', 'vertex_id', vertexId);
  }

  Future<Set<String>> _getEdgeLabels(int edgeId) async {
    return _getLabels('edge_labels', 'edge_id', edgeId);
  }

  /// Batch fetch labels for multiple vertices to avoid N+1 queries
  Future<Map<int, Set<String>>> _getBatchVertexLabels(
      List<int> vertexIds) async {
    if (vertexIds.isEmpty) {
      return {};
    }

    final placeholders = List.filled(vertexIds.length, '?').join(', ');
    final results = await _txn.query(
      'vertex_labels',
      columns: ['vertex_id', 'label'],
      where: 'vertex_id IN ($placeholders)',
      whereArgs: vertexIds,
    );

    final labelsMap = <int, Set<String>>{};
    for (final row in results) {
      final vertexId = row['vertex_id']! as int;
      final label = row['label']! as String;
      labelsMap.putIfAbsent(vertexId, () => <String>{}).add(label);
    }

    return labelsMap;
  }

  /// Batch fetch labels for multiple edges to avoid N+1 queries
  Future<Map<int, Set<String>>> _getBatchEdgeLabels(List<int> edgeIds) async {
    if (edgeIds.isEmpty) {
      return {};
    }

    final placeholders = List.filled(edgeIds.length, '?').join(', ');
    final results = await _txn.query(
      'edge_labels',
      columns: ['edge_id', 'label'],
      where: 'edge_id IN ($placeholders)',
      whereArgs: edgeIds,
    );

    final labelsMap = <int, Set<String>>{};
    for (final row in results) {
      final edgeId = row['edge_id']! as int;
      final label = row['label']! as String;
      labelsMap.putIfAbsent(edgeId, () => <String>{}).add(label);
    }

    return labelsMap;
  }

  Future<Map<String, dynamic>> _getProperties(
    String table,
    String idColumn,
    int id,
  ) async {
    final results = await _txn.query(
      table,
      columns: ['key', 'value', 'type'],
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    return Map.fromEntries(
      results.map((row) {
        final key = row['key']! as String;
        final value = row['value'];
        final type = DatabaseValueType.fromId(row['type']! as int);
        return MapEntry(
          key,
          DatabaseValueHelper.fromDatabaseValue(type, value),
        );
      }),
    );
  }

  Future<Map<String, dynamic>> _getVertexProperties(int vertexId) async {
    return _getProperties('vertex_properties', 'vertex_id', vertexId);
  }

  Future<Map<String, dynamic>> _getEdgeProperties(int edgeId) async {
    return _getProperties('edge_properties', 'edge_id', edgeId);
  }

  /// Batch fetch properties for multiple vertices to avoid N+1 queries
  Future<Map<int, Map<String, dynamic>>> _getBatchVertexProperties(
    List<int> vertexIds,
  ) async {
    if (vertexIds.isEmpty) {
      return {};
    }

    final placeholders = List.filled(vertexIds.length, '?').join(', ');
    final results = await _txn.query(
      'vertex_properties',
      columns: ['vertex_id', 'key', 'value', 'type'],
      where: 'vertex_id IN ($placeholders)',
      whereArgs: vertexIds,
    );

    final propertiesMap = <int, Map<String, dynamic>>{};
    for (final row in results) {
      final vertexId = row['vertex_id']! as int;
      final key = row['key']! as String;
      final value = row['value'];
      final type = DatabaseValueType.fromId(row['type']! as int);

      propertiesMap.putIfAbsent(vertexId, () => <String, dynamic>{})[key] =
          DatabaseValueHelper.fromDatabaseValue(type, value);
    }

    return propertiesMap;
  }

  /// Batch fetch properties for multiple edges to avoid N+1 queries
  Future<Map<int, Map<String, dynamic>>> _getBatchEdgeProperties(
    List<int> edgeIds,
  ) async {
    if (edgeIds.isEmpty) {
      return {};
    }

    final placeholders = List.filled(edgeIds.length, '?').join(', ');
    final results = await _txn.query(
      'edge_properties',
      columns: ['edge_id', 'key', 'value', 'type'],
      where: 'edge_id IN ($placeholders)',
      whereArgs: edgeIds,
    );

    final propertiesMap = <int, Map<String, dynamic>>{};
    for (final row in results) {
      final edgeId = row['edge_id']! as int;
      final key = row['key']! as String;
      final value = row['value'];
      final type = DatabaseValueType.fromId(row['type']! as int);

      propertiesMap.putIfAbsent(edgeId, () => <String, dynamic>{})[key] =
          DatabaseValueHelper.fromDatabaseValue(type, value);
    }

    return propertiesMap;
  }

  Future<void> _insertProperties(
    String table,
    String idColumn,
    int id,
    Map<String, dynamic> properties,
  ) async {
    for (final entry in properties.entries) {
      final value = entry.value;
      if (value != null) {
        await _txn.insert(table, {
          idColumn: id,
          'key': entry.key,
          'value': DatabaseValueHelper.toDatabaseValue(value),
          'type': DatabaseValueHelper.getDatabaseValueType(value).id,
        });
      } else {
        await _txn.insert(table, {
          idColumn: id,
          'key': entry.key,
          'value': null,
          'type': DatabaseValueType.null_.id,
        });
      }
    }
  }

  Future<void> _insertVertexProperties(
    int vertexId,
    Map<String, dynamic> properties,
  ) async {
    await _insertProperties(
      'vertex_properties',
      'vertex_id',
      vertexId,
      properties,
    );
  }

  Future<void> _insertEdgeProperties(
    int edgeId,
    Map<String, dynamic> properties,
  ) async {
    await _insertProperties('edge_properties', 'edge_id', edgeId, properties);
  }

  @override
  TransactionalTraversalSource traversal() {
    if (_graph == null) {
      throw StateError(
        'Graph object not set. Transactional traversal is only available '
        'when using Graph.transaction() method.',
      );
    }
    return SqlTransactionalTraversalSourceImpl(_graph, this);
  }
}
