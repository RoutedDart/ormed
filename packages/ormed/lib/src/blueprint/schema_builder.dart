import 'schema_driver.dart';
import 'schema_plan.dart';
import 'schema_snapshot.dart';
import 'table_blueprint.dart';

/// Fluent builder that collects schema commands for a migration direction.
class SchemaBuilder {
  SchemaBuilder({SchemaSnapshot? snapshot}) : _snapshot = snapshot;

  final SchemaSnapshot? _snapshot;
  SchemaInspector? _inspector;
  final List<SchemaMutation> _mutations = [];

  /// Returns true when this builder was constructed with a [SchemaSnapshot].
  bool get hasSnapshot => _snapshot != null;

  /// Lazily exposes an inspector backed by the captured [SchemaSnapshot].
  SchemaInspector get inspector {
    if (_inspector != null) {
      return _inspector!;
    }
    final snapshot = _requireSnapshot();
    _inspector = SchemaInspector(SnapshotSchemaDriver(snapshot));
    return _inspector!;
  }

  /// Builds a `CREATE TABLE` command.
  TableBlueprint create(
    String table,
    void Function(TableBlueprint table) definition,
  ) {
    final blueprint = TableBlueprint.create(table);
    definition(blueprint);
    _mutations.add(SchemaMutation.createTable(blueprint));
    return blueprint;
  }

  /// Builds an `ALTER TABLE` command.
  TableBlueprint table(
    String table,
    void Function(TableBlueprint table) definition,
  ) {
    final blueprint = TableBlueprint.alter(table);
    definition(blueprint);
    _mutations.add(SchemaMutation.alterTable(blueprint));
    return blueprint;
  }

  /// Registers a drop table command.
  void drop(String table, {bool ifExists = false, bool cascade = false}) {
    _mutations.add(
      SchemaMutation.dropTable(
        table: table,
        ifExists: ifExists,
        cascade: cascade,
      ),
    );
  }

  /// Registers a rename table command.
  void rename(String from, String to) {
    _mutations.add(SchemaMutation.renameTable(from: from, to: to));
  }

  /// Registers Mongo-style create collection command.
  void createCollection(
    String collection, {
    Map<String, Object?>? validator,
    Map<String, Object?>? options,
  }) {
    _mutations.add(
      SchemaMutation.createCollection(
        collection: collection,
        validator: validator,
        options: options,
      ),
    );
  }

  /// Registers Mongo-style drop collection command.
  void dropCollection(String collection) {
    _mutations.add(SchemaMutation.dropCollection(collection: collection));
  }

  /// Registers Mongo-style create index command.
  void createIndex({
    required String collection,
    required Map<String, Object?> keys,
    Map<String, Object?>? options,
  }) {
    _mutations.add(
      SchemaMutation.createIndex(
        collection: collection,
        keys: keys,
        options: options,
      ),
    );
  }

  /// Registers Mongo-style drop index command.
  void dropIndex({required String collection, required String name}) {
    _mutations.add(
      SchemaMutation.dropIndex(collection: collection, name: name),
    );
  }

  /// Registers Mongo-style validator modification command.
  void modifyValidator({
    required String collection,
    required Map<String, Object?> validator,
  }) {
    _mutations.add(
      SchemaMutation.modifyValidator(
        collection: collection,
        validator: validator,
      ),
    );
  }

  /// Appends a raw SQL command.
  void raw(String sql, {List<Object?> parameters = const []}) {
    _mutations.add(SchemaMutation.rawSql(sql, parameters: parameters));
  }

  /// Finalizes the plan captured by this builder.
  SchemaPlan build({String? description}) {
    return SchemaPlan(
      mutations: List.unmodifiable(_mutations),
      description: description,
    );
  }

  /// Returns true when no commands were recorded.
  bool get isEmpty => _mutations.isEmpty;

  /// Returns true if a table exists within the captured snapshot.
  bool hasTable(String table, {String? schema}) {
    final snapshot = _requireSnapshot();
    final target = table.toLowerCase();
    final schemaTarget = schema?.toLowerCase();
    return snapshot.tables.any((entry) {
      final entrySchema = entry.schema?.toLowerCase();
      if (schemaTarget != null && entrySchema != schemaTarget) {
        return false;
      }
      return entry.name.toLowerCase() == target;
    });
  }

  /// Returns true if a column exists within the captured snapshot.
  bool hasColumn(String table, String column, {String? schema}) {
    final snapshot = _requireSnapshot();
    final tableTarget = table.toLowerCase();
    final columnTarget = column.toLowerCase();
    final schemaTarget = schema?.toLowerCase();
    return snapshot.columns.any((entry) {
      final entrySchema = entry.schema?.toLowerCase();
      if (schemaTarget != null && entrySchema != schemaTarget) {
        return false;
      }
      if (entry.tableName?.toLowerCase() != tableTarget) {
        return false;
      }
      return entry.name.toLowerCase() == columnTarget;
    });
  }

  /// Returns the column type for the requested table/column if available.
  String? columnType(String table, String column, {String? schema}) {
    final snapshot = _requireSnapshot();
    final tableTarget = table.toLowerCase();
    final columnTarget = column.toLowerCase();
    final schemaTarget = schema?.toLowerCase();
    final match = snapshot.columns.firstWhere((entry) {
      final entrySchema = entry.schema?.toLowerCase();
      if (schemaTarget != null && entrySchema != schemaTarget) {
        return false;
      }
      if (entry.tableName?.toLowerCase() != tableTarget) {
        return false;
      }
      return entry.name.toLowerCase() == columnTarget;
    }, orElse: () => const SchemaColumn(name: '', dataType: ''));
    return match.name.isEmpty ? null : match.dataType;
  }

  /// Lists tables from the snapshot (optionally schema-qualified).
  List<String> tableListing({String? schema, bool schemaQualified = true}) {
    final snapshot = _requireSnapshot();
    final schemaTarget = schema?.toLowerCase();
    return snapshot.tables
        .where((table) {
          final entrySchema = table.schema?.toLowerCase();
          return schemaTarget == null || entrySchema == schemaTarget;
        })
        .map(
          (table) => schemaQualified ? table.schemaQualifiedName : table.name,
        )
        .toList(growable: false);
  }

  SchemaSnapshot _requireSnapshot() {
    final snapshot = _snapshot;
    if (snapshot == null) {
      throw StateError(
        'SchemaSnapshot is not configured for this SchemaBuilder.',
      );
    }
    return snapshot;
  }
}
