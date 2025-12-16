import 'dart:io';

import 'package:ormed/ormed.dart';

import '../base/runner_command.dart';
import '../base/shared.dart';

class StatusCommand extends RunnerCommand {
  StatusCommand() {
    argParser.addFlag(
      'pending',
      negatable: false,
      help:
          'Only list pending migrations and exit with a failure when any exist.',
    );
  }

  @override
  String get name => 'migrate:status';

  @override
  String get description => 'Show the status of each migration.';

  @override
  Future<void> handle(
    OrmProjectContext project,
    OrmProjectConfig config,
    MigrationRunner runner,
    OrmConnection connection,
    SqlMigrationLedger ledger,
    CliEventReporter reporter,
  ) async {
    final pendingOnly = argResults?['pending'] == true;
    final statuses = await runner.status();
    final filtered = pendingOnly
        ? statuses.where((status) => !status.applied).toList()
        : statuses;
    if (filtered.isEmpty) {
      if (pendingOnly) {
        cliIO.info('No pending migrations.');
      } else {
        cliIO.info('No migrations registered.');
      }
      return;
    }

    cliIO.title('Migration Status');

    final rows = filtered.map((status) {
      final batchStr = status.batch?.toString() ?? '-';
      final statusLabel = status.applied
          ? cliIO.style.success('Applied')
          : cliIO.style.warning('Pending');
      final appliedAt = status.applied
          ? (status.appliedAt?.toIso8601String() ?? 'unknown')
          : '-';
      return [
        status.descriptor.id.toString(),
        batchStr,
        statusLabel,
        appliedAt,
      ];
    }).toList();

    cliIO.table(
      headers: ['Migration', 'Batch', 'Status', 'Applied At'],
      rows: rows,
    );

    if (pendingOnly && filtered.isNotEmpty) {
      exitCode = 1;
    }
  }
}
