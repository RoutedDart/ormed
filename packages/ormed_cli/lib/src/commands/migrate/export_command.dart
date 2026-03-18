import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:ormed/ormed.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import '../base/shared.dart';

class ExportCommand extends Command<void> {
  ExportCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help:
            'Path to ormed.yaml (optional; convention defaults are used when omitted).',
      )
      ..addOption(
        'path',
        help:
            'Override the migration registry file path (relative to project root unless --realpath is used).',
      )
      ..addFlag(
        'realpath',
        negatable: false,
        help: 'Treat --path as an absolute path.',
      )
      ..addOption(
        'database',
        abbr: 'd',
        help: 'Override the database connection used by this command.',
      )
      ..addOption(
        'connection',
        help:
            'Select a specific connection block defined in ormed.yaml when present (defaults to default_connection or the only entry).',
      )
      ..addOption(
        'out',
        help:
            'Output directory for exported SQL (defaults to migrations.directory).',
      )
      ..addFlag(
        'all',
        negatable: false,
        help: 'Export all migrations (default: only pending).',
      )
      ..addOption(
        'limit',
        help: 'Maximum number of pending migrations to export.',
      );
  }

  @override
  String get name => 'migrate:export';

  @override
  String get description =>
      'Export SQL files (up.sql/down.sql) from Dart migrations without applying them.';

  @override
  Future<void> run() async {
    final configArg = argResults?['config'] as String?;
    final databaseOverride = argResults?['database'] as String?;
    final connectionOverride = argResults?['connection'] as String?;
    final pathOverride = argResults?['path'] as String?;
    final realPath = argResults?['realpath'] == true;
    final exportAll = argResults?['all'] == true;
    final limitRaw = argResults?['limit'] as String?;
    final limit = limitRaw == null ? null : int.tryParse(limitRaw);

    final resolved = resolveOrmProjectConfig(configPath: configArg);
    final root = resolved.root;
    var config = resolved.config;
    if (!resolved.hasConfigFile) {
      printConfigFallbackNotice();
    }
    if (connectionOverride != null && connectionOverride.trim().isNotEmpty) {
      config = config.withConnection(connectionOverride);
    }
    final effectiveConfig = databaseOverride == null
        ? config
        : config.updateActiveConnection(
            driver: config.driver.copyWith(
              options: {...config.driver.options, 'database': databaseOverride},
            ),
          );

    final registryPath = resolveRegistryFilePath(
      root,
      effectiveConfig,
      override: pathOverride,
      realPath: realPath,
    );

    final migrations = await loadMigrations(
      root,
      effectiveConfig,
      registryPath: registryPath,
    );
    if (migrations.isEmpty) {
      cliIO.warn('No migrations found in registry.');
      return;
    }

    final outOverride = (argResults?['out'] as String?)?.trim();
    final outPath = _resolveOutPath(
      root: root,
      config: effectiveConfig,
      override: outOverride,
    );
    final outputRoot = Directory(outPath)..createSync(recursive: true);

    final handle = await createConnection(root, effectiveConfig);
    try {
      await handle.use((connection) async {
        final driver = connection.driver;
        if (driver is! SchemaDriver) {
          usageException('Migrations require a schema-capable driver.');
        }
        final schemaDriver = driver as SchemaDriver;
        final exporter = MigrationSqlExporter(schemaDriver);
        final snapshot = await SchemaSnapshot.capture(schemaDriver);

        final appliedIds = exportAll
            ? const <String>{}
            : await _readAppliedIdsIfLedgerExists(
                schemaDriver: schemaDriver,
                ledger: SqlMigrationLedger(
                  driver,
                  tableName: effectiveConfig.migrations.ledgerTable,
                ),
                ledgerTable: effectiveConfig.migrations.ledgerTable,
              );

        final selected = <MigrationDescriptor>[];
        for (final descriptor in migrations) {
          if (!exportAll && appliedIds.contains(descriptor.id.toString())) {
            continue;
          }
          selected.add(descriptor);
          if (!exportAll && limit != null && selected.length >= limit) {
            break;
          }
        }

        if (selected.isEmpty) {
          cliIO.info(
            exportAll
                ? 'No migrations to export.'
                : 'No pending migrations to export.',
          );
          return;
        }

        for (final descriptor in selected) {
          final upPlan = await buildRuntimePlan(
            root: root,
            config: effectiveConfig,
            id: descriptor.id,
            direction: MigrationDirection.up,
            snapshot: snapshot,
            registryPath: registryPath,
          );
          final downPlan = await buildRuntimePlan(
            root: root,
            config: effectiveConfig,
            id: descriptor.id,
            direction: MigrationDirection.down,
            snapshot: snapshot,
            registryPath: registryPath,
          );
          await exporter.exportDescriptor(
            descriptor,
            outputRoot: outputRoot,
            upPlan: upPlan,
            downPlan: downPlan,
          );
        }

        cliIO.success('Exported ${selected.length} migration(s).');
        cliIO.twoColumnDetail(
          'Output',
          p.relative(outputRoot.path, from: root.path),
        );
      });
    } finally {
      await handle.dispose();
    }
  }
}

String _resolveOutPath({
  required Directory root,
  required OrmProjectConfig config,
  String? override,
}) {
  final candidate = (override == null || override.isEmpty)
      ? config.migrations.directory
      : override;
  if (p.isAbsolute(candidate)) return p.normalize(candidate);
  return resolvePath(root, candidate);
}

Future<Set<String>> _readAppliedIdsIfLedgerExists({
  required SchemaDriver schemaDriver,
  required SqlMigrationLedger ledger,
  required String ledgerTable,
}) async {
  final exists = await SchemaInspector(schemaDriver).hasTable(ledgerTable);
  if (!exists) return <String>{};
  try {
    final applied = await ledger.readApplied();
    return applied.map((r) => r.id.toString()).toSet();
  } catch (_) {
    return <String>{};
  }
}
