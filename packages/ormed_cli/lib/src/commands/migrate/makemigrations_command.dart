import 'dart:convert';
import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:ormed/migrations.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import '../base/shared.dart';
import 'sync_command.dart';

abstract class ModelSchemaLoader {
  Future<List<ModelSchemaTable>> load({
    required Directory root,
    required String packageName,
    required String ormRegistryPath,
  });
}

class ProcessModelSchemaLoader implements ModelSchemaLoader {
  const ProcessModelSchemaLoader();

  @override
  Future<List<ModelSchemaTable>> load({
    required Directory root,
    required String packageName,
    required String ormRegistryPath,
  }) async {
    final libDir = p.join(root.path, 'lib');
    final relativeToLib = p.relative(ormRegistryPath, from: libDir);
    if (relativeToLib.startsWith('..')) {
      throw StateError(
        'ORM registry must be under lib/ to import via package: URI: $ormRegistryPath',
      );
    }
    final importPath = relativeToLib.replaceAll(r'\', '/');
    final scriptDir = Directory(p.join(root.path, '.dart_tool', 'ormed_cli'))
      ..createSync(recursive: true);
    final scriptFile = File(
      p.join(
        scriptDir.path,
        'model_schema_${DateTime.now().microsecondsSinceEpoch}.dart',
      ),
    );
    scriptFile.writeAsStringSync(_schemaLoaderScript(packageName, importPath));

    try {
      final result = await Process.run(
        'dart',
        ['run', p.relative(scriptFile.path, from: root.path)],
        workingDirectory: root.path,
        runInShell: Platform.isWindows,
      );
      if (result.exitCode != 0) {
        throw StateError(
          'Failed to load model schema from $ormRegistryPath:\n${result.stderr}',
        );
      }
      final stdoutText = result.stdout as String;
      final start = stdoutText.indexOf('[');
      final end = stdoutText.lastIndexOf(']');
      if (start == -1 || end == -1 || end < start) {
        throw StateError(
          'Failed to parse model schema JSON from output:\n$stdoutText',
        );
      }
      final payloadText = stdoutText.substring(start, end + 1);
      final payload = jsonDecode(payloadText) as List;
      return payload
          .map(
            (entry) => ModelSchemaTable.fromJson(
              Map<String, Object?>.from(entry as Map),
            ),
          )
          .toList(growable: false);
    } finally {
      if (scriptFile.existsSync()) {
        scriptFile.deleteSync();
      }
    }
  }
}

ModelSchemaLoader modelSchemaLoader = const ProcessModelSchemaLoader();

/// Generates migration files from model metadata when possible, then syncs
/// migrations.dart entries as a fallback/safety net.
class MakeMigrationsCommand extends MigrationSyncCommand {
  MakeMigrationsCommand() {
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help:
            'Optional slug for generated migration (defaults to inferred sync slug).',
      )
      ..addOption(
        'orm-registry',
        help:
            'Path to orm_registry.g.dart (defaults to discovered convention paths).',
      )
      ..addFlag(
        'sync-only',
        negatable: false,
        help:
            'Skip model-diff generation and only sync migrations registry entries.',
      );
  }

  @override
  String get name => 'makemigrations';

  @override
  String get description =>
      'Generate a migration from model schema diffs, then sync migrations.dart entries.';

  @override
  Future<void> run() async {
    if (argResults?['sync-only'] == true) {
      await super.run();
      return;
    }

    final generated = await _generateFromModels();

    if (!generated) {
      cliIO.note(
        'No model diff migration generated; falling back to migrations:sync.',
      );
    }

    await super.run();
  }

  Future<bool> _generateFromModels() async {
    final configArg = argResults?['config'] as String?;
    final resolved = resolveOrmProjectConfig(configPath: configArg);
    final root = resolved.root;
    final config = resolved.config;

    final ormRegistry = _resolveOrmRegistryPath(root, argResults);
    if (ormRegistry == null) {
      return false;
    }
    if (!File(ormRegistry).existsSync()) {
      return false;
    }

    final packageName = getPackageName(root);
    final models = await modelSchemaLoader.load(
      root: root,
      packageName: packageName,
      ormRegistryPath: ormRegistry,
    );
    if (models.isEmpty) {
      return false;
    }

    final snapshot = await _captureSnapshot(root, config);
    final changes = _diffModels(models, snapshot);
    if (changes.isEmpty) {
      cliIO.info('No model schema changes detected.');
      return false;
    }

    final migrationsDir = Directory(
      resolvePath(root, config.migrations.directory),
    );
    if (!migrationsDir.existsSync()) {
      migrationsDir.createSync(recursive: true);
    }

    final requestedSlug = (argResults?['name'] as String?)?.trim();
    final slug = _ensureUniqueSlug(
      requestedSlug?.isNotEmpty == true
          ? requestedSlug!
          : _defaultSlug(changes),
      migrationsDir,
    );
    final migrationId = '${_formatTimestamp(DateTime.now().toUtc())}_$slug';
    final className = _toPascalCase(slug);
    final migrationFile = File(p.join(migrationsDir.path, '$migrationId.dart'));
    final content = _renderMigrationFile(className, changes);
    final dryRun = argResults?['dry-run'] == true;

    cliIO.section('Model diff migration');
    cliIO.components.horizontalTable({
      'Registry': p.relative(ormRegistry, from: root.path),
      'Changes': changes.length.toString(),
      'Migration': p.relative(migrationFile.path, from: root.path),
      if (dryRun) 'Mode': 'dry-run',
    });

    if (dryRun) {
      return false;
    }

    migrationFile.writeAsStringSync(content);
    cliIO.success(
      'Created migration ${p.relative(migrationFile.path, from: root.path)}',
    );

    final registryPath = resolveRegistryFilePath(
      root,
      config,
      override: argResults?['path'] as String?,
      realPath: argResults?['realpath'] == true,
    );
    final registryFile = File(registryPath);
    if (!registryFile.existsSync()) {
      registryFile.parent.createSync(recursive: true);
      registryFile.writeAsStringSync(initialRegistryTemplate);
      cliIO.note(
        'Bootstrapped missing migration registry at ${p.relative(registryPath, from: root.path)}.',
      );
    }

    return true;
  }
}

String? _resolveOrmRegistryPath(Directory root, ArgResults? args) {
  final option = (args?['orm-registry'] as String?)?.trim();
  if (option != null && option.isNotEmpty) {
    if (p.isAbsolute(option)) return p.normalize(option);
    return resolvePath(root, option);
  }

  final candidates = <String>[
    p.join(root.path, 'lib', 'src', 'database', 'orm_registry.g.dart'),
    p.join(root.path, 'lib', 'database', 'orm_registry.g.dart'),
  ];
  for (final candidate in candidates) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }
  return null;
}

Future<SchemaSnapshot> _captureSnapshot(
  Directory root,
  OrmProjectConfig config,
) async {
  final handle = await createConnection(root, config);
  try {
    return await handle.use((connection) async {
      final driver = connection.driver;
      if (driver is! SchemaDriver) {
        throw StateError('Active connection driver does not support schema.');
      }
      return SchemaSnapshot.capture(driver as SchemaDriver);
    });
  } finally {
    await handle.dispose();
  }
}

List<ModelSchemaChange> _diffModels(
  List<ModelSchemaTable> models,
  SchemaSnapshot snapshot,
) {
  final dbTables = <String>{};
  for (final table in snapshot.tables) {
    dbTables.add(_tableKey(table.name, table.schema));
  }

  final dbColumnsByTable = <String, Set<String>>{};
  for (final column in snapshot.columns) {
    final tableName = column.tableName;
    if (tableName == null || tableName.trim().isEmpty) continue;
    final key = _tableKey(tableName, column.schema);
    dbColumnsByTable
        .putIfAbsent(key, () => <String>{})
        .add(column.name.toLowerCase());
  }

  final changes = <ModelSchemaChange>[];
  for (final table in models) {
    final key = _tableKey(table.tableName, table.schema);
    if (!dbTables.contains(key)) {
      changes.add(ModelSchemaCreateTable(table));
      continue;
    }
    final existingColumns = dbColumnsByTable[key] ?? const <String>{};
    final missingColumns = table.columns
        .where((column) => !existingColumns.contains(column.columnNameLower))
        .toList(growable: false);
    if (missingColumns.isNotEmpty) {
      changes.add(
        ModelSchemaAddColumns(
          tableName: table.tableName,
          columns: missingColumns,
        ),
      );
    }
  }
  return changes;
}

String _tableKey(String table, String? schema) {
  final tablePart = table.trim().toLowerCase();
  final schemaPart = (schema ?? '').trim().toLowerCase();
  return '$schemaPart.$tablePart';
}

String _defaultSlug(List<ModelSchemaChange> changes) {
  final create = changes.whereType<ModelSchemaCreateTable>().toList();
  if (create.length == 1) {
    return 'create_${create.first.table.tableName}_table';
  }
  return 'sync_model_schema';
}

String _ensureUniqueSlug(String slug, Directory migrationsDir) {
  var candidate = normalizeSnakeCaseToken(slug);
  var suffix = 1;
  while (_slugExists(candidate, migrationsDir)) {
    candidate = '${normalizeSnakeCaseToken(slug)}_$suffix';
    suffix++;
  }
  return candidate;
}

bool _slugExists(String slug, Directory migrationsDir) {
  if (!migrationsDir.existsSync()) return false;
  for (final entity in migrationsDir.listSync()) {
    final base = p.basename(entity.path);
    if (base.endsWith('_$slug.dart')) {
      return true;
    }
    if (entity is Directory && base.endsWith('_$slug')) {
      return true;
    }
  }
  return false;
}

String _renderMigrationFile(String className, List<ModelSchemaChange> changes) {
  final upLines = <String>[];
  final downLines = <String>[];

  for (final change in changes) {
    switch (change) {
      case ModelSchemaCreateTable(:final table):
        upLines.add(
          "    schema.create('${_escape(table.tableName)}', (table) {",
        );
        for (final column in table.columns) {
          upLines.add(_renderColumn(column, indent: '      '));
        }
        upLines.add('    });');
        break;
      case ModelSchemaAddColumns(:final tableName, :final columns):
        upLines.add("    schema.table('${_escape(tableName)}', (table) {");
        for (final column in columns) {
          upLines.add(_renderColumn(column, indent: '      '));
        }
        upLines.add('    });');
        break;
    }
  }

  for (final change in changes.reversed) {
    switch (change) {
      case ModelSchemaAddColumns(:final tableName, :final columns):
        downLines.add("    schema.table('${_escape(tableName)}', (table) {");
        for (final column in columns.reversed) {
          downLines.add(
            "      table.dropColumn('${_escape(column.columnName)}');",
          );
        }
        downLines.add('    });');
        break;
      case ModelSchemaCreateTable(:final table):
        downLines.add(
          "    schema.drop('${_escape(table.tableName)}', ifExists: true);",
        );
        break;
    }
  }

  final upBlock = upLines.isEmpty
      ? '    // No schema changes.'
      : upLines.join('\n');
  final downBlock = downLines.isEmpty
      ? '    // No rollback changes.'
      : downLines.join('\n');

  return '''
import 'package:ormed/migrations.dart';

class $className extends Migration {
  const $className();

  @override
  void up(SchemaBuilder schema) {
$upBlock
  }

  @override
  void down(SchemaBuilder schema) {
$downBlock
  }
}
''';
}

String _renderColumn(ModelSchemaColumn column, {required String indent}) {
  var line =
      "$indent"
      "table.column('${_escape(column.columnName)}', ${_columnTypeExpression(column)})";
  if (column.isNullable) {
    line += '.nullable()';
  }
  if (column.isUnique) {
    line += '.unique()';
  }
  if (column.isIndexed) {
    line += '.indexed()';
  }
  if (column.isPrimaryKey) {
    line += '.primaryKey()';
  }
  if (column.autoIncrement) {
    line += '.autoIncrement()';
  }
  return '$line;';
}

String _columnTypeExpression(ModelSchemaColumn column) {
  final declared = column.columnType?.trim();
  if (declared != null && declared.isNotEmpty) {
    return "const ColumnType.custom('${_escape(declared)}')";
  }

  switch (column.resolvedTypeNormalized) {
    case 'int':
      return 'const ColumnType.integer()';
    case 'double':
    case 'num':
      return 'const ColumnType.decimal()';
    case 'string':
      return 'const ColumnType.string()';
    case 'datetime':
      return 'const ColumnType.timestamp(timezoneAware: true)';
    case 'bool':
      return 'const ColumnType.boolean()';
    default:
      return 'const ColumnType.json()';
  }
}

String _escape(String value) => value.replaceAll("'", r"\'");

String _formatTimestamp(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return 'm_$year$month$day$hour$minute$second';
}

String _toPascalCase(String slug) => slug
    .split(RegExp('[-_ ]+'))
    .where((segment) => segment.isNotEmpty)
    .map(
      (segment) => segment.substring(0, 1).toUpperCase() + segment.substring(1),
    )
    .join();

String _schemaLoaderScript(String packageName, String registryImportPath) =>
    '''
import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:$packageName/$registryImportPath' as g;

void main() {
  final definitions = g.generatedOrmModelDefinitions;
  final payload = <Map<String, Object?>>[];
  for (final raw in definitions) {
    if (raw is! ModelDefinition) continue;
    payload.add({
      'modelName': raw.modelName,
      'tableName': raw.tableName,
      'schema': raw.schema,
      'columns': [
        for (final field in raw.fields)
          {
            'name': field.name,
            'columnName': field.columnName,
            'resolvedType': field.resolvedType,
            'columnType': field.columnType,
            'isNullable': field.isNullable,
            'isPrimaryKey': field.isPrimaryKey,
            'isUnique': field.isUnique,
            'isIndexed': field.isIndexed,
            'autoIncrement': field.autoIncrement,
          },
      ],
    });
  }
  print(jsonEncode(payload));
}
''';

class ModelSchemaTable {
  const ModelSchemaTable({
    required this.modelName,
    required this.tableName,
    required this.schema,
    required this.columns,
  });

  final String modelName;
  final String tableName;
  final String? schema;
  final List<ModelSchemaColumn> columns;

  factory ModelSchemaTable.fromJson(Map<String, Object?> json) {
    return ModelSchemaTable(
      modelName: json['modelName'] as String? ?? '',
      tableName: json['tableName'] as String,
      schema: json['schema'] as String?,
      columns: (json['columns'] as List? ?? const [])
          .map(
            (entry) => ModelSchemaColumn.fromJson(
              Map<String, Object?>.from(entry as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class ModelSchemaColumn {
  const ModelSchemaColumn({
    required this.name,
    required this.columnName,
    required this.resolvedType,
    required this.columnType,
    required this.isNullable,
    required this.isPrimaryKey,
    required this.isUnique,
    required this.isIndexed,
    required this.autoIncrement,
  });

  final String name;
  final String columnName;
  final String resolvedType;
  final String? columnType;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool isUnique;
  final bool isIndexed;
  final bool autoIncrement;

  String get columnNameLower => columnName.trim().toLowerCase();

  String get resolvedTypeNormalized =>
      resolvedType.replaceAll('?', '').trim().toLowerCase();

  factory ModelSchemaColumn.fromJson(Map<String, Object?> json) {
    return ModelSchemaColumn(
      name: json['name'] as String? ?? '',
      columnName: json['columnName'] as String,
      resolvedType: json['resolvedType'] as String? ?? 'Object?',
      columnType: json['columnType'] as String?,
      isNullable: json['isNullable'] as bool? ?? false,
      isPrimaryKey: json['isPrimaryKey'] as bool? ?? false,
      isUnique: json['isUnique'] as bool? ?? false,
      isIndexed: json['isIndexed'] as bool? ?? false,
      autoIncrement: json['autoIncrement'] as bool? ?? false,
    );
  }
}

sealed class ModelSchemaChange {
  const ModelSchemaChange();
}

class ModelSchemaCreateTable extends ModelSchemaChange {
  const ModelSchemaCreateTable(this.table);

  final ModelSchemaTable table;
}

class ModelSchemaAddColumns extends ModelSchemaChange {
  const ModelSchemaAddColumns({required this.tableName, required this.columns});

  final String tableName;
  final List<ModelSchemaColumn> columns;
}
