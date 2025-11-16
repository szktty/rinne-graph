import 'package:rinne_graph/src/database/helper.dart';
import 'package:rinne_graph/src/database/transaction_intf.dart';
import 'package:rinne_graph/src/exception.dart';
import 'package:rinne_graph/src/graph/graph_intf.dart';
import 'package:rinne_graph/src/model/model.dart';
import 'package:rinne_graph/src/traversal/graph_loader.dart';
import 'package:rinne_graph/src/traversal/sql_traversal/sql_query.dart';
import 'package:rinne_graph/src/traversal/sql_traversal/sql_traversal_impl.dart';
import 'package:rinne_graph/src/traversal/traversal_intf.dart';
import 'package:rinne_graph/src/traversal/traversal_path.dart';

/// Traversal source implementation for use within transactions
final class SqlTransactionalTraversalSourceImpl
    implements TransactionalTraversalSource {
  SqlTransactionalTraversalSourceImpl(this.graph, this.transaction);

  final Graph graph;
  final Transaction transaction;

  @override
  Traversal E([List<int>? ids]) {
    return SqlTransactionalTraversalImpl(graph, transaction)..E(ids);
  }

  @override
  Traversal V([List<int>? ids]) {
    return SqlTransactionalTraversalImpl(graph, transaction)..V(ids);
  }
}

/// Traversal implementation that executes SQL queries within transactions
final class SqlTransactionalTraversalImpl implements Traversal {
  SqlTransactionalTraversalImpl(this.graph, this.transaction) {
    _delegate = SqlTraversalImpl(graph);
  }

  final Graph graph;
  final Transaction transaction;
  late final SqlTraversalImpl _delegate;

  // For alias resolution (simple version: only supports V([id]).as(label))
  final Map<String, int> _aliasVertexIds = {};
  int? _lastExplicitVertexId;

  // Temporary holding of mutation steps (executed as terminal steps)
  _PendingMergeV? _pendingMergeV;
  _PendingMergeE? _pendingMergeE;

  @override
  Future<List<dynamic>> toList() async {
    // First, prioritize processing mutation terminal steps
    if (_pendingMergeV != null) {
      final v = await _executeMergeV(_pendingMergeV!);
      _pendingMergeV = null; // Consume
      return [v];
    }
    if (_pendingMergeE != null) {
      final e = await _executeMergeE(_pendingMergeE!);
      _pendingMergeE = null;
      return [e];
    }

    final querySet = _delegate.buildQuerySet();
    final results = await transaction.rawQuery(
      querySet.resultQuery!.query,
      querySet.resultQuery!.parameters,
    );

    // Use GraphLoader to convert database results to appropriate types
    // Use transactional version of GraphLoader
    final loader = GraphLoader(
      getVertex: transaction.getVertex,
      getEdge: transaction.getEdge,
    );
    return loader.loadFromQueryResult(
      results,
      querySet.resultQuery!.resultType,
    );
  }

  Future<Vertex> _executeMergeV(_PendingMergeV req) async {
    if (req.labels.isEmpty) {
      throw ArgumentError('mergeV: labels must have at least one entry');
    }

    // Search for existing vertex: has all specified labels AND all match key=value
    final sql = StringBuffer('SELECT v.id FROM vertices v WHERE 1=1');
    final args = <dynamic>[];

    for (final label in req.labels) {
      sql.write(
          ' AND EXISTS (SELECT 1 FROM vertex_labels vl WHERE vl.vertex_id = v.id AND vl.label = ?)');
      args.add(label);
    }

    for (final entry in req.match.entries) {
      final key = entry.key;
      final value = entry.value;
      final typeId = DatabaseValueHelper.getDatabaseValueType(value).id;
      sql.write(
          ' AND EXISTS (SELECT 1 FROM vertex_properties vp WHERE vp.vertex_id = v.id AND vp.key = ? AND vp.type = ?');
      args.add(key);
      args.add(typeId);
      if (value is NullValue) {
        sql.write(' AND vp.value IS NULL)');
      } else {
        sql.write(' AND vp.value = ?)');
        args.add(DatabaseValueHelper.toDatabaseValue(value));
      }
    }

    final rows = await transaction.rawQuery(sql.toString(), args);

    if (rows.length > 1) {
      throw VertexException(
          'mergeV: matched multiple vertices (ambiguous match)');
    }

    if (rows.length == 1) {
      final id = rows.first['id'] as int;

      // Upsert onMatch properties
      if (req.onMatch != null && req.onMatch!.isNotEmpty) {
        for (final e in req.onMatch!.entries) {
          // Delete existing → insert
          await transaction.execute(
            'DELETE FROM vertex_properties WHERE vertex_id = ? AND key = ?',
            [id, e.key],
          );
          final type = DatabaseValueHelper.getDatabaseValueType(e.value).id;
          final value = e.value is NullValue
              ? null
              : DatabaseValueHelper.toDatabaseValue(e.value);
          await transaction.execute(
            'INSERT INTO vertex_properties(vertex_id, key, value, type) VALUES(?, ?, ?, ?)',
            [id, e.key, value, type],
          );
        }
      }

      // Add labels (only missing ones)
      final current = await transaction.getVertex(id);
      final currentLabels = current?.labels ?? <String>{};
      for (final label in req.labels) {
        if (!currentLabels.contains(label)) {
          await transaction.execute(
            'INSERT OR IGNORE INTO vertex_labels(vertex_id, label) VALUES(?, ?)',
            [id, label],
          );
        }
      }

      final updated = await transaction.getVertex(id);
      return updated!;
    }

    // Not found: create new (match ∪ onCreate (onCreate takes priority))
    final props = <String, dynamic>{...req.match};
    if (req.onCreate != null) {
      props.addAll(req.onCreate!);
    }
    final created = await transaction.createVertex(
      Vertex(labels: req.labels.toSet(), properties: props),
    );
    return created;
  }

  Future<Edge> _executeMergeE(_PendingMergeE req) async {
    if (req.labels.isEmpty) {
      throw ArgumentError('mergeE: labels must have at least one entry');
    }
    final fromId = _aliasVertexIds[req.fromAlias];
    final toId = _aliasVertexIds[req.toAlias];
    if (fromId == null || toId == null) {
      throw ArgumentError(
        "mergeE: specify fromAlias/toAlias with V([id]).as('alias') (phase 1 simple support)",
      );
    }

    // Search for existing edge: endpoints match AND has all specified labels AND all match key=value
    final sql = StringBuffer(
        'SELECT e.id FROM edges e WHERE e.from_vertex_id = ? AND e.to_vertex_id = ?');
    final args = <dynamic>[fromId, toId];

    for (final label in req.labels) {
      sql.write(
          ' AND EXISTS (SELECT 1 FROM edge_labels el WHERE el.edge_id = e.id AND el.label = ?)');
      args.add(label);
    }
    for (final entry in req.match.entries) {
      final key = entry.key;
      final value = entry.value;
      final typeId = DatabaseValueHelper.getDatabaseValueType(value).id;
      sql.write(
          ' AND EXISTS (SELECT 1 FROM edge_properties ep WHERE ep.edge_id = e.id AND ep.key = ? AND ep.type = ?');
      args.add(key);
      args.add(typeId);
      if (value is NullValue) {
        sql.write(' AND ep.value IS NULL)');
      } else {
        sql.write(' AND ep.value = ?)');
        args.add(DatabaseValueHelper.toDatabaseValue(value));
      }
    }

    final rows = await transaction.rawQuery(sql.toString(), args);

    if (rows.length > 1) {
      throw EdgeException('mergeE: matched multiple edges (ambiguous match)');
    }

    if (rows.length == 1) {
      final id = rows.first['id'] as int;

      // Upsert onMatch properties
      if (req.onMatch != null && req.onMatch!.isNotEmpty) {
        for (final e in req.onMatch!.entries) {
          await transaction.execute(
            'DELETE FROM edge_properties WHERE edge_id = ? AND key = ?',
            [id, e.key],
          );
          final type = DatabaseValueHelper.getDatabaseValueType(e.value).id;
          final value = e.value is NullValue
              ? null
              : DatabaseValueHelper.toDatabaseValue(e.value);
          await transaction.execute(
            'INSERT INTO edge_properties(edge_id, key, value, type) VALUES(?, ?, ?, ?)',
            [id, e.key, value, type],
          );
        }
      }

      // Add labels (only missing ones)
      final current = await transaction.getEdge(id);
      final currentLabels = current?.labels ?? <String>{};
      for (final label in req.labels) {
        if (!currentLabels.contains(label)) {
          await transaction.execute(
            'INSERT OR IGNORE INTO edge_labels(edge_id, label) VALUES(?, ?)',
            [id, label],
          );
        }
      }

      final updated = await transaction.getEdge(id);
      return updated!;
    }

    // Not found: create new (match ∪ onCreate (onCreate takes priority))
    final props = <String, dynamic>{...req.match};
    if (req.onCreate != null) {
      props.addAll(req.onCreate!);
    }
    final created = await transaction.createEdge(
      Edge(
        fromVertexId: fromId,
        toVertexId: toId,
        labels: req.labels.toSet(),
        properties: props,
      ),
    );
    return created;
  }

  @override
  Stream<TraversalPath> get pathStream async* {
    if (!_delegate.traversalPathEnabled) {
      throw StateError('Path tracking is not enabled. Call path() first.');
    }

    final querySet = _delegate.buildQuerySet();
    final results = await transaction.rawQuery(
      querySet.resultQuery!.query,
      querySet.resultQuery!.parameters,
    );

    final sqlResults =
        SqlResultSet(results, querySet.resultQuery!.propertyKeyMap);
    final paths = sqlResults.getTraversalPaths();

    for (final path in paths) {
      yield path;
    }
  }

  // Below, delegate all Traversal methods to _delegate
  @override
  Traversal V([List<int>? ids]) {
    // For simple alias resolution, record only explicit ID of one entry
    if (ids != null && ids.length == 1) {
      _lastExplicitVertexId = ids.first;
    } else {
      _lastExplicitVertexId = null;
    }
    _delegate.V(ids);
    return this;
  }

  @override
  Traversal E([List<int>? ids]) {
    _delegate.E(ids);
    return this;
  }

  @override
  Traversal id() {
    _delegate.id();
    return this;
  }

  @override
  Traversal hasId([List<int>? ids]) {
    _delegate.hasId(ids);
    return this;
  }

  @override
  Traversal hasKey(String key, dynamic value) {
    _delegate.hasKey(key, value);
    return this;
  }

  @override
  Traversal hasKeyContains(String key, String value) {
    _delegate.hasKeyContains(key, value);
    return this;
  }

  @override
  Traversal hasKeyStartsWith(String key, String value) {
    _delegate.hasKeyStartsWith(key, value);
    return this;
  }

  @override
  Traversal hasKeyEndsWith(String key, String value) {
    _delegate.hasKeyEndsWith(key, value);
    return this;
  }

  @override
  Traversal hasKeyMatches(String key, String pattern) {
    _delegate.hasKeyMatches(key, pattern);
    return this;
  }

  @override
  Traversal hasKeyGreaterThan(String key, dynamic value) {
    _delegate.hasKeyGreaterThan(key, value);
    return this;
  }

  @override
  Traversal hasKeyLessThan(String key, dynamic value) {
    _delegate.hasKeyLessThan(key, value);
    return this;
  }

  @override
  Traversal hasKeyBetween(String key, dynamic min, dynamic max) {
    _delegate.hasKeyBetween(key, min, max);
    return this;
  }

  @override
  Traversal hasKeyIn(String key, List<dynamic> values) {
    _delegate.hasKeyIn(key, values);
    return this;
  }

  @override
  Traversal hasKeyNotIn(String key, List<dynamic> values) {
    _delegate.hasKeyNotIn(key, values);
    return this;
  }

  @override
  Traversal hasNot(String key) {
    _delegate.hasNot(key);
    return this;
  }

  @override
  Traversal or(List<Traversal Function(Traversal)> conditions) {
    _delegate.or(conditions);
    return this;
  }

  @override
  Traversal not(Traversal Function(Traversal) condition) {
    _delegate.not(condition);
    return this;
  }

  @override
  Traversal hasNotLabel(List<String> labels) {
    _delegate.hasNotLabel(labels);
    return this;
  }

  @override
  Traversal listContains(String key, dynamic value) {
    _delegate.listContains(key, value);
    return this;
  }

  @override
  Traversal listContainsExact(String key, dynamic value) {
    _delegate.listContainsExact(key, value);
    return this;
  }

  @override
  Traversal listLength(String key, int length) {
    _delegate.listLength(key, length);
    return this;
  }

  @override
  Traversal hasLabel(List<String> labels) {
    _delegate.hasLabel(labels);
    return this;
  }

  @override
  Traversal out([List<String>? labels]) {
    _delegate.out(labels);
    return this;
  }

  @override
  Traversal in_([List<String>? labels]) {
    _delegate.in_(labels);
    return this;
  }

  @override
  Traversal both([List<String>? labels]) {
    _delegate.both(labels);
    return this;
  }

  @override
  Traversal outE([List<String>? labels]) {
    _delegate.outE(labels);
    return this;
  }

  @override
  Traversal inE([List<String>? labels]) {
    _delegate.inE(labels);
    return this;
  }

  @override
  Traversal bothE([List<String>? labels]) {
    _delegate.bothE(labels);
    return this;
  }

  @override
  Traversal outV() {
    _delegate.outV();
    return this;
  }

  @override
  Traversal inV() {
    _delegate.inV();
    return this;
  }

  @override
  Traversal bothV() {
    _delegate.bothV();
    return this;
  }

  @override
  Traversal values([List<String>? keys]) {
    _delegate.values(keys);
    return this;
  }

  @override
  Traversal valueMap([List<String>? keys]) {
    _delegate.valueMap(keys);
    return this;
  }

  @override
  Traversal limit(int limit) {
    _delegate.limit(limit);
    return this;
  }

  @override
  Traversal skip(int offset) {
    _delegate.skip(offset);
    return this;
  }

  @override
  Traversal order() {
    _delegate.order();
    return this;
  }

  @override
  Traversal group() {
    _delegate.group();
    return this;
  }

  @override
  Traversal byId([SortOrder? order]) {
    _delegate.byId(order);
    return this;
  }

  @override
  Traversal byKey(String key, [SortOrder? order]) {
    _delegate.byKey(key, order);
    return this;
  }

  @override
  Traversal dedup() {
    _delegate.dedup();
    return this;
  }

  @override
  Traversal map(dynamic Function(dynamic) transformer) {
    _delegate.map(transformer);
    return this;
  }

  @override
  Traversal path() {
    _delegate.path();
    return this;
  }

  @override
  Traversal filter(bool Function(dynamic) filterFunction) {
    _delegate.filter(filterFunction);
    return this;
  }

  @override
  Traversal count() {
    _delegate.count();
    return this;
  }

  @override
  Traversal as(String label) {
    // Simple support: if V([id]) was called immediately before, associate that id with label
    if (_lastExplicitVertexId != null) {
      _aliasVertexIds[label] = _lastExplicitVertexId!;
      _lastExplicitVertexId = null;
    }
    _delegate.as(label);
    return this;
  }

  @override
  Traversal select(List<String> labels) {
    _delegate.select(labels);
    return this;
  }

  @override
  Traversal repeat(Traversal traversal) {
    _delegate.repeat(traversal);
    return this;
  }

  @override
  Traversal until(bool Function(dynamic) predicate) {
    _delegate.until(predicate);
    return this;
  }

  @override
  Traversal times(int times) {
    _delegate.times(times);
    return this;
  }

  // Mutation steps (terminal)
  @override
  Traversal mergeV({
    required Set<String> labels,
    required Map<String, dynamic> match,
    Map<String, dynamic>? onCreate,
    Map<String, dynamic>? onMatch,
  }) {
    _pendingMergeV = _PendingMergeV(
      labels: labels,
      match: match,
      onCreate: onCreate,
      onMatch: onMatch,
    );
    return this;
  }

  @override
  Traversal mergeE({
    required Set<String> labels,
    required Map<String, dynamic> match,
    required String fromAlias,
    required String toAlias,
    Map<String, dynamic>? onCreate,
    Map<String, dynamic>? onMatch,
  }) {
    _pendingMergeE = _PendingMergeE(
      labels: labels,
      match: match,
      fromAlias: fromAlias,
      toAlias: toAlias,
      onCreate: onCreate,
      onMatch: onMatch,
    );
    return this;
  }

  @override
  Stream<dynamic> get stream => throw UnimplementedError();

  @override
  Future<Set<dynamic>> toSet() async {
    final list = await toList();
    return list.toSet();
  }

  @override
  Future<List<TraversalPath>> toPathList() async {
    return pathStream.toList();
  }

  @override
  SqlQuery buildQuery() {
    return _delegate.buildQuery();
  }

  @override
  SqlQuerySet buildQuerySet() {
    return _delegate.buildQuerySet();
  }
}

class _PendingMergeV {
  _PendingMergeV({
    required this.labels,
    required this.match,
    this.onCreate,
    this.onMatch,
  });

  final Set<String> labels;
  final Map<String, dynamic> match;
  final Map<String, dynamic>? onCreate;
  final Map<String, dynamic>? onMatch;
}

class _PendingMergeE {
  _PendingMergeE({
    required this.labels,
    required this.match,
    required this.fromAlias,
    required this.toAlias,
    this.onCreate,
    this.onMatch,
  });

  final Set<String> labels;
  final Map<String, dynamic> match;
  final String fromAlias;
  final String toAlias;
  final Map<String, dynamic>? onCreate;
  final Map<String, dynamic>? onMatch;
}
