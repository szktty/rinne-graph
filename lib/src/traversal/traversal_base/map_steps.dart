import 'package:rinne_graph/src/traversal/traversal_base/traversal_base_class.dart';

abstract class TraversalStepPathBase extends TraversalStepBase {
  @override
  String get name => 'path';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => ElementType.any;

  @override
  bool get allowsStartStep => false;
}
