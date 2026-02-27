import 'package:ormed/ormed.dart';

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
    CliEventReporter reporter,
  ) async {
    final force = argResults?['force'] == true;
    final step = argResults?['step'] == true;
    final seed = argResults?['seed'] == true;
    final seederOverride = argResults?['seeder'] as String?;

    if (!confirmToProceed(force: force, action: 'refresh the database')) {
      cliIO.warn('Refresh cancelled.');
      return;
    }

    // 1. Reset
    final statuses = await runner.status();
    final appliedCount = statuses.where((s) => s.applied).length;

    if (appliedCount > 0) {
      cliIO.section('Rolling back $appliedCount migration(s)');
      await runner.rollback(steps: appliedCount);
    } else {
      cliIO.info('Nothing to rollback.');
    }

    cliIO.newLine();

    // 2. Migrate
    cliIO.section('Running migrations');
    final report = await runner.applyAll(limit: step ? 1 : null);

    if (report.isEmpty) {
      cliIO.info('No migrations to apply.');
    }
    cliIO.success('Database refreshed successfully.');

    // 3. Seed
    if (seed || seederOverride != null) {
      final seeds = config.seeds;
      if (seeds == null) {
        cliIO.warn('No seeds configuration found. Skipping seeder.');
      } else {
        cliIO.info('Running seeders...');
        await runSeedRegistry(
          project: project,
          config: config,
          seeds: seeds,
          overrideClasses: seederOverride == null
              ? null
              : <String>[seederOverride],
          databaseOverride: argResults?['database'] as String?,
          connection: argResults?['connection'] as String?,
        );
        cliIO.success('Seeding complete.');
      }
    }
  }
}
