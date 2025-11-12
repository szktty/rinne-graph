import 'package:meta/meta.dart';

// Needed to represent database null
// Putting null in Map means the entry doesn't exist
@immutable
final class NullValue {
  factory NullValue() => _instance;

  const NullValue._();

  static const NullValue _instance = NullValue._();

  @override
  String toString() => 'NullValue';

  @override
  bool operator ==(Object other) => other is NullValue;

  @override
  int get hashCode => 0;

  /// Checks if the given value is null or NullValue
  static bool isNull(dynamic value) => value == null || value is NullValue;

  /// Converts null to NullValue, leaves other values unchanged
  static dynamic toNullValue(dynamic value) => value ?? NullValue();

  /// Converts NullValue to null, leaves other values unchanged
  static dynamic toNull(dynamic value) => value is NullValue ? null : value;
}
