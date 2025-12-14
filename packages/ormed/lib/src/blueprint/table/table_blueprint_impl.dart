import 'column_command.dart';
import 'column_definition.dart';
import 'column_driver_override.dart';
import 'column_default.dart';
import 'column_rename.dart';
import 'column_type.dart';
import 'enums.dart';
import 'foreign_key_command.dart';
import 'foreign_key_definition.dart';
import 'index_command.dart';
import 'index_definition.dart';
import 'sqlite_full_text_options.dart';
import 'sqlite_spatial_index_options.dart';

/// Mutable blueprint that records the operations to perform against a table.
class TableBlueprint {
  TableBlueprint._(this.table, this.operation, {this.schema});

  factory TableBlueprint.create(String table, {String? schema}) =>
      TableBlueprint._(table, TableOperationKind.create, schema: schema);

  factory TableBlueprint.alter(String table, {String? schema}) =>
      TableBlueprint._(table, TableOperationKind.alter, schema: schema);

  factory TableBlueprint.fromJson(Map<String, Object?> json) {
    final operation = TableOperationKind.values.byName(
      json['operation'] as String,
    );
    final table = json['table'] as String;
    final blueprint = operation == TableOperationKind.create
        ? TableBlueprint.create(table)
        : TableBlueprint.alter(table);
    if (json['temporary'] == true) {
      blueprint.markTemporary();
    }

    final columnMaps = (json['columns'] as List?) ?? const [];
    for (final column in columnMaps.cast<Map<String, Object?>>()) {
      final command = ColumnCommand.fromJson(column);
      switch (command.kind) {
        case ColumnCommandKind.add:
        case ColumnCommandKind.alter:
          blueprint._columns.add(
            _ColumnEntry(
              name: command.name,
              kind: command.kind,
              definition: command.definition,
            ),
          );
        case ColumnCommandKind.drop:
          blueprint._columns.add(_ColumnEntry.drop(command.name));
      }
    }

    final renames = (json['renamedColumns'] as List?) ?? const [];
    for (final rename in renames.cast<Map<String, Object?>>()) {
      blueprint._renamedColumns.add(ColumnRename.fromJson(rename));
    }

    final indexCommands = (json['indexes'] as List?) ?? const [];
    for (final indexJson in indexCommands.cast<Map<String, Object?>>()) {
      final command = IndexCommand.fromJson(indexJson);
      switch (command.kind) {
        case IndexCommandKind.add:
          if (command.definition != null) {
            blueprint._indexes.add(_IndexEntry(command.definition!));
          }
        case IndexCommandKind.drop:
          blueprint._droppedIndexes.add(command.name);
      }
    }

    final foreignCommands = (json['foreignKeys'] as List?) ?? const [];
    for (final foreignJson in foreignCommands.cast<Map<String, Object?>>()) {
      final command = ForeignKeyCommand.fromJson(foreignJson);
      switch (command.kind) {
        case ForeignKeyCommandKind.add:
          if (command.definition != null) {
            blueprint._foreignKeys.add(ForeignKeyEntry(command.definition!));
          }
        case ForeignKeyCommandKind.drop:
          blueprint._droppedForeignKeys.add(command.name);
      }
    }

    return blueprint;
  }

  /// Name of the table being created or altered by this blueprint.
  final String table;

  /// Optional schema name for the table.
  final String? schema;

  /// Operation kind describing whether this is a create or alter.
  final TableOperationKind operation;

  /// Whether the blueprint creates a temporary table.
  bool temporary = false;

  /// Explicit storage engine to use when creating the table.
  String? engine;

  /// Charset override applied to the table.
  String? tableCharset;

  /// Collation override applied to the table.
  String? tableCollation;

  String? _tableComment;

  /// Optional comment attached to the table definition.
  String? get tableComment => _tableComment;

  final List<_ColumnEntry> _columns = [];
  final List<_IndexEntry> _indexes = [];
  final List<String> _droppedIndexes = [];
  final List<ForeignKeyEntry> _foreignKeys = [];
  final List<String> _droppedForeignKeys = [];
  final List<ColumnRename> _renamedColumns = [];

  /// Column commands that will run when the blueprint is applied.
  List<ColumnCommand> get columns =>
      _columns.map((entry) => entry.toCommand()).toList(growable: false);

  /// Index commands generated from the fluent API and drops.
  List<IndexCommand> get indexes {
    final commands = <IndexCommand>[];
    final seenNames = <String>{};

    for (final entry in _indexes) {
      commands.add(IndexCommand.add(entry.definition));
      seenNames.add(entry.definition.name);
    }

    for (final definition in _buildFluentIndexDefinitions()) {
      if (seenNames.add(definition.name)) {
        commands.add(IndexCommand.add(definition));
      }
    }

    commands.addAll(_droppedIndexes.map(IndexCommand.drop));
    return commands;
  }

  /// Foreign key commands tracked by the blueprint.
  List<ForeignKeyCommand> get foreignKeys => [
    ..._foreignKeys.map((entry) => ForeignKeyCommand.add(entry.definition)),
    ..._droppedForeignKeys.map(ForeignKeyCommand.drop),
  ];

  /// Column rename operations declared on this blueprint.
  List<ColumnRename> get renamedColumns => List.unmodifiable(_renamedColumns);

  /// Marks the table as temporary (where supported by the driver).
  void markTemporary() {
    temporary = true;
  }

  void useEngine(String value) {
    engine = value;
  }

  void setTableCharset(String value) {
    tableCharset = value;
  }

  void charset(String value) => setTableCharset(value);

  void setTableCollation(String value) {
    tableCollation = value;
  }

  void collation(String value) => setTableCollation(value);

  void setTableComment(String value) {
    _tableComment = value;
  }

  /// Adds an auto-incrementing big integer primary key column.
  ColumnBuilder increments(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return integer(
      name,
      mutation: mutation,
    ).unsigned().primaryKey().autoIncrement();
  }

  ColumnBuilder id([String name = 'id']) => bigIncrements(name);

  ColumnBuilder bigIncrements(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => bigInteger(
    name,
    mutation: mutation,
    unsigned: true,
  ).primaryKey().autoIncrement();

  ColumnBuilder mediumIncrements(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => mediumInteger(
    name,
    mutation: mutation,
    unsigned: true,
  ).primaryKey().autoIncrement();

  ColumnBuilder smallIncrements(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => smallInteger(
    name,
    mutation: mutation,
    unsigned: true,
  ).primaryKey().autoIncrement();

  ColumnBuilder tinyIncrements(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => tinyInteger(
    name,
    mutation: mutation,
    unsigned: true,
  ).primaryKey().autoIncrement();

  ColumnBuilder integerIncrements(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => increments(name, mutation: mutation);

  /// Adds a UUID primary key column.
  ColumnBuilder uuid(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.uuid(), mutation: mutation);
  }

  ColumnBuilder ulid(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    int length = 26,
  }) => column(name, ColumnType.string(length: length), mutation: mutation);

  /// Adds a variable length string column.
  ColumnBuilder string(
    String name, {
    int length = 255,
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, ColumnType.string(length: length), mutation: mutation);
  }

  ColumnBuilder char(
    String name, {
    int length = 255,
    ColumnMutation mutation = ColumnMutation.add,
  }) => column(name, ColumnType.string(length: length), mutation: mutation);

  ColumnBuilder geometry(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => column(name, const ColumnType.geometry(), mutation: mutation);

  ColumnBuilder geography(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => column(name, const ColumnType.geography(), mutation: mutation);

  ColumnBuilder vector(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    int? dimensions,
  }) => column(
    name,
    ColumnType.vector(dimensions: dimensions),
    mutation: mutation,
  );

  ColumnBuilder point(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => column(name, const ColumnType.custom('POINT'), mutation: mutation);

  ColumnBuilder lineString(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => column(name, const ColumnType.custom('LINESTRING'), mutation: mutation);

  ColumnBuilder polygon(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => column(name, const ColumnType.custom('POLYGON'), mutation: mutation);

  ColumnBuilder multiPoint(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => column(name, const ColumnType.custom('MULTIPOINT'), mutation: mutation);

  ColumnBuilder multiLineString(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => column(
    name,
    const ColumnType.custom('MULTILINESTRING'),
    mutation: mutation,
  );

  ColumnBuilder multiPolygon(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) =>
      column(name, const ColumnType.custom('MULTIPOLYGON'), mutation: mutation);

  ColumnBuilder geometryCollection(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => column(
    name,
    const ColumnType.custom('GEOMETRYCOLLECTION'),
    mutation: mutation,
  );

  /// Adds a text column.
  ColumnBuilder text(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.text(), mutation: mutation);
  }

  ColumnBuilder tinyText(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => column(name, const ColumnType.text(), mutation: mutation);

  ColumnBuilder mediumText(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => column(name, const ColumnType.longText(), mutation: mutation);

  ColumnBuilder ipAddress([
    String name = 'ip_address',
    ColumnMutation mutation = ColumnMutation.add,
  ]) => string(name, length: 45, mutation: mutation);

  ColumnBuilder macAddress([
    String name = 'mac_address',
    ColumnMutation mutation = ColumnMutation.add,
  ]) => string(name, length: 17, mutation: mutation);

  ColumnBuilder rememberToken({ColumnMutation mutation = ColumnMutation.add}) =>
      string('remember_token', length: 100, mutation: mutation).nullable();

  /// Adds an integer column.
  ColumnBuilder integer(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    bool unsigned = false,
  }) {
    final builder = column(
      name,
      const ColumnType.integer(),
      mutation: mutation,
    );
    return unsigned ? builder.unsigned() : builder;
  }

  ColumnBuilder smallInteger(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    bool unsigned = false,
  }) {
    final builder = column(
      name,
      const ColumnType.smallInteger(),
      mutation: mutation,
    );
    return unsigned ? builder.unsigned() : builder;
  }

  ColumnBuilder mediumInteger(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    bool unsigned = false,
  }) {
    final builder = column(
      name,
      const ColumnType.mediumInteger(),
      mutation: mutation,
    );
    return unsigned ? builder.unsigned() : builder;
  }

  ColumnBuilder tinyInteger(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    bool unsigned = false,
  }) {
    final builder = column(
      name,
      const ColumnType.tinyInteger(),
      mutation: mutation,
    );
    return unsigned ? builder.unsigned() : builder;
  }

  /// Adds a big integer column.
  ColumnBuilder bigInteger(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    bool unsigned = false,
  }) {
    final builder = column(
      name,
      const ColumnType.bigInteger(),
      mutation: mutation,
    );
    return unsigned ? builder.unsigned() : builder;
  }

  /// Adds an unsigned big integer column.
  ColumnBuilder unsignedBigInteger(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => bigInteger(name, mutation: mutation, unsigned: true);

  ColumnBuilder unsignedInteger(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => integer(name, mutation: mutation, unsigned: true);

  ColumnBuilder unsignedMediumInteger(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => mediumInteger(name, mutation: mutation, unsigned: true);

  ColumnBuilder unsignedSmallInteger(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => smallInteger(name, mutation: mutation, unsigned: true);

  ColumnBuilder unsignedTinyInteger(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => tinyInteger(name, mutation: mutation, unsigned: true);

  /// Adds a boolean column.
  ColumnBuilder boolean(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.boolean(), mutation: mutation);
  }

  ColumnBuilder foreignId(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    bool unsigned = true,
    String? constrainedTable,
    String referencedColumn = 'id',
    ReferenceAction onDelete = ReferenceAction.noAction,
    ReferenceAction onUpdate = ReferenceAction.noAction,
  }) {
    final builder = bigInteger(name, mutation: mutation, unsigned: unsigned);
    if (constrainedTable != null) {
      foreign(
        [name],
        references: constrainedTable,
        referencedColumns: [referencedColumn],
        onDelete: onDelete,
        onUpdate: onUpdate,
      );
    }
    return builder;
  }

  ColumnBuilder foreignUuid(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    bool nullable = false,
    String? constrainedTable,
    String referencedColumn = 'id',
    ReferenceAction onDelete = ReferenceAction.noAction,
    ReferenceAction onUpdate = ReferenceAction.noAction,
  }) {
    final builder = uuid(name, mutation: mutation);
    if (nullable) {
      builder.nullable();
    }
    if (constrainedTable != null) {
      foreign(
        [name],
        references: constrainedTable,
        referencedColumns: [referencedColumn],
        onDelete: onDelete,
        onUpdate: onUpdate,
      );
    }
    return builder;
  }

  ColumnBuilder foreignUlid(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    bool nullable = false,
    String? constrainedTable,
    String referencedColumn = 'id',
    ReferenceAction onDelete = ReferenceAction.noAction,
    ReferenceAction onUpdate = ReferenceAction.noAction,
  }) {
    final builder = ulid(name, mutation: mutation);
    if (nullable) {
      builder.nullable();
    }
    if (constrainedTable != null) {
      foreign(
        [name],
        references: constrainedTable,
        referencedColumns: [referencedColumn],
        onDelete: onDelete,
        onUpdate: onUpdate,
      );
    }
    return builder;
  }

  ColumnBuilder float(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    int? precision,
    int? scale,
  }) {
    return column(
      name,
      ColumnType(ColumnTypeName.float, precision: precision, scale: scale),
      mutation: mutation,
    );
  }

  ColumnBuilder double(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    int? precision,
    int? scale,
  }) {
    return column(
      name,
      ColumnType(
        ColumnTypeName.doublePrecision,
        precision: precision,
        scale: scale,
      ),
      mutation: mutation,
    );
  }

  /// Adds a binary column.
  ColumnBuilder binary(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.binary(), mutation: mutation);
  }

  ColumnBuilder dateTime(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    bool timezoneAware = false,
    int? precision,
  }) => column(
    name,
    ColumnType.timestamp(timezoneAware: timezoneAware, precision: precision),
    mutation: mutation,
  );

  ColumnBuilder dateTimeTz(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    int? precision,
  }) => dateTime(
    name,
    mutation: mutation,
    timezoneAware: true,
    precision: precision,
  );

  /// Adds a timestamp column.
  ColumnBuilder timestamp(
    String name, {
    bool timezoneAware = false,
    ColumnMutation mutation = ColumnMutation.add,
    int? precision,
  }) {
    return column(
      name,
      ColumnType.timestamp(timezoneAware: timezoneAware, precision: precision),
      mutation: mutation,
    );
  }

  ColumnBuilder timestampTz(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    int? precision,
  }) => timestamp(
    name,
    mutation: mutation,
    timezoneAware: true,
    precision: precision,
  );

  /// Adds a decimal column.
  ColumnBuilder decimal(
    String name, {
    int precision = 10,
    int scale = 0,
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      ColumnType.decimal(precision: precision, scale: scale),
      mutation: mutation,
    );
  }

  /// Adds a JSON column.
  ColumnBuilder json(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.json(), mutation: mutation);
  }

  ColumnBuilder jsonb(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.jsonb(), mutation: mutation);
  }

  ColumnBuilder date(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, ColumnType.date(), mutation: mutation);
  }

  ColumnBuilder year(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => column(name, ColumnType.custom('year'), mutation: mutation);

  ColumnBuilder computed(
    String name,
    String expression, {
    ColumnMutation mutation = ColumnMutation.add,
    bool stored = false,
    ColumnType type = const ColumnType.text(),
  }) {
    final builder = column(name, type, mutation: mutation);
    return stored
        ? builder.storedAs(expression)
        : builder.virtualAs(expression);
  }

  ColumnBuilder time(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    bool timezoneAware = false,
  }) {
    return column(
      name,
      ColumnType.time(timezoneAware: timezoneAware),
      mutation: mutation,
    );
  }

  ColumnBuilder timeTz(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return time(name, timezoneAware: true, mutation: mutation);
  }

  ColumnBuilder longText(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.longText(), mutation: mutation);
  }

  ColumnBuilder enum_(
    String name,
    List<String> allowedValues, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      const ColumnType.enumType(),
      mutation: mutation,
    ).allowedValues(allowedValues);
  }

  ColumnBuilder set(
    String name,
    List<String> allowedValues, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      const ColumnType.setType(),
      mutation: mutation,
    ).allowedValues(allowedValues);
  }

  /// Adds a custom column definition.
  ColumnBuilder column(
    String name,
    ColumnType type, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    final entry = _ColumnEntry(
      name: name,
      kind: mutation == ColumnMutation.add
          ? ColumnCommandKind.add
          : ColumnCommandKind.alter,
      definition: ColumnDefinition(name: name, type: type),
    );
    _columns.add(entry);
    return ColumnBuilder._(entry);
  }

  /// Drops one or more columns.
  void dropColumn(String name, [List<String>? additional]) {
    _columns.add(_ColumnEntry.drop(name));
    if (additional != null) {
      for (final extra in additional) {
        _columns.add(_ColumnEntry.drop(extra));
      }
    }
  }

  void dropRememberToken() => dropColumn('remember_token');

  /// Drops multiple columns.
  void dropColumns(Iterable<String> columns) {
    for (final column in columns) {
      _columns.add(_ColumnEntry.drop(column));
    }
  }

  /// Renames an existing column.
  void renameColumn(String from, String to) {
    _renamedColumns.add(ColumnRename(from: from, to: to));
  }

  /// Adds created_at and updated_at timestamps.
  void timestamps({
    bool useCurrent = true,
    bool timezoneAware = false,
    bool nullable = false,
    int precision = 3,
  }) {
    final created = timestamp(
      'created_at',
      timezoneAware: timezoneAware,
      precision: precision,
    );
    final updated = timestamp(
      'updated_at',
      timezoneAware: timezoneAware,
      precision: precision,
    );
    if (useCurrent) {
      created.useCurrentTimestamp();
      updated.useCurrentTimestamp().useCurrentOnUpdate();
    }
    if (nullable) {
      created.nullable();
      updated.nullable();
    }
  }

  void timestampsTz({bool useCurrent = true, int precision = 3}) {
    timestamps(
      useCurrent: useCurrent,
      timezoneAware: true,
      precision: precision,
    );
  }

  void nullableTimestamps({bool timezoneAware = false, int precision = 3}) {
    timestamps(
      useCurrent: false,
      timezoneAware: timezoneAware,
      nullable: true,
      precision: precision,
    );
  }

  void nullableTimestampsTz({int precision = 3}) {
    timestamps(
      useCurrent: false,
      timezoneAware: true,
      nullable: true,
      precision: precision,
    );
  }

  List<ColumnBuilder> datetimes({
    bool timezoneAware = false,
    int precision = 3,
  }) {
    final created = dateTime(
      'created_at',
      timezoneAware: timezoneAware,
      precision: precision,
    ).nullable();
    final updated = dateTime(
      'updated_at',
      timezoneAware: timezoneAware,
      precision: precision,
    ).nullable();
    return [created, updated];
  }

  void softDeletes({
    String columnName = 'deleted_at',
    bool timezoneAware = false,
    int precision = 3,
  }) {
    timestamp(
      columnName,
      timezoneAware: timezoneAware,
      precision: precision,
    ).nullable();
  }

  void softDeletesTz({String columnName = 'deleted_at', int precision = 3}) {
    softDeletes(
      columnName: columnName,
      timezoneAware: true,
      precision: precision,
    );
  }

  void softDeletesDatetime({
    String columnName = 'deleted_at',
    int precision = 3,
  }) {
    dateTime(columnName, precision: precision).nullable();
  }

  void morphs(String name, {bool nullable = false}) {
    _addMorphs(name, nullable: nullable, keyType: MorphKeyType.numeric);
  }

  void numericMorphs(String name, {bool nullable = false}) =>
      morphs(name, nullable: nullable);

  void uuidMorphs(String name, {bool nullable = false}) {
    _addMorphs(name, nullable: nullable, keyType: MorphKeyType.uuid);
  }

  void ulidMorphs(String name, {bool nullable = false}) {
    _addMorphs(name, nullable: nullable, keyType: MorphKeyType.ulid);
  }

  void nullableMorphs(String name) {
    morphs(name, nullable: true);
  }

  void nullableNumericMorphs(String name) => morphs(name, nullable: true);

  void nullableUuidMorphs(String name) {
    uuidMorphs(name, nullable: true);
  }

  void nullableUlidMorphs(String name) {
    ulidMorphs(name, nullable: true);
  }

  /// Adds an index across the provided columns.
  IndexDefinition index(
    Iterable<String> columns, {
    String? name,
    Map<String, Map<String, Object?>>? driverOptions,
  }) {
    return _addIndex(
      columns,
      IndexType.regular,
      nameSuffix: 'index',
      explicitName: name,
      driverOptions: driverOptions,
    );
  }

  /// Adds a unique index across the provided columns.
  IndexDefinition unique(
    Iterable<String> columns, {
    String? name,
    Map<String, Map<String, Object?>>? driverOptions,
  }) {
    return _addIndex(
      columns,
      IndexType.unique,
      nameSuffix: 'unique',
      explicitName: name,
      driverOptions: driverOptions,
    );
  }

  IndexDefinition fullText(
    Iterable<String> columns, {
    String? name,
    SqliteFullTextOptions? sqlite,
  }) {
    return _addIndex(
      columns,
      IndexType.fullText,
      nameSuffix: 'fulltext',
      explicitName: name,
      driverOptions: _sqliteDriverOptions(
        'fts',
        sqlite?.toJson(),
        sqlite?.hasOptions ?? false,
      ),
    );
  }

  IndexDefinition spatialIndex(
    Iterable<String> columns, {
    String? name,
    SqliteSpatialIndexOptions? sqlite,
  }) {
    return _addIndex(
      columns,
      IndexType.spatial,
      nameSuffix: 'spatial',
      explicitName: name,
      driverOptions: _sqliteDriverOptions(
        'spatial',
        sqlite?.toJson(),
        sqlite?.hasOptions ?? false,
      ),
    );
  }

  IndexDefinition rawIndex(String expression, {String? name}) {
    final normalized = _normalizeIdentifierSegment(expression);
    final definition = IndexDefinition(
      name: name ?? '${table}_${normalized}_raw_index',
      type: IndexType.regular,
      columns: [expression],
      raw: true,
      driverOptions: const {},
    );
    _indexes.add(_IndexEntry(definition));
    return definition;
  }

  /// Adds a primary key index across the provided columns.
  IndexDefinition primary(Iterable<String> columns, {String? name}) {
    return _addIndex(
      columns,
      IndexType.primary,
      nameSuffix: 'primary',
      explicitName: name,
      driverOptions: null,
    );
  }

  /// Drops an index by name.
  void dropIndex(String name) {
    _droppedIndexes.add(name);
  }

  /// Adds a foreign key definition.
  ForeignKeyBuilder foreign(
    Iterable<String> columns, {
    required String references,
    required Iterable<String> referencedColumns,
    ReferenceAction onDelete = ReferenceAction.noAction,
    ReferenceAction onUpdate = ReferenceAction.noAction,
    String? name,
  }) {
    final definition = ForeignKeyDefinition(
      name: name ?? _defaultConstraintName(columns, suffix: 'foreign'),
      columns: List.unmodifiable(columns),
      referencedTable: references,
      referencedColumns: List.unmodifiable(referencedColumns),
      onDelete: onDelete,
      onUpdate: onUpdate,
    );
    final entry = ForeignKeyEntry(definition);
    _foreignKeys.add(entry);
    return ForeignKeyBuilder(entry);
  }

  /// Drops a foreign key by name.
  void dropForeign(String name) {
    _droppedForeignKeys.add(name);
  }

  Map<String, Object?> toJson() => {
    'table': table,
    'operation': operation.name,
    if (temporary) 'temporary': true,
    if (engine != null) 'engine': engine,
    if (tableCharset != null) 'charset': tableCharset,
    if (tableCollation != null) 'collation': tableCollation,
    if (_tableComment != null) 'comment': _tableComment,
    'columns': columns.map((c) => c.toJson()).toList(),
    if (_renamedColumns.isNotEmpty)
      'renamedColumns': _renamedColumns.map((r) => r.toJson()).toList(),
    if (_indexes.isNotEmpty || _droppedIndexes.isNotEmpty)
      'indexes': indexes.map((i) => i.toJson()).toList(),
    if (_foreignKeys.isNotEmpty || _droppedForeignKeys.isNotEmpty)
      'foreignKeys': foreignKeys.map((f) => f.toJson()).toList(),
  };

  IndexDefinition _addIndex(
    Iterable<String> columns,
    IndexType type, {
    required String nameSuffix,
    String? explicitName,
    Map<String, Map<String, Object?>>? driverOptions,
  }) {
    final normalizedColumns = List<String>.unmodifiable(columns);
    final name =
        explicitName ??
        _defaultConstraintName(normalizedColumns, suffix: nameSuffix);
    final definition = IndexDefinition(
      name: name,
      type: type,
      columns: normalizedColumns,
      driverOptions: driverOptions ?? const {},
    );
    _indexes.add(_IndexEntry(definition));
    return definition;
  }

  Map<String, Map<String, Object?>>? _sqliteDriverOptions(
    String key,
    Map<String, Object?>? value,
    bool hasOptions,
  ) {
    if (!hasOptions || value == null || value.isEmpty) {
      return null;
    }
    return {
      'sqlite': {key: value},
    };
  }

  String _defaultConstraintName(
    Iterable<String> columns, {
    required String suffix,
  }) {
    final columnPart = columns.join('_');
    return '${table}_${columnPart}_$suffix';
  }

  String _normalizeIdentifierSegment(String value) {
    final collapsed = value
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return collapsed.isEmpty ? 'expr' : collapsed;
  }

  void _addMorphs(
    String name, {
    required bool nullable,
    required MorphKeyType keyType,
  }) {
    final idName = '${name}_id';
    final typeName = '${name}_type';

    late final ColumnBuilder idBuilder;
    switch (keyType) {
      case MorphKeyType.numeric:
        idBuilder = bigInteger(idName, unsigned: true);
        break;
      case MorphKeyType.uuid:
        idBuilder = uuid(idName);
        break;
      case MorphKeyType.ulid:
        idBuilder = ulid(idName);
        break;
    }
    final typeBuilder = string(typeName);

    if (nullable) {
      idBuilder.nullable();
      typeBuilder.nullable();
    }

    index([typeName, idName]);
  }

  List<IndexDefinition> _buildFluentIndexDefinitions() {
    final definitions = <IndexDefinition>[];
    for (final column in _columns) {
      final definition = column.definitionOrNull;
      if (definition == null) {
        continue;
      }

      if (definition.primaryKey) {
        definitions.add(
          IndexDefinition(
            name: _defaultConstraintName([definition.name], suffix: 'pkey'),
            type: IndexType.primary,
            columns: [definition.name],
            driverOptions: const {},
          ),
        );
      }

      if (definition.unique) {
        definitions.add(
          IndexDefinition(
            name: _defaultConstraintName([definition.name], suffix: 'unique'),
            type: IndexType.unique,
            columns: [definition.name],
            driverOptions: const {},
          ),
        );
      }

      if (definition.indexed) {
        definitions.add(
          IndexDefinition(
            name: _defaultConstraintName([definition.name], suffix: 'index'),
            type: IndexType.regular,
            columns: [definition.name],
            driverOptions: const {},
          ),
        );
      }
    }
    return definitions;
  }
}

class ColumnBuilder {
  ColumnBuilder._(this._entry);

  final _ColumnEntry _entry;

  ColumnDefinition get _definition => _entry.definition;

  ColumnBuilder unsigned([bool value = true]) {
    _entry.updateDefinition(_definition.copyWith(unsigned: value));
    return this;
  }

  ColumnBuilder nullable([bool value = true]) {
    _entry.updateDefinition(_definition.copyWith(nullable: value));
    return this;
  }

  ColumnBuilder unique([bool value = true]) {
    _entry.updateDefinition(_definition.copyWith(unique: value));
    return this;
  }

  ColumnBuilder indexed([bool value = true]) {
    _entry.updateDefinition(_definition.copyWith(indexed: value));
    return this;
  }

  ColumnBuilder primaryKey([bool value = true]) {
    _entry.updateDefinition(_definition.copyWith(primaryKey: value));
    return this;
  }

  ColumnBuilder autoIncrement([bool value = true]) {
    _entry.updateDefinition(_definition.copyWith(autoIncrement: value));
    return this;
  }

  ColumnBuilder defaultValue(Object? value) {
    _entry.updateDefinition(
      _definition.copyWith(defaultValue: ColumnDefault.literal(value)),
    );
    return this;
  }

  ColumnBuilder defaultExpression(String sql) {
    _entry.updateDefinition(
      _definition.copyWith(defaultValue: ColumnDefault.expression(sql)),
    );
    return this;
  }

  ColumnBuilder useCurrentTimestamp() {
    _entry.updateDefinition(
      _definition.copyWith(
        defaultValue: const ColumnDefault.currentTimestamp(),
      ),
    );
    return this;
  }

  ColumnBuilder clearDefault() {
    _entry.updateDefinition(_definition.copyWith(clearDefault: true));
    return this;
  }

  ColumnBuilder comment(String text) {
    _entry.updateDefinition(_definition.copyWith(comment: text));
    return this;
  }

  ColumnBuilder charset(String value) {
    _entry.updateDefinition(_definition.copyWith(charset: value));
    return this;
  }

  ColumnBuilder collation(String value) {
    _entry.updateDefinition(_definition.copyWith(collation: value));
    return this;
  }

  ColumnBuilder driverOverride(
    String driver, {
    ColumnType? type,
    String? sqlType,
    ColumnDefault? defaultValue,
    String? collation,
    String? charset,
  }) {
    if (type == null &&
        sqlType == null &&
        defaultValue == null &&
        collation == null &&
        charset == null) {
      throw ArgumentError('At least one override value is required.');
    }
    if (type != null && sqlType != null) {
      throw ArgumentError(
        'Provide either a logical ColumnType or a raw sqlType string.',
      );
    }
    if (sqlType != null && sqlType.trim().isEmpty) {
      throw ArgumentError.value(sqlType, 'sqlType', 'must not be empty.');
    }
    final overrides = Map<String, ColumnDriverOverride>.from(
      _definition.driverOverrides,
    );
    final merged = (overrides[driver] ?? const ColumnDriverOverride()).merge(
      ColumnDriverOverride(
        type: type,
        sqlType: sqlType,
        defaultValue: defaultValue,
        collation: collation,
        charset: charset,
      ),
    );
    overrides[driver] = merged;
    _entry.updateDefinition(
      _definition.copyWith(driverOverrides: Map.unmodifiable(overrides)),
    );
    return this;
  }

  ColumnBuilder driverType(String driver, ColumnType type) =>
      driverOverride(driver, type: type);

  ColumnBuilder driverSqlType(String driver, String sqlType) =>
      driverOverride(driver, sqlType: sqlType);

  ColumnBuilder driverDefault(
    String driver, {
    ColumnDefault? defaultValue,
    Object? value,
    String? expression,
    bool useCurrentTimestamp = false,
  }) {
    ColumnDefault? resolved = defaultValue;
    if (value != null && expression != null) {
      throw ArgumentError('Provide either value or expression, not both.');
    }
    if (useCurrentTimestamp) {
      resolved = const ColumnDefault.currentTimestamp();
    } else if (expression != null) {
      resolved = ColumnDefault.expression(expression);
    } else if (value != null) {
      resolved = ColumnDefault.literal(value);
    }
    if (resolved == null) {
      throw ArgumentError('A default value must be provided.');
    }
    return driverOverride(driver, defaultValue: resolved);
  }

  ColumnBuilder after(String column) {
    _entry.updateDefinition(
      _definition.copyWith(afterColumn: column, first: false),
    );
    return this;
  }

  ColumnBuilder first() {
    _entry.updateDefinition(
      _definition.copyWith(first: true, afterColumn: null),
    );
    return this;
  }

  ColumnBuilder useCurrentOnUpdate([bool value = true]) {
    _entry.updateDefinition(_definition.copyWith(useCurrentOnUpdate: value));
    return this;
  }

  ColumnBuilder generatedAs(String expression) {
    _entry.updateDefinition(_definition.copyWith(generatedAs: expression));
    return this;
  }

  ColumnBuilder storedAs(String expression) {
    _entry.updateDefinition(
      _definition.copyWith(storedAs: expression, virtualAs: null),
    );
    return this;
  }

  ColumnBuilder virtualAs(String expression) {
    _entry.updateDefinition(
      _definition.copyWith(virtualAs: expression, storedAs: null),
    );
    return this;
  }

  ColumnBuilder invisible([bool value = true]) {
    _entry.updateDefinition(_definition.copyWith(invisible: value));
    return this;
  }

  ColumnBuilder always([bool value = true]) {
    _entry.updateDefinition(_definition.copyWith(always: value));
    return this;
  }

  ColumnBuilder allowedValues(List<String> values) {
    _entry.updateDefinition(
      _definition.copyWith(allowedValues: List.unmodifiable(values)),
    );
    return this;
  }

  /// Marks the column command as an alteration (e.g. `$table->string(...)->change()`).
  ColumnBuilder change() {
    _entry.markAsAlter();
    return this;
  }
}

class _ColumnEntry {
  _ColumnEntry({
    required this.name,
    required ColumnCommandKind kind,
    ColumnDefinition? definition,
  }) : _kind = kind,
       _definition = definition;

  factory _ColumnEntry.drop(String name) =>
      _ColumnEntry(name: name, kind: ColumnCommandKind.drop);

  final String name;
  ColumnCommandKind get kind => _kind;
  ColumnCommandKind _kind;
  ColumnDefinition? _definition;

  ColumnDefinition get definition {
    if (_definition == null) {
      throw StateError('Column "$name" does not have a definition.');
    }
    return _definition!;
  }

  ColumnDefinition? get definitionOrNull => _definition;

  void updateDefinition(ColumnDefinition definition) {
    if (kind == ColumnCommandKind.drop) {
      throw StateError('Cannot update a dropped column.');
    }
    _definition = definition;
  }

  void markAsAlter() {
    if (_kind == ColumnCommandKind.drop) {
      throw StateError('Cannot alter a dropped column.');
    }
    _kind = ColumnCommandKind.alter;
  }

  ColumnCommand toCommand() =>
      ColumnCommand(kind: _kind, name: name, definition: _definition);
}

class _IndexEntry {
  _IndexEntry(this.definition);

  final IndexDefinition definition;
}

class ForeignKeyEntry {
  ForeignKeyEntry(this.definition);

  ForeignKeyDefinition definition;
}

class ForeignKeyBuilder {
  ForeignKeyBuilder(this._entry);

  final ForeignKeyEntry _entry;

  ForeignKeyBuilder onDelete(ReferenceAction action) {
    _entry.definition = _entry.definition.copyWith(onDelete: action);
    return this;
  }

  ForeignKeyBuilder onUpdate(ReferenceAction action) {
    _entry.definition = _entry.definition.copyWith(onUpdate: action);
    return this;
  }

  ForeignKeyDefinition get definition => _entry.definition;
}
