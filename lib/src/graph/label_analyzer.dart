import 'package:rinne_graph/src/graph/graph_intf.dart';
import 'package:rinne_graph/src/graph/label_statistics.dart';

/// Class providing label analysis functionality
class LabelAnalyzer {
  LabelAnalyzer(this._graph);
  final Graph _graph;

  /// Label combination analysis
  ///
  /// Analyzes combination patterns of entities with multiple labels.
  Future<Map<Set<String>, int>> analyzeLabelCombinations() async {
    final combinations = <Set<String>, int>{};

    // Analyze vertex combinations
    await _graph.transaction((txn) async {
      await for (final vertex in txn.vertices()) {
        if (vertex.labels.length > 1) {
          combinations[vertex.labels] = (combinations[vertex.labels] ?? 0) + 1;
        }
      }

      // Analyze edge combinations
      await for (final edge in txn.edges()) {
        if (edge.labels.length > 1) {
          combinations[edge.labels] = (combinations[edge.labels] ?? 0) + 1;
        }
      }
    });

    return combinations;
  }

  /// Label relationship analysis
  ///
  /// Analyzes relationships between labels connected through edges.
  Future<Map<String, Map<String, int>>> analyzeLabelRelationships() async {
    final relationships = <String, Map<String, int>>{};

    // Analyze relationships between labels connected through edges
    await _graph.transaction((txn) async {
      await for (final edge in txn.edges()) {
        // Get source and target vertices
        final fromVertex = await txn.getVertex(edge.fromVertexId);
        final toVertex = await txn.getVertex(edge.toVertexId);

        if (fromVertex != null && toVertex != null) {
          // Count relationships
          for (final fromLabel in fromVertex.labels) {
            for (final toLabel in toVertex.labels) {
              relationships.putIfAbsent(fromLabel, () => {});
              relationships[fromLabel]![toLabel] =
                  (relationships[fromLabel]![toLabel] ?? 0) + 1;
            }
          }
        }
      }
    });

    return relationships;
  }

  /// Unused label detection
  ///
  /// Detects labels that are defined but not used.
  Future<List<String>> findUnusedLabels() async {
    final stats = await _graph.getStatistics();
    final usedVertexLabels = stats.vertexLabelCounts.keys.toSet();
    final usedEdgeLabels = stats.edgeLabelCounts.keys.toSet();

    // Currently returns only used labels
    // In the future, compare with label definition table
    final allUsedLabels = <String>{};
    allUsedLabels.addAll(usedVertexLabels);
    allUsedLabels.addAll(usedEdgeLabels);

    // Treat labels with 0 usage as unused
    final unusedLabels = <String>[];
    stats.vertexLabelCounts.forEach((label, count) {
      if (count == 0) {
        unusedLabels.add(label);
      }
    });
    stats.edgeLabelCounts.forEach((label, count) {
      if (count == 0 && !unusedLabels.contains(label)) {
        unusedLabels.add(label);
      }
    });

    return unusedLabels;
  }

  /// Label usage analysis
  ///
  /// Analyzes detailed usage status of each label.
  Future<Map<String, LabelUsageInfo>> analyzeLabelUsage() async {
    final stats = await _graph.getStatistics();
    final usageInfo = <String, LabelUsageInfo>{};

    final totalVertices = stats.totalVertices;
    final totalEdges = stats.totalEdges;
    final totalEntities = totalVertices + totalEdges;

    // Collect all labels
    final allLabels = <String>{};
    allLabels.addAll(stats.vertexLabelCounts.keys);
    allLabels.addAll(stats.edgeLabelCounts.keys);

    for (final label in allLabels) {
      final vertexCount = stats.vertexLabelCounts[label] ?? 0;
      final edgeCount = stats.edgeLabelCounts[label] ?? 0;
      final totalCount = vertexCount + edgeCount;

      final usageFrequency =
          totalEntities > 0 ? totalCount / totalEntities : 0.0;

      usageInfo[label] = LabelUsageInfo(
        label: label,
        vertexCount: vertexCount,
        edgeCount: edgeCount,
        usageFrequency: usageFrequency,
        // TODO(szktty): Implement actual creation and update timestamp retrieval.
      );
    }

    return usageInfo;
  }

  /// Generate comprehensive label analysis report
  Future<LabelAnalysisReport> generateReport() async {
    final stats = await _graph.getStatistics();
    final combinations = await analyzeLabelCombinations();
    final relationships = await analyzeLabelRelationships();

    return LabelAnalysisReport(
      totalVertices: stats.totalVertices,
      totalEdges: stats.totalEdges,
      vertexLabelCounts: stats.vertexLabelCounts,
      edgeLabelCounts: stats.edgeLabelCounts,
      labelCombinations: combinations,
      labelRelationships: relationships,
    );
  }

  /// Detect underutilized labels
  Future<List<String>> findUnderutilizedLabels(
      {double threshold = 0.01}) async {
    final usageInfo = await analyzeLabelUsage();

    return usageInfo.entries
        .where((entry) => entry.value.usageFrequency < threshold)
        .map((entry) => entry.key)
        .toList();
  }

  /// Detect popular labels
  Future<List<String>> findPopularLabels({double threshold = 0.1}) async {
    final usageInfo = await analyzeLabelUsage();

    return usageInfo.entries
        .where((entry) => entry.value.usageFrequency >= threshold)
        .map((entry) => entry.key)
        .toList();
  }

  /// Analyze label distribution
  Future<Map<String, double>> analyzeVertexLabelDistribution() async {
    final stats = await _graph.getStatistics();
    return LabelDistributionChart.calculateDistribution(
      stats.vertexLabelCounts,
      stats.totalVertices,
    );
  }

  /// Analyze edge label distribution
  Future<Map<String, double>> analyzeEdgeLabelDistribution() async {
    final stats = await _graph.getStatistics();
    return LabelDistributionChart.calculateDistribution(
      stats.edgeLabelCounts,
      stats.totalEdges,
    );
  }

  /// Get top labels
  Future<List<MapEntry<String, int>>> getTopVertexLabels(int limit) async {
    final stats = await _graph.getStatistics();
    return LabelDistributionChart.getTopLabels(
      stats.vertexLabelCounts,
      limit,
    );
  }

  /// Get top edge labels
  Future<List<MapEntry<String, int>>> getTopEdgeLabels(int limit) async {
    final stats = await _graph.getStatistics();
    return LabelDistributionChart.getTopLabels(
      stats.edgeLabelCounts,
      limit,
    );
  }

  /// Build relationship network
  Future<Map<String, List<String>>> buildLabelNetwork({
    int minConnections = 1,
  }) async {
    final relationships = await analyzeLabelRelationships();
    return LabelRelationshipNetwork.buildNetwork(
      relationships,
      minConnections,
    );
  }

  /// Detect bidirectional relationships
  Future<Map<String, List<String>>> findBidirectionalRelationships({
    int minConnections = 1,
  }) async {
    final relationships = await analyzeLabelRelationships();
    return LabelRelationshipNetwork.findBidirectionalRelationships(
      relationships,
      minConnections,
    );
  }
}
