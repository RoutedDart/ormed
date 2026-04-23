// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:html';

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

Future<void> main() async {
  final output = querySelector('#output') as PreElement?;
  if (output == null) {
    throw StateError('Missing #output element');
  }

  void log(String line) {
    output.text = '${output.text}$line\n';
    window.console.log(line);
  }

  output.text = '';

  final registry = ModelRegistry();
  final ds = DataSource(
    registry.sqliteFileDataSourceOptions(
      path: 'example.sqlite',
      name: 'web',
      workerUri: 'worker.js',
      wasmUri: 'sqlite3.wasm',
    ),
  );

  try {
    await ds.init();
    log('Driver: ${ds.options.driver.metadata.name}');

    await ds.connection.driver.executeRaw(
      'CREATE TABLE IF NOT EXISTS users ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'email TEXT NOT NULL'
      ')',
    );
    await ds.connection.driver.executeRaw('DELETE FROM users');
    await ds.connection.driver.executeRaw(
      'INSERT INTO users (email) VALUES (?)',
      ['web@example.com'],
    );

    final rows = await ds.connection.driver.queryRaw(
      'SELECT id, email FROM users ORDER BY id',
    );
    log('Rows: ${jsonEncode(rows)}');
  } catch (error, stackTrace) {
    log('Error: $error');
    log('$stackTrace');
    rethrow;
  } finally {
    await ds.dispose();
  }
}
