import 'package:rinne_graph/src/database/database.dart';
import 'package:rinne_graph/src/traversal/traversal_base/traversal_base.dart';
import 'package:rinne_graph/src/traversal/traversal_intf.dart';

abstract class SqlTraversalSource extends TraversalSource {}

abstract class SqlTraversal implements TraversalBase {
  String get labelTable;

  /// Column name for element ID in property and label tables
  /// Element is either vertex or edge, whichever is currently selected
  String get elementIdColumn;

  /// Type number of currently selected element
  /// SqlTraversalPathType.vertexId or SqlTraversalPathType.edgeId
  String get elementTypeColumn;

  String get propertyTable;

  String get lastCteName;

  String addParameter(dynamic value);

  List<String> addParameters(Iterable<dynamic> values);

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
  });

  void setLimit(int limit);

  void setOffset(int offset);

  void addPostProcessFilter(bool Function(dynamic) filter);

  void addPostProcessTransformer(dynamic Function(dynamic) transformer);
}

// Use abstract class for consistency with TraversalStep interface, even though it has only one method
// ignore: one_member_abstracts
abstract class SqlTraversalStep implements TraversalStep {
  void apply(SqlTraversal traversal);
}

enum SqlTraversalPathType {
  null_,
  boolean,
  integer,
  float,
  string,
  datetime,
  blob,
  list,
  vertex,
  edge;

  static const int vertexId = 10000;
  static const int edgeId = 10001;

  static SqlTraversalPathType fromId(int id) {
    switch (id) {
      case 0:
        return SqlTraversalPathType.null_;
      case 1:
        return SqlTraversalPathType.boolean;
      case 2:
        return SqlTraversalPathType.integer;
      case 3:
        return SqlTraversalPathType.float;
      case 4:
        return SqlTraversalPathType.string;
      case 5:
        return SqlTraversalPathType.datetime;
      case 6:
        return SqlTraversalPathType.blob;
      case 7:
        return SqlTraversalPathType.list;
      case vertexId:
        return SqlTraversalPathType.vertex;
      case edgeId:
        return SqlTraversalPathType.edge;
      default:
        throw ArgumentError('Unsupported database value type id: $id');
    }
  }

  static SqlTraversalPathType fromDatabaseValueType(DatabaseValueType type) {
    switch (type) {
      case DatabaseValueType.null_:
        return SqlTraversalPathType.null_;
      case DatabaseValueType.boolean:
        return SqlTraversalPathType.boolean;
      case DatabaseValueType.integer:
        return SqlTraversalPathType.integer;
      case DatabaseValueType.float:
        return SqlTraversalPathType.float;
      case DatabaseValueType.string:
        return SqlTraversalPathType.string;
      case DatabaseValueType.datetime:
        return SqlTraversalPathType.datetime;
      case DatabaseValueType.blob:
        return SqlTraversalPathType.blob;
      case DatabaseValueType.list:
        return SqlTraversalPathType.list;
    }
  }

  int get id {
    switch (this) {
      case SqlTraversalPathType.null_:
        return 0;
      case SqlTraversalPathType.boolean:
        return 1;
      case SqlTraversalPathType.integer:
        return 2;
      case SqlTraversalPathType.float:
        return 3;
      case SqlTraversalPathType.string:
        return 4;
      case SqlTraversalPathType.datetime:
        return 5;
      case SqlTraversalPathType.blob:
        return 6;
      case SqlTraversalPathType.list:
        return 7;
      case SqlTraversalPathType.vertex:
        return vertexId;
      case SqlTraversalPathType.edge:
        return edgeId;
    }
  }

  DatabaseValueType get databaseValueType {
    switch (this) {
      case SqlTraversalPathType.null_:
        return DatabaseValueType.null_;
      case SqlTraversalPathType.boolean:
        return DatabaseValueType.boolean;
      case SqlTraversalPathType.integer:
        return DatabaseValueType.integer;
      case SqlTraversalPathType.float:
        return DatabaseValueType.float;
      case SqlTraversalPathType.string:
        return DatabaseValueType.string;
      case SqlTraversalPathType.datetime:
        return DatabaseValueType.datetime;
      case SqlTraversalPathType.blob:
        return DatabaseValueType.blob;
      case SqlTraversalPathType.list:
        return DatabaseValueType.list;
      case SqlTraversalPathType.vertex:
      case SqlTraversalPathType.edge:
        throw ArgumentError('Unsupported database value type: $this');
    }
  }
}
