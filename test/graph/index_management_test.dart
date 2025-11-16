import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Index Management API Tests', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('IndexEntityType enum values', () {
      expect(IndexEntityType.values.length, equals(3));
      expect(IndexEntityType.vertices, isNotNull);
      expect(IndexEntityType.edges, isNotNull);
      expect(IndexEntityType.both, isNotNull);
    });

    test('PropertyIndexInfo creation', () {
      const info = PropertyIndexInfo(
        name: 'test_index',
        propertyKey: 'name',
        entityType: IndexEntityType.vertices,
      );

      expect(info.name, equals('test_index'));
      expect(info.propertyKey, equals('name'));
      expect(info.entityType, equals(IndexEntityType.vertices));
    });

    test('PropertyIndexInfo equality', () {
      const info1 = PropertyIndexInfo(
        name: 'test_index',
        propertyKey: 'name',
        entityType: IndexEntityType.vertices,
      );

      const info2 = PropertyIndexInfo(
        name: 'test_index',
        propertyKey: 'name',
        entityType: IndexEntityType.vertices,
      );

      const info3 = PropertyIndexInfo(
        name: 'different_index',
        propertyKey: 'name',
        entityType: IndexEntityType.vertices,
      );

      expect(info1, equals(info2));
      expect(info1, isNot(equals(info3)));
    });

    test('createPropertyIndex with invalid property key throws ArgumentError',
        () async {
      expect(
        () => graph.createPropertyIndex(''),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => graph.createPropertyIndex("invalid'key"),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createPropertyIndex with invalid index name throws ArgumentError',
        () async {
      expect(
        () => graph.createPropertyIndex('valid_key', indexName: ''),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => graph.createPropertyIndex('valid_key', indexName: "invalid'name"),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
        'createPropertyIndex throws UnimplementedError (current implementation)',
        () async {
      expect(
        () => graph.createPropertyIndex('name'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('dropPropertyIndex with invalid index name throws ArgumentError',
        () async {
      expect(
        () => graph.dropPropertyIndex(''),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => graph.dropPropertyIndex("invalid'name"),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('dropPropertyIndex throws UnimplementedError (current implementation)',
        () async {
      expect(
        () => graph.dropPropertyIndex('valid_name'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('listPropertyIndexes returns empty list (current implementation)',
        () async {
      final indexes = await graph.listPropertyIndexes();
      expect(indexes, isEmpty);
      expect(indexes, isA<List<PropertyIndexInfo>>());
    });

    test('hasPropertyIndex with invalid property key throws ArgumentError',
        () async {
      expect(
        () => graph.hasPropertyIndex(''),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => graph.hasPropertyIndex("invalid'key"),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('hasPropertyIndex returns false (current implementation)', () async {
      final hasIndex = await graph.hasPropertyIndex('name');
      expect(hasIndex, isFalse);
    });

    test('hasPropertyIndex with different entity types', () async {
      final hasVertexIndex = await graph.hasPropertyIndex(
        'name',
      );
      expect(hasVertexIndex, isFalse);

      final hasEdgeIndex = await graph.hasPropertyIndex(
        'weight',
        entityType: IndexEntityType.edges,
      );
      expect(hasEdgeIndex, isFalse);
    });
  });

  group('IndexManagementUtils Tests', () {
    test('generateIndexName for vertices', () {
      final name = IndexManagementUtils.generateIndexName(
          'name', IndexEntityType.vertices);
      expect(name, equals('idx_user_v_name'));
    });

    test('generateIndexName for edges', () {
      final name = IndexManagementUtils.generateIndexName(
          'weight', IndexEntityType.edges);
      expect(name, equals('idx_user_e_weight'));
    });

    test('generateIndexName for both', () {
      final name =
          IndexManagementUtils.generateIndexName('type', IndexEntityType.both);
      expect(name, equals('idx_user_both_type'));
    });

    test('isValidPropertyKey validation', () {
      expect(IndexManagementUtils.isValidPropertyKey('name'), isTrue);
      expect(IndexManagementUtils.isValidPropertyKey('_s_entity_id'), isTrue);
      expect(IndexManagementUtils.isValidPropertyKey('user123'), isTrue);

      expect(IndexManagementUtils.isValidPropertyKey(''), isFalse);
      expect(IndexManagementUtils.isValidPropertyKey("invalid'key"), isFalse);
      expect(IndexManagementUtils.isValidPropertyKey('invalid"key'), isFalse);
    });

    test('isValidIndexName validation', () {
      expect(IndexManagementUtils.isValidIndexName('idx_name'), isTrue);
      expect(IndexManagementUtils.isValidIndexName('user_index_123'), isTrue);

      expect(IndexManagementUtils.isValidIndexName(''), isFalse);
      expect(IndexManagementUtils.isValidIndexName('invalid name'), isFalse);
      expect(IndexManagementUtils.isValidIndexName("invalid'name"), isFalse);
      expect(IndexManagementUtils.isValidIndexName('invalid"name'), isFalse);

      // Name too long
      final longName = 'a' * 65;
      expect(IndexManagementUtils.isValidIndexName(longName), isFalse);
    });

    test('generateCreateIndexSQL for vertices', () {
      final sql = IndexManagementUtils.generateCreateIndexSQL(
        'idx_name',
        'name',
        IndexEntityType.vertices,
      );
      expect(
          sql, contains('CREATE INDEX idx_name ON vertex_properties(value)'));
      expect(sql, contains('WHERE key = ?'));
    });

    test('generateCreateIndexSQL for edges', () {
      final sql = IndexManagementUtils.generateCreateIndexSQL(
        'idx_weight',
        'weight',
        IndexEntityType.edges,
      );
      expect(
          sql, contains('CREATE INDEX idx_weight ON edge_properties(value)'));
      expect(sql, contains('WHERE key = ?'));
    });

    test('generateCreateIndexSQL for both throws UnimplementedError', () {
      expect(
        () => IndexManagementUtils.generateCreateIndexSQL(
          'idx_type',
          'type',
          IndexEntityType.both,
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('generateDropIndexSQL', () {
      final sql = IndexManagementUtils.generateDropIndexSQL('idx_name');
      expect(sql, equals('DROP INDEX IF EXISTS idx_name'));
    });
  });
}
