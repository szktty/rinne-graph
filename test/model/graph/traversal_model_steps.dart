import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/helpers/collection.dart';
import 'package:rinne_graph/src/model/element_id.dart';
import 'package:rinne_graph/src/model/helpers.dart';
import 'package:rinne_graph/src/traversal/aggregation.dart';
import 'package:rinne_graph/src/traversal/traversal_base/traversal_base.dart';
import 'package:rinne_graph/src/traversal/traversal_path.dart';

import 'traversal_model.dart';

abstract class TraversalStepModel implements TraversalStep {
  // Return targets
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  );
}

class VertexStep extends TraversalStepVertexBase implements TraversalStepModel {
  VertexStep(super.ids);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return (ids.isNotEmpty
            ? t.graph.vertices.where((v) => ids.contains(v.id))
            : t.graph.vertices)
        .map((e) =>
            TraversalPathImpl.fromObject(ElementIdImpl.fromVertexId(e.id!)));
  }
}

class EdgeStep extends TraversalStepEdgeBase implements TraversalStepModel {
  EdgeStep(super.ids);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return (ids.isNotEmpty
            ? t.graph.edges.where((e) => ids.contains(e.id))
            : t.graph.edges)
        .map((e) =>
            TraversalPathImpl.fromObject(ElementIdImpl.fromEdgeId(e.id!)));
  }
}

class IdStep extends TraversalStepIdBase implements TraversalStepModel {
  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    //print('IdStep: path heads: ${targets.pathHeads()}');
    return targets.extendPaths<ElementId>((id) => id.id);
  }
}

class HasIdStep extends TraversalStepHasIdBase implements TraversalStepModel {
  HasIdStep(this.ids);

  final List<int> ids;

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.wherePath<ElementId>((e) => ids.contains(e.id));
  }
}

class HasKeyStep extends TraversalStepHasKeyBase implements TraversalStepModel {
  HasKeyStep(this.key, this.value);

  final String key;
  final dynamic value;

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.wherePath<ElementId>((id) {
      final e = t.graph.getElementByElementId(id)!;
      return e.hasProperty(key) &&
          e.getPropertyType(key) ==
              DatabaseValueHelper.getDatabaseValueType(value) &&
          e.getProperty(key) == value;
    });
  }
}

class HasKeyContainsStep extends TraversalStepHasKeyContainsBase
    implements TraversalStepModel {
  HasKeyContainsStep(this.key, this.value);

  final String key;
  final String value;

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.wherePath<ElementId>((id) {
      final e = t.graph.getElementByElementId(id)!;
      return e.hasProperty(key) &&
          e.getPropertyType(key) == DatabaseValueType.string &&
          e
              .getProperty(key)
              .toString()
              .toLowerCase()
              .contains(value.toLowerCase());
    });
  }
}

class HasKeyMatchesStep extends TraversalStepHasKeyMatchesBase
    implements TraversalStepModel {
  HasKeyMatchesStep(this.key, this.pattern);

  final String key;
  final String pattern;

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.wherePath<ElementId>((id) {
      final e = t.graph.getElementByElementId(id)!;
      if (!e.hasProperty(key) ||
          e.getPropertyType(key) != DatabaseValueType.string) {
        return false;
      }
      final value = e.getProperty(key).toString();
      final regex = RegExp(pattern);
      return regex.hasMatch(value);
    });
  }
}

class HasLabelStep extends TraversalStepHasLabelBase
    implements TraversalStepModel {
  HasLabelStep(this.labels);

  final List<String> labels;

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.wherePath<ElementId>((id) => t.graph
        .getElementByElementId(id)!
        .labels
        .containsAny(labels, ifUnspecified: true));
  }
}

class HasNotStep extends TraversalStepHasNotBase implements TraversalStepModel {
  HasNotStep(this.key);

  final String key;

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.wherePath<ElementId>((id) {
      final e = t.graph.getElementByElementId(id)!;
      // Pass if key doesn't exist or value is NullValue/null
      if (!e.hasProperty(key)) return true;
      final v = e.getProperty(key);
      return NullValue.isNull(v);
    });
  }
}

class OutStep extends TraversalStepOutBase implements TraversalStepModel {
  OutStep(this.labels);

  final List<String> labels;

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, vertex) => t.graph.edges
        .where((e) => e.isOutgoingFrom(vertex.id) && e.hasAnyLabel(labels))
        .map((e) => p.extend(
            ElementIdImpl.fromVertexId(e.toVertexId), e.commonLabels(labels))));
  }
}

class InStep extends TraversalStepInBase implements TraversalStepModel {
  InStep(this.labels);

  final List<String> labels;

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>(
      (p, vertex) => t.graph.edges
          .where((e) => e.isIncomingTo(vertex.id) && e.hasAnyLabel(labels))
          .map(
            (e) => p.extend(ElementIdImpl.fromVertexId(e.fromVertexId),
                e.commonLabels(labels)),
          ),
    );
  }
}

class BothStep extends TraversalStepBothBase implements TraversalStepModel {
  BothStep(this.labels);

  final List<String> labels;

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, vertex) => t.graph.edges
        .where((e) => e.isConnectedTo(vertex.id) && e.hasAnyLabel(labels))
        .map((e) => p.extend(
            ElementIdImpl.fromVertexId(
                e.isOutgoingFrom(vertex.id) ? e.toVertexId : e.fromVertexId),
            e.commonLabels(labels))));
  }
}

class OutEStep extends TraversalStepOutEBase implements TraversalStepModel {
  OutEStep(this.labels);

  final List<String> labels;

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, vertex) => t.graph.edges
        .where((e) => e.isOutgoingFrom(vertex.id) && e.hasAnyLabel(labels))
        .map((e) =>
            p.extend(ElementIdImpl.fromEdgeId(e.id!), e.commonLabels(labels))));
  }
}

class InEStep extends TraversalStepInEBase implements TraversalStepModel {
  InEStep(this.labels);

  final List<String> labels;

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, vertex) => t.graph.edges
        .where((e) => e.isIncomingTo(vertex.id) && e.hasAnyLabel(labels))
        .map((e) =>
            p.extend(ElementIdImpl.fromEdgeId(e.id!), e.commonLabels(labels))));
  }
}

class BothEStep extends TraversalStepBothEBase implements TraversalStepModel {
  BothEStep(this.labels);

  final List<String> labels;

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, vertex) => t.graph.edges
        .where((e) => e.isConnectedTo(vertex.id) && e.hasAnyLabel(labels))
        .map((e) =>
            p.extend(ElementIdImpl.fromEdgeId(e.id!), e.commonLabels(labels))));
  }
}

class OutVStep extends TraversalStepOutVBase implements TraversalStepModel {
  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, edge) {
      final e = t.graph.getEdgeById(edge.id)!;
      return [p.extend(ElementIdImpl.fromVertexId(e.fromVertexId))];
    });
  }
}

class InVStep extends TraversalStepInVBase implements TraversalStepModel {
  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, edge) {
      final e = t.graph.getEdgeById(edge.id)!;
      return [p.extend(ElementIdImpl.fromVertexId(e.toVertexId))];
    });
  }
}

class BothVStep extends TraversalStepBothVBase implements TraversalStepModel {
  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, edge) {
      final e = t.graph.getEdgeById(edge.id)!;
      return [
        p.extend(ElementIdImpl.fromVertexId(e.fromVertexId)),
        p.extend(ElementIdImpl.fromVertexId(e.toVertexId))
      ];
    });
  }
}

class ValuesStep extends TraversalStepValuesBase implements TraversalStepModel {
  ValuesStep(super.keys);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, id) {
      final e = t.graph.getElementByElementId(id)!;
      return (keys.isNotEmpty ? keys : e.propertyKeys)
          .map((key) => p.extend(e.getProperty(key)));
    });
  }
}

class ValueMapStep extends TraversalStepValueMapBase
    implements TraversalStepModel {
  ValueMapStep(super.keys);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, id) {
      final e = t.graph.getElementByElementId(id)!;
      return (keys.isNotEmpty ? keys : e.propertyKeys)
          .map((key) => p.extend(MapEntry(key, e.getProperty(key))));
    });
  }
}

class LimitStep extends TraversalStepLimitBase implements TraversalStepModel {
  LimitStep(super.limit);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.take(limit);
  }
}

class OrderStep extends TraversalStepOrderBase implements TraversalStepModel {
  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    // targets are not used here
    final descriptors = t.collectAggregationDescriptors(modulatorSteps,
        (byStep) => (byStep as TraversalStepModel).apply(t, targets));

    // TODO(szktty): Implement
    // DatabaseHelper.compareDatabaseValues
    // TODO(szktty): Consider limit later
    return targets.sortedPaths((a, b) {
      // TODO(szktty): What about non-element cases?
      if (a is Element && b is Element) {
        for (final descriptor in descriptors) {
          var result = 0;
          if (descriptor is IdSortDescriptor) {
            result = a.id!.compareTo(b.id!);
            if (descriptor.order == SortOrder.desc) {
              result = -result;
            }
          } else if (descriptor is KeySortDescriptor) {
            result = DatabaseValueHelper.compareDatabaseValues(
              a.getProperty(descriptor.key),
              b.getProperty(descriptor.key),
            );
            if (descriptor.order == SortOrder.desc) {
              result = -result;
            }
          } else {
            throw StateError('Unknown sort descriptor: $descriptor');
          }

          if (result != 0) {
            return result;
          }
        }
        return 0;
      } else {
        return DatabaseValueHelper.compareDatabaseValues(a, b);
      }
    });
  }
}

class GroupStep extends TraversalStepGroupBase implements TraversalStepModel {
  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    // Do nothing here, actual grouping will be done in OrderByKeyStep
    return targets;
  }
}

class ByIdStep extends TraversalStepByIdBase implements TraversalStepModel {
  ByIdStep(super.order);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    t.addAggregationDescriptor(IdSortDescriptor(order));
    return targets;
  }
}

class ByKeyStep extends TraversalStepByKeyBase implements TraversalStepModel {
  ByKeyStep(super.key, super.order);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    t.addAggregationDescriptor(KeySortDescriptor(key, order));
    return targets;
  }
}

class DedupStep extends TraversalStepDedupBase implements TraversalStepModel {
  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.toSet();
  }
}

class MapStep extends TraversalStepMapBase implements TraversalStepModel {
  MapStep(super.transformer);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.extendPaths<dynamic>(transformer);
  }
}

class PathStep extends TraversalStepPathBase implements TraversalStepModel {
  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    // do nothing
    return targets;
  }
}

class CountStep extends TraversalStepCountBase implements TraversalStepModel {
  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    // Execute count and return result
    final count = targets.length;
    return [TraversalPathImpl().extend(count)];
  }
}

class AsStep extends TraversalStepAsBase implements TraversalStepModel {
  AsStep(super.label);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    // as() step only labels current results without changing them
    // Basic implementation does nothing
    return targets;
  }
}

class SelectStep extends TraversalStepSelectBase implements TraversalStepModel {
  SelectStep(super.labels);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    // select() step selects results with specified labels
    // Basic implementation returns current results as is
    return targets;
  }
}

class RepeatStep extends TraversalStepRepeatBase implements TraversalStepModel {
  RepeatStep(super.traversal);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    // repeat() step requires complex implementation
    // Basic implementation executes specified traversal only once
    throw UnimplementedError('RepeatStep requires complex implementation');
  }
}

class UntilStep extends TraversalStepUntilBase implements TraversalStepModel {
  UntilStep(super.predicate);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    // until() step is used in combination with repeat()
    // Basic implementation does nothing
    return targets;
  }
}

class TimesStep extends TraversalStepTimesBase implements TraversalStepModel {
  TimesStep(super.times);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    // times() step is used in combination with repeat()
    // Basic implementation does nothing
    return targets;
  }
}

class ListContainsStep extends TraversalStepListContainsBase
    implements TraversalStepModel {
  ListContainsStep(super.key, super.value);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, elementId) {
      final element = t.graph.getElementByElementId(elementId);
      if (element == null) return <TraversalPath>[];

      final property = element.getProperty(key);
      if (property is List) {
        return property.contains(value)
            ? [TraversalPathImpl.fromObject(elementId)]
            : <TraversalPath>[];
      }
      return <TraversalPath>[];
    });
  }
}

class ListContainsExactStep extends TraversalStepListContainsExactBase
    implements TraversalStepModel {
  ListContainsExactStep(super.key, super.value);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, elementId) {
      final element = t.graph.getElementByElementId(elementId);
      if (element == null) return <TraversalPath>[];

      final property = element.getProperty(key);
      if (property is List) {
        return property.contains(value)
            ? [TraversalPathImpl.fromObject(elementId)]
            : <TraversalPath>[];
      }
      return <TraversalPath>[];
    });
  }
}

class ListLengthStep extends TraversalStepListLengthBase
    implements TraversalStepModel {
  ListLengthStep(super.key, super.length);

  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    return targets.derivePaths<ElementId>((p, elementId) {
      final element = t.graph.getElementByElementId(elementId);
      if (element == null) return <TraversalPath>[];

      final property = element.getProperty(key);
      if (property is List) {
        return property.length == length
            ? [TraversalPathImpl.fromObject(elementId)]
            : <TraversalPath>[];
      }
      return <TraversalPath>[];
    });
  }
}
