# Query Builder & Repositories

The query builder provides a fluent, type-safe API for building SQL queries
without embedding backend-specific syntax. It works in tandem with repositories,
relation loaders, and the model registry.

## QueryContext

```dart
final context = QueryContext(
  registry: registry,
  driver: sqliteAdapter,
  codecRegistry: sqliteAdapter.codecs,
);
```

`QueryContext` wires together the model registry, driver adapter, and codec
registry. It offers:

- `query<T>()` – start a typed query.
- `repository<T>()` – perform inserts/updates/deletes/upserts.
- `table('raw_table', {as: 'alias', columns: [...]})` – build ad-hoc queries that return
  `Map<String, Object?>` rows without requiring a generated ORM model. Useful
  for reporting tables or pivot-only lookups. Supply `columns` with `AdHocColumn`
  definitions when you want to describe column metadata (names, aliases, types,
  nullability).
- `describeQuery/describeMutation` – generate statement previews (`StatementPreview`).
- Event listeners: `onQuery` and `onMutation` emit `QueryEvent`/
  `MutationEvent` objects (plan, preview, duration, row counts, errors).

Combine `table()` with `mapRows` to project DTOs without manual plumbing:

```dart
final events = await connection
    .table('analytics_events')
    .mapRows(EventRow.fromMap)
    .getMapped();

final enriched = await connection
    .table(
      'events_2025',
      columns: const [
        AdHocColumn(name: 'occurredAt', columnName: 'occurred_at', dartType: 'DateTime'),
      ],
    )
    .mapRows(EventRow.fromMap)
    .getMapped();
```

`mapRows` also exposes `firstMapped`, `paginateMapped`, and `cursorPaginateMapped`
helpers, so ad-hoc queries can enjoy the same ergonomics as typed models.

Need incremental results? Every query offers streaming helpers:

```dart
await for (final user in context.query<User>().streamModels()) {
  logger.info('saw user', {'id': user.id});
}

await for (final dto in connection
    .table('events')
    .mapRows(EventRow.fromMap)
    .streamMapped()) {
  sink.add(dto);
}
```

Streaming still buffers at the driver level today, but it keeps your API
consistent and avoids materializing large lists when you only need iteration.

## Fluent Query API

### Basic Queries

The query builder can be accessed via `QueryContext.query<T>()` or directly from model classes using the static `query()` helper:

```dart
// Via context
final activeUsers = await context
    .query<User>()
    .whereEquals('active', true)
    .whereGreaterThan('created_at', DateTime(2024))
    .orderBy('email')
    .limit(20)
    .get();

// Via static helper (more ergonomic)
final recentUsers = await User.query()
    .whereGreaterThan('created_at', DateTime(2024))
    .orderBy('email', descending: true)
    .limit(10)
    .get();

// With custom connection
final adminUsers = await User.query(connection: 'admin')
    .whereEquals('role', 'admin')
    .get();
```

The static `query()` helper is automatically generated for all models and provides a cleaner API similar to Laravel's Eloquent.

### Query Caching

Cache expensive query results to improve performance and reduce database load:

```dart
// Cache for 5 minutes
final popularPosts = await Post.query()
    .where('views', '>', 1000)
    .orderBy('views', descending: true)
    .remember(Duration(minutes: 5))
    .get();

// Cache indefinitely (good for reference data)
final countries = await Country.query()
    .rememberForever()
    .get();

// Bypass cache for specific query
final freshData = await User.query()
    .where('id', userId)
    .dontRemember()
    .first();

// Manage cache
context.flushQueryCache(); // Clear all
context.vacuumQueryCache(); // Remove expired entries
final stats = context.queryCacheStats; // Get statistics

// Listen to cache events (unique feature!)
context.queryCache.listen((event) {
  if (event is CacheHitEvent) {
    metrics.recordHit();
  } else if (event is CacheMissEvent) {
    metrics.recordMiss();
  }
});
```

**Key features:**
- ✅ TTL-based expiration
- ✅ Cache events for monitoring (unique to this ORM!)
- ✅ Manual cache management
- ✅ Cache statistics tracking
- ✅ Laravel-compatible API

See [Query Caching Guide](query-caching.md) for detailed documentation, best practices, and comparison with Laravel.

Supported clauses:

| Method | Description |
| --- | --- |
| `whereEquals(field, value)` | `field = value` (accepts JSON selectors like `payload->flag`) |
| `whereIn(field, values)` | `field IN (...)` |
| `whereGreaterThan/whereLessThan` | Numeric/date comparisons |
| `orderBy(field, descending: false)` | Sort results |
| `limit(offset)` / `offset(value)` | Pagination |
| `limitPerGroup(limit, column, {offset})` | Returns at most `limit` rows per `column` partition using window functions |
| `withRelation(name)` | Eager-load relations (hasOne, hasMany, manyToMany) |
| `join('table', ...)` | INNER join a table or builder callback |
| `leftJoin`, `rightJoin`, `crossJoin`, `straightJoin` | Additional join variants |
| `joinWhere` | Compare a join column to a literal/binding |
| `joinSub(query, alias, ...)` | Join a subquery with merged bindings |
| `joinRelation('posts.comments')` | Join relation paths without eager loading |
| `joinLateral(query, alias)` | Postgres & MySQL LATERAL joins |
| `rows()` | Returns `List<QueryRow<T>>` (raw row + relation map) |
| `get()` | Returns hydrated models (`List<T>`) |
| `first()` / `firstOrNull()` / `firstRow()` | Convenience fetchers |
| `firstOrFail()` / `sole()` | Throw typed `ModelNotFoundException` / `MultipleRecordsFoundException` |
| `value(field)` / `pluck(field)` | Scalar + column extraction |
| `count()` / `exists()` | Aggregates without writing SQL manually |
| `find(id)` / `findOrFail(id)` | Primary key helpers |
| `toSql()` | Returns `StatementPreview` (SQL + parameters or command payload) without executing |
| `orderByRandom([seed])` | Randomizes ordering using the dialect's random function (MySQL also accepts a numeric seed for deterministic ordering) |
| `orderBy('payload->key')` | Orders by JSON selectors (`->` / `->>`); compiles to the dialect's JSON extraction helpers |
| `useIndex` / `forceIndex` / `ignoreIndex` | MySQL index hints appended after the `FROM` clause |
| `lockForUpdate()` / `sharedLock()` / `lock(clause)` | Emit dialect-specific row locks (Postgres/MySQL) |
| `whereFullText(columns, value, {language, mode, expanded})` | Dialect-aware full-text predicates (MySQL `MATCH ... AGAINST`, Postgres `to_tsvector`) |
| `whereJsonContains(field, value, {path})` | Filters JSON columns by checking whether the value exists at the given path (MySQL/Postgres/SQLite) |
| `whereJsonOverlaps(field, values, {path})` | Matches rows where an array shares at least one element with `values` |
| `whereJsonContainsKey(field, [path])` | Ensures the specified JSON key/path exists |
| `whereJsonLength(field, operatorOrLength, [length])` | Compares the array length at the JSON path (`whereJsonLength('data->tags', '>=', 2)`) |
| `havingBitwise(field, operator, value)` | Adds a dialect-aware bitwise `HAVING` clause (casts to boolean on Postgres) |

JSON selectors using `->` / `->>` can be passed anywhere you would normally
reference a column (`where`, `whereNull`, `whereLike`, etc.). When you compare
boolean fragments (for example `where('payload->isActive', true)`), the builder
automatically casts your Dart `bool` to the dialect's JSON literal so MySQL,
Postgres, and SQLite all emit valid SQL.

`limitPerGroup` mirrors Laravel's `limitPerGroup` helper by adding a `ROW_NUMBER()` window over the specified column. Order the query before calling it (e.g., `orderBy('publishedAt', descending: true).limitPerGroup(2, 'authorId')`) to pull the most recent rows per parent.

Use `rows()` when you need relation metadata (`QueryRow.relation*` helpers) and
`get()` when you simply want hydrated models. Scalar helpers like `value`,
`pluck`, and `count` mirror Laravel's builder API for familiarity.

### Full-text, Locks, and Index Hints

Advanced helpers mirror Laravel's ergonomics:

```dart
final articles = await context
    .query<Article>()
    .whereFullText(
      ['title', 'body'],
      searchTerm,
      language: 'english',
      mode: FullTextMode.websearch,
    )
    .useIndex(['articles_fulltext']) // MySQL / MariaDB only
    .orderByRandom(42)
    .lockForUpdate() // no-ops on SQLite
    .limit(10)
    .get();
```

- `FullTextMode.boolean`, `.natural`, `.phrase`, and `.websearch` route to the
  correct grammar per dialect (Postgres uses `to_tsvector`, MySQL emits
  `MATCH ... AGAINST`). SQLite throws `UnsupportedError` if invoked.
- `useIndex` / `forceIndex` / `ignoreIndex` are MySQL-only; Postgres/SQLite
  simply ignore the hints.
- `lockForUpdate`, `sharedLock`, and `lock('FOR KEY SHARE')` map directly to the
  available clauses on each grammar. Dialects that do not support locking return
  the base SELECT without modification, so it is safe to call the helpers in
  shared code.

### JSON Predicates

```dart
final docs = await context
    .query<Document>()
    .whereJsonContains('payload->tags', ['billing'])
    .whereJsonContainsKey('payload', 'meta.author')
    .whereJsonLength('payload->items', '>=', 2)
    .get();
```

- JSON helpers accept either `field->path` or an explicit `path:` parameter; all
  paths normalize to `$.foo.bar` under the hood.
- Dialect support mirrors Laravel: MySQL uses `JSON_CONTAINS`, Postgres uses
  jsonb operators (`@>`, `jsonb_path_exists`), and SQLite targets JSON1
  functions (`json_extract`, `json_array_length`).
- Unsupported drivers throw `UnsupportedError`, so misuse is detected during
  query compilation rather than at runtime.

## Manual Joins

The builder supports Laravel-style join helpers:

```dart
final rows = await context
    .query<Post>()
    .join('authors', (join) {
      join.on('authors.id', '=', 'posts.author_id');
      join.where('authors.active', true);
    })
    .joinRelation('tags')
    .select(['authors.name', 'rel_tags_0.label'])
    .orderBy('posts.id')
    .rows();

final counts = context
    .query<Post>()
    .select(['author_id'])
    .selectCount('id', alias: 'total_posts')
    .groupBy(['author_id']);

final aggregated = await context
    .query<Author>()
    .leftJoinSub(
      counts,
      'post_counts',
      'post_counts.author_id',
      '=',
      'authors.id',
    )
    .rows();
```

- `join`, `leftJoin`, `rightJoin`, `crossJoin`, and `straightJoin` emit the
  expected SQL keywords.
- Pass a callback to compose complex predicates (`join.where`,
  `join.orWhereRaw`, etc.).
- `joinSub` / `leftJoinSub` merge bindings from subqueries; Postgres and
  MySQL drivers also support `joinLateral`.
- `joinRelation('posts.comments')` reuses model metadata (pivot tables, morph
  columns, foreign keys) to build the appropriate join chain while exposing
  deterministic aliases (`rel_posts_0`, `rel_posts_0_1`, ...).
- Drivers that lack specific join types (e.g., RIGHT JOIN or LATERAL on
  SQLite) throw an `UnsupportedError` when compiling `toSql()` so failures appear
  during testing.

### Distinct

- `distinct()` prepends `SELECT DISTINCT` to the query.
- `distinct(['column', 'another'])` uses Postgres `DISTINCT ON (...)` semantics
  (the builder normalizes field names and JSON selectors automatically). Other
  dialects throw `UnsupportedError` if `DISTINCT ON` is requested.
- `withoutDistinct()` clears the distinct state so downstream scopes can toggle
  it dynamically.

### Union

- `union(otherQuery)` and `unionAll(otherQuery)` compose the current builder
  with another query using `UNION` / `UNION ALL`. SQLite wraps each branch in
  a `SELECT * FROM (...)` subquery (mirroring Laravel’s `wrapUnion`) so order
  clauses and limits remain valid within every segment.

## Relation Loader (Eager Loading)

When `withRelation` is specified, `RelationLoader` batches secondary queries or
JOINs according to relation metadata. `QueryRow<T>` exposes
`relation<R>('name')` and `relationList<R>('name')` helpers.

```dart
final posts = await context
    .query<Post>()
    .withRelation('author')
    .withRelation('tags')
    .withRelation('comments', (query) => query
        .whereEquals('approved', true)
        .orderBy('created_at', descending: true)
        .limit(10))
    .get();

for (final post in posts) {
  print('${post.title} by ${post.author?.name}');
  print('Tags: ${post.tags.map((t) => t.name).join(', ')}');
}
```

### Eager Loading Aggregates

Load relation counts or existence flags without fetching full related models:

```dart
final posts = await context
    .query<Post>()
    .withCount('comments')
    .withCount('tags', alias: 'tag_count')
    .withExists('author', alias: 'has_author')
    .rows();

for (final row in posts) {
  final commentCount = row.row['comments_count'] as int;
  final hasAuthor = row.row['has_author'] as bool;
}
```

### Lazy Loading

Models extending `Model<T>` can load relations on-demand after hydration:

```dart
final post = await Post.query().firstOrFail();

// Lazy load single relation
await post.load('author');

// Load if not already loaded
await post.loadMissing(['author', 'tags', 'comments']);

// Load with constraints
await post.load('comments', (query) => query.whereEquals('approved', true));

// Lazy aggregate loading
await post.loadCount('comments');
await post.loadExists('author');
```

See the [Relations & Lazy Loading](relations.md) documentation for complete
coverage of relation definitions, eager/lazy loading strategies, and mutation
helpers like `associate()`, `attach()`, `detach()`, and `sync()`.

## Structured Logging

Attach `StructuredQueryLogger` to the context for JSON-friendly diagnostics:

```dart
StructuredQueryLogger(
  onLog: (entry) => print(entry),
  includeParameters: true,
  attributes: {'env': 'dev'},
).attach(context);
```

Each entry contains `sql`, `parameters`, duration, row counts, and errors.

### Diagnostics

- `context.threadCount()` returns the number of open connections reported by
  the active driver (MySQL/MariaDB/Postgres). Dialects that do not expose this
  metric return `null`.

## Query Mutations

- `query<T>().update({...})` issues a single `UPDATE ...` statement scoped by
  the builder filters (where clauses, joins, scopes, etc.). The builder must
  target a model with a primary key so the ORM can correlate rows. JSON update
  helpers (`jsonSet/jsonSetPath`) and soft-delete scopes work the same way they
  do when calling repository helpers. Values flow through the active driver's
  codecs, so JSON/array columns receive correctly typed parameters.
- Include JSON selectors directly in the update map (e.g.
  `{'payload->mode': 'dark', r'payload->$.meta.count': 5}`) to patch nested
  values. Dialects emit `JSON_SET`/`jsonb_set`/`json_set` clauses accordingly.
- `query<T>().insertUsing(columns, sourceQuery)` mirrors Laravel's
  `insertUsing`, issuing `INSERT ... SELECT ...` statements that stream rows
  from [sourceQuery] into the target table. The [columns] list must align with
  the projection emitted by the source query, and both builders must share the
  same `QueryContext`. Call `insertOrIgnoreUsing` to apply driver-specific
  conflict suppression (`INSERT IGNORE`, `ON CONFLICT DO NOTHING`,
  `INSERT OR IGNORE`).
- PostgreSQL and SQLite mirror Laravel’s ability to update ad-hoc tables that
  lack explicit primary keys by falling back to the dialect’s row identifiers
  (`ctid` / `rowid`). This keeps `context.table('users').limit(1).update(...)`
  working even when the model is not registered.

## Repositories

Repositories convert models to mutation plans.

```dart
final repo = context.repository<User>();
await repo.insert(const User(id: 1, email: 'test@example.com', active: true));
await repo.updateMany([...]);
await repo.deleteByKeys([
  {'id': 1},
]);
```

Capabilities:

- `insert/insertMany`
- `insertOrIgnore` / `insertOrIgnoreMany`
- `updateMany`
- `upsertMany` (optionally pass `uniqueBy` + `updateColumns` to target
  non-primary keys)
- `deleteByKeys`
- Preview helpers (e.g., `previewInsertMany`) that return `StatementPreview` objects
  without executing.

`upsertMany` mirrors Laravel’s signature: pass `uniqueBy: ['email', ...]` to
target alternate unique keys and `updateColumns: ['active']` to limit the fields
that are updated when a conflict occurs.

`insertOrIgnoreMany` lets you batch insert while suppressing duplicate-key
errors (`INSERT IGNORE`, `ON CONFLICT DO NOTHING`, `INSERT OR IGNORE`
depending on the driver). It returns the number of rows that were actually
inserted.

Repositories depend on the configured `ValueCodecRegistry`, so custom codecs are
respected automatically.

When a model’s primary key field is marked `autoIncrement: true`, inserts on
drivers that support generated keys (Postgres, MySQL/MariaDB, SQLite) no longer
require you to pre-populate the id. The ORM omits the column when its value is
`null`, letting the dialect’s default/sequence assign the key and, when the
driver advertises `supportsReturning`, hydrates the generated id back onto the
model (mirroring Laravel’s `insertGetId`).

To patch nested JSON columns without rewriting the entire document, provide the
`jsonUpdates` builder when calling `updateMany`/`upsertMany`:

```dart
await repo.updateMany(
  [DriverOverrideEntry(id: 1, payload: const {})],
  jsonUpdates: (_) => [
    JsonUpdateDefinition.selector('payload->mode', 'light'),
    JsonUpdateDefinition.path('payload', r'$.meta.count', 5),
  ],
);
```

Models that extend `Model<T>` can also call `jsonSet('payload->mode', 'dark')`
or `jsonSetPath('payload', r'$.meta.count', 10)` before invoking `save()` to
queue JSON mutations automatically.

## Soft Delete Helpers

- `withTrashed()` temporarily disables the default `deleted_at IS NULL` scope
  so the builder can see every row.
- `onlyTrashed()` scopes the query to records that were soft deleted.
- `restore()` issues an update that clears the soft delete column for the
  matched rows.
- `forceDelete()` removes rows permanently. When the active driver advertises
  `supportsQueryDeletes` (MySQL/MariaDB, Postgres, and SQLite), the ORM emits
  single-shot `DELETE ... ORDER BY ... LIMIT ...` statements by wrapping the
  ordered/limited query in a sub-select, so clauses like `limitPerGroup` or
  ad-hoc ordering work identically to Laravel. Other drivers fall back to
  selecting primary keys and issuing targeted deletes, preserving correctness
  albeit with an extra round-trip.

## Error Handling

- Missing primary keys throw a `StateError` when performing updates/upserts.
- Unknown fields result in an `ArgumentError` during query construction.
- Query/mutation events surface exceptions to listeners, making it easy to send
  them to logging/monitoring systems.

### Ad-hoc scopes

Register reusable predicates for raw tables:

```dart
context.scopeRegistry.registerAdHocTableScope(
  'tenant',
  (query) => query.whereEquals('tenant_id', 42),
  pattern: 'events_*',
);

final recent = await connection
    .table('events_2025', scopes: ['tenant'])
    .whereGreaterThan('created_at', DateTime.utc(2025, 1, 1))
    .get();
```

Scopes may target explicit table names or glob patterns and only run when the
caller opts in via the `scopes:` argument.

### Reusing Model Definitions for Views

Need to hit a view without losing relation metadata? Clone a definition with a
new table/schema/alias:

```dart
final archived = await connection
    .queryAs<User>(table: 'user_view', alias: 'uv')
    .withRelation('posts')
    .get();
```

All relation metadata (eager loading, codecs, scopes) remains intact while the
query grammar targets the overridden table/alias.
