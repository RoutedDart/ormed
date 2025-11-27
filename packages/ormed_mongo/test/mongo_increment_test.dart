import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

import 'support/mongo_harness.dart';

void main() {
  late MongoTestHarness harness;

  setUpAll(() async {
    harness = await MongoTestHarness.create();
    await seedGraph(harness);
    await harness.adapter.dropCollectionDirect('articles');
  });

  tearDownAll(() async => await harness.dispose());

  test(
    'increment helper records \$inc payload and updates documents',
    () async {
      final article = Article(
        id: 301,
        title: 'Increment Story',
        body: 'Testing Mongo increments',
        status: 'draft',
        rating: 4.2,
        priority: 10,
        publishedAt: DateTime.utc(2024, 6, 1),
        reviewedAt: null,
        categoryId: 1,
      );
      await harness.context.repository<Article>().insert(article);
      final query = harness.context.query<Article>().whereEquals(
        'id',
        article.id,
      );
      final plan = query.debugPlan();
      expect(plan.filters.single.field, equals('id'));
      expect(plan.filters.single.value, equals(article.id));
      final existing = await query.first();
      expect(existing, isNotNull);
      expect(existing!.id, equals(article.id));
      expect(existing.priority, equals(article.priority));
      final pkField = plan.definition.primaryKeyField!;
      final primarySelect = plan.copyWith(
        selects: [pkField.columnName],
        rawSelects: const [],
        aggregates: const [],
        projectionOrder: const [ProjectionOrderEntry.column(0)],
      );
      final mutationPlan = MutationPlan.queryUpdate(
        definition: plan.definition,
        plan: primarySelect,
        values: const {},
        jsonUpdates: const [],
        driverName: harness.adapter.metadata.name,
        primaryKey: pkField.columnName,
        queryIncrementValues: {'priority': 3},
      );
      final preview = harness.context.describeMutation(mutationPlan);
      final payload = preview.payload as DocumentStatementPayload;
      final updateDoc = payload.arguments['update'] as Map<String, Object?>?;
      expect(updateDoc, isNotNull);
      expect(updateDoc!['\$inc'], equals({'priority': 3}));

      final affected = await query.increment('priority', 3);
      expect(affected, equals(1));

      final updated = await harness.context
          .query<Article>()
          .whereEquals('id', article.id)
          .first();
      expect(updated, isNotNull);
      expect(updated!.priority, equals(article.priority + 3));
      await harness.context.repository<Article>().deleteByKeys([
        {'id': article.id},
      ]);
    },
  );

  test(
    'decrement helper records negative \$inc and updates documents',
    () async {
      final article = Article(
        id: 302,
        title: 'Decrement Story',
        body: 'Testing Mongo decrements',
        status: 'review',
        rating: 3.5,
        priority: 20,
        publishedAt: DateTime.utc(2024, 6, 2),
        reviewedAt: DateTime.utc(2024, 6, 5),
        categoryId: 1,
      );
      await harness.context.repository<Article>().insert(article);
      final query = harness.context.query<Article>().whereEquals(
        'id',
        article.id,
      );
      final plan = query.debugPlan();
      expect(plan.filters.single.field, equals('id'));
      expect(plan.filters.single.value, equals(article.id));
      final existing = await query.first();
      expect(existing, isNotNull);
      expect(existing!.id, equals(article.id));
      expect(existing.priority, equals(article.priority));
      final pkField = plan.definition.primaryKeyField!;
      final primarySelect = plan.copyWith(
        selects: [pkField.columnName],
        rawSelects: const [],
        aggregates: const [],
        projectionOrder: const [ProjectionOrderEntry.column(0)],
      );
      final mutationPlan = MutationPlan.queryUpdate(
        definition: plan.definition,
        plan: primarySelect,
        values: const {},
        jsonUpdates: const [],
        driverName: harness.adapter.metadata.name,
        primaryKey: pkField.columnName,
        queryIncrementValues: {'priority': -5},
      );
      final preview = harness.context.describeMutation(mutationPlan);
      final payload = preview.payload as DocumentStatementPayload;
      final updateDoc = payload.arguments['update'] as Map<String, Object?>?;
      expect(updateDoc, isNotNull);
      expect(updateDoc!['\$inc'], equals({'priority': -5}));

      final affected = await query.decrement('priority', 5);
      expect(affected, equals(1));

      final updated = await harness.context
          .query<Article>()
          .whereEquals('id', article.id)
          .first();
      expect(updated, isNotNull);
      expect(updated!.priority, equals(article.priority - 5));
      await harness.context.repository<Article>().deleteByKeys([
        {'id': article.id},
      ]);
    },
  );
}
