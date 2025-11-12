final class GraphStatistics {
  GraphStatistics({
    required this.databasePath,
    required this.isInMemory,
    required this.totalVertices,
    required this.totalEdges,
    required this.vertexLabelCounts,
    required this.edgeLabelCounts,
    required this.vertexPropertyCounts,
    required this.edgePropertyCounts,
    required this.lastModified,
  });
  final String databasePath;
  final bool isInMemory;
  final int totalVertices;
  final int totalEdges;
  final Map<String, int> vertexLabelCounts;
  final Map<String, int> edgeLabelCounts;
  final Map<String, int> vertexPropertyCounts;
  final Map<String, int> edgePropertyCounts;
  final DateTime lastModified;
}
