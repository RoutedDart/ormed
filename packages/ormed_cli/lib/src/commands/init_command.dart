import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../config.dart';
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
      );
  }

  @override
  String get name => 'init';

  @override
  String get description => 'Initialize orm.yaml and migration registry.';

  @override
  Future<void> run() async {
    final force = argResults?['force'] == true;
    final showPaths = argResults?['paths'] == true;
    final root = findProjectRoot();
    final tracker = _ArtifactTracker(root);

    final configFile = File(p.join(root.path, 'orm.yaml'));
    _writeFile(
      file: configFile,
      content: defaultOrmYaml,
      label: 'orm.yaml',
      force: force,
      tracker: tracker,
    );

    // Load config to get paths from defaultOrmYaml
    final config = loadOrmProjectConfig(configFile);

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
    );

    final defaultSeeder = File(p.join(seedersDir.path, 'database_seeder.dart'));
    _writeFile(
      file: defaultSeeder,
      content: _defaultSeederTemplate,
      label: 'database seeder',
      force: force,
      tracker: tracker,
    );
    // Create schema dump directory
    final schemaDumpDir = Directory(
      resolvePath(root, config.migrations.schemaDump),
    );
    if (!schemaDumpDir.existsSync()) {
      schemaDumpDir.createSync(recursive: true);
      tracker.paths['schema'] = schemaDumpDir.path;
    }

    // Create a .gitkeep to ensure directory is tracked
    final gitkeep = File(p.join(schemaDumpDir.path, '.gitkeep'));
    if (!gitkeep.existsSync()) {
      gitkeep.writeAsStringSync('');
    }

    stdout.writeln(
      'Ledger table configured as ${config.migrations.ledgerTable}.',
    );
    stdout.writeln(
      'Schema dump directory: ${p.relative(schemaDumpDir.path, from: root.path)}',
    );

    if (showPaths) {
      stdout.writeln('\nScaffolded artifact paths:');
      for (final entry in tracker.paths.entries) {
        stdout.writeln('  ${entry.key}: ${tracker.relative(entry.value)}');
      }
    }
  }
}

const String _defaultSeederTemplate = '''
import 'package:ormed/ormed.dart';

class DatabaseSeeder extends DatabaseSeeder {
  DatabaseSeeder(super.connection);

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
}) {
  tracker.note(label, file.path);
  file.parent.createSync(recursive: true);
  if (file.existsSync()) {
    if (force) {
      file.writeAsStringSync(content);
      stdout.writeln('Recreated $label at ${tracker.relative(file.path)}');
    } else {
      stdout.writeln('$label already exists at ${tracker.relative(file.path)}');
    }
    return;
  }
  file.writeAsStringSync(content);
  stdout.writeln('Created $label at ${tracker.relative(file.path)}');
}

void _ensureDirectory(Directory dir, String label, _ArtifactTracker tracker) {
  tracker.note(label, dir.path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    stdout.writeln('Created $label at ${tracker.relative(dir.path)}');
  } else {
    stdout.writeln('$label already exists at ${tracker.relative(dir.path)}');
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
