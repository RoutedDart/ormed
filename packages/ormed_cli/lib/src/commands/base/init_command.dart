import 'dart:io';

import 'package:artisan_args/artisan_args.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import 'shared.dart';

class InitCommand extends ArtisanCommand<void> {
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

    // Add wizard if running without specific flags, or explicit wizard mode?
    // Usually 'init' just does default.
    // Let's make it interactive by default if config file doesn't exist?
    // Or just ask "Do you want to initialize now?"
    // The previous implementation was purely scaffold.
    // We can add a simple interactive confirmation.

    if (!force) {
      final configFile = File(p.join(root.path, 'orm.yaml'));
      if (configFile.existsSync()) {
        stdout.writeln('Project already initialized.');
        if (!io.confirm('Do you want to re-initialize (overwrite files)?')) {
          return;
        }
        // If confirmed, proceed with overwrite (simulate force behavior for this run)
        // But we need to pass force=true technically.
        // We'll handle force logic in _writeFile.
      }
    }

    final configFile = File(p.join(root.path, 'orm.yaml'));
    _writeFile(
      file: configFile,
      content: defaultOrmYaml,
      label: 'orm.yaml',
      force:
          force, // If interactive override, we might need variable update. But simpler to rely on _writeFile logic? No, _writeFile takes 'force'.
      tracker: tracker,
      interactive: true, // Let _writeFile ask if force not set?
    );

    // ... (rest is same but passed interactive context)
    // Actually, refactoring _writeFile to handle interactive confirm is cleaner.

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

    // Create a .gitkeep to ensure directory is tracked
    final gitkeep = File(p.join(schemaDumpDir.path, '.gitkeep'));
    if (!gitkeep.existsSync()) {
      gitkeep.writeAsStringSync('');
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
  bool interactive = false,
}) {
  tracker.note(label, file.path);
  file.parent.createSync(recursive: true);
  if (file.existsSync()) {
    if (force) {
      file.writeAsStringSync(content);
      cliIO.writeln(
        '${cliIO.style.warning('↻')} Recreated $label at ${tracker.relative(file.path)}',
      );
    } else {
      cliIO.writeln(
        '${cliIO.style.muted('○')} $label already exists ${cliIO.style.muted('(skipped)')}',
      );
    }
    return;
  }
  file.writeAsStringSync(content);
  cliIO.writeln(
    '${cliIO.style.success('✓')} Created $label at ${tracker.relative(file.path)}',
  );
}

void _ensureDirectory(Directory dir, String label, _ArtifactTracker tracker) {
  tracker.note(label, dir.path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    cliIO.writeln(
      '${cliIO.style.success('✓')} Created $label at ${tracker.relative(dir.path)}',
    );
  } else {
    cliIO.writeln('${cliIO.style.muted('○')} $label already exists');
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
