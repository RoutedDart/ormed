import 'dart:io';

import 'package:ormed/ormed.dart';

import 'runner_command.dart';
import 'shared.dart';

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
  String get name => 'status';

  @override
  String get description => 'Show migration status.';

  @override
  Future<void> handle(
    OrmProjectContext project,
    OrmProjectConfig config,
    MigrationRunner runner,
    OrmConnection connection,
    SqlMigrationLedger ledger,
  ) async {
    final pendingOnly = argResults?['pending'] == true;
    final statuses = await runner.status();
    final filtered = pendingOnly
        ? statuses.where((status) => !status.applied).toList()
        : statuses;
    if (filtered.isEmpty) {
      if (pendingOnly) {
        stdout.writeln('No pending migrations.');
      } else {
        stdout.writeln('No migrations registered.');
      }
      return;
    }

    stdout.writeln('Migration                                 Status');
    stdout.writeln(
      '------------------------------------------ -------------------------',
    );
    for (final status in filtered) {
      final batchSuffix = status.batch != null
          ? ' [batch ${status.batch}]'
          : '';
      final statusLabel = status.applied
          ? 'Ran at ${status.appliedAt?.toIso8601String() ?? 'unknown'}'
          : 'Pending';
      stdout.writeln(
        '${status.descriptor.id}$batchSuffix'.padRight(40) + statusLabel,
      );
    }

    if (pendingOnly && filtered.isNotEmpty) {
      exitCode = 1;
    }
  }
}
