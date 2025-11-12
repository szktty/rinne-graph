import 'package:rinne_graph/src/database/helper.dart';
import 'package:rinne_graph/src/database/schema.dart';
import 'package:rinne_graph/src/helpers/helpers.dart';

import 'package:rinne_graph/src/model/null_value.dart';

abstract class Element {
  int? get id;

  Set<String> get labels;

  bool hasAnyLabel(List<String> labels);

  // unmodifiable map
  // Use setProperty for updates
  Map<String, dynamic> get properties;

  Set<String> get propertyKeys;

  bool hasProperty(String key);

  DatabaseValueType getPropertyType(String key);

  // Returns null if not exists, returns NullValue if it's set
  Object? getProperty(String key);

  // NullValue is assigned if value is null
  // Error if unsupported type is set
  void setProperty(String key, Object? value);

  void removeProperty(String key);

  DateTime? get createdAt;

  DateTime? get updatedAt;

  Map<String, dynamic> toMap();
}

abstract class ElementImpl implements Element {
  ElementImpl({
    this.id,
    Set<String>? labels,
    Map<String, dynamic>? properties,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : labels = labels ?? {},
        _properties = properties ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  @override
  final int? id;

  @override
  final Set<String> labels;

  @override
  Map<String, dynamic> get properties => Map.unmodifiable(_properties);

  @override
  Set<String> get propertyKeys => _properties.keys.toSet();

  final Map<String, dynamic> _properties;

  @override
  final DateTime? createdAt;

  @override
  final DateTime? updatedAt;

  @override
  bool hasAnyLabel(List<String> labels) {
    return this.labels.containsAny(labels, ifUnspecified: true);
  }

  @override
  bool hasProperty(String key) {
    return _properties.containsKey(key);
  }

  @override
  DatabaseValueType getPropertyType(String key) {
    return DatabaseValueHelper.getDatabaseValueType(_properties[key]);
  }

  @override
  Object? getProperty(String key) {
    return _properties[key];
  }

  @override
  void setProperty(String key, Object? value) {
    if (value == null) {
      _properties[key] = NullValue();
    } else if (value is bool ||
        value is int ||
        value is double ||
        value is String ||
        value is DateTime ||
        value is List ||
        value is NullValue) {
      _properties[key] = value;
    } else {
      throw ArgumentError('Unsupported type: ${value.runtimeType}');
    }
  }

  @override
  void removeProperty(String key) {
    _properties.remove(key);
  }
}

extension ElementExtension on Element {
  Set<String> commonLabels(Iterable<String> otherLabels) {
    return labels.intersection(otherLabels.toSet());
  }
}
