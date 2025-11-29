# MongoDB Guide

This guide covers using Ormed with MongoDB, including its unique features, limitations, and best practices.

## Overview

MongoDB is a document-oriented NoSQL database that uses JSON-like documents with optional schemas. Ormed's MongoDB driver provides a familiar query builder API while leveraging MongoDB's native capabilities like aggregation pipelines.

## Setup

### Add Dependencies

```yaml
dependencies:
  ormed: ^0.1.0
  ormed_mongo: ^0.1.0
```

### Connect to MongoDB

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';

void main() async {
  // Connect via connection string
  final adapter = MongoDriverAdapter.uri(
    'mongodb://localhost:27017/mydb',
  );

  // Or with custom config
  final adapter = MongoDriverAdapter.custom(
    config: const DatabaseConfig(
      driver: 'mongodb',
      options: {
        'host': 'localhost',
        'port': 27017,
        'database': 'mydb',
        'username': 'user',
        'password': 'pass',
      },
    ),
  );

  final registry = ModelRegistry()
    ..register(UserOrmDefinition.definition);

  final context = QueryContext(
    registry: registry,
    driver: adapter,
  );

  // Your queries here...

  await adapter.close();
}
```

## Models & Collections

MongoDB models work the same way as SQL models:

```dart
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users') // 'table' maps to MongoDB collection name
class User extends Model<User> {
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.metadata = const {},
  });

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final String id; // MongoDB uses String IDs by default

  @OrmField(isUnique: true)
  final String email;

  final String name;

  // MongoDB excels at nested documents
  final Map<String, dynamic> metadata;
}
```

**Note**: MongoDB uses `_id` as the primary key field name by default. Use `columnName: '_id'` in your annotation.

## Querying

Most query builder methods work identically to SQL drivers:

```dart
// Basic queries
final users = await context
    .query<User>()
    .whereEquals('name', 'John')
    .orderBy('email')
    .limit(10)
    .get();

// Complex filters
final activeUsers = await context
    .query<User>()
    .whereEquals('active', true)
    .whereGreaterThan('created_at', DateTime(2024))
    .whereIn('role', ['admin', 'editor'])
    .get();

// Count
final count = await context.query<User>().count();

// Exists
final hasUsers = await context.query<User>().exists();
```

## MongoDB-Specific Features

### Nested Field Queries

MongoDB excels at querying nested documents:

```dart
// Query nested fields using dot notation
final users = await context
    .query<User>()
    .whereEquals('metadata.subscription', 'premium')
    .whereGreaterThan('metadata.score', 100)
    .get();
```

### Array Queries

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> {
  const Post({
    required this.id,
    required this.title,
    required this.tags,
  });

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final String id;

  final String title;
  final List<String> tags;
}

// Query documents where array contains value
final posts = await context
    .query<Post>()
    .whereEquals('tags', 'mongodb') // Matches if 'mongodb' is in tags array
    .get();

// Query with $in on arrays
final posts = await context
    .query<Post>()
    .whereIn('tags', ['mongodb', 'dart']) // Matches if any tag is in the list
    .get();
```

## Relations in MongoDB

MongoDB relations work the same as SQL drivers, using the aggregation pipeline under the hood:

### BelongsTo

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> {
  const Post({
    required this.id,
    required this.authorId,
    required this.title,
    this.author,
  });

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final String id;

  @OrmField(columnName: 'author_id')
  final String authorId;

  final String title;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.belongsTo,
    target: Author,
    foreignKey: 'author_id',
    localKey: '_id',
  )
  final Author? author;
}

// Eager load
final posts = await context
    .query<Post>()
    .withRelation('author')
    .get();

// Uses MongoDB $lookup:
// [
//   { $lookup: {
//       from: 'authors',
//       localField: 'author_id',
//       foreignField: '_id',
//       as: 'author'
//   }},
//   { $unwind: { path: '$author', preserveNullAndEmptyArrays: true }}
// ]
```

### HasMany

```dart
@OrmModel(table: 'authors')
class Author extends Model<Author> {
  const Author({
    required this.id,
    required this.name,
    this.posts = const [],
  });

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final String id;

  final String name;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.hasMany,
    target: Post,
    foreignKey: 'author_id',
    localKey: '_id',
  )
  final List<Post> posts;
}

final authors = await context
    .query<Author>()
    .withRelation('posts')
    .get();
```

### ManyToMany

MongoDB handles many-to-many relationships using a separate collection:

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> {
  const Post({
    required this.id,
    required this.title,
    this.tags = const [],
  });

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final String id;

  final String title;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.manyToMany,
    target: Tag,
    through: 'post_tags',
    pivotForeignKey: 'post_id',
    pivotRelatedKey: 'tag_id',
  )
  final List<Tag> tags;
}

// Eager load with pivot lookups
final posts = await context
    .query<Post>()
    .withRelation('tags')
    .get();

// Mutation helpers work the same
await post.attach('tags', ['tag1', 'tag2']);
await post.detach('tags', ['tag1']);
await post.sync('tags', ['tag2', 'tag3']);
```

## Relation Aggregates

MongoDB implements relation aggregates using its native aggregation pipeline with `$lookup` and `$group`:

```dart
// Count related documents
final authors = await context
    .query<Author>()
    .withCount('posts')
    .get();

for (final author in authors) {
  final count = author.getAttribute<int>('posts_count');
  print('${author.name} has $count posts');
}

// Sum, average, min, max
final authors = await context
    .query<Author>()
    .withSum('posts', 'views', alias: 'total_views')
    .withAvg('posts', 'views', alias: 'avg_views')
    .withMax('posts', 'views', alias: 'max_views')
    .withMin('posts', 'views', alias: 'min_views')
    .get();

// Behind the scenes, MongoDB uses:
// [
//   { $lookup: { from: 'posts', localField: '_id', foreignField: 'author_id', as: 'posts' }},
//   { $unwind: { path: '$posts', preserveNullAndEmptyArrays: true }},
//   { $group: {
//       _id: '$_id',
//       total_views: { $sum: '$posts.views' },
//       avg_views: { $avg: '$posts.views' },
//       doc: { $first: '$$ROOT' }
//   }},
//   { $replaceRoot: { newRoot: { $mergeObjects: ['$doc', { total_views: '$total_views' }] }}}
// ]
```

Lazy loading aggregates also work:

```dart
final author = await Author.query().first();
await author.loadCount('posts');
await author.loadSum('posts', 'views');
print('Total views: ${author.getAttribute<num>('posts_sum_views')}');
```

## Limitations

MongoDB has some limitations compared to SQL databases:

### ❌ Raw SQL/Query Expressions

MongoDB doesn't support raw SQL since it uses its own query language:

```dart
// ❌ These don't work on MongoDB:
context.query<User>().selectRaw('COUNT(*) as total'); // Throws UnsupportedError
context.query<User>().whereRaw('age > 18'); // Throws UnsupportedError
context.query<User>().havingRaw('COUNT(*) > 5'); // Throws UnsupportedError
```

**Workaround**: Use the query builder's native methods:

```dart
// ✅ Use query builder methods instead:
final count = await context.query<User>().count();
final adults = await context.query<User>().whereGreaterThan('age', 18).get();
```

### ⚠️ Limited JOIN Support

MongoDB doesn't have traditional SQL JOINs. Use `$lookup` via relations instead:

```dart
// ❌ Don't use manual joins:
context.query<Post>().join('authors', ...); // Limited support

// ✅ Use relation loading:
context.query<Post>().withRelation('author');
```

### ⚠️ Transaction Limitations

MongoDB transactions require replica sets or sharded clusters (not available in standalone mode):

```dart
// Only works with replica sets
await context.transaction(() async {
  await context.repository<User>().insert(user);
  await context.repository<Post>().insert(post);
});
```

For local development, either:
1. Set up a replica set
2. Use individual operations (MongoDB's atomic document updates are quite powerful)

## Capabilities System

The driver advertises its capabilities, and tests automatically skip unsupported features:

```dart
final adapter = MongoDriverAdapter.uri('mongodb://localhost:27017/test');

// Check capabilities
if (adapter.supportsCapability(DriverCapability.rawSQL)) {
  // This will be false for MongoDB
  query.selectRaw('...');
}

if (adapter.supportsCapability(DriverCapability.relationAggregates)) {
  // This will be true for MongoDB
  query.withSum('posts', 'views');
}
```

### Supported Capabilities

| Capability | MongoDB | SQLite | PostgreSQL | MySQL |
|------------|---------|--------|------------|-------|
| `queryDeletes` | ✅ | ✅ | ✅ | ✅ |
| `schemaIntrospection` | ✅ | ✅ | ✅ | ✅ |
| `transactions` | ⚠️ Replica sets only | ✅ | ✅ | ✅ |
| `rawSQL` | ❌ | ✅ | ✅ | ✅ |
| `adHocQueryUpdates` | ❌ | ✅ | ✅ | ✅ |
| `joins` | ⚠️ Limited | ✅ | ✅ | ✅ |
| `relationAggregates` | ✅ | ✅ | ✅ | ✅ |

## Best Practices

### 1. Embrace Document Model

Store related data in nested documents when appropriate:

```dart
@OrmModel(table: 'users')
class User extends Model<User> {
  const User({
    required this.id,
    required this.email,
    required this.profile,
    required this.settings,
  });

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final String id;

  final String email;

  // Instead of a separate 'profiles' table, embed the data
  final UserProfile profile;
  final Map<String, dynamic> settings;
}
```

### 2. Use Relations for True Relationships

Use relations when data needs to be queried independently:

```dart
// Posts should be separate documents (queried independently)
@OrmRelation(
  kind: RelationKind.hasMany,
  target: Post,
  foreignKey: 'author_id',
  localKey: '_id',
)
final List<Post> posts;

// But post metadata can be embedded
final Map<String, dynamic> metadata;
```

### 3. Leverage Indexes

Create indexes for frequently queried fields:

```dart
// In your migration
await db.collection('users').createIndex({
  'email': 1,
  'created_at': -1,
});
```

### 4. Use Aggregates Wisely

Relation aggregates are powerful but can be expensive:

```dart
// ✅ Good: Load aggregates once
final authors = await context
    .query<Author>()
    .withCount('posts')
    .withSum('posts', 'views')
    .get();

// ❌ Avoid: Lazy loading aggregates in loops
for (final author in authors) {
  await author.loadCount('posts'); // N+1 problem!
}
```

### 5. Consider Denormalization

MongoDB performs better with some denormalization:

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> {
  const Post({
    required this.id,
    required this.title,
    required this.authorId,
    required this.authorName, // Denormalized for quick access
  });

  final String authorId;
  final String authorName; // Duplicate of author.name
}
```

## Testing

Use the driver test harness with capability-aware test skipping:

```dart
import 'package:driver_tests/driver_tests.dart';

void main() {
  final config = DriverTestConfig(
    driverName: 'MongoDB',
    capabilities: {
      DriverCapability.queryDeletes,
      DriverCapability.schemaIntrospection,
      DriverCapability.relationAggregates, // Supported!
    },
  );

  test('raw SQL queries', () async {
    // This test will be skipped on MongoDB
  }, skip: !config.supportsCapability(DriverCapability.rawSQL));

  test('relation aggregates', () async {
    // This test will run on MongoDB
    final authors = await context.query<Author>().withCount('posts').get();
    expect(authors.first.getAttribute<int>('posts_count'), greaterThan(0));
  }, skip: !config.supportsCapability(DriverCapability.relationAggregates));
}
```

## Complete Example

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';

Future<void> main() async {
  // Setup
  final adapter = MongoDriverAdapter.uri('mongodb://localhost:27017/blog');
  final registry = ModelRegistry()
    ..register(AuthorOrmDefinition.definition)
    ..register(PostOrmDefinition.definition);

  final context = QueryContext(registry: registry, driver: adapter);
  Model.bindConnectionResolver(resolveConnection: (_) => context);

  // Insert authors
  await context.repository<Author>().insertMany([
    const Author(id: '1', name: 'Alice'),
    const Author(id: '2', name: 'Bob'),
  ]);

  // Insert posts
  await context.repository<Post>().insertMany([
    const Post(id: '1', authorId: '1', title: 'MongoDB Basics', views: 100),
    const Post(id: '2', authorId: '1', title: 'Advanced MongoDB', views: 250),
    const Post(id: '3', authorId: '2', title: 'Dart ORM', views: 180),
  ]);

  // Query with aggregates using MongoDB's aggregation pipeline
  final authors = await context
      .query<Author>()
      .withCount('posts')
      .withSum('posts', 'views', alias: 'total_views')
      .withAvg('posts', 'views', alias: 'avg_views')
      .get();

  for (final author in authors) {
    print('${author.name}:');
    print('  Posts: ${author.getAttribute<int>('posts_count')}');
    print('  Total views: ${author.getAttribute<num>('total_views')}');
    print('  Avg views: ${author.getAttribute<num>('avg_views')}');
  }

  // Lazy load with nested relations
  final post = await Post.query().firstOrFail();
  await post.load('author');
  await post.loadCount('comments');

  print('\n${post.title} by ${post.author?.name}');
  print('Comments: ${post.getAttribute<int>('comments_count')}');

  // Cleanup
  Model.unbindConnectionResolver();
  await adapter.close();
}
```

## Migration from SQL

If you're migrating from a SQL database:

1. **IDs**: Change `int` primary keys to `String` and use `columnName: '_id'`
2. **Relations**: Keep the same relation definitions, they work identically
3. **Raw SQL**: Replace with query builder methods
4. **JOINs**: Use `withRelation()` instead of manual joins
5. **Transactions**: Ensure you're using replica sets if you need transactions
6. **Denormalization**: Consider embedding frequently accessed related data

## Resources

- [MongoDB Manual](https://docs.mongodb.com/manual/)
- [Aggregation Pipeline](https://docs.mongodb.com/manual/core/aggregation-pipeline/)
- [mongo_dart Package](https://pub.dev/packages/mongo_dart)
- [Ormed Relations Guide](relations.md)
- [Driver Capabilities](driver_capabilities.md)

---

**Next**: Read the [Relations & Lazy Loading](relations.md) guide for comprehensive relation management patterns that work across all drivers.
