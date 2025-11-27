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

    final migrationsDir = Directory(
      p.join(root.path, 'database', 'migrations'),
    );
    _ensureDirectory(migrationsDir, 'database/migrations', tracker);

    final registry = File(p.join(root.path, 'database', 'migrations.dart'));
    _writeFile(
      file: registry,
      content: initialRegistryTemplate,
      label: 'database/migrations.dart',
      force: force,
      tracker: tracker,
    );

    final seedersDir = Directory(p.join(root.path, 'database', 'seeders'));
    _ensureDirectory(seedersDir, 'database/seeders', tracker);

    final seedRegistry = File(p.join(root.path, 'database', 'seeders.dart'));
    _writeFile(
      file: seedRegistry,
      content: initialSeedRegistryTemplate,
      label: 'database/seeders.dart',
      force: force,
      tracker: tracker,
    );

    final defaultSeeder = File(p.join(seedersDir.path, 'database_seeder.dart'));
    _writeFile(
      file: defaultSeeder,
      content: _defaultSeederTemplate,
      label: 'database/seeders/database_seeder.dart',
      force: force,
      tracker: tracker,
    );

    final config = loadOrmProjectConfig(configFile);
    final schemaDumpFile = File(
      resolvePath(root, config.migrations.schemaDump),
    );
    _writeFile(
      file: schemaDumpFile,
      content: schemaDumpTemplate,
      label: config.migrations.schemaDump,
      force: force,
      tracker: tracker,
    );

    stdout.writeln(
      'Ledger table configured as ${config.migrations.ledgerTable}.',
    );
    stdout.writeln(
      'Schema dump target: ${p.relative(schemaDumpFile.path, from: root.path)}',
    );

    if (showPaths) {
      stdout.writeln('\nScaffolded artifact paths:');
      for (final entry in tracker.paths.entries) {
        stdout.writeln('  ${entry.key}: ${tracker.relative(entry.value)}');
      }
    }
  }
}

const String schemaDumpTemplate = '''
-- Schema dump created by orm init.
-- Run `dart run orm_cli:orm schema:describe` to refresh this file.
''';

const String _defaultSeederTemplate = '''
import 'package:ormed/ormed.dart';

import '../seeders.dart';

class DatabaseSeeder {
  const DatabaseSeeder();

  Future<void> run(SeedContext context) async {
    final seeder = context.seeder;
    // TODO: add demo rows with seeder.insert(...)
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
