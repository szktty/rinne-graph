import 'dart:io';

import 'package:kiri_check/kiri_check.dart';
import 'package:path/path.dart' as path;
import 'package:rinne_graph/src/database/database.dart';
import 'package:rinne_graph/src/exception.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite;
import 'package:test/test.dart';

import 'helpers/debug_helper.dart';
import 'helpers/helpers.dart';

void main() {
  // Initialize debug settings
  initializeDebugSettings();

  group('Database Validation Tests', () {
    property('validateDatabaseFile returns error for non-existent file', () {
      forAll(
        ArbitraryTestHelpers.identifierString().map((s) => '$s.db'),
        (fileName) async {
          final manager = DatabaseManager();
          final result = await manager.validateDatabaseFile(fileName);

          expect(result.isValid, isFalse);
          expect(result.isInitialized, isFalse);
          expect(result.errorMessage, contains('Database file does not exist'));
        },
      );
    });

    property('validateDatabaseFile validates properly initialized database',
        () {
      forAll(
        ArbitraryTestHelpers.identifierString().map((s) => '$s.db'),
        (fileName) async {
          final manager = DatabaseManager();

          // Create and initialize database
          final db = await manager.openFile(fileName);
          await db.close();

          try {
            // Execute validation
            final result = await manager.validateDatabaseFile(fileName);

            expect(result.isValid, isTrue);
            expect(result.isInitialized, isTrue);
            expect(result.isFullyInitialized, isTrue);
            expect(result.missingTables, isEmpty);
            expect(result.missingIndexes, isEmpty);
            expect(result.missingTriggers, isEmpty);
            expect(result.errorMessage, isNull);
          } finally {
            // Cleanup
            final dbPath =
                path.join(await manager.getDatabasesPath(), fileName);
            await sqflite.deleteDatabase(dbPath);
          }
        },
      );
    });

    property('validateDatabaseFile detects missing tables in empty database',
        () {
      forAll(
        ArbitraryTestHelpers.identifierString().map((s) => '$s.db'),
        (fileName) async {
          final manager = DatabaseManager();
          final dbPath = path.join(await manager.getDatabasesPath(), fileName);

          try {
            // Create empty SQLite database (no tables)
            final db = await sqflite.databaseFactoryFfi.openDatabase(
              dbPath,
              options: sqflite.OpenDatabaseOptions(
                version: 1,
                // Create empty database by not specifying onCreate
              ),
            );
            await db.close();

            // Execute validation
            final result = await manager.validateDatabaseFile(fileName);

            expect(result.isValid, isFalse);
            expect(result.isInitialized, isFalse);
            expect(result.missingTables, isNotEmpty);
            expect(result.missingTables, contains('vertices'));
            expect(result.missingTables, contains('edges'));
          } finally {
            // Cleanup
            if (File(dbPath).existsSync()) {
              await File(dbPath).delete();
            }
          }
        },
      );
    });

    property('validateDatabaseFile with different validation options', () {
      forAll(
        ArbitraryTestHelpers.identifierString().map((s) => '$s.db'),
        (fileName) async {
          final manager = DatabaseManager();

          // Create and initialize database
          final db = await manager.openFile(fileName);
          await db.close();

          try {
            // Basic validation options
            final basicResult = await manager.validateDatabaseFile(
              fileName,
              options: DatabaseValidationOptions.basic,
            );
            expect(basicResult.isValid, isTrue);
            expect(basicResult.isInitialized, isTrue);

            // Default validation options
            final defaultResult = await manager.validateDatabaseFile(fileName);
            expect(defaultResult.isValid, isTrue);
            expect(defaultResult.isInitialized, isTrue);
            expect(defaultResult.isFullyInitialized, isTrue);

            // Strict validation options
            final strictResult = await manager.validateDatabaseFile(
              fileName,
              options: DatabaseValidationOptions.strict,
            );
            expect(strictResult.isValid, isTrue);
            expect(strictResult.isInitialized, isTrue);
          } finally {
            // Cleanup
            final dbPath =
                path.join(await manager.getDatabasesPath(), fileName);
            await sqflite.deleteDatabase(dbPath);
          }
        },
      );
    });

    test('DatabaseValidationResult description provides meaningful messages',
        () {
      // Fully initialized database
      const validResult = DatabaseValidationResult(
        isValid: true,
        isInitialized: true,
        missingTables: [],
        missingIndexes: [],
        missingTriggers: [],
        schemaVersion: 1,
      );
      expect(validResult.description, contains('properly initialized'));
      expect(validResult.isFullyInitialized, isTrue);

      // Incomplete database
      const invalidResult = DatabaseValidationResult(
        isValid: false,
        isInitialized: false,
        missingTables: ['vertices', 'edges'],
        missingIndexes: ['idx_vertex_labels'],
        missingTriggers: ['update_vertex_timestamp'],
        schemaVersion: null,
        errorMessage: 'Test error',
      );
      expect(invalidResult.description, contains('Missing tables'));
      expect(invalidResult.description, contains('vertices, edges'));
      expect(invalidResult.description, contains('Missing indexes'));
      expect(invalidResult.description, contains('Missing triggers'));
      expect(invalidResult.description, contains('Test error'));
      expect(invalidResult.isFullyInitialized, isFalse);
    });

    test('DatabaseValidationException is thrown for invalid operations', () {
      expect(
        () => throw DatabaseValidationException('Test error'),
        throwsA(isA<DatabaseValidationException>()),
      );
    });
  });
}
