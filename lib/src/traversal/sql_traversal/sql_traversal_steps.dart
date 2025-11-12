import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/traversal/aggregation.dart';
import 'package:rinne_graph/src/traversal/sql_traversal/sql_traversal_intf.dart';
import 'package:rinne_graph/src/traversal/traversal_base/traversal_base.dart';

// Basic structure
// - Each step creates a search table using CTE
//   - This CTE becomes the search target for the next step
// - Each CTE has an id column, but creates an alias
// - The SELECT target table of the final query is the last CTE
// - Output columns return all columns of the last CTE
class VertexStep extends TraversalStepVertexBase implements SqlTraversalStep {
  VertexStep(super.ids);

  @override
  void apply(SqlTraversal t) {
    String? where;
    if (ids.isNotEmpty) {
      final idList = t.addParameters(ids);
      where = 'id IN (${idList.join(', ')})';
      t.addCte(
        cteName: 'V',
        id: 'vertices.id',
        type: '${SqlTraversalPathType.vertexId}',
        value: 'vertices.id',
        from: 'vertices',
        where: where,
      );
    } else {
      // Omit if ID is not specified
    }
  }
}

class EdgeStep extends TraversalStepEdgeBase implements SqlTraversalStep {
  EdgeStep(super.ids);

  @override
  void apply(SqlTraversal t) {
    String? where;
    if (ids.isNotEmpty) {
      final idList = t.addParameters(ids);
      where = 'id IN (${idList.join(', ')})';
      t.addCte(
        cteName: 'E',
        id: 'edges.id',
        type: '${SqlTraversalPathType.edgeId}',
        value: 'edges.id',
        from: 'edges',
        where: where,
      );
    } else {
      // Omit if ID is not specified
    }
  }
}

class IdStep extends TraversalStepIdBase implements SqlTraversalStep {
  @override
  void apply(SqlTraversal t) {
    t.addCte(
      cteName: 'id',
      id: '${t.lastCteName}.id',
      type: '${DatabaseValueType.integer.id}',
      value: '${t.lastCteName}.id',
    );
  }
}

class HasIdStep extends TraversalStepHasIdBase implements SqlTraversalStep {
  HasIdStep(this.ids);

  final List<int> ids;

  @override
  void apply(SqlTraversal t) {
    final idList = t.addParameters(ids);
    t.addCte(
      cteName: 'hasId',
      id: 'id',
      type: '${t.lastCteName}.type',
      value: 'id',
      where: 'id IN (${idList.join(', ')})',
    );
  }
}

class HasLabelStep extends TraversalStepHasLabelBase
    implements SqlTraversalStep {
  HasLabelStep(this.labels);

  final List<String> labels;

  @override
  void apply(SqlTraversal t) {
    if (labels.isEmpty) return;

    final labelCondition = t.addParameters(labels);
    t.addCte(
      cteName: 'hasLabel',
      id: 'id',
      type: t.elementTypeColumn,
      value: 'id',
      select: 'l.label AS label',
      joins: [
        '${t.labelTable} l ON ${t.lastCteName}.id = l.${t.elementIdColumn}',
      ],
      where: 'l.label IN (${labelCondition.join(', ')})',
    );
  }
}

class HasKeyStep extends TraversalStepHasKeyBase implements SqlTraversalStep {
  HasKeyStep(this.key, this.value);

  final String key;
  final dynamic value;

  @override
  void apply(SqlTraversal t) {
    final keyPlaceholder = t.addParameter(key);
    final typePlaceholder =
        t.addParameter(DatabaseValueHelper.getDatabaseValueType(value).id);

    String condition;
    if (value is NullValue) {
      condition = '${t.propertyTable}.key = $keyPlaceholder AND '
          '${t.propertyTable}.type = $typePlaceholder AND '
          '${t.propertyTable}.value IS NULL';
    } else {
      final valuePlaceholder =
          t.addParameter(DatabaseValueHelper.toDatabaseValue(value));
      condition = '${t.propertyTable}.key = $keyPlaceholder AND '
          '${t.propertyTable}.type = $typePlaceholder AND '
          '${t.propertyTable}.value = $valuePlaceholder';
    }

    t.addCte(
      cteName: 'has',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: condition,
    );
  }
}

class HasKeyContainsStep extends TraversalStepHasKeyContainsBase
    implements SqlTraversalStep {
  HasKeyContainsStep(this.key, this.value);

  final String key;
  final String value;

  @override
  void apply(SqlTraversal t) {
    final keyPlaceholder = t.addParameter(key);
    final typePlaceholder = t.addParameter(DatabaseValueType.string.id);
    final valuePlaceholder = t.addParameter('%$value%');

    final condition = '${t.propertyTable}.key = $keyPlaceholder AND '
        '${t.propertyTable}.type = $typePlaceholder AND '
        '${t.propertyTable}.value LIKE $valuePlaceholder';

    t.addCte(
      cteName: 'hasContains',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: condition,
    );
  }
}

class HasKeyStartsWithStep extends TraversalStepHasKeyStartsWithBase
    implements SqlTraversalStep {
  HasKeyStartsWithStep(this.key, this.value);

  final String key;
  final String value;

  @override
  void apply(SqlTraversal t) {
    final keyPlaceholder = t.addParameter(key);
    final typePlaceholder = t.addParameter(DatabaseValueType.string.id);
    final valuePlaceholder = t.addParameter('str:$value%');

    final condition = '${t.propertyTable}.key = $keyPlaceholder AND '
        '${t.propertyTable}.type = $typePlaceholder AND '
        '${t.propertyTable}.value LIKE $valuePlaceholder';

    t.addCte(
      cteName: 'hasStartsWith',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: condition,
    );
  }
}

class HasKeyEndsWithStep extends TraversalStepHasKeyEndsWithBase
    implements SqlTraversalStep {
  HasKeyEndsWithStep(this.key, this.value);

  final String key;
  final String value;

  @override
  void apply(SqlTraversal t) {
    final keyPlaceholder = t.addParameter(key);
    final typePlaceholder = t.addParameter(DatabaseValueType.string.id);
    final valuePlaceholder = t.addParameter('%$value');

    final condition = '${t.propertyTable}.key = $keyPlaceholder AND '
        '${t.propertyTable}.type = $typePlaceholder AND '
        '${t.propertyTable}.value LIKE $valuePlaceholder';

    t.addCte(
      cteName: 'hasEndsWith',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: condition,
    );
  }
}

class HasKeyMatchesStep extends TraversalStepHasKeyMatchesBase
    implements SqlTraversalStep {
  HasKeyMatchesStep(this.key, this.pattern);

  final String key;
  final String pattern;

  @override
  void apply(SqlTraversal t) {
    final keyPlaceholder = t.addParameter(key);
    final typePlaceholder = t.addParameter(DatabaseValueType.string.id);
    final patternPlaceholder = t.addParameter(pattern);

    final condition = '${t.propertyTable}.key = $keyPlaceholder AND '
        '${t.propertyTable}.type = $typePlaceholder AND '
        'SUBSTR(${t.propertyTable}.value, 5) REGEXP $patternPlaceholder';

    t.addCte(
      cteName: 'hasMatches',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: condition,
    );
  }
}

class HasKeyGreaterThanStep extends TraversalStepHasKeyGreaterThanBase
    implements SqlTraversalStep {
  HasKeyGreaterThanStep(this.key, this.value);

  final String key;
  final dynamic value;

  @override
  void apply(SqlTraversal t) {
    final keyPlaceholder = t.addParameter(key);
    final typePlaceholder =
        t.addParameter(DatabaseValueHelper.getDatabaseValueType(value).id);
    final valuePlaceholder =
        t.addParameter(DatabaseValueHelper.toDatabaseValue(value));

    final condition = '${t.propertyTable}.key = $keyPlaceholder AND '
        '${t.propertyTable}.type = $typePlaceholder AND '
        '${t.propertyTable}.value > $valuePlaceholder';

    t.addCte(
      cteName: 'hasGreaterThan',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: condition,
    );
  }
}

class HasKeyLessThanStep extends TraversalStepHasKeyLessThanBase
    implements SqlTraversalStep {
  HasKeyLessThanStep(this.key, this.value);

  final String key;
  final dynamic value;

  @override
  void apply(SqlTraversal t) {
    final keyPlaceholder = t.addParameter(key);
    final typePlaceholder =
        t.addParameter(DatabaseValueHelper.getDatabaseValueType(value).id);
    final valuePlaceholder =
        t.addParameter(DatabaseValueHelper.toDatabaseValue(value));

    final condition = '${t.propertyTable}.key = $keyPlaceholder AND '
        '${t.propertyTable}.type = $typePlaceholder AND '
        '${t.propertyTable}.value < $valuePlaceholder';

    t.addCte(
      cteName: 'hasLessThan',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: condition,
    );
  }
}

class HasKeyBetweenStep extends TraversalStepHasKeyBetweenBase
    implements SqlTraversalStep {
  HasKeyBetweenStep(this.key, this.min, this.max);

  final String key;
  final dynamic min;
  final dynamic max;

  @override
  void apply(SqlTraversal t) {
    final keyPlaceholder = t.addParameter(key);
    final typePlaceholder =
        t.addParameter(DatabaseValueHelper.getDatabaseValueType(min).id);
    final minPlaceholder =
        t.addParameter(DatabaseValueHelper.toDatabaseValue(min));
    final maxPlaceholder =
        t.addParameter(DatabaseValueHelper.toDatabaseValue(max));

    final condition = '${t.propertyTable}.key = $keyPlaceholder AND '
        '${t.propertyTable}.type = $typePlaceholder AND '
        '${t.propertyTable}.value BETWEEN $minPlaceholder AND $maxPlaceholder';

    t.addCte(
      cteName: 'hasBetween',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: condition,
    );
  }
}

class HasKeyInStep extends TraversalStepHasKeyInBase
    implements SqlTraversalStep {
  HasKeyInStep(this.key, this.values);

  final String key;
  final List<dynamic> values;

  @override
  void apply(SqlTraversal t) {
    if (values.isEmpty) return;

    final keyPlaceholder = t.addParameter(key);
    final valuePlaceholders =
        t.addParameters(values.map(DatabaseValueHelper.toDatabaseValue));

    final condition = '${t.propertyTable}.key = $keyPlaceholder AND '
        '${t.propertyTable}.value IN (${valuePlaceholders.join(', ')})';

    t.addCte(
      cteName: 'hasIn',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: condition,
    );
  }
}

class HasNotStep extends TraversalStepHasNotBase implements SqlTraversalStep {
  HasNotStep(this.key);

  final String key;

  @override
  void apply(SqlTraversal t) {
    // Pass through elements where the specified key does not exist or is NullValue (type=null_ and value IS NULL)
    final keyPlaceholder = t.addParameter(key);
    final nullTypePlaceholder = t.addParameter(DatabaseValueType.null_.id);

    t.addCte(
      cteName: 'hasNot',
      id: '${t.lastCteName}.id',
      type: t.elementTypeColumn,
      value: '${t.lastCteName}.id',
      from: t.lastCteName,
      joins: [
        'LEFT JOIN ${t.propertyTable} p ON ${t.lastCteName}.id = p.${t.elementIdColumn} AND p.key = $keyPlaceholder',
      ],
      where:
          'p.key IS NULL OR (p.type = $nullTypePlaceholder AND p.value IS NULL)',
    );
  }
}

class HasNotLabelStep extends TraversalStepHasNotLabelBase
    implements SqlTraversalStep {
  HasNotLabelStep(this.labels);

  final List<String> labels;

  @override
  void apply(SqlTraversal t) {
    if (labels.isEmpty) return;

    final labelCondition = t.addParameters(labels);
    t.addCte(
      cteName: 'hasNotLabel',
      id: 'id',
      type: t.elementTypeColumn,
      value: 'id',
      where: 'id NOT IN ('
          ' SELECT ${t.elementIdColumn} FROM ${t.labelTable} l '
          ' WHERE l.label IN (${labelCondition.join(', ')})'
          ' )',
    );
  }
}

class HasKeyNotInStep extends TraversalStepHasKeyNotInBase
    implements SqlTraversalStep {
  HasKeyNotInStep(this.key, this.values);

  final String key;
  final List<dynamic> values;

  @override
  void apply(SqlTraversal t) {
    if (values.isEmpty) return;

    final keyPlaceholder = t.addParameter(key);
    final valuePlaceholders =
        t.addParameters(values.map(DatabaseValueHelper.toDatabaseValue));

    final condition = '${t.propertyTable}.key = $keyPlaceholder AND '
        '${t.propertyTable}.value NOT IN (${valuePlaceholders.join(', ')})';

    t.addCte(
      cteName: 'hasNotIn',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: condition,
    );
  }
}

class OutStep extends TraversalStepOutBase implements SqlTraversalStep {
  OutStep(this.labels);

  final List<String> labels;

  @override
  void apply(SqlTraversal t) {
    t.addCte(
      cteName: 'out',
      id: 'e.to_vertex_id',
      type: '${SqlTraversalPathType.vertexId}',
      value: 'e.to_vertex_id',
      select:
          'e.to_vertex_id AS id, ${SqlTraversalPathType.vertexId} AS type, e.to_vertex_id AS value',
      joins: [
        'edges e ON ${t.lastCteName}.id = e.from_vertex_id',
        if (labels.isNotEmpty)
          'edge_labels el ON e.id = el.edge_id AND el.label IN (${labels.map(t.addParameter).join(', ')})',
      ],
    );
  }
}

class InStep extends TraversalStepInBase implements SqlTraversalStep {
  InStep(this.labels);

  final List<String> labels;

  @override
  void apply(SqlTraversal t) {
    t.addCte(
      cteName: 'in',
      id: 'e.from_vertex_id',
      type: '${SqlTraversalPathType.vertexId}',
      value: 'e.from_vertex_id',
      select:
          'e.from_vertex_id AS id, ${SqlTraversalPathType.vertexId} AS type, e.from_vertex_id AS value',
      joins: [
        'edges e ON ${t.lastCteName}.id = e.to_vertex_id',
        if (labels.isNotEmpty)
          'edge_labels el ON e.id = el.edge_id AND el.label IN (${labels.map(t.addParameter).join(', ')})',
      ],
    );
  }
}

class BothStep extends TraversalStepBothBase implements SqlTraversalStep {
  BothStep(this.labels);

  final List<String> labels;

  @override
  void apply(SqlTraversal t) {
    final idColumn = '''
      COALESCE(
        CASE WHEN ${t.lastCteName}.id = e.from_vertex_id THEN e.to_vertex_id ELSE NULL END,
        CASE WHEN ${t.lastCteName}.id = e.to_vertex_id THEN e.from_vertex_id ELSE NULL END
      )
    ''';
    t.addCte(
      cteName: 'both',
      id: idColumn,
      type: '${SqlTraversalPathType.vertexId}',
      value: idColumn,
      select:
          '($idColumn) AS id, ${SqlTraversalPathType.vertexId} AS type, ($idColumn) AS value',
      joins: [
        'edges e ON ${t.lastCteName}.id = e.from_vertex_id OR ${t.lastCteName}.id = e.to_vertex_id',
        if (labels.isNotEmpty)
          'edge_labels el ON e.id = el.edge_id AND el.label IN (${labels.map(t.addParameter).join(', ')})',
      ],
    );
  }
}

class ValuesStep extends TraversalStepValuesBase implements SqlTraversalStep {
  ValuesStep(super.keys);

  @override
  void apply(SqlTraversal t) {
    final keyPlaceholders =
        keys.isNotEmpty ? t.addParameters(keys) : <String>[];

    // Use appropriate column for base tables (vertices, edges)
    String idColumn;

    if (t.lastCteName == 'vertices') {
      idColumn = 'vertices.id';
    } else if (t.lastCteName == 'edges') {
      idColumn = 'edges.id';
    } else {
      // Use existing column for CTE
      idColumn = '${t.lastCteName}.id';
    }

    t.addCte(
      cteName: 'values',
      id: idColumn,
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON $idColumn = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: keyPlaceholders.isNotEmpty
          ? '${t.propertyTable}.key IN (${keyPlaceholders.join(', ')})'
          : null,
    );
  }
}

class ValueMapStep extends TraversalStepValueMapBase
    implements SqlTraversalStep {
  ValueMapStep(super.keys);

  @override
  void apply(SqlTraversal t) {
    // valueMap() step requires complex implementation
    // Basic implementation creates CTE to retrieve properties
    // Actual implementation needs to return properties in map format
    final keyPlaceholders =
        keys.isNotEmpty ? t.addParameters(keys) : <String>[];

    // Use appropriate column for base tables (vertices, edges)
    String idColumn;
    String typeColumn;
    String valueColumn;

    if (t.lastCteName == 'vertices') {
      idColumn = 'vertices.id';
      typeColumn = '${SqlTraversalPathType.vertexId}';
      valueColumn = 'vertices.id';
    } else if (t.lastCteName == 'edges') {
      idColumn = 'edges.id';
      typeColumn = '${SqlTraversalPathType.edgeId}';
      valueColumn = 'edges.id';
    } else {
      // Use existing column for CTE
      idColumn = '${t.lastCteName}.id';
      typeColumn = '${t.lastCteName}.type';
      valueColumn = '${t.lastCteName}.value';
    }

    t.addCte(
      cteName: 'valueMap',
      id: idColumn,
      type: typeColumn,
      value: valueColumn,
      select:
          '${t.propertyTable}.key, ${t.propertyTable}.value, ${t.propertyTable}.type',
      joins: [
        '${t.propertyTable} ON $idColumn = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: keyPlaceholders.isNotEmpty
          ? '${t.propertyTable}.key IN (${keyPlaceholders.join(', ')})'
          : null,
    );
  }
}

class LimitStep extends TraversalStepLimitBase implements SqlTraversalStep {
  LimitStep(super.limit);

  @override
  void apply(SqlTraversal t) {
    t.setLimit(limit);
  }
}

class SkipStep extends TraversalStepSkipBase implements SqlTraversalStep {
  SkipStep(super.offset);

  @override
  void apply(SqlTraversal t) {
    t.setOffset(offset);
  }
}

class OrderStep extends TraversalStepOrderBase implements SqlTraversalStep {
  @override
  void apply(SqlTraversal t) {
    // TODO(szktty): Consider including 'limit' in the descriptor.
    final descriptors = t.collectAggregationDescriptors(
      modulatorSteps,
      (step) => (step as SqlTraversalStep).apply(t),
    );

    // Order the specified keys
    final idRanks = <IdSortDescriptor, int>{};
    final keyRanks = <KeySortDescriptor, int>{};
    for (var i = 0; i < descriptors.length; i++) {
      final descriptor = descriptors[i];
      descriptor.rank = i;
      if (descriptor is IdSortDescriptor) {
        idRanks[descriptor] = idRanks.length;
      } else if (descriptor is KeySortDescriptor) {
        keyRanks[descriptor] = keyRanks.length;
      } else {
        throw StateError('Unknown sort descriptor: $descriptor');
      }
    }

    // CTE: Prepare table for each specified key
    // Convert property type and value to comparable value
    final comparableTables = <SortDescriptor, String>{};
    for (final descriptor in descriptors) {
      if (descriptor is IdSortDescriptor) {
        // do nothing
      } else if (descriptor is KeySortDescriptor) {
        const idColumn = 't.id';
        const typeColumn = '''
        CASE
          WHEN p.type IS NULL THEN 0  -- property not found
          WHEN p.type = 0 THEN 0  -- null
          WHEN p.type = 1 THEN 1  -- boolean
          WHEN p.type IN (2, 3) THEN 2  -- integer, float
          WHEN p.type = 4 THEN 3  -- string
          WHEN p.type = 5 THEN 4  -- datetime
          WHEN p.type = 6 THEN 5  -- blob
          WHEN p.type IN (${SqlTraversalPathType.vertexId}, ${SqlTraversalPathType.edgeId}) THEN 2  -- vertex, edge as number
          ELSE 6  -- unknown
        END
        ''';
        const valueColumn = '''
        CASE
          WHEN p.type IS NULL THEN NULL  -- property not found
          WHEN p.type = 0 THEN NULL
          WHEN p.type = 1 THEN CAST(p.value AS INTEGER)
          WHEN p.type IN (2, 3) THEN CAST(p.value AS REAL)
          WHEN p.type = 4 THEN p.value
          WHEN p.type = 5 THEN datetime(p.value)
          WHEN p.type = 6 THEN p.value
          ELSE p.value
        END''';
        final joins = <String>[];
        joins.add('LEFT JOIN ${t.propertyTable} p '
            'ON t.id = p.${t.elementIdColumn} '
            'AND p.key = ${t.addParameter(descriptor.key)}');

        final cte = t.addCte(
          cteName: 'comparable_values',
          id: idColumn,
          type: typeColumn,
          value: valueColumn,
          from: '${t.lastCteName} t',
          joins: joins,
          // TODO(szktty): Implement traversal support.
        );
        comparableTables[descriptor] = cte;
      } else {
        throw StateError('Unknown sort descriptor: $descriptor');
      }
    }

    // CTE: Join tables generated for each key and sort

    String getOrderType(SortOrder order) {
      switch (order) {
        case SortOrder.asc:
          return 'ASC';
        case SortOrder.desc:
          return 'DESC';
        case SortOrder.shuffle:
          return 'RANDOM()';
      }
    }

    final sortJoins = <String>[];
    final sortColumns = <String>[];
    final sortOrders = <String>[];
    for (final descriptor in descriptors) {
      if (descriptor is IdSortDescriptor) {
        final orderType = getOrderType(descriptor.order);
        sortOrders.add('t.id $orderType');
      } else if (descriptor is KeySortDescriptor) {
        final orderType = getOrderType(descriptor.order);
        final cte = comparableTables[descriptor]!;
        final table = 'p${descriptor.rank}';
        sortJoins.add('LEFT JOIN $cte $table '
            'ON t.id = $table.id');
        sortColumns.add('$table.type AS ${table}_type');
        sortColumns.add('$table.value AS ${table}_value');
        sortOrders.add('${table}_type $orderType, '
            '${table}_value $orderType');
      } else {
        throw StateError('Unknown sort descriptor: $descriptor');
      }
    }

    String typeColumn;
    if (t.lastCteName == 'vertices') {
      typeColumn = '${SqlTraversalPathType.vertexId}';
    } else if (t.lastCteName == 'edges') {
      typeColumn = '${SqlTraversalPathType.edgeId}';
    } else {
      typeColumn = 't.type';
    }

    String valueColumn;
    if (t.lastCteName == 'vertices') {
      valueColumn = 't.id';
    } else if (t.lastCteName == 'edges') {
      valueColumn = 't.id';
    } else {
      valueColumn = 't.value';
    }

    t.addCte(
      cteName: 'sort_values',
      id: 't.id',
      // FIXME
      type: typeColumn,
      value: valueColumn,
      select: sortColumns.isNotEmpty ? sortColumns.join(', ') : null,
      from: '${t.lastCteName} t',
      joins: sortJoins,
      orderBy: sortOrders.join(', '),
    );
  }
}

class ByIdStep extends TraversalStepByIdBase implements SqlTraversalStep {
  ByIdStep(super.order);

  @override
  void apply(SqlTraversal t) {
    t.addAggregationDescriptor(IdSortDescriptor(order));
  }
}

class ByKeyStep extends TraversalStepByKeyBase implements SqlTraversalStep {
  ByKeyStep(super.key, super.order);

  @override
  void apply(SqlTraversal t) {
    t.addAggregationDescriptor(KeySortDescriptor(key, order));
  }
}

class GroupStep extends TraversalStepGroupBase implements SqlTraversalStep {
  @override
  void apply(SqlTraversal t) {
    // group() step does nothing in basic implementation
    // Actual grouping is performed by subsequent byKey() or byId() steps
    // Basic implementation passes current results as is
  }
}

class DedupStep extends TraversalStepDedupBase implements SqlTraversalStep {
  @override
  void apply(SqlTraversal t) {
    // Use DISTINCT to remove duplicates
    // Use appropriate column for base tables (vertices, edges)
    String idColumn;
    String typeColumn;
    String valueColumn;

    if (t.lastCteName == 'vertices') {
      idColumn = 'vertices.id';
      typeColumn = '${SqlTraversalPathType.vertexId}';
      valueColumn = 'vertices.id';
    } else if (t.lastCteName == 'edges') {
      idColumn = 'edges.id';
      typeColumn = '${SqlTraversalPathType.edgeId}';
      valueColumn = 'edges.id';
    } else {
      // Use existing column for CTE
      idColumn = '${t.lastCteName}.id';
      typeColumn = '${t.lastCteName}.type';
      valueColumn = '${t.lastCteName}.value';
    }

    t.addCte(
      cteName: 'dedup',
      id: idColumn,
      type: typeColumn,
      value: valueColumn,
      distinct: true,
      from: t.lastCteName,
    );
  }
}

class CountStep extends TraversalStepCountBase implements SqlTraversalStep {
  @override
  void apply(SqlTraversal t) {
    // Create CTE to execute count
    t.addCte(
      cteName: 'count',
      id: 'COUNT(*)',
      type: '${DatabaseValueType.integer.id}',
      value: 'COUNT(*)',
      select: 'COUNT(*) AS count_value',
      from: t.lastCteName,
    );
  }
}

class AsStep extends TraversalStepAsBase implements SqlTraversalStep {
  AsStep(super.label);

  @override
  void apply(SqlTraversal t) {
    // as() step only labels current results and does not affect SQL query
    // Save label information only when path feature is enabled
    // Actual implementation needs to manage labels in path tracking system
    // Basic implementation does nothing
  }
}

class SelectStep extends TraversalStepSelectBase implements SqlTraversalStep {
  SelectStep(super.labels);

  @override
  void apply(SqlTraversal t) {
    // select() step selects results with specified labels
    // Basic implementation returns current results as is
    // Actual implementation needs to select results with specified labels from labeled results
    // TODO(szktty): Implement label selection in coordination with path tracking system.
  }
}

class RepeatStep extends TraversalStepRepeatBase implements SqlTraversalStep {
  RepeatStep(super.traversal);

  @override
  void apply(SqlTraversal t) {
    // repeat() step requires complex implementation
    // Basic implementation executes specified traversal only once
    // Actual implementation performs repeated processing in combination with until() or times()
    // TODO(szktty): Implement full repeat processing functionality.
    throw UnimplementedError('RepeatStep requires complex implementation');
  }
}

class UntilStep extends TraversalStepUntilBase implements SqlTraversalStep {
  UntilStep(super.predicate);

  @override
  void apply(SqlTraversal t) {
    // until() step is used in combination with repeat()
    // Basic implementation does nothing
    // TODO(szktty): Implement coordination with repeat() step.
  }
}

class TimesStep extends TraversalStepTimesBase implements SqlTraversalStep {
  TimesStep(super.times);

  @override
  void apply(SqlTraversal t) {
    // times() step is used in combination with repeat()
    // Basic implementation does nothing
    // TODO(szktty): Implement coordination with repeat() step.
  }
}

class PathStep extends TraversalStepPathBase implements SqlTraversalStep {
  @override
  void apply(SqlTraversal t) {
    // path() step passes current results as is and enables path tracking
    // Use appropriate column for base tables (vertices, edges)
    String idColumn;
    String typeColumn;
    String valueColumn;

    if (t.lastCteName == 'vertices') {
      idColumn = 'vertices.id';
      typeColumn = '${SqlTraversalPathType.vertexId}';
      valueColumn = 'vertices.id';
    } else if (t.lastCteName == 'edges') {
      idColumn = 'edges.id';
      typeColumn = '${SqlTraversalPathType.edgeId}';
      valueColumn = 'edges.id';
    } else {
      // Use existing column for CTE
      idColumn = '${t.lastCteName}.id';
      typeColumn = '${t.lastCteName}.type';
      valueColumn = '${t.lastCteName}.value';
    }

    t.addCte(
      cteName: 'path',
      id: idColumn,
      type: typeColumn,
      value: valueColumn,
      from: t.lastCteName,
    );
  }
}

class OutEStep extends TraversalStepOutEBase implements SqlTraversalStep {
  OutEStep(this.labels);

  final List<String> labels;

  @override
  void apply(SqlTraversal t) {
    // Get outgoing edges from vertex
    // t.lastCteName is current vertex table
    t.addCte(
      cteName: 'outE',
      id: 'e.id',
      type: '${SqlTraversalPathType.edgeId}',
      value: 'e.id',
      select:
          'e.id AS id, ${SqlTraversalPathType.edgeId} AS type, e.id AS value, e.from_vertex_id, e.to_vertex_id',
      joins: [
        'edges e ON ${t.lastCteName}.id = e.from_vertex_id',
        if (labels.isNotEmpty)
          'edge_labels el ON e.id = el.edge_id AND el.label IN (${labels.map(t.addParameter).join(", ")})',
      ],
    );
  }
}

class InEStep extends TraversalStepInEBase implements SqlTraversalStep {
  InEStep(this.labels);

  final List<String> labels;

  @override
  void apply(SqlTraversal t) {
    // Get incoming edges to vertex
    // t.lastCteName is current vertex table
    t.addCte(
      cteName: 'inE',
      id: 'e.id',
      type: '${SqlTraversalPathType.edgeId}',
      value: 'e.id',
      select:
          'e.id AS id, ${SqlTraversalPathType.edgeId} AS type, e.id AS value, e.from_vertex_id, e.to_vertex_id',
      joins: [
        'edges e ON ${t.lastCteName}.id = e.to_vertex_id',
        if (labels.isNotEmpty)
          'edge_labels el ON e.id = el.edge_id AND el.label IN (${labels.map(t.addParameter).join(", ")})',
      ],
    );
  }
}

class BothEStep extends TraversalStepBothEBase implements SqlTraversalStep {
  BothEStep(this.labels);

  final List<String> labels;

  @override
  void apply(SqlTraversal t) {
    // Get all edges connected to vertex
    // t.lastCteName is current vertex table
    t.addCte(
      cteName: 'bothE',
      id: 'e.id',
      type: '${SqlTraversalPathType.edgeId}',
      value: 'e.id',
      select:
          'e.id AS id, ${SqlTraversalPathType.edgeId} AS type, e.id AS value, e.from_vertex_id, e.to_vertex_id',
      joins: [
        'edges e ON ${t.lastCteName}.id = e.from_vertex_id OR ${t.lastCteName}.id = e.to_vertex_id',
        if (labels.isNotEmpty)
          'edge_labels el ON e.id = el.edge_id AND el.label IN (${labels.map(t.addParameter).join(", ")})',
      ],
    );
  }
}

class OutVStep extends TraversalStepOutVBase implements SqlTraversalStep {
  @override
  void apply(SqlTraversal t) {
    // Move to source vertex of edge
    // t.lastCteName is current edge table
    t.addCte(
      cteName: 'outV',
      id: 'e.from_vertex_id',
      type: '${SqlTraversalPathType.vertexId}',
      value: 'e.from_vertex_id',
      select:
          'e.from_vertex_id AS id, ${SqlTraversalPathType.vertexId} AS type, e.from_vertex_id AS value',
      from: '${t.lastCteName} t',
      joins: [
        'edges e ON t.id = e.id',
      ],
    );
  }
}

class InVStep extends TraversalStepInVBase implements SqlTraversalStep {
  @override
  void apply(SqlTraversal t) {
    // Move to target vertex of edge
    // t.lastCteName is current edge table
    t.addCte(
      cteName: 'inV',
      id: 'e.to_vertex_id',
      type: '${SqlTraversalPathType.vertexId}',
      value: 'e.to_vertex_id',
      select:
          'e.to_vertex_id AS id, ${SqlTraversalPathType.vertexId} AS type, e.to_vertex_id AS value',
      from: '${t.lastCteName} t',
      joins: [
        'edges e ON t.id = e.id',
      ],
    );
  }
}

class BothVStep extends TraversalStepBothVBase implements SqlTraversalStep {
  @override
  void apply(SqlTraversal t) {
    // Move to both vertices of edge
    // t.lastCteName is current edge table

    // Get source vertex
    t.addCte(
      cteName: 'bothV_from',
      id: '${t.lastCteName}.from_vertex_id',
      type: '${SqlTraversalPathType.vertexId}',
      value: '${t.lastCteName}.from_vertex_id',
      from: t.lastCteName,
    );

    // Get target vertex
    t.addCte(
      cteName: 'bothV_to',
      id: '${t.lastCteName}.to_vertex_id',
      type: '${SqlTraversalPathType.vertexId}',
      value: '${t.lastCteName}.to_vertex_id',
      from: t.lastCteName,
    );

    // Join source and target vertices
    // Simply create CTE containing both vertices
    // Create final CTE
    t.addCte(
      cteName: 'bothV',
      id: 'v.id',
      type: '${SqlTraversalPathType.vertexId}',
      value: 'v.id',
      from: 'vertices v',
      joins: [
        '(SELECT from_vertex_id AS vertex_id FROM ${t.lastCteName} UNION SELECT to_vertex_id AS vertex_id FROM ${t.lastCteName}) AS b ON v.id = b.vertex_id',
      ],
    );
  }
}

class FilterStep extends TraversalStepFilterBase implements SqlTraversalStep {
  FilterStep(super.filterFunction);

  @override
  void apply(SqlTraversal t) {
    // Create basic CTE (pass results as is)
    // Use appropriate column for base tables (vertices, edges)
    String idColumn;
    String typeColumn;
    String valueColumn;

    if (t.lastCteName == 'vertices') {
      idColumn = 'vertices.id';
      typeColumn = '${SqlTraversalPathType.vertexId}';
      valueColumn = 'vertices.id';
    } else if (t.lastCteName == 'edges') {
      idColumn = 'edges.id';
      typeColumn = '${SqlTraversalPathType.edgeId}';
      valueColumn = 'edges.id';
    } else {
      // Use existing column for CTE
      idColumn = '${t.lastCteName}.id';
      typeColumn = '${t.lastCteName}.type';
      valueColumn = '${t.lastCteName}.value';
    }

    t.addCte(
      cteName: 'filter',
      id: idColumn,
      type: typeColumn,
      value: valueColumn,
      from: t.lastCteName,
    );

    // Register as post-process filter
    t.addPostProcessFilter(filterFunction);
  }
}

class MapStep extends TraversalStepMapBase implements SqlTraversalStep {
  MapStep(super.transformer);

  @override
  void apply(SqlTraversal t) {
    // Create basic CTE (pass results as is)
    // Use appropriate column for base tables (vertices, edges)
    String idColumn;
    String typeColumn;
    String valueColumn;

    if (t.lastCteName == 'vertices') {
      idColumn = 'vertices.id';
      typeColumn = '${SqlTraversalPathType.vertexId}';
      valueColumn = 'vertices.id';
    } else if (t.lastCteName == 'edges') {
      idColumn = 'edges.id';
      typeColumn = '${SqlTraversalPathType.edgeId}';
      valueColumn = 'edges.id';
    } else {
      // Use existing column for CTE
      idColumn = '${t.lastCteName}.id';
      typeColumn = '${t.lastCteName}.type';
      valueColumn = '${t.lastCteName}.value';
    }

    t.addCte(
      cteName: 'map',
      id: idColumn,
      type: typeColumn,
      value: valueColumn,
      from: t.lastCteName,
    );

    // Register as post-process transformer
    t.addPostProcessTransformer(transformer);
  }
}

// List search step (using LIKE operator)
class ListContainsStep extends TraversalStepListContainsBase
    implements SqlTraversalStep {
  ListContainsStep(super.key, super.value);

  @override
  void apply(SqlTraversal t) {
    final keyPlaceholder = t.addParameter(key);
    final typePlaceholder = t.addParameter(DatabaseValueType.list.id);

    // Build search pattern (match JSON encoded format)
    String searchPattern;
    if (value is String) {
      // For strings: enclosed in quotes in JSON
      searchPattern = '%"$value"%';
    } else if (value is bool) {
      // For booleans: represented as true/false in JSON
      searchPattern = '%$value%';
    } else {
      // For numbers: represented without quotes in JSON
      searchPattern = '%$value%';
    }
    final valuePlaceholder = t.addParameter(searchPattern);

    final condition = '${t.propertyTable}.key = $keyPlaceholder AND '
        '${t.propertyTable}.type = $typePlaceholder AND '
        '${t.propertyTable}.value LIKE $valuePlaceholder';

    t.addCte(
      cteName: 'listContains',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: condition,
    );
  }
}

// List length filter step (using JSON1 extension)
class ListLengthStep extends TraversalStepListLengthBase
    implements SqlTraversalStep {
  ListLengthStep(super.key, super.length);

  @override
  void apply(SqlTraversal t) {
    final keyPlaceholder = t.addParameter(key);
    final typePlaceholder = t.addParameter(DatabaseValueType.list.id);
    final lengthPlaceholder = t.addParameter(length);

    final condition = '${t.propertyTable}.key = $keyPlaceholder AND '
        '${t.propertyTable}.type = $typePlaceholder AND '
        'json_array_length(${t.propertyTable}.value) = $lengthPlaceholder';

    t.addCte(
      cteName: 'listLength',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
      ],
      where: condition,
    );
  }
}

// Exact list search step using JSON1 extension
class ListContainsExactStep extends TraversalStepListContainsExactBase
    implements SqlTraversalStep {
  ListContainsExactStep(super.key, super.value);

  @override
  void apply(SqlTraversal t) {
    final keyPlaceholder = t.addParameter(key);
    final typePlaceholder = t.addParameter(DatabaseValueType.list.id);

    // Convert value for SQLite parameter
    dynamic sqlValue;
    if (value is bool) {
      sqlValue = (value as bool) ? 1 : 0;
    } else if (value is String) {
      sqlValue = value;
    } else {
      sqlValue = value;
    }
    final valuePlaceholder = t.addParameter(sqlValue);

    // Use json_each to expand each element of array and search for exact match
    final condition = '${t.propertyTable}.key = $keyPlaceholder AND '
        '${t.propertyTable}.type = $typePlaceholder AND '
        'json_each.value = $valuePlaceholder';

    t.addCte(
      cteName: 'listContainsExact',
      id: '${t.propertyTable}.${t.elementIdColumn}',
      type: '${t.propertyTable}.type',
      value: '${t.propertyTable}.value',
      select: '${t.propertyTable}.key',
      joins: [
        '${t.propertyTable} ON ${t.lastCteName}.id = ${t.propertyTable}.${t.elementIdColumn}',
        'json_each(${t.propertyTable}.value)',
      ],
      where: condition,
    );
  }
}
