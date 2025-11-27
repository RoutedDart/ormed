import 'package:driver_tests/models.dart';
import 'package:test/test.dart';
import 'support/postgres_harness.dart';

void main() {
  group('Postgres query scopes and macros', () {
    late PostgresTestHarness harness;

    setUp(() async {
      harness = await PostgresTestHarness.connect();
      await harness.seedUsers(const [
        User(id: 1, email: 'alice@example.com', active: true),
        User(id: 2, email: 'bob@example.com', active: true),
        User(id: 3, email: 'carol@inactive.com', active: false),
      ]);

      harness.context.registerGlobalScope<User>(
        'active_only',
        (query) => query.whereEquals('active', true),
      );

      harness.context.registerLocalScope<User>(
        'email_like',
        (query, args) => query.whereLike('email', args.first as String),
      );

      harness.context.registerMacro(
        'orderedBy',
        (query, args) => query.orderBy(args.first as String),
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    test(
      'global scopes run automatically and can be removed per query',
      () async {
        final scoped = await harness.context.query<User>().orderBy('id').get();
        expect(scoped.map((u) => u.id), equals([1, 2]));

        final unscoped = await harness.context
            .query<User>()
            .withoutGlobalScope('active_only')
            .orderBy('id')
            .get();
        expect(unscoped.map((u) => u.id), equals([1, 2, 3]));

        final allIgnored = await harness.context
            .query<User>()
            .withoutGlobalScopes()
            .orderBy('id')
            .get();
        expect(allIgnored.map((u) => u.id), equals([1, 2, 3]));
      },
    );

    test('local scopes are invoked via scope()', () async {
      final scoped = await harness.context
          .query<User>()
          .scope('email_like', ['%example.com'])
          .orderBy('id')
          .get();

      expect(scoped.map((u) => u.id), equals([1, 2]));

      expect(
        () => harness.context.query<User>().scope('missing', []),
        throwsArgumentError,
      );
    });

    test('query macros mutate the builder and return typed results', () async {
      final first = await harness.context.query<User>().macro('orderedBy', [
        'email',
      ]).first();

      expect(first?.email, 'alice@example.com');
    });
  });
}
