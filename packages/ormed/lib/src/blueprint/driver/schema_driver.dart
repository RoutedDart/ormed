import '../schema_plan.dart';

import 'schema_column.dart';
import 'schema_foreign_key.dart';
import 'schema_index.dart';
import 'schema_namespace.dart';
import 'schema_preview.dart';
import 'schema_table.dart';
import 'schema_view.dart';

/// Contract implemented by database drivers that can execute schema plans and
/// introspect live database metadata.
///
/// ```dart
/// class MySaneDriver implements SchemaDriver {
///   // implement members...
/// }
/// ```
abstract class SchemaDriver {
  /// Executes the given [plan], typically inside a transaction when supported.
  Future<void> applySchemaPlan(SchemaPlan plan);

  /// Returns a preview of the SQL statements that would run for [plan].
  SchemaPreview describeSchemaPlan(SchemaPlan plan);

  /// Lists the schemas/namespaces available in the connection.
  Future<List<SchemaNamespace>> listSchemas();

  /// Lists all user tables on the connection, optionally filtered by [schema].
  Future<List<SchemaTable>> listTables({String? schema});

  /// Lists all views on the connection, optionally filtered by [schema].
  Future<List<SchemaView>> listViews({String? schema});

  /// Lists columns for [table] within an optional [schema].
  Future<List<SchemaColumn>> listColumns(String table, {String? schema});

  /// Lists indexes for [table] within an optional [schema].
  Future<List<SchemaIndex>> listIndexes(String table, {String? schema});

  /// Lists foreign keys for [table] within an optional [schema].
  Future<List<SchemaForeignKey>> listForeignKeys(
    String table, {
    String? schema,
  });
}
