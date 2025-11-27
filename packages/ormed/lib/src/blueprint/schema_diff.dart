import 'schema_driver.dart';
import 'schema_plan.dart';
import 'schema_snapshot.dart';
import 'table_blueprint.dart';

/// Describes the action a diff entry represents.
enum SchemaDiffAction {
  createTable,
  dropTable,
  renameTable,
  addColumn,
  dropColumn,
  alterColumn,
  renameColumn,
  addIndex,
  dropIndex,
  addForeignKey,
  dropForeignKey,
  rawSql,
}

/// Severity used when presenting schema change diagnostics.
enum SchemaDiffSeverity { info, warning }

/// One human-readable entry produced by the schema differ.
class SchemaDiffEntry {
  SchemaDiffEntry({
    required this.action,
    required this.description,
    this.target,
    this.notes = const <String>[],
    this.severity = SchemaDiffSeverity.info,
  });

  final SchemaDiffAction action;
  final String description;
  final String? target;
  final List<String> notes;
  final SchemaDiffSeverity severity;

  String get symbol {
    if (severity == SchemaDiffSeverity.warning) return '!';
    switch (action) {
      case SchemaDiffAction.createTable:
      case SchemaDiffAction.addColumn:
      case SchemaDiffAction.addIndex:
      case SchemaDiffAction.addForeignKey:
        return '+';
      case SchemaDiffAction.dropTable:
      case SchemaDiffAction.dropColumn:
      case SchemaDiffAction.dropIndex:
      case SchemaDiffAction.dropForeignKey:
        return '-';
      case SchemaDiffAction.renameTable:
      case SchemaDiffAction.renameColumn:
      case SchemaDiffAction.alterColumn:
        return '~';
      case SchemaDiffAction.rawSql:
        return '?';
    }
  }
}

/// Aggregated diff output describing a migration plan.
class SchemaDiff {
  const SchemaDiff(this.entries);

  final List<SchemaDiffEntry> entries;

  bool get isEmpty => entries.isEmpty;
  Iterable<SchemaDiffEntry> get warnings =>
      entries.where((entry) => entry.severity == SchemaDiffSeverity.warning);
}

/// Computes a diff between the desired schema plan and the current snapshot.
class SchemaDiffer {
  SchemaDiff diff({
    required SchemaPlan plan,
    required SchemaSnapshot snapshot,
  }) {
    final lookup = SnapshotLookup(snapshot);
    final entries = <SchemaDiffEntry>[];

    for (final mutation in plan.mutations) {
      switch (mutation.operation) {
        case SchemaMutationOperation.createTable:
          final blueprint = mutation.blueprint!;
          entries.add(_describeCreateTable(blueprint, lookup));
          break;
        case SchemaMutationOperation.alterTable:
          entries.addAll(_describeAlterTable(mutation.blueprint!, lookup));
          break;
        case SchemaMutationOperation.dropTable:
          entries.add(_describeDropTable(mutation.dropOptions!, lookup));
          break;
        case SchemaMutationOperation.renameTable:
          entries.add(_describeRenameTable(mutation.rename!, lookup));
          break;
        case SchemaMutationOperation.rawSql:
          entries.add(
            SchemaDiffEntry(
              action: SchemaDiffAction.rawSql,
              description: 'Execute raw SQL: ${mutation.sql}',
            ),
          );
          break;
        default:
          throw StateError(
            'Unsupported schema mutation operation: '
            '${mutation.operation}',
          );
      }
    }

    return SchemaDiff(entries);
  }

  SchemaDiffEntry _describeCreateTable(
    TableBlueprint blueprint,
    SnapshotLookup lookup,
  ) {
    final table = TableRef.parse(blueprint.table);
    final exists = lookup.tableExists(table);
    final columnNames =
        blueprint.columns
            .where((column) => column.kind != ColumnCommandKind.drop)
            .map((column) => column.name)
            .toList()
          ..sort();
    final indexCommands = blueprint.indexes
        .where((command) => command.kind == IndexCommandKind.add)
        .map((command) => command.definition!)
        .toList();
    final foreignCommands = blueprint.foreignKeys
        .where((command) => command.kind == ForeignKeyCommandKind.add)
        .map((command) => command.definition!)
        .toList();

    final notes = <String>[];
    if (columnNames.isNotEmpty) {
      notes.add('columns: ${columnNames.join(', ')}');
    }
    if (indexCommands.isNotEmpty) {
      notes.add('indexes: ${indexCommands.map((i) => i.name).join(', ')}');
    }
    if (foreignCommands.isNotEmpty) {
      notes.add(
        'foreign keys: ${foreignCommands.map((f) => f.name).join(', ')}',
      );
    }

    return SchemaDiffEntry(
      action: SchemaDiffAction.createTable,
      severity: exists ? SchemaDiffSeverity.warning : SchemaDiffSeverity.info,
      description: exists
          ? 'Create table ${table.displayName} (already exists)'
          : 'Create table ${table.displayName}',
      notes: notes,
      target: table.displayName,
    );
  }

  SchemaDiffEntry _describeDropTable(
    DropTableOptions options,
    SnapshotLookup lookup,
  ) {
    final table = TableRef.parse(options.table);
    final exists = lookup.tableExists(table);
    final notes = <String>[];
    if (!exists) {
      notes.add('table does not exist');
    }
    if (options.cascade) {
      notes.add('cascade');
    }
    return SchemaDiffEntry(
      action: SchemaDiffAction.dropTable,
      severity: exists ? SchemaDiffSeverity.info : SchemaDiffSeverity.warning,
      description: 'Drop table ${table.displayName}',
      notes: notes,
      target: table.displayName,
    );
  }

  SchemaDiffEntry _describeRenameTable(
    RenameTableOptions options,
    SnapshotLookup lookup,
  ) {
    final from = TableRef.parse(options.from);
    final to = TableRef.parse(options.to);
    final fromExists = lookup.tableExists(from);
    final toExists = lookup.tableExists(to);
    final notes = <String>[];
    if (!fromExists) {
      notes.add('source table missing');
    }
    if (toExists) {
      notes.add('target table already exists');
    }
    return SchemaDiffEntry(
      action: SchemaDiffAction.renameTable,
      severity: (!fromExists || toExists)
          ? SchemaDiffSeverity.warning
          : SchemaDiffSeverity.info,
      description: 'Rename table ${from.displayName} -> ${to.displayName}',
      notes: notes,
      target: from.displayName,
    );
  }

  Iterable<SchemaDiffEntry> _describeAlterTable(
    TableBlueprint blueprint,
    SnapshotLookup lookup,
  ) sync* {
    final table = TableRef.parse(blueprint.table);
    final tableExists = lookup.tableExists(table);
    if (!tableExists) {
      yield SchemaDiffEntry(
        action: SchemaDiffAction.alterColumn,
        severity: SchemaDiffSeverity.warning,
        description: 'Alter table ${table.displayName}',
        notes: const ['table does not exist'],
        target: table.displayName,
      );
      return;
    }

    for (final column in blueprint.columns) {
      switch (column.kind) {
        case ColumnCommandKind.add:
          final exists = lookup.columnExists(table, column.name);
          final definition = column.definition;
          final notes = <String>[];
          if (definition != null) {
            notes.add('type: ${_formatColumnType(definition.type)}');
            if (!definition.nullable) notes.add('not null');
            if (definition.defaultValue != null) {
              notes.add('default: ${_formatDefault(definition.defaultValue!)}');
            }
          }
          if (exists) notes.add('column already exists');
          yield SchemaDiffEntry(
            action: SchemaDiffAction.addColumn,
            severity: exists
                ? SchemaDiffSeverity.warning
                : SchemaDiffSeverity.info,
            description: 'Add column ${table.displayName}.${column.name}',
            notes: notes,
            target: '${table.displayName}.${column.name}',
          );
        case ColumnCommandKind.alter:
          yield SchemaDiffEntry(
            action: SchemaDiffAction.alterColumn,
            description: 'Alter column ${table.displayName}.${column.name}',
            target: '${table.displayName}.${column.name}',
          );
        case ColumnCommandKind.drop:
          final exists = lookup.columnExists(table, column.name);
          yield SchemaDiffEntry(
            action: SchemaDiffAction.dropColumn,
            severity: exists
                ? SchemaDiffSeverity.info
                : SchemaDiffSeverity.warning,
            description: 'Drop column ${table.displayName}.${column.name}',
            notes: exists ? const [] : const ['column missing'],
            target: '${table.displayName}.${column.name}',
          );
      }
    }

    for (final rename in blueprint.renamedColumns) {
      final sourceExists = lookup.columnExists(table, rename.from);
      final targetExists = lookup.columnExists(table, rename.to);
      final notes = <String>[];
      if (!sourceExists) notes.add('source column missing');
      if (targetExists) notes.add('target column already exists');
      yield SchemaDiffEntry(
        action: SchemaDiffAction.renameColumn,
        severity: (!sourceExists || targetExists)
            ? SchemaDiffSeverity.warning
            : SchemaDiffSeverity.info,
        description:
            'Rename column ${table.displayName}.${rename.from} '
            '-> ${rename.to}',
        notes: notes,
        target: '${table.displayName}.${rename.from}',
      );
    }

    for (final index in blueprint.indexes) {
      switch (index.kind) {
        case IndexCommandKind.add:
          final definition = index.definition;
          if (definition == null) continue;
          final exists = lookup.indexExists(table, definition.name);
          final notes = <String>['columns: ${definition.columns.join(', ')}'];
          if (exists) notes.add('index already exists');
          yield SchemaDiffEntry(
            action: SchemaDiffAction.addIndex,
            severity: exists
                ? SchemaDiffSeverity.warning
                : SchemaDiffSeverity.info,
            description: 'Add index ${definition.name} on ${table.displayName}',
            notes: notes,
            target: definition.name,
          );
        case IndexCommandKind.drop:
          final exists = lookup.indexExists(table, index.name);
          yield SchemaDiffEntry(
            action: SchemaDiffAction.dropIndex,
            severity: exists
                ? SchemaDiffSeverity.info
                : SchemaDiffSeverity.warning,
            description: 'Drop index ${index.name} on ${table.displayName}',
            notes: exists ? const [] : const ['index missing'],
            target: index.name,
          );
      }
    }

    for (final foreign in blueprint.foreignKeys) {
      switch (foreign.kind) {
        case ForeignKeyCommandKind.add:
          final definition = foreign.definition;
          if (definition == null) continue;
          final exists = lookup.foreignKeyExists(table, definition.name);
          final notes = <String>[
            'columns: ${definition.columns.join(', ')} -> '
                '${definition.referencedTable}(${definition.referencedColumns.join(', ')})',
          ];
          if (exists) notes.add('foreign key already exists');
          yield SchemaDiffEntry(
            action: SchemaDiffAction.addForeignKey,
            severity: exists
                ? SchemaDiffSeverity.warning
                : SchemaDiffSeverity.info,
            description:
                'Add foreign key ${definition.name} on ${table.displayName}',
            notes: notes,
            target: definition.name,
          );
        case ForeignKeyCommandKind.drop:
          final exists = lookup.foreignKeyExists(table, foreign.name);
          yield SchemaDiffEntry(
            action: SchemaDiffAction.dropForeignKey,
            severity: exists
                ? SchemaDiffSeverity.info
                : SchemaDiffSeverity.warning,
            description:
                'Drop foreign key ${foreign.name} on ${table.displayName}',
            notes: exists ? const [] : const ['foreign key missing'],
            target: foreign.name,
          );
      }
    }
  }

  String _formatColumnType(ColumnType type) {
    final buffer = StringBuffer(type.customName ?? type.name.name);
    if (type.length != null) {
      buffer.write('(${type.length})');
    } else if (type.precision != null) {
      buffer.write('(${type.precision}');
      if (type.scale != null) buffer.write(', ${type.scale}');
      buffer.write(')');
    }
    if (type.timezoneAware) buffer.write(' with timezone');
    return buffer.toString();
  }

  String _formatDefault(ColumnDefault value) {
    if (value.useCurrentTimestamp) return 'CURRENT_TIMESTAMP';
    if (value.expression != null) return value.expression!;
    return '${value.value}';
  }
}

class SnapshotLookup {
  SnapshotLookup(SchemaSnapshot snapshot) {
    for (final table in snapshot.tables) {
      final key = tableKey(table.schema, table.name);
      tables[key] = table;
    }
    for (final column in snapshot.columns) {
      if (column.tableName == null) continue;
      final key = tableKey(column.schema, column.tableName!);
      columns.putIfAbsent(key, () => <String>{}).add(column.name.toLowerCase());
    }
    for (final index in snapshot.indexes) {
      if (index.tableName == null) continue;
      final key = tableKey(index.schema, index.tableName!);
      indexes.putIfAbsent(key, () => <String>{}).add(index.name.toLowerCase());
    }
    for (final fk in snapshot.foreignKeys) {
      if (fk.tableName == null) continue;
      final key = tableKey(fk.schema, fk.tableName!);
      foreignKeys.putIfAbsent(key, () => <String>{}).add(fk.name.toLowerCase());
    }
  }

  final Map<String, SchemaTable> tables = {};
  final Map<String, Set<String>> columns = {};
  final Map<String, Set<String>> indexes = {};
  final Map<String, Set<String>> foreignKeys = {};

  bool tableExists(TableRef table) => tables.containsKey(table.key);

  bool columnExists(TableRef table, String column) {
    return columns[table.key]?.contains(column.toLowerCase()) ?? false;
  }

  bool indexExists(TableRef table, String indexName) {
    return indexes[table.key]?.contains(indexName.toLowerCase()) ?? false;
  }

  bool foreignKeyExists(TableRef table, String name) {
    return foreignKeys[table.key]?.contains(name.toLowerCase()) ?? false;
  }
}

class TableRef {
  TableRef(this.schema, this.name);

  final String? schema;
  final String name;

  String get key => tableKey(schema, name);
  String get displayName => schema == null ? name : '$schema.$name';

  static TableRef parse(String input) {
    final parts = input.split('.');
    if (parts.length == 2) {
      return TableRef(parts[0], parts[1]);
    }
    return TableRef(null, input);
  }
}

String tableKey(String? schema, String name) {
  final tableLower = name.toLowerCase();
  if (schema == null || schema.isEmpty) return tableLower;
  return '${schema.toLowerCase()}.$tableLower';
}
