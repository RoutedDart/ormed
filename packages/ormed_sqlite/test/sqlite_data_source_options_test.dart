import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteDataSourceRegistryExtensions', () {
    test('builds file-backed options', () {
      final registry = ModelRegistry();

      final options = registry.sqliteFileDataSourceOptions(
        path: 'database/app.sqlite',
        name: 'primary',
        logging: true,
      );

      expect(options.name, equals('primary'));
      expect(options.registry, same(registry));
      expect(options.database, equals('database/app.sqlite'));
      expect(options.driver, isA<SqliteDriverAdapter>());
      expect(
        (options.driver as SqliteDriverAdapter).options['path'],
        equals('database/app.sqlite'),
      );
    });

    test('builds in-memory data source', () {
      final registry = ModelRegistry();

      final dataSource = registry.sqliteInMemoryDataSource(name: 'tests');

      expect(dataSource.options.name, equals('tests'));
      expect(dataSource.options.database, equals(':memory:'));
      expect(dataSource.options.registry, same(registry));
      expect(dataSource.options.driver, isA<SqliteDriverAdapter>());
    });
  });
}
