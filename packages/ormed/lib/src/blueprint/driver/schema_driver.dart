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

  // ========== Existence Checking ==========

  /// Determines if the given table exists.
  Future<bool> hasTable(String table, {String? schema});

  /// Determines if the given view exists.
  Future<bool> hasView(String view, {String? schema});

  /// Determines if the given table has a specific column.
  Future<bool> hasColumn(String table, String column, {String? schema});

  /// Determines if the given table has all of the specified columns.
  Future<bool> hasColumns(String table, List<String> columns, {String? schema});

  /// Determines if the given table has a specific index.
  /// Optionally check by index type ('primary', 'unique', or specific driver type).
  Future<bool> hasIndex(String table, String index, {String? schema, String? type});

  // ========== Database Management ==========

  /// Creates a new database with the given name.
  ///
  /// Options are driver-specific:
  /// - MySQL: `{charset: 'utf8mb4', collation: 'utf8mb4_unicode_ci'}`
  /// - Postgres: `{encoding: 'UTF8', owner: 'username', template: 'template0',
  ///             locale: 'en_US.UTF-8', lc_collate: 'en_US.UTF-8',
  ///             lc_ctype: 'en_US.UTF-8', tablespace: 'pg_default',
  ///             connection_limit: -1}`
  /// - SQLite: (no options - file-based)
  ///
  /// Returns true if created, false if already exists.
  /// Throws [DriverException] on error.
  Future<bool> createDatabase(
    String name, {
    Map<String, Object?>? options,
  });

  /// Drops a database with the given name.
  /// Throws if database doesn't exist.
  Future<bool> dropDatabase(String name);

  /// Drops a database if it exists.
  /// Returns true if dropped, false if didn't exist.
  Future<bool> dropDatabaseIfExists(String name);

  /// Lists all databases/catalogs accessible to the current connection.
  Future<List<String>> listDatabases();

  // ========== Foreign Key Constraint Management ==========

  /// Enables foreign key constraint checking.
  /// Returns true if successful.
  Future<bool> enableForeignKeyConstraints();

  /// Disables foreign key constraint checking.
  /// Returns true if successful.
  Future<bool> disableForeignKeyConstraints();

  /// Executes a callback with foreign key constraints disabled.
  /// Automatically re-enables constraints after callback completes.
  Future<T> withoutForeignKeyConstraints<T>(Future<T> Function() callback);

  // ========== Bulk Operations ==========

  /// Drops all tables from the database.
  /// Automatically handles foreign key constraints.
  Future<void> dropAllTables({String? schema});
}
