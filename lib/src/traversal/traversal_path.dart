import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:rinne_graph/rinne_graph.dart';

abstract class TraversalPathStep {
  dynamic get object;

  Set<String> get labels;
}

final class TraversalPathStepImpl extends Equatable
    implements TraversalPathStep {
  const TraversalPathStepImpl(this.object, this.labels);

  @override
  final dynamic object;
  @override
  final Set<String> labels;

  TraversalPathStepImpl copyWith({
    dynamic object,
    Set<String>? labels,
  }) {
    return TraversalPathStepImpl(
        object ?? this.object, labels ?? Set.from(this.labels));
  }

  @override
  String toString() {
    if (object is String) {
      return '"$object"';
    } else if (object is Vertex) {
      final vertex = object as Vertex;
      return 'v[${vertex.id}]';
    } else if (object is Edge) {
      final edge = object as Edge;
      return 'e[${edge.fromVertexId}-${labels.join(',')}-${edge.toVertexId}]';
    } else {
      return object.toString();
    }
  }

  @override
  List<Object?> get props => [object, labels];
}

abstract class TraversalPath {
  int get length;

  bool get isEmpty;

  bool get isNotEmpty;

  List<TraversalPathStep> get steps;

  List<dynamic> get objects;

  List<Set<String>> get labels;

  TraversalPathStep? get head;

  TraversalPath extend(dynamic object, [Set<String>? labels]);

  bool hasLabel(String label);

  TraversalPathStep? getAt(int index);

  TraversalPathStep? getByLabel(String label);

  TraversalPath mapSteps(
      TraversalPathStep Function(TraversalPathStep) transform);
}

final class TraversalPathImpl extends Equatable implements TraversalPath {
  TraversalPathImpl([List<TraversalPathStep>? steps]) {
    if (steps != null) {
      _steps.addAll(steps);
    }
  }

  factory TraversalPathImpl.fromStep(TraversalPathStep step) {
    return TraversalPathImpl([step]);
  }

  factory TraversalPathImpl.fromObject(dynamic object, [Set<String>? labels]) {
    return TraversalPathImpl([TraversalPathStepImpl(object, labels ?? {})]);
  }

  final List<TraversalPathStep> _steps = [];

  @override
  int get length => _steps.length;

  @override
  bool get isEmpty => _steps.isEmpty;

  @override
  bool get isNotEmpty => _steps.isNotEmpty;

  @override
  List<TraversalPathStep> get steps => List.of(_steps);

  @override
  List<dynamic> get objects => _steps.nonNulls.map((e) => e.object).toList();

  @override
  List<Set<String>> get labels => _steps.map((e) => e.labels).toList();

  @override
  TraversalPathStep? get head => _steps.lastOrNull;

  dynamic operator [](int index) {
    return _steps[index].object;
  }

  TraversalPath copyWith({
    List<TraversalPathStep>? steps,
  }) {
    return TraversalPathImpl(steps ?? List.from(this.steps));
  }

  @override
  TraversalPath extend(dynamic object, [Set<String>? labels]) {
    return copyWith(
        steps: [..._steps, TraversalPathStepImpl(object, labels ?? {})]);
  }

  @override
  bool hasLabel(String label) {
    return _steps.any((e) => e.labels.contains(label));
  }

  // getAt
  @override
  TraversalPathStep? getAt(int index) {
    return _steps[index];
  }

  @override
  TraversalPathStep? getByLabel(String label) {
    return _steps.where((e) => e.labels.contains(label)).firstOrNull;
  }

  @override
  TraversalPath mapSteps(
      TraversalPathStep Function(TraversalPathStep) transform) {
    return copyWith(steps: _steps.map(transform).toList());
  }

  @override
  String toString() {
    return '[${_steps.map((e) => e.toString()).join(', ')}]';
  }

  @override
  List<Object?> get props => [_steps];
}

extension IterableOfTraversalPathExtension on Iterable<TraversalPath> {
  Iterable<T> pathHeads<T>() {
    return map((e) => e.head?.object as T);
  }

  Iterable<TraversalPath> wherePath<T>(bool Function(T) test) {
    return where((e) => test(e.head?.object as T));
  }

  // Add a step to each path
  // Block receives the current head and returns a new head
  Iterable<TraversalPath> extendPaths<T>(dynamic Function(T) transform) {
    return map((e) => e.extend(transform(e.head?.object as T)));
  }

  // Derive multiple paths from each path
  // Block receives the current head and returns a list of derived paths
  // Derived paths are added to the original path list
  //
  // Example:
  // ```dart
  // final paths = [p1, p2, p3];
  // final derivedPaths = paths.derivePaths((path, head) => [path, path, path]);
  // print(derivedPaths); // [p1, p1, p1, p2, p2, p2, p3, p3, p3]
  // ```
  Iterable<TraversalPath> derivePaths<T>(
      Iterable<TraversalPath> Function(TraversalPath, T) transform) {
    return expand((e) => transform(e, e.head?.object as T));
  }

  List<TraversalPath> sortedPaths(int Function(dynamic, dynamic) compare) {
    return sorted((a, b) => compare(a.head?.object, b.head?.object));
  }
}
