import 'schema_driver.dart';
import 'schema_plan.dart';

/// Captures a read-only snapshot of schema metadata for offline inspection.
class SchemaSnapshot {
  SchemaSnapshot({
    required this.schemas,
    required this.tables,
    required this.views,
    required this.columns,
    required this.indexes,
    required this.foreignKeys,
  });

  final List<SchemaNamespace> schemas;
  final List<SchemaTable> tables;
  final List<SchemaView> views;
  final List<SchemaColumn> columns;
  final List<SchemaIndex> indexes;
  final List<SchemaForeignKey> foreignKeys;

  static Future<SchemaSnapshot> capture(SchemaDriver driver) async {
    final schemas = await driver.listSchemas();
    final tables = await driver.listTables();
    final views = await driver.listViews();
    final columns = <SchemaColumn>[];
    final indexes = <SchemaIndex>[];
    final foreignKeys = <SchemaForeignKey>[];
    for (final table in tables) {
      final schema = table.schema;
      columns.addAll(await driver.listColumns(table.name, schema: schema));
      indexes.addAll(await driver.listIndexes(table.name, schema: schema));
      foreignKeys.addAll(
        await driver.listForeignKeys(table.name, schema: schema),
      );
    }
    return SchemaSnapshot(
      schemas: schemas,
      tables: tables,
      views: views,
      columns: columns,
      indexes: indexes,
      foreignKeys: foreignKeys,
    );
  }

  Map<String, Object?> toJson() => {
    'schemas': schemas.map((s) => s.toJson()).toList(),
    'tables': tables.map((t) => t.toJson()).toList(),
    'views': views.map((v) => v.toJson()).toList(),
    'columns': columns.map((c) => c.toJson()).toList(),
    'indexes': indexes.map((i) => i.toJson()).toList(),
    'foreignKeys': foreignKeys.map((f) => f.toJson()).toList(),
  };

  factory SchemaSnapshot.fromJson(Map<String, Object?> json) => SchemaSnapshot(
    schemas: (json['schemas'] as List)
        .map(
          (entry) =>
              SchemaNamespace.fromJson(Map<String, Object?>.from(entry as Map)),
        )
        .toList(),
    tables: (json['tables'] as List)
        .map(
          (entry) =>
              SchemaTable.fromJson(Map<String, Object?>.from(entry as Map)),
        )
        .toList(),
    views: (json['views'] as List)
        .map(
          (entry) =>
              SchemaView.fromJson(Map<String, Object?>.from(entry as Map)),
        )
        .toList(),
    columns: (json['columns'] as List)
        .map(
          (entry) =>
              SchemaColumn.fromJson(Map<String, Object?>.from(entry as Map)),
        )
        .toList(),
    indexes: (json['indexes'] as List)
        .map(
          (entry) =>
              SchemaIndex.fromJson(Map<String, Object?>.from(entry as Map)),
        )
        .toList(),
    foreignKeys: (json['foreignKeys'] as List)
        .map(
          (entry) => SchemaForeignKey.fromJson(
            Map<String, Object?>.from(entry as Map),
          ),
        )
        .toList(),
  );
}

/// Lightweight driver backed entirely by a [SchemaSnapshot].
class SnapshotSchemaDriver implements SchemaDriver {
  SnapshotSchemaDriver(this.snapshot);

  final SchemaSnapshot snapshot;

  @override
  Future<void> applySchemaPlan(SchemaPlan plan) {
    throw UnsupportedError('SnapshotSchemaDriver does not apply schema plans.');
  }

  @override
  SchemaPreview describeSchemaPlan(SchemaPlan plan) => const SchemaPreview([]);

  @override
  Future<List<SchemaNamespace>> listSchemas() async =>
      snapshot.schemas.toList(growable: false);

  @override
  Future<List<SchemaTable>> listTables({String? schema}) async => snapshot
      .tables
      .where((table) => schema == null || table.schema == schema)
      .toList(growable: false);

  @override
  Future<List<SchemaView>> listViews({String? schema}) async => snapshot.views
      .where((view) => schema == null || view.schema == schema)
      .toList(growable: false);

  @override
  Future<List<SchemaColumn>> listColumns(
    String table, {
    String? schema,
  }) async => snapshot.columns
      .where(
        (column) =>
            _equals(column.tableName, table) &&
            (schema == null || _equals(column.schema, schema)),
      )
      .toList(growable: false);

  @override
  Future<List<SchemaIndex>> listIndexes(String table, {String? schema}) async =>
      snapshot.indexes
          .where(
            (index) =>
                _equals(index.tableName, table) &&
                (schema == null || _equals(index.schema, schema)),
          )
          .toList(growable: false);

  @override
  Future<List<SchemaForeignKey>> listForeignKeys(
    String table, {
    String? schema,
  }) async => snapshot.foreignKeys
      .where(
        (fk) => _equalsOwner(fk.schema, schema) && _equals(fk.tableName, table),
      )
      .toList(growable: false);

  @override
  Future<bool> createDatabase(
    String name, {
    Map<String, Object?>? options,
  }) async {
    throw UnsupportedError(
      'SnapshotSchemaDriver does not support database management.',
    );
  }

  @override
  Future<bool> dropDatabase(String name) async {
    throw UnsupportedError(
      'SnapshotSchemaDriver does not support database management.',
    );
  }

  @override
  Future<bool> dropDatabaseIfExists(String name) async {
    throw UnsupportedError(
      'SnapshotSchemaDriver does not support database management.',
    );
  }

  @override
  Future<List<String>> listDatabases() async {
    throw UnsupportedError(
      'SnapshotSchemaDriver does not support database management.',
    );
  }

  @override
  Future<bool> createSchema(String name) async {
    throw UnsupportedError(
      'SnapshotSchemaDriver does not support schema management.',
    );
  }

  @override
  Future<bool> dropSchemaIfExists(String name) async {
    throw UnsupportedError(
      'SnapshotSchemaDriver does not support schema management.',
    );
  }

  @override
  Future<void> setCurrentSchema(String name) async {
    throw UnsupportedError(
      'SnapshotSchemaDriver does not support schema management.',
    );
  }

  @override
  Future<String> getCurrentSchema() async {
    throw UnsupportedError(
      'SnapshotSchemaDriver does not support schema management.',
    );
  }

  @override
  Future<bool> enableForeignKeyConstraints() async {
    throw UnsupportedError(
      'SnapshotSchemaDriver does not support FK constraint control.',
    );
  }

  @override
  Future<bool> disableForeignKeyConstraints() async {
    throw UnsupportedError(
      'SnapshotSchemaDriver does not support FK constraint control.',
    );
  }

  @override
  Future<T> withoutForeignKeyConstraints<T>(
    Future<T> Function() callback,
  ) async {
    throw UnsupportedError(
      'SnapshotSchemaDriver does not support FK constraint control.',
    );
  }

  @override
  Future<void> dropAllTables({String? schema}) async {
    throw UnsupportedError(
      'SnapshotSchemaDriver does not support table operations.',
    );
  }

  @override
  Future<bool> hasTable(String table, {String? schema}) async {
    return snapshot.tables.any(
      (t) => _equalsOwner(t.schema, schema) && _equals(t.name, table),
    );
  }

  @override
  Future<bool> hasView(String view, {String? schema}) async {
    return snapshot.views.any(
      (v) => _equalsOwner(v.schema, schema) && _equals(v.name, view),
    );
  }

  @override
  Future<bool> hasColumn(String table, String column, {String? schema}) async {
    return snapshot.columns.any(
      (c) =>
          _equalsOwner(c.schema, schema) &&
          _equals(c.tableName, table) &&
          _equals(c.name, column),
    );
  }

  @override
  Future<bool> hasColumns(
    String table,
    List<String> columns, {
    String? schema,
  }) async {
    final tableColumns = snapshot.columns
        .where(
          (c) => _equalsOwner(c.schema, schema) && _equals(c.tableName, table),
        )
        .toList();

    for (final column in columns) {
      if (!tableColumns.any((c) => _equals(c.name, column))) {
        return false;
      }
    }

    return true;
  }

  @override
  Future<bool> hasIndex(
    String table,
    String index, {
    String? schema,
    String? type,
  }) async {
    return snapshot.indexes.any((idx) {
      final typeMatches =
          type == null ||
          (type == 'primary' && idx.primary) ||
          (type == 'unique' && idx.unique) ||
          _equals(type, idx.type);

      return _equalsOwner(idx.schema, schema) &&
          _equals(idx.tableName, table) &&
          _equals(idx.name, index) &&
          typeMatches;
    });
  }

  bool _equals(String? a, String? b) =>
      (a ?? '').toLowerCase() == (b ?? '').toLowerCase();

  bool _equalsOwner(String? value, String? schema) {
    if (schema == null) return true;
    return _equals(value, schema);
  }
}
