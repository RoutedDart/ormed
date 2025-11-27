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

  bool _equals(String? a, String? b) =>
      (a ?? '').toLowerCase() == (b ?? '').toLowerCase();

  bool _equalsOwner(String? value, String? schema) {
    if (schema == null) return true;
    return _equals(value, schema);
  }
}
