import 'dart:io';

import 'package:artisan_args/artisan_args.dart';
import 'package:ormed/ormed.dart';

import '../../config.dart';
import '../base/runner_command.dart';
import '../base/shared.dart';

class RefreshCommand extends RunnerCommand {
  RefreshCommand() {
    argParser.addFlag(
      'seed',
      negatable: false,
      help: 'Run the default seeder after refreshing.',
    );
    argParser.addOption(
      'seeder',
      help: 'Run a specific seeder after refreshing.',
    );
    argParser.addFlag(
      'step',
      negatable: false,
      help: 'Run the migrations one by one.',
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Skip the production confirmation prompt.',
    );
  }

  @override
  String get name => 'migrate:refresh';

  @override
  String get description => 'Reset and re-run all migrations.';

  @override
  Future<void> handle(
    OrmProjectContext project,
    OrmProjectConfig config,
    MigrationRunner runner,
    OrmConnection connection,
    SqlMigrationLedger ledger,
  ) async {
    final force = argResults?['force'] == true;
    final step = argResults?['step'] == true;
    final seed = argResults?['seed'] == true;
    final seederOverride = argResults?['seeder'] as String?;

    if (!confirmToProceed(force: force, action: 'refresh the database')) {
      cliIO.warning('Refresh cancelled.');
      return;
    }

    // 1. Reset
    final statuses = await runner.status();
    final appliedCount = statuses.where((s) => s.applied).length;

    if (appliedCount > 0) {
      cliIO.section('Rolling back $appliedCount migration(s)');
      final report = await runner.rollback(steps: appliedCount);
      for (final action in report.actions) {
        cliIO.writeln(
          '${cliIO.style.success('✓')} Rolled back ${cliIO.style.emphasize(action.descriptor.id.toString())} ${cliIO.style.muted('(${action.duration.inMilliseconds}ms)')}',
        );
      }
    } else {
      cliIO.info('Nothing to rollback.');
    }

    cliIO.newLine();

    // 2. Migrate
    cliIO.section('Running migrations');
    final report = await runner.applyAll(limit: step ? 1 : null);

    if (report.isEmpty) {
      cliIO.info('No migrations to apply.');
    } else {
      for (final action in report.actions) {
        cliIO.writeln(
          '${cliIO.style.success('✓')} Applied ${cliIO.style.emphasize(action.descriptor.id.toString())} ${cliIO.style.muted('(${action.duration.inMilliseconds}ms)')}',
        );
      }
      cliIO.newLine();
      cliIO.success('Database refreshed successfully.');
    }

    // 3. Seed
    if (seed || seederOverride != null) {
      final seeds = config.seeds;
      if (seeds == null) {
        cliIO.warning('No seeds configuration found. Skipping seeder.');
      } else {
        final targetClass = seederOverride ?? seeds.defaultClass;
        cliIO.info('Running seeder $targetClass...');
        await runSeedRegistry(
          project: project,
          config: config,
          seeds: seeds,
          overrideClasses: <String>[targetClass],
          databaseOverride: argResults?['database'] as String?,
          connection: argResults?['connection'] as String?,
        );
        cliIO.success('Seeding complete.');
      }
    }
  }
}
