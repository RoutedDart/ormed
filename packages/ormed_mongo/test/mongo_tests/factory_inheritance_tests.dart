import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../models/models.dart';

void runDriverFactoryInheritanceTests({required DataSource dataSource}) {
  final metadata = dataSource.connection.driver.metadata;
  group('${metadata.name} factory inheritance', () {
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
      await manager.beginTest('factory_inheritance_tests', dataSource);
    });

    tearDown(
      () async => manager.endTest('factory_inheritance_tests', dataSource),
    );

    tearDownAll(() async {
      // Schema cleanup is handled by outer test file
    });

    test('multi-level derived factory includes ancestor fields', () {
      final builder = Model.factory<DerivedForFactory>().withOverrides({
        'baseName': 'root',
        'layerOneNotes': {'notes': true},
        'layerTwoFlag': true,
      });
      final values = builder.values();
      expect(values['baseName'], 'root');
      expect(values['layerOneNotes'], {'notes': true});
      expect(values['layerTwoFlag'], true);
    });

    test('derived models persist with inherited metadata', () async {
      final derived = Model.factory<DerivedForFactory>().withOverrides({
        'baseName': 'root',
        'layerOneNotes': {'notes': true},
        'layerTwoFlag': true,
      }).make(registry: dataSource.context.codecRegistry);

      await dataSource.context.repository<DerivedForFactory>().insert(derived);

      final fetched = await dataSource.context.query<DerivedForFactory>().get();
      expect(fetched, isNotEmpty);
      expect(fetched.first.baseName, 'root');
      expect(fetched.first.layerOneNotes, {'notes': true});
      expect(fetched.first.layerTwoFlag, true);
    });
  });
}
