// Stub implementation for sqlite3 package for web compatibility

/// Stub Database class for web compatibility
class Database {
  /// Last inserted row ID
  int get lastInsertRowId => 0;

  /// Number of updated rows
  int get updatedRows => 0;

  /// Execute a SQL statement
  void execute(String sql, [List<Object?>? parameters]) {
    // Stub implementation - does nothing on web
  }

  /// Prepare a SQL statement
  PreparedStatement prepare(String sql) {
    return PreparedStatement._();
  }

  /// Dispose the database connection
  void dispose() {
    // Stub implementation - does nothing on web
  }
}

/// Stub PreparedStatement class for web compatibility
class PreparedStatement {
  PreparedStatement._();

  /// Execute the prepared statement
  void execute([List<Object?>? parameters]) {
    // Stub implementation - does nothing on web
  }

  /// Select data using the prepared statement
  ResultSet select([List<Object?>? parameters]) {
    return ResultSet._();
  }

  /// Dispose the prepared statement
  void dispose() {
    // Stub implementation - does nothing on web
  }
}

/// Stub ResultSet class for web compatibility
class ResultSet {
  ResultSet._();

  /// Column names in the result set
  List<String> get columnNames => [];

  /// Check if the result set is empty
  bool get isEmpty => true;

  /// Check if the result set is not empty
  bool get isNotEmpty => false;

  /// Get the first row
  List<Object?> get first => [];

  /// Map over the result set
  Iterable<T> map<T>(T Function(List<Object?> row) f) {
    return <T>[];
  }
}

/// Stub sqlite3 object for web compatibility
final sqlite3 = _SQLite3._();

class _SQLite3 {
  _SQLite3._();

  /// Open a database connection
  Database open(String path) {
    return Database();
  }
}
