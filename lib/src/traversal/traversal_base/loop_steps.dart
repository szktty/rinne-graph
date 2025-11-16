import 'package:rinne_graph/src/traversal/traversal_base/traversal_base_class.dart';

abstract class TraversalStepRepeatBase extends TraversalStepBase {
  TraversalStepRepeatBase(this.traversal);

  final TraversalBase traversal;

  @override
  String get name => 'repeat';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepUntilBase extends TraversalStepBase {
  TraversalStepUntilBase(this.predicate);

  final bool Function(dynamic) predicate;

  @override
  String get name => 'until';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepTimesBase extends TraversalStepBase {
  TraversalStepTimesBase(this.times);

  final int times;

  @override
  String get name => 'times';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}
