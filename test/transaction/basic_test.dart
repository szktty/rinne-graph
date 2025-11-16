import 'package:kiri_check/kiri_check.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

import '../helpers/arbitrary.dart';

void main() {
  final dbManager = DatabaseManager();

  property('Vertex operations', () {
    forAll(
      deck(),
      (deck) async {
        final db = await dbManager.openInMemory();
        await db.transaction((txn) async {
          // Create vertex
          final vertex = Vertex(
            labels: {deck.draw(ArbitraryTestHelpers.identifierString())},
            properties: {
              deck.draw(ArbitraryTestHelpers.identifierString()):
                  deck.draw(integer()),
            },
          );
          final createdVertex = await txn.createVertex(vertex);
          expect(createdVertex.id, isNotNull);

          // Get vertex
          final retrievedVertex = await txn.getVertex(createdVertex.id!);
          expect(retrievedVertex, isNotNull);
          expect(retrievedVertex!.labels, equals(vertex.labels));
          expect(retrievedVertex.properties, equals(vertex.properties));

          // Update vertex
          final updatedProperties = {
            deck.draw(ArbitraryTestHelpers.identifierString()):
                deck.draw(integer()),
          };
          final updatedVertex =
              createdVertex.copyWith(properties: updatedProperties);
          await txn.updateVertex(updatedVertex);
          final retrievedUpdatedVertex = await txn.getVertex(createdVertex.id!);
          expect(retrievedUpdatedVertex!.properties, equals(updatedProperties));

          // Delete vertex
          await txn.deleteVertex(createdVertex.id!);
          final deletedVertex = await txn.getVertex(createdVertex.id!);
          expect(deletedVertex, isNull);
        });
        await db.close();
      },
    );
  });

  property('Edge operations', () {
    forAll(
      deck(),
      (deck) async {
        final db = await dbManager.openInMemory();
        await db.transaction((txn) async {
          // Create two vertices
          final vertex1 = await txn.createVertex(Vertex());
          final vertex2 = await txn.createVertex(Vertex());

          // Create edge
          final edge = Edge(
            fromVertexId: vertex1.id!,
            toVertexId: vertex2.id!,
            labels: {deck.draw(ArbitraryTestHelpers.identifierString())},
            properties: {
              deck.draw(ArbitraryTestHelpers.identifierString()):
                  deck.draw(integer()),
            },
          );
          final createdEdge = await txn.createEdge(edge);
          expect(createdEdge.id, isNotNull);

          // Get edge
          final retrievedEdge = await txn.getEdge(createdEdge.id!);
          expect(retrievedEdge, isNotNull);
          expect(retrievedEdge!.labels, equals(edge.labels));
          expect(retrievedEdge.properties, equals(edge.properties));

          // Update edge
          final updatedProperties = {
            deck.draw(ArbitraryTestHelpers.identifierString()):
                deck.draw(integer()),
          };
          final updatedEdge =
              createdEdge.copyWith(properties: updatedProperties);
          await txn.updateEdge(updatedEdge);
          final retrievedUpdatedEdge = await txn.getEdge(createdEdge.id!);
          expect(retrievedUpdatedEdge!.properties, equals(updatedProperties));

          // Delete edge
          await txn.deleteEdge(createdEdge.id!);
          final deletedEdge = await txn.getEdge(createdEdge.id!);
          expect(deletedEdge, isNull);
        });
        await db.close();
      },
    );
  });

  property('Vertex and Edge queries', () {
    forAll(
      deck(),
      (deck) async {
        final db = await dbManager.openInMemory();
        await db.transaction((txn) async {
          final label = deck.draw(ArbitraryTestHelpers.identifierString());

          // Create vertices
          final vertices = await Future.wait(
            List.generate(3, (_) => txn.createVertex(Vertex(labels: {label}))),
          );

          // Get vertices by label
          final retrievedVertices = await txn.getVerticesWithLabel(label);
          expect(retrievedVertices.length, equals(3));

          // Create edges
          final edges = await Future.wait([
            txn.createEdge(
              Edge(
                fromVertexId: vertices[0].id!,
                toVertexId: vertices[1].id!,
                labels: {label},
              ),
            ),
            txn.createEdge(
              Edge(
                fromVertexId: vertices[1].id!,
                toVertexId: vertices[2].id!,
                labels: {label},
              ),
            ),
          ]);

          // Get edges by label
          final retrievedEdges = await txn.getEdgesWithLabel(label);
          expect(retrievedEdges.length, equals(2));

          // Get edges from vertex
          final edgesFromVertex = await txn.getEdgesFromVertex(vertices[0].id!);
          expect(edgesFromVertex.length, equals(1));
          expect(edgesFromVertex[0].id, equals(edges[0].id));

          // Get edges to vertex
          final edgesToVertex = await txn.getEdgesToVertex(vertices[2].id!);
          expect(edgesToVertex.length, equals(1));
          expect(edgesToVertex[0].id, equals(edges[1].id));
        });
        await db.close();
      },
    );
  });
}
