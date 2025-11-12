import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  test('minimal sqlite test', () async {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Try to open an in-memory database
    final db = await openDatabase(inMemoryDatabasePath);

    // Execute a simple query
    final result = await db.rawQuery('SELECT 1');
    expect(
        result,
        equals([
          {'1': 1}
        ]));

    await db.close();
  });

  test('JSON1 extension availability test', () async {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Try to open an in-memory database
    final db = await openDatabase(inMemoryDatabasePath);

    try {
      // Test JSON1 functions
      final result1 = await db.rawQuery("SELECT json('[]') as test");
      expect(result1.first['test'], equals('[]'));

      // Test json_each function
      final result2 = await db.rawQuery("""
        SELECT value FROM json_each('["apple", "banana", "cherry"]')
      """);
      expect(result2.length, equals(3));
      expect(result2[0]['value'], equals('apple'));
      expect(result2[1]['value'], equals('banana'));
      expect(result2[2]['value'], equals('cherry'));

      // Test json_array_length function
      final result3 = await db.rawQuery("""
        SELECT json_array_length('["a", "b", "c"]') as length
      """);
      expect(result3.first['length'], equals(3));

      print('JSON1 extension is available and working correctly');
    } catch (e) {
      print('JSON1 extension test failed: $e');
      rethrow;
    } finally {
      await db.close();
    }
  });
}
