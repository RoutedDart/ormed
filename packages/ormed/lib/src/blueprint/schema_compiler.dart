import '../hook/query_builder_hook.dart';
import 'schema_driver.dart';
import 'schema_plan.dart';

/// Translates [SchemaPlan] objects into SQL statements using a dialect.
class SchemaPlanCompiler {
  SchemaPlanCompiler(this.dialect, {List<SchemaMutationHook>? hooks})
    : _hooks = hooks ?? const <SchemaMutationHook>[];

  final SchemaDialect dialect;
  final List<SchemaMutationHook> _hooks;

  SchemaPreview compile(SchemaPlan plan) {
    final statements = <SchemaStatement>[];
    for (final mutation in plan.mutations) {
      final hookStatements = _hookStatements(mutation);
      if (hookStatements != null) {
        statements.addAll(hookStatements);
        continue;
      }
      statements.addAll(dialect.compileMutation(mutation));
    }
    return SchemaPreview(List.unmodifiable(statements));
  }

  List<SchemaStatement>? _hookStatements(SchemaMutation mutation) {
    for (final hook in _hooks) {
      if (hook.handles(mutation)) {
        return hook.handle(mutation);
      }
    }
    return null;
  }
}

/// Dialects convert individual schema mutations into executable SQL.
abstract class SchemaDialect {
  const SchemaDialect();

  /// Identifier for the driver this dialect targets (e.g. `postgres`).
  String get driverName;

  List<SchemaStatement> compileMutation(SchemaMutation mutation);

  // ========== Database Management ==========

  /// Compiles SQL to create a database.
  /// Returns null if this dialect doesn't support database creation via SQL.
  String? compileCreateDatabase(String name, Map<String, Object?>? options) {
    return null;
  }

  /// Compiles SQL to drop a database if it exists.
  /// Returns null if this dialect doesn't support database dropping via SQL.
  String? compileDropDatabaseIfExists(String name) {
    return null;
  }

  /// Compiles SQL to list all databases.
  /// Returns null if this dialect doesn't support listing databases via SQL.
  String? compileListDatabases() {
    return null;
  }

  // ========== Schema Introspection ==========

  /// Compiles SQL to list schemas/namespaces.
  String? compileSchemas({String? schema});

  /// Compiles SQL to list tables for an optional schema.
  String? compileTables({String? schema});

  /// Compiles SQL to list views for an optional schema.
  String? compileViews({String? schema});

  /// Compiles SQL to list columns for a table within an optional schema.
  String? compileColumns(String table, {String? schema});

  /// Compiles SQL to list indexes for a table within an optional schema.
  String? compileIndexes(String table, {String? schema});

  /// Compiles SQL to list foreign keys for a table within an optional schema.
  String? compileForeignKeys(String table, {String? schema});

  // ========== Foreign Key Constraint Management ==========

  /// Compiles SQL to enable foreign key constraint checking.
  /// Returns null if this dialect doesn't support FK constraint control.
  String? compileEnableForeignKeyConstraints() {
    return null;
  }

  /// Compiles SQL to disable foreign key constraint checking.
  /// Returns null if this dialect doesn't support FK constraint control.
  String? compileDisableForeignKeyConstraints() {
    return null;
  }
}
