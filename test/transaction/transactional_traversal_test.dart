import 'package:kiri_check/kiri_check.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Transactional Traversal API', () {
    late DatabaseManager dbManager;

    setUp(() {
      dbManager = DatabaseManager();
    });

    property('Basic transactional traversal execution', () {
      forAll(
        deck(),
        (deck) async {
          final db = await dbManager.openInMemory();
          final graph = Graph.fromDatabase(db);

          try {
            await graph.transaction((txn) async {
              // Create test data
              final vertex1 = await txn.createVertex(Vertex(
                labels: {'person'},
                properties: {'name': 'Alice', 'age': 30},
              ));

              final vertex2 = await txn.createVertex(Vertex(
                labels: {'person'},
                properties: {'name': 'Bob', 'age': 25},
              ));

              await txn.createEdge(Edge(
                fromVertexId: vertex1.id!,
                toVertexId: vertex2.id!,
                labels: {'knows'},
                properties: {'since': 2020},
              ));

              // Use traversal API within transaction
              final g = txn.traversal();

              // Get vertices
              final vertices = await g.V().toList();
              expect(vertices.length, equals(2));

              // Label filtering
              final persons = await g.V().hasLabel(['person']).toList();
              expect(persons.length, equals(2));

              // Property filtering
              final aliceVertices = await g
                  .V()
                  .hasLabel(['person'])
                  .hasKey('name', 'Alice')
                  .toList();
              expect(aliceVertices.length, equals(1));

              // Edge traversal
              final edges = await g.E().toList();
              expect(edges.length, equals(1));

              // Get adjacent vertices
              final neighbors =
                  await g.V([vertex1.id!]).out(['knows']).toList();
              expect(neighbors.length, equals(1));
              expect((neighbors.first as Vertex).properties['name'],
                  equals('Bob'));

              return true;
            });
          } finally {
            await graph.close();
          }
        },
      );
    });

    property('Transactional traversal rollback', () {
      forAll(
        deck(),
        (deck) async {
          final db = await dbManager.openInMemory();
          final graph = Graph.fromDatabase(db);

          try {
            // Create initial data
            await graph.transaction((txn) async {
              await txn.createVertex(Vertex(
                labels: {'person'},
                properties: {'name': 'Initial', 'age': 20},
              ));
            });

            // Rollback test
            try {
              await graph.transaction((txn) async {
                // Create new vertex
                await txn.createVertex(Vertex(
                  labels: {'person'},
                  properties: {'name': 'Rollback', 'age': 25},
                ));

                // Use traversal API within transaction
                final g = txn.traversal();
                final vertices = await g.V().hasLabel(['person']).toList();
                expect(vertices.length, equals(2)); // Initial + new

                // Intentionally throw exception to test rollback
                throw Exception('Forced rollback for testing');
              });
            } on Exception catch (e) {
              // Catch exception (rollback occurs)
              expect(e.toString(), contains('Forced rollback'));
            }

            // Verify after rollback
            await graph.transaction((txn) async {
              final g = txn.traversal();
              final vertices = await g.V().hasLabel(['person']).toList();
              expect(vertices.length, equals(1)); // Only initial data remains

              final initialVertex = vertices.first as Vertex;
              expect(initialVertex.properties['name'], equals('Initial'));
            });
          } finally {
            await graph.close();
          }
        },
      );
    });

    property('Complex transactional traversal operations', () {
      forAll(
        deck(),
        (deck) async {
          final db = await dbManager.openInMemory();
          final graph = Graph.fromDatabase(db);

          try {
            await graph.transaction((txn) async {
              // Create multiple vertices and edges
              final vertices = await Future.wait([
                txn.createVertex(Vertex(
                  labels: {'person'},
                  properties: {'name': 'Alice', 'age': 30},
                )),
                txn.createVertex(Vertex(
                  labels: {'person'},
                  properties: {'name': 'Bob', 'age': 25},
                )),
                txn.createVertex(Vertex(
                  labels: {'company'},
                  properties: {'name': 'TechCorp'},
                )),
              ]);

              await Future.wait([
                txn.createEdge(Edge(
                  fromVertexId: vertices[0].id!,
                  toVertexId: vertices[1].id!,
                  labels: {'knows'},
                )),
                txn.createEdge(Edge(
                  fromVertexId: vertices[0].id!,
                  toVertexId: vertices[2].id!,
                  labels: {'works_at'},
                )),
              ]);

              // Complex traversal within transaction
              final g = txn.traversal();

              // Get Alice's acquaintances
              final friends =
                  await g.V().hasKey('name', 'Alice').out(['knows']).toList();
              expect(friends.length, equals(1));

              // Get Alice's workplace
              final workplace = await g
                  .V()
                  .hasKey('name', 'Alice')
                  .out(['works_at']).toList();
              expect(workplace.length, equals(1));

              // Get all people
              final allPersons = await g.V().hasLabel(['person']).toList();
              expect(allPersons.length, equals(2));

              // Verify edge count
              final edgeCount = await g.E().count().toList();
              // count() result becomes Map object
              if (edgeCount.first is Map) {
                final countMap = edgeCount.first as Map<String, dynamic>;
                expect(countMap['count_value'], equals(2));
              } else {
                expect(edgeCount.first, equals(2));
              }

              return true;
            });
          } finally {
            await graph.close();
          }
        },
      );
    });
  });
}
