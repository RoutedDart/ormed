import 'dart:io';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';

void main() {
  group('Postgres-specific joins', () {
    late DataSource dataSource;
    late PostgresDriverAdapter driverAdapter;

    setUpAll(() async {
      final url =
          Platform.environment['POSTGRES_URL'] ??
          'postgres://postgres:postgres@localhost:6543/orm_test';

      // Create custom codecs map
      final customCodecs = <String, ValueCodec<dynamic>>{
        'PostgresPayloadCodec': const PostgresPayloadCodec(),
        'SqlitePayloadCodec': const SqlitePayloadCodec(),
        'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
        'JsonMapCodec': const JsonMapCodec(),
      };

      // Create codec registry for the adapter
      final codecRegistry = ValueCodecRegistry.standard();
      for (final entry in customCodecs.entries) {
        codecRegistry.registerCodec(key: entry.key, codec: entry.value);
      }

      driverAdapter = PostgresDriverAdapter.custom(
        config: DatabaseConfig(driver: 'postgres', options: {'url': url}),
        codecRegistry: codecRegistry,
      );

      dataSource = DataSource(DataSourceOptions(
        driver: driverAdapter,
        entities: generatedOrmModelDefinitions,
        codecs: customCodecs,
      ));

      await dataSource.init();
      registerDriverTestFactories();
      await resetDriverTestSchema(driverAdapter, schema: null);
    });

    tearDownAll(() async {
      await dropDriverTestSchema(driverAdapter, schema: null);
      await dataSource.dispose();
    });

    test('emits LATERAL join keyword', () async {
      final subquery = dataSource.context
          .query<Post>()
          .orderBy('id', descending: true)
          .limit(1);

      final plan = dataSource.context
          .query<Author>()
          .joinLateral(
            subquery,
            'recent_posts',
            on: (join) => join.on('recent_posts.author_id', '=', 'base.id'),
          )
          .debugPlan();

      final sql = const PostgresQueryGrammar().compileSelect(plan).sql;
      expect(sql.toUpperCase(), contains('JOIN LATERAL'));
    });
  });
}
