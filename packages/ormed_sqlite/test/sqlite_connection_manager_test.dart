import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('registerSqliteOrmConnection', () {
    late ModelRegistry registry;

    setUp(() {
      registry = ModelRegistry()..registerAll([AuthorOrmDefinition.definition]);
    });

    test('registers connection with custom manager', () async {
      final manager = ConnectionManager();
      final handle = registerSqliteOrmConnection(
        name: 'sqlite.testing',
        database: const DatabaseConfig(
          driver: 'sqlite',
          options: {'memory': true},
        ),
        registry: registry,
        manager: manager,
        singleton: false,
      );

      await manager.use('sqlite.testing', (connection) async {
        final adapter = connection.driver as SqliteDriverAdapter;
        await adapter.executeRaw(
          'CREATE TABLE authors (id INTEGER PRIMARY KEY, name TEXT, active INTEGER)',
        );
        await adapter.executeRaw(
          "INSERT INTO authors (id, name, active) VALUES (1, 'Alice', 1)",
        );

        final authors = await connection.query<Author>().get();
        expect(authors.map((a) => a.name), ['Alice']);
      });
      await handle.dispose();
    });
  });
}
