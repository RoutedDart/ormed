import 'dart:io';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';

void main() {
  group('MySQL-specific joins', () {
    late DataSource dataSource;
    late MySqlDriverAdapter driverAdapter;

    setUpAll(() async {
      final url =
          Platform.environment['MYSQL_URL'] ??
          'mysql://root:secret@localhost:6605/orm_test';

      driverAdapter = MySqlDriverAdapter.custom(
        config: DatabaseConfig(
          driver: 'mysql',
          options: {'url': url, 'ssl': true},
        ),
      );

      dataSource = DataSource(DataSourceOptions(
        driver: driverAdapter,
        entities: generatedOrmModelDefinitions,
      ));

      registerDriverTestFactories();
      
      // Use schema lock to prevent concurrent schema modifications
      // await withSchemaLock(() async {
      //   await resetDriverTestSchema(driverAdapter, schema: null);
      //   await dataSource.init();
      // });
    });

    tearDownAll(() async {
      await dropDriverTestSchema(driverAdapter, schema: null);
      await dataSource.dispose();
    });

    test('emits STRAIGHT_JOIN keyword', () async {
      final plan = dataSource.context
          .query<Post>()
          .straightJoin('authors', 'authors.id', '=', 'posts.author_id')
          .debugPlan();

      final sql = const MySqlQueryGrammar().compileSelect(plan).sql;
      expect(sql.toUpperCase(), contains('STRAIGHT_JOIN'));
    });

    test('joinLateral emits keyword', () async {
      final subquery = dataSource.context.query<Post>().limit(1);
      final plan = dataSource.context
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
