import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ormed/ormed.dart';

class MySqlSchemaState implements SchemaState {
  MySqlSchemaState({
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
    defaultValue: 'root',
  );
  String? get _password => _stringOption(key: 'password');
  String? get _host => _stringOption(
    key: 'host',
    fallbackKeys: const ['server'],
    defaultValue: '127.0.0.1',
  );
  String? get _port => _stringOption(
    key: 'port',
    fallbackKeys: const ['serverport'],
    defaultValue: '3306',
  );
  String? get _socket => _stringOption(key: 'unix_socket');
  bool get _isMaria => config.driver.contains('maria');

  @override
  bool get canDump => true;

  @override
  bool get canLoad => true;

  @override
  Future<void> dump(File path) async {
    await _dumpToFile(
      ['mysqldump', ..._baseArgs, _database],
      path,
      append: false,
    );
    await _dumpToFile(
      [
        'mysqldump',
        ..._baseArgs,
        '--no-create-info',
        '--skip-extended-insert',
        '--skip-routines',
        _database,
        ledgerTable,
      ],
      path,
      append: true,
    );
  }

  @override
  Future<void> load(File path) async {
    final process = await Process.start('mysql', [
      ..._authArgs,
      if (_host != null) '--host=$_host',
      if (_port != null) '--port=$_port',
      _database,
    ], environment: _env);
    await path.openRead().pipe(process.stdin);
    final stderrText = await process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw StateError('mysql load failed ($exitCode): ${stderrText.trim()}');
    }
  }

  Future<void> _dumpToFile(
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
      throw StateError('mysqldump failed ($exitCode): ${stderrText.trim()}');
    }
  }

  List<String> get _authArgs {
    final args = <String>[];
    if (_host != null) args.add('--host=$_host');
    if (_port != null) args.add('--port=$_port');
    args
      ..add('--user=$_username')
      ..add('--password=${_password ?? ''}');
    if (_socket != null) {
      args.add('--socket=$_socket');
    }
    return args;
  }

  List<String> get _baseArgs => [
    ..._authArgs,
    '--skip-comments',
    '--skip-add-locks',
    '--skip-set-charset',
    '--tz-utc',
    '--column-statistics=0',
    if (!_isMaria) '--set-gtid-purged=OFF',
  ];

  Map<String, String> get _env {
    final env = <String, String>{};
    if (_password != null && _password!.isNotEmpty) {
      env['MYSQL_PWD'] = _password!;
    }
    return env;
  }

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
      throw StateError('Missing $key option for MySQL schema state.');
    }
    return value;
  }
}

class MySqlSchemaStateProvider implements SchemaStateProvider {
  MySqlSchemaStateProvider(this.config);

  final DatabaseConfig config;

  @override
  SchemaState? createSchemaState({
    required OrmConnection connection,
    required String ledgerTable,
  }) {
    return MySqlSchemaState(
      config: config,
      connection: connection,
      ledgerTable: ledgerTable,
    );
  }
}
