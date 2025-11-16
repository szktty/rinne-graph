import 'package:json_annotation/json_annotation.dart';
import 'package:rinne_graph/src/database/schema.dart';
import 'package:rinne_graph/src/model/element.dart';

part 'vertex.g.dart';

abstract class Vertex implements Element {
  factory Vertex({
    int? id,
    Set<String>? labels,
    Map<String, dynamic>? properties,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VertexImpl(
      id: id,
      labels: labels,
      properties: properties,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Vertex.fromMap(Map<String, dynamic> map) {
    return VertexImpl.fromMap(map);
  }

  factory Vertex.fromJson(Map<String, dynamic> json) {
    return VertexImpl.fromJson(json);
  }

  static const int autoIncrementStartId = DatabaseSchema.autoIncrementStartId;

  Map<String, dynamic> toJson();

  Vertex copyWith({
    int? id,
    Set<String>? labels,
    Map<String, dynamic>? properties,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

@JsonSerializable()
final class VertexImpl extends ElementImpl implements Vertex {
  VertexImpl({
    super.id,
    super.labels,
    super.properties,
    super.createdAt,
    super.updatedAt,
  });

  factory VertexImpl.fromMap(Map<String, dynamic> map) {
    return VertexImpl(
      id: map['id'] as int?,
      labels: Set.from(map['labels'] as List<String>),
      properties: Map.from(map['properties'] as Map<String, dynamic>),
    );
  }

  factory VertexImpl.fromJson(Map<String, dynamic> json) =>
      _$VertexImplFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$VertexImplToJson(this);

  @override
  Vertex copyWith({
    int? id,
    Set<String>? labels,
    Map<String, dynamic>? properties,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VertexImpl(
      id: id ?? this.id,
      labels: labels ?? Set.from(this.labels),
      properties: properties ?? Map.from(this.properties),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'labels': labels.toList(),
      'properties': properties,
    };
  }

  @override
  String toString() {
    return 'Vertex{id: $id, labels: $labels, properties: $properties}';
  }
}
