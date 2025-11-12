import 'package:collection/collection.dart';

// TODO(szktty): Consider removing this helper as double comparison is now possible with raw value storage instead of TEXT.

abstract class ComparisonHelper {
  static bool doubleEquals(double a, double b, {double epsilon = 1e-10}) {
    return (a - b).abs() < epsilon;
  }

  static DeepCollectionEquality deepCollectionEquality({
    double epsilon = 1e-10,
  }) {
    return DeepCollectionEquality(_DatabaseValueEquality(epsilon: epsilon));
  }

  static bool deepEquals(dynamic a, dynamic b, {double epsilon = 1e-10}) {
    return deepCollectionEquality(epsilon: epsilon).equals(a, b);
  }
}

final class _DatabaseValueEquality extends DefaultEquality<dynamic> {
  _DatabaseValueEquality({this.epsilon = 1e-10});

  final double epsilon;

  @override
  int hash(Object? e) {
    if (e is double) {
      if (e.isInfinite || e.isNaN) {
        return e.hashCode;
      } else {
        // TODO(szktty): Handle potential errors when calling toInt() on Infinity or NaN in hashCode().
        return (e / epsilon).round().hashCode;
      }
    } else {
      return super.hash(e);
    }
  }

  @override
  bool equals(Object? e1, Object? e2) {
    if (e1 is double && e2 is double) {
      return ComparisonHelper.doubleEquals(e1, e2, epsilon: epsilon);
    } else {
      return super.equals(e1, e2);
    }
  }
}
