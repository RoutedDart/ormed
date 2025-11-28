import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_mongo/src/mongo_query_plan_metadata.dart';
import 'package:test/test.dart';

import 'shared.dart';
import 'support/mongo_harness.dart';

void main() {
  late MongoTestHarness harness;

  setUpAll(() async {
    harness = await MongoTestHarness.create();
  });

  setUp(() async {
    await clearDatabase();
    await seedGraph(harness);
  });

  tearDownAll(() async => await harness.dispose());

  test('nested relation counts and metadata', () async {
    final posts = await harness.context.query<Post>().get();
    final photos = await harness.context.query<Photo>().get();
    final postIdsByAuthor = <int, List<int>>{};
    for (final post in posts) {
      postIdsByAuthor.putIfAbsent(post.authorId, () => <int>[]).add(post.id);
    }
    final nestedCounts = <int, int>{};
    for (final photo in photos) {
      if (photo.imageableType != 'Post') continue;
      for (final entry in postIdsByAuthor.entries) {
        if (entry.value.contains(photo.imageableId)) {
          nestedCounts[entry.key] = (nestedCounts[entry.key] ?? 0) + 1;
        }
      }
    }

    consumeTrackedMongoPlans();
    final query = harness.context
        .query<Author>()
        .withCount('posts.photos')
        .orderBy('id');
    final plan = query.debugPlan();
    final alias = plan.relationAggregates.single.alias;
    final rows = await query.rows();

    for (final row in rows) {
      final authorId = row.model.id;
      final expected = nestedCounts[authorId] ?? 0;
      expect(row.row[alias], equals(expected));
    }

    final tracked = trackedMongoPlans();
    expect(tracked, isNotEmpty);
    final metadata = metadataForPlan(tracked.last);
    consumeTrackedMongoPlans();
    expect(metadata, isNotNull);
    expect(metadata!.relationAggregates, hasLength(1));
    final aggregate = metadata.relationAggregates.single;
    expect(
      aggregate.path.segments.map((segment) => segment.name).join('.'),
      equals('posts.photos'),
    );
  });

  test('streaming exists keeps boolean alias and metadata', () async {
    consumeTrackedMongoPlans();
    final streamed = await harness.context
        .query<Author>()
        .withExists('posts')
        .streamRows()
        .toList();
    expect(streamed, isNotEmpty);
    for (final row in streamed) {
      expect(row.row.values.any((value) => value is bool), isTrue);
    }
    final tracked = trackedMongoPlans();
    expect(tracked, isNotEmpty);
    final metadata = metadataForPlan(tracked.last);
    expect(metadata, isNotNull);
    expect(metadata!.relationAggregates, isNotEmpty);
    expect(
      metadata.relationAggregates.first.type,
      equals(RelationAggregateType.exists),
    );
    consumeTrackedMongoPlans();
  });

  test(
    'relation ordering with distinct sorts buffered and streamed rows',
    () async {
      consumeTrackedMongoPlans();
      final query = harness.context.query<Author>().orderByRelation(
        'posts',
        aggregate: RelationAggregateType.count,
        descending: true,
        distinct: true,
      );
      final rows = await query.rows();
      final streamed = await query.streamRows().toList();
      expect(
        rows.map((row) => row.model.id),
        equals(streamed.map((row) => row.model.id)),
      );
      final tracked = trackedMongoPlans();
      expect(tracked, isNotEmpty);
      final metadata = metadataForPlan(tracked.last);
      expect(metadata, isNotNull);
      expect(metadata!.relationOrders, isNotEmpty);
      consumeTrackedMongoPlans();
    },
  );

  test('predicate-based counts store predicate in metadata', () async {
    consumeTrackedMongoPlans();
    final query = harness.context.query<Author>().withCount(
      'posts',
      constraint: (builder) =>
          builder.where('id', 1, PredicateOperator.greaterThan),
    );
    await query.rows();
    final tracked = trackedMongoPlans();
    expect(tracked, isNotEmpty);
    final metadata = metadataForPlan(tracked.last);
    expect(metadata, isNotNull);
    final matching = metadata!.relationAggregates.where(
      (aggregate) =>
          aggregate.path.segments.map((segment) => segment.name).join('.') ==
          'posts',
    );
    expect(matching, isNotEmpty);
    final predicate = matching.first.where;
    expect(predicate, isNotNull);
    expect(predicate, isA<FieldPredicate>());
    final fieldPredicate = predicate as FieldPredicate;
    expect(fieldPredicate.operator, equals(PredicateOperator.greaterThan));
    consumeTrackedMongoPlans();
  });

  test('nested relation ordering tracks descriptors', () async {
    consumeTrackedMongoPlans();
    final _ = harness.context
        .query<Author>()
        .orderByRelation(
          'posts.photos',
          aggregate: RelationAggregateType.count,
          descending: true,
        )
        .debugPlan();
    await harness.context
        .query<Author>()
        .orderByRelation(
          'posts.photos',
          aggregate: RelationAggregateType.count,
          descending: true,
        )
        .rows();
    final tracked = trackedMongoPlans();
    expect(tracked, isNotEmpty);
    final metadata = metadataForPlan(tracked.last);
    expect(metadata, isNotNull);
    final order = metadata!.relationOrders.single;
    expect(
      order.path.segments.map((segment) => segment.name).join('.'),
      equals('posts.photos'),
    );
    consumeTrackedMongoPlans();
  });
}
