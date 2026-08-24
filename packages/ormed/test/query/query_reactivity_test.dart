import 'dart:async';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryQueryExecutor driver;
  late QueryContext context;

  setUp(() {
    driver = InMemoryQueryExecutor();
    driver.register(AuthorOrmDefinition.definition, const [
      Author(id: 1, name: 'Alice', active: true),
    ]);
    context = QueryContext(registry: bootstrapOrm(), driver: driver);
  });

  test(
    'watch emits an initial snapshot and refreshes after a mutation',
    () async {
      final iterator = StreamIterator(
        context.query<Author>().orderBy('id').watch(),
      );

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current.map((author) => author.name), ['Alice']);

      await context.query<Author>().create({
        'id': 2,
        'name': 'Bob',
        'active': true,
      });

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current.map((author) => author.name), ['Alice', 'Bob']);

      await iterator.cancel();
    },
  );

  test('watch only refreshes for tables in the query dependency set', () async {
    final snapshots = <List<String>>[];
    final subscription = context.query<Author>().watch().listen(
      (authors) => snapshots.add(authors.map((author) => author.name).toList()),
    );

    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, [
      ['Alice'],
    ]);

    context.notifyTablesChanged(['posts']);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, [
      ['Alice'],
    ]);

    context.notifyTablesChanged(['authors']);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, [
      ['Alice'],
      ['Alice'],
    ]);

    await subscription.cancel();
  });

  test('transaction changes publish on commit and not on rollback', () async {
    final snapshots = <List<String>>[];
    final subscription = context.query<Author>().watch().listen(
      (authors) => snapshots.add(authors.map((author) => author.name).toList()),
    );

    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, [
      ['Alice'],
    ]);

    await context.transaction(() async {
      context.notifyTablesChanged(['authors']);
    });
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, [
      ['Alice'],
      ['Alice'],
    ]);

    await expectLater(
      context.transaction(() async {
        context.notifyTablesChanged(['authors']);
        throw StateError('rollback');
      }),
      throwsStateError,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, [
      ['Alice'],
      ['Alice'],
    ]);

    await subscription.cancel();
  });

  test('plan dependencies include eager-loaded relation tables', () {
    final plan = context.query<Author>().withRelation('posts').debugPlan();

    expect(plan.readTables, containsAll(['authors', 'posts']));
  });

  test('plan dependencies include nested subquery tables', () {
    final plan = context
        .query<Author>()
        .whereInSubquery('id', context.query<Post>().select(['authorId']))
        .debugPlan();

    final dependencies = QueryDependencies.fromPlan(plan);

    expect(dependencies.tables, containsAll(['authors', 'posts']));
    expect(dependencies.allTables, isFalse);
  });

  test('opaque predicates conservatively invalidate every watcher', () {
    final plan = context.query<Author>().whereRaw(
      'EXISTS (SELECT 1 FROM audit_log WHERE audit_log.id = ?)',
      [1],
    ).debugPlan();

    final dependencies = QueryDependencies.fromPlan(plan);

    expect(dependencies.allTables, isTrue);
  });

  test(
    'watch snapshots pass through stream and refresh interceptors',
    () async {
      final operations = <String>[];
      final instrumented = QueryContext(
        registry: bootstrapOrm(),
        driver: driver,
        interceptorPipeline: QueryInterceptorPipeline(
          driverName: driver.metadata.name,
          interceptors: [_OperationRecorder(operations)],
        ),
      );
      final iterator = StreamIterator(instrumented.query<Author>().watch());

      expect(await iterator.moveNext(), isTrue);
      instrumented.notifyTablesChanged(['authors']);
      expect(await iterator.moveNext(), isTrue);
      await iterator.cancel();

      expect(operations.where((operation) => operation == 'WATCH:stream'), [
        'WATCH:stream',
      ]);
      expect(operations.where((operation) => operation == 'SELECT'), [
        'SELECT',
        'SELECT',
      ]);
    },
  );
}

class _OperationRecorder extends QueryInterceptor {
  _OperationRecorder(this.operations);

  final List<String> operations;

  @override
  Future<T> intercept<T>(
    QueryExecutionContext context,
    Future<T> Function() next,
  ) {
    operations.add(context.operationName);
    return next();
  }

  @override
  Stream<T> interceptStream<T>(
    QueryExecutionContext context,
    Stream<T> Function() next,
  ) {
    operations.add('${context.operationName}:stream');
    return next();
  }
}
