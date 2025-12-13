import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';
import '../seed_data.dart';

void runDriverJoinTests() {
  ormedGroup('manual joins', (dataSource) {
    final metadata = dataSource.options.driver.metadata;
    if (!metadata.supportsCapability(DriverCapability.joins)) {
      return;
    }
    setUp(() async {
      // Seed data directly via repository
      await dataSource.repo<User>().insertMany(buildDefaultUsers());
      await dataSource.repo<Author>().insertMany(defaultAuthors.toList());
      await dataSource.repo<Post>().insertMany(buildDefaultPosts());
      await dataSource.repo<Tag>().insertMany(defaultTags.toList());
      await dataSource.repo<PostTag>().insertMany(defaultPostTags.toList());
      await dataSource.repo<Image>().insertMany(defaultImages.toList());
      await dataSource.repo<Photo>().insertMany(defaultPhotos.toList());
      await dataSource.context.query<Comment>().createMany(defaultComments);
    });

    test('inner join hydrates related rows', () async {
      final rows = await dataSource.context
          .query<Post>()
          .selectRaw('posts.id AS id')
          .selectRaw('posts.author_id AS author_id')
          .selectRaw('posts.title AS title')
          .selectRaw('posts.published_at AS published_at')
          .join('authors', 'authors.id', '=', 'posts.author_id')
          .selectRaw('authors.name AS author_name')
          .orderBy('title')
          .rows();

      expect(rows, hasLength(3));
      final names = rows.map((row) => row.row['author_name']).toList();
      expect(names, contains('Alice'));
      expect(names, contains('Bob'));
    });

    test('join builder supports additional constraints', () async {
      final preview = dataSource.context.query<Post>().join('authors', (join) {
        join.on('authors.id', '=', 'posts.author_id');
        join.where('authors.name', 'Alice');
      }).toSql();

      expect(preview.sql.toUpperCase(), contains('JOIN'));
      expect(
        preview.parameters,
        contains('Alice'),
        reason: 'closure-based where should bind literal values',
      );
    });

    test('joinRelation exposes relation aliases for selects', () async {
      final rows = await dataSource.context
          .query<Author>()
          .selectRaw('authors.id AS id')
          .selectRaw('authors.name AS name')
          .joinRelation('posts')
          .selectRaw('rel_posts_0.title AS post_title')
          .orderBy('name')
          .rows();

      final titles = rows
          .map((row) => row.row['post_title'])
          .whereType<String>();
      expect(titles, contains('Welcome'));
    });

    test('joinSub merges aggregation results', () async {
      final postCounts = dataSource.context
          .query<Post>()
          .selectRaw('author_id')
          .selectRaw('COUNT(*) AS total_posts')
          .groupBy(['author_id']);

      final rows = await dataSource.context
          .query<Author>()
          .selectRaw('authors.id AS id')
          .selectRaw('authors.name AS name')
          .joinSub(
            postCounts,
            'post_counts',
            'post_counts.author_id',
            '=',
            'authors.id',
          )
          .selectRaw('post_counts.total_posts AS total_posts')
          .orderBy('name')
          .rows();

      expect(rows.first.row['total_posts'], 2);
      expect(rows.last.row['total_posts'], 1);
    });
  });
}
