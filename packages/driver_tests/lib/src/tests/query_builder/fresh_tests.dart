import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

void runFreshTests(DataSource dataSource) {
  final metadata = dataSource.connection.driver.metadata;
  group('${metadata.name} Model.fresh()', () {
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
        Post(id: 1, authorId: 1, title: 'Post 1', publishedAt: DateTime(2024)),
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

    group('basic functionality', () {
      test('returns a new instance from database', () async {
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        final freshAuthor = await author.fresh();

        // Should return a new instance, not the same one
        expect(identical(freshAuthor, author), isFalse);
        expect(freshAuthor.id, equals(author.id));
        expect(freshAuthor.name, equals(author.name));
      });

      test('fresh instance reflects database changes', () async {
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        final originalName = author.name;

        // Update author in database (simulate external change)
        await dataSource.context.runMutation(
          MutationPlan.update(
            definition: AuthorOrmDefinition.definition,
            rows: [
              MutationRow(values: {'name': 'Updated Name'}, keys: {'id': 1}),
            ],
            driverName: dataSource.connection.driver.metadata.name,
          ),
        );

        // Get fresh instance
        final freshAuthor = await author.fresh();

        // Original should still have old value
        expect(author.name, equals(originalName));

        // Fresh should have new value
        expect(freshAuthor.name, equals('Updated Name'));
        expect(freshAuthor.name, isNot(equals(originalName)));
      });

      test('original instance is not modified', () async {
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        final originalName = author.name;

        // Update author in database
        await dataSource.context.runMutation(
          MutationPlan.update(
            definition: AuthorOrmDefinition.definition,
            rows: [
              MutationRow(values: {'name': 'Changed'}, keys: {'id': 1}),
            ],
            driverName: dataSource.connection.driver.metadata.name,
          ),
        );

        // Get fresh instance
        await author.fresh();

        // Original should remain unchanged
        expect(author.name, equals(originalName));
      });
    });

    group('with relations', () {
      test('fresh returns instance with specified relations loaded', () async {
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        expect(author.relationLoaded('posts'), isFalse);
        expect(author.posts, isEmpty);

        // Get fresh instance with relations
        final freshAuthor = await author.fresh(withRelations: ['posts']);

        expect(freshAuthor.relationLoaded('posts'), isTrue);
        expect(freshAuthor.posts, hasLength(2));

        // Original should still not have relations loaded
        expect(author.relationLoaded('posts'), isFalse);
      });

      test('fresh with multiple relations', () async {
        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(post.relationLoaded('author'), isFalse);
        expect(post.relationLoaded('tags'), isFalse);

        final freshPost = await post.fresh(withRelations: ['author', 'tags']);

        expect(freshPost.relationLoaded('author'), isTrue);
        expect(freshPost.relationLoaded('tags'), isTrue);
        expect(freshPost.author, isNotNull);
        expect(freshPost.tags, hasLength(1));
      });

      test('fresh preserves existing relations on original', () async {
        final rows = await dataSource.context
            .query<Author>()
            .withRelation('posts')
            .where('id', 1)
            .get();
        final author = rows.first;

        expect(author.relationLoaded('posts'), isTrue);
        final originalPosts = author.posts;

        // Get fresh instance without relations
        final freshAuthor = await author.fresh();

        // Original should still have its loaded relations
        expect(author.relationLoaded('posts'), isTrue);
        expect(identical(author.posts, originalPosts), isTrue);

        // Fresh instance should not have relations loaded
        expect(freshAuthor.relationLoaded('posts'), isFalse);
      });

      test('fresh relations reflect database changes', () async {
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        // Add a new post in database
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 3,
            authorId: 1,
            title: 'Post 3',
            publishedAt: DateTime(2024, 3),
          ),
        ]);

        // Get fresh instance with relations
        final freshAuthor = await author.fresh(withRelations: ['posts']);

        // Fresh should have all 3 posts
        expect(freshAuthor.posts, hasLength(3));
      });
    });

    group('comparison with refresh()', () {
      test(
        'fresh() returns new instance while refresh() mutates original',
        () async {
          final rows = await dataSource.context
              .query<Author>()
              .where('id', 1)
              .get();
          final author = rows.first;

          // Update author in database
          await dataSource.context.runMutation(
            MutationPlan.update(
              definition: AuthorOrmDefinition.definition,
              rows: [
                MutationRow(
                  values: {'name': 'External Change'},
                  keys: {'id': 1},
                ),
              ],
              driverName: metadata.name,
            ),
          );

          // Get fresh instance
          final freshAuthor = await author.fresh();

          // At this point author still has old value
          expect(author.name, equals('Alice'));
          expect(freshAuthor.name, equals('External Change'));

          // Now refresh the original
          await author.refresh();

          // Now original should be updated too
          expect(author.name, equals('External Change'));
        },
      );

      test('fresh() and refresh() both support withRelations', () async {
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        // fresh with relations
        final freshAuthor = await author.fresh(withRelations: ['posts']);
        expect(freshAuthor.relationLoaded('posts'), isTrue);

        // refresh with relations
        await author.refresh(withRelations: ['posts']);
        expect(author.relationLoaded('posts'), isTrue);

        // Both should have same post count
        expect(author.posts.length, equals(freshAuthor.posts.length));
      });
    });

    group('edge cases', () {
      test(
        'fresh() on model without changes returns equivalent data',
        () async {
          final rows = await dataSource.context
              .query<Author>()
              .where('id', 1)
              .get();
          final author = rows.first;

          final freshAuthor = await author.fresh();

          expect(freshAuthor.id, equals(author.id));
          expect(freshAuthor.name, equals(author.name));
        },
      );

      test('fresh() throws for model without primary key value', () async {
        // Create an author instance without saving (no id from database)
        final unsavedAuthor = const Author(id: 999999, name: 'Unsaved');

        // This should throw because the model doesn't exist in database
        expect(
          () => unsavedAuthor.fresh(),
          throwsA(isA<ModelNotFoundException>()),
        );
      });

      test('multiple fresh() calls return independent instances', () async {
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        final fresh1 = await author.fresh();
        final fresh2 = await author.fresh();

        expect(identical(fresh1, fresh2), isFalse);
        expect(fresh1.id, equals(fresh2.id));
        expect(fresh1.name, equals(fresh2.name));
      });

      test('fresh() with empty withRelations list', () async {
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        // Should work with empty relations list
        final freshAuthor = await author.fresh(withRelations: []);

        expect(freshAuthor.id, equals(author.id));
        expect(freshAuthor.relationLoaded('posts'), isFalse);
      });
    });

    group('use cases', () {
      test('use fresh() to preserve original while checking updates', () async {
        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
        final author = rows.first;

        // Simulate external update
        await dataSource.context.runMutation(
          MutationPlan.update(
            definition: AuthorOrmDefinition.definition,
            rows: [
              MutationRow(values: {'name': 'New Name'}, keys: {'id': 1}),
            ],
            driverName: dataSource.connection.driver.metadata.name,
          ),
        );

        // Get fresh to compare with original
        final freshAuthor = await author.fresh();

        // Compare old and new values
        final hasChanged = author.name != freshAuthor.name;
        expect(hasChanged, isTrue);

        // Original still has old value for reference
        expect(author.name, equals('Alice'));
      });

      test('use fresh() when needing immutable reference', () async {
        final rows = await dataSource.context
            .query<Author>()
            .withRelation('posts')
            .where('id', 1)
            .get();
        final originalAuthor = rows.first;

        // Get a fresh copy with relations for further processing
        final workingCopy = await originalAuthor.fresh(
          withRelations: ['posts'],
        );

        // Modify the working copy's cache (for example)
        workingCopy.clearRelations();
        expect(workingCopy.relationLoaded('posts'), isFalse);

        // Original should be unaffected
        expect(originalAuthor.relationLoaded('posts'), isTrue);
        expect(originalAuthor.posts, hasLength(2));
      });
    });
  });
}
