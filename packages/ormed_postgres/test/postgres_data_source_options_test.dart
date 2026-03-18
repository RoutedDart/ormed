import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';

void main() {
  group('PostgresDataSourceRegistryExtensions', () {
    test('builds options from explicit details', () {
      final registry = ModelRegistry();
      final options = registry.postgresDataSourceOptions(
        host: 'db.local',
        port: 5433,
        database: 'app_db',
        username: 'app_user',
        password: 'secret',
        sslmode: 'require',
      );

      expect(options.registry, same(registry));
      expect(options.database, equals('app_db'));
      expect(options.driver, isA<PostgresDriverAdapter>());
      expect(options.driver.metadata.name, equals('postgres'));
    });

    test('builds options from env with URL', () {
      final registry = ModelRegistry();
      final options = registry.postgresDataSourceOptionsFromEnv(
        environment: const {
          'DATABASE_URL': 'postgres://user:pass@localhost:5432/app',
          'DB_SSLMODE': 'require',
        },
      );

      expect(options.driver, isA<PostgresDriverAdapter>());
      expect(options.driver.metadata.name, equals('postgres'));
    });
  });
}
