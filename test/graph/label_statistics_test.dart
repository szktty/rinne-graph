import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Label Statistics', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('should analyze label combinations', () async {
      // Create test data
      await graph.transaction((txn) async {
        // Create vertices with multiple labels
        await txn.createVertex(Vertex(
          labels: {'person', 'user'},
          properties: {'name': 'Alice'},
        ));

        await txn.createVertex(Vertex(
          labels: {'person', 'admin'},
          properties: {'name': 'Bob'},
        ));

        await txn.createVertex(Vertex(
          labels: {'person', 'user', 'premium'},
          properties: {'name': 'Charlie'},
        ));

        // Vertex with single label
        await txn.createVertex(Vertex(
          labels: {'company'},
          properties: {'name': 'ACME Corp'},
        ));
      });

      // Analyze label combinations
      final analyzer = graph.labelAnalyzer;
      final combinations = await analyzer.analyzeLabelCombinations();

      // Verify results
      expect(combinations.length, equals(3));

      // Verify each combination exists
      var foundPersonUser = false;
      var foundPersonAdmin = false;
      var foundPersonUserPremium = false;

      combinations.forEach((labels, count) {
        if (labels.contains('person') &&
            labels.contains('user') &&
            labels.length == 2) {
          foundPersonUser = true;
          expect(count, equals(1));
        } else if (labels.contains('person') &&
            labels.contains('admin') &&
            labels.length == 2) {
          foundPersonAdmin = true;
          expect(count, equals(1));
        } else if (labels.contains('person') &&
            labels.contains('user') &&
            labels.contains('premium') &&
            labels.length == 3) {
          foundPersonUserPremium = true;
          expect(count, equals(1));
        }
      });

      expect(foundPersonUser, isTrue);
      expect(foundPersonAdmin, isTrue);
      expect(foundPersonUserPremium, isTrue);

      // Single labels are not included
      expect(combinations.keys.any((labels) => labels.length == 1), isFalse);
    });

    test('should analyze label usage', () async {
      // Create test data
      await graph.transaction((txn) async {
        // Create vertices
        await txn.createVertex(Vertex(labels: {'person'}));
        await txn.createVertex(Vertex(labels: {'person'}));
        await txn.createVertex(Vertex(labels: {'company'}));

        // Create edges
        final vertex1 = await txn.createVertex(Vertex(labels: {'person'}));
        final vertex2 = await txn.createVertex(Vertex(labels: {'person'}));

        await txn.createEdge(Edge(
          fromVertexId: vertex1.id!,
          toVertexId: vertex2.id!,
          labels: {'knows'},
        ));

        await txn.createEdge(Edge(
          fromVertexId: vertex1.id!,
          toVertexId: vertex2.id!,
          labels: {'knows'},
        ));
      });

      // Analyze label usage
      final analyzer = graph.labelAnalyzer;
      final usageInfo = await analyzer.analyzeLabelUsage();

      // Verify results
      expect(usageInfo.containsKey('person'), isTrue);
      expect(usageInfo.containsKey('company'), isTrue);
      expect(usageInfo.containsKey('knows'), isTrue);

      final personUsage = usageInfo['person']!;
      expect(personUsage.vertexCount, equals(4));
      expect(personUsage.edgeCount, equals(0));
      expect(personUsage.totalCount, equals(4));

      final knowsUsage = usageInfo['knows']!;
      expect(knowsUsage.vertexCount, equals(0));
      expect(knowsUsage.edgeCount, equals(2));
      expect(knowsUsage.totalCount, equals(2));
    });

    test('should find popular and underutilized labels', () async {
      // Create test data (create many vertices)
      await graph.transaction((txn) async {
        // Popular label (heavily used)
        for (var i = 0; i < 50; i++) {
          await txn.createVertex(Vertex(labels: {'popular'}));
        }

        // Normal label (moderately used)
        for (var i = 0; i < 10; i++) {
          await txn.createVertex(Vertex(labels: {'normal'}));
        }

        // Underutilized label (rarely used)
        await txn.createVertex(Vertex(labels: {'rare'}));
      });

      final analyzer = graph.labelAnalyzer;

      // Detect popular labels (10% or more)
      final popularLabels = await analyzer.findPopularLabels();
      expect(popularLabels, contains('popular'));
      expect(popularLabels, isNot(contains('rare')));

      // Detect underutilized labels (less than 5%)
      final underutilizedLabels =
          await analyzer.findUnderutilizedLabels(threshold: 0.05);
      expect(underutilizedLabels, contains('rare'));
      expect(underutilizedLabels, isNot(contains('popular')));
    });

    test('should analyze label relationships', () async {
      // Create test data
      late Vertex alice;
      late Vertex bob;
      late Vertex company;
      await graph.transaction((txn) async {
        alice = await txn.createVertex(Vertex(
          labels: {'person', 'employee'},
          properties: {'name': 'Alice'},
        ));

        bob = await txn.createVertex(Vertex(
          labels: {'person', 'manager'},
          properties: {'name': 'Bob'},
        ));

        company = await txn.createVertex(Vertex(
          labels: {'company'},
          properties: {'name': 'ACME Corp'},
        ));

        // Create relationships
        await txn.createEdge(Edge(
          fromVertexId: alice.id!,
          toVertexId: bob.id!,
          labels: {'reports_to'},
        ));

        await txn.createEdge(Edge(
          fromVertexId: alice.id!,
          toVertexId: company.id!,
          labels: {'works_for'},
        ));

        await txn.createEdge(Edge(
          fromVertexId: bob.id!,
          toVertexId: company.id!,
          labels: {'works_for'},
        ));
      });

      // Analyze label relationships
      final analyzer = graph.labelAnalyzer;
      final relationships = await analyzer.analyzeLabelRelationships();

      // Verify results
      expect(relationships.containsKey('person'), isTrue);
      expect(relationships.containsKey('employee'), isTrue);
      expect(relationships.containsKey('manager'), isTrue);

      // person -> company relationship
      expect(relationships['person']!.containsKey('company'), isTrue);
      expect(relationships['person']!['company'], greaterThan(0));

      // employee -> manager relationship
      expect(relationships['employee']!.containsKey('manager'), isTrue);
      expect(relationships['employee']!['manager'], equals(1));
    });

    test('should generate comprehensive analysis report', () async {
      // Create test data
      await graph.transaction((txn) async {
        final alice = await txn.createVertex(Vertex(
          labels: {'person', 'user'},
          properties: {'name': 'Alice'},
        ));

        final bob = await txn.createVertex(Vertex(
          labels: {'person', 'admin'},
          properties: {'name': 'Bob'},
        ));

        await txn.createEdge(Edge(
          fromVertexId: alice.id!,
          toVertexId: bob.id!,
          labels: {'knows'},
        ));
      });

      // Generate comprehensive report
      final analyzer = graph.labelAnalyzer;
      final report = await analyzer.generateReport();

      // Verify results
      expect(report.totalVertices, equals(2));
      expect(report.totalEdges, equals(1));
      expect(report.vertexLabelCounts.length, greaterThan(0));
      expect(report.edgeLabelCounts.length, greaterThan(0));
      expect(report.labelCombinations.length, greaterThan(0));
      expect(report.labelRelationships.length, greaterThan(0));
      expect(report.generatedAt, isA<DateTime>());

      // Verify summary
      final summary = report.getSummary();
      expect(summary['totalVertices'], equals(2));
      expect(summary['totalEdges'], equals(1));
      expect(summary['generatedAt'], isA<String>());
    });

    test('should calculate label distributions', () async {
      // Create test data
      await graph.transaction((txn) async {
        // Create labels with different ratios
        for (var i = 0; i < 6; i++) {
          await txn.createVertex(Vertex(labels: {'common'}));
        }

        for (var i = 0; i < 3; i++) {
          await txn.createVertex(Vertex(labels: {'uncommon'}));
        }

        await txn.createVertex(Vertex(labels: {'rare'}));
      });

      final analyzer = graph.labelAnalyzer;

      // Analyze vertex label distribution
      final distribution = await analyzer.analyzeVertexLabelDistribution();

      // Verify results
      expect(distribution['common'], closeTo(60.0, 0.1)); // 6/10 = 60%
      expect(distribution['uncommon'], closeTo(30.0, 0.1)); // 3/10 = 30%
      expect(distribution['rare'], closeTo(10.0, 0.1)); // 1/10 = 10%

      // Get top labels
      final topLabels = await analyzer.getTopVertexLabels(2);
      expect(topLabels.length, equals(2));
      expect(topLabels[0].key, equals('common'));
      expect(topLabels[0].value, equals(6));
      expect(topLabels[1].key, equals('uncommon'));
      expect(topLabels[1].value, equals(3));
    });

    test('should build label network', () async {
      // Create test data
      late Vertex alice;
      late Vertex bob;
      late Vertex charlie;
      await graph.transaction((txn) async {
        alice = await txn.createVertex(Vertex(labels: {'person'}));
        bob = await txn.createVertex(Vertex(labels: {'person'}));
        charlie = await txn.createVertex(Vertex(labels: {'company'}));

        // Create network
        await txn.createEdge(Edge(
          fromVertexId: alice.id!,
          toVertexId: bob.id!,
          labels: {'knows'},
        ));

        await txn.createEdge(Edge(
          fromVertexId: alice.id!,
          toVertexId: charlie.id!,
          labels: {'works_for'},
        ));

        await txn.createEdge(Edge(
          fromVertexId: bob.id!,
          toVertexId: charlie.id!,
          labels: {'works_for'},
        ));
      });

      final analyzer = graph.labelAnalyzer;

      // Build label network
      final network = await analyzer.buildLabelNetwork();

      // Verify results
      expect(network.containsKey('person'), isTrue);
      expect(network['person'], contains('person')); // person -> person
      expect(network['person'], contains('company')); // person -> company
    });
  });
}
