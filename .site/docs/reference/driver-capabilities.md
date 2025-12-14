---
sidebar_position: 6
---

# Driver Capabilities

Ormed supports multiple database drivers (SQLite, PostgreSQL, MySQL), but not all databases support the same features. The Driver Capabilities system allows you to query what features are available at runtime.

## Overview

Different databases have varying levels of SQL feature support:

| Feature | SQLite | PostgreSQL | MySQL |
|---------|--------|------------|-------|
| Raw SQL Expressions | ✅ | ✅ | ✅ |
| Ad-hoc Updates/Deletes | ✅ | ✅ | ✅ |
| Complex Joins | ✅ | ✅ | ✅ |
| Window Functions | ✅ 3.25+ | ✅ | ✅ 8.0+ |
| Subqueries | ✅ | ✅ | ✅ |
| CTEs (WITH clause) | ✅ 3.8+ | ✅ | ✅ 8.0+ |

## Available Capabilities

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

## Checking Capabilities at Runtime

```dart
import 'package:ormed/ormed.dart';

void main() async {
  final adapter = SqliteDriverAdapter.file('app.sqlite');
  
  // Check single capability
  if (adapter.supportsCapability(DriverCapability.rawExpressions)) {
    print('Can use raw SQL expressions');
  }
  
  // Check multiple capabilities
  final canDoComplexQuery = 
      adapter.supportsCapability(DriverCapability.complexJoins) &&
      adapter.supportsCapability(DriverCapability.subqueries);
  
  // Get all supported capabilities
  final supported = adapter.capabilities;
  print('Driver supports: ${supported.map((c) => c.name).join(', ')}');
}
```

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

## Writing Cross-Database Code

### Strategy 1: Capability Checks

```dart
Future<List<Post>> getTopPosts(QueryContext context) async {
  var query = context.query<$Post>();
  
  if (context.driver.supportsCapability(DriverCapability.rawExpressions)) {
    query = query.selectRaw(
      'posts.*, (SELECT COUNT(*) FROM comments WHERE post_id = posts.id) as comment_count'
    );
  } else {
    query = query.withCount(['comments']);
  }
  
  return query.orderBy('created_at', descending: true).limit(10).get();
}
```

### Strategy 2: Prefer Query Builder Over Raw

The query builder API works across all drivers:

```dart
// ✅ Works everywhere
final posts = await context.query<$Post>()
    .whereEquals('status', 'published')
    .whereGreaterThan('views', 100)
    .orderBy('created_at', descending: true)
    .get();

// ⚠️ Only works on SQL databases
final posts = await context.query<$Post>()
    .whereRaw('status = ? AND views > ?', ['published', 100])
    .orderByRaw('created_at DESC')
    .get();
```

### Strategy 3: Feature Detection

```dart
abstract class SearchStrategy {
  Future<List<Post>> search(QueryContext context, String term);
}

class SqlSearchStrategy implements SearchStrategy {
  @override
  Future<List<Post>> search(QueryContext context, String term) async {
    return context.query<$Post>()
        .whereRaw('title LIKE ?', ['%$term%'])
        .orWhereRaw('content LIKE ?', ['%$term%'])
        .get();
  }
}

class BasicSearchStrategy implements SearchStrategy {
  @override
  Future<List<Post>> search(QueryContext context, String term) async {
    return context.query<$Post>()
        .whereContains('title', term)
        .orWhereContains('content', term)
        .get();
  }
}

SearchStrategy selectStrategy(QueryContext context) {
  return context.driver.supportsCapability(DriverCapability.rawExpressions)
      ? SqlSearchStrategy()
      : BasicSearchStrategy();
}
```

## Testing Across Drivers

### Skipping Incompatible Tests

```dart
test('raw expression in select', () async {
  final posts = await context.query<$Post>()
      .selectRaw('*, (SELECT COUNT(*) FROM comments WHERE post_id = posts.id) as count')
      .get();
  
  expect(posts.first.getAttribute<int>('count'), greaterThan(0));
}, skip: !adapter.supportsCapability(DriverCapability.rawExpressions));
```

## Migration Considerations

### Conditional Migrations

```dart
class AddFullTextSearchMigration extends Migration {
  @override
  Future<void> up(SchemaBuilder schema) async {
    if (schema.driver.supportsCapability(DriverCapability.rawExpressions)) {
      // SQLite FTS5
      await schema.rawStatement('''
        CREATE VIRTUAL TABLE posts_fts USING fts5(title, content, content=posts);
      ''');
    }
  }
  
  @override
  Future<void> down(SchemaBuilder schema) async {
    if (schema.driver.supportsCapability(DriverCapability.rawExpressions)) {
      await schema.rawStatement('DROP TABLE IF EXISTS posts_fts');
    }
  }
}
```

## Best Practices

### 1. Use Query Builder First

```dart
// ✅ Cross-database compatible
context.query<$Post>()
    .whereEquals('status', 'published')
    .orderBy('created_at', descending: true);

// ❌ SQL-specific
context.query<$Post>()
    .whereRaw('status = ?', ['published'])
    .orderByRaw('created_at DESC');
```

### 2. Check Capabilities, Don't Assume

```dart
// ❌ Bad - assumes raw expressions work
query.selectRaw('COUNT(*)');

// ✅ Good - checks capability first
if (adapter.supportsCapability(DriverCapability.rawExpressions)) {
  query.selectRaw('COUNT(*)');
} else {
  query.withCount(['items']);
}
```

### 3. Document Driver Requirements

```dart
/// Performs full-text search on posts.
///
/// **Requirements:**
/// - Driver must support [DriverCapability.rawExpressions]
Future<List<Post>> fullTextSearch(String term) async {
  if (!adapter.supportsCapability(DriverCapability.rawExpressions)) {
    throw UnsupportedError('Full-text search requires raw expression support');
  }
  // ... implementation
}
```

### 4. Fallback to Compatible Alternatives

```dart
Future<List<Post>> getPostsWithStats(QueryContext context) async {
  if (context.driver.supportsCapability(DriverCapability.windowFunctions)) {
    return context.query<$Post>()
        .selectRaw('*, ROW_NUMBER() OVER (ORDER BY views DESC) as rank')
        .get();
  } else {
    // Fallback: compute rank in memory
    final posts = await context.query<$Post>()
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

## Summary

- **Driver capabilities** let you detect database feature support at runtime
- **Query builder API** provides maximum cross-database compatibility
- **Capability checks** enable graceful feature degradation
- For most applications, sticking to the standard query builder API provides excellent cross-database portability without manual capability checks
