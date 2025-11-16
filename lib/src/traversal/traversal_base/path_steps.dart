import 'package:rinne_graph/src/traversal/traversal_base/traversal_base_class.dart';

abstract class TraversalStepAsBase extends TraversalStepBase {
  TraversalStepAsBase(this.label);

  final String label;

  @override
  String get name => 'as';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepSelectBase extends TraversalStepBase {
  TraversalStepSelectBase(this.labels);

  final List<String> labels;

  @override
  String get name => 'select';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => ElementType.value;

  @override
  bool get allowsStartStep => false;
}
