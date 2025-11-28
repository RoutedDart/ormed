import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ormed/ormed.dart';

class PostgresSchemaState implements SchemaState {
  PostgresSchemaState({
    required this.config,
    required this.connection,
    required this.ledgerTable,
  });

  final DatabaseConfig config;
  final OrmConnection connection;
  final String ledgerTable;

  String get _database => _requireOption('database');
  String get _username => _stringOption(
    key: 'username',
    fallbackKeys: const ['user'],
    defaultValue: 'postgres',
  );
  String? get _password => _stringOption(key: 'password');
  String get _host => _stringOption(
    key: 'host',
    fallbackKeys: const ['server'],
    defaultValue: '127.0.0.1',
  );
  String? get _port => _stringOption(
    key: 'port',
    fallbackKeys: const ['serverport'],
    defaultValue: '5432',
  );

  @override
  bool get canDump => true;

  @override
  bool get canLoad => true;

  @override
  Future<void> dump(File path) async {
    await _runDump([
      'pg_dump',
      '--no-owner',
      '--no-acl',
      '--schema-only',
      ..._connectionArgs,
    ], path);
    await _runDump(
      [
        'pg_dump',
        '--no-owner',
        '--no-acl',
        '--data-only',
        '-t',
        ledgerTable,
        ..._connectionArgs,
      ],
      path,
      append: true,
    );
  }

  @override
  Future<void> load(File path) async {
    final process = await Process.start('psql', [
      ..._connectionArgs,
      '--file=${path.path}',
    ], environment: _env);
    final stderrText = await process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw StateError('psql failed ($exitCode): ${stderrText.trim()}');
    }
  }

  Future<void> _runDump(
    List<String> command,
    File path, {
    bool append = false,
  }) async {
    final process = await Process.start(
      command.first,
      command.sublist(1),
      environment: _env,
    );
    final sink = path.openWrite(
      mode: append ? FileMode.append : FileMode.write,
    );
    await process.stdout.pipe(sink);
    final stderrText = await process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    await sink.close();
    if (exitCode != 0) {
      throw StateError('pg_dump failed ($exitCode): ${stderrText.trim()}');
    }
  }

  List<String> get _connectionArgs {
    final args = <String>[
      '--host=$_host',
      '--username=$_username',
      '--dbname=$_database',
    ];
    if (_port != null && _port!.isNotEmpty) {
      args.add('--port=$_port');
    }
    return args;
  }

  Map<String, String> get _env => _password != null && _password!.isNotEmpty
      ? {'PGPASSWORD': _password!}
      : const {};

  String _stringOption({
    required String key,
    List<String> fallbackKeys = const [],
    String defaultValue = '',
  }) {
    final value = config.options[key]?.toString();
    if (value != null && value.isNotEmpty) {
      return value;
    }

    //cycle through fallbacks until a non-empty value is found
    for (final fallbackKey in fallbackKeys) {
      final value = config.options[fallbackKey]?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return defaultValue;
  }

  String _requireOption(String key) {
    final value = _stringOption(key: key);
    if (value.isEmpty) {
      throw StateError('Missing $key option for Postgres schema state.');
    }
    return value;
  }
}

class PostgresSchemaStateProvider implements SchemaStateProvider {
  PostgresSchemaStateProvider(this.config);

  final DatabaseConfig config;

  @override
  SchemaState? createSchemaState({
    required OrmConnection connection,
    required String ledgerTable,
  }) {
    return PostgresSchemaState(
      config: config,
      connection: connection,
      ledgerTable: ledgerTable,
    );
  }
}
