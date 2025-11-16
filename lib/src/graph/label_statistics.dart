/// Extended functionality for label statistics
///
/// Provides more detailed analysis capabilities in addition to basic label statistics.
library;

/// Label usage information
class LabelUsageInfo {
  // Usage frequency (0.0-1.0)

  LabelUsageInfo({
    required this.label,
    required this.vertexCount,
    required this.edgeCount,
    required this.usageFrequency,
    this.firstUsed,
    this.lastUsed,
  }) : totalCount = vertexCount + edgeCount;
  final String label;
  final int vertexCount;
  final int edgeCount;
  final int totalCount;
  final DateTime? firstUsed;
  final DateTime? lastUsed;
  final double usageFrequency;

  @override
  String toString() {
    return 'LabelUsageInfo(label: $label, vertexCount: $vertexCount, '
        'edgeCount: $edgeCount, totalCount: $totalCount, '
        'usageFrequency: ${(usageFrequency * 100).toStringAsFixed(1)}%)';
  }

  @override
  // Cannot apply @immutable due to computed properties
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LabelUsageInfo &&
        other.label == label &&
        other.vertexCount == vertexCount &&
        other.edgeCount == edgeCount &&
        other.firstUsed == firstUsed &&
        other.lastUsed == lastUsed &&
        other.usageFrequency == usageFrequency;
  }

  @override
  // Cannot apply @immutable due to computed properties
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode {
    return Object.hash(
      label,
      vertexCount,
      edgeCount,
      firstUsed,
      lastUsed,
      usageFrequency,
    );
  }
}

/// Extended label statistics
class LabelStatistics {
  LabelStatistics({
    required this.vertexLabelCounts,
    required this.edgeLabelCounts,
    required this.labelUsageInfo,
    required this.unusedLabels,
    required this.labelCombinations,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
  final Map<String, int> vertexLabelCounts;
  final Map<String, int> edgeLabelCounts;
  final Map<String, LabelUsageInfo> labelUsageInfo;
  final List<String> unusedLabels;
  final Map<Set<String>, int> labelCombinations;
  final DateTime generatedAt;

  /// Get most used vertex label
  String? get mostUsedVertexLabel {
    if (vertexLabelCounts.isEmpty) return null;
    return vertexLabelCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get most used edge label
  String? get mostUsedEdgeLabel {
    if (edgeLabelCounts.isEmpty) return null;
    return edgeLabelCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get underutilized labels
  List<String> getUnderutilizedLabels(double threshold) {
    return labelUsageInfo.entries
        .where((entry) => entry.value.usageFrequency < threshold)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get popular labels
  List<String> getPopularLabels(double threshold) {
    return labelUsageInfo.entries
        .where((entry) => entry.value.usageFrequency >= threshold)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get total label count
  int get totalLabelCount {
    final allLabels = <String>{};
    allLabels.addAll(vertexLabelCounts.keys);
    allLabels.addAll(edgeLabelCounts.keys);
    return allLabels.length;
  }

  @override
  String toString() {
    return 'LabelStatistics(totalLabels: $totalLabelCount, '
        'vertexLabels: ${vertexLabelCounts.length}, '
        'edgeLabels: ${edgeLabelCounts.length}, '
        'unusedLabels: ${unusedLabels.length}, '
        'combinations: ${labelCombinations.length})';
  }
}

/// Label analysis report
class LabelAnalysisReport {
  LabelAnalysisReport({
    required this.totalVertices,
    required this.totalEdges,
    required this.vertexLabelCounts,
    required this.edgeLabelCounts,
    required this.labelCombinations,
    required this.labelRelationships,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
  final int totalVertices;
  final int totalEdges;
  final Map<String, int> vertexLabelCounts;
  final Map<String, int> edgeLabelCounts;
  final Map<Set<String>, int> labelCombinations;
  final Map<String, Map<String, int>> labelRelationships;
  final DateTime generatedAt;

  /// Get report summary
  Map<String, dynamic> getSummary() {
    return {
      'totalVertices': totalVertices,
      'totalEdges': totalEdges,
      'uniqueVertexLabels': vertexLabelCounts.length,
      'uniqueEdgeLabels': edgeLabelCounts.length,
      'labelCombinations': labelCombinations.length,
      'labelRelationships': labelRelationships.length,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    final summary = getSummary();
    return 'LabelAnalysisReport(${summary.entries.map((e) => '${e.key}: ${e.value}').join(', ')})';
  }
}

/// Utility for label distribution charts
class LabelDistributionChart {
  /// Calculate label distribution
  static Map<String, double> calculateDistribution(
    Map<String, int> labelCounts,
    int total,
  ) {
    if (total == 0) return {};

    return labelCounts.map(
      (label, count) => MapEntry(label, count / total * 100),
    );
  }

  /// Get top labels
  static List<MapEntry<String, int>> getTopLabels(
    Map<String, int> labelCounts,
    int limit,
  ) {
    final entries = labelCounts.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Calculate label usage rates
  static Map<String, double> calculateUsageRates(
    Map<String, int> labelCounts,
    int total,
  ) {
    if (total == 0) return {};

    return labelCounts.map(
      (label, count) => MapEntry(label, count / total),
    );
  }
}

/// Utility for label relationship networks
class LabelRelationshipNetwork {
  /// Build relationship network
  static Map<String, List<String>> buildNetwork(
    Map<String, Map<String, int>> relationships,
    int minConnections,
  ) {
    final network = <String, List<String>>{};

    relationships.forEach((fromLabel, connections) {
      final strongConnections = connections.entries
          .where((entry) => entry.value >= minConnections)
          .map((entry) => entry.key)
          .toList();

      if (strongConnections.isNotEmpty) {
        network[fromLabel] = strongConnections;
      }
    });

    return network;
  }

  /// Calculate relationship strength
  static Map<String, Map<String, double>> calculateRelationshipStrength(
    Map<String, Map<String, int>> relationships,
  ) {
    final strength = <String, Map<String, double>>{};

    relationships.forEach((fromLabel, connections) {
      final totalConnections =
          connections.values.fold(0, (sum, count) => sum + count);
      if (totalConnections > 0) {
        strength[fromLabel] = connections.map(
          (toLabel, count) => MapEntry(toLabel, count / totalConnections),
        );
      }
    });

    return strength;
  }

  /// Detect bidirectional relationships
  static Map<String, List<String>> findBidirectionalRelationships(
    Map<String, Map<String, int>> relationships,
    int minConnections,
  ) {
    final bidirectional = <String, List<String>>{};

    relationships.forEach((fromLabel, connections) {
      final bidirectionalConnections = <String>[];

      connections.forEach((toLabel, count) {
        if (count >= minConnections) {
          final reverseCount = relationships[toLabel]?[fromLabel] ?? 0;
          if (reverseCount >= minConnections) {
            bidirectionalConnections.add(toLabel);
          }
        }
      });

      if (bidirectionalConnections.isNotEmpty) {
        bidirectional[fromLabel] = bidirectionalConnections;
      }
    });

    return bidirectional;
  }
}
