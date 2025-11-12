import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('NullValue', () {
    test('should be a singleton', () {
      final instance1 = NullValue();
      final instance2 = NullValue();
      expect(identical(instance1, instance2), isTrue);
    });

    test('should be equal to another NullValue', () {
      final nullValue1 = NullValue();
      final nullValue2 = NullValue();
      expect(nullValue1, equals(nullValue2));
    });

    test('isNull should return true for null and NullValue', () {
      expect(NullValue.isNull(null), isTrue);
      expect(NullValue.isNull(NullValue()), isTrue);
      expect(NullValue.isNull(0), isFalse);
    });

    test('toNullValue should convert null to NullValue', () {
      expect(NullValue.toNullValue(null), isA<NullValue>());
      expect(NullValue.toNullValue(1), equals(1));
    });

    test('toNull should convert NullValue to null', () {
      expect(NullValue.toNull(NullValue()), isNull);
      expect(NullValue.toNull(1), equals(1));
    });
  });
}
