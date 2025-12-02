import 'dart:io';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';

void main() {
  group('Postgres query scopes and macros', () {
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

    setUp(() async {
      await dataSource.repo<User>().insertMany(const [
        User(id: 1, email: 'alice@example.com', active: true),
        User(id: 2, email: 'bob@example.com', active: true),
        User(id: 3, email: 'carol@inactive.com', active: false),
      ]);

      dataSource.context.registerGlobalScope<User>(
        'active_only',
        (query) => query.whereEquals('active', true),
      );

      dataSource.context.registerLocalScope<User>(
        'email_like',
        (query, args) => query.whereLike('email', args.first as String),
      );

      dataSource.context.registerMacro(
        'orderedBy',
        (query, args) => query.orderBy(args.first as String),
      );
    });

    tearDown(() async {
      // Truncate table for isolation
      await driverAdapter.executeRaw('TRUNCATE TABLE users CASCADE');
    });

    tearDownAll(() async {
      await dropDriverTestSchema(driverAdapter, schema: null);
      await dataSource.dispose();
    });

    test(
      'global scopes run automatically and can be removed per query',
      () async {
        final scoped = await dataSource.context.query<User>().orderBy('id').get();
        expect(scoped.map((u) => u.id), equals([1, 2]));

        final unscoped = await dataSource.context
            .query<User>()
            .withoutGlobalScope('active_only')
            .orderBy('id')
            .get();
        expect(unscoped.map((u) => u.id), equals([1, 2, 3]));

        final allIgnored = await dataSource.context
            .query<User>()
            .withoutGlobalScopes()
            .orderBy('id')
            .get();
        expect(allIgnored.map((u) => u.id), equals([1, 2, 3]));
      },
    );

    test('local scopes are invoked via scope()', () async {
      final scoped = await dataSource.context
          .query<User>()
          .scope('email_like', ['%example.com'])
          .orderBy('id')
          .get();

      expect(scoped.map((u) => u.id), equals([1, 2]));

      expect(
        () => dataSource.context.query<User>().scope('missing', []),
        throwsArgumentError,
      );
    });

    test('query macros mutate the builder and return typed results', () async {
      final first = await dataSource.context.query<User>().macro('orderedBy', [
        'email',
      ]).first();

      expect(first?.email, 'alice@example.com');
    });
  });
}
