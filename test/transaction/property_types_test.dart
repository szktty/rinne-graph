import 'package:kiri_check/kiri_check.dart';
import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

import '../helpers/arbitrary.dart';

void main() {
  group('Vertex', () {
    property('Null', () {
      forAll(
        ArbitraryTestHelpers.identifierString(),
        (key) async {
          await testVertexPropertyType(key, null, null);
        },
      );
    });

    property('String', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.identifierString(),
          ArbitraryTestHelpers.propertyString(),
          ArbitraryTestHelpers.propertyString(),
        ),
        (args) async {
          await testVertexPropertyType(args.$1, args.$2, args.$3);
        },
      );
    });

    property('Int', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.identifierString(),
          integer(),
          integer(),
        ),
        (args) async {
          await testVertexPropertyType(args.$1, args.$2, args.$3);
        },
      );
    });

    property('Double', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.identifierString(),
          float(),
          float(),
        ),
        (args) async {
          await testVertexPropertyType(args.$1, args.$2, args.$3);
        },
      );
    });

    property('Bool', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.identifierString(),
          boolean(),
          boolean(),
        ),
        (args) async {
          await testVertexPropertyType(args.$1, args.$2, args.$3);
        },
      );
    });

    property('DateTime', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.identifierString(),
          ArbitraryTestHelpers.propertyDateTime(),
          ArbitraryTestHelpers.propertyDateTime(),
        ),
        (args) async {
          await testVertexPropertyType(args.$1, args.$2, args.$3);
        },
      );
    });

    property('Random', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.identifierString(),
          ArbitraryTestHelpers.propertyValue(),
          ArbitraryTestHelpers.propertyValue(),
        ),
        (args) async {
          await testVertexPropertyType(args.$1, args.$2, args.$3);
        },
      );
    });
  });

  group('Edge', () {
    property('Null', () {
      forAll(
        ArbitraryTestHelpers.identifierString(),
        (key) async {
          await testEdgePropertyType(key, null, null);
        },
      );
    });

    property('String', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.identifierString(),
          ArbitraryTestHelpers.propertyString(),
          ArbitraryTestHelpers.propertyString(),
        ),
        (args) async {
          await testEdgePropertyType(args.$1, args.$2, args.$3);
        },
      );
    });

    property('Int', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.identifierString(),
          integer(),
          integer(),
        ),
        (args) async {
          await testEdgePropertyType(args.$1, args.$2, args.$3);
        },
      );
    });

    property('Double', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.identifierString(),
          float(),
          float(),
        ),
        (args) async {
          await testEdgePropertyType(args.$1, args.$2, args.$3);
        },
      );
    });

    property('Bool', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.identifierString(),
          boolean(),
          boolean(),
        ),
        (args) async {
          await testEdgePropertyType(args.$1, args.$2, args.$3);
        },
      );
    });

    property('DateTime', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.identifierString(),
          ArbitraryTestHelpers.propertyDateTime(),
          ArbitraryTestHelpers.propertyDateTime(),
        ),
        (args) async {
          await testEdgePropertyType(args.$1, args.$2, args.$3);
        },
      );
    });

    property('Random', () {
      forAll(
        combine3(
          ArbitraryTestHelpers.identifierString(),
          ArbitraryTestHelpers.propertyValue(),
          ArbitraryTestHelpers.propertyValue(),
        ),
        (args) async {
          await testEdgePropertyType(args.$1, args.$2, args.$3);
        },
      );
    });
  });
}

Future<void> testVertexPropertyType(
  String key,
  dynamic value1,
  dynamic value2,
) async {
  final db = await DatabaseManager().openInMemory();
  await db.transaction((txn) async {
    final vertex = Vertex(properties: {key: value1});
    final createdVertex = await txn.createVertex(vertex);
    final retrievedVertex = await txn.getVertex(createdVertex.id!);
    if (value1 == null) {
      expect(retrievedVertex!.properties[key], isA<NullValue>());
    } else {
      expect(retrievedVertex!.properties[key], equals(value1));
    }

    retrievedVertex.setProperty(key, value2);
    await txn.updateVertex(retrievedVertex);
    final updatedVertex = await txn.getVertex(retrievedVertex.id!);
    if (value2 == null) {
      expect(updatedVertex!.properties[key], isA<NullValue>());
    } else {
      expect(updatedVertex!.properties[key], equals(value2));
    }
  });
  await db.close();
}

Future<void> testEdgePropertyType(
  String key,
  dynamic value1,
  dynamic value2,
) async {
  final db = await DatabaseManager().openInMemory();
  await db.transaction((txn) async {
    final vertex1 = await txn.createVertex(Vertex());
    final vertex2 = await txn.createVertex(Vertex());
    final edge = Edge(
      fromVertexId: vertex1.id!,
      toVertexId: vertex2.id!,
      properties: {key: value1},
    );
    final createdEdge = await txn.createEdge(edge);
    final retrievedEdge = await txn.getEdge(createdEdge.id!);
    if (value1 == null) {
      expect(retrievedEdge!.properties[key], isA<NullValue>());
    } else {
      expect(retrievedEdge!.properties[key], equals(value1));
    }

    retrievedEdge.setProperty(key, value2);
    await txn.updateEdge(retrievedEdge);
    final updatedEdge = await txn.getEdge(retrievedEdge.id!);
    if (value2 == null) {
      expect(updatedEdge!.properties[key], isA<NullValue>());
    } else {
      expect(updatedEdge!.properties[key], equals(value2));
    }
  });
  await db.close();
}
