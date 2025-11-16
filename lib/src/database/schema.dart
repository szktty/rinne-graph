enum DatabaseValueType {
  null_,
  boolean,
  integer,
  float,
  string,
  datetime,
  blob,
  list;

  static DatabaseValueType fromId(int id) {
    switch (id) {
      case 0:
        return DatabaseValueType.null_;
      case 1:
        return DatabaseValueType.boolean;
      case 2:
        return DatabaseValueType.integer;
      case 3:
        return DatabaseValueType.float;
      case 4:
        return DatabaseValueType.string;
      case 5:
        return DatabaseValueType.datetime;
      case 6:
        return DatabaseValueType.blob;
      case 7:
        return DatabaseValueType.list;
      default:
        throw ArgumentError('Unsupported database value type id: $id');
    }
  }

  int get id {
    switch (this) {
      case DatabaseValueType.null_:
        return 0;
      case DatabaseValueType.boolean:
        return 1;
      case DatabaseValueType.integer:
        return 2;
      case DatabaseValueType.float:
        return 3;
      case DatabaseValueType.string:
        return 4;
      case DatabaseValueType.datetime:
        return 5;
      case DatabaseValueType.blob:
        return 6;
      case DatabaseValueType.list:
        return 7;
    }
  }

  int get precedence {
    switch (this) {
      case DatabaseValueType.null_:
        return 0;
      case DatabaseValueType.boolean:
        return 1;
      case DatabaseValueType.integer:
      case DatabaseValueType.float:
        return 2;
      case DatabaseValueType.string:
        return 3;
      case DatabaseValueType.datetime:
        return 4;
      case DatabaseValueType.blob:
        return 5;
      case DatabaseValueType.list:
        return 6;
    }
  }

  bool get isNumber =>
      DatabaseValueType.integer == this || DatabaseValueType.float == this;
}

final class DatabaseSchema {
  static const String createVerticesTable = '''
    CREATE TABLE vertices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      archived BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  static const String createVertexLabelsTable = '''
    CREATE TABLE vertex_labels (
      vertex_id INTEGER,
      label TEXT NOT NULL,
      PRIMARY KEY (vertex_id, label),
      FOREIGN KEY (vertex_id) REFERENCES vertices(id) ON DELETE CASCADE
    )
  ''';

  static const String createVertexPropertiesTable = '''
    CREATE TABLE vertex_properties (
      vertex_id INTEGER,
      key TEXT NOT NULL,
      value NONE,
      type INTEGER NOT NULL,
      PRIMARY KEY (vertex_id, key),
      FOREIGN KEY (vertex_id) REFERENCES vertices(id) ON DELETE CASCADE
    )
  ''';

  static const String createEdgesTable = '''
    CREATE TABLE edges (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      from_vertex_id INTEGER NOT NULL,
      to_vertex_id INTEGER NOT NULL,
      archived BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (from_vertex_id) REFERENCES vertices(id) ON DELETE CASCADE,
      FOREIGN KEY (to_vertex_id) REFERENCES vertices(id) ON DELETE CASCADE
    )
  ''';

  static const String createEdgeLabelsTable = '''
    CREATE TABLE edge_labels (
      edge_id INTEGER,
      label TEXT NOT NULL,
      PRIMARY KEY (edge_id, label),
      FOREIGN KEY (edge_id) REFERENCES edges(id) ON DELETE CASCADE
    )
  ''';

  static const String createEdgePropertiesTable = '''
    CREATE TABLE edge_properties (
      edge_id INTEGER,
      key TEXT NOT NULL,
      value NONE,
      type INTEGER NOT NULL,
      PRIMARY KEY (edge_id, key),
      FOREIGN KEY (edge_id) REFERENCES edges(id) ON DELETE CASCADE
    )
  ''';

  static const int autoIncrementStartId = 1000000;

  static const List<String> createIndices = [
    'CREATE INDEX idx_vertex_labels ON vertex_labels(label)',
    'CREATE INDEX idx_edge_labels ON edge_labels(label)',
    'CREATE INDEX idx_edges_from_to ON edges(from_vertex_id, to_vertex_id)',
    'CREATE INDEX idx_vertex_properties_key_type_value ON vertex_properties(key, type, value)',
    'CREATE INDEX idx_edge_properties_key_type_value ON edge_properties(key, type, value)',
    'CREATE INDEX idx_vertices_archived ON vertices(archived)',
    'CREATE INDEX idx_edges_archived ON edges(archived)',
    "INSERT INTO sqlite_sequence (name, seq) VALUES ('vertices', $autoIncrementStartId)",
  ];

  static const String createVertexTimestampTrigger = '''
    CREATE TRIGGER update_vertex_timestamp AFTER UPDATE ON vertices
    BEGIN
      UPDATE vertices SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END
  ''';

  static const String createEdgeTimestampTrigger = '''
    CREATE TRIGGER update_edge_timestamp AFTER UPDATE ON edges
    BEGIN
      UPDATE edges SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END
  ''';
}
