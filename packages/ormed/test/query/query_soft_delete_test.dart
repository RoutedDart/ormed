import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'package:driver_tests/driver_tests.dart';

void main() {
  group('Soft deletes', () {
    late ModelRegistry registry;
    late InMemoryQueryExecutor executor;
    late QueryContext context;

    setUp(() {
      registry = ModelRegistry()..register(CommentOrmDefinition.definition);
      executor = InMemoryQueryExecutor();
      final visible = Comment(id: 1, body: 'Visible');
      final trashed = Comment(id: 2, body: 'Trashed')
        ..deletedAt = DateTime.utc(2024, 1, 15);
      executor.register(CommentOrmDefinition.definition, [visible, trashed]);
      context = QueryContext(registry: registry, driver: executor);
    });

    test('global scope hides trashed records', () async {
      final comments = await context.query<Comment>().get();
      expect(comments, hasLength(1));
      expect(comments.single.body, 'Visible');
    });

    test('withTrashed returns all rows', () async {
      final comments = await context.query<Comment>().withTrashed().get();
      expect(comments.map((c) => c.body), containsAll(['Visible', 'Trashed']));
    });

    test('onlyTrashed filters to deleted rows', () async {
      final trashed = await context.query<Comment>().onlyTrashed().get();
      expect(trashed.single.body, 'Trashed');
    });

    test('restore clears deleted_at column through mutation plan', () async {
      final affected = await context
          .query<Comment>()
          .whereEquals('id', 2)
          .restore();

      expect(affected, 1);
      final withTrashed = await context
          .query<Comment>()
          .withTrashed()
          .orderBy('id')
          .get();
      expect(withTrashed.map((c) => c.deletedAt), everyElement(isNull));
    });

    test('forceDelete removes rows regardless of scope', () async {
      final affected = await context
          .query<Comment>()
          .withTrashed()
          .whereEquals('id', 1)
          .forceDelete();

      expect(affected, 1);
      final remaining = await context.query<Comment>().withTrashed().get();
      expect(remaining.single.id, 2);
    });
  });
}
