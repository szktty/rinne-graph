import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:rinne_graph/src/database/database.dart';
import 'package:rinne_graph/src/model/element_id.dart';
import 'package:rinne_graph/src/traversal/sql_traversal/sql_traversal_intf.dart';
import 'package:rinne_graph/src/traversal/traversal_internal.dart';

enum SqlQueryResultType {
  vertex,
  edge,
  mixed,
  raw,
}

final class SqlQuery {
  SqlQuery(
    this.query, [
    this.parameters = const [],
    this.resultType = SqlQueryResultType.raw,
    this.propertyKeyMap = const {},
  ]);

  final String query;
  final List<Object?> parameters;
  final SqlQueryResultType resultType;
  final Map<String, String> propertyKeyMap;
}

final class SqlQuerySet {
  SqlQuerySet({
    this.initialQueries = const [],
    this.resultQuery,
    this.cleanupQueries = const [],
  });

  final List<SqlQuery> initialQueries;
  final SqlQuery? resultQuery;
  final List<SqlQuery> cleanupQueries;
}

final class SqlResultSet {
  SqlResultSet(this.raw, this.propertyKeyMap) {
    entries =
        raw.map((entry) => SqlResultEntry(entry, propertyKeyMap)).toList();
  }

  final List<Map<String, dynamic>> raw;
  final Map<String, String> propertyKeyMap;
  late final List<SqlResultEntry> entries;

  int get length => entries.length;

  List<int> getIds() => entries.map((entry) => entry.getId()).nonNulls.toList();

  List<Map<String, dynamic>> getPropertiesList() {
    if (entries.isEmpty) {
      return [];
    }

    final propertiesList = <Map<String, dynamic>>[];
    final grouped = groupBy(entries, (entry) => entry.getId()!);
    for (final group in grouped.entries) {
      final properties = <String, dynamic>{};
      for (final entry in group.value) {
        properties[entry.raw['key'] as String] =
            DatabaseValueHelper.fromDatabaseValue(
          DatabaseValueType.fromId(entry.raw['type'] as int),
          entry.raw['value'],
        );
      }
      propertiesList.add(properties);
    }
    return propertiesList;
  }

  List<TraversalPath> getTraversalPaths() {
    final paths = <TraversalPath>[];
    for (final item in raw) {
      TraversalPath path = TraversalPathImpl();
      // path content is a JSON string
      // [[id, type, value], [id, type, value], ...]
      final stepInfos = (jsonDecode(item['path'] as String) as List<dynamic>)
          .cast<List<dynamic>>();
      for (final stepInfo in stepInfos) {
        final id = stepInfo[0] as int;
        final type = SqlTraversalPathType.fromId(stepInfo[1] as int);
        if (type == SqlTraversalPathType.vertex) {
          path = path.extend(ElementIdImpl(id: id, type: ElementIdType.vertex));
        } else if (type == SqlTraversalPathType.edge) {
          path = path.extend(ElementIdImpl(id: id, type: ElementIdType.edge));
        } else {
          final dbValue = DatabaseValueHelper.fromDatabaseValue(
              type.databaseValueType, stepInfo[2]);
          path = path.extend(dbValue);
        }
      }
      paths.add(path);
    }
    return paths;
  }

  @override
  String toString() {
    return 'QueryResultSet{raw: $raw, propertyKeyMap: $propertyKeyMap, entries: $entries}';
  }
}

final class SqlResultEntry {
  SqlResultEntry(this.raw, this.propertyKeyMap);

  final Map<String, dynamic> raw;
  final Map<String, String> propertyKeyMap;

  int? getId() => raw['id'] as int?;
}
