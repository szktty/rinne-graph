// Use when you want to represent only element ID

import 'package:equatable/equatable.dart';

enum ElementIdType {
  vertex,
  edge,
}

abstract class ElementId {
  int get id;

  ElementIdType get type;
}

final class ElementIdImpl extends Equatable implements ElementId {
  const ElementIdImpl({
    required this.id,
    required this.type,
  });

  factory ElementIdImpl.fromVertexId(int id) {
    return ElementIdImpl(id: id, type: ElementIdType.vertex);
  }

  factory ElementIdImpl.fromEdgeId(int id) {
    return ElementIdImpl(id: id, type: ElementIdType.edge);
  }

  @override
  final int id;

  @override
  final ElementIdType type;

  @override
  String toString() {
    switch (type) {
      case ElementIdType.vertex:
        return 'VertexId{$id}';
      case ElementIdType.edge:
        return 'EdgeId{$id}';
    }
  }

  @override
  List<Object?> get props => [id, type];
}
