# Driver Capabilities & Cross-Database Compatibility

Ormed supports multiple database drivers (SQLite, PostgreSQL, MySQL, MongoDB), but not all databases support the same features. The **Driver Capabilities** system allows you to query what features are available at runtime and handle differences gracefully.

## Overview

Different databases have varying levels of support for SQL features:

| Feature | SQLite | PostgreSQL | MySQL | MongoDB |
|---------|--------|------------|-------|---------|
| Raw SQL Expressions | ✅ | ✅ | ✅ | ❌ |
| Ad-hoc Updates/Deletes | ✅ | ✅ | ✅ | ❌ |
| Complex Joins | ✅ | ✅ | ✅ | ⚠️ Limited |
| Window Functions | ✅ 3.25+ | ✅ | ✅ 8.0+ | ❌ |
| Subqueries | ✅ | ✅ | ✅ | ⚠️ Limited |
| CTEs (WITH clause) | ✅ 3.8+ | ✅ | ✅ 8.0+ | ❌ |

**MongoDB Note:** MongoDB is a document database and doesn't use SQL. While Ormed provides a unified query builder API, some SQL-specific features aren't applicable or have different semantics in MongoDB.

---

## Checking Driver Capabilities

Every driver implements the `DriverCapability` enum to indicate supported features.

### Available Capabilities

```dart
enum DriverCapability {
  /// Driver supports raw SQL expressions in select, where, orderBy
  rawExpressions,
  
  /// Driver supports UPDATE/DELETE with WHERE clauses on arbitrary tables
  adHocQueryUpdates,
  
  /// Driver supports complex multi-table JOINs
  complexJoins,
  
  /// Driver supports window functions (ROW_NUMBER, RANK, etc.)
  windowFunctions,
  
  /// Driver supports Common Table Expressions (WITH clause)
  cte,
  
  /// Driver supports subqueries in WHERE/HAVING/SELECT
  subqueries,
}
```

### Checking Capabilities at Runtime

```dart
import 'package:ormed/ormed.dart';

void main() async {
  final adapter = SqliteAdapter(/* ... */);
  
  // Check single capability
  if (adapter.supportsCapability(DriverCapability.rawExpressions)) {
    print('Can use DB.raw()');
  }
  
  // Check multiple capabilities
  final canDoComplexQuery = adapter.supportsCapability(DriverCapability.complexJoins) &&
                            adapter.supportsCapability(DriverCapability.subqueries);
  
  // Get all supported capabilities
  final supported = adapter.capabilities;
  print('Driver supports: ${supported.map((c) => c.name).join(', ')}');
}
```

---

## Driver-Specific Behavior

### SQLite

**Supported Capabilities:**
- ✅ `rawExpressions`
- ✅ `adHocQueryUpdates`
- ✅ `complexJoins`
- ✅ `windowFunctions` (SQLite 3.25+)
- ✅ `cte` (SQLite 3.8+)
- ✅ `subqueries`

**Notes:**
- Window functions require SQLite 3.25 or higher
- CTEs require SQLite 3.8 or higher
- Full-text search available via FTS5 extension

### PostgreSQL

**Supported Capabilities:**
- ✅ `rawExpressions`
- ✅ `adHocQueryUpdates`
- ✅ `complexJoins`
- ✅ `windowFunctions`
- ✅ `cte`
- ✅ `subqueries`

**Notes:**
- Most feature-complete SQL implementation
- Supports advanced features like LATERAL joins, JSONB operators
- Excellent subquery optimization

### MySQL

**Supported Capabilities:**
- ✅ `rawExpressions`
- ✅ `adHocQueryUpdates`
- ✅ `complexJoins`
- ✅ `windowFunctions` (MySQL 8.0+)
- ✅ `cte` (MySQL 8.0+)
- ✅ `subqueries`

**Notes:**
- Window functions and CTEs require MySQL 8.0+
- MariaDB has similar but slightly different feature set

### MongoDB

**Supported Capabilities:**
- ❌ `rawExpressions` - No SQL syntax
- ❌ `adHocQueryUpdates` - Uses aggregation pipeline instead
- ⚠️ `complexJoins` - Limited via `$lookup` in aggregation
- ❌ `windowFunctions` - Use aggregation operators instead
- ❌ `cte` - Not applicable
- ⚠️ `subqueries` - Limited via `$expr` and aggregation

**Notes:**
- MongoDB uses BSON documents and aggregation pipelines, not SQL
- Ormed translates query builder calls to MongoDB operations where possible
- Some SQL-centric features don't translate directly

---

## Writing Cross-Database Code

### Strategy 1: Capability Checks

Adapt your queries based on driver capabilities:

```dart
import 'package:ormed/ormed.dart';

Future<List<Post>> getTopPosts(QueryContext context) async {
  var query = context.query<Post>();
  
  if (context.adapter.supportsCapability(DriverCapability.rawExpressions)) {
    // Use raw expression for SQL databases
    query = query.selectRaw('posts.*, (SELECT COUNT(*) FROM comments WHERE post_id = posts.id) as comment_count');
  } else {
    // Fallback: load count separately for MongoDB
    query = query.withCount('comments');
  }
  
  return query.orderBy('created_at', descending: true).limit(10).get();
}
```

### Strategy 2: Feature Detection

Use abstract interfaces and implement driver-specific logic:

```dart
abstract class SearchStrategy {
  Future<List<Post>> search(QueryContext context, String term);
}

class SqlSearchStrategy implements SearchStrategy {
  @override
  Future<List<Post>> search(QueryContext context, String term) async {
    return context
        .query<Post>()
        .whereRaw('title LIKE ?', ['%$term%'])
        .orWhereRaw('content LIKE ?', ['%$term%'])
        .get();
  }
}

class MongoSearchStrategy implements SearchStrategy {
  @override
  Future<List<Post>> search(QueryContext context, String term) async {
    return context
        .query<Post>()
        .where((q) => q
            .whereContains('title', term)
            .orWhereContains('content', term))
        .get();
  }
}

SearchStrategy selectStrategy(QueryContext context) {
  return context.adapter.supportsCapability(DriverCapability.rawExpressions)
      ? SqlSearchStrategy()
      : MongoSearchStrategy();
}
```

### Strategy 3: Prefer Query Builder Over Raw

The query builder API is designed to work across all drivers:

```dart
// ✅ Works everywhere
final posts = await context
    .query<Post>()
    .whereEquals('status', 'published')
    .whereGreaterThan('views', 100)
    .orderBy('created_at', descending: true)
    .get();

// ⚠️ Only works on SQL databases
final posts = await context
    .query<Post>()
    .whereRaw('status = ? AND views > ?', ['published', 100])
    .orderByRaw('created_at DESC')
    .get();
```

---

## Testing Across Drivers

Ormed includes a **driver test suite** that runs the same tests against all supported databases. This ensures your application logic works consistently.

### Using Driver Tests in Your Package

```dart
// test/driver_test.dart
import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

void main() {
  // Run all driver tests with SQLite
  runDriverTests(
    testHarness: SqliteTestHarness(),
    driverName: 'SQLite',
  );
  
  // Run with capability checks
  group('MongoDB specific', () {
    final harness = MongoTestHarness();
    
    test('raw queries throw UnsupportedError', () {
      expect(
        () => harness.context.query<Post>().whereRaw('x = 1').get(),
        throwsUnsupportedError,
      );
    }, skip: harness.config.supportsCapability(DriverCapability.rawExpressions));
  });
}
```

### Skipping Incompatible Tests

Use the `skip` parameter with capability checks:

```dart
test('raw expression in select', () async {
  final posts = await context
      .query<Post>()
      .selectRaw('*, (SELECT COUNT(*) FROM comments WHERE post_id = posts.id) as count')
      .get();
  
  expect(posts.first.getAttribute<int>('count'), greaterThan(0));
}, skip: !config.supportsCapability(DriverCapability.rawExpressions));
```

---

## Migration Considerations

### Conditional Migrations

Use capability checks in migrations:

```dart
class AddFullTextSearchToPostsMigration extends Migration {
  @override
  Future<void> up(SchemaBuilder schema) async {
    if (schema.adapter.supportsCapability(DriverCapability.rawExpressions)) {
      // SQLite FTS5
      await schema.rawStatement('''
        CREATE VIRTUAL TABLE posts_fts USING fts5(title, content, content=posts);
      ''');
    } else {
      // MongoDB text index
      await schema.collection('posts').index(['title', 'content'], textSearch: true);
    }
  }
  
  @override
  Future<void> down(SchemaBuilder schema) async {
    if (schema.adapter.supportsCapability(DriverCapability.rawExpressions)) {
      await schema.rawStatement('DROP TABLE posts_fts');
    } else {
      await schema.collection('posts').dropIndex('title_content_text');
    }
  }
}
```

---

## Best Practices

### 1. **Use Query Builder First**

Prefer the cross-database query builder API over raw SQL:

```dart
// ✅ Cross-database compatible
context.query<Post>()
    .whereEquals('status', 'published')
    .orderBy('created_at', descending: true);

// ❌ SQL-specific
context.query<Post>()
    .whereRaw('status = ?', ['published'])
    .orderByRaw('created_at DESC');
```

### 2. **Check Capabilities, Don't Assume**

Never assume a driver supports a feature:

```dart
// ❌ Bad - assumes raw expressions work
query.selectRaw('COUNT(*)');

// ✅ Good - checks capability first
if (adapter.supportsCapability(DriverCapability.rawExpressions)) {
  query.selectRaw('COUNT(*)');
} else {
  query.withCount('items');
}
```

### 3. **Document Driver Requirements**

If your package requires specific capabilities, document them:

```dart
/// Performs full-text search on posts.
///
/// **Requirements:**
/// - Driver must support [DriverCapability.rawExpressions]
/// - For SQL databases: Requires FTS extension
/// - For MongoDB: Requires text index on title/content
Future<List<Post>> fullTextSearch(String term) async {
  if (!adapter.supportsCapability(DriverCapability.rawExpressions)) {
    throw UnsupportedError('Full-text search requires raw expression support');
  }
  
  // ... implementation
}
```

### 4. **Test Against Multiple Drivers**

Use the driver test suite to validate cross-database compatibility:

```bash
# Run tests against all drivers
just test-all-drivers

# Or test individual drivers
just test-sqlite
just test-postgres
just test-mongo
```

### 5. **Fallback to Compatible Alternatives**

Provide graceful degradation when features aren't available:

```dart
Future<List<Post>> getPostsWithStats(QueryContext context) async {
  if (context.adapter.supportsCapability(DriverCapability.windowFunctions)) {
    // Use window function for efficient ranking
    return context.query<Post>()
        .selectRaw('*, ROW_NUMBER() OVER (ORDER BY views DESC) as rank')
        .get();
  } else {
    // Fallback: compute rank in memory
    final posts = await context.query<Post>()
        .orderBy('views', descending: true)
        .get();
    
    return posts.asMap().entries.map((entry) {
      final post = entry.value;
      post.setAttribute('rank', entry.key + 1);
      return post;
    }).toList();
  }
}
```

---

## Summary

- **Driver capabilities** let you detect database feature support at runtime
- **MongoDB** has limited SQL feature support due to its document-oriented nature
- **Query builder API** provides maximum cross-database compatibility
- **Capability checks** enable graceful feature degradation
- **Driver tests** validate your code works across all supported databases

For most applications, sticking to the standard query builder API provides excellent cross-database portability without manual capability checks.
