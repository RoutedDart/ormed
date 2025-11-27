import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';

import 'support/postgres_harness.dart';

void main() {
  group('Postgres-specific joins', () {
    late PostgresTestHarness harness;

    setUp(() async {
      harness = await PostgresTestHarness.connect();
    });

    tearDown(() async => harness.dispose());

    test('emits LATERAL join keyword', () async {
      final subquery = harness.context
          .query<Post>()
          .orderBy('id', descending: true)
          .limit(1);

      final plan = harness.context
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
