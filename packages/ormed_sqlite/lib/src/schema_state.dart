import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ormed/ormed.dart';

class SqliteSchemaState implements SchemaState {
  SqliteSchemaState({required this.database, required this.ledgerTable});

  final String database;
  final String ledgerTable;

  bool get _isMemory {
    final lower = database.toLowerCase();
    return lower == ':memory:' ||
        lower.startsWith('file::memory:') ||
        lower.contains('mode=memory');
  }

  @override
  bool get canDump => !_isMemory;

  @override
  bool get canLoad => !_isMemory;

  @override
  Future<void> dump(File path) async {
    if (!canDump) {
      throw StateError('In-memory sqlite databases cannot dump schema.');
    }
    final schema = await _runSqlite([database, '.schema --indent']);
    final filtered = schema
        .replaceAll(RegExp(r"CREATE TABLE sqlite_[^;]+;\s*", dotAll: true), '')
        .trim();
    final buffer = StringBuffer(filtered)..writeln();
    final migrations = await _runSqlite([database, '.dump "$ledgerTable"']);
    final lines = migrations
        .split(RegExp(r'\r?\n'))
        .where(
          (line) =>
              line.trim().isNotEmpty &&
              (line.trim().startsWith('--') ||
                  line.trim().toUpperCase().startsWith('INSERT')),
        )
        .join('\n');
    if (lines.isNotEmpty) {
      buffer.writeln(lines);
    }
    await path.writeAsString(buffer.toString());
  }

  @override
  Future<void> load(File path) async {
    if (!canLoad) {
      throw StateError('In-memory sqlite databases cannot load schema dumps.');
    }
    final process = await Process.start('sqlite3', [database]);
    await path.openRead().pipe(process.stdin);
    final error = await process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw StateError('sqlite3 failed ($exitCode): ${error.trim()}');
    }
  }

  Future<String> _runSqlite(List<String> args) async {
    final process = await Process.start('sqlite3', args);
    final output = await process.stdout.transform(utf8.decoder).join();
    final error = await process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw StateError('sqlite3 failed ($exitCode): ${error.trim()}');
    }
    return output;
  }
}

class SqliteSchemaStateProvider implements SchemaStateProvider {
  SqliteSchemaStateProvider(this.config);

  final DatabaseConfig config;

  @override
  SchemaState? createSchemaState({
    required OrmConnection connection,
    required String ledgerTable,
  }) {
    final path = config.options['path'] ?? config.options['database'];
    if (path is! String || path.isEmpty) {
      return null;
    }
    return SqliteSchemaState(database: path, ledgerTable: ledgerTable);
  }
}
