import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  ModelRegistry registry = bootstrapOrm();
  group('Query predicate AST', () {
    late QueryContext context;

    setUp(() {
      context = QueryContext(
        registry: registry,
        driver: InMemoryQueryExecutor(),
      );
    });

    group('boolean grouping', () {
      test('captures nested AND/OR branches', () {
        final plan = context
            .query<Post>()
            .withTrashed()
            .where((outer) {
              outer.where('authorId', 1).orWhere((inner) {
                inner.whereBetween('id', 10, 20);
                inner.whereColumn('authorId', 'id');
              });
            })
            .orWhere((builder) {
              builder.whereNull('title');
              builder.whereNotNull('publishedAt');
            })
            .debugPlan();

        final root = plan.predicate as PredicateGroup;
        expect(root.logicalOperator, PredicateLogicalOperator.or);
        expect(root.predicates, hasLength(3));

        final equals = root.predicates[0] as FieldPredicate;
        expect(equals.field, 'author_id');
        expect(equals.operator, PredicateOperator.equals);
        expect(equals.value, 1);

        final inner = root.predicates[1] as PredicateGroup;
        expect(inner.logicalOperator, PredicateLogicalOperator.and);
        final between = inner.predicates.first as FieldPredicate;
        expect(between.operator, PredicateOperator.between);
        expect(between.lower, 10);
        expect(between.upper, 20);
        final columnCompare = inner.predicates.last as FieldPredicate;
        expect(columnCompare.operator, PredicateOperator.columnEquals);
        expect(columnCompare.compareField, 'id');

        final rhs = root.predicates[2] as PredicateGroup;
        expect(rhs.logicalOperator, PredicateLogicalOperator.and);
        final isNull = rhs.predicates.first as FieldPredicate;
        expect(isNull.operator, PredicateOperator.isNull);
        final isNotNull = rhs.predicates.last as FieldPredicate;
        expect(isNotNull.operator, PredicateOperator.isNotNull);
      });
    });

    group('range predicates', () {
      test('tracks inclusive bounds for between variants', () {
        final plan = context
            .query<Post>()
            .withTrashed()
            .whereBetween('id', 1, 5)
            .whereNotBetween('id', 50, 75)
            .debugPlan();

        final group = plan.predicate as PredicateGroup;
        expect(group.logicalOperator, PredicateLogicalOperator.and);
        expect(group.predicates, hasLength(2));

        final between = group.predicates.first as FieldPredicate;
        expect(between.operator, PredicateOperator.between);
        expect(between.lower, 1);
        expect(between.upper, 5);

        final notBetween = group.predicates.last as FieldPredicate;
        expect(notBetween.operator, PredicateOperator.notBetween);
        expect(notBetween.lower, 50);
        expect(notBetween.upper, 75);
      });
    });

    group('null predicates', () {
      test('captures nullability checks', () {
        final plan = context
            .query<Post>()
            .withTrashed()
            .whereNull('title')
            .whereNotNull('publishedAt')
            .debugPlan();

        final group = plan.predicate as PredicateGroup;
        final first = group.predicates.first as FieldPredicate;
        final second = group.predicates.last as FieldPredicate;
        expect(first.operator, PredicateOperator.isNull);
        expect(second.operator, PredicateOperator.isNotNull);
      });
    });

    group('set membership', () {
      test('stores in/not-in collections in the AST', () {
        final plan = context
            .query<Author>()
            .whereIn('id', [1, 2, 3])
            .whereNotIn('id', [4, 5])
            .debugPlan();

        final group = plan.predicate as PredicateGroup;
        final inPredicate = group.predicates.first as FieldPredicate;
        expect(inPredicate.operator, PredicateOperator.inValues);
        expect(inPredicate.values, [1, 2, 3]);

        final notInPredicate = group.predicates.last as FieldPredicate;
        expect(notInPredicate.operator, PredicateOperator.notInValues);
        expect(notInPredicate.values, [4, 5]);
      });
    });

    group('pattern predicates', () {
      test('tracks like/ilike variants and case sensitivity', () {
        final plan = context
            .query<Author>()
            .whereLike('name', 'Al%')
            .whereNotLike('name', 'Bob%')
            .whereILike('name', '%li%')
            .whereNotILike('name', '%zz%')
            .debugPlan();

        final predicates = (plan.predicate as PredicateGroup).predicates
            .cast<FieldPredicate>();
        expect(predicates[0].operator, PredicateOperator.like);
        expect(predicates[0].caseInsensitive, isFalse);
        expect(predicates[1].operator, PredicateOperator.notLike);
        expect(predicates[2].operator, PredicateOperator.iLike);
        expect(predicates[2].caseInsensitive, isTrue);
        expect(predicates[3].operator, PredicateOperator.notILike);
        expect(predicates[3].caseInsensitive, isTrue);
      });
    });

    group('column predicates', () {
      test('captures column equality and inequality comparisons', () {
        final plan = context
            .query<Post>()
            .withTrashed()
            .whereColumn('authorId', 'id')
            .whereColumn(
              'authorId',
              'id',
              operator: PredicateOperator.columnNotEquals,
            )
            .debugPlan();

        final group = plan.predicate as PredicateGroup;
        final equals = group.predicates.first as FieldPredicate;
        expect(equals.operator, PredicateOperator.columnEquals);
        expect(equals.compareField, 'id');

        final notEquals = group.predicates.last as FieldPredicate;
        expect(notEquals.operator, PredicateOperator.columnNotEquals);
        expect(notEquals.compareField, 'id');
      });
    });

    group('raw predicates', () {
      test('preserves SQL fragments and bindings', () {
        final plan = context
            .query<Post>()
            .withTrashed()
            .whereRaw('json_extract(metadata, ?) = ?', [r'$.flag', true])
            .havingRaw('count(*) > ?', [1])
            .debugPlan();

        final predicate = plan.predicate as RawPredicate;
        expect(predicate.sql, 'json_extract(metadata, ?) = ?');
        expect(predicate.bindings, [r'$.flag', true]);

        final having = plan.having as RawPredicate;
        expect(having.sql, 'count(*) > ?');
        expect(having.bindings.single, 1);
      });
    });

    group('projection metadata', () {
      test('captures select, raw select, and aggregate metadata', () {
        final plan = context
            .query<Post>()
            .select(['id'])
            .addSelect('title')
            .selectRaw(
              'strftime(?, published_at)',
              alias: 'published_year',
              bindings: ['%Y'],
            )
            .countAggregate(expression: 'authorId', alias: 'author_count')
            .max('publishedAt', alias: 'latest_published')
            .debugPlan();

        expect(plan.selects, ['id', 'title']);
        expect(plan.rawSelects, hasLength(1));
        expect(plan.rawSelects.first.alias, 'published_year');
        expect(plan.rawSelects.first.bindings, ['%Y']);

        expect(plan.aggregates, hasLength(2));
        final countAgg = plan.aggregates.first;
        expect(countAgg.function, AggregateFunction.count);
        expect(countAgg.expression, 'author_id');
        expect(countAgg.alias, 'author_count');

        final maxAgg = plan.aggregates.last;
        expect(maxAgg.function, AggregateFunction.max);
        expect(maxAgg.expression, 'published_at');
        expect(maxAgg.alias, 'latest_published');
      });
    });

    group('grouping metadata', () {
      test('captures groupBy keys and having clauses', () {
        final plan = context
            .query<Post>()
            .groupBy(['authorId'])
            .having('authorId', PredicateOperator.greaterThan, 5)
            .havingRaw('count(*) > ?', [2])
            .debugPlan();

        expect(plan.groupBy, ['author_id']);

        final having = plan.having as PredicateGroup;
        expect(having.logicalOperator, PredicateLogicalOperator.and);
        final fieldHaving = having.predicates.first as FieldPredicate;
        expect(fieldHaving.field, 'author_id');
        expect(fieldHaving.operator, PredicateOperator.greaterThan);
        expect(fieldHaving.value, 5);

        final rawHaving = having.predicates.last as RawPredicate;
        expect(rawHaving.sql, 'count(*) > ?');
        expect(rawHaving.bindings.single, 2);
      });
    });
  });
}
