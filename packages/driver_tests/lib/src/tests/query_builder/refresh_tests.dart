import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

void runRefreshTests(
  DriverHarnessBuilder<DriverTestHarness> createHarness,
  DriverTestConfig config,
) {
  group('${config.driverName} Model.refresh() with relations', () {
    late DriverTestHarness harness;

    setUp(() async {
      harness = await createHarness();

      // Bind connection resolver for Model methods to work
      Model.bindConnectionResolver(
        resolveConnection: (name) => harness.context,
      );

      // Seed test data
      await harness.seedAuthors([const Author(id: 1, name: 'Alice')]);
      await harness.seedPosts([
        Post(id: 1, authorId: 1, title: 'Post 1', publishedAt: DateTime(2024)),
        Post(
          id: 2,
          authorId: 1,
          title: 'Post 2',
          publishedAt: DateTime(2024, 2),
        ),
      ]);
      await harness.seedTags([const Tag(id: 1, label: 'dart')]);
      await harness.seedPostTags([const PostTag(postId: 1, tagId: 1)]);
    });

    tearDown(() async {
      Model.unbindConnectionResolver();
      await harness.dispose();
    });

    test('reloads model with specified relations', () async {
      // Load author without relations
      final rows = await harness.context.query<Author>().where('id', 1).get();
      final author = rows.first;

      expect(author.relationLoaded('posts'), isFalse);
      expect(author.posts, isEmpty);

      // Refresh with relations
      await author.refresh(withRelations: ['posts']);

      expect(author.relationLoaded('posts'), isTrue);
      expect(author.posts, hasLength(2));
    });

    test('refreshes attributes and relations together', () async {
      // Load author with relations
      final rows = await harness.context
          .query<Author>()
          .withRelation('posts')
          .where('id', 1)
          .get();
      final author = rows.first;

      final originalName = author.name;
      expect(author.posts, hasLength(2));

      // Update author in database (simulate external change)
      await harness.context.runMutation(
        MutationPlan.update(
          definition: AuthorOrmDefinition.definition,
          rows: [
            MutationRow(values: {'name': 'Updated Name'}, keys: {'id': 1}),
          ],
          driverName: harness.adapter.metadata.name,
        ),
      );

      // Add another post
      await harness.seedPosts([
        Post(
          id: 3,
          authorId: 1,
          title: 'Post 3',
          publishedAt: DateTime(2024, 3),
        ),
      ]);

      // Refresh with relations
      await author.refresh(withRelations: ['posts']);

      // Verify both attributes and relations are refreshed
      expect(author.name, equals('Updated Name'));
      expect(author.name, isNot(equals(originalName)));
      expect(author.posts, hasLength(3));
    });

    test('works with empty relations', () async {
      // Seed author without posts
      await harness.seedAuthors([const Author(id: 2, name: 'Bob')]);

      // Load author
      final rows = await harness.context.query<Author>().where('id', 2).get();
      final author = rows.first;

      // Refresh with relations
      await author.refresh(withRelations: ['posts']);

      expect(author.relationLoaded('posts'), isTrue);
      expect(author.posts, isEmpty);
    });

    test('refresh without relations still works', () async {
      // Ensure backward compatibility
      final rows = await harness.context.query<Author>().where('id', 1).get();
      final author = rows.first;

      final originalName = author.name;

      // Update in database
      await harness.context.runMutation(
        MutationPlan.update(
          definition: AuthorOrmDefinition.definition,
          rows: [
            MutationRow(values: {'name': 'New Name'}, keys: {'id': 1}),
          ],
          driverName: harness.adapter.metadata.name,
        ),
      );

      // Refresh without relations
      await author.refresh();

      expect(author.name, equals('New Name'));
      expect(author.name, isNot(equals(originalName)));
    });
  });
}
