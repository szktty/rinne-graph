import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/helpers/comparison.dart';
import 'package:test/test.dart';

void main() {
  test('doubleEquals', () {
    expect(ComparisonHelper.doubleEquals(1, 1), isTrue);
    expect(ComparisonHelper.doubleEquals(1, 1.0 + 1e-11), isTrue);
    expect(ComparisonHelper.doubleEquals(1, 1.0 + 1e-9), isFalse);

    expect(
      ComparisonHelper.doubleEquals(-303.060045662071, -303.0600456620714),
      isTrue,
    );
  });

  test('deep equality with double', () {
    expect(
      ComparisonHelper.deepEquals(
        {'a': -303.060045662071},
        {'a': -303.0600456620714},
      ),
      isTrue,
    );
  });

  test('deep equality with double 2', () {
    final actual = {
      'cbg2Z4y6N': NullValue(),
      'dkULtdbY1SbTasH': -8852,
      'vRSrM': 87,
      'xHULN0XWQ': -7640.68503553935,
    };
    final expected = {
      'cbg2Z4y6N': NullValue(),
      'dkULtdbY1SbTasH': -8852,
      'vRSrM': 87,
      'xHULN0XWQ': -7640.68503553935,
    };

    expect(ComparisonHelper.deepEquals(actual, expected), isTrue);
  });

  test('deep equality with NullValue', () {
    expect(
      ComparisonHelper.deepEquals(
        {'vUBWD6Hep062Aci': NullValue()},
        {'vUBWD6Hep062Aci': NullValue()},
      ),
      isTrue,
    );
  });
}
