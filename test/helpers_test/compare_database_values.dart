import 'package:kiri_check/kiri_check.dart';
import 'package:rinne_graph/src/database/helper.dart';
import 'package:test/test.dart';

import '../helpers/arbitrary.dart';

Arbitrary<int> smallId() => integer(min: 0, max: 10);

void main() {
  KiriCheck.maxExamples = 1000;

  group('values only', () {
    property('symmetry', () {
      forAll(
          combine2(
            ArbitraryTestHelpers.propertyValue(),
            ArbitraryTestHelpers.propertyValue(),
          ), (args) {
        final (value1, value2) = args;
        final result1 =
            DatabaseValueHelper.compareDatabaseValues(value1, value2);
        final result2 =
            DatabaseValueHelper.compareDatabaseValues(value2, value1);
        expect(result1, equals(-result2));
      });
    });

    property('reflexivity', () {
      forAll(ArbitraryTestHelpers.propertyValue(), (value) {
        final result = DatabaseValueHelper.compareDatabaseValues(value, value);
        expect(result, equals(0));
      });
    });

    property('transitivity', () {
      forAll(
          combine3(
            ArbitraryTestHelpers.propertyValue(),
            ArbitraryTestHelpers.propertyValue(),
            ArbitraryTestHelpers.propertyValue(),
          ), (args) {
        final (value1, value2, value3) = args;
        final result1 =
            DatabaseValueHelper.compareDatabaseValues(value1, value2);
        final result2 =
            DatabaseValueHelper.compareDatabaseValues(value2, value3);
        final result3 =
            DatabaseValueHelper.compareDatabaseValues(value1, value3);
        if (result1 == 0 && result2 == 0) {
          expect(result3, equals(0), reason: '$result3 == 0');
        } else if (result1 <= 0 && result2 <= 0) {
          expect(result3, lessThanOrEqualTo(0), reason: '$result3 <= 0');
        } else if (result1 >= 0 && result2 >= 0) {
          expect(result3, greaterThanOrEqualTo(0), reason: '$result3 >= 0');
        } else {
          // ignore
        }
      });
    });

    property('consistency', () {
      forAll(
          combine2(
            ArbitraryTestHelpers.propertyValue(),
            ArbitraryTestHelpers.propertyValue(),
          ), (args) {
        final (value1, value2) = args;
        final result1 =
            DatabaseValueHelper.compareDatabaseValues(value1, value2);
        final result2 =
            DatabaseValueHelper.compareDatabaseValues(value1, value2);
        expect(result1, equals(result2));
      });
    });
  });

  group('values and IDs', () {
    property('symmetry', () {
      forAll(
          combine2(
            ArbitraryTestHelpers.propertyValue(),
            ArbitraryTestHelpers.propertyValue(),
          ), (args) {
        final (value1, value2) = args;
        final id1 = smallId().example();
        final id2 = smallId().example();
        final result1 = DatabaseValueHelper.compareDatabaseValuesOrIds(
          id1,
          id2,
          value1,
          value2,
        );
        final result2 = DatabaseValueHelper.compareDatabaseValuesOrIds(
          id2,
          id1,
          value2,
          value1,
        );
        expect(result1, equals(-result2));
      });
    });

    property('reflexivity', () {
      forAll(ArbitraryTestHelpers.propertyValue(), (value) {
        final id = smallId().example();
        final result = DatabaseValueHelper.compareDatabaseValuesOrIds(
          id,
          id,
          value,
          value,
        );
        expect(result, equals(0));
      });
    });

    property('transitivity', () {
      forAll(
          combine3(
            ArbitraryTestHelpers.propertyValue(),
            ArbitraryTestHelpers.propertyValue(),
            ArbitraryTestHelpers.propertyValue(),
          ), (args) {
        final (value1, value2, value3) = args;
        final id1 = smallId().example();
        final id2 = smallId().example();
        final id3 = smallId().example();
        final result1 = DatabaseValueHelper.compareDatabaseValuesOrIds(
          id1,
          id2,
          value1,
          value2,
        );
        final result2 = DatabaseValueHelper.compareDatabaseValuesOrIds(
          id2,
          id3,
          value2,
          value3,
        );
        final result3 = DatabaseValueHelper.compareDatabaseValuesOrIds(
          id1,
          id3,
          value1,
          value3,
        );
        if (result1 == 0 && result2 == 0) {
          expect(result3, equals(0), reason: '$result3 == 0');
        } else if (result1 <= 0 && result2 <= 0) {
          expect(result3, lessThanOrEqualTo(0), reason: '$result3 <= 0');
        } else if (result1 >= 0 && result2 >= 0) {
          expect(result3, greaterThanOrEqualTo(0), reason: '$result3 >= 0');
        } else {
          // ignore
        }
      });
    });

    property('consistency', () {
      forAll(
          combine2(
            ArbitraryTestHelpers.propertyValue(),
            ArbitraryTestHelpers.propertyValue(),
          ), (args) {
        final (value1, value2) = args;
        final id1 = smallId().example();
        final id2 = smallId().example();
        final result1 = DatabaseValueHelper.compareDatabaseValuesOrIds(
          id1,
          id2,
          value1,
          value2,
        );
        final result2 = DatabaseValueHelper.compareDatabaseValuesOrIds(
          id1,
          id2,
          value1,
          value2,
        );
        expect(result1, equals(result2));
      });
    });
  });
}
