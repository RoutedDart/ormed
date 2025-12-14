import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../config.dart';
import 'shared.dart';

class MakeCommand extends Command<void> {
  MakeCommand() {
    argParser
      ..addOption('name', abbr: 'n', help: 'Slug for the migration/seeder.')
      ..addOption(
        'table',
        help:
            'Table to modify or create (defaults to guesses when --create is used).',
      )
      ..addFlag(
        'create',
        negatable: false,
        help:
            'Indicates the migration will create a table (guesses name from slug).',
      )
      ..addOption(
        'path',
        help:
            'Override the migrations directory (relative to project root unless --realpath is set).',
      )
      ..addFlag(
        'realpath',
        negatable: false,
        help: 'Treat --path as an absolute file system path.',
      )
      ..addFlag(
        'fullpath',
        negatable: false,
        help:
            'Print the created migration file full path instead of relative path.',
      )
      ..addFlag(
        'seeder',
        negatable: false,
        help: 'Generate a seeder instead of a migration.',
      )
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to orm.yaml (defaults to project root).',
      );
  }

  @override
  String get name => 'make';

  @override
  String get description => 'Create a new migration file and register it.';

  @override
  Future<void> run() async {
    final slug = (argResults?['name'] as String?)?.trim();
    if (slug == null || slug.isEmpty) {
      throw UsageException('Missing --name for generator.', usage);
    }
    final shouldCreateSeeder = argResults?['seeder'] == true;
    final tableOption = (argResults?['table'] as String?)?.trim();
    final createFlag = argResults?['create'] == true;
    final configArg = argResults?['config'] as String?;
    final context = resolveOrmProject(configPath: configArg);
    final root = context.root;
    final config = loadOrmProjectConfig(context.configFile);
    final migrationsDir = Directory(
      _resolveDirectory(
        root: root,
        overridePath: argResults?['path'] as String?,
        defaultPath: config.migrations.directory,
        useRealPath: argResults?['realpath'] == true,
      ),
    );

    if (!migrationsDir.existsSync()) {
      migrationsDir.createSync(recursive: true);
    }

    if (shouldCreateSeeder) {
      _createSeeder(slug: slug, root: root, config: config, usage: usage);
      return;
    }

    final tableName =
        tableOption ?? (createFlag ? _guessTableFromSlug(slug) : null);
    if (createFlag && tableName == null) {
      stdout.writeln(
        'Hint: add --table=<name> so the generated migration can scaffold columns for the right table.',
      );
    }

    _createMigration(
      root: root,
      slug: slug,
      migrationsDir: migrationsDir,
      config: config,
      tableName: tableName,
      createTable: createFlag,
      fullPath: argResults?['fullpath'] == true,
      usage: usage,
    );
  }
}

/// Format timestamp as m_YYYYMMDDHHMMSS (new Dart-compliant format)
String _formatTimestamp(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return 'm_$year$month$day$hour$minute$second';
}

String _toPascalCase(String slug) {
  return slug
      .split(RegExp('[-_ ]+'))
      .where((segment) => segment.isNotEmpty)
      .map(
        (segment) =>
            segment.substring(0, 1).toUpperCase() + segment.substring(1),
      )
      .join();
}

String _migrationFileTemplate(String className) =>
    '''
import 'package:ormed/migrations.dart';

class $className extends Migration {
  const $className();

  @override
  void up(SchemaBuilder schema) {}

  @override
  void down(SchemaBuilder schema) {}
}
''';

String _seederFileTemplate(String className) =>
    '''
import 'package:ormed/ormed.dart';

class $className extends DatabaseSeeder {
  $className(super.connection);

  @override
  Future<void> run() async {
    // TODO: add seed logic here
    // Examples:
    // await seed<User>([
    //   {'name': 'John Doe', 'email': 'john@example.com'},
    //   {'name': 'Jane Smith', 'email': 'jane@example.com'},
    // ]);
    //
    // Or use call() to run other seeders:
    // await call([UserSeeder.new, PostSeeder.new]);
  }
}
''';

String _toSnakeCase(String slug) => slug
    .trim()
    .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
    .replaceAll(RegExp(r'_+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '')
    .toLowerCase();

String _resolveDirectory({
  required Directory root,
  required String defaultPath,
  String? overridePath,
  required bool useRealPath,
}) {
  final candidate = overridePath ?? defaultPath;
  if (useRealPath || p.isAbsolute(candidate)) {
    return p.normalize(candidate);
  }
  return resolvePath(root, candidate);
}

String? _guessTableFromSlug(String slug) {
  final match = RegExp(r'^create_(.+)_table$').firstMatch(slug);
  if (match != null) {
    return match.group(1);
  }
  final fallback = RegExp(r'^create_(.+)$').firstMatch(slug);
  return fallback?.group(1);
}

void _createSeeder({
  required String slug,
  required Directory root,
  required OrmProjectConfig config,
  required String usage,
}) {
  final seeds = config.seeds;
  if (seeds == null) {
    throw UsageException(
      'orm.yaml missing seeds configuration. Update orm.yaml to include a seeds block.',
      usage,
    );
  }

  final seedersDir = Directory(resolvePath(root, seeds.directory));
  if (!seedersDir.existsSync()) {
    seedersDir.createSync(recursive: true);
  }

  final snake = _toSnakeCase(slug);
  final className = _toPascalCase(slug);
  final file = File(p.join(seedersDir.path, '$snake.dart'));
  if (file.existsSync()) {
    throw UsageException('Seeder file ${file.path} already exists.', usage);
  }
  file.writeAsStringSync(_seederFileTemplate(className));
  stdout.writeln('Created ${p.relative(file.path, from: root.path)}');

  final registryPath = resolvePath(root, seeds.registry);
  final registry = File(registryPath);
  if (!registry.existsSync()) {
    throw StateError(
      'Seeder registry $registryPath not found. Run `orm init`.',
    );
  }
  var content = registry.readAsStringSync();

  // Calculate relative import path from registry to seeder file
  final registryDir = p.dirname(registryPath);
  final relativeImportPath = p
      .relative(file.path, from: registryDir)
      .replaceAll(r'\', '/'); // Normalize for Dart imports

  final importLine = "import '$relativeImportPath';";
  if (!content.contains(importLine)) {
    content = insertBetweenMarkers(
      content,
      seedImportsMarkerStart,
      seedImportsMarkerEnd,
      importLine,
      indent: '',
    );
  }
  final entry =
      '''  SeederRegistration(
    name: '$className',
    factory: $className.new,
  ),''';
  if (!content.contains("name: '$className'")) {
    content = insertBetweenMarkers(
      content,
      seedRegistryMarkerStart,
      seedRegistryMarkerEnd,
      entry,
      indent: '',
    );
  }
  registry.writeAsStringSync(content);
  stdout.writeln('Registered seeder $className');
  stdout.writeln('Seeder snippet:');
  stdout.writeln('  import: $importLine');
  stdout.writeln('  entry: $entry');
}

void _createMigration({
  required Directory root,
  required String slug,
  required Directory migrationsDir,
  required OrmProjectConfig config,
  String? tableName,
  required bool createTable,
  required bool fullPath,
  required String usage,
}) {
  final existing = migrationsDir
      .listSync()
      .whereType<File>()
      .map((file) => p.basename(file.path))
      .where((name) => name.endsWith('_$slug.dart'))
      .isNotEmpty;
  if (existing) {
    throw UsageException('Migration with slug $slug already exists.', usage);
  }

  final timestamp = _formatTimestamp(DateTime.now().toUtc());
  final fileName = '${timestamp}_$slug.dart';
  final className = _toPascalCase(slug);
  final file = File(p.join(migrationsDir.path, fileName));
  if (file.existsSync()) {
    throw UsageException('Migration file $fileName already exists.', usage);
  }
  file.writeAsStringSync(_migrationFileTemplate(className));
  final displayPath = fullPath
      ? file.path
      : p.relative(file.path, from: root.path);
  stdout.writeln('Created migration at $displayPath');
  if (createTable || tableName != null) {
    final tableInfo = tableName ?? 'guessing from slug';
    stdout.writeln(
      'Migration intent: create table = $createTable, target table = $tableInfo',
    );
  }

  final registryPath = resolvePath(root, config.migrations.registry);
  final registry = File(registryPath);
  if (!registry.existsSync()) {
    throw StateError('Registry file $registryPath not found. Run `orm init`.');
  }
  var content = registry.readAsStringSync();

  // Calculate relative import path from registry to migration file
  final registryDir = p.dirname(registryPath);
  final relativeImportPath = p
      .relative(file.path, from: registryDir)
      .replaceAll(r'\', '/'); // Normalize for Dart imports

  final importLine = "import '$relativeImportPath';";
  content = insertBetweenMarkers(
    content,
    importsMarkerStart,
    importsMarkerEnd,
    importLine,
    indent: '',
  );
  final descriptor =
      '''MigrationEntry(
    id: MigrationId.parse('${timestamp}_$slug'),
    migration: const $className(),
  ),''';
  content = insertBetweenMarkers(
    content,
    registryMarkerStart,
    registryMarkerEnd,
    descriptor,
    indent: '  ',
  );
  registry.writeAsStringSync(content);
  stdout.writeln('Registered migration ${timestamp}_$slug');
  stdout.writeln('Migration snippet:');
  stdout.writeln('  import: $importLine');
  stdout.writeln('  descriptor: $descriptor');
}
