import 'package:rinne_graph/src/traversal/traversal_internal.dart';

import 'graph_model.dart';
import 'traversal_model_steps.dart';

// Need to return this for method chaining
// ignore_for_file: avoid_returning_this

final class TraversalSourceModel implements TraversalSource {
  TraversalSourceModel({
    required this.graph,
  });

  final GraphModel graph;

  @override
  TraversalModel V([List<int>? ids]) {
    return TraversalModel(graph).V(ids) as TraversalModel;
  }

  @override
  TraversalModel E([List<int>? ids]) {
    return TraversalModel(graph).E(ids) as TraversalModel;
  }
}

class TraversalModel extends TraversalBase {
  TraversalModel(
    this.graph, {
    List<TraversalStep>? steps,
  }) : super(steps: steps ?? []);

  final GraphModel graph;

  @override
  Traversal V([List<int>? ids]) {
    return withNewStep(VertexStep(ids ?? []));
  }

  @override
  Traversal E([List<int>? ids]) {
    return withNewStep(EdgeStep(ids ?? []));
  }

  @override
  Traversal id() {
    return withNewStep(IdStep());
  }

  @override
  Traversal both([List<String>? labels]) {
    return withNewStep(BothStep(labels?.toList() ?? []));
  }

  @override
  Traversal byId([SortOrder? order]) {
    return withNewStep(ByIdStep(order ??= SortOrder.asc));
  }

  @override
  Traversal byKey(String key, [SortOrder? order]) {
    return withNewStep(ByKeyStep(key, order ??= SortOrder.asc));
  }

  @override
  Traversal dedup() {
    return withNewStep(DedupStep());
  }

  @override
  Traversal hasId([List<int>? ids]) {
    return withNewStep(HasIdStep(ids ?? []));
  }

  @override
  Traversal hasKey(String key, dynamic value) {
    return withNewStep(HasKeyStep(key, value));
  }

  @override
  Traversal hasKeyContains(String key, String value) {
    return withNewStep(HasKeyContainsStep(key, value));
  }

  @override
  Traversal hasKeyMatches(String key, String pattern) {
    return withNewStep(HasKeyMatchesStep(key, pattern));
  }

  @override
  Traversal hasKeyStartsWith(String key, String value) {
    throw UnimplementedError('hasKeyStartsWith not implemented in test model');
  }

  @override
  Traversal hasKeyEndsWith(String key, String value) {
    throw UnimplementedError('hasKeyEndsWith not implemented in test model');
  }

  @override
  Traversal hasKeyGreaterThan(String key, dynamic value) {
    throw UnimplementedError('hasKeyGreaterThan not implemented in test model');
  }

  @override
  Traversal hasKeyLessThan(String key, dynamic value) {
    throw UnimplementedError('hasKeyLessThan not implemented in test model');
  }

  @override
  Traversal hasKeyBetween(String key, dynamic min, dynamic max) {
    throw UnimplementedError('hasKeyBetween not implemented in test model');
  }

  @override
  Traversal hasKeyIn(String key, List<dynamic> values) {
    throw UnimplementedError('hasKeyIn not implemented in test model');
  }

  @override
  Traversal hasNotLabel(List<String> labels) {
    throw UnimplementedError('hasNotLabel not implemented in test model');
  }

  @override
  Traversal hasKeyNotIn(String key, List<dynamic> values) {
    throw UnimplementedError('hasKeyNotIn not implemented in test model');
  }

  @override
  Traversal listContains(String key, dynamic value) {
    return withNewStep(ListContainsStep(key, value));
  }

  @override
  Traversal listContainsExact(String key, dynamic value) {
    return withNewStep(ListContainsExactStep(key, value));
  }

  @override
  Traversal listLength(String key, int length) {
    return withNewStep(ListLengthStep(key, length));
  }

  @override
  Traversal skip(int offset) {
    throw UnimplementedError('skip not implemented in test model');
  }

  @override
  Traversal or(List<Traversal Function(Traversal)> conditions) {
    throw UnimplementedError('OR conditions not yet implemented');
  }

  @override
  Traversal not(Traversal Function(Traversal) condition) {
    throw UnimplementedError('NOT conditions not yet implemented');
  }

  @override
  Traversal hasLabel(List<String> labels) {
    return withNewStep(HasLabelStep(labels.toList()));
  }

  @override
  Traversal hasNot(String key) {
    return withNewStep(HasNotStep(key));
  }

  @override
  Traversal in_([List<String>? labels]) {
    return withNewStep(InStep(labels?.toList() ?? []));
  }

  @override
  Traversal limit(int limit) {
    return withNewStep(LimitStep(limit));
  }

  @override
  Traversal order() {
    return withNewStep(OrderStep());
  }

  @override
  Traversal out([List<String>? labels]) {
    return withNewStep(OutStep(labels?.toList() ?? []));
  }

  @override
  Traversal outE([List<String>? labels]) {
    return withNewStep(OutEStep(labels?.toList() ?? []));
  }

  @override
  Traversal inE([List<String>? labels]) {
    return withNewStep(InEStep(labels?.toList() ?? []));
  }

  @override
  Traversal bothE([List<String>? labels]) {
    return withNewStep(BothEStep(labels?.toList() ?? []));
  }

  @override
  Traversal outV() {
    return withNewStep(OutVStep());
  }

  @override
  Traversal inV() {
    return withNewStep(InVStep());
  }

  @override
  Traversal bothV() {
    return withNewStep(BothVStep());
  }

  @override
  Traversal valueMap([List<String>? keys]) {
    return withNewStep(ValueMapStep(keys ?? []));
  }

  @override
  Traversal values([List<String>? keys]) {
    return withNewStep(ValuesStep(keys ?? []));
  }

  @override
  Traversal group() {
    return withNewStep(GroupStep());
  }

  @override
  Traversal filter(bool Function(dynamic p1) filterFunction) {
    throw UnimplementedError();
  }

  @override
  Traversal map(dynamic Function(dynamic p1) transformer) {
    return withNewStep(MapStep(transformer));
  }

  @override
  Traversal path() {
    return withNewStep(PathStep());
  }

  @override
  Traversal count() {
    return withNewStep(CountStep());
  }

  @override
  Traversal as(String label) {
    return withNewStep(AsStep(label));
  }

  @override
  Traversal select(List<String> labels) {
    return withNewStep(SelectStep(labels));
  }

  @override
  Traversal repeat(Traversal traversal) {
    return withNewStep(RepeatStep(traversal as TraversalBase));
  }

  @override
  Traversal until(bool Function(dynamic) predicate) {
    return withNewStep(UntilStep(predicate));
  }

  @override
  Traversal times(int times) {
    return withNewStep(TimesStep(times));
  }

  @override
  Traversal mergeV({
    required Set<String> labels,
    required Map<String, dynamic> match,
    Map<String, dynamic>? onCreate,
    Map<String, dynamic>? onMatch,
  }) {
    throw UnsupportedError('mergeV not supported in TraversalModel (test)');
  }

  @override
  Traversal mergeE({
    required Set<String> labels,
    required Map<String, dynamic> match,
    required String fromAlias,
    required String toAlias,
    Map<String, dynamic>? onCreate,
    Map<String, dynamic>? onMatch,
  }) {
    throw UnsupportedError('mergeE not supported in TraversalModel (test)');
  }

  @override
  Stream<dynamic> get stream {
    final targets = _applySteps();
    return Stream.fromIterable(targets.pathHeads<dynamic>());
  }

  @override
  Stream<TraversalPath> get pathStream {
    final targets = _applySteps();
    return Stream.fromIterable(targets);
  }

  @override
  SqlQuery buildQuery() {
    throw UnsupportedError('$runtimeType does not support buildQuery');
  }

  Iterable<TraversalPath> _applySteps() {
    Iterable<TraversalPath> targets = [];
    for (final step in steps) {
      targets = (step as TraversalStepModel).apply(this, targets);
    }
    return targets;
  }
}
