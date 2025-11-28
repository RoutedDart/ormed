import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';
import '../config.dart';
import '../harness/driver_test_harness.dart';
import '../seed_data.dart';

void runDriverQueryTests({
  required DriverHarnessBuilder<DriverTestHarness> createHarness,
  required DriverTestConfig config,
}) {
  group('${config.driverName} queries', () {
    late DriverTestHarness harness;
    late List<User> seededUsers; // Declare to store generated users
    void expectPreviewMetadata(StatementPreview preview) {
      final normalized = preview.normalized;
      expect(normalized.command, isNotEmpty);
      expect(normalized.type, isIn(['sql', 'document']));
      expect(normalized.arguments, isNotNull);
      expect(normalized.parameters, isNotNull);
    }

    setUp(() async {
      harness = await createHarness();
      seededUsers = buildDefaultUsers(
        suffix: 'fixed',
      ); // Generate users with fixed suffix
      await seedGraph(
        harness,
        users: seededUsers,
      ); // Pass generated users to seedGraph
    });

    tearDown(() async => harness.dispose());

    test('supports filtering, ordering, and pagination', () async {
      final expectedUser = seededUsers.where((user) => user.active).toList()
        ..sort((a, b) => b.email.compareTo(a.email));

      final rows = await harness.context
          .query<User>()
          .whereEquals('active', true)
          .orderBy('email', descending: true)
          .limit(1)
          .rows();
      expect(rows.single.model.email, expectedUser.first.email);
    });

    test('exposes statement previews for queries', () async {
      final preview = harness.context
          .query<User>()
          .whereEquals('active', true)
          .orderBy('email')
          .limit(1)
          .toSql();

      expectPreviewMetadata(preview);
    });

    test('emits query events with metadata', () async {
      final events = <QueryEvent>[];
      harness.context.onQuery(events.add);

      await harness.context.query<User>().whereEquals('id', 1).first();

      expect(events, hasLength(1));
      final event = events.single;
      expect(event.rows, 1);
      expectPreviewMetadata(event.preview);
      expect(event.duration, greaterThan(Duration.zero));
      expect(event.succeeded, isTrue);
    });

    test('records query errors in events', () async {
      // Skip for MongoDB since it doesn't support raw SQL
      if (config.driverName.toLowerCase().contains('mongo')) {
        return;
      }
      
      final events = <QueryEvent>[];
      harness.context.onQuery(events.add);
      await harness.adapter.executeRaw('DROP TABLE users');

      await expectLater(
        () => harness.context.query<User>().get(),
        throwsA(isA<Exception>()),
      );

      expect(events, hasLength(1));
      expect(events.single.error, isNotNull);
      expect(events.single.succeeded, isFalse);
    });

    test('threadCount reports driver metric', () async {
      final count = await harness.context.threadCount();
      if (config.supportsCapability(DriverCapability.threadCount)) {
        expect(count, isNotNull);
        expect(count, greaterThanOrEqualTo(1));
      } else {
        expect(count, isNull);
      }
    });

    test('union combines results from separate queries', () async {
      final users = await harness.context
          .query<User>()
          .whereEquals('active', true)
          .union(harness.context.query<User>().whereEquals('active', false))
          .get();

      final ids = users.map((u) => u.id).toList()..sort();
      expect(ids, equals([1, 2, 3]));
    });

    test('date helpers filter by calendar components', () async {
      final posts = await harness.context
          .query<Post>()
          .whereYear('publishedAt', 2024)
          .whereMonth('publishedAt', 2)
          .get();

      expect(posts.map((p) => p.id), equals([2]));

      final exact = await harness.context
          .query<Post>()
          .whereDate('publishedAt', DateTime.utc(2024, 1, 1))
          .first();

      expect(exact?.id, 1);
    });

    if (config.supportsAdvancedQueryBuilders) {
      test('time helpers compare HH:mm:ss fragments', () async {
        final timeQuery = harness.context.query<Post>().whereTime(
          'publishedAt',
          '08:30:00',
        );
        final preview = timeQuery.toSql();
        expectPreviewMetadata(preview);

        if (config.driverName != 'MySqlDriverAdapter') {
          final match = await timeQuery.first();
          expect(match?.id, 2);
        }

        final dayMatches = await harness.context
            .query<Post>()
            .whereDay('publishedAt', 12)
            .orderBy('id')
            .get();

        expect(dayMatches.map((post) => post.id), equals([3]));
      });
    }

    test('eager loads hasMany relations', () async {
      final rows = await harness.context
          .query<Author>()
          .withRelation('posts')
          .orderBy('id')
          .rows();

      final posts = rows.first.relationList<Post>('posts');
      expect(posts.map((p) => p.title), containsAll(['Welcome', 'Second']));
    });

    test('eager loads belongsTo relations', () async {
      final post = await harness.context
          .query<Post>()
          .whereEquals('title', 'Intro')
          .withRelation('author')
          .firstRow();

      expect(post?.relation<Author>('author')?.name, 'Bob');
    });

    test('eager loads manyToMany relations', () async {
      final post = await harness.context
          .query<Post>()
          .whereEquals('id', 1)
          .withRelation('tags')
          .firstRow();

      final tags = post!.relationList<Tag>('tags');
      expect(tags.map((t) => t.label), containsAll(['featured']));
    });

    test('eager loads morphMany relations', () async {
      final post = await harness.context
          .query<Post>()
          .whereEquals('id', 1)
          .withRelation('photos')
          .firstRow();

      final photos = post!.relationList<Photo>('photos');
      expect(photos.map((p) => p.path), containsAll(['hero.jpg', 'thumb.jpg']));
    });

    test('eager loads morphOne relations', () async {
      final image = await harness.context
          .query<Image>()
          .whereEquals('id', 101)
          .withRelation('primaryPhoto')
          .firstRow();

      expect(image?.relation<Photo>('primaryPhoto')?.path, 'cover.jpg');
    });

    test('describes nested orderByRelation preview for morph paths', () {
      final preview = harness.context
          .query<Author>()
          .orderByRelation('posts.photos', descending: true)
          .limit(1)
          .toSql();

      expectPreviewMetadata(preview);
    });

    test('withExists builds nested EXISTS preview for morph paths', () {
      final preview = harness.context
          .query<Author>()
          .withExists('posts.photos', alias: 'has_photos')
          .limit(1)
          .toSql();

      expectPreviewMetadata(preview);
    });

    test(
      'orderByRelation distinct preview metadata for nested pivot paths',
      () {
        final preview = harness.context
            .query<Author>()
            .orderByRelation('posts.tags', distinct: true)
            .limit(1)
            .toSql();

        expectPreviewMetadata(preview);
      },
    );

    if (config.supportsAdvancedQueryBuilders) {
      group('predicate AST support', () {
        test('applies nested boolean groups and advanced operators', () async {
          final rows = await harness.context
              .query<Post>()
              .where((outer) {
                outer
                  ..where('authorId', 1)
                  ..orWhere((inner) => inner.whereBetween('id', 2, 3));
              })
              .whereNotIn('id', [1])
              .orderBy('id')
              .rows();

          expect(rows.map((row) => row.model.id), equals([2, 3]));
        });

        test(
          'handles raw predicates and case-insensitive like comparisons',
          () async {
            final rows = await harness.context
                .query<Post>()
                .whereRaw('substr(title, 1, 1) = ?', ['I'])
                .orWhere((builder) {
                  if (config.supportsCaseInsensitiveLike) {
                    builder.whereILike('title', 'wel%');
                  } else {
                    builder.whereLike('title', 'Wel%');
                  }
                })
                .orderBy('id')
                .rows();

            expect(
              rows.map((row) => row.model.title),
              equals(['Welcome', 'Intro']),
            );
          },
        );
      });

      group('projection metadata', () {
        test('exposes preview metadata for aggregates and raw selects', () {
          final preview = harness.context
              .query<Post>()
              .select(['authorId'])
              .selectRaw(
                'strftime(?, published_at)',
                alias: 'published_year',
                bindings: ['%Y'],
              )
              .countAggregate(expression: '*', alias: 'total_posts')
              .groupBy(['authorId'])
              .having('authorId', PredicateOperator.greaterThan, 0)
              .havingBitwise('authorId', '&', 1)
              .havingRaw('COUNT(*) > ?', [1])
              .orderBy('authorId')
              .toSql();

          expectPreviewMetadata(preview);
        });
      });

      group('relation helpers', () {
        test('filters parents via whereHas constraints', () async {
          final ids = await harness.context
              .query<Author>()
              .whereHas('posts', (posts) => posts.where('title', 'Welcome'))
              .orderBy('id')
              .get()
              .then((authors) => authors.map((a) => a.id).toList());

          expect(ids, equals([1]));
        });

        test('supports withCount and exposes alias in rows', () async {
          final rows = await harness.context
              .query<Author>()
              .withCount('posts')
              .orderBy('id')
              .rows();

          expect(rows[0].row['posts_count'], 2);
          expect(rows[1].row['posts_count'], 1);
        });

        test('supports nested withCount over morph relations', () async {
          final rows = await harness.context
              .query<Author>()
              .withCount('posts.photos')
              .orderBy('id')
              .rows();

          expect(rows[0].row['posts_photos_count'], 2);
          expect(rows[1].row['posts_photos_count'], 1);
        });

        test(
          'withCount preserves multiplicity for nested pivot paths',
          () async {
            final rows = await harness.context
                .query<Author>()
                .withCount('posts.tags')
                .orderBy('id')
                .rows();

            expect(rows[0].row['posts_tags_count'], 3);
            expect(rows[1].row['posts_tags_count'], 1);
          },
        );

        test('distinct withCount collapses duplicate pivot rows', () async {
          final rows = await harness.context
              .query<Author>()
              .withCount('posts.tags', distinct: true)
              .orderBy('id')
              .rows();

          expect(rows[0].row['posts_tags_count'], 2);
          expect(rows[1].row['posts_tags_count'], 1);
        });

        test('filters parents via nested morph whereHas constraints', () async {
          final ids = await harness.context
              .query<Author>()
              .whereHas(
                'posts.photos',
                (photos) => photos.where('path', 'hero.jpg'),
              )
              .orderBy('id')
              .get()
              .then((authors) => authors.map((a) => a.id).toList());

          expect(ids, equals([1]));
        });

        test('orders by relation aggregate', () async {
          final authors = await harness.context
              .query<Author>()
              .orderByRelation('posts', descending: true)
              .get();

          expect(authors.first.id, 1);
          expect(authors.last.id, 2);
        });
      });

      group('pagination and chunking', () {
        test('paginate returns metadata and eager loads relations', () async {
          final result = await harness.context
              .query<Post>()
              .withRelation('author')
              .orderBy('id')
              .paginate(perPage: 2, page: 1);

          expect(result.total, 3);
          expect(result.perPage, 2);
          expect(result.currentPage, 1);
          expect(result.lastPage, 2);
          expect(result.hasMorePages, isTrue);
          expect(result.items, hasLength(2));
          expect(result.items.first.relation<Author>('author')?.name, 'Alice');
        });

        test('simplePaginate and cursorPaginate advance windows', () async {
          final simple = await harness.context
              .query<Post>()
              .orderBy('id')
              .simplePaginate(perPage: 2, page: 1);
          expect(simple.items, hasLength(2));
          expect(simple.hasMorePages, isTrue);

          final simpleTail = await harness.context
              .query<Post>()
              .orderBy('id')
              .simplePaginate(perPage: 2, page: 2);
          expect(simpleTail.items, hasLength(1));
          expect(simpleTail.hasMorePages, isFalse);

          final firstCursor = await harness.context
              .query<Post>()
              .cursorPaginate(perPage: 2, column: 'id');
          expect(firstCursor.items.map((row) => row.model.id), equals([1, 2]));
          expect(firstCursor.hasMore, isTrue);
          expect(firstCursor.nextCursor, 2);

          final secondCursor = await harness.context
              .query<Post>()
              .cursorPaginate(
                perPage: 2,
                column: 'id',
                cursor: firstCursor.nextCursor,
              );
          expect(secondCursor.items.map((row) => row.model.id), equals([3]));
          expect(secondCursor.hasMore, isFalse);
          expect(secondCursor.nextCursor, isNull);
        });

        test('chunk helpers iterate deterministically', () async {
          final visited = <int>[];
          await harness.context.query<Post>().chunk(1, (rows) {
            visited.add(rows.single.model.id);
            return visited.length < 2;
          });
          expect(visited, equals([1, 2]));

          final batches = <List<int>>[];
          await harness.context.query<Post>().chunkById(2, (rows) {
            batches.add(rows.map((row) => row.model.id).toList());
            return true;
          });
          expect(
            batches,
            equals([
              [1, 2],
              [3],
            ]),
          );

          final eachVisited = <int>[];
          await harness.context.query<Post>().eachById(1, (row) {
            eachVisited.add(row.model.id);
            return row.model.id < 2;
          });
          expect(eachVisited, equals([1, 2]));
        });
      });
      group('soft deletes', () {
        test('withTrashed and onlyTrashed toggle the default scope', () async {
          final scoped = await harness.context.query<Comment>().get();
          expect(scoped.single.body, 'Visible');

          final all = await harness.context
              .query<Comment>()
              .withTrashed()
              .get();
          expect(all.map((c) => c.body), containsAll(['Visible', 'Hidden']));

          final trashed = await harness.context
              .query<Comment>()
              .onlyTrashed()
              .get();
          expect(trashed.single.body, 'Hidden');
        });

        test('restore clears deleted_at for matching rows', () async {
          final affected = await harness.context
              .query<Comment>()
              .whereEquals('id', 2)
              .restore();

          expect(affected, 1);
          final rows = await harness.context
              .query<Comment>()
              .withTrashed()
              .orderBy('id')
              .get();
          expect(rows.map((c) => c.deletedAt), everyElement(isNull));
        });

        test('forceDelete removes rows regardless of scope', () async {
          final affected = await harness.context
              .query<Comment>()
              .withTrashed()
              .whereEquals('id', 1)
              .forceDelete();

          expect(affected, 1);
          final remaining = await harness.context
              .query<Comment>()
              .withTrashed()
              .get();
          expect(remaining.single.id, 2);
        });

        test('forceDelete honors order and limit clauses', () async {
          final affected = await harness.context
              .query<Comment>()
              .withTrashed()
              .orderBy('id', descending: true)
              .limit(1)
              .forceDelete();

          expect(affected, 1);
          final rows = await harness.context
              .query<Comment>()
              .withTrashed()
              .orderBy('id')
              .get();
          expect(rows.map((c) => c.id), equals([1]));
        }, skip: !config.supportsCapability(DriverCapability.queryDeletes));
      });

      group('json predicates', () {
        Future<void> seedDriverSettings() =>
            harness.context.repository<DriverOverrideEntry>().insertMany(const [
              DriverOverrideEntry(
                id: 1,
                payload: {
                  'mode': 'dark',
                  'featured': true,
                  'tags': ['alpha', 'beta'],
                  'meta': {
                    'author': {'name': 'Alicia'},
                  },
                },
              ),
              DriverOverrideEntry(
                id: 2,
                payload: {
                  'mode': 'light',
                  'featured': false,
                  'tags': ['gamma'],
                },
              ),
            ]);

        test('whereJsonContains filters JSON arrays', () async {
          await seedDriverSettings();

          final results = await harness.context
              .query<DriverOverrideEntry>()
              .whereJsonContains('payload->tags', ['beta'])
              .get();

          expect(results.map((entry) => entry.id), [1]);
        });

        test('whereJsonContainsKey matches nested paths', () async {
          await seedDriverSettings();

          final results = await harness.context
              .query<DriverOverrideEntry>()
              .whereJsonContainsKey('payload', 'meta.author.name')
              .get();

          expect(results.map((entry) => entry.id), [1]);
        });

        test('whereJsonLength compares array lengths', () async {
          await seedDriverSettings();

          final results = await harness.context
              .query<DriverOverrideEntry>()
              .whereJsonLength('payload->tags', '>=', 2)
              .get();

          expect(results.map((entry) => entry.id), [1]);
        });

        test('whereJsonOverlaps matches any overlapping array value', () async {
          await seedDriverSettings();

          final results = await harness.context
              .query<DriverOverrideEntry>()
              .whereJsonOverlaps('payload->tags', ['beta', 'delta'])
              .get();

          expect(results.map((entry) => entry.id), [1]);
        });

        test('json selectors compare boolean payload fragments', () async {
          await seedDriverSettings();

          final featured = await harness.context
              .query<DriverOverrideEntry>()
              .where('payload->featured', true)
              .get();

          expect(featured.map((entry) => entry.id), [1]);

          final hidden = await harness.context
              .query<DriverOverrideEntry>()
              .where('payload->featured', false)
              .get();

          expect(hidden.map((entry) => entry.id), [2]);
        });
      });

      test('limitPerGroup returns the latest post per author', () async {
        final posts = await harness.context
            .query<Post>()
            .orderBy('publishedAt', descending: true)
            .limitPerGroup(1, 'authorId')
            .get();

        expect(posts, hasLength(2));
        expect(posts.map((post) => post.id).toSet(), {2, 3});
      });
    }
  });
}
