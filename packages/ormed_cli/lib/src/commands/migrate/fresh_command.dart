import 'package:ormed/ormed.dart';

import '../base/runner_command.dart';
import '../base/shared.dart';

class FreshCommand extends RunnerCommand {
  FreshCommand() {
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
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Skip the production confirmation prompt.',
    );
    argParser.addFlag(
      'drop-views',
      negatable: false,
      help: 'Drop all views in addition to tables.',
    );
    argParser.addFlag(
      'drop-types',
      negatable: false,
      help: 'Drop all user-defined types (Postgres only).',
    );
  }

  @override
  String get name => 'migrate:fresh';

  @override
  String get description => 'Drop all tables and re-run all migrations.';

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
    final seed = argResults?['seed'] == true;
    final seederOverride = argResults?['seeder'] as String?;
    // drop-views / drop-types ignored or todo as in WipeCommand

    if (!confirmToProceed(
      force: force,
      action: 'wipe and re-migrate the database',
    )) {
      cliIO.warn('Fresh cancelled.');
      return;
    }

    final driver = connection.driver;
    if (driver is! SchemaDriver) {
      usageException('Database driver does not support schema operations.');
    }
    final schemaDriver = driver as SchemaDriver;

    cliIO.info('Dropping all tables...');
    try {
      await schemaDriver.dropAllTables();
      cliIO.success('Dropped all tables.');
    } catch (e) {
      cliIO.error('Failed to drop tables: $e');
      rethrow;
    }

    cliIO.newLine();
    cliIO.info('Running migrations...');
    final report = await runner.applyAll();

    if (report.isEmpty) {
      cliIO.info('No migrations to apply.');
    }

    // Seed
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
