# Best Practices

This guide covers recommended patterns, common pitfalls, and optimization strategies for using Ormed effectively.

## Table of Contents

1. [Query Optimization](#query-optimization)
2. [Relation Loading Strategies](#relation-loading-strategies)
3. [Model Design](#model-design)
4. [Error Handling](#error-handling)
5. [Testing](#testing)
6. [Performance Monitoring](#performance-monitoring)
7. [Security](#security)

---

## Query Optimization

### 1. Avoid N+1 Queries

**❌ Bad**: Lazy loading in loops

```dart
final users = await context.query<User>().get();

for (final user in users) {
  await user.load('posts'); // N+1 problem! (1 query + N queries)
}
```

**✅ Good**: Eager load relations upfront

```dart
final users = await context
    .query<User>()
    .withRelation('posts')
    .get();

for (final user in users) {
  print(user.posts.length); // Already loaded, no queries
}
```

**✅ Good**: Batch load for collections

```dart
final users = await context.query<User>().get();
await Model.loadRelations(users, 'posts'); // Single query for all posts
```

### 2. Use Aggregate Loaders

**❌ Bad**: Loading full collections just to count

```dart
await post.load('comments');
final count = post.comments.length; // Loaded all comments into memory!
```

**✅ Good**: Use aggregate loaders

```dart
await post.loadCount('comments');
final count = post.getAttribute<int>('comments_count'); // Single COUNT query
```

**✅ Good**: Eager load aggregates for collections

```dart
final posts = await context
    .query<Post>()
    .withCount('comments')
    .withSum('orders', 'total', alias: 'revenue')
    .get();

for (final post in posts) {
  final comments = post.getAttribute<int>('comments_count');
  final revenue = post.getAttribute<num>('revenue');
  print('$comments comments, \$$revenue revenue');
}
```

### 3. Select Only What You Need

**❌ Bad**: Selecting all columns when you only need a few

```dart
final users = await context
    .query<User>()
    .get(); // Loads all columns
```

**✅ Good**: Use `pluck()` for single columns

```dart
final emails = await context
    .query<User>()
    .pluck('email');
```

**✅ Good**: Project specific columns with ad-hoc queries

```dart
final rows = await context
    .table('users', columns: [
      AdHocColumn(name: 'id'),
      AdHocColumn(name: 'email'),
    ])
    .get();
```

### 4. Use Pagination

**❌ Bad**: Loading thousands of records at once

```dart
final posts = await context
    .query<Post>()
    .get(); // Could return millions of rows!
```

**✅ Good**: Use limit and offset

```dart
final posts = await context
    .query<Post>()
    .orderBy('created_at', descending: true)
    .limit(20)
    .offset(page * 20)
    .get();
```

**✅ Better**: Use cursor pagination for better performance

```dart
final result = await context
    .query<Post>()
    .orderBy('id')
    .cursorPaginate(
      limit: 20,
      cursor: lastSeenId,
      cursorColumn: 'id',
    );

final posts = result.data;
final nextCursor = result.nextCursor;
```

### 5. Index Frequently Queried Columns

Create database indexes for columns used in `WHERE`, `ORDER BY`, and `JOIN` clauses:

```dart
// In your migration
await schema.table('users', (table) {
  table.string('email').unique();
  table.timestamp('created_at');
  table.index(['email']); // For WHERE email = ...
  table.index(['created_at']); // For ORDER BY created_at
  table.index(['status', 'created_at']); // Composite index for common query
});
```

---

## Relation Loading Strategies

### When to Use Eager Loading

✅ Use when you **know** you'll need the relations:
- List views showing related data
- APIs returning nested resources
- Reports and dashboards

```dart
// Good: Blog post list with author info
final posts = await context
    .query<Post>()
    .withRelation('author')
    .withCount('comments')
    .orderBy('published_at', descending: true)
    .limit(10)
    .get();
```

### When to Use Lazy Loading

✅ Use when relations are **conditionally** needed:
- Detail views where relations depend on user permissions
- Optional expansions based on request parameters
- Complex business logic determining what to load

```dart
// Good: Conditional loading based on permissions
final post = await Post.query().firstOrFail();

if (currentUser.canSeeAuthor) {
  await post.load('author');
}

if (currentUser.canSeeDrafts) {
  await post.load('drafts');
}
```

### Use LoadMissing for Hybrid Scenarios

✅ When combining eager and lazy loading:

```dart
// Controller loads basic relations
final post = await Post.query()
    .withRelation('author')
    .firstOrFail();

// Service layer needs more relations
// but doesn't know what's already loaded
await post.loadMissing(['author', 'tags', 'comments']);
// Only loads 'tags' and 'comments'
```

### Prevent Lazy Loading in Production

✅ Catch N+1 problems during development:

```dart
void main() {
  // Enable in development/test
  if (kDebugMode || environment == 'test') {
    ModelRelations.preventsLazyLoading = true;
  }

  runApp(MyApp());
}
```

Now accidental lazy loads throw exceptions, forcing you to fix them.

---

## Model Design

### 1. Extend Model<T> for Full Features

**✅ Recommended**: Extend `Model<T>` to get all features

```dart
@OrmModel(table: 'users')
class User extends Model<User> {
  const User({required this.id, required this.email});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String email;
}

// Benefits:
// - Lazy loading: await user.load('posts')
// - Relation mutations: user.associate('role', role)
// - Persistence: await user.save()
// - Attributes: user.getAttribute('computed_value')
```

### 2. Use Immutable Models

**✅ Good**: Define models as immutable

```dart
@OrmModel(table: 'users')
class User extends Model<User> {
  const User({required this.id, required this.email});

  final int id; // Immutable
  final String email; // Immutable

  // Create new instances for updates
  User copyWith({int? id, String? email}) => User(
    id: id ?? this.id,
    email: email ?? this.email,
  );
}
```

Benefits:
- Thread-safe
- Predictable behavior
- Easy to test
- Follows Dart best practices

### 3. Use Proper Field Types

**✅ Good**: Match Dart types to database columns

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> {
  final int id;                    // INTEGER
  final String title;              // VARCHAR/TEXT
  final String? subtitle;          // Nullable VARCHAR
  final DateTime publishedAt;      // TIMESTAMP
  final bool isPublished;          // BOOLEAN
  final double rating;             // REAL/DOUBLE
  final Map<String, dynamic> meta; // JSON
  final List<String> tags;         // JSON array
}
```

### 4. Document Relations Clearly

**✅ Good**: Add comments explaining relations

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> {
  // One-to-many: A post belongs to one author
  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.belongsTo,
    target: Author,
    foreignKey: 'author_id',
    localKey: 'id',
  )
  final Author? author;

  // Many-to-many: A post can have many tags
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
```

### 5. Use Soft Deletes Wisely

**✅ Good**: Use soft deletes for important data

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> with SoftDeletes {
  // Automatically adds deleted_at handling

  @override
  String get softDeleteColumn => 'deleted_at';
}

// Query with soft deletes
final posts = await context.query<Post>().get(); // Excludes deleted

final all = await context.query<Post>().withTrashed().get(); // Includes all

final deleted = await context.query<Post>().onlyTrashed().get(); // Only deleted

// Restore
await context.query<Post>().whereEquals('id', 1).restore();

// Permanently delete
await context.query<Post>().whereEquals('id', 1).forceDelete();
```

**⚠️ Consider**: Soft deletes add complexity. Only use when:
- You need audit trails
- Data recovery is important
- Compliance requires retention

---

## Error Handling

### 1. Use Typed Exceptions

**✅ Good**: Catch specific exceptions

```dart
try {
  final user = await context
      .query<User>()
      .whereEquals('email', email)
      .firstOrFail();
} on ModelNotFoundException catch (e) {
  return Response.notFound('User not found');
} on MultipleRecordsFoundException catch (e) {
  return Response.error('Multiple users found with that email');
}
```

### 2. Handle Lazy Loading Violations

**✅ Good**: Gracefully handle lazy loading violations

```dart
try {
  await post.load('author');
} on LazyLoadingViolationException catch (e) {
  logger.warning('Lazy loading blocked: ${e.relationName} on ${e.modelName}');
  // Fall back to eager loading
  final post = await Post.query()
      .whereEquals('id', post.id)
      .withRelation('author')
      .firstOrFail();
}
```

### 3. Validate Before Save

**✅ Good**: Add validation methods

```dart
@OrmModel(table: 'users')
class User extends Model<User> {
  const User({required this.email, required this.age});

  final String email;
  final int age;

  void validate() {
    if (!email.contains('@')) {
      throw ArgumentError('Invalid email format');
    }
    if (age < 0 || age > 150) {
      throw ArgumentError('Invalid age');
    }
  }
}

// Before inserting
user.validate();
await context.repository<User>().insert(user);
```

### 4. Use Transactions for Critical Operations

**✅ Good**: Wrap related operations in transactions

```dart
await context.transaction(() async {
  // Deduct from source account
  await context
      .query<Account>()
      .whereEquals('id', fromAccountId)
      .update({'balance': sourceBalance - amount});

  // Add to destination account
  await context
      .query<Account>()
      .whereEquals('id', toAccountId)
      .update({'balance', destBalance + amount});

  // Record transaction
  await context
      .repository<Transaction>()
      .insert(transaction);
});
```

**⚠️ Note**: MongoDB transactions require replica sets.

---

## Testing

### 1. Use In-Memory Databases for Tests

**✅ Good**: Use SQLite in-memory for fast tests

```dart
void main() {
  late QueryContext context;
  late SqliteDriverAdapter adapter;

  setUp(() async {
    adapter = SqliteDriverAdapter.memory(); // Fast, isolated
    context = QueryContext(
      registry: buildOrmRegistry(),
      driver: adapter,
    );

    // Run migrations
    await runMigrations(adapter);
  });

  tearDown(() async {
    await adapter.close();
  });

  test('user creation', () async {
    await context.repository<User>().insert(user);
    final found = await context.query<User>().firstOrNull();
    expect(found?.email, equals(user.email));
  });
}
```

### 2. Use Factories for Test Data

**✅ Good**: Generate test data with factories

```dart
import 'package:ormed/factories.dart';

final userFactory = ModelFactory<User>(
  (faker) => User(
    id: faker.randomGenerator.integer(1000000),
    email: faker.internet.email(),
    name: faker.person.name(),
  ),
);

// In tests
test('bulk operations', () async {
  final users = userFactory.makeMany(100);
  await context.repository<User>().insertMany(users);

  final count = await context.query<User>().count();
  expect(count, equals(100));
});
```

### 3. Test Relation Loading

**✅ Good**: Verify relations are loaded correctly

```dart
test('eager loading posts with author', () async {
  final posts = await context
      .query<Post>()
      .withRelation('author')
      .get();

  expect(posts, isNotEmpty);
  expect(posts.first.author, isNotNull);
  expect(posts.first.relationLoaded('author'), isTrue);
});

test('lazy loading prevention', () async {
  ModelRelations.preventsLazyLoading = true;

  final post = await Post.query().first();
  expect(
    () => post.load('author'),
    throwsA(isA<LazyLoadingViolationException>()),
  );

  ModelRelations.preventsLazyLoading = false;
});
```

### 4. Use Capability-Aware Tests

**✅ Good**: Skip tests for unsupported features

```dart
test('raw SQL expressions', () async {
  final users = await context
      .query<User>()
      .selectRaw('COUNT(*) as total')
      .get();

  expect(users, isNotEmpty);
}, skip: !adapter.supportsCapability(DriverCapability.rawSQL));
```

---

## Performance Monitoring

### 1. Enable Query Logging

**✅ Good**: Log queries in development

```dart
if (kDebugMode) {
  StructuredQueryLogger(
    onLog: (entry) {
      if (entry['duration_ms'] > 100) {
        logger.warning('Slow query: ${entry['sql']}');
      }
    },
    includeParameters: true,
  ).attach(context);
}
```

### 2. Monitor Query Count

**✅ Good**: Track queries per request

```dart
int queryCount = 0;

context.onQuery.listen((event) {
  queryCount++;
  if (queryCount > 10) {
    logger.warning('High query count: $queryCount queries');
  }
});
```

### 3. Profile Slow Queries

**✅ Good**: Log slow queries for optimization

```dart
context.onQuery.listen((event) {
  if (event.duration.inMilliseconds > 100) {
    logger.warning('Slow query: ${event.preview.sql}');
    logger.debug('Duration: ${event.duration.inMilliseconds}ms');
    logger.debug('Parameters: ${event.preview.parameters}');
  }
});
```

---

## Security

### 1. Never Use Raw User Input

**❌ Bad**: Concatenating user input

```dart
// NEVER DO THIS!
final users = await context
    .query<User>()
    .whereRaw("email = '$userInput'") // SQL injection!
    .get();
```

**✅ Good**: Use parameterized queries

```dart
final users = await context
    .query<User>()
    .whereEquals('email', userInput) // Safe, parameterized
    .get();
```

### 2. Validate Relations Before Mutations

**✅ Good**: Check permissions before associating

```dart
Future<void> assignAuthor(Post post, Author author) async {
  // Validate author exists and is active
  final validAuthor = await context
      .query<Author>()
      .whereEquals('id', author.id)
      .whereEquals('active', true)
      .firstOrNull();

  if (validAuthor == null) {
    throw UnauthorizedException('Invalid author');
  }

  post.associate('author', validAuthor);
  await post.save();
}
```

### 3. Use Scopes for Multi-Tenancy

**✅ Good**: Automatically filter by tenant

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> {
  final int tenantId;
  final String title;
}

// Register global scope
context.scopeRegistry.registerScope<Post>((query) {
  query.whereEquals('tenant_id', currentTenantId);
});

// All queries automatically filtered
final posts = await context.query<Post>().get();
// SELECT * FROM posts WHERE tenant_id = ?
```

### 4. Limit Exposed Fields

**✅ Good**: Create DTOs for API responses

```dart
// Internal model with sensitive data
@OrmModel(table: 'users')
class User extends Model<User> {
  final String email;
  final String passwordHash; // Sensitive!
  final String apiToken;     // Sensitive!
}

// Public DTO
class UserDto {
  final int id;
  final String email;
  // No sensitive fields

  factory UserDto.fromModel(User user) => UserDto(
    id: user.id,
    email: user.email,
  );
}

// Return DTOs, not models
final users = await context.query<User>().get();
return users.map(UserDto.fromModel).toList();
```

---

## Summary Checklist

### Query Performance
- [ ] Use eager loading instead of lazy loading in loops
- [ ] Use aggregate loaders (loadCount, loadSum) instead of loading full collections
- [ ] Add database indexes for frequently queried columns
- [ ] Use pagination for large result sets
- [ ] Monitor and log slow queries

### Relation Loading
- [ ] Enable lazy loading prevention in development
- [ ] Use `loadMissing()` when combining eager and lazy loading
- [ ] Prefer eager loading for known relationships
- [ ] Use batch loading for collections

### Model Design
- [ ] Extend `Model<T>` for full feature support
- [ ] Use immutable models
- [ ] Document relations with comments
- [ ] Add validation methods
- [ ] Use soft deletes only when needed

### Error Handling
- [ ] Catch specific exceptions (ModelNotFoundException, etc.)
- [ ] Handle lazy loading violations gracefully
- [ ] Use transactions for critical operations
- [ ] Validate data before persistence

### Testing
- [ ] Use in-memory databases for fast tests
- [ ] Generate test data with factories
- [ ] Test relation loading behavior
- [ ] Use capability-aware test skipping

### Security
- [ ] Never concatenate user input in queries
- [ ] Always use parameterized queries
- [ ] Validate relations before mutations
- [ ] Use scopes for multi-tenancy
- [ ] Create DTOs for API responses

---

**Next**: Explore specific topics in depth:
- [Relations & Lazy Loading](relations.md)
- [Query Builder](query_builder.md)
- [MongoDB Guide](mongodb.md)
- [Driver Capabilities](driver_capabilities.md)
