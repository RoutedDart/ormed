import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import '../base/shared.dart';

class MakeCommand extends Command<void> {
  MakeCommand() {
    argParser
      ..addOption('name', abbr: 'n', help: 'Slug for the migration/seeder.')
      ..addOption(
        'format',
        help:
            'Migration authoring format (dart|sql). Defaults from ormed.yaml.',
        allowed: const ['dart', 'sql'],
      )
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
      ..addFlag(
        'manual',
        negatable: false,
        help:
            'Create migration files without editing migrations.dart. Prints import/entry snippets for manual registration.',
      )
      ..addOption(
        'config',
        abbr: 'c',
        help:
            'Path to ormed.yaml (optional; convention defaults are used when omitted).',
      );
  }

  @override
  String get name => 'make';

  @override
  String get description => 'Create a new migration file and register it.';

  @override
  Future<void> run() async {
    // Interactively ask for name if not provided
    var slug = (argResults?['name'] as String?)?.trim();
    if (slug == null || slug.isEmpty) {
      slug = io.ask(
        'What is the name of the migration/seeder?',
        validator: (value) {
          if (value.trim().isEmpty) return 'Name cannot be empty.';
          return null;
        },
      );
    }

    // Determine type (seeder or migration)
    var shouldCreateSeeder = argResults?['seeder'] == true;

    // If user provided no type flags and we're interactive, maybe ask?
    // Actually standard behavior is migration unless --seeder specified.
    // However, if the name ends in 'Seeder', we could guess?
    if (!shouldCreateSeeder && slug.toLowerCase().endsWith('seeder')) {
      if (io.confirm(
        'The name ends in "Seeder". Do you want to create a seeder?',
        defaultValue: true,
      )) {
        shouldCreateSeeder = true;
      }
    }

    final tableOption = (argResults?['table'] as String?)?.trim();
    final createFlag = argResults?['create'] == true;
    final hints = _inferMigrationHints(slug);
    final inferredCreate = createFlag || hints.createTable;
    final formatOption = (argResults?['format'] as String?)?.trim();

    // If not a seeder, and we didn't specify table/create, ask intent
    // Or just rely on reasonable defaults (guess table from slug).

    final configArg = argResults?['config'] as String?;
    final resolved = resolveOrmProjectConfig(configPath: configArg);
    final root = resolved.root;
    final config = resolved.config;
    if (!resolved.hasConfigFile) {
      printConfigFallbackNotice();
    }
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

    final migrationFormat = _resolveMigrationFormat(
      formatOption,
      config.migrations.format,
      usage: usage,
    );
    final tableName = tableOption ?? hints.tableName;
    if (inferredCreate && tableName == null) {
      io.note(
        'Hint: add --table=<name> so the generated migration can scaffold columns for the right table.',
      );
    }

    _createMigration(
      root: root,
      slug: slug,
      migrationsDir: migrationsDir,
      config: config,
      tableName: tableName,
      createTable: inferredCreate,
      fullPath: argResults?['fullpath'] == true,
      format: migrationFormat,
      registerInRegistry: argResults?['manual'] != true,
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

String _migrationFileTemplate(
  String className, {
  String? tableName,
  bool createTable = false,
}) {
  var up = '';
  var down = '';
  if (tableName != null) {
    if (createTable) {
      up =
          """
    schema.create('$tableName', (table) {
      table.id();
      table.timestamps();
    });""";
      down = "    schema.drop('$tableName');";
    } else {
      up =
          """
    schema.table('$tableName', (table) {
      //
    });""";
    }
  }

  return '''
import 'package:ormed/migrations.dart';

class $className extends Migration {
  const $className();

  @override
  void up(SchemaBuilder schema) {
$up
  }

  @override
  void down(SchemaBuilder schema) {
$down
  }
}
''';
}

String _seederFileTemplate(String className, String packageName) =>
    '''
import 'package:ormed/ormed.dart';
import 'package:$packageName/src/database/orm_registry.g.dart';

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

const String _defaultSeederTemplate = '''
import 'package:ormed/ormed.dart';

/// Root seeder executed by `orm seed` and `orm migrate --seed`.
class AppDatabaseSeeder extends DatabaseSeeder {
  AppDatabaseSeeder(super.connection);

  @override
  Future<void> run() async {
    // TODO: add seed logic here
    // Examples:
    // await seed<User>([
    //   {'name': 'Admin User', 'email': 'admin@example.com'},
    // ]);
    //
    // Or call other seeders:
    // await call([UserSeeder.new, PostSeeder.new]);
  }
}
''';

String _toSnakeCase(String slug) => normalizeSnakeCaseToken(slug);

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

_MigrationSlugHints _inferMigrationHints(String slug) {
  final createTableMatch = RegExp(r'^create_(.+)_table$').firstMatch(slug);
  if (createTableMatch != null) {
    final table = createTableMatch.group(1);
    return _MigrationSlugHints(tableName: table, createTable: table != null);
  }

  final createMatch = RegExp(r'^create_(.+)$').firstMatch(slug);
  if (createMatch != null) {
    final table = createMatch.group(1);
    return _MigrationSlugHints(tableName: table, createTable: table != null);
  }

  final addMatch = RegExp(r'^add_.+_to_(.+)$').firstMatch(slug);
  if (addMatch != null) {
    return _MigrationSlugHints(
      tableName: addMatch.group(1),
      createTable: false,
    );
  }

  final removeMatch = RegExp(r'^remove_.+_from_(.+)$').firstMatch(slug);
  if (removeMatch != null) {
    return _MigrationSlugHints(
      tableName: removeMatch.group(1),
      createTable: false,
    );
  }

  final renameMatch = RegExp(r'^rename_.+_in_(.+)$').firstMatch(slug);
  if (renameMatch != null) {
    return _MigrationSlugHints(
      tableName: renameMatch.group(1),
      createTable: false,
    );
  }

  final alterMatch = RegExp(r'^alter_(.+)$').firstMatch(slug);
  if (alterMatch != null) {
    return _MigrationSlugHints(
      tableName: alterMatch.group(1),
      createTable: false,
    );
  }

  return const _MigrationSlugHints(tableName: null, createTable: false);
}

class _MigrationSlugHints {
  const _MigrationSlugHints({
    required this.tableName,
    required this.createTable,
  });

  final String? tableName;
  final bool createTable;
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
      'Missing seeds configuration. Run `ormed init --only=seeders` or add a `seeds` block to ormed.yaml.',
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
  final packageName = getPackageName(root);
  file.writeAsStringSync(_seederFileTemplate(className, packageName));
  cliIO.success('Created seeder');
  cliIO.components.horizontalTable({
    'File': p.relative(file.path, from: root.path),
    'Class': className,
  });

  final registryPath = resolvePath(root, seeds.registry);
  final registry = File(registryPath);
  _ensureSeederScaffold(
    root: root,
    seeds: seeds,
    packageName: packageName,
    registry: registry,
  );
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
  cliIO.success('Registered seeder $className');
}

void _createMigration({
  required Directory root,
  required String slug,
  required Directory migrationsDir,
  required OrmProjectConfig config,
  String? tableName,
  required bool createTable,
  required bool fullPath,
  required MigrationFormat format,
  required bool registerInRegistry,
  required String usage,
}) {
  final timestamp = _formatTimestamp(DateTime.now().toUtc());
  final migrationId = '${timestamp}_$slug';
  final className = _toPascalCase(slug);

  final conflict = migrationsDir
      .listSync()
      .map((entry) => p.basename(entry.path))
      .any((name) {
        if (name.endsWith('_$slug.dart')) return true;
        if (name.endsWith('_$slug') &&
            Directory(p.join(migrationsDir.path, name)).existsSync()) {
          return true;
        }
        return false;
      });
  if (conflict) {
    throw UsageException('Migration with slug $slug already exists.', usage);
  }

  String? createdDisplayPath;
  if (format == MigrationFormat.dart) {
    final fileName = '$migrationId.dart';
    final file = File(p.join(migrationsDir.path, fileName));
    if (file.existsSync()) {
      throw UsageException('Migration file $fileName already exists.', usage);
    }
    file.writeAsStringSync(
      _migrationFileTemplate(
        className,
        tableName: tableName,
        createTable: createTable,
      ),
    );
    createdDisplayPath = fullPath
        ? file.path
        : p.relative(file.path, from: root.path);
    cliIO.success('Created migration');
    cliIO.components.horizontalTable({
      'File': createdDisplayPath,
      'Class': className,
      if (createTable || tableName != null)
        'Table': tableName ?? 'guessing from slug',
    });
  } else {
    final dir = Directory(p.join(migrationsDir.path, migrationId));
    if (dir.existsSync()) {
      throw UsageException(
        'Migration directory $migrationId already exists.',
        usage,
      );
    }
    dir.createSync(recursive: true);
    File(p.join(dir.path, 'up.sql')).writeAsStringSync('');
    File(p.join(dir.path, 'down.sql')).writeAsStringSync('');
    createdDisplayPath = fullPath
        ? dir.path
        : p.relative(dir.path, from: root.path);
    cliIO.success('Created SQL migration');
    cliIO.components.horizontalTable({
      'Directory': createdDisplayPath,
      'Files': 'up.sql, down.sql',
      if (createTable || tableName != null)
        'Table': tableName ?? 'guessing from slug',
    });
  }

  final registryPath = resolvePath(root, config.migrations.registry);
  final registryDir = p.dirname(registryPath);
  if (!registerInRegistry) {
    _printManualRegistrationSnippet(
      format: format,
      migrationId: migrationId,
      className: className,
      migrationsDir: migrationsDir.path,
      registryDir: registryDir,
      registryPath: registryPath,
      root: root.path,
    );
    cliIO.note('Manual mode: migration was not added to migrations registry.');
    return;
  }

  final registry = File(registryPath);
  _ensureMigrationRegistry(registry);
  var content = registry.readAsStringSync();

  if (format == MigrationFormat.dart) {
    final filePath = p.join(migrationsDir.path, '$migrationId.dart');
    final relativeImportPath = p
        .relative(filePath, from: registryDir)
        .replaceAll(r'\', '/'); // Normalize for Dart imports

    final importLine = "import '$relativeImportPath';";
    content = insertBetweenMarkers(
      content,
      importsMarkerStart,
      importsMarkerEnd,
      importLine,
      indent: '',
    );
  }

  final entry = format == MigrationFormat.dart
      ? '''MigrationEntry.named(
    '${timestamp}_$slug',
    const $className(),
  ),'''
      : (() {
          final sqlDirPath = p.join(migrationsDir.path, migrationId);
          final relativeDir = p
              .relative(sqlDirPath, from: registryDir)
              .replaceAll(r'\', '/');
          return '''MigrationEntry.named(
    '${timestamp}_$slug',
    SqlFileMigration(
      upPath: '$relativeDir/up.sql',
      downPath: '$relativeDir/down.sql',
    ),
  ),''';
        })();

  content = insertBetweenMarkers(
    content,
    registryMarkerStart,
    registryMarkerEnd,
    entry,
    indent: '  ',
  );
  registry.writeAsStringSync(content);
  cliIO.success('Registered migration ${timestamp}_$slug');
}

void _ensureMigrationRegistry(File registry) {
  if (registry.existsSync()) return;
  registry.parent.createSync(recursive: true);
  registry.writeAsStringSync(initialRegistryTemplate);
  cliIO.note('Bootstrapped missing migration registry at ${registry.path}.');
}

void _ensureSeederScaffold({
  required Directory root,
  required SeedSection seeds,
  required String packageName,
  required File registry,
}) {
  final seedersDir = Directory(resolvePath(root, seeds.directory));
  if (!seedersDir.existsSync()) {
    seedersDir.createSync(recursive: true);
  }

  final defaultSeederFile = File(
    p.join(seedersDir.path, 'database_seeder.dart'),
  );
  if (!defaultSeederFile.existsSync()) {
    defaultSeederFile.writeAsStringSync(_defaultSeederTemplate);
    cliIO.note(
      'Bootstrapped default database seeder at ${defaultSeederFile.path}.',
    );
  }

  if (!registry.existsSync()) {
    registry.parent.createSync(recursive: true);
    registry.writeAsStringSync(
      initialSeedRegistryTemplate.replaceAll('{{package_name}}', packageName),
    );
    cliIO.note('Bootstrapped missing seed registry at ${registry.path}.');
  }
}

void _printManualRegistrationSnippet({
  required MigrationFormat format,
  required String migrationId,
  required String className,
  required String migrationsDir,
  required String registryDir,
  required String registryPath,
  required String root,
}) {
  cliIO.newLine();
  cliIO.section('Manual registration');
  if (format == MigrationFormat.dart) {
    final filePath = p.join(migrationsDir, '$migrationId.dart');
    final relativeImportPath = p
        .relative(filePath, from: registryDir)
        .replaceAll(r'\', '/');
    cliIO.writeln("import '$relativeImportPath';");
    cliIO.writeln('''MigrationEntry.named(
  '$migrationId',
  const $className(),
),''');
  } else {
    final sqlDirPath = p.join(migrationsDir, migrationId);
    final relativeDir = p
        .relative(sqlDirPath, from: registryDir)
        .replaceAll(r'\', '/');
    cliIO.writeln('''MigrationEntry.named(
  '$migrationId',
  SqlFileMigration(
    upPath: '$relativeDir/up.sql',
    downPath: '$relativeDir/down.sql',
  ),
),''');
  }
  cliIO.writeln('Paste into ${p.relative(registryPath, from: root)} markers.');
}

MigrationFormat _resolveMigrationFormat(
  String? optionValue,
  MigrationFormat defaultFormat, {
  required String usage,
}) {
  final normalized = optionValue?.toLowerCase();
  switch (normalized) {
    case null:
    case '':
      return defaultFormat;
    case 'dart':
      return MigrationFormat.dart;
    case 'sql':
      return MigrationFormat.sql;
    default:
      throw UsageException(
        'Invalid --format "$optionValue". Expected "dart" or "sql".',
        usage,
      );
  }
}

/// Alias for `make` with migration-focused naming.
class MakeMigrationCommand extends MakeCommand {
  @override
  String get name => 'make:migration';

  @override
  String get description => 'Alias for make. Create a new migration file.';
}

/// Alias for `make --seeder`.
class MakeSeederCommand extends MakeCommand {
  @override
  String get name => 'make:seeder';

  @override
  String get description => 'Alias for make --seeder. Create a seeder file.';

  @override
  Future<void> run() async {
    var slug = (argResults?['name'] as String?)?.trim();
    if (slug == null || slug.isEmpty) {
      slug = io.ask(
        'What is the name of the seeder?',
        validator: (value) {
          if (value.trim().isEmpty) return 'Name cannot be empty.';
          return null;
        },
      );
    }

    final configArg = argResults?['config'] as String?;
    final resolved = resolveOrmProjectConfig(configPath: configArg);
    if (!resolved.hasConfigFile) {
      printConfigFallbackNotice();
    }

    _createSeeder(
      slug: slug,
      root: resolved.root,
      config: resolved.config,
      usage: usage,
    );
  }
}
