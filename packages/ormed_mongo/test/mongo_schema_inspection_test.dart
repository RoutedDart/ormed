import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'shared.dart';
import 'package:ormed_mongo/ormed_mongo.dart';

void main() {
  late DataSource dataSource;
  late MongoDriverAdapter driverAdapter;

  setUpAll(() async {
    await waitForMongoReady();
    await clearDatabase();
    driverAdapter = createAdapter();
    registerDriverTestFactories();
    // Create custom codecs map
    final customCodecs = <String, ValueCodec<dynamic>>{
      'PostgresPayloadCodec': const PostgresPayloadCodec(),
      'SqlitePayloadCodec': const SqlitePayloadCodec(),
      'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
      'JsonMapCodec': const JsonMapCodec(),
    };

    dataSource = DataSource(DataSourceOptions(
      driver: driverAdapter,
      entities: generatedOrmModelDefinitions,
      codecs: customCodecs,
    ));
    await dataSource.init();
    await seedGraph(dataSource);
  });

  tearDownAll(() async => await dataSource.dispose());

  test('lists collections via inspector', () async {
    final tables = await driverAdapter.listTables();
    expect(tables.map((t) => t.name), contains('posts'));
    expect(tables.map((t) => t.name), contains('users'));
  });

  test('lists indexes for a collection', () async {
    final indexes = await driverAdapter.listIndexes('posts');
    expect(indexes.any((index) => index.columns.contains('_id')), isTrue);
  });

  test('exposes field metadata for collections', () async {
    final tables = await driverAdapter.listTables();
    final posts = tables.firstWhere((table) => table.name == 'posts');
    expect(posts.fields.any((field) => field.name == 'author_id'), isTrue);
    expect(
      posts.fields.firstWhere((field) => field.name == 'author_id').nullable,
      isFalse,
    );
  });
}
