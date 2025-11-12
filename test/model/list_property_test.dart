import 'package:kiri_check/kiri_check.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

import '../helpers/arbitrary.dart';

void main() {
  group('List property tests', () {
    test('Set and get list properties', () async {
      final graph = await Graph.openInMemory();
      try {
        final vertex = await graph.transaction((txn) async {
          return txn.createVertex(Vertex(
            labels: {'Person'},
            properties: {
              'name': 'Alice',
              'tags': ['developer', 'engineer', 'tech'],
              'scores': [85, 92, 78],
              'flags': [true, false, true],
              'mixed': ['text', 42, true],
            },
          ));
        });

        // Verify list property retrieval
        expect(vertex.getProperty('tags'),
            equals(['developer', 'engineer', 'tech']));
        expect(vertex.getProperty('scores'), equals([85, 92, 78]));
        expect(vertex.getProperty('flags'), equals([true, false, true]));
        expect(vertex.getProperty('mixed'), equals(['text', 42, true]));

        // Retrieve from database and verify
        final retrievedVertex = await graph.transaction((txn) async {
          return txn.getVertex(vertex.id!);
        });
        expect(retrievedVertex!.getProperty('tags'),
            equals(['developer', 'engineer', 'tech']));
        expect(retrievedVertex.getProperty('scores'), equals([85, 92, 78]));
        expect(
            retrievedVertex.getProperty('flags'), equals([true, false, true]));
        expect(
            retrievedVertex.getProperty('mixed'), equals(['text', 42, true]));
      } finally {
        await graph.close();
      }
    });

    test('Empty list property', () async {
      final graph = await Graph.openInMemory();
      try {
        final vertex = await graph.transaction((txn) async {
          return txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'empty_list': <dynamic>[],
            },
          ));
        });

        expect(vertex.getProperty('empty_list'), equals([]));

        // Retrieve from database and verify
        final retrievedVertex = await graph.transaction((txn) async {
          return txn.getVertex(vertex.id!);
        });
        expect(retrievedVertex!.getProperty('empty_list'), equals([]));
      } finally {
        await graph.close();
      }
    });

    test('Update list property', () async {
      final graph = await Graph.openInMemory();
      try {
        final vertex = await graph.transaction((txn) async {
          return txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'items': ['a', 'b'],
            },
          ));
        });

        // Update property
        vertex.setProperty('items', ['x', 'y', 'z']);
        await graph.transaction((txn) async {
          await txn.updateVertex(vertex);
        });

        // Retrieve from database and verify
        final retrievedVertex = await graph.transaction((txn) async {
          return txn.getVertex(vertex.id!);
        });
        expect(retrievedVertex!.getProperty('items'), equals(['x', 'y', 'z']));
      } finally {
        await graph.close();
      }
    });

    test('List property for edges', () async {
      final graph = await Graph.openInMemory();
      try {
        final (vertex1, vertex2, edge) = await graph.transaction((txn) async {
          final v1 = await txn.createVertex(Vertex(labels: {'Person'}));
          final v2 = await txn.createVertex(Vertex(labels: {'Person'}));

          final e = await txn.createEdge(Edge(
            fromVertexId: v1.id!,
            toVertexId: v2.id!,
            labels: {'KNOWS'},
            properties: {
              'contexts': ['work', 'school', 'hobby'],
              'years': [2020, 2021, 2022],
            },
          ));

          return (v1, v2, e);
        });

        expect(
            edge.getProperty('contexts'), equals(['work', 'school', 'hobby']));
        expect(edge.getProperty('years'), equals([2020, 2021, 2022]));

        // Retrieve from database and verify
        final retrievedEdge = await graph.transaction((txn) async {
          return txn.getEdge(edge.id!);
        });
        expect(retrievedEdge!.getProperty('contexts'),
            equals(['work', 'school', 'hobby']));
        expect(retrievedEdge.getProperty('years'), equals([2020, 2021, 2022]));
      } finally {
        await graph.close();
      }
    });

    property('Random test for list properties', () {
      forAll(
        ArbitraryTestHelpers.listProperty(),
        (listProperty) async {
          final graph = await Graph.openInMemory();
          try {
            final vertex = await graph.transaction((txn) async {
              return txn.createVertex(Vertex(
                labels: {'Test'},
                properties: {'list_prop': listProperty},
              ));
            });

            expect(vertex.getProperty('list_prop'), equals(listProperty));

            // Retrieve from database and verify
            final retrievedVertex = await graph.transaction((txn) async {
              return txn.getVertex(vertex.id!);
            });
            expect(retrievedVertex!.getProperty('list_prop'),
                equals(listProperty));
          } finally {
            await graph.close();
          }
        },
      );
    });

    test('Type checking for list properties', () async {
      final graph = await Graph.openInMemory();
      try {
        final vertex = await graph.transaction((txn) async {
          return txn.createVertex(Vertex(
            labels: {'Test'},
            properties: {
              'tags': ['a', 'b', 'c'],
            },
          ));
        });

        expect(vertex.getPropertyType('tags'), equals(DatabaseValueType.list));
      } finally {
        await graph.close();
      }
    });
  });
}
