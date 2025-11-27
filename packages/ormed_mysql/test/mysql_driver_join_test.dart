import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';

import 'support/mysql_harness.dart';

void main() {
  group('MySQL-specific joins', () {
    late MySqlTestHarness harness;

    setUp(() async {
      harness = await MySqlTestHarness.connect();
    });

    tearDown(() async => harness.dispose());

    test('emits STRAIGHT_JOIN keyword', () async {
      final plan = harness.context
          .query<Post>()
          .straightJoin('authors', 'authors.id', '=', 'posts.author_id')
          .debugPlan();

      final sql = const MySqlQueryGrammar().compileSelect(plan).sql;
      expect(sql.toUpperCase(), contains('STRAIGHT_JOIN'));
    });

    test('joinLateral emits keyword', () async {
      final subquery = harness.context.query<Post>().limit(1);
      final plan = harness.context
          .query<Author>()
          .joinLateral(
            subquery,
            'recent_posts',
            on: (join) => join.on('recent_posts.author_id', '=', 'base.id'),
          )
          .debugPlan();

      final sql = const MySqlQueryGrammar().compileSelect(plan).sql;
      expect(sql.toUpperCase(), contains('JOIN LATERAL'));
    });
  });
}
