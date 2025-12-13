import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

void runRefreshTests() {
  ormedGroup(
    ' Model.refresh() with relations', (dataSource) {
      setUp(() async {
        // Bind connection resolver for Model methods to work
        Model.bindConnectionResolver(
          resolveConnection: (name) => dataSource.context,
        );

        // Seed test data
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
          Post(
            id: 2,
            authorId: 1,
            title: 'Post 2',
            publishedAt: DateTime(2024, 2),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
        ]);
      });

      tearDown(() async {
        Model.unbindConnectionResolver();
      });

      test('reloads model with specified relations', () async {
        // Load author without relations
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
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
        final rows = await dataSource.context
            .query<Author>()
            .withRelation('posts')
            .where('id', 1)
            .get();
        final author = rows.first;

        final originalName = author.name;
        expect(author.posts, hasLength(2));

        // Update author in database (simulate external change)
        await dataSource.context.runMutation(
          MutationPlan.update(
            definition: AuthorOrmDefinition.definition,
            rows: [
              MutationRow(values: {'name': 'Updated Name'}, keys: {'id': 1}),
            ],
            driverName: dataSource.options.driver.metadata.name,
          ),
        );

        // Add another post
        await dataSource.repo<Post>().insertMany([
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
        await dataSource.repo<Author>().insertMany([
          const Author(id: 2, name: 'Bob'),
        ]);

        // Load author
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 2)
            .get();
        final author = rows.first;

        // Refresh with relations
        await author.refresh(withRelations: ['posts']);

        expect(author.relationLoaded('posts'), isTrue);
        expect(author.posts, isEmpty);
      });

      test('refresh without relations still works', () async {
        // Ensure backward compatibility
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        final originalName = author.name;

        // Update in database
        await dataSource.context.runMutation(
          MutationPlan.update(
            definition: AuthorOrmDefinition.definition,
            rows: [
              MutationRow(values: {'name': 'New Name'}, keys: {'id': 1}),
            ],
            driverName: dataSource.options.driver.metadata.name,
          ),
        );

        // Refresh without relations
        await author.refresh();

        expect(author.name, equals('New Name'));
        expect(author.name, isNot(equals(originalName)));
      });
    },
  );
}
