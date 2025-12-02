import 'dart:io';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/src/schema_state.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late OrmConnection connection;

  setUp(() {
    connection = OrmConnection(
      config: ConnectionConfig(name: 'sqlite-state'),
      driver: InMemoryQueryExecutor(),
      registry: ModelRegistry(),
    );
  });

  tearDown(() async {
    await connection.driver.close();
  });

  test('provider exposes schema state for disk databases', () {
    final tempDir = Directory.systemTemp.createTempSync('sqlite-state');
    final databasePath = p.join(tempDir.path, 'app.db');
    final provider = SqliteSchemaStateProvider(
      DatabaseConfig(driver: 'sqlite', options: {'path': databasePath}),
    );

    final state = provider.createSchemaState(
      connection: connection,
      ledgerTable: 'orm_migrations',
    );

    expect(state, isNotNull);
    expect(state!.canDump, isTrue);
    expect(state.canLoad, isTrue);

    tempDir.deleteSync(recursive: true);
  });

  test('provider disables dumping for in-memory databases', () {
    final provider = SqliteSchemaStateProvider(
      DatabaseConfig(driver: 'sqlite', options: {'database': ':memory:'}),
    );

    final state = provider.createSchemaState(
      connection: connection,
      ledgerTable: 'orm_migrations',
    );

    expect(state, isNotNull);
    expect(state!.canDump, isFalse);
    expect(state.canLoad, isFalse);
  });
}
