import 'package:rinne_graph/src/util.dart';
import 'package:test/test.dart';

void main() {
  group('escapeString', () {
    test('escapes special characters correctly', () {
      expect(
        escapeSqlString("It's a \"test\""),
        equals("It\\'s a \\\"test\\\""),
      );
      expect(escapeSqlString(r'100% \ success'), equals(r'100% \\ success'));
      expect(escapeSqlString('New\nLine'), equals(r'New\nLine'));
      expect(escapeSqlString('Tab\tCharacter'), equals(r'Tab\tCharacter'));
      expect(escapeSqlString('Backspace\b'), equals(r'Backspace\b'));
      expect(escapeSqlString('Carriage\rReturn'), equals(r'Carriage\rReturn'));
      expect(escapeSqlString('Ctrl+Z\x1A'), equals(r'Ctrl+Z\Z'));
    });

    test('handles empty string', () {
      expect(escapeSqlString(''), equals(''));
    });

    test('handles string without special characters', () {
      expect(escapeSqlString('Normal string'), equals('Normal string'));
    });
  });
}
