import 'package:rinne_graph/src/traversal/traversal_base/traversal_base_class.dart';

abstract class TraversalStepOutBase extends TraversalStepBase {
  @override
  String get name => 'out';

  @override
  ElementType get requiredInputType => ElementType.vertex;

  @override
  ElementType get outputType => ElementType.vertex;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepInBase extends TraversalStepBase {
  @override
  String get name => 'in';

  @override
  ElementType get requiredInputType => ElementType.vertex;

  @override
  ElementType get outputType => ElementType.vertex;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepBothBase extends TraversalStepBase {
  @override
  String get name => 'both';

  @override
  ElementType get requiredInputType => ElementType.vertex;

  @override
  ElementType get outputType => ElementType.vertex;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepOutEBase extends TraversalStepBase {
  @override
  String get name => 'outE';

  @override
  ElementType get requiredInputType => ElementType.vertex;

  @override
  ElementType get outputType => ElementType.edge;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepInEBase extends TraversalStepBase {
  @override
  String get name => 'inE';

  @override
  ElementType get requiredInputType => ElementType.vertex;

  @override
  ElementType get outputType => ElementType.edge;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepBothEBase extends TraversalStepBase {
  @override
  String get name => 'bothE';

  @override
  ElementType get requiredInputType => ElementType.vertex;

  @override
  ElementType get outputType => ElementType.edge;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepOutVBase extends TraversalStepBase {
  @override
  String get name => 'outV';

  @override
  ElementType get requiredInputType => ElementType.edge;

  @override
  ElementType get outputType => ElementType.vertex;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepInVBase extends TraversalStepBase {
  @override
  String get name => 'inV';

  @override
  ElementType get requiredInputType => ElementType.edge;

  @override
  ElementType get outputType => ElementType.vertex;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepBothVBase extends TraversalStepBase {
  @override
  String get name => 'bothV';

  @override
  ElementType get requiredInputType => ElementType.edge;

  @override
  ElementType get outputType => ElementType.vertex;

  @override
  bool get allowsStartStep => false;
}
