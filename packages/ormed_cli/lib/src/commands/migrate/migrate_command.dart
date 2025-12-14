import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import '../base/runner_command.dart';
import '../base/shared.dart';

class ApplyCommand extends RunnerCommand {
  ApplyCommand() {
    argParser.addOption('limit', help: 'Maximum number of migrations to run.');
    argParser.addFlag(
      'seed',
      negatable: false,
      help: 'Run the default seeder after applying migrations.',
    );
    argParser.addOption(
      'seeder',
      help: 'Run a specific seeder after migrations.',
    );
    argParser.addFlag(
      'step',
      negatable: false,
      help:
          'Apply migrations one step at a time so rollbacks can target each change.',
    );
    argParser.addFlag(
      'pretend',
      negatable: false,
      help: 'Preview the SQL that would run without mutating the database.',
    );
    argParser.addOption(
      'schema-path',
      help:
          'Schema dump file to load when the ledger is empty (defaults to migrations.schema_dump).',
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Skip the production confirmation prompt.',
    );
    argParser.addFlag(
      'graceful',
      negatable: false,
      help:
          'Return success even if an error occurs during migration application.',
    );
  }

  @override
  String get name => 'migrate';

  @override
  String get description => 'Run the database migrations.';

  @override
  Future<void> handle(
    OrmProjectContext project,
    OrmProjectConfig config,
    MigrationRunner runner,
    OrmConnection connection,
    SqlMigrationLedger ledger,
  ) async {
    final limitRaw = argResults?['limit'] as String?;
    final limit = limitRaw == null ? null : int.tryParse(limitRaw);
    final step = argResults?['step'] == true;
    final pretend = argResults?['pretend'] == true;
    final force = argResults?['force'] == true;
    final graceful = argResults?['graceful'] == true;
    final schemaPath = argResults?['schema-path'] as String?;

    final driver = connection.driver;
    final schemaDriver = driver as SchemaDriver;
    await _prepareLedger(
      project: project,
      config: config,
      ledger: ledger,
      driver: driver,
      schemaDriver: schemaDriver,
      schemaPathOverride: schemaPath,
      connection: connection,
    );

    if (pretend) {
      final registryPath = resolveRegistryFilePath(
        project.root,
        config,
        override: argResults?['path'] as String?,
        realPath: argResults?['realpath'] == true,
      );
      await _previewMigrations(
        root: project.root,
        config: config,
        runner: runner,
        schemaDriver: schemaDriver,
        limit: step ? 1 : limit,
        registryPath: registryPath,
      );
      return;
    }

    if (!confirmToProceed(force: force)) {
      cliIO.warning('Migration cancelled.');
      return;
    }

    final limitToApply = step ? 1 : limit;
    final seeds = config.seeds;
    try {
      final report = await runner.applyAll(limit: limitToApply);
      if (report.isEmpty) {
        cliIO.info('No migrations to apply.');
      } else {
        for (final action in report.actions) {
          cliIO.writeln(
            '${cliIO.style.success('✓')} Applied ${cliIO.style.emphasize(action.descriptor.id.toString())} ${cliIO.style.muted('(${action.duration.inMilliseconds}ms)')}',
          );
        }
        cliIO.newLine();
        cliIO.success('Applied ${report.actions.length} migration(s).');
      }
    } catch (error) {
      if (graceful) {
        cliIO.warning('$error');
        return;
      }
      rethrow;
    }

    if ((argResults?['seed'] == true) || argResults?['seeder'] != null) {
      if (seeds == null) {
        usageException(
          'orm.yaml missing seeds configuration. Add a `seeds` block before running --seed.',
        );
      }
      final seederOverride = argResults?['seeder'] as String?;
      final targetClass = seederOverride ?? seeds.defaultClass;
      cliIO.info('Running seeder $targetClass...');
      await runSeedRegistry(
        project: project,
        config: config,
        seeds: seeds,
        overrideClasses: <String>[targetClass],
        databaseOverride: argResults?['database'] as String?,
      );
    }
  }
}

Future<void> _prepareLedger({
  required OrmProjectContext project,
  required OrmProjectConfig config,
  required SqlMigrationLedger ledger,
  required DriverAdapter driver,
  required SchemaDriver schemaDriver,
  required OrmConnection connection,
  String? schemaPathOverride,
}) async {
  await ledger.ensureInitialized();
  final applied = await ledger.readApplied();
  if (applied.isNotEmpty) return;
  final dumpFile = _resolveSchemaDumpFile(
    project.root,
    config,
    schemaPathOverride,
  );
  if (!dumpFile.existsSync()) {
    return;
  }
  final state = resolveSchemaState(
    driver,
    connection,
    config.migrations.ledgerTable,
  );
  if (state != null && state.canLoad) {
    await state.load(dumpFile);
    cliIO.success(
      'Loaded schema dump from ${p.relative(dumpFile.path, from: project.root.path)}',
    );
    return;
  }
  await _executeSchemaDump(driver, dumpFile);
  cliIO.success(
    'Loaded schema dump from ${p.relative(dumpFile.path, from: project.root.path)} (fallback)',
  );
}

Future<void> _executeSchemaDump(DriverAdapter driver, File dumpFile) async {
  final statements = <String>[];
  final buffer = StringBuffer();
  for (final rawLine in dumpFile.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('--')) {
      continue;
    }
    buffer.write(line);
    if (line.endsWith(';')) {
      statements.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(' ');
    }
  }
  final remainder = buffer.toString().trim();
  if (remainder.isNotEmpty) {
    statements.add(remainder);
  }
  for (final statement in statements) {
    final sql = statement.trim();
    if (sql.isEmpty) continue;
    await driver.executeRaw(sql);
  }
}

File _resolveSchemaDumpFile(
  Directory root,
  OrmProjectConfig config,
  String? override,
) {
  final candidate = override ?? config.migrations.schemaDump;
  final path = p.isAbsolute(candidate)
      ? p.normalize(candidate)
      : resolvePath(root, candidate);
  return File(path);
}

Future<void> _previewMigrations({
  required Directory root,
  required OrmProjectConfig config,
  required MigrationRunner runner,
  required SchemaDriver schemaDriver,
  int? limit,
  required String registryPath,
}) async {
  final statuses = await runner.status();
  final pending = statuses.where((status) => !status.applied).toList();
  if (pending.isEmpty) {
    cliIO.info('No pending migrations.');
    return;
  }
  final snapshot = await SchemaSnapshot.capture(schemaDriver);
  final count = limit == null || limit > pending.length
      ? pending.length
      : limit;
  for (var i = 0; i < count; i++) {
    final descriptor = pending[i].descriptor;
    final plan = await buildRuntimePlan(
      root: root,
      config: config,
      id: descriptor.id,
      direction: MigrationDirection.up,
      snapshot: snapshot,
      registryPath: registryPath,
    );
    final diff = SchemaDiffer().diff(plan: plan, snapshot: snapshot);
    final preview = schemaDriver.describeSchemaPlan(plan);
    printMigrationPlanPreview(
      descriptor: descriptor,
      direction: MigrationDirection.up,
      diff: diff,
      preview: preview,
      includeStatements: true,
    );
  }
}
