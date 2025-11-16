import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:rinne_graph/src/database/database_base.dart';
import 'package:rinne_graph/src/database/schema.dart';
import 'package:rinne_graph/src/database/validation.dart';
import 'package:rinne_graph/src/exception.dart';
import 'package:rinne_graph/src/graph/event_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class DatabaseManager {
  factory DatabaseManager() {
    return _instance;
  }

  DatabaseManager._internal() {
    _initializeDatabaseFactory();
  }

  static final DatabaseManager _instance = DatabaseManager._internal();

  bool _initialized = false;

  void _initializeDatabaseFactory() {
    if (!_initialized) {
      ffi.sqfliteFfiInit();
      ffi.databaseFactoryOrNull = ffi.databaseFactoryFfi;
      _initialized = true;
    }
  }

  Future<Database> openFile(String path) async {
    try {
      final dbPath = p.join(await getDatabasesPath(), path);
      final sqliteDb = await ffi.databaseFactoryFfi.openDatabase(
        dbPath,
        options: ffi.OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
        ),
      );
      final eventManager = GraphEventManagerImpl();
      return SQLiteDatabase(sqliteDb, eventManager);
    } catch (e) {
      throw DatabaseException('Failed to open file database: $e');
    }
  }

  /// Open database file with absolute path
  Future<Database> openFileWithAbsolutePath(String absolutePath) async {
    try {
      final sqliteDb = await ffi.databaseFactoryFfi.openDatabase(
        absolutePath,
        options: ffi.OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
        ),
      );
      final eventManager = GraphEventManagerImpl();
      return SQLiteDatabase(sqliteDb, eventManager);
    } catch (e) {
      throw DatabaseException(
          'Failed to open file database with absolute path: $e');
    }
  }

  Future<Database> openInMemory() async {
    try {
      final sqliteDb = await ffi.databaseFactoryFfi.openDatabase(
        ffi.inMemoryDatabasePath,
        options: ffi.OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
        ),
      );
      final eventManager = GraphEventManagerImpl();
      return SQLiteDatabase(sqliteDb, eventManager);
    } catch (e) {
      throw DatabaseException(
        'Failed to open in-memory database: $e',
      );
    }
  }

  Future<String> getDatabasesPath() async {
    return ffi.getDatabasesPath();
  }

  Future<void> deleteDatabase(String path) async {
    await ffi.deleteDatabase(path);
  }

  /// Check if SQLite file is initialized for this library
  ///
  /// [path] Path to the database file to check
  /// [options] Validation options (default if omitted)
  ///
  /// Returns: [DatabaseValidationResult] Validation result
  ///
  /// Throws: [DatabaseValidationException] File access errors, etc.
  Future<DatabaseValidationResult> validateDatabaseFile(
    String path, {
    DatabaseValidationOptions options =
        DatabaseValidationOptions.defaultOptions,
  }) async {
    ffi.Database? db;
    try {
      final dbPath = p.join(await getDatabasesPath(), path);

      // Check file existence
      if (!_fileExists(dbPath)) {
        return DatabaseValidationResult(
          isValid: false,
          isInitialized: false,
          missingTables: [],
          missingIndexes: [],
          missingTriggers: [],
          schemaVersion: null,
          errorMessage: 'Database file does not exist: $dbPath',
        );
      }

      // Open database in read-only mode
      db = await ffi.databaseFactoryFfi.openDatabase(
        dbPath,
        options: ffi.OpenDatabaseOptions(
          readOnly: true,
        ),
      );

      return await _validateDatabase(db, options);
    } catch (e) {
      throw DatabaseValidationException('Failed to validate database file: $e');
    } finally {
      await db?.close();
    }
  }

  /// Check file existence
  bool _fileExists(String path) {
    return File(path).existsSync();
  }

  /// Execute database validation
  Future<DatabaseValidationResult> _validateDatabase(
    ffi.Database db,
    DatabaseValidationOptions options,
  ) async {
    try {
      // Definition of required tables, indexes, and triggers
      final requiredTables = [
        'vertices',
        'edges',
        'vertex_labels',
        'edge_labels',
        'vertex_properties',
        'edge_properties',
      ];

      final requiredIndexes = [
        'idx_vertex_labels',
        'idx_edge_labels',
        'idx_edges_from_to',
        'idx_vertex_properties_key_type_value',
        'idx_edge_properties_key_type_value',
      ];

      final requiredTriggers = [
        'update_vertex_timestamp',
        'update_edge_timestamp',
      ];

      final missingTables = <String>[];
      final missingIndexes = <String>[];
      final missingTriggers = <String>[];

      // Check table existence
      if (options.checkTables) {
        for (final table in requiredTables) {
          final result = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
            [table],
          );
          if (result.isEmpty) {
            missingTables.add(table);
          }
        }
      }

      // Check index existence
      if (options.checkIndexes) {
        for (final index in requiredIndexes) {
          final result = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
            [index],
          );
          if (result.isEmpty) {
            missingIndexes.add(index);
          }
        }
      }

      // Check trigger existence
      if (options.checkTriggers) {
        for (final trigger in requiredTriggers) {
          final result = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='trigger' AND name=?",
            [trigger],
          );
          if (result.isEmpty) {
            missingTriggers.add(trigger);
          }
        }
      }

      // Get schema version
      int? schemaVersion;
      if (options.checkSchemaVersion) {
        try {
          final result = await db.rawQuery('PRAGMA user_version');
          if (result.isNotEmpty) {
            schemaVersion = result.first['user_version'] as int?;
          }
        } on Exception {
          // Ignore if schema version retrieval fails
        }
      }

      // Determine initialization state
      final isInitialized = missingTables.isEmpty;
      final isValid = isInitialized;

      return DatabaseValidationResult(
        isValid: isValid,
        isInitialized: isInitialized,
        missingTables: missingTables,
        missingIndexes: missingIndexes,
        missingTriggers: missingTriggers,
        schemaVersion: schemaVersion,
      );
    } on Exception catch (e) {
      return DatabaseValidationResult(
        isValid: false,
        isInitialized: false,
        missingTables: [],
        missingIndexes: [],
        missingTriggers: [],
        schemaVersion: null,
        errorMessage: 'Error occurred during database validation: $e',
      );
    }
  }

  static Future<void> _onCreate(ffi.Database db, int version) async {
    await db.execute(DatabaseSchema.createVerticesTable);
    await db.execute(DatabaseSchema.createVertexLabelsTable);
    await db.execute(DatabaseSchema.createVertexPropertiesTable);
    await db.execute(DatabaseSchema.createEdgesTable);
    await db.execute(DatabaseSchema.createEdgeLabelsTable);
    await db.execute(DatabaseSchema.createEdgePropertiesTable);

    for (final indexQuery in DatabaseSchema.createIndices) {
      await db.execute(indexQuery);
    }

    await db.execute(DatabaseSchema.createVertexTimestampTrigger);
    await db.execute(DatabaseSchema.createEdgeTimestampTrigger);
  }
}
