import 'package:rinne_graph/src/traversal/traversal_base/traversal_base_class.dart';

abstract class TraversalStepCountBase extends TraversalStepBase {
  @override
  String get name => 'count';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => ElementType.value;

  @override
  bool get allowsStartStep => false;
}
