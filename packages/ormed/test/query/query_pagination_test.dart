import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  ModelRegistry registry = bootstrapOrm();
  late InMemoryQueryExecutor executor;
  late QueryContext context;

  setUp(() {
    executor = InMemoryQueryExecutor();

    executor.register(AuthorOrmDefinition.definition, const [
      Author(id: 1, name: 'Alice', active: true),
      Author(id: 2, name: 'Bob', active: true),
    ]);

    executor.register(PostOrmDefinition.definition, [
      Post(
        id: 1,
        authorId: 1,
        title: 'Welcome',
        publishedAt: DateTime.utc(2024, 1, 1),
      ),
      Post(
        id: 2,
        authorId: 1,
        title: 'Second',
        publishedAt: DateTime.utc(2024, 2, 1),
      ),
      Post(
        id: 3,
        authorId: 2,
        title: 'Intro',
        publishedAt: DateTime.utc(2024, 3, 15),
      ),
    ]);

    context = QueryContext(registry: registry, driver: executor);
  });

  group('pagination helpers', () {
    test('paginate returns metadata and eager loads relations', () async {
      final result = await context
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

      final firstAuthor = result.items.first.relation<Author>('author');
      expect(firstAuthor?.name, 'Alice');

      final titles = result.models.map((post) => post.title).toList();
      expect(titles, ['Welcome', 'Second']);
    });

    test('simplePaginate toggles hasMorePages correctly', () async {
      final first = await context
          .query<Post>()
          .orderBy('id')
          .simplePaginate(perPage: 2, page: 1);

      expect(first.items, hasLength(2));
      expect(first.hasMorePages, isTrue);
      expect(first.currentPage, 1);

      final second = await context
          .query<Post>()
          .orderBy('id')
          .simplePaginate(perPage: 2, page: 2);

      expect(second.items, hasLength(1));
      expect(second.hasMorePages, isFalse);
      expect(second.currentPage, 2);
    });

    test('cursorPaginate resumes from the provided cursor', () async {
      final first = await context.query<Post>().cursorPaginate(
        perPage: 2,
        column: 'id',
      );

      expect(first.items.map((row) => row.model.id).toList(), [1, 2]);
      expect(first.hasMore, isTrue);
      expect(first.nextCursor, 2);

      final second = await context.query<Post>().cursorPaginate(
        perPage: 2,
        column: 'id',
        cursor: first.nextCursor,
      );

      expect(second.items.map((row) => row.model.id).toList(), [3]);
      expect(second.hasMore, isFalse);
      expect(second.nextCursor, isNull);
    });
  });

  group('chunk helpers', () {
    test('chunk stops processing when callback returns false', () async {
      final processed = <int>[];

      await context.query<Post>().orderBy('id').chunk(1, (rows) {
        processed.add(rows.single.model.id);
        return processed.length < 2; // halt after processing id 2
      });

      expect(processed, [1, 2]);
    });

    test('chunkById iterates rows in ascending order', () async {
      final batches = <List<int>>[];

      await context.query<Post>().chunkById(2, (rows) {
        batches.add(rows.map((row) => row.model.id).toList());
        return true;
      });

      expect(batches, [
        [1, 2],
        [3],
      ]);
    });

    test('eachById stops iteration when callback returns false', () async {
      final visited = <int>[];

      await context.query<Post>().eachById(1, (row) {
        visited.add(row.model.id);
        return row.model.id < 2;
      });

      expect(visited, [1, 2]);
    });
  });
}
