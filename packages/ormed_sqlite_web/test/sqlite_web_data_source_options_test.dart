import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_web/ormed_sqlite_web.dart';
import 'package:test/test.dart';

import 'test_support.dart';

void main() {
  group('SqliteWebDataSourceRegistryExtensions', () {
    test('builds web-backed options', () {
      final registry = ModelRegistry();

      final options = registry.sqliteWebDataSourceOptions(
        name: 'browser',
        database: 'app.sqlite',
        workerUri: 'worker.dart.js',
        wasmUri: 'sqlite3.wasm',
      );

      expect(options.name, equals('browser'));
      expect(options.database, equals('app.sqlite'));
      expect(options.registry, same(registry));
      expect(options.driver, isA<SqliteWebDriverAdapter>());

      final driver = options.driver as SqliteWebDriverAdapter;
      expect(driver.options['database'], equals('app.sqlite'));
      expect(driver.options['workerUri'], equals('worker.dart.js'));
      expect(driver.options['wasmUri'], equals('sqlite3.wasm'));
      expect(driver.options['implementation'], equals('recommended'));
    });

    test('accepts injected transports for tests', () {
      final registry = ModelRegistry();
      final transport = FakeSqliteWebTransport();

      final options = registry.sqliteWebDataSourceOptions(
        name: 'browser',
        database: 'app.sqlite',
        workerUri: 'worker.dart.js',
        wasmUri: 'sqlite3.wasm',
        transport: transport,
      );

      final driver = options.driver as SqliteWebDriverAdapter;
      expect(driver, isA<SqliteWebDriverAdapter>());
    });
  });
}
