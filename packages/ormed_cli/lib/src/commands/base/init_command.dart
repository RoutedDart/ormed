import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/args.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import 'shared.dart';

class InitCommand extends Command<void> {
  InitCommand() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Rebuild the scaffolding even if files already exist.',
      )
      ..addFlag(
        'paths',
        negatable: false,
        help: 'Print the canonical path for each scaffolded artifact.',
      )
      // New: populate existing migrations/seeders into registries if present
      ..addFlag(
        'populate-existing',
        abbr: 'p',
        negatable: true,
        help:
            'Scan existing migrations/seeders and populate registries accordingly.',
      );
  }

  @override
  String get name => 'init';

  @override
  String get description => 'Initialize orm.yaml and migration/seed registries.';

  @override
  Future<void> run() async {
    final force = argResults?['force'] == true;
    final showPaths = argResults?['paths'] == true;
    final populateExisting = argResults?['populate-existing'] == true;
    final root = findProjectRoot();
    final tracker = _ArtifactTracker(root);

    // If config exists, offer re-initialize
    if (!force) {
      final configFile = File(p.join(root.path, 'orm.yaml'));
      if (configFile.existsSync()) {
        cliIO.writeln(cliIO.style.info('Project already initialized.'));
        // Ask whether to re-initialize
        if (!io.confirm('Do you want to re-initialize (overwrite files)?')) {
          // Continue with population flow if requested, otherwise exit
          if (!populateExisting) {
            return;
          }
        }
      }
    }

    final configFile = File(p.join(root.path, 'orm.yaml'));
    _writeFile(
      file: configFile,
      content: defaultOrmYaml,
      label: 'orm.yaml',
      force: force,
      tracker: tracker,
      interactive: true,
    );

    // Load config
    final config = loadOrmProjectConfig(configFile);

    // Directories
    final migrationsDir = Directory(
      resolvePath(root, config.migrations.directory),
    );
    _ensureDirectory(migrationsDir, 'migrations directory', tracker);

    final registry = File(resolvePath(root, config.migrations.registry));
    _writeFile(
      file: registry,
      content: initialRegistryTemplate,
      label: 'migrations registry',
      force: force,
      tracker: tracker,
      interactive: true,
    );

    final seedersDir = Directory(resolvePath(root, config.seeds!.directory));
    _ensureDirectory(seedersDir, 'seeders directory', tracker);

    final seedRegistry = File(resolvePath(root, config.seeds!.registry));
    _writeFile(
      file: seedRegistry,
      content: initialSeedRegistryTemplate,
      label: 'seeders registry',
      force: force,
      tracker: tracker,
      interactive: true,
    );

    final defaultSeeder = File(p.join(seedersDir.path, 'database_seeder.dart'));
    _writeFile(
      file: defaultSeeder,
      content: _defaultSeederTemplate,
      label: 'database seeder',
      force: force,
      tracker: tracker,
      interactive: true,
    );

    // Create schema dump directory
    final schemaDumpDir = Directory(
      resolvePath(root, config.migrations.schemaDump),
    );
    if (!schemaDumpDir.existsSync()) {
      schemaDumpDir.createSync(recursive: true);
      tracker.paths['schema'] = schemaDumpDir.path;
    }
    final gitkeep = File(p.join(schemaDumpDir.path, '.gitkeep'));
    if (!gitkeep.existsSync()) {
      gitkeep.writeAsStringSync('');
    }

    // Populate existing artifacts into registries
    if (populateExisting) {
      await _populateExisting(
        io: cliIO,
        root: root,
        config: config,
        migrationsDir: migrationsDir,
        seedersDir: seedersDir,
        registryFile: registry,
        seedRegistryFile: seedRegistry,
      );
    } else {
      // If not explicitly requested, check whether dirs contain files and prompt
      final hasExistingMigrations = _hasDartFiles(migrationsDir);
      final hasExistingSeeders = _hasDartFiles(seedersDir);
      if (hasExistingMigrations || hasExistingSeeders) {
        cliIO.section('Existing artifacts detected');
        if (hasExistingMigrations) {
          cliIO.writeln(
            '• Found existing migrations in ${tracker.relative(migrationsDir.path)}',
          );
        }
        if (hasExistingSeeders) {
          cliIO.writeln(
            '• Found existing seeders in ${tracker.relative(seedersDir.path)}',
          );
        }
        // When forcing scaffold recreation, do not auto-populate unless
        // explicitly requested via --populate-existing.
        final shouldPopulate = force
            ? false
            : io.confirm('Do you want to populate registries from existing files?');
        if (shouldPopulate) {
          await _populateExisting(
            io: cliIO,
            root: root,
            config: config,
            migrationsDir: migrationsDir,
            seedersDir: seedersDir,
            registryFile: registry,
            seedRegistryFile: seedRegistry,
          );
        }
      }
    }

    cliIO.twoColumnDetail('Ledger table', config.migrations.ledgerTable);
    cliIO.twoColumnDetail(
      'Schema dump directory',
      p.relative(schemaDumpDir.path, from: root.path),
    );

    if (showPaths) {
      cliIO.newLine();
      cliIO.section('Scaffolded artifact paths');
      for (final entry in tracker.paths.entries) {
        cliIO.twoColumnDetail(entry.key, tracker.relative(entry.value));
      }
    }

    cliIO.newLine();
    cliIO.success('Project initialized successfully.');
  }
}

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

void _writeFile({
  required File file,
  required String content,
  required String label,
  required bool force,
  required _ArtifactTracker tracker,
  bool interactive = false,
}) {
  tracker.note(label, file.path);
  file.parent.createSync(recursive: true);
  if (file.existsSync()) {
    if (force) {
      file.writeAsStringSync(content);
      cliIO.writeln(
        '${cliIO.style.foreground(Colors.warning).render('↻')} Recreated $label at ${tracker.relative(file.path)}',
      );
    } else {
      cliIO.writeln(
        '${cliIO.style.foreground(Colors.muted).render('○')} $label already exists ${cliIO.style.foreground(Colors.muted).render('(skipped)')}',
      );
    }
    return;
  }
  file.writeAsStringSync(content);
  cliIO.writeln(
    '${cliIO.style.foreground(Colors.success).render('✓')} Created $label at ${tracker.relative(file.path)}',
  );
}

void _ensureDirectory(Directory dir, String label, _ArtifactTracker tracker) {
  tracker.note(label, dir.path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    cliIO.writeln(
      '${cliIO.style.foreground(Colors.success).render('✓')} Created $label at ${tracker.relative(dir.path)}',
    );
  } else {
    cliIO.writeln('${cliIO.style.foreground(Colors.muted).render('○')} $label already exists');
  }
}

class _ArtifactTracker {
  _ArtifactTracker(this.root);

  final Directory root;
  final Map<String, String> paths = <String, String>{};

  void note(String label, String path) {
    paths[label] = path;
  }

  String relative(String path) => p.relative(path, from: root.path);
}

// --- Helpers for populating existing migrations/seeders ---

bool _hasDartFiles(Directory dir) {
  if (!dir.existsSync()) return false;
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .any((f) => f.path.endsWith('.dart'));
}

Future<void> _populateExisting({
  required ArtisanIO io,
  required Directory root,
  required OrmProjectConfig config,
  required Directory migrationsDir,
  required Directory seedersDir,
  required File registryFile,
  required File seedRegistryFile,
}) async {
  io.section('Populating registries from existing files');

  // Migrations: gather files like migrations/m_*.dart and rebuild registry
  final migrationFiles = migrationsDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  // Seeders: gather files in seeders dir
  final seederFiles = seedersDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  // Build migration registry content skeleton by importing and registering
  final migrationImports = <String>[];
  final migrationEntries = <String>[];
  for (final f in migrationFiles) {
    final rel = p.relative(f.path, from: p.dirname(registryFile.path));
    final importPath = rel.replaceAll('\\', '/');
    // Guess class name from filename, keep a conservative fallback
    final base = p.basenameWithoutExtension(f.path);
    // Expected pattern: m_YYYY..._name.dart => class CreateUsersTable or similar
    // We cannot reliably infer class – we import and leave a TODO entry
    migrationImports.add("import '$importPath';");
    migrationEntries.add(
      "  // TODO: Add entry for $base (imported above)",
    );
  }

  final registryContent = [
    "import 'dart:convert';",
    "",
    "import 'package:ormed/migrations.dart';",
    "",
    ...migrationImports,
    "",
    "final List<MigrationEntry> _entries = [",
    ...migrationEntries,
    "];",
    "",
    "/// Build migration descriptors sorted by timestamp.",
    "List<MigrationDescriptor> buildMigrations() =>",
    "    MigrationEntry.buildDescriptors(_entries);",
    "",
    "MigrationEntry? _findEntry(String rawId) {",
    "  for (final entry in _entries) {",
    "    if (entry.id.toString() == rawId) return entry;",
    "  }",
    "  return null;",
    "}",
    "",
    "void main(List<String> args) {",
    "  if (args.contains('--dump-json')) {",
    "    final payload = buildMigrations().map((m) => m.toJson()).toList();",
    "    print(jsonEncode(payload));",
    "    return;",
    "  }",
    "",
    "  final planIndex = args.indexOf('--plan-json');",
    "  if (planIndex != -1) {",
    "    final id = args[planIndex + 1];",
    "    final entry = _findEntry(id);",
    "    if (entry == null) {",
    "      throw StateError('Unknown migration id ' + id + '.');",
    "    }",
    "    final directionName = args[args.indexOf('--direction') + 1];",
    "    final direction = MigrationDirection.values.byName(directionName);",
    "    final snapshotIndex = args.indexOf('--schema-snapshot');",
    "    SchemaSnapshot? snapshot;",
    "    if (snapshotIndex != -1) {",
    "      final decoded = utf8.decode(base64.decode(args[snapshotIndex + 1]));",
    "      final payload = jsonDecode(decoded) as Map<String, Object?>;",
    "      snapshot = SchemaSnapshot.fromJson(payload);",
    "    }",
    "    final plan = entry.migration.plan(direction, snapshot: snapshot);",
    "    print(jsonEncode(plan.toJson()));",
    "  }",
    "}",
  ].join('\n');

  if (migrationFiles.isNotEmpty) {
    registryFile.writeAsStringSync(registryContent);
    io.success(
      'Populated migrations registry with ${migrationFiles.length} imports (manual entry TODOs left).',
    );
  } else {
    io.writeln(io.style.muted('No migration files found.'));
  }

  // Build seed registry
  final seedImports = <String>[];
  final seedRegistrations = <String>[];
  for (final f in seederFiles) {
    final rel = p.relative(f.path, from: p.dirname(seedRegistryFile.path));
    final importPath = rel.replaceAll('\\', '/');
    final base = p.basenameWithoutExtension(f.path);
    seedImports.add("import '$importPath';");
    seedRegistrations.add(
      "  // TODO: Register seeder for $base",
    );
  }

  final seedRegistryContent = [
    "import 'package:ormed_cli/runtime.dart';",
    "import 'package:ormed/ormed.dart';",
    "",
    ...seedImports,
    "",
    "final List<SeederRegistration> _seeders = <SeederRegistration>[",
    ...seedRegistrations,
    "];",
    "",
    "Future<void> seedPlayground(",
    "  OrmConnection connection, {",
    "  List<String>? names,",
    "  bool pretend = false,",
    "}) => runSeedRegistryOnConnection(",
    "  connection,",
    "  _seeders,",
    "  names: names,",
    "  pretend: pretend,",
    "  beforeRun: (conn) => conn.context.registry.registerGeneratedModels(),",
    ");",
    "",
    "Future<void> main(List<String> args) => runSeedRegistryEntrypoint(",
    "  args: args,",
    "  seeds: _seeders,",
    "  beforeRun: (connection) =>",
    "      connection.context.registry.registerGeneratedModels(),",
    ");",
  ].join('\n');

  if (seederFiles.isNotEmpty) {
    seedRegistryFile.writeAsStringSync(seedRegistryContent);
    io.success(
      'Populated seed registry with ${seederFiles.length} imports (manual registration TODOs left).',
    );
  } else {
    io.writeln(io.style.muted('No seeder files found.'));
  }
}
