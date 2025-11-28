import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

import 'support/mongo_harness.dart';

void main() {
  group('MongoDB query logging', () {
    late MongoTestHarness harness;
    late QueryContext loggingContext;
    final logEntries = <QueryLogEntry>[];

    setUpAll(() async {
      harness = await MongoTestHarness.create();
      await seedGraph(harness);
      loggingContext = QueryContext(
        registry: harness.registry,
        driver: harness.adapter,
        codecRegistry: harness.adapter.codecs,
        queryLogHook: (entry) => logEntries.add(entry),
      );
    });

    tearDownAll(() async {
      await harness.dispose();
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
