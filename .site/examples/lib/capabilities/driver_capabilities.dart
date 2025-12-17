// Driver capabilities examples for documentation
// ignore_for_file: unused_local_variable, unused_element

import 'package:ormed/ormed.dart';

// These are placeholder types for the examples
class Post {}

class $Post extends Model<$Post> {
  const $Post();
  final int id = 0;
  final String title = '';
  final int views = 0;
}

class $Comment extends Model<$Comment> {
  const $Comment();
}

// #region capability-enum
// Ormed exposes a fixed set of driver capabilities:
//
// joins
// insertUsing
// queryDeletes
// schemaIntrospection
// returning
// transactions
// threadCount
// adHocQueryUpdates
// advancedQueryBuilders
// sqlPreviews
// increment
// rawSQL
// relationAggregates
// caseInsensitiveLike
// rightJoin
// distinctOn
// databaseManagement
// foreignKeyConstraintControl
// #endregion capability-enum

// #region check-capabilities
void checkCapabilitiesExample(QueryContext context) async {
  final adapter = context.driver;

  // Check single capability
  if (adapter.supportsCapability(DriverCapability.rawSQL)) {
    print('Can use raw SQL fragments');
  }

  // Check multiple capabilities
  final canDoComplexQuery =
      adapter.supportsCapability(DriverCapability.joins) &&
      adapter.supportsCapability(DriverCapability.rawSQL);

  // Get all supported capabilities
  final supported = adapter.capabilities;
  print('Driver supports: ${supported.map((c) => c.name).join(', ')}');
}
// #endregion check-capabilities

// #region capability-checks-strategy
Future<List<$Post>> getTopPostsWithCapabilityCheck(QueryContext context) async {
  var query = context.query<$Post>();

  if (context.driver.supportsCapability(DriverCapability.rawSQL)) {
    query = query.selectRaw(
      'posts.*, (SELECT COUNT(*) FROM comments WHERE post_id = posts.id) AS comment_count',
    );
  } else {
    // Prefer query builder fallbacks when raw SQL isn't supported.
    query = query.select(['id', 'title', 'views']);
  }

  return query.orderBy('created_at', descending: true).limit(10).get();
}
// #endregion capability-checks-strategy

// #region query-builder-vs-raw
Future<void> queryBuilderVsRaw(QueryContext context) async {
  // ✅ Works everywhere
  final posts1 = await context
      .query<$Post>()
      .whereEquals('status', 'published')
      .whereGreaterThan('views', 100)
      .orderBy('created_at', descending: true)
      .get();

  // ⚠️ Only works on SQL databases
  final posts2 = await context
      .query<$Post>()
      .whereRaw('status = ? AND views > ?', ['published', 100])
      .orderByRaw('created_at DESC')
      .get();
}
// #endregion query-builder-vs-raw

// #region feature-detection-strategy
abstract class SearchStrategy {
  Future<List<$Post>> search(QueryContext context, String term);
}

class SqlSearchStrategy implements SearchStrategy {
  @override
  Future<List<$Post>> search(QueryContext context, String term) async {
    return context
        .query<$Post>()
        .whereRaw('title LIKE ?', ['%$term%']) // requires rawSQL
        .orWhereRaw('content LIKE ?', ['%$term%'])
        .get();
  }
}

class BasicSearchStrategy implements SearchStrategy {
  @override
  Future<List<$Post>> search(QueryContext context, String term) async {
    return context
        .query<$Post>()
        .whereContains('title', term)
        .orWhereContains('content', term)
        .get();
  }
}

// #region feature-detection-strategy-select
SearchStrategy selectStrategy(QueryContext context) {
  return context.driver.supportsCapability(DriverCapability.rawSQL)
      ? SqlSearchStrategy()
      : BasicSearchStrategy();
}
// #endregion feature-detection-strategy-select
// #endregion feature-detection-strategy

// #region skip-incompatible-tests
void skipIncompatibleTestsExample(DriverAdapter adapter) {
  // test('raw expression in select', () async {
  //   final posts = await context.query<$Post>()
  //       .selectRaw('*, (SELECT COUNT(*) FROM comments WHERE post_id = posts.id) as count')
  //       .get();
  //
  //   expect(posts.first.getAttribute<int>('count'), greaterThan(0));
  // }, skip: !adapter.supportsCapability(DriverCapability.rawExpressions));
}
// #endregion skip-incompatible-tests

// #region conditional-migrations
class AddFullTextSearchMigration extends Migration {
  @override
  Future<void> up(SchemaBuilder schema) async {
    if (schema.driver.supportsCapability(DriverCapability.rawSQL)) {
      await schema.rawStatement(
        "CREATE VIRTUAL TABLE posts_fts USING fts5(title, content, content=posts);",
      );
    }
  }

  @override
  Future<void> down(SchemaBuilder schema) async {
    if (schema.driver.supportsCapability(DriverCapability.rawSQL)) {
      await schema.rawStatement('DROP TABLE IF EXISTS posts_fts');
    }
  }
}
// #endregion conditional-migrations

// #region best-practice-query-builder
void bestPracticeQueryBuilder(QueryContext context) {
  // ✅ Cross-database compatible
  context
      .query<$Post>()
      .whereEquals('status', 'published')
      .orderBy('created_at', descending: true);

  // ❌ SQL-specific
  context
      .query<$Post>()
      .whereRaw('status = ?', ['published'])
      .orderByRaw('created_at DESC');
}
// #endregion best-practice-query-builder

// #region best-practice-check-capabilities
Future<void> bestPracticeCheckCapabilities(
  DriverAdapter adapter,
  Query query,
) async {
  // ❌ Bad - assumes raw expressions work
  query.selectRaw('COUNT(*)');

  // ✅ Good - checks capability first
  if (adapter.supportsCapability(DriverCapability.rawExpressions)) {
    query.selectRaw('COUNT(*)');
  } else {
    query.withCount(['items']);
  }
}
// #endregion best-practice-check-capabilities

// #region document-driver-requirements
/// Performs full-text search on posts.
///
/// **Requirements:**
/// - Driver must support [DriverCapability.rawSQL]
Future<List<$Post>> fullTextSearch(DriverAdapter adapter, String term) async {
  if (!adapter.supportsCapability(DriverCapability.rawSQL)) {
    throw UnsupportedError('Full-text search requires raw SQL support');
  }
  // ... implementation
  return [];
}
// #endregion document-driver-requirements

// #region fallback-alternatives
Future<List<$Post>> getPostsWithStats(QueryContext context) async {
  if (context.driver.supportsCapability(DriverCapability.windowFunctions)) {
    return context
        .query<$Post>()
        .selectRaw('*, ROW_NUMBER() OVER (ORDER BY views DESC) as rank')
        .get();
  } else {
    // Fallback: compute rank in memory
    final posts = await context
        .query<$Post>()
        .orderBy('views', descending: true)
        .get();

    return posts.asMap().entries.map((entry) {
      final post = entry.value;
      post.setAttribute('rank', entry.key + 1);
      return post;
    }).toList();
  }
}

// #endregion fallback-alternatives
