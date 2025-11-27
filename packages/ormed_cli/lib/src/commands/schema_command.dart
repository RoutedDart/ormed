import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:path/path.dart' as p;

import '../config.dart';
import 'shared.dart';

class SchemaDescribeCommand extends Command<void> {
  SchemaDescribeCommand() {
    argParser.addOption(
      'config',
      abbr: 'c',
      help: 'Path to orm.yaml (defaults to project root).',
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
    final context = resolveOrmProject(configPath: configArg);
    final config = loadOrmProjectConfig(context.configFile);
    final handle = await createConnection(context.root, config);
    try {
      await handle.use((connection) async {
        final driver = connection.driver;
        final metadata = await schemaMetadata(driver);
        final path = resolvePath(context.root, config.migrations.schemaDump);
        final builder = StringBuffer();
        for (final table in metadata) {
          final name = table['name'];
          stdout.writeln('Collection: $name');
          builder.writeln('Collection: $name');
          if (table['indexCount'] != null) {
            stdout.writeln('  Indexes: ${table['indexCount']}');
            builder.writeln('  Indexes: ${table['indexCount']}');
          }
          if (table['validator'] != null) {
            stdout.writeln('  Validator: ${table['validator']}');
            builder.writeln('  Validator: ${table['validator']}');
          }
        }
        final schemaFile = File(path);
        final state = resolveSchemaState(
          driver,
          connection,
          config.migrations.ledgerTable,
        );
        if (asJson) {
          final payload = const JsonEncoder.withIndent('  ').convert(metadata);
          stdout.writeln(payload);
          if (state?.canDump == true) {
            await state!.dump(schemaFile);
            stdout.writeln(
              'Updated schema dump at ${p.relative(schemaFile.path, from: context.root.path)}',
            );
          } else {
            _writeSchemaDump(context.root, path, payload);
          }
        } else {
          if (state?.canDump == true) {
            await state!.dump(schemaFile);
            stdout.writeln(
              'Updated schema dump at ${p.relative(schemaFile.path, from: context.root.path)}',
            );
          } else {
            _writeSchemaDump(context.root, path, builder.toString());
          }
        }
      });
    } finally {
      await handle.dispose();
    }
  }
}

void _writeSchemaDump(Directory root, String path, String contents) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
  stdout.writeln(
    'Updated schema dump at ${p.relative(file.path, from: root.path)}',
  );
}

Future<List<Map<String, Object?>>> schemaMetadata(DriverAdapter driver) async {
  if (driver is MongoDriverAdapter) {
    final inspector = MongoSchemaInspector(driver);
    final tables = await inspector.listTables();
    final results = <Map<String, Object?>>[];
    for (final table in tables) {
      final indexes = await inspector.listIndexes(table.name);
      final tableMeta = <String, Object?>{
        'name': table.name,
        'schema': table.schema,
        'type': table.type,
        'validator': table.comment,
        'indexCount': indexes.length,
      };
      results.add(tableMeta);
    }
    return results;
  }
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
