---
sidebar_position: 5
---

# Examples & Recipes

End-to-end walkthroughs demonstrating how Ormed pieces work together.

## End-to-End SQLite Workflow

### 1. Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  ormed:
  ormed_sqlite:
dev_dependencies:
  build_runner:
  ormed_cli:
```

### 2. Model (`lib/user.dart`)

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

### 3. Generate

```bash
dart run build_runner build --delete-conflicting-outputs
```

This produces `lib/orm_registry.g.dart` with `buildOrmRegistry()`.

### 4. Bootstrap CLI

```bash
dart run ormed_cli:init
```

Creates `orm.yaml`, registry, and migrations directory.

### 5. Create/Apply Migrations

```bash
dart run ormed_cli:make --name create_users
# Edit the generated file
dart run ormed_cli:apply
```

### 6. Query

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

  await context.repository<$User>().insertMany([
    const $User(id: 1, email: 'example@example.com'),
  ]);

  final emails = (await context.query<$User>().orderBy('id').get())
      .map((user) => user.email)
      .join(', ');
  print('Users: $emails');
  await adapter.close();
}
```

## Static Helpers Pattern

Bind a global resolver for cleaner code:

```dart
Model.bindConnectionResolver(resolveConnection: (_) => context);

final created = await Model.create<User>(
  const $User(id: 2, email: 'hi@example.com'),
);
final models = await Model.query<$User>().orderBy('id').get();
print('Users: ${models.length}');

// Cleanup in tests
Model.unbindConnectionResolver();
```

## PostgreSQL + QueryContext

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

Future<void> main() async {
  final adapter = PostgresDriverAdapter.custom(
    config: const DatabaseConfig(
      driver: 'postgres',
      options: {'url': 'postgres://postgres:postgres@localhost:5432/app'},
    ),
  );

  final context = QueryContext(
    registry: ModelRegistry()..register(UserOrmDefinition.definition),
    driver: adapter,
  );

  await context.repository<$User>().insert(
    const $User(id: 1, email: 'pg@example.com'),
  );
  print((await context.query<$User>().first())?.email);
  await adapter.close();
}
```

## Observability Example

```dart
final context = QueryContext(registry: registry, driver: adapter);
StructuredQueryLogger.printing(pretty: true).attach(context);

await context.query<$User>().whereEquals('id', 1).first();
```

Output:
```json
{
  "type": "query",
  "model": "User",
  "sql": "SELECT \"id\", \"email\" FROM \"users\" WHERE \"id\" = ?",
  "parameters": [1],
  "duration_ms": 0.42
}
```

## Working with Relations

### Eager Loading

```dart
final posts = await context.query<$Post>()
    .with_(['author'])
    .with_(['tags'])
    .with_(['comments'], (query) => query
        .whereEquals('approved', true)
        .orderBy('created_at', descending: true)
        .limit(5))
    .get();

for (final post in posts) {
  print('${post.title} by ${post.author?.name}');
  print('Tags: ${post.tags.map((t) => t.name).join(', ')}');
}
```

### Eager Loading Aggregates

```dart
final posts = await context.query<$Post>()
    .withCount(['comments'])
    .withCount(['tags'], alias: 'tag_count')
    .withExists(['author'], alias: 'has_author')
    .orderBy('comments_count', descending: true)
    .limit(10)
    .rows();

for (final row in posts) {
  final post = row.model;
  final commentCount = row.row['comments_count'] as int;
  print('${post.title}: $commentCount comments');
}
```

### Lazy Loading

```dart
final post = await Post.query().firstOrFail();

// Lazy load when needed
await post.load(['author']);
print('Author: ${post.author?.name}');

// Load multiple if not already loaded
await post.loadMissing(['tags', 'comments']);

// Nested relation loading
await post.load(['comments.author']);
```

### Lazy Loading Aggregates

```dart
final post = await Post.query().firstOrFail();

await post.loadCount(['comments']);
print('Comments: ${post.getAttribute<int>('comments_count')}');

await post.loadSum(['orders'], 'total', alias: 'order_total');
print('Total: \$${post.getAttribute<num>('order_total')}');
```

### Relation Mutations

```dart
final post = await Post.query().firstOrFail();

// BelongsTo: Associate & Dissociate
final author = await Author.query().whereEquals('email', 'john@example.com').firstOrFail();
post.associate('author', author);
await post.save();

post.dissociate('author');
await post.save();

// ManyToMany: Attach, Detach & Sync
await post.attach('tags', [1, 2, 3]);
await post.detach('tags', [1]);
await post.sync('tags', [4, 5, 6]);

// With pivot data
await post.attach('tags', [7], pivotData: {
  'created_at': DateTime.now(),
  'priority': 'high',
});
```

### Batch Loading

```dart
final posts = await Post.query().limit(10).get();

// Single query loads all authors
await Model.loadRelations(posts, 'author');

// Load multiple relations
await Model.loadRelationsMany(posts, ['author', 'tags', 'comments']);

// Load only missing relations
await Model.loadRelationsMissing(posts, ['author', 'tags']);
```

### Preventing Lazy Loading

```dart
// Enable in development
if (environment != 'production') {
  ModelRelations.preventsLazyLoading = true;
}

// Now any lazy load throws
try {
  await post.load(['author']); // Throws!
} on LazyLoadingViolationException catch (e) {
  print('Blocked: ${e.relationName} on ${e.modelName}');
}
```

## Manual Join Recipe

```dart
final recentPosts = await context.query<$Post>()
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

## Seeding Data

```dart
import 'package:ormed/testing.dart';

final connection = await factory.register(...).connection();
final seeder = OrmSeeder(connection);

await seeder.truncate('users');
final admin = await seeder.insert(
  $User(id: 0, email: 'admin@example.com', name: 'Admin', active: true),
);
await seeder.insertMany([
  $Post(id: 0, userId: admin.id!, title: 'Hello', body: '...'),
  $Post(id: 0, userId: admin.id!, title: 'Another', body: '...'),
]);
```

## Testing Tips

- Use `InMemoryQueryExecutor` for fast tests without a real database
- Attach listeners to `context.onQuery`/`.onMutation` to assert behavior
- For migrations, use `MigrationRunner` with a fake ledger to verify ordering
- For Postgres integration tests, use `PostgresTestHarness` which spins up a schema per test
