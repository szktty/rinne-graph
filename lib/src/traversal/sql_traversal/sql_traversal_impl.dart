import 'package:collection/collection.dart';
import 'package:rinne_graph/src/graph/graph.dart';
import 'package:rinne_graph/src/traversal/graph_loader.dart';
import 'package:rinne_graph/src/traversal/sql_traversal/sql_traversal_intf.dart';
import 'package:rinne_graph/src/traversal/sql_traversal/sql_traversal_steps.dart';
import 'package:rinne_graph/src/traversal/traversal_internal.dart';
import 'package:rinne_graph/src/util/logger.dart';

enum QuerySourceType {
  cte,
  temporaryTable,
}

// TODO(szktty): Consider supporting existing tables in addition to CTEs.
abstract class QuerySource {}

final class Cte extends QuerySource {
  Cte({
    required this.name,
    required this.from,
    required this.id,
    required this.type,
    required this.value,
    this.previousId,
    this.select,
    this.distinct = false,
    this.joins,
    this.where,
    this.groupBy,
    this.orderBy,
    this.limit,
  });

  final String name;

  // Used when path is enabled and there is no previous CTE
  // No previous CTE means the first step is V() or E()
  // If V() or E() doesn't specify ID, all elements are targeted,
  // so making it a CTE would cause unnecessary searches, so it's omitted
  final String? previousId;

  // ID to include in path. Independent for JSON construction
  final String id;

  /// Used when returning path or value
  final String type;

  /// Used when returning path or value
  final String value;

  final String? select;
  final bool distinct;
  final String from;
  final List<String>? joins;
  final String? where;
  final String? groupBy;
  final String? orderBy;

  int? limit;
}

final class SqlTraversalSourceImpl extends SqlTraversalSource {
  SqlTraversalSourceImpl(this.graph);

  final Graph graph;

  @override
  Traversal E([List<int>? ids]) {
    return SqlTraversalImpl(graph)..E(ids);
  }

  @override
  Traversal V([List<int>? ids]) {
    return SqlTraversalImpl(graph)..V(ids);
  }
}

final class SqlTraversalImpl extends TraversalBase implements SqlTraversal {
  SqlTraversalImpl(this.graph)
      : super(
          steps: [],
        );

  final Graph graph;

  final Map<String, dynamic> _parameters = {};
  int _paramCounter = 0;
  static String propertyKeyAliasPrefix = 'prop_';
  static String propertyTypeAliasSuffix = '_type';
  static String columnAliasPrefix = 'col_';
  static String cteNamePrefix = 'cte_';

  Set<int> targetIds = {};

  final List<Cte> _ctes = [];
  final List<bool Function(dynamic)> _postProcessFilters = [];
  final List<dynamic Function(dynamic)> _postProcessTransformers = [];

  Cte? get _lastCte => _ctes.lastOrNull;

  bool get startsWithVertex => firstStep is VertexStep;

  bool get startsWithEdge => firstStep is EdgeStep;

  @override
  String get lastCteName {
    if (_lastCte != null) {
      return _lastCte!.name;
    } else if (startsWithVertex) {
      return 'vertices';
    } else if (startsWithEdge) {
      return 'edges';
    } else {
      throw ArgumentError('No source for CTE');
    }
  }

  List<String> conditions = [];
  int? _limit;
  int? _offset;
  bool _limitBeforeOffset = false;

  Map<String, dynamic> parameters = {};
  int paramCounter = 0;
  Map<String, String> propertyKeyAliases = {};

  @override
  String get labelTable {
    // Use output type of previous step or current CTE information
    final isVertex = _determineCurrentElementType().isVertex;
    return isVertex ? 'vertex_labels' : 'edge_labels';
  }

  @override
  String get elementIdColumn {
    final isVertex = _determineCurrentElementType().isVertex;
    return isVertex ? 'vertex_id' : 'edge_id';
  }

  @override
  String get elementTypeColumn {
    final isVertex = _determineCurrentElementType().isVertex;
    return isVertex
        ? '${SqlTraversalPathType.vertexId}'
        : '${SqlTraversalPathType.edgeId}';
  }

  @override
  String get propertyTable {
    final isVertex = _determineCurrentElementType().isVertex;
    return isVertex ? 'vertex_properties' : 'edge_properties';
  }

  ElementType _determineCurrentElementType() {
    // Trace back from previous steps to find the last vertex or edge type
    for (var i = steps.length - 1; i >= 0; i--) {
      final step = steps[i];
      final outputType = step.outputType;

      // Return the type if it's a vertex or edge
      if (outputType.isVertex || outputType.isEdge) {
        return outputType;
      }

      // For properties or values, check their input type
      if (outputType == ElementType.property ||
          outputType == ElementType.value) {
        final inputType = step.inputType;
        if (inputType.isVertex || inputType.isEdge) {
          return inputType;
        }
      }
    }

    // Default is vertex
    return ElementType.vertex;
  }

  int _cteCounter = 0;
  int _columnAliasCounter = 0;

  String createCteName([String? name]) {
    _cteCounter++;
    if (name != null) {
      return '$cteNamePrefix${_cteCounter}_$name';
    } else {
      return '$cteNamePrefix$_cteCounter';
    }
  }

  String createColumnAlias() {
    return '$columnAliasPrefix${_columnAliasCounter++}';
  }

  String createPropertyKeyAlias(String key) {
    if (propertyKeyAliases.containsKey(key)) {
      return propertyKeyAliases[key]!;
    }
    final alias = '$propertyKeyAliasPrefix${propertyKeyAliases.length}';
    propertyKeyAliases[key] = alias;
    return alias;
  }

  String getPropertyKeyForAlias(String alias) {
    return propertyKeyAliases.entries
        .firstWhere(
          (entry) => entry.value == alias,
          orElse: () => MapEntry(alias, alias),
        )
        .key;
  }

  static String getPropertyTypeAlias(String alias) => '${alias}_type';

  Map<String, String> idColumnsForCtes = {};

  // TODO(szktty): Make id and select specification a set or make id mandatory. Use id argument instead of manually specifying id in select.
  @override
  String addCte({
    required String id,
    required String type,
    required String value,
    String? cteName,
    String? previousId,
    String? select,
    String? from,
    bool distinct = false,
    List<String>? joins,
    String? where,
    String? groupBy,
    String? orderBy,
    int? limit,
  }) {
    var from0 = from;
    if (from == null) {
      if (_lastCte != null) {
        from0 = _lastCte!.name;
      } else if (startsWithVertex) {
        from0 = 'vertices';
      } else if (startsWithEdge) {
        from0 = 'edges';
      } else {
        throw ArgumentError('No source for CTE');
      }
    }
    final cte = Cte(
      name: createCteName(cteName),
      previousId: previousId,
      id: id,
      type: type,
      value: value,
      select: select ?? '*',
      from: from0!,
      distinct: distinct,
      joins: joins,
      where: where,
      groupBy: groupBy,
      orderBy: orderBy,
      limit: limit,
    );
    _ctes.add(cte);
    return cte.name;
  }

  @override
  String addParameter(dynamic value) {
    final paramName = 'p${_paramCounter++}';
    _parameters[paramName] = value;
    return '@$paramName';
  }

  @override
  List<String> addParameters(Iterable<dynamic> values) {
    return values.map(addParameter).toList();
  }

  @override
  void setLimit(int limit) {
    // Set global limit, but we need to handle interaction with offset properly
    _limit = limit;
    // If offset is already set, this means limit comes after offset
    if (_offset != null) {
      _limitBeforeOffset = false;
    } else {
      _limitBeforeOffset = true;
    }
  }

  @override
  void setOffset(int offset) {
    _offset = offset;
    // If limit is already set, this means offset comes after limit
    if (_limit != null) {
      _limitBeforeOffset = true;
    }
  }

  @override
  void addPostProcessFilter(bool Function(dynamic) filter) {
    _postProcessFilters.add(filter);
  }

  @override
  void addPostProcessTransformer(dynamic Function(dynamic) transformer) {
    _postProcessTransformers.add(transformer);
  }

  // TODO(szktty): Remove this method eventually.
  @override
  SqlQuery buildQuery() {
    return buildQuerySet().resultQuery!;
  }

  // TODO(szktty): Consider completely separating processing for traversal path and non-path cases.
  @override
  SqlQuerySet buildQuerySet() {
    traversalLogger.fine('build steps: $steps');
    for (final step in steps) {
      (step as SqlTraversalStep).apply(this);
    }

    if (traversalPathEnabled) {
      return _buildQuerySetWithTraversalPath();
    } else {
      return _buildQuerySet();
    }
  }

  SqlQuerySet _buildQuerySet() {
    final buffer = StringBuffer();
    _buildQuerySetBase(_ctes, buffer, sourceType: QuerySourceType.cte);
    final parameters = _buildQuerySource(buffer);

    // result
    buffer.writeln('SELECT *');
    buffer.writeln('  FROM $lastCteName');
    if (_limit != null || _offset != null) {
      if (_limit != null && _offset != null) {
        if (_limitBeforeOffset) {
          // limit() was called before skip() - need to limit first then skip
          // This requires adjusting the limit to account for SQL semantics
          final adjustedLimit = _limit! - _offset!;
          if (adjustedLimit > 0) {
            buffer.write('LIMIT $adjustedLimit OFFSET $_offset');
          } else {
            // If adjusted limit would be 0 or negative, return no results
            buffer.write('LIMIT 0');
          }
        } else {
          // skip() was called before limit() - standard SQL semantics work
          buffer.write('LIMIT $_limit OFFSET $_offset');
        }
      } else if (_limit != null) {
        buffer.write('LIMIT $_limit');
      } else {
        buffer.write('LIMIT -1'); // Represents unlimited in SQLite
        if (_offset != null) {
          buffer.write(' OFFSET $_offset');
        }
      }
      buffer.writeln();
    }

    return SqlQuerySet(
      resultQuery: _createSqlQuery(buffer.toString(), parameters),
    );
  }

  SqlQuerySet _buildQuerySetWithTraversalPath() {
    final sourceBuffer = StringBuffer();

    List<String> onSelectColumns(int i, Cte cte) {
      final columns = <String>[];
      final ctePathItem = 'json_array(${cte.id}, ${cte.type}, ${cte.value})';

      if (i == 0) {
        // First CTE
        if (cte.from == 'vertices' || cte.from == 'edges') {
          // If the first CTE targets vertices or edges
          // Make the matched element's ID the first path
          if (firstStep is VertexStep) {
            columns.add('json_array('
                'json_array(vertices.id, ${SqlTraversalPathType.vertexId}, vertices.id),'
                '$ctePathItem) AS path');
          } else if (firstStep is EdgeStep) {
            columns.add('json_array('
                'json_array(edges.id, ${SqlTraversalPathType.edgeId}, edges.id)'
                '$ctePathItem) AS path');
          } else {
            throw StateError('First step must be V() or E()');
          }
        } else {
          // If the first CTE doesn't target vertices or edges
          // That is, the first step is V() or E() and doesn't specify ID
          // Include the first CTE's source previousId in the path
          if (cte.previousId == null) {
            throw ArgumentError(
                'previousId is required for the first step ${firstStep!.name}()');
          }
          final type = startsWithVertex
              ? SqlTraversalPathType.vertexId
              : SqlTraversalPathType.edgeId;
          columns.add('json_array('
              'json_array(${cte.previousId!}, $type, ${cte.previousId!}),'
              '$ctePathItem) AS path');
        }
      } else {
        columns.add(
            "json_insert(${cte.from}.path, '\$[#]', $ctePathItem) AS path");
      }
      return columns;
    }

    _buildQuerySetBase(
      _ctes,
      sourceBuffer,
      //sourceType: QuerySourceType.temporaryTable,
      sourceType: QuerySourceType.cte,
      onSelectColumns: onSelectColumns,
      // onAfterEachSource: onAfterEachSource,
    );
    sourceBuffer.writeln('SELECT path');
    sourceBuffer.writeln('  FROM $lastCteName');
    if (_limit != null || _offset != null) {
      if (_limit != null && _offset != null) {
        if (_limitBeforeOffset) {
          // limit() was called before skip() - need to limit first then skip
          // This requires adjusting the limit to account for SQL semantics
          final adjustedLimit = _limit! - _offset!;
          if (adjustedLimit > 0) {
            sourceBuffer.write('LIMIT $adjustedLimit OFFSET $_offset');
          } else {
            // If adjusted limit would be 0 or negative, return no results
            sourceBuffer.write('LIMIT 0');
          }
        } else {
          // skip() was called before limit() - standard SQL semantics work
          sourceBuffer.write('LIMIT $_limit OFFSET $_offset');
        }
      } else if (_limit != null) {
        sourceBuffer.write('LIMIT $_limit');
      } else {
        sourceBuffer.write('LIMIT -1'); // Represents unlimited in SQLite
        if (_offset != null) {
          sourceBuffer.write(' OFFSET $_offset');
        }
      }
      sourceBuffer.writeln();
    }
    final parameters = _buildQuerySource(sourceBuffer);
    final sourceQuery = _createSqlQuery(sourceBuffer.toString(), parameters);

    return SqlQuerySet(
      resultQuery: sourceQuery,
    );
  }

  void _buildQuerySetBase(
    List<Cte> ctes,
    StringBuffer buffer, {
    required QuerySourceType sourceType,
    List<String> Function(int, Cte)? onSelectColumns,
    void Function(int, Cte)? onAfterEachSource,
  }) {
    if (sourceType == QuerySourceType.cte && ctes.isNotEmpty) {
      buffer.writeln('WITH');
    }

    for (var i = 0; i < ctes.length; i++) {
      final cte = ctes[i];

      switch (sourceType) {
        case QuerySourceType.cte:
          buffer.writeln('  ${cte.name} AS (');
        case QuerySourceType.temporaryTable:
          buffer.writeln('CREATE TEMPORARY TABLE ${cte.name} AS');
      }

      buffer.write('    SELECT');
      if (cte.distinct) {
        buffer.write(' DISTINCT');
      }
      buffer.writeln();

      final selectColumns = <String>[];
      if (onSelectColumns != null) {
        selectColumns.addAll(onSelectColumns(i, cte));
      }
      selectColumns.add('${cte.id} AS id');
      selectColumns.add('${cte.type} AS type');
      selectColumns.add('${cte.value} AS value');
      if (cte.select != null) {
        final columns = cte.select!.split(',').map((s) => s.trim());
        if (columns.isNotEmpty) {
          selectColumns.addAll(columns);
        }
      }

      for (var i = 0; i < selectColumns.length; i++) {
        final column = selectColumns[i];
        buffer.write('      $column');
        if (i < selectColumns.length - 1) {
          buffer.write(',');
        }
        buffer.writeln();
      }

      buffer.writeln('      FROM ${cte.from}');
      if (cte.joins != null) {
        for (final join in cte.joins!) {
          // Check if JOIN type is explicitly specified
          if (join.trim().toUpperCase().startsWith('LEFT JOIN') ||
              join.trim().toUpperCase().startsWith('RIGHT JOIN') ||
              join.trim().toUpperCase().startsWith('INNER JOIN') ||
              join.trim().toUpperCase().startsWith('FULL JOIN')) {
            buffer.writeln('    $join');
          } else {
            buffer.writeln('    JOIN $join');
          }
        }
      }
      if (cte.where != null) {
        buffer.writeln('    WHERE');
        buffer.writeln('      ${cte.where}');
      }
      if (cte.orderBy != null) {
        buffer.writeln('    ORDER BY');
        buffer.writeln('      ${cte.orderBy}');
      }
      if (cte.groupBy != null) {
        buffer.writeln('    GROUP BY');
        buffer.writeln('      ${cte.groupBy}');
      }
      if (cte.limit != null) {
        buffer.writeln('    LIMIT ${cte.limit}');
      }

      switch (sourceType) {
        case QuerySourceType.cte:
          if (i < ctes.length - 1) {
            buffer.writeln('  ),');
          } else {
            buffer.writeln('  )');
          }
        case QuerySourceType.temporaryTable:
          buffer.writeln(';');
      }

      if (onAfterEachSource != null) {
        onAfterEachSource(i, cte);
      }
    }

    buffer.writeln();
  }

  List<Object?> _buildQuerySource(StringBuffer buffer) {
    final parameters = <Object?>[];
    final base = buffer.toString();

    // Convert parameters to ordered list
    final paramRegex = RegExp(r'@p\d+');
    paramRegex.allMatches(base).forEach((match) {
      final paramName = match.group(0)!.substring(1); // Remove '@'
      parameters.add(_parameters[paramName]);
    });

    // Replace named parameters in query with '?'
    final replaced = buffer.toString().replaceAll(paramRegex, '?');
    buffer.clear();
    buffer.write(replaced);
    return parameters;
  }

  SqlQueryResultType _determineResultType() {
    // If the last CTE is a base table
    if (lastCteName == 'vertices') {
      return SqlQueryResultType.vertex;
    } else if (lastCteName == 'edges') {
      return SqlQueryResultType.edge;
    }

    // If there are steps, check the output type of the last step
    if (steps.isNotEmpty) {
      final lastStep = steps.last;
      final outputType = lastStep.outputType;

      if (outputType == ElementType.vertex) {
        return SqlQueryResultType.vertex;
      } else if (outputType == ElementType.edge) {
        return SqlQueryResultType.edge;
      } else if (outputType == ElementType.both) {
        // For both, determine based on starting step
        if (startsWithVertex) {
          return SqlQueryResultType.vertex;
        } else if (startsWithEdge) {
          return SqlQueryResultType.edge;
        } else {
          return SqlQueryResultType.mixed;
        }
      } else {
        // For property, value, any, use raw
        return SqlQueryResultType.raw;
      }
    }

    // Fallback: determine based on starting step
    if (startsWithVertex) {
      return SqlQueryResultType.vertex;
    } else if (startsWithEdge) {
      return SqlQueryResultType.edge;
    } else {
      return SqlQueryResultType.raw;
    }
  }

  SqlQuery _createSqlQuery(String resultQuery, List<Object?> parameters) =>
      SqlQuery(
          resultQuery,
          parameters,
          _determineResultType(),
          propertyKeyAliases.map(
            (key, value) => MapEntry(value, key),
          ));

  @override
  Traversal V([List<int>? ids]) {
    return withNewStep(VertexStep(ids ?? []));
  }

  @override
  Traversal E([List<int>? ids]) {
    return withNewStep(EdgeStep(ids ?? []));
  }

  @override
  Traversal id() {
    return withNewStep(IdStep());
  }

  @override
  Traversal hasKey(String key, dynamic value) {
    return withNewStep(HasKeyStep(key, value));
  }

  @override
  Traversal hasKeyContains(String key, String value) {
    return withNewStep(HasKeyContainsStep(key, value));
  }

  @override
  Traversal hasAnyKeyContains(String value,
      {Set<String> excludeKeys = const {}}) {
    return withNewStep(HasAnyKeyContainsStep(value, excludeKeys: excludeKeys));
  }

  @override
  Traversal hasKeyStartsWith(String key, String value) {
    return withNewStep(HasKeyStartsWithStep(key, value));
  }

  @override
  Traversal hasKeyEndsWith(String key, String value) {
    return withNewStep(HasKeyEndsWithStep(key, value));
  }

  @override
  Traversal hasKeyMatches(String key, String pattern) {
    return withNewStep(HasKeyMatchesStep(key, pattern));
  }

  @override
  Traversal hasKeyGreaterThan(String key, dynamic value) {
    return withNewStep(HasKeyGreaterThanStep(key, value));
  }

  @override
  Traversal hasKeyLessThan(String key, dynamic value) {
    return withNewStep(HasKeyLessThanStep(key, value));
  }

  @override
  Traversal hasKeyBetween(String key, dynamic min, dynamic max) {
    return withNewStep(HasKeyBetweenStep(key, min, max));
  }

  @override
  Traversal hasKeyIn(String key, List<dynamic> values) {
    return withNewStep(HasKeyInStep(key, values));
  }

  @override
  Traversal hasNotLabel(List<String> labels) {
    return withNewStep(HasNotLabelStep(labels));
  }

  @override
  Traversal hasKeyNotIn(String key, List<dynamic> values) {
    return withNewStep(HasKeyNotInStep(key, values));
  }

  @override
  Traversal listContains(String key, dynamic value) {
    return withNewStep(ListContainsStep(key, value));
  }

  @override
  Traversal listContainsExact(String key, dynamic value) {
    return withNewStep(ListContainsExactStep(key, value));
  }

  @override
  Traversal listLength(String key, int length) {
    return withNewStep(ListLengthStep(key, length));
  }

  @override
  Traversal or(List<Traversal Function(Traversal)> conditions) {
    // TODO(szktty): Implement complex OR condition support.
    throw UnimplementedError('OR conditions not yet implemented');
  }

  @override
  Traversal not(Traversal Function(Traversal) condition) {
    // TODO(szktty): Implement complex NOT condition support.
    throw UnimplementedError('NOT conditions not yet implemented');
  }

  @override
  Traversal hasId([List<int>? ids]) {
    return withNewStep(HasIdStep(ids ?? []));
  }

  @override
  Traversal hasLabel(List<String> labels) {
    return withNewStep(HasLabelStep(labels));
  }

  @override
  Traversal hasNot(String key) {
    return withNewStep(HasNotStep(key));
  }

  @override
  Traversal out([List<String>? labels]) {
    return withNewStep(OutStep(labels ?? []));
  }

  @override
  Traversal in_([List<String>? labels]) {
    return withNewStep(InStep(labels ?? []));
  }

  @override
  Traversal both([List<String>? labels]) {
    return withNewStep(BothStep(labels ?? []));
  }

  @override
  Traversal outE([List<String>? labels]) {
    return withNewStep(OutEStep(labels ?? []));
  }

  @override
  Traversal inE([List<String>? labels]) {
    return withNewStep(InEStep(labels ?? []));
  }

  @override
  Traversal bothE([List<String>? labels]) {
    return withNewStep(BothEStep(labels ?? []));
  }

  @override
  Traversal outV() {
    return withNewStep(OutVStep());
  }

  @override
  Traversal inV() {
    return withNewStep(InVStep());
  }

  @override
  Traversal bothV() {
    return withNewStep(BothVStep());
  }

  @override
  Traversal values([List<String>? keys]) {
    return withNewStep(ValuesStep(keys ?? []));
  }

  @override
  Traversal valueMap([List<String>? keys]) {
    return withNewStep(ValueMapStep(keys ?? []));
  }

  @override
  Traversal limit(int limit) {
    return withNewStep(LimitStep(limit));
  }

  @override
  Traversal skip(int offset) {
    return withNewStep(SkipStep(offset));
  }

  @override
  Traversal order() {
    return withNewStep(OrderStep());
  }

  @override
  Traversal group() {
    return withNewStep(GroupStep());
  }

  @override
  Traversal byId([SortOrder? order]) {
    return withNewStep(ByIdStep(order ?? SortOrder.asc));
  }

  @override
  Traversal byKey(String key, [SortOrder? order]) {
    return withNewStep(ByKeyStep(key, order ?? SortOrder.asc));
  }

  @override
  Traversal dedup() {
    return withNewStep(DedupStep());
  }

  @override
  Traversal map(dynamic Function(dynamic) transformer) {
    return withNewStep(MapStep(transformer));
  }

  @override
  Traversal path() {
    return withNewStep(PathStep());
  }

  @override
  Traversal filter(bool Function(dynamic) filterFunction) {
    return withNewStep(FilterStep(filterFunction));
  }

  @override
  Traversal count() {
    return withNewStep(CountStep());
  }

  @override
  Traversal as(String label) {
    return withNewStep(AsStep(label));
  }

  @override
  Traversal select(List<String> labels) {
    return withNewStep(SelectStep(labels));
  }

  @override
  Traversal repeat(Traversal traversal) {
    return withNewStep(RepeatStep(traversal as TraversalBase));
  }

  @override
  Traversal until(bool Function(dynamic) predicate) {
    return withNewStep(UntilStep(predicate));
  }

  @override
  Traversal times(int times) {
    return withNewStep(TimesStep(times));
  }

  // Mutation steps are not supported in non-transactional implementation
  @override
  Traversal mergeV({
    required Set<String> labels,
    required Map<String, dynamic> match,
    Map<String, dynamic>? onCreate,
    Map<String, dynamic>? onMatch,
  }) {
    throw UnsupportedError(
        'mergeV() can only be used in transactional traversal. Use graph.transaction((txn) => txn.traversal().mergeV(...)).');
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
    throw UnsupportedError(
        'mergeE() can only be used in transactional traversal.');
  }

  @override
  Future<List<dynamic>> toList() async {
    final querySet = buildQuerySet();
    final results = await graph.database.rawQuery(
      querySet.resultQuery!.query,
      querySet.resultQuery!.parameters,
    );

    // Use GraphLoader to convert database results to appropriate types
    final loader = GraphLoader(db: graph.database);
    var processedResults = await loader.loadFromQueryResult(
      results,
      querySet.resultQuery!.resultType,
    );

    // For SqlQueryResultType.raw, extract values according to specific steps
    if (querySet.resultQuery!.resultType == SqlQueryResultType.raw) {
      processedResults = _extractRawValues(processedResults);
    }

    // Apply post-process filters
    for (final filter in _postProcessFilters) {
      processedResults = processedResults.where(filter).toList();
    }

    // Apply post-process transformers
    for (final transformer in _postProcessTransformers) {
      processedResults = processedResults.map(transformer).toList();
    }

    return processedResults;
  }

  List<dynamic> _extractRawValues(List<dynamic> results) {
    if (results.isEmpty) return results;

    // Extract values based on the last step
    if (steps.isNotEmpty) {
      final lastStep = steps.last;

      if (lastStep.name == 'id') {
        // For id() step, return id column value
        return results.map((row) {
          if (row is Map<String, dynamic> && row.containsKey('id')) {
            return row['id'];
          }
          return row;
        }).toList();
      } else if (lastStep.name == 'values') {
        // For values() step, return value column value
        return results.map((row) {
          if (row is Map<String, dynamic> && row.containsKey('value')) {
            final value = row['value'];
            // Remove str: prefix
            if (value is String && value.startsWith('str:')) {
              return value.substring(4);
            }
            return value;
          }
          return row;
        }).toList();
      }
    }

    return results;
  }

  @override
  // TODO(szktty): Implement stream support.
  Stream<dynamic> get stream => throw UnimplementedError();

  @override
  Stream<TraversalPath> get pathStream async* {
    if (!traversalPathEnabled) {
      throw StateError('Path tracking is not enabled. Call path() first.');
    }

    final querySet = buildQuerySet();
    final results = await graph.database.rawQuery(
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
}
