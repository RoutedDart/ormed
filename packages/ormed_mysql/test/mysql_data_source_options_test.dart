import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';

void main() {
  group('MySqlDataSourceRegistryExtensions', () {
    test('builds mysql options from explicit details', () {
      final registry = ModelRegistry();
      final options = registry.mySqlDataSourceOptions(
        host: 'db.local',
        port: 3307,
        database: 'app_db',
        username: 'app_user',
        password: 'secret',
        secure: true,
      );

      expect(options.registry, same(registry));
      expect(options.database, equals('app_db'));
      expect(options.driver, isA<MySqlDriverAdapter>());
      expect(options.driver.metadata.name, equals('mysql'));
    });

    test('builds mysql options from environment map', () {
      final registry = ModelRegistry();
      final options = registry.mySqlDataSourceOptionsFromEnv(
        environment: const {
          'DB_HOST': 'env-host',
          'DB_PORT': '3308',
          'DB_NAME': 'env_db',
          'DB_USER': 'env_user',
          'DB_PASSWORD': 'env_secret',
          'DB_SSLMODE': 'require',
        },
      );

      expect(options.database, equals('env_db'));
      expect(options.driver, isA<MySqlDriverAdapter>());
      expect(options.driver.metadata.name, equals('mysql'));
    });

    test('builds mariadb data source', () {
      final registry = ModelRegistry();
      final dataSource = registry.mariaDbDataSource(database: 'maria_db');

      expect(dataSource.options.database, equals('maria_db'));
      expect(dataSource.options.driver, isA<MySqlDriverAdapter>());
      expect(dataSource.options.driver.metadata.name, equals('mariadb'));
    });
  });
}
