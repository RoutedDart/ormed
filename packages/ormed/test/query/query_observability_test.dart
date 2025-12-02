/// Ensures query and mutation observability hooks behave as expected.
library;

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';


void main() {
  group('QueryContext observability', () {
    late ModelRegistry registry;
    late InMemoryQueryExecutor driver;
    late QueryContext context;

    setUp(() {
      registry = ModelRegistry()
        ..registerAll([
          AuthorOrmDefinition.definition,
          PostOrmDefinition.definition,
        ]);
      driver = InMemoryQueryExecutor();
      context = QueryContext(registry: registry, driver: driver);

      driver.register(AuthorOrmDefinition.definition, const [
        Author(id: 1, name: 'Alice', active: true),
        Author(id: 2, name: 'Bob', active: false),
      ]);
    });

    test('toSql delegates to the driver describe implementation', () {
      final preview = context.query<Author>().whereEquals('id', 1).toSql();
      expect(preview.sql, '<in-memory>');
    });

    test('emits query events with row counts', () async {
      final events = <QueryEvent>[];
      context.onQuery(events.add);

      final rows = await context.query<Author>().whereEquals('id', 1).rows();
      expect(rows, hasLength(1));

      expect(events, hasLength(1));
      final event = events.single;
      expect(event.rows, 1);
      expect(event.succeeded, isTrue);
      expect(event.preview.sql, '<in-memory>');
    });

    test('emits mutation events for repository inserts', () async {
      final events = <MutationEvent>[];
      context.onMutation(events.add);

      await context.repository<Author>().insert(
        const Author(id: 10, name: 'Test', active: true),
      );

      expect(events, hasLength(1));
      final event = events.single;
      expect(event.affectedRows, 1);
      expect(event.succeeded, isTrue);
      expect(event.preview.sql, '<in-memory>');
    });

    test('captures driver errors inside query events', () async {
      final failingContext = QueryContext(
        registry: registry,
        driver: _ThrowingDriver(),
      );
      final events = <QueryEvent>[];
      failingContext.onQuery(events.add);

      await expectLater(
        () => failingContext.query<Author>().get(),
        throwsStateError,
      );

      expect(events, hasLength(1));
      final event = events.single;
      expect(event.error, isA<StateError>());
      expect(event.succeeded, isFalse);
    });

    test('structured logger emits JSON-friendly maps', () async {
      final entries = <Map<String, Object?>>[];
      StructuredQueryLogger(
        onLog: entries.add,
        attributes: const {'env': 'test'},
      ).attach(context);

      await context.query<Author>().whereEquals('id', 1).first();
      await context.repository<Author>().insert(
        const Author(id: 99, name: 'Logger', active: true),
      );

      expect(entries, hasLength(2));
      final queryEntry = entries.firstWhere((e) => e['type'] == 'query');
      expect(queryEntry['model'], 'Author');
      expect(queryEntry['env'], 'test');
      final mutationEntry = entries.firstWhere((e) => e['type'] == 'mutation');
      expect(mutationEntry['operation'], 'insert');
      expect(mutationEntry['row_count'], 1);
      // Parameters may be omitted when the preview uses batched values.
      if (mutationEntry.containsKey('parameters')) {
        expect(mutationEntry['parameters'], isA<List<Object?>>());
      }
    });
  });
}

class _ThrowingDriver extends InMemoryQueryExecutor {
  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    throw StateError('boom');
  }
}
