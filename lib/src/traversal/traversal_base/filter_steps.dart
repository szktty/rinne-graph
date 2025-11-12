import 'package:rinne_graph/src/traversal/traversal_base/traversal_base_class.dart';

abstract class TraversalStepFilterBase extends TraversalStepBase {
  TraversalStepFilterBase(this.filterFunction);

  final bool Function(dynamic) filterFunction;

  @override
  String get name => 'filter';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepListContainsBase extends TraversalStepBase {
  TraversalStepListContainsBase(this.key, this.value);

  final String key;
  final dynamic value;

  @override
  String get name => 'listContains';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepListLengthBase extends TraversalStepBase {
  TraversalStepListLengthBase(this.key, this.length);

  final String key;
  final int length;

  @override
  String get name => 'listLength';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepListContainsExactBase extends TraversalStepBase {
  TraversalStepListContainsExactBase(this.key, this.value);

  final String key;
  final dynamic value;

  @override
  String get name => 'listContainsExact';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}
