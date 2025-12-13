import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';
import '../seed_data.dart';

void runDriverAdvancedQueryTests() {
  ormedGroup('advanced builders', (dataSource) {
    final metadata = dataSource.options.driver.metadata;
    if (!metadata.supportsCapability(DriverCapability.advancedQueryBuilders)) {
      return;
    }
    setUp(() async {
      await dataSource.repo<Article>().insertMany(sampleArticles);
    });

    group('filter predicates', () {
      test('applies between/notBetween combinations', () async {
        final models = await dataSource.context
            .query<Article>()
            .whereBetween('rating', 3.5, 4.9)
            .whereNotBetween('priority', 4, 5)
            .orderBy('id')
            .get();

        expect(models.map((a) => a.id), equals([2]));
      });

      test('supports in/notIn sets with empty guard rails', () async {
        final include = await dataSource.context
            .query<Article>()
            .whereIn('status', ['draft', 'review'])
            .orderBy('id')
            .get();
        expect(include.map((a) => a.id), equals([1, 2]));

        final exclude = await dataSource.context
            .query<Article>()
            .whereNotIn('id', [1, 4])
            .orderBy('id')
            .get();
        expect(exclude.map((a) => a.id), equals([2, 3]));
      });

      test('handles null/notNull predicates on nullable columns', () async {
        final nullBodies = await dataSource.context
            .query<Article>()
            .whereNull('body')
            .orderBy('id')
            .get();
        expect(nullBodies.map((a) => a.id), equals([1, 4]));

        final reviewed = await dataSource.context
            .query<Article>()
            .whereNotNull('reviewedAt')
            .orderBy('id')
            .get();
        expect(reviewed.map((a) => a.id), equals([2, 3, 4]));
      });
    });

    group('pattern predicates', () {
      test('combines like/notLike and ilike/notILike', () async {
        final titles = await dataSource.context
            .query<Article>()
            .whereLike('title', '%Update%')
            .orWhere((builder) {
              if (metadata.supportsCapability(
                DriverCapability.caseInsensitiveLike,
              )) {
                builder.whereILike('title', 'DELTA%');
              } else {
                builder.whereLike('title', 'delta%');
              }
            })
            .orderBy('id')
            .get();
        expect(titles.map((a) => a.id), equals([2, 4]));

        final filtered = await dataSource.context
            .query<Article>()
            .whereNotLike('title', '%Release%')
            .where((builder) {
              if (metadata.supportsCapability(
                DriverCapability.caseInsensitiveLike,
              )) {
                builder.whereNotILike('title', 'GAMMA%');
              } else {
                builder.whereNotLike('title', 'Gamma%');
              }
            })
            .orderBy('id')
            .get();
        expect(filtered.map((a) => a.id), equals([2, 4]));
      });
    });

    group('column comparisons', () {
      test('supports equals and not-equals between columns', () async {
        final matching = await dataSource.context
            .query<Article>()
            .whereColumn('reviewedAt', 'publishedAt')
            .get();
        expect(matching.map((a) => a.id), equals([2]));

        final different = await dataSource.context
            .query<Article>()
            .whereColumn(
              'reviewedAt',
              'publishedAt',
              operator: PredicateOperator.columnNotEquals,
            )
            .orderBy('id')
            .get();
        expect(different.map((a) => a.id), equals([3, 4]));
      });
    });

    group('raw predicates and having clauses', () {
      test('evaluates whereRaw fragments with bindings', () async {
        final models = await dataSource.context
            .query<Article>()
            .whereRaw('LENGTH(title) BETWEEN ? AND ?', [11, 14])
            .orderBy('id')
            .get();

        expect(models.map((a) => a.id), equals([1, 2, 3]));
      });

      test('applies having and havingRaw over grouped aggregates', () async {
        final query = dataSource.context
            .query<Article>()
            .select(['categoryId'])
            .countAggregate(expression: '*', alias: 'total_articles')
            .sum('priority', alias: 'priority_sum')
            .groupBy(['categoryId'])
            .having('categoryId', PredicateOperator.greaterThan, 0)
            .havingRaw('SUM(priority) > ?', [5])
            .orderBy('categoryId');

        // ignore: invalid_use_of_visible_for_testing_member
        final rows = await dataSource.connection.driver.execute(
          query.debugPlan(),
        );
        expect(rows, hasLength(2));
        expect(rows[0]['category_id'], 1);
        expect(rows[0]['priority_sum'], 8);
        expect(rows[1]['category_id'], 2);
        expect(rows[1]['total_articles'], 2);
      });
    });

    group('projection metadata', () {
      test(
        'returns raw selects and aggregates alongside base columns',
        () async {
          final query = dataSource.context
              .query<Article>()
              .select(['id', 'title'])
              .selectRaw('UPPER(title) AS loud_title')
              .max('rating', alias: 'max_rating')
              .whereEquals('id', 1)
              .groupBy(['id', 'title']);

          // ignore: invalid_use_of_visible_for_testing_member
          final plan = query.debugPlan();
          final rows = await dataSource.connection.driver.execute(plan);

          expect(rows.single['id'], 1);
          expect(rows.single['loud_title'], 'ALPHA RELEASE');
          expect(rows.single['max_rating'], 4.8);
        },
      );
    });
  });
}
