import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

void main() {
  test('insertMany should insert all records', () async {
    registerDriverTestFactories();

    // Create custom codecs map
    final customCodecs = <String, ValueCodec<dynamic>>{
      'PostgresPayloadCodec': const PostgresPayloadCodec(),
      'SqlitePayloadCodec': const SqlitePayloadCodec(),
      'JsonMapCodec': const JsonMapCodec(),
    };

    // Create codec registry for the adapter
    final codecRegistry = ValueCodecRegistry.standard();
    for (final entry in customCodecs.entries) {
      codecRegistry.registerCodec(key: entry.key, codec: entry.value);
    }

    // Create adapter with the codec registry
    final driverAdapter = SqliteDriverAdapter.inMemory(codecRegistry: codecRegistry);

    final dataSource = DataSource(
      DataSourceOptions(
        name: 'default',
        driver: driverAdapter,
        entities: generatedOrmModelDefinitions,
        codecs: customCodecs,
      ),
    );

    await dataSource.init();

    // Setup test schema
    await resetDriverTestSchema(driverAdapter, schema: null);
    
    try {
      // Try to insert 3 authors
      await dataSource.repo<Author>().insertMany([
        const Author(id: 1, name: 'Alice'),
        const Author(id: 2, name: 'Bob'),
        const Author(id: 3, name: 'Charlie'),
      ]);
      
      // Query to verify all were inserted
      final authors = await dataSource.context.query<Author>().get();
      
      print('Inserted ${authors.length} authors');
      for (final author in authors) {
        print('  - ${author.id}: ${author.name}');
      }
      
      expect(authors.length, equals(3));
      expect(authors.map((a) => a.name).toList(), containsAll(['Alice', 'Bob', 'Charlie']));
    } finally {
      await dataSource.dispose();
    }
  });
}
