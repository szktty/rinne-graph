extension ListExtension<E> on List<E> {
  bool containsAny(Iterable<E> elements, {bool ifUnspecified = false}) {
    if (ifUnspecified && elements.isEmpty) {
      return true;
    }
    for (final element in elements) {
      if (contains(element)) {
        return true;
      }
    }
    return false;
  }
}

extension SetExtension<E> on Set<E> {
  bool containsAny(Iterable<E> elements, {bool ifUnspecified = false}) {
    if (ifUnspecified && elements.isEmpty) {
      return true;
    }
    for (final element in elements) {
      if (contains(element)) {
        return true;
      }
    }
    return false;
  }
}
