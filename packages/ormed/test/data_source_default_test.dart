import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'package:driver_tests/driver_tests.dart';

void main() {
  ModelRegistry registry = buildOrmRegistry();
  group('DataSource setDefaultDataSource', () {
    late InMemoryQueryExecutor driver;
    late DataSource dataSource;

    setUp(() {
      driver = InMemoryQueryExecutor();
    });

    tearDown(() async {
      if (dataSource.isInitialized) {
        await dataSource.dispose();
      }
      // Clean up both possible connection names
      if (ConnectionManager.instance.isRegistered('default')) {
        await ConnectionManager.instance.unregister('default');
      }
      if (ConnectionManager.instance.isRegistered('analytics')) {
        await ConnectionManager.instance.unregister('analytics');
      }
      // Clear default connection
      ConnectionManager.instance.clearDefault();
    });

    test('registers data source as default connection', () async {
      dataSource = DataSource(
        DataSourceOptions(name: 'default', driver: driver, registry: registry),
      );
      await dataSource.init();

      ConnectionManager.instance.registerDataSource(dataSource);

      final conn = ConnectionManager.instance.connection('default');
      expect(conn, isNotNull);
      expect(conn.config.name, 'default');
    });

    test('throws if DataSource name is not "default"', () async {
      dataSource = DataSource(
        DataSourceOptions(name: 'other', driver: driver, registry: registry),
      );
      await dataSource.init();

      expect(
        () => ConnectionManager.instance.setDefaultDataSource(dataSource),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('enables static helpers to work', () async {
      // ActiveUser specifies connection: 'analytics', so register under that name
      dataSource = DataSource(
        DataSourceOptions(
          name: 'analytics',
          driver: driver,
          registry: registry,
        ),
      );
      // init() auto-registers and sets as default (first DataSource)
      await dataSource.init();

      // Insert test data
      await dataSource.repo<ActiveUser>().insert(
        const ActiveUser(id: 1, name: 'Test User', email: 'test@example.com'),
      );

      // Use static helpers - they will use the 'analytics' connection (default)
      final users = await ActiveUsers.query().get();
      expect(users, hasLength(1));
      expect(users.first.name, 'Test User');

      final user = await ActiveUsers.find(1);
      expect(user, isNotNull);
      expect(user!.email, 'test@example.com');
    });
  });
}
