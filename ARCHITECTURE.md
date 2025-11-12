# RinneGraph Architecture

## Core Principles

- **Embedded Database**: Designed to run within Flutter applications
- **SQLite Backend**: Leverages SQLite for data persistence and ACID transactions
- **Property Graph Model**: Supports vertices and edges with labels and properties
- **Gremlin-Inspired API**: Provides a fluent, declarative query interface
- **Type Safety**: Utilizes Dart's type system for safe graph operations

## Project Structure

```
rinne-graph/
├── lib/
│   ├── rinne_graph.dart          # Main library entry point
│   └── src/
│       ├── database/              # Database layer
│       ├── graph/                 # Graph operations
│       ├── model/                 # Data models
│       ├── traversal/             # Traversal API
│       │   ├── sql_traversal/    # SQL-based implementation
│       │   └── traversal_base/   # Base classes
│       └── helpers/               # Utilities
├── test/                          # Tests
├── example/                       # Usage examples
├── doc/                           # Documentation
└── bin/                           # CLI tools
```


## Architecture Layers

RinneGraph is organized into four main architectural layers:

### 1. Database Layer

Handles SQLite database operations and data persistence.

**Key Components**:
- `Database`: Abstract interface for database operations
- `SQLiteDatabase`: Concrete SQLite implementation
- `DatabaseManager`: Manages database lifecycle (open, close, initialization)
- `Transaction`: Interface for transaction processing

**Responsibilities**:
- Database file management
- Transaction handling
- Schema initialization and migration
- Raw SQL query execution

### 2. Model Layer

Defines the graph data model abstractions.

**Key Components**:
- `Element`: Common interface for vertices and edges
  - Properties: ID, labels, properties, timestamps
- `Vertex`: Represents graph vertices
- `Edge`: Represents graph edges (with source and target vertex IDs)

**Responsibilities**:
- Data model definitions
- Property type handling
- JSON serialization/deserialization
- Element validation

### 3. Graph Operations Layer

Provides high-level graph manipulation operations.

**Key Components**:
- `Graph`: Main interface for graph database operations
  - Database lifecycle management
  - Transaction management
  - Traversal source creation
- `GraphStatistics`: Graph statistics and metadata

**Responsibilities**:
- CRUD operations for vertices and edges
- Graph-wide operations
- Statistics collection
- Event management

### 4. Traversal Layer

Implements the Gremlin-inspired query API.

**Key Components**:
- `TraversalSource`: Entry point for traversals (obtained via `graph.traversal()`)
- `Traversal`: Interface defining traversal operations
- `TraversalStep`: Individual step in a traversal chain
- `SqlTraversal`: Converts traversals to SQL queries
- `TraversalPath`: Tracks path information during traversal

**Responsibilities**:
- Fluent API for graph queries
- Step chaining and validation
- SQL query generation
- Result streaming

## Database Schema

RinneGraph uses a normalized relational schema to store graph data in SQLite.

### Tables

#### Vertices
```sql
CREATE TABLE vertices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Vertex Labels
```sql
CREATE TABLE vertex_labels (
    vertex_id INTEGER,
    label TEXT NOT NULL,
    PRIMARY KEY (vertex_id, label),
    FOREIGN KEY (vertex_id) REFERENCES vertices(id) ON DELETE CASCADE
);
```

#### Vertex Properties
```sql
CREATE TABLE vertex_properties (
    vertex_id INTEGER,
    key TEXT NOT NULL,
    value TEXT,
    type TEXT NOT NULL,
    PRIMARY KEY (vertex_id, key),
    FOREIGN KEY (vertex_id) REFERENCES vertices(id) ON DELETE CASCADE
);
```

#### Edges
```sql
CREATE TABLE edges (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_vertex_id INTEGER NOT NULL,
    to_vertex_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_vertex_id) REFERENCES vertices(id) ON DELETE CASCADE,
    FOREIGN KEY (to_vertex_id) REFERENCES vertices(id) ON DELETE CASCADE
);
```

#### Edge Labels
```sql
CREATE TABLE edge_labels (
    edge_id INTEGER,
    label TEXT NOT NULL,
    PRIMARY KEY (edge_id, label),
    FOREIGN KEY (edge_id) REFERENCES edges(id) ON DELETE CASCADE
);
```

#### Edge Properties
```sql
CREATE TABLE edge_properties (
    edge_id INTEGER,
    key TEXT NOT NULL,
    value TEXT,
    type TEXT NOT NULL,
    PRIMARY KEY (edge_id, key),
    FOREIGN KEY (edge_id) REFERENCES edges(id) ON DELETE CASCADE
);
```

### Indexes

```sql
CREATE INDEX idx_vertex_labels ON vertex_labels(label);
CREATE INDEX idx_edge_labels ON edge_labels(label);
CREATE INDEX idx_edges_from_to ON edges(from_vertex_id, to_vertex_id);
CREATE INDEX idx_vertex_properties_key_value ON vertex_properties(key, value);
CREATE INDEX idx_edge_properties_key_value ON edge_properties(key, value);
```

### Triggers

Automatic timestamp updates:

```sql
CREATE TRIGGER update_vertex_timestamp AFTER UPDATE ON vertices
BEGIN
    UPDATE vertices SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_edge_timestamp AFTER UPDATE ON edges
BEGIN
    UPDATE edges SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
```

### Property Types

Supported property value types:
- `string`: Text values
- `integer`: Integer numbers
- `float`: Floating-point numbers
- `boolean`: Boolean values
- `datetime`: Date and time values
- `null`: Null values (represented by `NullValue` class)

Properties are stored as text in the database with type information in the `type` column, and converted to appropriate Dart types when retrieved.

### Schema Design Features

1. **Multiple Labels**: Both vertices and edges can have multiple labels
2. **Flexible Properties**: Key-value pairs allow arbitrary properties
3. **Referential Integrity**: Foreign key constraints ensure data consistency
4. **Cascade Deletion**: Related data is automatically deleted when parent is removed
5. **Efficient Indexing**: Indexes on common query patterns
6. **Automatic Timestamps**: Creation and update times are managed automatically

## Traversal API Architecture

### SQL-Based Traversal

RinneGraph converts traversal steps into SQL queries using a CTE (Common Table Expression) based approach.

**Key Concepts**:
1. Each traversal step generates a CTE
2. CTEs are chained together to form a complete query
3. The final query executes as a single SQL statement
4. Results are streamed back to the application

**Benefits**:
- Leverages SQLite's query optimizer
- Reduces memory overhead
- Enables efficient filtering and sorting
- Supports complex graph patterns

### Step Types

Traversal steps are categorized by their function:

1. **Start Steps**: `V()`, `E()` - Begin traversal
2. **Filter Steps**: `hasId()`, `hasLabel()`, `hasKey()`, `hasNot()`, `filter()`
3. **Navigation Steps**: `out()`, `in_()`, `both()`, `outE()`, `inE()`, `bothE()`
4. **Property Steps**: `values()`, `valueMap()`, `id()`
5. **Transform Steps**: `map()`, `dedup()`
6. **Order Steps**: `order()`, `byId()`, `byKey()`
7. **Limit Steps**: `limit()`
8. **Path Steps**: `path()`

### Type System

Each step has:
- **Input Type**: Expected element type (vertex, edge, property, etc.)
- **Output Type**: Resulting element type after the step
- **Type Validation**: Ensures steps are compatible when chained

## Adding New Traversal Steps

### Implementation Process

1. **Define Base Class** (in `traversal_base_class.dart` or similar):
```dart
abstract class TraversalStepNewStepBase extends TraversalStepBase {
  @override
  String get name => 'newStep';
  
  @override
  ElementType get requiredInputType => ElementType.vertex;
  
  @override
  ElementType get outputType => ElementType.edge;
  
  @override
  bool get allowsStartStep => false;
}
```

2. **Implement SQL Traversal Step** (in `sql_traversal_steps.dart`):
```dart
class NewStep extends TraversalStepNewStepBase implements SqlTraversalStep {
  NewStep(this.parameters);
  
  final List<String> parameters;
  
  @override
  void apply(SqlTraversal t) {
    t.addCte(
      cteName: 'newStep',
      id: '...',
      type: '...',
      value: '...',
      joins: [...],
      where: '...',
    );
  }
}
```

3. **Add to SQL Traversal Interface** (in `sql_traversal_impl.dart`):
```dart
@override
Traversal newStep([List<String>? parameters]) {
  return withNewStep(NewStep(parameters ?? []));
}
```

4. **Implement Model Step** (in `traversal_model_steps.dart`):
```dart
class NewStep extends TraversalStepNewStepBase implements TraversalStepModel {
  NewStep(this.parameters);
  
  final List<String> parameters;
  
  @override
  Iterable<TraversalPath> apply(
    TraversalModel t,
    Iterable<TraversalPath> targets,
  ) {
    // Implementation logic
  }
}
```

5. **Update Traversal Interface** (in `traversal_intf.dart`):
```dart
Traversal newStep([List<String>? parameters]);
```

6. **Add Tests** (in `test/` directory):
```dart
property('NewStep', () {
  forAll(ArbitraryTestHelpers.graph(), (f) async {
    final g = await f;
    final traversal = g.traversalSystem().V().newStep(...);
    final query = traversal.buildQuery();
    final results = await g.rawQuery(query.query, query.parameters);
    
    final actual = results.getIds();
    final expected = await g.V().newStep(...).id().toList();
    expect(setEquals(actual.toSet(), expected.toSet()), isTrue);
  });
});
```

### Best Practices

1. **CTE Design**:
   - Each step generates an independent CTE
   - Use meaningful, unique CTE names
   - Maintain consistent ID, Type, and Value column semantics

2. **Type Safety**:
   - Ensure `inputType` and `outputType` are correctly set
   - Implement explicit type conversion when needed

3. **Path Support**:
   - Consider how path information is maintained
   - Path info is stored as JSON arrays

4. **Label Filtering**:
   - Implement as JOIN conditions
   - Handle both empty and specified label lists

5. **Testing**:
   - Test basic functionality
   - Test with specific conditions (IDs, labels)
   - Test edge cases

## Testing Strategy

### Testing Approach

RinneGraph primarily uses **property-based testing** with the `kiri_check` library. This approach generates random test data to validate invariants and ensure correctness across a wide range of scenarios.

### Test Organization

The test suite is organized by functional area:

```
test/
├── database_test.dart              # Database layer tests
├── database_validation_test.dart   # Database validation API tests
├── transaction/                    # Transaction-related tests
│   ├── basic_test.dart            # Basic CRUD operations
│   ├── merge_v_test.dart          # Vertex merge operations
│   ├── merge_e_test.dart          # Edge merge operations
│   ├── property_types_test.dart   # Property type handling
│   └── transactional_traversal_test.dart
├── model/                          # Data model tests
│   ├── null_value_test.dart       # NullValue class tests
│   ├── list_property_test.dart    # List property support
│   └── graph/                     # Graph model tests
├── traversal/                      # Traversal API tests
│   ├── start_step_test.dart       # V(), E() steps
│   ├── filter_step_test.dart      # Filter steps
│   ├── movement_step_test.dart    # Navigation steps
│   ├── property_step_test.dart    # Property access steps
│   ├── result_control_step_test.dart  # Limit, order steps
│   ├── path_step_test.dart        # Path tracking
│   ├── count_step_test.dart       # Count aggregation
│   ├── dedup_step_test.dart       # Deduplication
│   ├── map_step_test.dart         # Map transformation
│   └── ...                        # Other step tests
├── graph/                          # Graph-level feature tests
│   ├── label_events_test.dart     # Label event system
│   ├── label_statistics_test.dart # Statistics API
│   └── index_management_test.dart # Index management
├── helpers/                        # Test utilities
│   ├── arbitrary.dart             # Property-based test generators
│   ├── database.dart              # Database test helpers
│   └── helpers.dart               # General test helpers
└── helpers_test/                   # Tests for test helpers
```

### Property-Based Testing with kiri_check

Most tests use `kiri_check` for property-based testing:

**Key Features**:
- **Random Graph Generation**: Creates graphs with random vertices, edges, labels, and properties
- **Arbitrary Generators**: Custom generators for graph elements (`ArbitraryTestHelpers`)
- **Invariant Testing**: Validates that operations maintain expected properties
- **Shrinking**: Automatically minimizes failing test cases (often disabled with `maxShrinkingTries: 0`)

**Example Test Pattern**:
```dart
property('V - 頂点選択', () {
  forAll(
    ArbitraryTestHelpers.graph(),
    (f) async {
      final g = await f;
      final vertexIds = g.getAnyVertexIds();
      final traversal = g.traversalSystem().V(vertexIds);
      final query = traversal.buildQuery();
      final results = await g.rawQuery(query.query, query.parameters);

      final actual = await g.V(results.getIds()).toList();
      final expected = await g.V(vertexIds).toList();
      expect(actual.toSet(), equals(expected.toSet()));
    },
  );
});
```

### Test Categories

1. **Database Layer Tests**:
   - Schema initialization and validation
   - Connection management
   - Raw SQL query execution
   - Transaction handling

2. **Transaction Tests**:
   - CRUD operations for vertices and edges
   - Property type handling (string, integer, float, boolean, datetime, null, list)
   - Merge operations (upsert semantics)
   - Transactional traversal execution

3. **Model Tests**:
   - Data model validation
   - NullValue singleton behavior
   - List property support
   - JSON serialization/deserialization

4. **Traversal Tests**:
   - Each traversal step has dedicated tests
   - SQL query generation validation
   - Result correctness verification
   - Type compatibility checking
   - Edge cases and error conditions

5. **Graph Feature Tests**:
   - Label event system
   - Statistics collection
   - Index management API

### Test Execution

Tests are configured with reduced example counts for faster execution:
```dart
KiriCheck.maxExamples = 30;  // Default is higher
```

Debug logging can be enabled/disabled via `initializeDebugSettings()` in test helpers.

## Performance Considerations

### SQLite Advantages
- Mature, stable technology
- Embeddable in mobile apps
- ACID transaction support
- Standard SQL expressiveness

### SQLite Limitations
- Graph queries don't map naturally to SQL
- Recursive queries can be inefficient
- Not suitable for very large graphs
- Requires careful query optimization

### Optimization Strategies
1. Proper index usage
2. Query result caching (future)
3. Batch operations where possible
4. Stream processing for large results
5. Partial in-memory processing for complex traversals

## Future Considerations

- Query result caching
- Advanced traversal steps (repeat, match, union)
- Subgraph extraction
- Graph algorithms (shortest path, centrality, etc.)
- Performance optimizations for large graphs
