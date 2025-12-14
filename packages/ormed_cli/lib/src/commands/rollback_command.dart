import 'dart:io';

import 'package:ormed/ormed.dart';

import 'runner_command.dart';
import 'shared.dart';

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
      stdout.writeln('No migrations to rollback.');
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
        stdout.writeln('No batches found in the ledger.');
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
        stdout.writeln('Batch $batchNumber not found.');
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
      await _previewRollbacks(
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
      stdout.writeln('Rollback cancelled.');
      return;
    }

    try {
      final report = await runner.rollback(steps: steps);
      if (report.isEmpty) {
        stdout.writeln('No migrations rolled back.');
        return;
      }
      final lookup = {
        for (final record in appliedRecords) record.id.toString(): record,
      };
      for (final action in report.actions) {
        final batch = lookup[action.descriptor.id.toString()]?.batch;
        final batchSuffix = batch != null ? ' (batch $batch)' : '';
        stdout.writeln('Rolled back ${action.descriptor.id}$batchSuffix.');
      }
    } catch (error) {
      if (graceful) {
        stdout.writeln('Warning: $error');
        return;
      }
      rethrow;
    }
  }
}

Future<void> _previewRollbacks({
  required Directory root,
  required OrmProjectConfig config,
  required MigrationRunner runner,
  required SchemaDriver schemaDriver,
  required int steps,
  required String registryPath,
}) async {
  final statuses = await runner.status();
  final applied = statuses.where((status) => status.applied).toList();
  if (applied.isEmpty) {
    stdout.writeln('No applied migrations to preview.');
    return;
  }
  final count = steps > applied.length ? applied.length : steps;
  final snapshot = await SchemaSnapshot.capture(schemaDriver);
  final targets = applied.reversed.take(count).toList();
  for (final status in targets) {
    final descriptor = status.descriptor;
    final plan = await buildRuntimePlan(
      root: root,
      config: config,
      id: descriptor.id,
      direction: MigrationDirection.down,
      snapshot: snapshot,
      registryPath: registryPath,
    );
    final diff = SchemaDiffer().diff(plan: plan, snapshot: snapshot);
    final preview = schemaDriver.describeSchemaPlan(plan);
    printMigrationPlanPreview(
      descriptor: descriptor,
      direction: MigrationDirection.down,
      diff: diff,
      preview: preview,
      includeStatements: true,
    );
  }
}
