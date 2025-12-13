import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';

void main() {
  ModelRegistry registry = buildOrmRegistry();
  group('QueryContext.table', () {
    late InMemoryQueryExecutor driver;
    late QueryContext context;

    setUp(() {
      driver = InMemoryQueryExecutor()
        ..register(AuthorOrmDefinition.definition, const [
          Author(id: 1, name: 'Alice', active: true),
        ]);
      context = QueryContext(registry: registry, driver: driver);
    });

    test('returns Map rows without model definition', () async {
      final models = await context.table('authors').whereEquals('id', 1).get();
      expect(models, hasLength(1));
      expect(models.single['name'], 'Alice');
    });

    test('allows arbitrary column predicates', () async {
      final query = context.table('authors');
      // Column not present in ORM definition should still be accepted.
      final plan = query.whereEquals('custom_column', 42).debugPlan();
      expect(plan.filters.single.field, 'custom_column');
    });

    test('records alias in the query plan', () {
      final plan = context.table('authors', as: 'a').debugPlan();
      expect(plan.tableAlias, 'a');
      expect(plan.definition.tableName, 'authors');
    });

    test('mapRows helper maps to custom DTOs', () async {
      final names = await context
          .table('authors')
          .mapRows((row) => row['name'] as String)
          .getMapped();
      expect(names, ['Alice']);
    });

    test('mapRows stream emits DTOs', () async {
      final stream = context
          .table('authors')
          .mapRows((row) => row['name'] as String)
          .streamMapped();

      expectLater(stream, emitsInOrder(['Alice', emitsDone]));
    });

    test('streamRows delegates to driver stream implementation', () async {
      final streamingRegistry = ModelRegistry()
        ..registerAll([AuthorOrmDefinition.definition])..registerGeneratedModels();
      final streamingDriver = _StreamingQueryDriver()
        ..register(AuthorOrmDefinition.definition, const [
          Author(id: 1, name: 'Alice', active: true),
          Author(id: 2, name: 'Bob', active: false),
        ]);
      final streamingContext = QueryContext(
        registry: streamingRegistry,
        driver: streamingDriver,
      );

      final names = await streamingContext
          .query<Author>()
          .orderBy('id')
          .streamRows()
          .map((row) => row.model.name)
          .toList();

      expect(names, ['Alice', 'Bob']);
      expect(streamingDriver.streamedTables, contains('authors'));
      expect(streamingDriver.executedTables, isEmpty);
    });

    test('streamRows eager loads relations in batches', () async {

      final streamingDriver = _StreamingQueryDriver()
        ..register(AuthorOrmDefinition.definition, const [
          Author(id: 1, name: 'Alice', active: true),
          Author(id: 2, name: 'Bob', active: true),
        ])
        ..register(PostOrmDefinition.definition, [
          Post(
            id: 1,
            authorId: 1,
            title: 'First',
            publishedAt: DateTime.utc(2024, 1, 1),
          ),
          Post(
            id: 2,
            authorId: 2,
            title: 'Second',
            publishedAt: DateTime.utc(2024, 1, 2),
          ),
        ]);

      final streamingContext = QueryContext(
        registry: registry,
        driver: streamingDriver,
      );

      final rows = await streamingContext
          .query<Post>()
          .withRelation('author')
          .orderBy('id')
          .streamRows(eagerLoadBatchSize: 1)
          .toList();

      expect(rows, hasLength(2));
      expect(rows.first.relation<Author>('author')?.id, 1);
      expect(rows.last.relation<Author>('author')?.id, 2);
      expect(
        streamingDriver.streamedTables.where((t) => t == 'posts'),
        hasLength(1),
      );
      expect(streamingDriver.executedTables.contains('posts'), isFalse);
      expect(streamingDriver.executedTables, contains('authors'));
    });

    test('table scopes apply registered callbacks', () {
      context.scopeRegistry.registerAdHocTableScope(
        'tenant',
        (query) => query.whereEquals('tenant_id', 99),
        pattern: 'authors',
      );

      final plan = context.table('authors', scopes: ['tenant']).debugPlan();

      expect(plan.filters.single.field, 'tenant_id');
      expect(plan.filters.single.value, 99);
    });

    test('table scopes support wildcard patterns', () {
      context.scopeRegistry.registerAdHocTableScope(
        'tenant',
        (query) => query.whereEquals('tenant_id', 42),
        pattern: 'author*',
      );

      final plan = context
          .table('authors_archive', scopes: ['tenant'])
          .debugPlan();

      expect(plan.filters.single.field, 'tenant_id');
      expect(plan.filters.single.value, 42);
    });

    test('column metadata customizes predicates', () {
      final plan = context
          .table(
            'events',
            columns: const [
              AdHocColumn(
                name: 'occurredAt',
                columnName: 'occurred_at',
                dartType: 'DateTime',
                resolvedType: 'DateTime?',
                isNullable: false,
              ),
            ],
          )
          .whereNull('occurredAt')
          .debugPlan();

      expect(plan.filters.single.field, 'occurred_at');
    });
  });
}

class _StreamingQueryDriver extends InMemoryQueryExecutor {
  final List<String> streamedTables = [];
  final List<String> executedTables = [];

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) {
    executedTables.add(plan.definition.tableName);
    return super.execute(plan);
  }

  @override
  Stream<Map<String, Object?>> stream(QueryPlan plan) async* {
    streamedTables.add(plan.definition.tableName);
    final rows = await super.execute(plan);
    for (final row in rows) {
      yield row;
    }
  }
}
