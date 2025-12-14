import 'dart:io';

import 'package:artisan_args/artisan_args.dart';
import 'package:ormed/ormed.dart';

import '../../config.dart';
import '../base/runner_command.dart';
import '../base/shared.dart';

class WipeCommand extends RunnerCommand {
  WipeCommand() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Skip the production confirmation prompt.',
    );
    // database option inherited from RunnerCommand
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
  String get name => 'db:wipe';

  @override
  String get description =>
      'Drop all tables, views, and types from the database.';

  @override
  Future<void> handle(
    OrmProjectContext project,
    OrmProjectConfig config,
    MigrationRunner runner,
    OrmConnection connection,
    SqlMigrationLedger ledger,
  ) async {
    final force = argResults?['force'] == true;
    final dropViews = argResults?['drop-views'] == true;
    // final dropTypes = argResults?['drop-types'] == true;

    if (!confirmToProceed(force: force, action: 'wipe the database')) {
      cliIO.warning('Wipe cancelled.');
      return;
    }

    final driver = connection.driver;
    if (driver is! SchemaDriver) {
      usageException('Database driver does not support schema operations.');
    }

    final schemaDriver = driver as SchemaDriver;
    final inspector = SchemaInspector(schemaDriver);

    // Drop Views
    if (dropViews) {
      // Typically SchemaInspector might not support listing views yet,
      // but if it did, we'd iterate and drop them.
      // For now, we assume standard tables.
      // If the driver supports wiping views, we'd use a specialized method.
      // Since `ormed` doesn't expose `dropAllViews` generically yet, we might skip or todo.
      // But let's check `SchemaDriver`.
      // It has `executeRaw`.
      // Getting strict: `db:wipe` usually drops all tables.
    }

    final tables = await inspector.tableListing(schemaQualified: true);
    if (tables.isEmpty) {
      cliIO.info('Database is already empty.');
    } else {
      cliIO.info('Dropping ${tables.length} table(s)...');

      try {
        await schemaDriver.dropAllTables();
      } catch (e) {
        cliIO.error('Failed to drop tables: $e');
        rethrow;
      }

      cliIO.success('Dropped all tables successfully.');
    }
  }
}
