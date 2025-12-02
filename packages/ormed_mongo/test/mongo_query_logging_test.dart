import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

import 'shared.dart';
import 'package:ormed_mongo/ormed_mongo.dart';

void main() {
  group('MongoDB query logging', () {
    late DataSource dataSource;
  late MongoDriverAdapter driverAdapter;
    late QueryContext loggingContext;
    final logEntries = <QueryLogEntry>[];

    setUpAll(() async {
      await waitForMongoReady();
    await clearDatabase();
    driverAdapter = createAdapter();
    registerDriverTestFactories();
    dataSource = DataSource(DataSourceOptions(
      driver: driverAdapter,
      entities: generatedOrmModelDefinitions,
    ));
    await dataSource.init();
      await seedGraph(dataSource);
      loggingContext = QueryContext(
        registry: dataSource.registry,
        driver: driverAdapter,
        codecRegistry: driverAdapter.codecs,
        queryLogHook: (entry) => logEntries.add(entry),
      );
    });

    tearDownAll(() async {
      await dataSource.dispose();
    });

    test('logs find queries with MongoDB notation', () async {
      logEntries.clear();
      await loggingContext.query<Author>().where('id', 1).get();

      final entry = logEntries.last;
      final sql = entry.sql;

      // Should show MongoDB find command instead of SQL
      expect(sql, contains('db.authors.find'));
      expect(sql, isNot(contains('SELECT')));
    });

    test('logs aggregate queries with MongoDB notation', () async {
      logEntries.clear();
      await loggingContext
          .query<Author>()
          .withSum('posts', 'views')
          .where('id', 1)
          .get();

      final entry = logEntries.last;
      final sql = entry.sql;

      // Should show MongoDB aggregate with pipeline
      expect(sql, contains('db.authors.aggregate'));
      expect(sql, contains('\$lookup'));
      expect(sql, isNot(contains('SELECT')));
    });
  });
}
