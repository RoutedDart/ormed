import 'package:ormed/ormed.dart';

import '../base/runner_command.dart';
import '../base/shared.dart';

class RollbackCommand extends RunnerCommand {
  RollbackCommand() {
    argParser
      ..addOption(
        'steps',
        defaultsTo: '1',
        help: 'Number of migrations (steps) to rollback.',
      )
      ..addOption(
        'batch',
        help:
            'Rollback all migrations from the specified batch (latest batch by default).',
      )
      ..addFlag(
        'pretend',
        negatable: false,
        help: 'Preview rollback SQL without executing it.',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Skip the production confirmation prompt.',
      )
      ..addFlag(
        'graceful',
        negatable: false,
        help: 'Treat errors during rollback as warnings and return success.',
      );
  }

  @override
  String get name => 'migrate:rollback';

  @override
  String get description => 'Rollback the last database migration.';

  @override
  Future<void> handle(
    OrmProjectContext project,
    OrmProjectConfig config,
    MigrationRunner runner,
    OrmConnection connection,
    SqlMigrationLedger ledger,
    CliEventReporter reporter,
  ) async {
    final stepsRaw = argResults?['steps'] as String? ?? '1';
    var steps = int.tryParse(stepsRaw) ?? 1;
    final batchArg = argResults?['batch'] as String?;
    final pretend = argResults?['pretend'] == true;
    final force = argResults?['force'] == true;
    final graceful = argResults?['graceful'] == true;
    final schemaDriver = connection.driver as SchemaDriver;
    final appliedRecords = await ledger.readApplied();
    if (appliedRecords.isEmpty) {
      cliIO.info('No migrations to rollback.');
      return;
    }

    if (batchArg != null) {
      final batchNumber = int.tryParse(batchArg);
      if (batchNumber == null) {
        usageException('Invalid --batch value: $batchArg');
      }
      final highestBatch = appliedRecords.fold<int>(0, (previous, record) {
        return record.batch > previous ? record.batch : previous;
      });
      if (highestBatch == 0) {
        cliIO.warning('No batches found in the ledger.');
        return;
      }
      if (batchNumber != highestBatch) {
        usageException(
          'Rollback can only target the most recent batch ($highestBatch).',
        );
      }
      final batchRecords = appliedRecords
          .where((record) => record.batch == batchNumber)
          .toList();
      if (batchRecords.isEmpty) {
        cliIO.warning('Batch $batchNumber not found.');
        return;
      }
      steps = batchRecords.length;
    }

    steps = steps.clamp(1, appliedRecords.length);

    final registryPath = resolveRegistryFilePath(
      project.root,
      config,
      override: argResults?['path'] as String?,
      realPath: argResults?['realpath'] == true,
    );

    if (pretend) {
      await previewRollbacks(
        root: project.root,
        config: config,
        runner: runner,
        schemaDriver: schemaDriver,
        steps: steps,
        registryPath: registryPath,
      );
      return;
    }

    if (!confirmToProceed(force: force)) {
      cliIO.warning('Rollback cancelled.');
      return;
    }

    try {
      final report = await runner.rollback(steps: steps);
      if (report.isEmpty) {
        cliIO.info('No migrations rolled back.');
      }
    } catch (error) {
      if (graceful) {
        cliIO.warning('$error');
        return;
      }
      rethrow;
    }
  }
}
