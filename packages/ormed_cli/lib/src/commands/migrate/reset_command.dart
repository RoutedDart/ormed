import 'dart:io';

import 'package:artisan_args/artisan_args.dart';
import 'package:ormed/ormed.dart';

import '../../config.dart';
import '../base/runner_command.dart';
import '../base/shared.dart';

class ResetCommand extends RunnerCommand {
  ResetCommand() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Skip the production confirmation prompt.',
    );
    argParser.addFlag(
      'pretend',
      negatable: false,
      help: 'Dump the SQL queries that would be run.',
    );
  }

  @override
  String get name => 'migrate:reset';

  @override
  String get description => 'Rollback all database migrations.';

  @override
  Future<void> handle(
    OrmProjectContext project,
    OrmProjectConfig config,
    MigrationRunner runner,
    OrmConnection connection,
    SqlMigrationLedger ledger,
  ) async {
    final force = argResults?['force'] == true;
    final pretend = argResults?['pretend'] == true;

    if (!pretend &&
        !confirmToProceed(force: force, action: 'reset the database')) {
      cliIO.warning('Reset cancelled.');
      return;
    }

    final statuses = await runner.status();
    final appliedCount = statuses.where((s) => s.applied).length;

    if (appliedCount == 0) {
      cliIO.info('Nothing to rollback.');
      return;
    }

    if (pretend) {
      final registryPath = resolveRegistryFilePath(
        project.root,
        config,
        override: argResults?['path'] as String?,
        realPath: argResults?['realpath'] == true,
      );
      final schemaDriver = connection.driver as SchemaDriver;
      await previewRollbacks(
        root: project.root,
        config: config,
        runner: runner,
        schemaDriver: schemaDriver,
        steps: appliedCount,
        registryPath: registryPath,
      );
      return;
    }

    final report = await runner.rollback(steps: appliedCount);

    if (report.isEmpty) {
      cliIO.info('Nothing to rollback.');
    } else {
      for (final action in report.actions) {
        cliIO.writeln(
          '${cliIO.style.success('✓')} Rolled back ${cliIO.style.emphasize(action.descriptor.id.toString())} ${cliIO.style.muted('(${action.duration.inMilliseconds}ms)')}',
        );
      }
      cliIO.newLine();
      cliIO.success(
        'Reset complete. Rolled back ${report.actions.length} migration(s).',
      );
    }
  }
}
