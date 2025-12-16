import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'package:driver_tests/driver_tests.dart';

void main() {
  ModelRegistry registry = bootstrapOrm();
  group('DataSource Multi-Connection', () {
    late DataSource primary;
    late DataSource secondary;
    late InMemoryQueryExecutor primaryDriver;
    late InMemoryQueryExecutor secondaryDriver;

    setUp(() async {
      // Clear any previous defaults
      DataSource.clearDefault();
      ConnectionManager.instance.clearDefault();

      primaryDriver = InMemoryQueryExecutor();
      secondaryDriver = InMemoryQueryExecutor();

      // Create two separate data sources
      // Note: ActiveUser has 'analytics' in its annotation
      primary = DataSource(
        DataSourceOptions(
          name: 'analytics',
          driver: primaryDriver,
          entities: [ActiveUserOrmDefinition.definition],
          registry: registry,
        ),
      );

      secondary = DataSource(
        DataSourceOptions(
          name: 'secondary',
          driver: secondaryDriver,
          registry: registry,
        ),
      );

      // init() auto-registers and sets first as default
      await primary.init();
      await secondary.init();

      // Clear the auto-set default for tests that need explicit control
      DataSource.clearDefault();
      ConnectionManager.instance.clearDefault();
    });

    tearDown(() async {
      await primary.dispose();
      await secondary.dispose();
      // Unregister connections
      if (ConnectionManager.instance.isRegistered('analytics')) {
        await ConnectionManager.instance.unregister('analytics');
      }
      if (ConnectionManager.instance.isRegistered('secondary')) {
        await ConnectionManager.instance.unregister('secondary');
      }
      ConnectionManager.instance.clearDefault();
      // Clear the static default data source reference
      DataSource.clearDefault();
    });

    test('can query specific data sources directly', () async {
      // Insert into analytics (primary)
      await primary.repo<ActiveUser>().insert(
        const ActiveUser(
          email: 'analytics@example.com',
          name: 'Analytics User',
        ),
      );

      // Insert into secondary
      await secondary.repo<ActiveUser>().insert(
        const ActiveUser(
          email: 'secondary@example.com',
          name: 'Secondary User',
        ),
      );

      // Query each data source
      final primaryUsers = await primary.query<ActiveUser>().get();
      final secondaryUsers = await secondary.query<ActiveUser>().get();

      expect(primaryUsers.length, 1);
      expect(primaryUsers.first.email, 'analytics@example.com');

      expect(secondaryUsers.length, 1);
      expect(secondaryUsers.first.email, 'secondary@example.com');
    });

    test('default data source is used by static helpers', () async {
      primary.setAsDefault();

      // Insert via analytics data source (primary)
      await primary.repo<ActiveUser>().insert(
        const ActiveUser(email: 'default@example.com', name: 'Default User'),
      );

      // Static helper should use 'analytics' connection (which is primary/default)
      final users = await ActiveUsers.query().get();

      expect(users.length, 1);
      expect(users.first.email, 'default@example.com');
    });

    test('static helpers can target named connections', () async {
      primary.setAsDefault();

      // Insert into both databases
      await primary.repo<ActiveUser>().insert(
        const ActiveUser(
          email: 'analytics@example.com',
          name: 'Analytics User',
        ),
      );

      await secondary.repo<ActiveUser>().insert(
        const ActiveUser(
          email: 'secondary@example.com',
          name: 'Secondary User',
        ),
      );

      // Default connection (analytics)
      final analyticsUsers = await ActiveUsers.query().get();
      expect(analyticsUsers.length, 1);
      expect(analyticsUsers.first.email, 'analytics@example.com');

      // Named connection (secondary)
      final secondaryUsers = await ActiveUsers.query('secondary').get();
      expect(secondaryUsers.length, 1);
      expect(secondaryUsers.first.email, 'secondary@example.com');
    });

    test('static find() works with named connections', () async {
      primary.setAsDefault();

      // Insert users with explicit IDs (InMemory driver doesn't auto-generate)
      await primary.repo<ActiveUser>().insert(
        const ActiveUser(
          id: 1,
          email: 'analytics@example.com',
          name: 'Analytics User',
        ),
      );

      await secondary.repo<ActiveUser>().insert(
        const ActiveUser(
          id: 2,
          email: 'secondary@example.com',
          name: 'Secondary User',
        ),
      );

      // Find from default connection (analytics)
      final fromAnalytics = await ActiveUsers.find(1);
      expect(
        fromAnalytics,
        isNotNull,
        reason: 'Should find user1 from analytics connection',
      );
      expect(fromAnalytics?.email, 'analytics@example.com');

      // Find from named connection (secondary)
      final fromSecondary = await ActiveUsers.find(2, connection: 'secondary');
      expect(
        fromSecondary,
        isNotNull,
        reason: 'Should find user2 from secondary connection',
      );
      expect(fromSecondary?.email, 'secondary@example.com');
    });

    test('static findOrFail() works with named connections', () async {
      primary.setAsDefault();

      await primary.repo<ActiveUser>().insert(
        const ActiveUser(id: 10, email: 'test@example.com', name: 'Test User'),
      );

      // Should succeed with default connection
      final found1 = await ActiveUsers.findOrFail(10);
      expect(found1.email, 'test@example.com');

      // Should fail with secondary connection (user not there)
      expect(
        () => ActiveUsers.findOrFail(10, connection: 'secondary'),
        throwsA(isA<StateError>()),
      );
    });

    test('static all() works with named connections', () async {
      primary.setAsDefault();

      await primary.repo<ActiveUser>().insert(
        const ActiveUser(email: 'analytics@example.com', name: 'Analytics'),
      );

      await secondary.repo<ActiveUser>().insertMany([
        const ActiveUser(email: 'secondary1@example.com', name: 'Secondary 1'),
        const ActiveUser(email: 'secondary2@example.com', name: 'Secondary 2'),
      ]);

      // Default connection (analytics)
      final analyticsUsers = await ActiveUsers.query().get();
      expect(analyticsUsers.length, 1);
      // Named connection (secondary)
      final secondaryUsers = await ActiveUsers.all(connection: 'secondary');
      expect(secondaryUsers.length, 2);
    });

    test('can switch default data source', () async {
      primary.setAsDefault();

      await primary.repo<ActiveUser>().insert(
        const ActiveUser(email: 'analytics@example.com', name: 'Analytics'),
      );

      await secondary.repo<ActiveUser>().insert(
        const ActiveUser(email: 'secondary@example.com', name: 'Secondary'),
      );

      // Initially uses analytics (primary)
      var users = await ActiveUsers.query().get();
      expect(users.length, 1);
      expect(users.first.email, 'analytics@example.com');

      // Switch to secondary
      secondary.setAsDefault();

      // Now uses secondary (but ActiveUser still wants 'analytics' connection!)
      // This should fail or we need to override the connection
      users = await ActiveUsers.query('secondary').get();
      expect(users.length, 1);
      expect(users.first.email, 'secondary@example.com');
    });

    test('getDefault() returns current default data source', () async {
      expect(DataSource.getDefault(), isNull);

      primary.setAsDefault();
      expect(DataSource.getDefault(), same(primary));

      secondary.setAsDefault();
      expect(DataSource.getDefault(), same(secondary));
    });

    test('transactions work on specific connections', () async {
      primary.setAsDefault();

      await primary.transaction(() async {
        await primary.repo<ActiveUser>().insert(
          const ActiveUser(email: 'analytics@example.com', name: 'Analytics'),
        );
      });

      await secondary.transaction(() async {
        await secondary.repo<ActiveUser>().insert(
          const ActiveUser(email: 'secondary@example.com', name: 'Secondary'),
        );
      });

      final analyticsUsers = await primary.query<ActiveUser>().get();
      final secondaryUsers = await secondary.query<ActiveUser>().get();

      expect(analyticsUsers.length, 1);
      expect(secondaryUsers.length, 1);
      expect(analyticsUsers.first.email, 'analytics@example.com');
      expect(secondaryUsers.first.email, 'secondary@example.com');
    });
  });
}
