import '../../driver/driver.dart';

/// Represents a single schema statement and optional structured payload.
///
/// ```dart
/// final statement = SchemaStatement(
///   'CREATE TABLE users (id INTEGER PRIMARY KEY)',
///   parameters: [],
/// );
/// ```
class SchemaStatement {
  const SchemaStatement(this.sql, {this.parameters = const [], this.payload});

  /// SQL text that will execute during the schema plan.
  final String sql;

  /// Statement parameters rendered alongside [sql].
  final List<Object?> parameters;

  /// Optional structured payload that accompanies the statement.
  final StatementPayload? payload;
}
