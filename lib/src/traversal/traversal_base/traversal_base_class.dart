// Base class that can be used generically
// Check the order of steps

import 'package:rinne_graph/src/traversal/aggregation.dart';
import 'package:rinne_graph/src/traversal/sql_traversal/sql_query.dart';
import 'package:rinne_graph/src/traversal/traversal_intf.dart';

import 'package:rinne_graph/src/traversal/traversal_path.dart';

enum ElementType {
  any,
  vertex,
  edge,
  both,
  property,
  value;

  bool get isAnyElement => this == vertex || this == edge || this == both;

  bool get isVertex => this == vertex;

  bool get isVertexOrBoth => this == vertex || this == both;

  bool get isVertexOrEdge => this == vertex || this == edge;

  bool get isEdge => this == edge;

  bool get isEdgeOrBoth => this == edge || this == both;

  bool allows(ElementType type) {
    if (this == ElementType.vertex && type.isVertexOrBoth) {
      return true;
    } else if (this == ElementType.edge && type.isEdgeOrBoth) {
      return true;
    } else if (this == ElementType.both && type.isAnyElement) {
      return true;
    } else {
      return this == type;
    }
  }
}

abstract class TraversalStep {
  String get name;

  ElementType get requiredInputType;

  ElementType get inputType;

  set inputType(ElementType value);

  ElementType get outputType;

  bool get allowsStartStep;

  List<TraversalStep> get modulatorSteps;

  void addModulatorStep(TraversalStep step);
}

// modulation
// by, from, to

abstract class TraversalBase implements Traversal {
  TraversalBase({required this.steps});

  final List<TraversalStep> steps;

  TraversalStep? get firstStep => steps.firstOrNull;

  TraversalStep? get lastStep => steps.lastOrNull;

  final List<List<AggregationDescriptor>> _aggregationDescriptorsList = [];

  bool traversalPathEnabled = false;

  void beginAggregation() {
    _aggregationDescriptorsList.add([]);
  }

  void endAggregation() {
    _aggregationDescriptorsList.removeLast();
  }

  void addAggregationDescriptor(AggregationDescriptor descriptor) {
    _aggregationDescriptorsList.last.add(descriptor);
  }

  List<AggregationDescriptor> get lastAggregationDescriptors {
    return _aggregationDescriptorsList.last;
  }

  List<AggregationDescriptor> collectAggregationDescriptors(
    List<TraversalStep> steps,
    void Function(TraversalStep) collector,
  ) {
    beginAggregation();
    for (final step in steps) {
      collector(step);
    }
    final descriptors = lastAggregationDescriptors;
    endAggregation();
    return descriptors;
  }

  final ModulationSwitcher modulationSwitcher = ModulationSwitcher();

  /*
  List<String> inByModulationSteps = [];
  Map<String, TraversalStep> byModulationSteps = {};

  static const List<String> byModulationStepNames = [
    'order',
    'group',
    'dedup',
  ];

  // TODO(szktty): Consider including 'limit' in this list.
  static const List<String> byStepNames = [
    'byId',
    'byKey',
  ];

  bool inByModulationStep(String stepName) {
    return inByModulationSteps.contains(stepName);
  }

  String get lastByModulationStepName {
    return inByModulationSteps.last;
  }
   */

  Traversal withNewStep(TraversalStep newStep) {
    addStep(newStep);
    return this;
  }

  void addStep(TraversalStep step) {
    if (!step.allowsStartStep) {
      if (steps.isEmpty) {
        throw Exception('Step ${step.name} must be a start step');
      } else {
        final lastOutputType = lastStep!.outputType;
        if (step.requiredInputType == ElementType.any) {
          step.inputType = lastOutputType;
        } else if (lastOutputType.isVertexOrEdge &&
            step.requiredInputType == ElementType.both) {
          step.inputType = lastOutputType;
        } else if (!step.inputType.allows(lastStep!.outputType)) {
          throw Exception(
              'Invalid input type ${lastStep!.outputType} for ${step.inputType} of step ${step.name}');
        }
      }
    }

    if (modulationSwitcher.hasModulation(step.name)) {
      if (modulationSwitcher.isModulatingStep(step.name)) {
        throw StateError('Step ${step.name} is already building');
      } else {
        modulationSwitcher.beginModulation(step);
        steps.add(step);
      }
    } else if (modulationSwitcher.inModulatingSteps) {
      final (modulation, modulatingStep) =
          modulationSwitcher.currentModulatingStep;
      if (modulation.modulatorStepNames.contains(step.name)) {
        modulatingStep.addModulatorStep(step);
      } else {
        modulationSwitcher.endModulation();
        steps.add(step);
      }
    } else if (modulationSwitcher.hasModulation(step.name)) {
      final modulation = modulationSwitcher.getModulation(step.name);
      throw StateError(
          'Step ${step.name} must be in ${modulation.modulatedStepNames.join(', ')} steps');
    } else {
      steps.add(step);
    }

    // path
    if (step.name == 'path') {
      traversalPathEnabled = true;
    }
  }

  @override
  Future<List<dynamic>> toList() async {
    return stream.toList();
  }

  @override
  Future<Set<dynamic>> toSet() async {
    return stream.toSet();
  }

  @override
  Future<List<TraversalPath>> toPathList() async {
    return pathStream.toList();
  }

  @override
  SqlQuerySet buildQuerySet() {
    throw UnimplementedError('buildQuerySet is not implemented');
  }
}

abstract class TraversalStepBase implements TraversalStep {
  ElementType? _inputType;

  @override
  ElementType get inputType => _inputType ?? requiredInputType;

  @override
  set inputType(ElementType value) {
    _inputType = value;
  }

  @override
  List<TraversalStep> modulatorSteps = [];

  @override
  void addModulatorStep(TraversalStep step) {
    modulatorSteps.add(step);
  }
}

abstract class TraversalStepVertexBase extends TraversalStepBase {
  TraversalStepVertexBase(this.ids);

  final List<int> ids;

  @override
  String get name => 'V';

  @override
  ElementType get requiredInputType => ElementType.vertex;

  @override
  ElementType get inputType => ElementType.vertex;

  @override
  ElementType get outputType => ElementType.vertex;

  @override
  bool get allowsStartStep => true;
}

abstract class TraversalStepEdgeBase extends TraversalStepBase {
  TraversalStepEdgeBase(this.ids);

  final List<int> ids;

  @override
  String get name => 'E';

  @override
  ElementType get requiredInputType => ElementType.edge;

  @override
  ElementType get inputType => ElementType.edge;

  @override
  ElementType get outputType => ElementType.edge;

  @override
  bool get allowsStartStep => true;
}

abstract class TraversalStepIdBase extends TraversalStepBase {
  @override
  String get name => 'id';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => ElementType.value;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasKeyBase extends TraversalStepBase {
  @override
  String get name => 'has';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasKeyContainsBase extends TraversalStepBase {
  @override
  String get name => 'hasContains';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasAnyKeyContainsBase extends TraversalStepBase {
  @override
  String get name => 'hasAnyKeyContains';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasKeyStartsWithBase extends TraversalStepBase {
  @override
  String get name => 'hasStartsWith';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasKeyEndsWithBase extends TraversalStepBase {
  @override
  String get name => 'hasEndsWith';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasKeyMatchesBase extends TraversalStepBase {
  @override
  String get name => 'hasMatches';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasKeyGreaterThanBase extends TraversalStepBase {
  @override
  String get name => 'hasGreaterThan';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasKeyLessThanBase extends TraversalStepBase {
  @override
  String get name => 'hasLessThan';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasKeyBetweenBase extends TraversalStepBase {
  @override
  String get name => 'hasBetween';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasKeyInBase extends TraversalStepBase {
  @override
  String get name => 'hasIn';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasNotLabelBase extends TraversalStepBase {
  @override
  String get name => 'hasNotLabel';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasKeyNotInBase extends TraversalStepBase {
  @override
  String get name => 'hasNotIn';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasIdBase extends TraversalStepBase {
  @override
  String get name => 'hasId';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasLabelBase extends TraversalStepBase {
  @override
  String get name => 'hasLabel';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepHasNotBase extends TraversalStepBase {
  @override
  String get name => 'hasNot';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepValuesBase extends TraversalStepBase {
  TraversalStepValuesBase(this.keys);

  final List<String> keys;

  @override
  String get name => 'values';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => ElementType.property;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepValueMapBase extends TraversalStepBase {
  TraversalStepValueMapBase(this.keys);

  final List<String> keys;

  @override
  String get name => 'valueMap';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => ElementType.value;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepLimitBase extends TraversalStepBase {
  TraversalStepLimitBase(this.limit) {
    if (limit < 0) {
      throw Exception('Limit must be a non-negative number');
    }
  }

  int limit;

  @override
  String get name => 'limit';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepSkipBase extends TraversalStepBase {
  TraversalStepSkipBase(this.offset) {
    if (offset < 0) {
      throw Exception('Offset must be a non-negative number');
    }
  }

  int offset;

  @override
  String get name => 'skip';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepOrderBase extends TraversalStepBase {
  @override
  String get name => 'order';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepByIdBase extends TraversalStepBase {
  TraversalStepByIdBase(this.order);

  final SortOrder order;

  @override
  String get name => 'byId';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;

  List<String> get requiredPreviousSteps => ['order'];
}

abstract class TraversalStepByKeyBase extends TraversalStepBase {
  TraversalStepByKeyBase(this.key, this.order);

  final String key;
  final SortOrder order;

  @override
  String get name => 'byKey';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;

  List<String> get requiredPreviousSteps => ['order'];
}

abstract class TraversalStepGroupBase extends TraversalStepBase {
  @override
  String get name => 'group';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepGroupByBase extends TraversalStepBase {
  TraversalStepGroupByBase([this.key]);

  final String? key;

  @override
  String get name => 'groupBy';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;

  List<String> get requiredPreviousSteps => ['group'];
}

abstract class TraversalStepGroupByKeyBase extends TraversalStepBase {
  @override
  String get name => 'groupByKey';

  @override
  ElementType get requiredInputType => ElementType.both;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;

  List<String> get requiredPreviousSteps => ['group'];
}

abstract class TraversalStepDedupBase extends TraversalStepBase {
  @override
  String get name => 'dedup';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => inputType;

  @override
  bool get allowsStartStep => false;
}

abstract class TraversalStepMapBase extends TraversalStepBase {
  TraversalStepMapBase(this.transformer);

  final dynamic Function(dynamic) transformer;

  @override
  String get name => 'map';

  @override
  ElementType get requiredInputType => ElementType.any;

  @override
  ElementType get outputType => ElementType.value;

  @override
  bool get allowsStartStep => false;
}

abstract class Modulation {
  List<String> get modulatedStepNames;

  List<String> get modulatorStepNames;
}

final class ByModulation implements Modulation {
  @override
  List<String> get modulatedStepNames => ['order', 'group', 'dedup', 'path'];

  @override
  List<String> get modulatorStepNames => ['byId', 'byKey'];
}

final class ModulationSwitcher {
  final List<Modulation> modulations = [ByModulation()];

  List<(Modulation, TraversalStep)> modulatingSteps = [];
  Map<String, TraversalStep> modulatedSteps = {};

  (Modulation, TraversalStep) get currentModulatingStep {
    return modulatingSteps.last;
  }

  bool get inModulatingSteps {
    return modulatingSteps.isNotEmpty;
  }

  bool hasModulation(String name) {
    return modulations.any((m) => m.modulatedStepNames.contains(name));
  }

  Modulation getModulation(String name) {
    return modulations.firstWhere(
      (m) => m.modulatedStepNames.contains(name),
    );
  }

  void beginModulation(TraversalStep step) {
    final modulation = modulations.firstWhere(
      (m) => m.modulatedStepNames.contains(step.name),
    );
    modulatingSteps.add((modulation, step));
  }

  void endModulation() {
    modulatingSteps.removeLast();
  }

  bool isModulatingStep(String name) {
    return modulatingSteps.any((s) => s.$1.modulatedStepNames.contains(name));
  }
}
