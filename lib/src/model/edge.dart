import 'package:json_annotation/json_annotation.dart';
import 'package:rinne_graph/src/model/element.dart';

part 'edge.g.dart';

abstract class Edge implements Element {
  factory Edge({
    required int fromVertexId,
    required int toVertexId,
    int? id,
    Set<String>? labels,
    Map<String, dynamic>? properties,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EdgeImpl(
      id: id,
      fromVertexId: fromVertexId,
      toVertexId: toVertexId,
      labels: labels ?? {},
      properties: properties ?? {},
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Edge.fromMap(Map<String, dynamic> map) {
    return EdgeImpl.fromMap(map);
  }

  factory Edge.fromJson(Map<String, dynamic> json) {
    return EdgeImpl.fromJson(json);
  }

  Map<String, dynamic> toJson();

  int get fromVertexId;

  int get toVertexId;

  Edge copyWith({
    int? id,
    int? fromVertexId,
    int? toVertexId,
    Set<String>? labels,
    Map<String, dynamic>? properties,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  /// vertexId --\[this\]->
  bool isOutgoingFrom(int vertexId);

  /// --\[this\]-> vertexId
  bool isIncomingTo(int vertexId);

  /// isOutgoingFrom(vertexId) || isIncomingTo(vertexId)
  bool isConnectedTo(int vertexId);
}

@JsonSerializable()
final class EdgeImpl extends ElementImpl implements Edge {
  EdgeImpl({
    required this.fromVertexId,
    required this.toVertexId,
    required Set<String> super.labels,
    super.id,
    super.properties,
    super.createdAt,
    super.updatedAt,
  });

  factory EdgeImpl.fromMap(Map<String, dynamic> map) {
    return EdgeImpl(
      id: map['id'] as int?,
      fromVertexId: map['fromVertexId'] as int,
      toVertexId: map['toVertexId'] as int,
      labels: Set.from(map['labels'] as List<String>),
      properties: Map.from(map['properties'] as Map<String, dynamic>),
    );
  }

  factory EdgeImpl.fromJson(Map<String, dynamic> json) =>
      _$EdgeImplFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$EdgeImplToJson(this);

  @override
  final int fromVertexId;

  @override
  final int toVertexId;

  @override
  Edge copyWith({
    int? id,
    int? fromVertexId,
    int? toVertexId,
    Set<String>? labels,
    Map<String, dynamic>? properties,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EdgeImpl(
      id: id ?? this.id,
      fromVertexId: fromVertexId ?? this.fromVertexId,
      toVertexId: toVertexId ?? this.toVertexId,
      labels: labels ?? Set.from(this.labels),
      properties: properties ?? Map.from(this.properties),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool isOutgoingFrom(int vertexId) {
    return fromVertexId == vertexId;
  }

  @override
  bool isIncomingTo(int vertexId) {
    return toVertexId == vertexId;
  }

  @override
  bool isConnectedTo(int vertexId) {
    return fromVertexId == vertexId || toVertexId == vertexId;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromVertexId': fromVertexId,
      'toVertexId': toVertexId,
      'labels': labels.toList(),
      'properties': properties,
    };
  }
}
