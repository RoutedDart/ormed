import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

void runRelationMutationTests(
  DriverHarnessBuilder<DriverTestHarness> createHarness,
  DriverTestConfig config,
) {
  group('${config.driverName} relation mutations', () {
    late DriverTestHarness harness;

    setUp(() async {
      harness = await createHarness();

      // Bind connection resolver for Model methods
      Model.bindConnectionResolver(
        resolveConnection: (name) => harness.context,
      );
    });

    tearDown(() async {
      Model.unbindConnectionResolver();
      await harness.dispose();
    });

    group('setRelation / unsetRelation / clearRelations', () {
      test('setRelation caches a relation and marks it loaded', () async {
        await harness.seedAuthors([const Author(id: 1, name: 'Alice')]);
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        final author = const Author(id: 1, name: 'Alice');
        post.setRelation('author', author);

        expect(post.relationLoaded('author'), isTrue);
        expect(post.getRelation<Author>('author'), equals(author));
      });

      test('unsetRelation removes from cache and marks unloaded', () async {
        await harness.seedAuthors([const Author(id: 1, name: 'Alice')]);
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        final author = const Author(id: 1, name: 'Alice');
        post.setRelation('author', author);
        expect(post.relationLoaded('author'), isTrue);

        post.unsetRelation('author');

        expect(post.relationLoaded('author'), isFalse);
        expect(post.getRelation<Author>('author'), isNull);
      });

      test('clearRelations removes all cached relations', () async {
        await harness.seedAuthors([const Author(id: 1, name: 'Alice')]);
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await harness.seedTags([const Tag(id: 1, label: 'dart')]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        post.setRelation('author', const Author(id: 1, name: 'Alice'));
        post.setRelation('tags', [const Tag(id: 1, label: 'dart')]);

        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isTrue);

        post.clearRelations();

        expect(post.relationLoaded('author'), isFalse);
        expect(post.relationLoaded('tags'), isFalse);
        expect(post.loadedRelationNames, isEmpty);
      });
    });

    group('associate() - belongsTo', () {
      test('associates parent and updates foreign key', () async {
        await harness.seedAuthors([const Author(id: 5, name: 'Alice')]);
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 999,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        final author = const Author(id: 5, name: 'Alice');
        await post.associate('author', author);

        // Check foreign key was updated
        expect(post.getAttribute<int>('author_id'), equals(5));

        // Check relation is cached
        expect(post.relationLoaded('author'), isTrue);
        expect(post.getRelation<Author>('author'), equals(author));
      });

      test('throws ArgumentError for invalid relation name', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        expect(
          () => post.associate('invalid', const Author(id: 1, name: 'Test')),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for non-belongsTo relation', () async {
        await harness.seedAuthors([const Author(id: 1, name: 'Alice')]);

        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;

        // 'posts' is hasMany, not belongsTo
        expect(
          () => author.associate(
            'posts',
            Post(
              id: 1,
              authorId: 1,
              title: 'Post',
              publishedAt: DateTime(2024),
            ),
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('belongsTo'),
            ),
          ),
        );
      });

      test('returns self for method chaining', () async {
        await harness.seedAuthors([const Author(id: 1, name: 'Alice')]);
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 999,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        final result = await post.associate(
          'author',
          const Author(id: 1, name: 'Alice'),
        );

        expect(identical(result, post), isTrue);
      });
    });

    group('dissociate() - belongsTo', () {
      test('dissociates parent and nullifies foreign key', () async {
        await harness.seedAuthors([const Author(id: 1, name: 'Alice')]);
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        // First associate
        post.setRelation('author', const Author(id: 1, name: 'Alice'));
        post.setAttribute('author_id', 1);

        // Then dissociate
        await post.dissociate('author');

        // Check foreign key was nullified
        expect(post.getAttribute<int?>('author_id'), isNull);

        // Check relation is removed from cache
        expect(post.relationLoaded('author'), isFalse);
        expect(post.getRelation<Author>('author'), isNull);
      });

      test('throws ArgumentError for invalid relation name', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        expect(() => post.dissociate('invalid'), throwsArgumentError);
      });

      test('throws ArgumentError for non-belongsTo relation', () async {
        await harness.seedAuthors([const Author(id: 1, name: 'Alice')]);

        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;

        expect(
          () => author.dissociate('posts'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('belongsTo'),
            ),
          ),
        );
      });

      test('returns self for method chaining', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        final result = await post.dissociate('author');

        expect(identical(result, post), isTrue);
      });
    });

    group('attach() - manyToMany', () {
      test('attaches related models and creates pivot records', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await harness.seedTags([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        await post.attach('tags', [1, 2, 3]);

        // Verify pivot records were created
        final pivotRecords = await harness.context.driver.queryRaw(
          'SELECT * FROM post_tags WHERE post_id = ?',
          [1],
        );

        expect(pivotRecords, hasLength(3));
        expect(pivotRecords.any((r) => r['tag_id'] == 1), isTrue);
        expect(pivotRecords.any((r) => r['tag_id'] == 2), isTrue);
        expect(pivotRecords.any((r) => r['tag_id'] == 3), isTrue);
      });

      test('attach with empty list does nothing', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        await post.attach('tags', []);

        final pivotRecords = await harness.context.driver.queryRaw(
          'SELECT * FROM post_tags WHERE post_id = ?',
          [1],
        );

        expect(pivotRecords, isEmpty);
      });

      test('throws ArgumentError for invalid relation name', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        expect(() => post.attach('invalid', [1, 2]), throwsArgumentError);
      });

      test('throws ArgumentError for non-manyToMany relation', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        expect(
          () => post.attach('author', [1]),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('manyToMany'),
            ),
          ),
        );
      });

      test('returns self for method chaining', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await harness.seedTags([const Tag(id: 1, label: 'dart')]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        final result = await post.attach('tags', [1]);

        expect(identical(result, post), isTrue);
      });
    });

    group('detach() - manyToMany', () {
      test('detaches specific related models', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await harness.seedTags([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);
        await harness.seedPostTags([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
          const PostTag(postId: 1, tagId: 3),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        // Detach tags 1 and 2
        await post.detach('tags', [1, 2]);

        final pivotRecords = await harness.context.driver.queryRaw(
          'SELECT * FROM post_tags WHERE post_id = ?',
          [1],
        );

        expect(pivotRecords, hasLength(1));
        expect(pivotRecords.first['tag_id'], equals(3));
      });

      test('detaches all related models when no IDs provided', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await harness.seedTags([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
        ]);
        await harness.seedPostTags([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        await post.detach('tags');

        final pivotRecords = await harness.context.driver.queryRaw(
          'SELECT * FROM post_tags WHERE post_id = ?',
          [1],
        );

        expect(pivotRecords, isEmpty);
      });

      test('detach with empty list detaches all', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await harness.seedTags([const Tag(id: 1, label: 'dart')]);
        await harness.seedPostTags([const PostTag(postId: 1, tagId: 1)]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        await post.detach('tags', []);

        final pivotRecords = await harness.context.driver.queryRaw(
          'SELECT * FROM post_tags WHERE post_id = ?',
          [1],
        );

        expect(pivotRecords, isEmpty);
      });

      test('throws ArgumentError for invalid relation name', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        expect(() => post.detach('invalid'), throwsArgumentError);
      });

      test('throws ArgumentError for non-manyToMany relation', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        expect(
          () => post.detach('author'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('manyToMany'),
            ),
          ),
        );
      });

      test('returns self for method chaining', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        final result = await post.detach('tags');

        expect(identical(result, post), isTrue);
      });
    });

    group('sync() - manyToMany', () {
      test('syncs to match given IDs exactly', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await harness.seedTags([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
          const Tag(id: 4, label: 'mobile'),
        ]);
        await harness.seedPostTags([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
          const PostTag(postId: 1, tagId: 3),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        // Currently has tags 1, 2, 3
        // Sync to have tags 2, 3, 4
        await post.sync('tags', [2, 3, 4]);

        final pivotRecords = await harness.context.driver.queryRaw(
          'SELECT tag_id FROM post_tags WHERE post_id = ? ORDER BY tag_id',
          [1],
        );

        expect(pivotRecords, hasLength(3));
        expect(pivotRecords[0]['tag_id'], equals(2));
        expect(pivotRecords[1]['tag_id'], equals(3));
        expect(pivotRecords[2]['tag_id'], equals(4));
      });

      test('sync with empty list removes all', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await harness.seedTags([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
        ]);
        await harness.seedPostTags([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        await post.sync('tags', []);

        final pivotRecords = await harness.context.driver.queryRaw(
          'SELECT * FROM post_tags WHERE post_id = ?',
          [1],
        );

        expect(pivotRecords, isEmpty);
      });

      test('sync replaces all existing with new IDs', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await harness.seedTags([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);
        await harness.seedPostTags([const PostTag(postId: 1, tagId: 1)]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        await post.sync('tags', [2, 3]);

        final pivotRecords = await harness.context.driver.queryRaw(
          'SELECT tag_id FROM post_tags WHERE post_id = ? ORDER BY tag_id',
          [1],
        );

        expect(pivotRecords, hasLength(2));
        expect(pivotRecords[0]['tag_id'], equals(2));
        expect(pivotRecords[1]['tag_id'], equals(3));
      });

      test('returns self for method chaining', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await harness.seedTags([const Tag(id: 1, label: 'dart')]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        final result = await post.sync('tags', [1]);

        expect(identical(result, post), isTrue);
      });
    });

    group('Method chaining with mutations', () {
      test('can chain associate with other operations', () async {
        await harness.seedAuthors([const Author(id: 1, name: 'Alice')]);
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 999,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        final author = const Author(id: 1, name: 'Alice');
        final result = await post.associate('author', author);

        expect(identical(result, post), isTrue);
        expect(post.getAttribute<int>('author_id'), equals(1));
      });

      test('can chain attach, sync operations', () async {
        await harness.seedPosts([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await harness.seedTags([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);

        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;

        await post.attach('tags', [1, 2]).then((p) => p.sync('tags', [2, 3]));

        final pivotRecords = await harness.context.driver.queryRaw(
          'SELECT tag_id FROM post_tags WHERE post_id = ? ORDER BY tag_id',
          [1],
        );

        expect(pivotRecords, hasLength(2));
        expect(pivotRecords[0]['tag_id'], equals(2));
        expect(pivotRecords[1]['tag_id'], equals(3));
      });
    });
  });
}
