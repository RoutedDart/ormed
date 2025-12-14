import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'package:driver_tests/driver_tests.dart';

void main() {
  ModelRegistry registry = buildOrmRegistry();
  group('Query scopes and macros', () {
    late QueryContext context;

    setUp(() {
      context = QueryContext(
        registry: registry,
        driver: InMemoryQueryExecutor()
          ..register(AuthorOrmDefinition.definition, const [
            Author(id: 1, name: 'Alice', active: true),
            Author(id: 2, name: 'Bob', active: false),
          ]),
      );
    });

    test('applies global scopes automatically', () {
      context.registerGlobalScope<Author>(
        'activeOnly',
        (query) => query.whereEquals('active', true),
      );

      final plan = context.query<Author>().debugPlan();
      expect(plan.predicate, isA<FieldPredicate>());

      final without = context
          .query<Author>()
          .withoutGlobalScope('activeOnly')
          .debugPlan();
      expect(without.predicate, isNull);
    });

    test('withoutGlobalScopes removes all registered scopes', () {
      context.registerGlobalScope<Author>(
        'activeOnly',
        (query) => query.whereEquals('active', true),
      );
      context.registerGlobalScope<Author>(
        'named',
        (query) => query.whereEquals('name', 'Alice'),
      );

      final plan = context.query<Author>().withoutGlobalScopes().debugPlan();
      expect(plan.predicate, isNull);
    });

    test('invokes registered local scopes', () {
      context.registerLocalScope<Author>(
        'named',
        (query, args) => query.whereEquals('name', args.first as String),
      );

      final plan = context.query<Author>().scope('named', [
        'Alice',
      ]).debugPlan();
      expect(plan.predicate, isA<FieldPredicate>());
    });

    test('invokes registered macros', () {
      context.registerMacro('whereActiveFlag', (query, args) {
        final builder = query as Query<Author>;
        return builder.whereEquals('active', args.first as bool);
      });

      final plan = context.query<Author>().macro('whereActiveFlag', [
        true,
      ]).debugPlan();
      expect(plan.predicate, isA<FieldPredicate>());
    });

    test('applies pattern-based global scopes', () {
      context.registerGlobalScopePattern<Author>(
        'activePattern',
        (query) => query.whereEquals('active', true),
        pattern: 'Auth*',
      );

      final plan = context.query<Author>().debugPlan();
      expect(plan.predicate, isA<FieldPredicate>());

      final without = context
          .query<Author>()
          .withoutGlobalScope('activePattern')
          .debugPlan();
      expect(without.predicate, isNull);
    });

    test('invokes pattern-based local scopes', () {
      context.registerLocalScopePattern<Author>(
        'namedPattern',
        (query, args) => query.whereEquals('name', args.first as String),
        pattern: 'Auth*',
      );

      final plan = context.query<Author>().scope('namedPattern', [
        'Alice',
      ]).debugPlan();
      expect(plan.predicate, isA<FieldPredicate>());
    });
  });
}
