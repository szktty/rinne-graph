/// Graph event system
///
/// Provides an event system for monitoring graph data changes
/// (especially label additions, updates, and deletions).
library;

import 'package:meta/meta.dart';

/// Base class for graph events
@immutable
abstract class GraphEvent {
  GraphEvent({
    required this.transactionId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  final DateTime timestamp;
  final String transactionId;
}

/// Label event types
enum LabelEventType {
  /// Label was newly added
  added,

  /// Label was removed
  removed,

  /// Entity with label was updated
  updated,
}

/// Base class for label-related events
@immutable
abstract class LabelEvent extends GraphEvent {
  LabelEvent({
    required this.label,
    required this.eventType,
    required super.transactionId,
    super.timestamp,
  });
  final String label;
  final LabelEventType eventType;
}

/// Vertex label event
@immutable
class VertexLabelEvent extends LabelEvent {
  // All current labels

  VertexLabelEvent({
    required this.vertexId,
    required this.allLabels,
    required super.label,
    required super.eventType,
    required super.transactionId,
    super.timestamp,
  });
  final int vertexId;
  final Set<String> allLabels;

  @override
  String toString() {
    return 'VertexLabelEvent(vertexId: $vertexId, label: $label, '
        'eventType: $eventType, allLabels: $allLabels, '
        'transactionId: $transactionId, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VertexLabelEvent &&
        other.vertexId == vertexId &&
        other.label == label &&
        other.eventType == eventType &&
        other.transactionId == transactionId;
  }

  @override
  int get hashCode {
    return Object.hash(vertexId, label, eventType, transactionId);
  }
}

/// Edge label event
@immutable
class EdgeLabelEvent extends LabelEvent {
  EdgeLabelEvent({
    required this.edgeId,
    required this.allLabels,
    required super.label,
    required super.eventType,
    required super.transactionId,
    super.timestamp,
  });
  final int edgeId;
  final Set<String> allLabels;

  @override
  String toString() {
    return 'EdgeLabelEvent(edgeId: $edgeId, label: $label, '
        'eventType: $eventType, allLabels: $allLabels, '
        'transactionId: $transactionId, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EdgeLabelEvent &&
        other.edgeId == edgeId &&
        other.label == label &&
        other.eventType == eventType &&
        other.transactionId == transactionId;
  }

  @override
  int get hashCode {
    return Object.hash(edgeId, label, eventType, transactionId);
  }
}
