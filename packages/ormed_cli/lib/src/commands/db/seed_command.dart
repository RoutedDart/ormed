import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import '../base/shared.dart';

class SeedCommand extends Command<void> {
  SeedCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help:
            'Path to ormed.yaml (optional; convention defaults are used when omitted).',
      )
      ..addOption(
        'database',
        abbr: 'd',
        help: 'Override the database connection used for seeding.',
      )
      ..addOption(
        'connection',
        help:
            'Select a specific connection block defined in ormed.yaml when present (defaults to default_connection or the only entry).',
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
  String get description =>
      'Run database seeders from the configured (or default) registry.';

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

    final resolved = resolveOrmProjectConfig(configPath: configArg);
    var config = resolved.config;
    if (connectionOverride != null && connectionOverride.trim().isNotEmpty) {
      config = config.withConnection(connectionOverride);
    }
    final project = OrmProjectContext(
      root: resolved.root,
      configFile: resolved.configFile,
    );
    var bootstrappedSeedScaffold = false;
    if (!resolved.hasConfigFile) {
      printConfigFallbackNotice();
    }
    final seeds = config.seeds;
    if (seeds == null) {
      usageException(
        'Missing seeds configuration. Run `ormed init --only=seeders` or add a `seeds` block to ormed.yaml.',
      );
    }
    if (projectSeederRunner is ProcessProjectSeederRunner) {
      final registryFile = File(resolvePath(project.root, seeds.registry));
      final seedersDir = Directory(resolvePath(project.root, seeds.directory));
      if (!registryFile.existsSync()) {
        if (!hasSeederSources(seedersDir)) {
          final changed = ensureSeedScaffoldIfMissing(
            root: project.root,
            seeds: seeds,
            packageName: getPackageName(project.root),
          );
          if (changed) {
            bootstrappedSeedScaffold = true;
            cliIO.note(
              'Bootstrapped seed scaffolding at ${p.relative(seedersDir.path, from: project.root.path)}.',
            );
          }
        }
      }
      final refreshedRegistry = File(resolvePath(project.root, seeds.registry));
      if (!refreshedRegistry.existsSync()) {
        usageException(
          'Seed registry ${registryFile.path} not found, but seeder files exist in ${seedersDir.path}. '
          'Run `ormed init --only=seeders --populate-existing` to scaffold and register seeders.',
        );
      }
    }

    if (bootstrappedSeedScaffold) {
      cliIO.note(
        'Seed scaffold was created. Run `dart run build_runner build` then rerun `ormed seed`.',
      );
      return;
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
      cliIO.warn('Seeding cancelled.');
      return;
    }

    cliIO.info('Running seeders...');
    await runSeedRegistry(
      project: project,
      config: config,
      seeds: seeds,
      overrideClasses: classes,
      databaseOverride: databaseOverride,
      connection: connectionOverride,
    );
    cliIO.success('Seeding complete.');
  }
}
