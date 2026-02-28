import 'dart:convert';
import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:ormed/ormed.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import '../base/shared.dart';

class SchemaDumpCommand extends Command<void> {
  SchemaDumpCommand() {
    argParser.addOption(
      'config',
      abbr: 'c',
      help:
          'Path to ormed.yaml (optional; convention defaults are used when omitted).',
    );
    argParser.addOption('database', help: 'The database connection to use.');
    argParser.addOption(
      'path',
      help: 'Custom output path for the schema dump.',
    );
    argParser.addFlag(
      'prune',
      negatable: false,
      help: 'Delete all existing migration files after dumping the schema.',
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Skip the production confirmation prompt.',
    );
  }

  @override
  String get name => 'schema:dump';

  @override
  String get description =>
      'Dump the current database schema to a SQL file for faster test database creation.';

  @override
  Future<void> run() async {
    final configArg = argResults?['config'] as String?;
    final databaseOverride = argResults?['database'] as String?;
    final pathOverride = argResults?['path'] as String?;
    final prune = argResults?['prune'] == true;
    final force = argResults?['force'] == true;

    final resolved = resolveOrmProjectConfig(configPath: configArg);
    final context = OrmProjectContext(
      root: resolved.root,
      configFile: resolved.configFile,
    );
    final config = resolved.config;
    if (!resolved.hasConfigFile) {
      printConfigFallbackNotice();
    }

    if (prune && !confirmToProceed(force: force, action: 'prune migrations')) {
      cliIO.warn('Schema dump cancelled.');
      return;
    }

    final handle = await createConnection(
      context.root,
      config,
      targetConnection: databaseOverride,
    );

    try {
      await handle.use((connection) async {
        final driver = connection.driver;

        if (driver is! SchemaDriver) {
          usageException(
            'Schema dump is not supported for ${driver.runtimeType}',
          );
        }

        final state = resolveSchemaState(
          driver,
          connection,
          config.migrations.ledgerTable,
        );

        if (state == null || !state.canDump) {
          usageException(
            'Schema dump is not supported for this database driver.',
          );
        }

        // Determine output path
        final String outputPath;
        if (pathOverride != null) {
          outputPath = pathOverride;
        } else {
          // Use connection name for the schema file (like Laravel)
          final connectionName = databaseOverride ?? config.connectionName;
          final schemaDir = resolvePath(
            context.root,
            config.migrations.schemaDump,
          );
          final schemaDirObj = Directory(schemaDir);
          schemaDirObj.createSync(recursive: true);
          outputPath = p.join(schemaDir, '$connectionName-schema.sql');
        }

        final schemaFile = File(outputPath);

        // Dump the schema
        await state.dump(schemaFile);

        final relativePath = p.relative(
          schemaFile.path,
          from: context.root.path,
        );
        cliIO.success('Database schema dumped to: $relativePath');

        if (prune) {
          await _pruneMigrations(context, config);
        }
      });
    } finally {
      await handle.dispose();
    }
  }

  Future<void> _pruneMigrations(
    OrmProjectContext context,
    OrmProjectConfig config,
  ) async {
    final migrationsPath = resolvePath(
      context.root,
      config.migrations.directory,
    );
    final migrationsDir = Directory(migrationsPath);

    if (!migrationsDir.existsSync()) {
      cliIO.warn('No migrations directory found.');
      return;
    }

    int deletedCount = 0;
    await for (final entity in migrationsDir.list()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        entity.deleteSync();
        deletedCount++;
      }
    }

    cliIO.success('Pruned $deletedCount migration file(s).');
  }
}

class SchemaDescribeCommand extends Command<void> {
  SchemaDescribeCommand() {
    argParser.addOption(
      'config',
      abbr: 'c',
      help:
          'Path to ormed.yaml (optional; convention defaults are used when omitted).',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Render the schema output as JSON.',
    );
  }

  @override
  String get name => 'schema:describe';

  @override
  String get description => 'Describe the current database schema.';

  @override
  Future<void> run() async {
    final configArg = argResults?['config'] as String?;
    final asJson = argResults?['json'] == true;
    final resolved = resolveOrmProjectConfig(configPath: configArg);
    final context = OrmProjectContext(
      root: resolved.root,
      configFile: resolved.configFile,
    );
    final config = resolved.config;
    if (!resolved.hasConfigFile) {
      printConfigFallbackNotice();
    }
    final handle = await createConnection(context.root, config);
    try {
      await handle.use((connection) async {
        final driver = connection.driver;
        final metadata = await schemaMetadata(driver);

        if (asJson) {
          final payload = const JsonEncoder.withIndent('  ').convert(metadata);
          cliIO.writeln(payload);
        } else {
          if (metadata.isEmpty) {
            cliIO.info('No tables found in database.');
          } else {
            cliIO.title('Database Schema');
            for (final table in metadata) {
              final name = table['name'];
              cliIO.writeln(cliIO.style.bold().render('Table: $name'));
              if (table['indexCount'] != null) {
                cliIO.twoColumnDetail('  Indexes', '${table['indexCount']}');
              }
              if (table['validator'] != null) {
                cliIO.twoColumnDetail('  Validator', '${table['validator']}');
              }
            }
          }
        }
      });
    } finally {
      await handle.dispose();
    }
  }
}

Future<List<Map<String, Object?>>> schemaMetadata(DriverAdapter driver) async {
  if (driver is SchemaDriver) {
    final schemaDriver = driver as SchemaDriver;
    final inspector = SchemaInspector(schemaDriver);
    final tables = await inspector.tableListing(schemaQualified: true);
    return tables
        .map((name) => <String, Object?>{'name': name})
        .toList(growable: false);
  }
  return const [];
}
