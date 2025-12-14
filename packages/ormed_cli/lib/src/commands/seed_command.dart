import 'dart:io';

import 'package:artisan_args/artisan_args.dart';

import '../config.dart';
import 'shared.dart';

class SeedCommand extends ArtisanCommand<void> {
  SeedCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to orm.yaml (defaults to project root).',
      )
      ..addOption(
        'database',
        abbr: 'd',
        help: 'Override the database connection used for seeding.',
      )
      ..addOption(
        'connection',
        help:
            'Select a specific connection block defined in orm.yaml (defaults to default_connection or the only entry).',
      )
      ..addMultiOption(
        'class',
        abbr: 's',
        splitCommas: true,
        help:
            'Specific seeder class(es) to run (defaults to configured default).',
      )
      ..addFlag(
        'pretend',
        negatable: false,
        help: 'Preview SQL without executing it.',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Skip the production confirmation prompt.',
      );
  }

  @override
  String get name => 'seed';

  @override
  String get description => 'Run database seeders defined in orm.yaml.';

  @override
  Future<void> run() async {
    final configArg = argResults?['config'] as String?;
    final targetClasses = List<String>.from(
      argResults?['class'] as List? ?? const <String>[],
    );
    final pretend = argResults?['pretend'] == true;
    final force = argResults?['force'] == true;
    final databaseOverride = argResults?['database'] as String?;
    final connectionOverride = argResults?['connection'] as String?;

    final project = resolveOrmProject(configPath: configArg);
    final config = loadOrmProjectConfig(project.configFile);
    final seeds = config.seeds;
    if (seeds == null) {
      usageException(
        'orm.yaml missing seeds configuration. Run `orm init` to scaffold seeds or add a `seeds` block.',
      );
    }

    final classes = targetClasses.isEmpty ? null : targetClasses;

    if (pretend) {
      await runSeedRegistry(
        project: project,
        config: config,
        seeds: seeds,
        overrideClasses: classes,
        pretend: true,
        databaseOverride: databaseOverride,
        connection: connectionOverride,
      );
      return;
    }

    if (!confirmToProceed(force: force)) {
      stdout.writeln('Seeding cancelled.');
      return;
    }

    await runSeedRegistry(
      project: project,
      config: config,
      seeds: seeds,
      overrideClasses: classes,
      databaseOverride: databaseOverride,
      connection: connectionOverride,
    );
  }
}
