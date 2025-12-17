import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

void runRelationMutationTests() {
  ormedGroup('relation mutations', (scopedDataSource) {
    final dataSource = scopedDataSource;
    setUp(() async {
      // Bind connection resolver for Model methods
      Model.bindConnectionResolver(
        resolveConnection: (name) => dataSource.context,
      );
    });

    tearDown(() async {
      Model.unbindConnectionResolver();
    });

    group('setRelation / unsetRelation / clearRelations', () {
      test('setRelation caches relation and marks loaded', () async {
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
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final author = const Author(id: 1, name: 'Alice');
        post.setRelation('author', author);

        expect(post.relationLoaded('author'), isTrue);
        expect(post.getRelation<Author>('author'), equals(author));
      });

      test('unsetRelation removes cached relation', () async {
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
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final author = const Author(id: 1, name: 'Alice');
        post.setRelation('author', author);
        expect(post.relationLoaded('author'), isTrue);

        post.unsetRelation('author');

        expect(post.relationLoaded('author'), isFalse);
        expect(post.getRelation<Author>('author'), isNull);
      });

      test('clearRelations removes all cached relations', () async {
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
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
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
        await dataSource.repo<Author>().insertMany([
          const Author(id: 5, name: 'Alice'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 999,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final author = const Author(id: 5, name: 'Alice');
        await post.associate('author', author);

        // Check foreign key was updated
        expect(post.getAttribute<int>('author_id'), equals(5));

        // Check relation is cached
        expect(post.relationLoaded('author'), isTrue);
        expect(post.getRelation<Author>('author'), equals(author));
      });

      test('associate throws for unknown relation', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(
          () => post.associate('invalid', const Author(id: 1, name: 'Test')),
          throwsArgumentError,
        );
      });

      test('associate rejects non-belongsTo relation', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);

        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
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
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 999,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
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
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
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

      test('dissociate throws for invalid relation', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(() => post.dissociate('invalid'), throwsArgumentError);
      });

      test('dissociate rejects non-belongsTo relation', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);

        final rows = await dataSource.context
            .query<Author>()
            .where('id', 1)
            .get();
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
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final result = await post.dissociate('author');

        expect(identical(result, post), isTrue);
      });
    });

    group('relation cache after mutations', () {
      test('attach refreshes relation cache and loadMissing preserves cache',
          () async {
        await dataSource.repo<Author>().insertMany(const [
          Author(id: 1, name: 'Alice'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany(const [
          Tag(id: 1, label: 'dart'),
          Tag(id: 2, label: 'flutter'),
          Tag(id: 3, label: 'ormed'),
        ]);
        await dataSource.repo<PostTag>().insertMany(const [
          PostTag(postId: 1, tagId: 1),
        ]);

        final post =
            (await dataSource.context.query<Post>().where('id', 1).get()).first;

        await post.load('tags');
        expect(post.tags.map((t) => t.id), equals([1]));

        await post.attach('tags', [2, 3]);
        expect(post.tags.map((t) => t.id).toSet(), equals({1, 2, 3}));

        await post.loadMissing(['tags']);
        expect(post.tags.map((t) => t.id).toSet(), equals({1, 2, 3}));

        // If cache is cleared, loadMissing should query again.
        post.unsetRelation('tags');
        await post.loadMissing(['tags']);
        expect(post.tags.map((t) => t.id).toSet(), equals({1, 2, 3}));
      });

      test('associate caches belongsTo and loadMissing preserves cache', () async {
        await dataSource.repo<Author>().insertMany(const [
          Author(id: 1, name: 'Alice'),
          Author(id: 2, name: 'Bob'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final post =
            (await dataSource.context.query<Post>().where('id', 1).get()).first;

        await post.load('author');
        expect(post.author?.id, equals(1));

        await post.associate('author', const Author(id: 2, name: 'Bob'));
        expect(post.author?.id, equals(2));

        await post.loadMissing(['author']);
        expect(post.author?.id, equals(2));
      });
    });

    group('attach() - manyToMany', () {
      test('attach creates pivot rows for many-to-many', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.attach('tags', [1, 2, 3]);

        // Verify pivot records were created
        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, hasLength(3));
        expect(pivotRecords.any((r) => r.tagId == 1), isTrue);
        expect(pivotRecords.any((r) => r.tagId == 2), isTrue);
        expect(pivotRecords.any((r) => r.tagId == 3), isTrue);
      });

      test('attach with empty list does nothing', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.attach('tags', []);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, isEmpty);
      });

      test('attach throws for invalid relation name', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(() => post.attach('invalid', [1, 2]), throwsArgumentError);
      });

      test('attach rejects non many-to-many relations', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
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
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final result = await post.attach('tags', [1]);

        expect(identical(result, post), isTrue);
      });
    });

    group('detach() - manyToMany', () {
      test('detaches specific related models', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
          const PostTag(postId: 1, tagId: 3),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        // Detach tags 1 and 2
        await post.detach('tags', [1, 2]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, hasLength(1));
        expect(pivotRecords.first.tagId, equals(3));
      });

      test('detach removes all relations when ids omitted', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.detach('tags');

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, isEmpty);
      });

      test('detach with empty list detaches all', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.detach('tags', []);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, isEmpty);
      });

      test('detach throws for invalid relation', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        expect(() => post.detach('invalid'), throwsArgumentError);
      });

      test('detach rejects non many-to-many relations', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
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
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final result = await post.detach('tags');

        expect(identical(result, post), isTrue);
      });
    });

    group('sync() - manyToMany', () {
      test('syncs to match given IDs exactly', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
          const Tag(id: 4, label: 'mobile'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
          const PostTag(postId: 1, tagId: 3),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        // Currently has tags 1, 2, 3
        // Sync to have tags 2, 3, 4
        await post.sync('tags', [2, 3, 4]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .orderBy('tag_id')
            .get();

        expect(pivotRecords, hasLength(3));
        expect(pivotRecords[0].tagId, equals(2));
        expect(pivotRecords[1].tagId, equals(3));
        expect(pivotRecords[2].tagId, equals(4));
      });

      test('sync with empty list removes all', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.sync('tags', []);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .get();

        expect(pivotRecords, isEmpty);
      });

      test('sync replaces all existing with new IDs', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.sync('tags', [2, 3]);

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .orderBy('tag_id')
            .get();

        expect(pivotRecords, hasLength(2));
        expect(pivotRecords[0].tagId, equals(2));
        expect(pivotRecords[1].tagId, equals(3));
      });

      test('returns self for method chaining', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final result = await post.sync('tags', [1]);

        expect(identical(result, post), isTrue);
      });
    });

    group('Method chaining with mutations', () {
      test('can chain associate with other operations', () async {
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 999,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        final author = const Author(id: 1, name: 'Alice');
        final result = await post.associate('author', author);

        expect(identical(result, post), isTrue);
        expect(post.getAttribute<int>('author_id'), equals(1));
      });

      test('can chain attach, sync operations', () async {
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
          const Tag(id: 3, label: 'web'),
        ]);

        final rows = await dataSource.context
            .query<Post>()
            .where('id', 1)
            .get();
        final post = rows.first;

        await post.attach('tags', [1, 2]).then((p) => p.sync('tags', [2, 3]));

        final pivotRecords = await dataSource.context
            .query<PostTag>()
            .where('post_id', 1)
            .orderBy('tag_id')
            .get();

        expect(pivotRecords, hasLength(2));
        expect(pivotRecords[0].tagId, equals(2));
        expect(pivotRecords[1].tagId, equals(3));
      });
    });
  });
}
