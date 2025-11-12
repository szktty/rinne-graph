import 'package:rinne_graph/rinne_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Label Events', () {
    late Graph graph;

    setUp(() async {
      graph = await Graph.openInMemory();
    });

    tearDown(() async {
      await graph.close();
    });

    test('should fire vertex label events on vertex creation', () async {
      final events = <VertexLabelEvent>[];

      // Register event listener
      graph.onVertexLabelEvent(events.add);

      // Create vertex
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
          labels: {'person', 'user'},
          properties: {'name': 'Alice'},
        ));
      });

      // Verify events were fired
      expect(events.length, equals(2));

      // First event
      expect(events[0].label, equals('person'));
      expect(events[0].eventType, equals(LabelEventType.added));
      expect(events[0].allLabels, containsAll(['person', 'user']));
      expect(events[0].vertexId, isA<int>());
      expect(events[0].transactionId, isNotEmpty);
      expect(events[0].timestamp, isA<DateTime>());

      // Second event
      expect(events[1].label, equals('user'));
      expect(events[1].eventType, equals(LabelEventType.added));
      expect(events[1].allLabels, containsAll(['person', 'user']));
      expect(events[1].vertexId, equals(events[0].vertexId));
      expect(events[1].transactionId, equals(events[0].transactionId));
    });

    test('should fire edge label events on edge creation', () async {
      final events = <EdgeLabelEvent>[];

      // Register event listener
      graph.onEdgeLabelEvent(events.add);

      // Create vertices
      late Vertex vertex1;
      late Vertex vertex2;
      await graph.transaction((txn) async {
        vertex1 = await txn.createVertex(Vertex(
          labels: {'person'},
          properties: {'name': 'Alice'},
        ));
        vertex2 = await txn.createVertex(Vertex(
          labels: {'person'},
          properties: {'name': 'Bob'},
        ));
      });

      // Create edges
      await graph.transaction((txn) async {
        await txn.createEdge(Edge(
          fromVertexId: vertex1.id!,
          toVertexId: vertex2.id!,
          labels: {'knows', 'friend'},
        ));
      });

      // Verify events were fired
      expect(events.length, equals(2));

      // First event
      expect(events[0].label, equals('knows'));
      expect(events[0].eventType, equals(LabelEventType.added));
      expect(events[0].allLabels, containsAll(['knows', 'friend']));
      expect(events[0].edgeId, isA<int>());
      expect(events[0].transactionId, isNotEmpty);

      // 2nd event
      expect(events[1].label, equals('friend'));
      expect(events[1].eventType, equals(LabelEventType.added));
      expect(events[1].allLabels, containsAll(['knows', 'friend']));
      expect(events[1].edgeId, equals(events[0].edgeId));
      expect(events[1].transactionId, equals(events[0].transactionId));
    });

    test('should handle multiple listeners', () async {
      final events1 = <VertexLabelEvent>[];
      final events2 = <VertexLabelEvent>[];

      // Register multiple listeners
      graph.onVertexLabelEvent(events1.add);

      graph.onVertexLabelEvent(events2.add);

      // Create vertex
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
          labels: {'test'},
          properties: {'name': 'Test'},
        ));
      });

      // Verify events were received by both listeners
      expect(events1.length, equals(1));
      expect(events2.length, equals(1));
      expect(events1[0].label, equals('test'));
      expect(events2[0].label, equals('test'));
    });

    test('should handle listener removal', () async {
      final events = <VertexLabelEvent>[];

      void listener(VertexLabelEvent event) {
        events.add(event);
      }

      // Register listener
      graph.onVertexLabelEvent(listener);

      // Create vertex
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
          labels: {'test1'},
        ));
      });

      expect(events.length, equals(1));

      // Remove listener
      graph.eventManager.removeEventListener<VertexLabelEvent>(listener);

      // Create another vertex
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
          labels: {'test2'},
        ));
      });

      // Verify no events were added
      expect(events.length, equals(1));
    });

    test('should handle callback errors gracefully', () async {
      var callbackExecuted = false;

      // Register listener that throws error
      graph.onVertexLabelEvent((event) {
        throw Exception('Test error');
      });

      // Also register normal listener
      graph.onVertexLabelEvent((event) {
        callbackExecuted = true;
      });

      // Create vertex (transaction should succeed even if error occurs)
      await graph.transaction((txn) async {
        await txn.createVertex(Vertex(
          labels: {'test'},
        ));
      });

      // The normal listener should have been executed
      expect(callbackExecuted, isTrue);
    });

    test('should provide event manager debug info', () async {
      // Register listeners
      graph.onVertexLabelEvent((event) {});
      graph.onEdgeLabelEvent((event) {});

      // Cast to internal implementation to get debug info
      if (graph.eventManager is GraphEventManagerImpl) {
        final debugInfo =
            (graph.eventManager as GraphEventManagerImpl).getDebugInfo();

        expect(debugInfo['totalListeners'], equals(2));
        expect(debugInfo['eventTypes'], isA<Map<String, dynamic>>());
      }
    });
  });
}
