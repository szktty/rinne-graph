import 'package:rinne_graph/src/traversal/traversal_intf.dart';

abstract class AggregationDescriptor {
  int rank = -1;
}

abstract class SortDescriptor extends AggregationDescriptor {
  SortDescriptor(this.order);

  final SortOrder order;
}

class IdSortDescriptor extends SortDescriptor {
  IdSortDescriptor(super.order);
}

class KeySortDescriptor extends SortDescriptor {
  KeySortDescriptor(this.key, super.order);

  final String key;
}

final class KeyGroupDescriptor extends AggregationDescriptor {
  KeyGroupDescriptor(this.key);

  final String key;
}
