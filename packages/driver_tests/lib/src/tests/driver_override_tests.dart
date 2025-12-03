import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';
import '../support/driver_schema.dart';

void runDriverOverrideTests({required DataSource dataSource}) {
  group('${dataSource.connection.driver.metadata.name} driver overrides', () {
    late TestDatabaseManager manager;

    setUpAll(() async {
      await dataSource.init();
      manager = TestDatabaseManager(
        baseDataSource: dataSource,
        migrationDescriptors: driverTestMigrationEntries
            .map(
              (e) => MigrationDescriptor.fromMigration(
                id: e.id,
                migration: e.migration,
              ),
            )
            .toList(),
        strategy: DatabaseIsolationStrategy.truncate,
      );
      await manager.initialize();
    });

    setUp(() async {
      await manager.beginTest('driver_override_tests', dataSource);
    });

    tearDown(() async => manager.endTest('driver_override_tests', dataSource));

    tearDownAll(() async {
      // Schema cleanup is handled by outer test file
    });

    test(
      'repository encodes payload using driver-specific codec',
      () async {
        final repo = dataSource.context.repository<DriverOverrideEntry>();
        const entry = DriverOverrideEntry(id: 1, payload: {'mode': 'dark'});
        await repo.insert(entry);

        final rows = await dataSource.connection.driver.queryRaw(
          'SELECT payload FROM driver_override_entries WHERE id = 1',
        );
        final value = rows.single['payload'];
        final driverName = dataSource.connection.driver.metadata.name
            .toLowerCase();
        if (driverName.contains('sqlite')) {
          expect(value, isA<String>());
          expect(value, equals(jsonEncode(entry.payload)));
        } else if (driverName.contains('postgres')) {
          expect(value, isA<Map>());
          final decoded = (value as Map).cast<String, Object?>();
          expect(decoded['encoded_by'], equals('postgres'));
        } else {
          expect(value, isA<Map>());
          final decoded = (value as Map).cast<String, Object?>();
          expect(decoded['mode'], equals('dark'));
        }

        final fetched = await dataSource.context
            .query<DriverOverrideEntry>()
            .whereEquals('id', 1)
            .firstOrFail();
        expect(fetched.payload['mode'], equals('dark'));
      },
      skip: !dataSource.connection.driver.metadata.supportsCapability(
        DriverCapability.rawSQL,
      ),
    );
  });
}
