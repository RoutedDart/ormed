library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:ormed/ormed.dart';

import 'src/commands/shared.dart';

export 'src/commands/shared.dart'
    show OrmProjectContext, resolveOrmProject, createConnection;
export 'src/config.dart'
    show
        OrmProjectConfig,
        DriverConfig,
        MigrationSection,
        SeedSection,
        loadOrmProjectConfig;

Future<void> runSeedRegistryOnConnection(
  OrmConnection connection,
  List<SeederRegistration> seeds, {
  List<String>? names,
  bool pretend = false,
  void Function(OrmConnection connection)? beforeRun,
  void Function(String message)? log,
}) async {
  if (seeds.isEmpty) {
    throw StateError('No seeders registered.');
  }
  beforeRun?.call(connection);
  final lookup = {for (final entry in seeds) entry.name: entry.factory};
  final queue = (names == null || names.isEmpty)
      ? <String>[seeds.first.name]
      : names;
  final logger = log ?? (String message) => stdout.writeln(message);

  for (final target in queue) {
    final factory = lookup[target];
    if (factory == null) {
      throw StateError('Seeder $target is not registered.');
    }
    final seeder = factory(connection);

    if (pretend) {
      // Use core's pretend functionality
      final statements = await connection.pretend(
        () async => await seeder.run(),
      );
      for (final entry in statements) {
        logger('[pretend] ${formatPretendEntry(entry)}');
      }
    } else {
      // Use core's seeding functionality
      await seeder.run();
    }
  }
}

Future<void> runSeedRegistryEntrypoint({
  required List<String> args,
  required List<SeederRegistration> seeds,
  void Function(OrmConnection connection)? beforeRun,
}) async {
  if (seeds.isEmpty) {
    stdout.writeln(jsonEncode(const []));
    return;
  }

  final pretend = args.contains('--pretend');
  final configIndex = args.indexOf('--config');
  final configArg = configIndex == -1 ? null : args[configIndex + 1];
  final databaseIndex = args.indexOf('--database');
  final databaseArg = databaseIndex == -1 ? null : args[databaseIndex + 1];
  final connectionArg = _extractOptionValue(args, '--connection');
  final requestedClasses = _extractRequestedClasses(args);

  final project = resolveOrmProject(configPath: configArg);
  var config = loadOrmProjectConfig(project.configFile);
  if (connectionArg != null && connectionArg.trim().isNotEmpty) {
    config = config.withConnection(connectionArg);
  }
  final effectiveConfig = databaseArg == null
      ? config
      : config.updateActiveConnection(
          driver: config.driver.copyWith(
            options: {...config.driver.options, 'database': databaseArg},
          ),
        );
  final handle = await createConnection(project.root, effectiveConfig);
  try {
    await handle.use((connection) async {
      await runSeedRegistryOnConnection(
        connection,
        seeds,
        names: requestedClasses.isEmpty
            ? (effectiveConfig.seeds?.defaultClass != null
                  ? <String>[effectiveConfig.seeds!.defaultClass]
                  : <String>[seeds.first.name])
            : requestedClasses,
        pretend: pretend,
        beforeRun: beforeRun,
      );
    });
  } finally {
    await handle.dispose();
  }
}

List<String> _extractRequestedClasses(List<String> args) {
  final classes = <String>[];
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--run') {
      if (i + 1 < args.length) {
        classes.addAll(
          args[i + 1]
              .split(',')
              .map((raw) => raw.trim())
              .where((value) => value.isNotEmpty),
        );
        i++;
      }
    } else if (arg.startsWith('--run=')) {
      final value = arg.substring('--run='.length);
      classes.addAll(
        value
            .split(',')
            .map((raw) => raw.trim())
            .where((entry) => entry.isNotEmpty),
      );
    }
  }
  return classes;
}

String? _extractOptionValue(List<String> args, String option) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == option) {
      if (i + 1 < args.length) {
        return args[i + 1];
      }
      return null;
    }
    if (arg.startsWith('$option=')) {
      return arg.substring(option.length + 1);
    }
  }
  return null;
}

@visibleForTesting
String formatPretendEntry(QueryLogEntry entry) => _formatPretendEntry(entry);

String _formatPretendEntry(QueryLogEntry entry) {
  final normalized = entry.preview.normalized;
  final logEntry = <String, Object?>{
    'type': normalized.type,
    'command': normalized.command,
    if (normalized.arguments.isNotEmpty) 'arguments': normalized.arguments,
    if (normalized.parameters.isNotEmpty) 'parameters': normalized.parameters,
    if (normalized.metadata.isNotEmpty) 'metadata': normalized.metadata,
    'duration_ms': entry.duration.inMicroseconds / 1000,
    'success': entry.success,
    if (entry.model != null) 'model': entry.model,
    if (entry.table != null) 'table': entry.table,
    if (entry.rowCount != null) 'row_count': entry.rowCount,
  };
  return const JsonEncoder.withIndent('  ').convert(logEntry);
}
