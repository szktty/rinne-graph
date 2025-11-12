/// Base exception class for the RinneGraph library.
class RinneException implements Exception {
  RinneException(this.message);

  final String message;

  @override
  String toString() => 'RinneException: $message';
}

/// Exception related to database operations.
class DatabaseException extends RinneException {
  DatabaseException(super.message);
}

/// Exception related to transaction operations.
class TransactionException extends RinneException {
  TransactionException(super.message);
}

/// Exception related to vertex operations.
class VertexException extends RinneException {
  VertexException(super.message);
}

/// Exception related to edge operations.
class EdgeException extends RinneException {
  EdgeException(super.message);
}

/// Exception related to query execution.
class QueryException extends RinneException {
  QueryException(super.message);
}

/// Exception related to database validation checks.
class DatabaseValidationException extends DatabaseException {
  DatabaseValidationException(super.message);
}
