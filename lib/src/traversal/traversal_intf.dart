import 'package:rinne_graph/src/traversal/sql_traversal/sql_query.dart';
import 'package:rinne_graph/src/traversal/traversal_path.dart';

// TODO(szktty): Consider defining detailed error types using sealed classes for better error messages in Arizal query support.
enum SortOrder {
  asc,
  desc,
  shuffle,
}

// S: Start, E_: End
abstract class TraversalSource {
  Traversal V([List<int>? ids]);

  Traversal E([List<int>? ids]);
}

// TODO(szktty): Implement additional traversal steps: addE, addV, key, label, is, min, max, not, and, or, properties, repeat, times, where, match, select, path, simplePath, some, to.
// TODO(szktty): Consider implementing subgraph support.
abstract class Traversal {
  // Basic traversal operations
  Traversal V([List<int>? ids]);

  Traversal E([List<int>? ids]);

  Traversal id();

  // Filtering
  Traversal hasId([List<int>? ids]);

  Traversal hasKey(String key, dynamic value);

  // Extended search functionality
  Traversal hasKeyContains(String key, String value);

  Traversal hasKeyStartsWith(String key, String value);

  Traversal hasKeyEndsWith(String key, String value);

  Traversal hasKeyMatches(String key, String pattern);

  // Comparison operators
  Traversal hasKeyGreaterThan(String key, dynamic value);

  Traversal hasKeyLessThan(String key, dynamic value);

  Traversal hasKeyBetween(String key, dynamic min, dynamic max);

  Traversal hasKeyIn(String key, List<dynamic> values);

  Traversal hasLabel(List<String> labels);

  Traversal hasNot(String key);

  // Logical operators
  Traversal or(List<Traversal Function(Traversal)> conditions);

  Traversal not(Traversal Function(Traversal) condition);

  Traversal hasNotLabel(List<String> labels);

  Traversal hasKeyNotIn(String key, List<dynamic> values);

  // List search
  Traversal listContains(String key, dynamic value);

  Traversal listContainsExact(String key, dynamic value);

  Traversal listLength(String key, int length);

  // Adjacent vertex traversal
  Traversal out([List<String>? labels]);

  Traversal in_([List<String>? labels]);

  Traversal both([List<String>? labels]);

  // Edge traversal
  Traversal outE([List<String>? labels]);

  Traversal inE([List<String>? labels]);

  Traversal bothE([List<String>? labels]);

  // Vertex traversal
  Traversal outV();

  Traversal inV();

  Traversal bothV();

  // Property operations
  Traversal values([List<String>? keys]);

  Traversal valueMap([
    List<String>? keys,
  ]);

  // Aggregation and transformation
  Traversal limit(int limit);

  Traversal skip(int offset);

  Traversal order();

  Traversal group();

  Traversal byId([SortOrder? order]);

  // Sort order is undefined when properties have the same value
  // Do not compare by ID arbitrarily
  Traversal byKey(String key, [SortOrder? order]);

  Traversal dedup();

  // Mutating steps (intended for terminal, minimal specification)
  // Note: Currently only supported in transactional traversal (txn.traversal()).
  Traversal mergeV({
    required Set<String> labels,
    required Map<String, dynamic> match,
    Map<String, dynamic>? onCreate,
    Map<String, dynamic>? onMatch,
  });

  // Reserved (future implementation): edge merge
  Traversal mergeE({
    required Set<String> labels,
    required Map<String, dynamic> match,
    required String fromAlias,
    required String toAlias,
    Map<String, dynamic>? onCreate,
    Map<String, dynamic>? onMatch,
  });

  // Custom processing
  // TODO(szktty): Replace this method with stream-based processing.
  Traversal map(dynamic Function(dynamic) transformer);

  Traversal filter(bool Function(dynamic) filterFunction);

  Traversal path();

  // Aggregation steps
  Traversal count();

  // Path manipulation steps
  Traversal as(String label);

  Traversal select(List<String> labels);

  // Loop steps
  Traversal repeat(Traversal traversal);

  Traversal until(bool Function(dynamic) predicate);

  Traversal times(int times);

  Stream<dynamic> get stream;

  // Available only when path is enabled
  Stream<TraversalPath> get pathStream;

  Future<List<dynamic>> toList();

  Future<Set<dynamic>> toSet();

  Future<List<TraversalPath>> toPathList();

  // TODO(szktty): Migrate to buildQuerySet and remove this method.
  SqlQuery buildQuery();

  SqlQuerySet buildQuerySet();
}
