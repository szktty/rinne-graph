# RinneGraph

## Overview

RinneGraph is an embedded graph database library for Dart and Flutter applications, using SQLite as its backend. It provides a property graph model with vertices and edges, and offers a Gremlin-inspired traversal API for querying graph data.

## Features

*   **Embedded & Lightweight**: Runs directly within your Dart or Flutter application with no separate server process.
*   **Traversal API**: Build complex graph queries with a chained, Gremlin-style API (`g.V().out('knows').values('name')`).
*   **Property Graph Model**: Supports vertices and edges with arbitrary properties.

## Installation

Add this to your `pubspec.yaml` file:

```yaml
dependencies:
  rinne_graph: ^0.7.0
```

Then run `dart pub get` or `flutter pub get`.

## Quick Start

Run locally:

```bash
dart run example/example.dart
```


Here's a simple example of creating a small graph and querying it.

```dart
import 'package/rinne_graph/rinne_graph.dart';

void main() async {
  // 1. Open an in-memory graph database
  final graph = await Graph.openInMemory();
  final g = graph.traversal();

  // 2. Create vertices and edges within a transaction
  await graph.transaction((txn) async {
    final v1 = await txn.createVertex(Vertex(
      labels: {'person'},
      properties: {'name': 'Alice', 'age': 30},
    ));
    final v2 = await txn.createVertex(Vertex(
      labels: {'person'},
      properties: {'name': 'Bob', 'age': 25},
    ));
    await txn.createEdge(Edge(
      fromVertexId: v1.id!,
      toVertexId: v2.id!,
      labels: {'knows'},
      properties: {'since': 2021},
    ));
  });

  // 3. Traverse the graph to find people Alice knows
  final names = await g.V()
      .hasLabel(['person'])
      .hasKey('name', 'Alice')
      .out('knows')
      .values(['name'])
      .toList();

  // 4. Print the results
  print("Alice knows: $names"); // Output: Alice knows: [Bob]

  // 5. Close the database
  await graph.close();
}
```

## Samples (optional)

You can quickly spin up sample graphs for testing and exploration.

```dart
import 'package:rinne_graph/rinne_graph_samples.dart';

final graph = await Samples.simpleGraph();
// or
final movies = await Samples.movies();
```


## Usage Examples

Below are minimal examples to complement the Quick Start.

Transaction & CRUD:

```dart
await graph.transaction((txn) async {
  final v = await txn.createVertex(Vertex(labels: {'note'}, properties: {'title': 'T'}));
  await txn.updateVertexProperties(v.id!, {'title': 'New Title'});
  await txn.deleteVertex(v.id!);
});
```

Basic traversal patterns:

```dart
final g = graph.traversal();
final names = await g.V().hasLabel(['person']).hasKey('age', 30).values(['name']).toList();
final neighbors = await g.V().hasKey('name', 'Alice').out('knows').toList();
```


## Index Management (Experimental)

RinneGraph provides a user-managed property index API to help optimize query performance at the SQLite level. Indexes can be created for property keys on vertices or edges.

Important: managing indexes is the user's responsibility; create indexes only for properties that are frequently queried. Indexes can improve read performance but may increase write cost and disk usage.

Available APIs:
- `createPropertyIndex(String propertyKey, {IndexEntityType entityType = IndexEntityType.vertices, String? indexName})`
- `dropPropertyIndex(String indexName)`
- `listPropertyIndexes() -> Future<List<PropertyIndexInfo>>`
- `hasPropertyIndex(String propertyKey, {IndexEntityType entityType = IndexEntityType.vertices}) -> Future<bool>`

Entity types:
- `IndexEntityType.vertices` (vertex properties)
- `IndexEntityType.edges` (edge properties)

Index name generation:
- If `indexName` is omitted, a name is auto-generated:
  - Vertices: `idx_user_v_{propertyKey}`
  - Edges: `idx_user_e_{propertyKey}`

Example:

```dart
final graph = await Graph.open('my_graph.db');

await graph.createPropertyIndex('name'); // vertex property
await graph.createPropertyIndex('weight', entityType: IndexEntityType.edges); // edge property

final indexes = await graph.listPropertyIndexes();
for (final idx in indexes) {
  print('${idx.name}: ${idx.propertyKey} (${idx.entityType})');
}

await graph.dropPropertyIndex('idx_user_v_name');
```

Status:
This feature is under active development. In current releases, some methods may not be fully implemented yet and may throw `UnimplementedError` or return placeholders. The API surface is intended to be stable, but behavior may evolve.


## Database Validation

Before opening an existing SQLite file with RinneGraph, you can safely validate whether it’s properly initialized for this library.

- API: `DatabaseManager.validateDatabaseFile(String path, { DatabaseValidationOptions options = DatabaseValidationOptions.defaultOptions })`
- Read-only validation: the file is opened in read-only mode and not modified
- Returns: `DatabaseValidationResult` (e.g., `isValid`, `isInitialized`, `isFullyInitialized`, `missingTables`, `missingIndexes`, `missingTriggers`, `schemaVersion`, `errorMessage`)

Example:

```dart
final manager = DatabaseManager();
final result = await manager.validateDatabaseFile('my_graph.db');
if (result.isFullyInitialized) {
  final graph = await Graph.open('my_graph.db');
  // ... use the graph
  await graph.close();
} else {
  print('Database issues: ${result.description}');
}
```

Options:
- `DatabaseValidationOptions.basic` (tables only)
- `DatabaseValidationOptions.defaultOptions` (tables, indexes, triggers, schema version)
- `DatabaseValidationOptions.strict` (stricter checks)
- Custom via `DatabaseValidationOptions(checkTables: ..., checkIndexes: ..., checkTriggers: ..., checkSchemaVersion: ...)`


## Label Events & Callbacks

You can subscribe to label-related events fired during transactions. Convenience methods are provided on `Graph` and the underlying `eventManager` is also available.

Event types:
- `VertexLabelEvent` and `EdgeLabelEvent` (both extend `LabelEvent`)
- `LabelEventType`: `added`, `removed`, `updated`

Register listeners:

```dart
final graph = await Graph.openInMemory();

graph.onVertexLabelEvent((e) {
  // e.vertexId, e.label, e.eventType, e.allLabels, e.timestamp
});

graph.onEdgeLabelEvent((e) {
  // e.edgeId, e.label, e.eventType, e.allLabels
});

graph.onLabelEvent((e) {
  // handle both vertex/edge label events if desired
});
```

Notes:
- Callbacks run safely; errors in callbacks are logged and do not break transactions.
- Internal details (event dispatch) are not part of the public API.


## Label Statistics & Analysis

Get quick, high-level statistics or run deeper analysis.

Quick statistics:

```dart
final graph = await Graph.openInMemory();
final stats = await graph.getStatistics();
// stats.totalVertices, stats.totalEdges, stats.labelCounts, ...
```

Deeper analysis with `LabelAnalyzer`:

```dart
final analyzer = graph.labelAnalyzer;
final report = await analyzer.generateReport();
// e.g., report.popularLabels, co-occurrence, distributions
```


## Command-line Tool: `rinne`



RinneGraph ships with a small CLI for common tasks. Run:

```bash
rinne --help
```

Common subcommands:
- `create --output <file>`: create a new SQLite database file
- `validate --database <file>`: check if a database file is properly initialized
- `info --database <file>`: show basic information/statistics
- `sample --output <file>`: generate a small sample dataset
- `import json -i <input.json> -d <database.db>` or `import csv -n <nodes.csv> -e <edges.csv> --database <database.db> [--config <config.csv>]`
- `export json --database <database.db> -o <output.json> [--pretty --include-metadata --filter-labels L1,L2 --limit N]`
- `export csv --database <database.db> --nodes-output <nodes.csv> --edges-output <edges.csv> [--no-header --filter-labels L1,L2 --limit N --encoding utf-8]`
- `query --database <file> --sql <SQL>`: run a raw SQL query (advanced)

Import/Export formats (brief):
- JSON: a single file with metadata, nodes, and links
- CSV: separate files (nodes.csv, edges.csv, optional config.csv)

Notes:
- The CLI uses the current working directory by default and supports both relative and absolute paths.
- Files are created in the specified (or working) directory; hidden system directories are not used.


## Data Import/Export

Use the `rinne` CLI for importing and exporting data.

Import (JSON):
```bash
rinne import json -i data.json -d graph.db
```

Import (CSV):
```bash
rinne import csv -n nodes.csv -e edges.csv --database graph.db [-c config.csv]
```

Export (JSON):
```bash
rinne export json --database graph.db -o out.json [--pretty --include-metadata --filter-labels person,knows --limit 100]
```

Export (CSV):
```bash
rinne export csv --database graph.db --nodes-output nodes.csv --edges-output edges.csv [--no-header --filter-labels person,knows --limit 100 --encoding utf-8]
```

Notes:
- JSON: single file containing metadata, nodes, links
- CSV: separate files (nodes.csv, edges.csv, optional config.csv)
- Paths can be relative or absolute; the CLI resolves relative paths against the current working directory.

## Related Projects

- [plough](https://pub.dev/packages/plough) — a graph drawing/rendering library for Flutter, self-authored by the same developer.

You can combine RinneGraph for local graph storage and traversal, and plough for visualization in Flutter apps.


## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
