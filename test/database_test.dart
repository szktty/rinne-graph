import 'package:kiri_check/kiri_check.dart';
import 'package:path/path.dart' as path;
import 'package:rinne_graph/rinne_graph.dart';
import 'package:rinne_graph/src/database/database_base.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite;
import 'package:test/test.dart';

import 'helpers/arbitrary.dart';
import 'helpers/debug_helper.dart';

void main() {
  // Initialize debug settings
  initializeDebugSettings();
  property('DatabaseManager().openFile creates valid database connection', () {
    forAll(
      ArbitraryTestHelpers.identifierString().map((s) => '$s.db'),
      (fileName) async {
        final db = await DatabaseManager().openFile(fileName);
        expect(db, isA<SQLiteDatabase>());
        expect(
          await db.rawQuery('SELECT 1'),
          equals([
            {'1': 1},
          ]),
        );
        await db.close();

        // Clean up: delete the created file
        final dbPath = path.join(await sqflite.getDatabasesPath(), fileName);
        await sqflite.deleteDatabase(dbPath);
      },
    );
  });

  property(
    'Database schema is correctly initialized',
    () {
      forAll(
        deck(),
        (deck) async {
          late Database db;
          try {
            db = await DatabaseManager().openInMemory();

            // Check table existence
            final tables = [
              'vertices',
              'edges',
              'vertex_labels',
              'edge_labels',
              'vertex_properties',
              'edge_properties',
            ];
            for (final table in tables) {
              final result = await db.rawQuery(
                "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
                [table],
              );
              expect(
                result.length,
                equals(1),
                reason: 'Table $table should exist',
              );
            }

            // Check index existence
            final indexes = [
              'idx_vertex_labels',
              'idx_edge_labels',
              'idx_edges_from_to',
              'idx_vertex_properties_key_type_value',
              'idx_edge_properties_key_type_value',
            ];
            for (final index in indexes) {
              final result = await db.rawQuery(
                "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
                [index],
              );
              expect(
                result.length,
                equals(1),
                reason: 'Index $index should exist',
              );
            }

            // Check trigger existence
            final triggers = [
              'update_vertex_timestamp',
              'update_edge_timestamp',
            ];
            for (final trigger in triggers) {
              final result = await db.rawQuery(
                "SELECT name FROM sqlite_master WHERE type='trigger' AND name=?",
                [trigger],
              );
              expect(
                result.length,
                equals(1),
                reason: 'Trigger $trigger should exist',
              );
            }

            // Check table structure details (e.g., vertices table)
            final verticesColumns =
                await db.rawQuery('PRAGMA table_info(vertices)');
            expect(
              verticesColumns.length,
              equals(4),
              reason: 'vertices table should have 4 columns',
            );
            expect(
              verticesColumns.map((c) => c['name']),
              containsAll(['id', 'archived', 'created_at', 'updated_at']),
              reason: 'vertices table should have correct columns',
            );
          } finally {
            await db.close();
          }
        },
      );
    },
    timeout: const Timeout(Duration(seconds: 60)),
  ); // Increase timeout

  property(
    'File-based database operations',
    () {
      forAll(
        ArbitraryTestHelpers.identifierString().map((s) => '$s.db'),
        (fileName) async {
          final dbPath =
              path.join(await DatabaseManager().getDatabasesPath(), fileName);
          Database? db;
          try {
            db = await DatabaseManager().openFile(dbPath);

            // Basic query execution test
            final result = await db.rawQuery('SELECT 1');
            expect(
              result,
              equals([
                {'1': 1},
              ]),
            );

            // Data insertion and retrieval test
            await db.rawQuery(
              'CREATE TABLE test (id INTEGER PRIMARY KEY, value TEXT)',
            );
            await db.rawQuery(
              'INSERT INTO test (value) VALUES (?)',
              ['test_value'],
            );
            final insertedData = await db.rawQuery('SELECT * FROM test');
            expect(
              insertedData,
              equals([
                {'id': 1, 'value': 'test_value'},
              ]),
            );
          } finally {
            await db?.close();
            // Cleanup: Delete test database file
            await DatabaseManager().deleteDatabase(dbPath);
          }
        },
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  property(
    'Database transaction operations',
    () {
      forAll(
        deck(),
        (deck) async {
          final dbManager = DatabaseManager();
          late Database db;
          try {
            db = await dbManager.openInMemory();

            await db.transaction((txn) async {
              final vertex1 = await txn.createVertex(
                Vertex(labels: {'Person'}, properties: {'name': 'Alice'}),
              );
              final vertex2 = await txn.createVertex(
                Vertex(labels: {'Person'}, properties: {'name': 'Bob'}),
              );

              final edge = await txn.createEdge(
                Edge(
                  fromVertexId: vertex1.id!,
                  toVertexId: vertex2.id!,
                  labels: {'KNOWS'},
                ),
              );

              final retrievedVertex1 = await txn.getVertex(vertex1.id!);
              expect(retrievedVertex1?.properties['name'], equals('Alice'));

              final retrievedEdge = await txn.getEdge(edge.id!);
              expect(retrievedEdge?.labels, contains('KNOWS'));

              final personsWithLabel = await txn.getVerticesWithLabel('Person');
              expect(personsWithLabel.length, equals(2));
            });

            // Transaction rollback test
            try {
              await db.transaction((txn) async {
                await txn.createVertex(
                  Vertex(
                    labels: {'Test'},
                    properties: {'value': 'RollbackTest'},
                  ),
                );
                throw Exception('Forced rollback');
              });
            } on Exception {
              // Catch exception and verify rollback
            }

            // Verify rollback succeeded
            await db.transaction((txn) async {
              final testVertices = await txn.getVerticesWithLabel('Test');
              expect(
                testVertices.length,
                equals(0),
                reason: 'Transaction should have been rolled back',
              );
            });
          } finally {
            await db.close();
          }
        },
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  property(
    'Concurrent database access',
    () {
      forAll(
        integer(min: 2, max: 20),
        (n) async {
          final dbManager = DatabaseManager();
          late Database db;
          try {
            db = await dbManager.openInMemory();

            // Create initial data
            await db.transaction((txn) async {
              await txn.createVertex(
                Vertex(labels: {'TestVertex'}, properties: {'value': 0}),
              );
            });

            // Simulate multiple concurrent transactions
            final futures = List.generate(
              n,
              (index) => db.transaction((txn) async {
                final vertices = await txn.getVerticesWithLabel('TestVertex');
                final vertex = vertices.first;
                final currentValue = vertex.properties['value'] as int;
                await txn.updateVertex(
                  vertex.copyWith(
                    properties: {
                      ...vertex.properties,
                      'value': currentValue + 1,
                    },
                  ),
                );
                return currentValue + 1;
              }),
            );

            final results = await Future.wait(futures);

            // Verify final value
            await db.transaction((txn) async {
              final vertices = await txn.getVerticesWithLabel('TestVertex');
              final finalVertex = vertices.first;
              final finalValue = finalVertex.properties['value'] as int;

              // Verify all transactions succeeded and consistency is maintained
              expect(
                finalValue,
                equals(n),
                reason: 'Final value should be 10 after 10 increments',
              );

              // Verify each transaction result is different (order not guaranteed)
              expect(
                results.toSet().length,
                equals(n),
                reason: 'Each transaction should see a different state',
              );
            });
          } finally {
            await db.close();
          }
        },
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  ); // Set longer timeout for concurrent processing
}
