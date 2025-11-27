import 'schema_statement.dart';

/// Preview of the SQL statements a schema plan would execute.
/// A preview of SQL statements that would be executed for a schema plan.
///
/// ```dart
/// final preview = SchemaPreview([
///   SchemaStatement('CREATE TABLE users(id INTEGER PRIMARY KEY)'),
/// ]);
/// ```
class SchemaPreview {
  const SchemaPreview(this.statements);

  /// Ordered statements that would run for a schema plan.
  final List<SchemaStatement> statements;
}
