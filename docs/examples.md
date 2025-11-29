# Examples & Recipes

This chapter provides end-to-end walkthroughs demonstrating how the routed ORM
pieces work together.

## End-to-End SQLite Workflow

1. **Dependencies** (`pubspec.yaml`)
   ```yaml
   dependencies:
     orm_core:
     ormed_sqlite:
   dev_dependencies:
     build_runner:
     ormed_cli:
   ```
2. **Model (`lib/user.dart`)**
   ```dart
   import 'package:ormed/ormed.dart';
   part 'user.orm.dart';

   @OrmModel(table: 'users')
   class User extends Model<User> {
     const User({required this.id, required this.email, this.posts = const []});

     @OrmField(isPrimaryKey: true)
     final int id;
     final String email;

     @OrmField(ignore: true)
     @OrmRelation(
       kind: RelationKind.hasMany,
       target: Post,
       foreignKey: 'user_id',
       localKey: 'id',
     )
     final List<Post> posts;
   }
   ```
3. **Generate** - `dart run build_runner build --delete-conflicting-outputs`.
   This also produces `lib/orm_registry.g.dart` which exports
   `buildOrmRegistry()`. Import it (`import 'package:your_app/orm_registry.g.dart';`)
   to get a `ModelRegistry` pre-populated with every generated model.

   If you want the registry in a different location (for example `lib/generated/`),
   add a `build.yaml` alongside `pubspec.yaml` that configures the builder:

   ```yaml
   targets:
     $default:
       builders:
         ormed|orm_registry:
           options:
             output: lib/generated/orm_registry.g.dart
   ```

   The path is relative to the package root and defaults to `lib/orm_registry.g.dart`.
4. **Bootstrap CLI** - `dart run ormed_cli:init` (creates `orm.yaml`, registry, and migrations directory).
5. **Create/Apply migrations** - `dart run ormed_cli:make --name create_users`, edit the file, then `dart run ormed_cli:apply`.
6. **Query** - reuse the generated models inside `QueryContext`:

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import 'user.dart';
import 'user.orm.dart';

Future<void> main() async {
  final registry = ModelRegistry()
    ..register(UserOrmDefinition.definition);

  final adapter = SqliteDriverAdapter.file('app.sqlite');
  final context = QueryContext(registry: registry, driver: adapter);

  await context.repository<User>().insertMany([
    const User(id: 1, email: 'example@example.com'),
  ], returning: true);

  final emails = (await context.query<User>().orderBy('id').get())
      .map((user) => user.email)
      .join(', ');
  print('Users: $emails');
  await adapter.close();
}
```
   Extending `Model<User>` is optional but saves you from manually adding the
   attribute/connection mixins and unlocks the built-in persistence helpers
   described later in this guide.

> **Helper tip** – If you prefer not to pass `context` around, bind the global
> resolver once:
>
> ```dart
> Model.bindConnectionResolver(resolveConnection: (_) => context);
> final created = await Model.create<User>(const User(id: 2, email: 'hi@routed.dev'));
> final models = await Model.query<User>().orderBy('id').get();
> print('Users: ${models.length}');
> ```
>
> This delegates to the same repositories/query builders under the hood while
> keeping sample code concise. Call `Model.unbindConnectionResolver()` when
> you're done (e.g., in tests).

> **CLI preview** - `ormed_cli` prints a "change set" before each migration runs,
> highlighting columns/indexes/foreign keys that will be created or dropped.

## Connecting to File-Based SQLite via ConnectionFactory

```dart
final factory = ConnectionFactory(connectors: {
  'sqlite': () => SqliteConnector(),
});

final adapter = SqliteDriverAdapter.custom(
  config: const DatabaseConfig(driver: 'sqlite', options: {'path': 'app.db'}),
  connections: factory,
);
```

- Swap `options` for `{'memory': true}` to run ephemeral tests.
- Register additional connectors in the factory to prepare for Postgres or
  MySQL once those adapters exist.

## Running Migrations with ormed_cli

### SQLite Project

1. Initialize scaffolding - `dart run ormed_cli:init`.
2. Create a migration - `dart run ormed_cli:make --name create_users_table`.
3. Edit the generated file (under `database/migrations/`).
4. Apply pending migrations - `dart run ormed_cli:apply`.
5. Verify status / ledger - `dart run ormed_cli:status`.
6. Roll back if needed - `dart run ormed_cli:rollback`.

### Postgres Project

1. Start Postgres locally (`docker compose up postgres` inside
   `packages/orm/ormed_postgres/`) or provide `POSTGRES_URL`.
2. Update `pubspec.yaml` to include `ormed_postgres`.
3. Configure `orm.yaml`:
   ```yaml
   driver:
     type: postgres
     options:
       url: ${POSTGRES_URL:-postgres://postgres:postgres@localhost:6543/orm_test}
   migrations:
     directory: database/migrations
     registry: database/migrations.dart
     ledger_table: orm_migrations
   ```
4. Run the same CLI commands (`init`, `make`, `apply`, `status`, `rollback`).
   The driver adapter handles ledger creation and schema diff previews against
   the Postgres server.

### Workspace Playground

This repository contains `orm_playground/`, a tiny Dart app wired to SQLite and
preloaded with migrations. You can run the CLI against it from the workspace
root without changing directories:

```
dart run packages/orm/ormed_cli/bin/orm.dart apply --config orm_playground/orm.yaml
```

After applying migrations, inspect the data via
`dart run orm_playground/bin/orm_playground.dart`. The playground uses
`PlaygroundDatabase` (exported from `package:orm_playground/orm_playground.dart`)
to register a connection through `ConnectionManager` and then issues ad-hoc
queries with `connection.table('users')`.

## Postgres + QueryContext Example

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

import 'user.dart';
import 'user.orm.dart';

Future<void> main() async {
  final adapter = PostgresDriverAdapter.custom(
    config: const DatabaseConfig(
      driver: 'postgres',
      options: {'url': 'postgres://postgres:postgres@localhost:6543/orm_test'},
    ),
  );

  final context = QueryContext(
    registry: ModelRegistry()..register(UserOrmDefinition.definition),
    driver: adapter,
  );

  await context.repository<User>().insert(const User(id: 1, email: 'pg@routed.dev'));
  print((await context.query<User>().first())?.email);
  await adapter.close();
}
```

## Observability Example

```dart
final context = QueryContext(registry: registry, driver: adapter);
StructuredQueryLogger.printing(pretty: true).attach(context);
await context.query<User>().whereEquals('id', 1).first();
```

Outputs:
```json
{
  "type": "query",
  "model": "User",
  "sql": "SELECT \"id\", \"email\" FROM \"users\" WHERE \"id\" = ?",
  "parameters": [1],
  "duration_ms": 0.42
}
```

## Manual Join Recipe

```dart
final recentPosts = await context
    .query<Post>()
    .join('authors', (join) {
      join.on('authors.id', '=', 'posts.author_id');
      join.where('authors.active', true);
    })
    .joinRelation('tags')
    .select(['authors.name', 'rel_tags_0.label'])
    .orderBy('posts.published_at', descending: true)
    .limit(5)
    .rows();

final summaries = recentPosts.map((row) {
  final model = row.model;
  final author = row.row['author_name'];
  final tag = row.row['tag_label'];
  return '${model.title} by $author (${tag ?? 'untagged'})';
});
```

`joinSub` / `leftJoinSub` can layer aggregations, while Postgres adapters also
support `joinLateral` for correlation-heavy queries. Use `joinRelation` to reuse
relation metadata (pivots, morph columns, etc.) when you need SQL JOINs instead
of eager loading the relation.

## Working with Relations

### Eager Loading Relations

Load related models alongside the main query to avoid N+1 problems:

```dart
// Load posts with their authors and tags
final posts = await context
    .query<Post>()
    .withRelation('author')
    .withRelation('tags')
    .withRelation('comments', (query) => query
        .whereEquals('approved', true)
        .orderBy('created_at', descending: true)
        .limit(5))
    .get();

for (final post in posts) {
  print('${post.title} by ${post.author?.name}');
  print('Tags: ${post.tags.map((t) => t.name).join(', ')}');
  print('Comments: ${post.comments.length}');
}
```

### Eager Loading Aggregates

Get counts or existence flags without loading full related models:

```dart
final posts = await context
    .query<Post>()
    .withCount('comments')
    .withCount('tags', alias: 'tag_count')
    .withExists('author', alias: 'has_author')
    .orderBy('comments_count', descending: true)
    .limit(10)
    .rows();

for (final row in posts) {
  final post = row.model;
  final commentCount = row.row['comments_count'] as int;
  final tagCount = row.row['tag_count'] as int;
  print('${post.title}: $commentCount comments, $tagCount tags');
}
```

### Lazy Loading Relations

Load relations on-demand after the model is hydrated (requires `Model<T>` base):

```dart
// Fetch post without relations
final post = await Post.query().firstOrFail();

// Lazy load when needed
await post.load('author');
print('Author: ${post.author?.name}');

// Load multiple if not already loaded
await post.loadMissing(['tags', 'comments']);

// Nested relation loading
await post.load('comments.author');
for (final comment in post.comments) {
  print('Comment by: ${comment.author?.name}');
}
```

### Lazy Loading Aggregates

Load counts, sums, and other aggregates without fetching full collections:

```dart
final post = await Post.query().firstOrFail();

// Load comment count
await post.loadCount('comments');
print('Comments: ${post.getAttribute<int>('comments_count')}');

// Load sum of order amounts
await post.loadSum('orders', 'total', alias: 'order_total');
print('Total: \$${post.getAttribute<num>('order_total')}');

// Load average rating
await post.loadAvg('ratings', 'score');
print('Rating: ${post.getAttribute<num>('ratings_avg_score')}');

// With constraints
await post.loadCount('comments', constraint: (query) =>
    query.whereEquals('approved', true));
```

### Preventing Lazy Loading (Development)

Catch N+1 query problems during development:

```dart
// Enable globally
ModelRelations.preventsLazyLoading = true;

// Now any lazy load throws LazyLoadingViolationException
try {
  final post = await Post.query().first();
  await post.load('author'); // Throws!
} on LazyLoadingViolationException catch (e) {
  print('Lazy loading blocked: ${e.relationName} on ${e.modelName}');
}

// Best practice: enable in dev/test only
if (environment != 'production') {
  ModelRelations.preventsLazyLoading = true;
}
```

### Relation Mutations

Manage associations without manual foreign key manipulation:

```dart
final post = await Post.query().firstOrFail();

// BelongsTo: Associate & Dissociate
final author = await Author.query().whereEquals('email', 'john@example.com').firstOrFail();
post.associate('author', author);
await post.save();
print(post.authorId); // Updated to author.id

post.dissociate('author');
await post.save();
print(post.authorId); // null

// ManyToMany: Attach, Detach & Sync
await post.attach('tags', [1, 2, 3]);
print(post.tags.length); // 3

await post.detach('tags', [1]);
print(post.tags.length); // 2

// Sync replaces all associations
await post.sync('tags', [4, 5, 6]);
print(post.tags.length); // 3 (only 4, 5, 6)

// With pivot data
await post.attach('tags', [7], pivotData: {
  'created_at': DateTime.now(),
  'priority': 'high',
});
```

### Batch Loading on Collections

Load relations for multiple models efficiently:

```dart
// Get posts from different sources
final posts = await Post.query().limit(10).get();

// Single query loads all authors
await Model.loadRelations(posts, 'author');

// Load multiple relations
await Model.loadRelationsMany(posts, ['author', 'tags', 'comments']);

// Load only missing relations
final postsWithAuthors = await Post.query().withRelation('author').get();
await Model.loadRelationsMissing(postsWithAuthors, ['author', 'tags']);
// Only loads 'tags' since 'author' is already present

// Load with constraints
await post.load('comments', (query) => query
    .whereEquals('approved', true)
    .orderBy('created_at', descending: true));

// Lazy aggregate loading
await post.loadCount('comments');
print('Comment count: ${post.getAttribute<int>('comments_count')}');

await post.loadExists('author');
print('Has author: ${post.getAttribute<bool>('author_exists')}');
```

### Managing BelongsTo Relations

Use `associate()` and `dissociate()` for parent relationships:

```dart
final post = await Post.query().firstOrFail();
final newAuthor = await Author.query().whereEquals('name', 'Jane').firstOrFail();

// Associate sets the foreign key and caches the relation
post.associate('author', newAuthor);
await post.save();

print(post.authorId);       // Updated to newAuthor.id
print(post.author?.name);   // 'Jane' (cached)

// Dissociate clears the relationship
post.dissociate('author');
await post.save();

print(post.authorId);       // null
print(post.author);         // null
```

### Managing ManyToMany Relations

Use `attach()`, `detach()`, and `sync()` for pivot table relationships:

```dart
final post = await Post.query().firstOrFail();

// Attach new tags (inserts pivot records)
await post.attach('tags', [1, 2, 3]);

// Attach with extra pivot data
await post.attach('tags', [4, 5], pivotData: {
  'created_at': DateTime.now(),
  'added_by': currentUserId,
});

// Detach specific tags
await post.detach('tags', [1, 2]);

// Detach all tags
await post.detach('tags');

// Sync replaces all existing associations
await post.sync('tags', [3, 4, 5]);

// Access the updated relation
print('Tags: ${post.tags.map((t) => t.name).join(', ')}');
```

### Preventing Accidental Lazy Loading

In production, enable strict mode to catch N+1 problems:

```dart
void main() {
  // Enable prevention globally
  ModelRelations.preventsLazyLoading = true;

  runApp(MyApp());
}

// Later, any lazy load throws LazyLoadingViolationException
try {
  await post.load('author'); // Throws!
} on LazyLoadingViolationException catch (e) {
  print('Blocked: ${e.relationName} on ${e.modelName}');
}

// Already-loaded relations still work
final post = await Post.query().withRelation('author').first();
print(post.author?.name); // OK - was eager loaded
```

### Nested Relation Paths

Load nested relations using dot notation:

```dart
final post = await Post.query().firstOrFail();

// Load comments and their authors in one call
await post.load('comments.author');

// Access nested data
for (final comment in post.comments) {
  print('Comment by: ${comment.author?.name}');
}

// Constraint applies to the final relation
await post.load('comments.author', (query) => query.whereEquals('active', true));
```

### Batch Loading on Collections

Efficiently load relations on multiple models with a single query:

```dart
final posts = await Post.query().get();

// Single query loads all authors (avoids N+1)
await Model.loadRelations(posts, 'author');

// Load multiple relations
await Model.loadRelationsMany(posts, ['author', 'tags', 'comments']);

// Load only missing relations (skips already loaded)
await Model.loadRelationsMissing(posts, ['author', 'tags']);

// With constraints
await Model.loadRelations(posts, 'comments', (query) =>
    query.whereEquals('approved', true));
```

### Checking Relation State

Query whether relations have been loaded:

```dart
final post = await Post.query().withRelation('author').first();

if (post.relationLoaded('author')) {
  print('Author already loaded');
}

if (!post.relationLoaded('comments')) {
  await post.load('comments');
}

// Get all loaded relation names
print('Loaded: ${post.loadedRelationNames}');

// Get all loaded relations as a map
final relations = post.loadedRelations;
```

## Testing Tips

- Use `InMemoryQueryExecutor` from `orm_core/testing` to exercise the query
  builder without a real database.
- Attach listeners to `QueryContext.onQuery` / `.onMutation` in tests to assert
  behavior (e.g., that certain filters were applied).
- For migrations, call `MigrationRunner` with a fake ledger/driver to verify
  ordering logic before connecting to SQLite or another driver.
- For Postgres integration tests, reuse `PostgresTestHarness` (under
  `packages/orm/ormed_postgres/test/support`) which spins up a schema per test
  using `POSTGRES_URL` or the bundled docker-compose file.
## Seeding Data with OrmSeeder

`package:orm_core/testing/seeder.dart` ships a lightweight helper for
integration tests or demos:

```dart
import 'package:orm_core/testing/seeder.dart';

final connection = await factory.register(...).connection();
final seeder = OrmSeeder(connection);

await seeder.truncate('users');
final admin = await seeder.insert(
  User(email: 'admin@example.com', name: 'Admin', active: true),
);
await seeder.insertMany([
  Post(userId: admin.id!, title: 'Hello', body: '...'),
  Post(userId: admin.id!, title: 'Another', body: '...'),
]);
```

Under the hood it reuses repositories (`connection.repository<T>()`) and
invokes driver-specific SQL for `truncate`, so your tests stay portable across
SQLite/MySQL/Postgres.
## Multi-tenant playground

The playground includes a multi-tenant `orm.yaml` with `default`/`analytics`
connections plus `orm_playground/bin/multi_tenant_demo.dart`. After you’ve run
migrations for each connection (e.g. `orm apply` and
`orm apply --connection analytics`), run the demo script:

```bash
dart run orm_playground/bin/multi_tenant_demo.dart
```

The script registers different SQLite files, seeds only empty datasets, and
prints per-tenant user counts through `UserModelFactory.withConnection`.

## Auto-registering connections from orm.yaml

`ormed_cli` already relies on `registerConnectionsFromConfig` to bootstrap
`ConnectionManager.defaultManager` for every entry in `orm.yaml`. Each driver
package (`ormed_sqlite`, `ormed_mysql`, `ormed_postgres`, `ormed_mongo`) registers
itself with `DriverRegistry`, so the helper simply selects the right callback,
registers the tenant, and returns an `OrmConnectionHandle`.

You can reuse the same helper in your application or playground without wiring
up each driver manually:

```dart
import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:your_app/user.dart';
import 'package:yaml/yaml.dart';

Future<void> main() async {
  final root = Directory.current;
  final configFile = File('orm.yaml');
  final yaml = loadYaml(configFile.readAsStringSync());
  final config = OrmProjectConfig.fromYaml(yaml);

  final handle = await registerConnectionsFromConfig(
    root: root,
    config: config,
    targetConnection: 'analytics',
  );

  await handle.use((connection) async {
    print('Analytics rows: ${await connection.query<User>().count()}');
  });
}
```

`registerConnectionsFromConfig` returns the handle for the requested connection,
and every tenant also becomes available through `ConnectionManager.defaultManager`
once registration completes.
