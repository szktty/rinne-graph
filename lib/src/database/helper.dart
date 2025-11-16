import 'dart:convert';
import 'dart:typed_data';

import 'package:rinne_graph/src/database/schema.dart';
import 'package:rinne_graph/src/model/model.dart';

abstract class DatabaseValueHelper {
  static DatabaseValueType getDatabaseValueType(dynamic value) {
    if (value == null || value is NullValue) {
      return DatabaseValueType.null_;
    } else if (value is String) {
      return DatabaseValueType.string;
    } else if (value is int || value is ElementId) {
      return DatabaseValueType.integer;
    } else if (value is double) {
      return DatabaseValueType.float;
    } else if (value is bool) {
      return DatabaseValueType.boolean;
    } else if (value is DateTime) {
      return DatabaseValueType.datetime;
    } else if (value is List) {
      return DatabaseValueType.list;
    } else {
      throw ArgumentError('Unsupported property type: ${value.runtimeType}');
    }
  }

  static dynamic fromDatabaseValue(DatabaseValueType type, dynamic value) {
    switch (type) {
      case DatabaseValueType.null_:
        return NullValue();
      case DatabaseValueType.string:
        final strValue = value as String;
        // Consistently remove prefix from all strings
        if (strValue.startsWith('str:')) {
          return strValue.substring(4);
        }
        return strValue;
      case DatabaseValueType.integer:
        return value as int;
      case DatabaseValueType.float:
        if (value is int) {
          return value.toDouble();
        } else {
          return value as double;
        }
      case DatabaseValueType.boolean:
        return (value as int) == 1;
      case DatabaseValueType.datetime:
        return DateTime.parse(value as String);
      case DatabaseValueType.blob:
        return value as Uint8List;
      case DatabaseValueType.list:
        return jsonDecode(value as String) as List<dynamic>;
    }
  }

  static dynamic toDatabaseValue(dynamic value) {
    if (value is NullValue) {
      return null;
    } else if (value is String) {
      // Consistently add prefix to all strings
      // This avoids issues with SQLite type conversion
      return 'str:$value';
    } else if (value is int) {
      return value;
    } else if (value is double) {
      return value;
    } else if (value is bool) {
      return value == true ? 1 : 0;
    } else if (value is DateTime) {
      return value.toUtc().toIso8601String();
    } else if (value is Uint8List) {
      return value;
    } else if (value is List) {
      return jsonEncode(value);
    } else {
      throw ArgumentError('Unsupported property type: ${value.runtimeType}');
    }
  }

  // TODO(szktty): Consider removing this method if not needed.
  // Default behavior: do not automatically compare by ID when values are equal
  static int compareDatabaseValuesOrIds(
    int id1,
    int id2,
    dynamic value1,
    dynamic value2,
  ) {
    // Compare by ID if values are equal
    final result = compareDatabaseValues(value1, value2);
    if (result == 0) {
      return id1.compareTo(id2);
    } else {
      return result;
    }
  }

  // TODO(szktty): Handle the case when the value is an element.
  static int compareDatabaseValues(
    dynamic value1,
    dynamic value2,
  ) {
    // null < boolean < integer, float < string < datetime < blob
    final type1 = getDatabaseValueType(value1);
    final type2 = getDatabaseValueType(value2);
    if (type1.isNumber && type2.isNumber) {
      final n1 = value1 is ElementId ? value1.id : value1 as num;
      final n2 = value2 is ElementId ? value2.id : value2 as num;
      return n1.compareTo(n2);
    } else if (type1 == DatabaseValueType.boolean &&
        type2 == DatabaseValueType.boolean) {
      final b1 = value1 as bool;
      final b2 = value2 as bool;
      if (b1 == b2) {
        return 0;
      } else if (b1) {
        return 1;
      } else {
        return -1;
      }
    } else if (type1 == DatabaseValueType.string &&
        type2 == DatabaseValueType.string) {
      // sqflite default is case sensitive
      final s1 = value1 as String;
      final s2 = value2 as String;
      //print('compare string: $s1, $s2');
      return s1.compareTo(s2);
    } else if (type1 == DatabaseValueType.datetime &&
        type2 == DatabaseValueType.datetime) {
      final d1 = (value1 as DateTime).toUtc();
      final d2 = (value2 as DateTime).toUtc();
      //print('compare datetime: $d1, $d2');
      return d1.compareTo(d2);
    } else if (type1 == DatabaseValueType.blob &&
        type2 == DatabaseValueType.blob) {
      final b1 = value1 as Uint8List;
      final b2 = value2 as Uint8List;
      return b1.length.compareTo(b2.length);
    } else if (type1 == DatabaseValueType.list &&
        type2 == DatabaseValueType.list) {
      final l1 = value1 as List<dynamic>;
      final l2 = value2 as List<dynamic>;
      return l1.length.compareTo(l2.length);
    } else if (type1 != type2) {
      return type1.precedence.compareTo(type2.precedence);
    } else {
      return type1.precedence.compareTo(type2.precedence);
    }
  }
}
