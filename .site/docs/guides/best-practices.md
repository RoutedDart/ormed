---
sidebar_position: 2
---

# Best Practices

Recommended patterns, common pitfalls, and optimization strategies for using Ormed effectively.

## Query Optimization

### Avoid N+1 Queries

**❌ Bad:** Lazy loading in loops

```dart
final users = await dataSource.query<$User>().get();

for (final user in users) {
  await user.load(['posts']); // N+1 problem!
}
```

**✅ Good:** Eager load relations upfront

```dart
final users = await dataSource.query<$User>()
    .with_(['posts'])
    .get();

for (final user in users) {
  print(user.posts.length); // Already loaded
}
```

### Use Aggregate Loaders

**❌ Bad:** Loading full collections to count

```dart
await post.load(['comments']);
final count = post.comments.length; // Loaded all into memory!
```

**✅ Good:** Use aggregate loaders

```dart
await post.loadCount(['comments']);
final count = post.getAttribute<int>('comments_count');
```

### Select Only What You Need

**❌ Bad:** Selecting all columns

```dart
final users = await dataSource.query<$User>().get();
```

**✅ Good:** Use `pluck()` for single columns

```dart
final emails = await dataSource.query<$User>().pluck('email');
```

### Use Pagination

**❌ Bad:** Loading thousands of records

```dart
final posts = await dataSource.query<$Post>().get();
```

**✅ Good:** Use limit and offset

```dart
final posts = await dataSource.query<$Post>()
    .orderBy('created_at', descending: true)
    .limit(20)
    .offset(page * 20)
    .get();
```

### Index Frequently Queried Columns

```dart
schema.create('users', (table) {
  table.string('email').unique();
  table.timestamp('created_at');
  table.index(['email']);
  table.index(['created_at']);
  table.index(['status', 'created_at']); // Composite index
});
```

## Relation Loading Strategies

### When to Use Eager Loading

✅ Use when you **know** you'll need the relations:
- List views showing related data
- APIs returning nested resources
- Reports and dashboards

```dart
final posts = await dataSource.query<$Post>()
    .with_(['author'])
    .withCount(['comments'])
    .orderBy('published_at', descending: true)
    .limit(10)
    .get();
```

### When to Use Lazy Loading

✅ Use when relations are **conditionally** needed:
- Detail views with permission-based data
- Optional expansions based on request parameters

```dart
final post = await dataSource.query<$Post>().first();

if (currentUser.canSeeAuthor) {
  await post.load(['author']);
}
```

### Use loadMissing for Hybrid Scenarios

```dart
// Controller loads basic relations
final post = await dataSource.query<$Post>()
    .with_(['author'])
    .first();

// Service layer needs more
await post.loadMissing(['author', 'tags', 'comments']);
// Only loads 'tags' and 'comments'
```

### Prevent Lazy Loading in Development

```dart
void main() {
  if (kDebugMode) {
    ModelRelations.preventsLazyLoading = true;
  }
  runApp(MyApp());
}
```

## Model Design

### Extend Model for Full Features

```dart
@OrmModel(table: 'users')
class User extends Model<User> {
  const User({required this.id, required this.email});

  @OrmField(isPrimaryKey: true)
  final int id;
  final String email;
}
```

Benefits:
- Lazy loading: `await user.load(['posts'])`
- Relation mutations: `user.associate('role', role)`
- Persistence: `await user.save()`
- Attributes: `user.getAttribute('computed_value')`

### Use Immutable Models

```dart
@OrmModel(table: 'users')
class User extends Model<User> {
  const User({required this.id, required this.email});

  final int id;
  final String email;

  User copyWith({int? id, String? email}) => User(
    id: id ?? this.id,
    email: email ?? this.email,
  );
}
```

Benefits: Thread-safe, predictable, easy to test.

### Use Soft Deletes Wisely

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> with SoftDeletes {
  // Automatically adds deleted_at handling
}

// Query with soft deletes
final posts = await dataSource.query<$Post>().get(); // Excludes deleted
final all = await dataSource.query<$Post>().withTrashed().get();
final deleted = await dataSource.query<$Post>().onlyTrashed().get();
```

⚠️ Only use soft deletes when:
- You need audit trails
- Data recovery is important
- Compliance requires retention

## Error Handling

### Use Typed Exceptions

```dart
try {
  final user = await dataSource.query<$User>()
      .whereEquals('email', email)
      .firstOrFail();
} on ModelNotFoundException catch (e) {
  return Response.notFound('User not found');
}
```

### Validate Before Save

```dart
@OrmModel(table: 'users')
class User extends Model<User> {
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
await dataSource.repo<$User>().insert(user);
```

### Use Transactions for Critical Operations

```dart
await dataSource.transaction(() async {
  await dataSource.query<$Account>()
      .whereEquals('id', fromAccountId)
      .update({'balance': sourceBalance - amount});

  await dataSource.query<$Account>()
      .whereEquals('id', toAccountId)
      .update({'balance': destBalance + amount});

  await dataSource.repo<$Transaction>().insert(transaction);
});
```

## Testing

### Use In-Memory Databases

```dart
driver: InMemoryQueryExecutor()  // Fast, isolated
```

### Use Factories for Test Data

```dart
final userFactory = Model.factory<User>();

test('bulk operations', () async {
  for (var i = 0; i < 100; i++) {
    await userFactory
        .seed(i)
        .withField('email', 'user_$i@test.com')
        .create(context: dataSource.context);
  }
  
  expect(await dataSource.query<$User>().count(), equals(100));
});
```

## Security

### Never Use Raw User Input

**❌ Bad:** SQL injection risk

```dart
final users = await dataSource.query<$User>()
    .whereRaw("email = '$userInput'")
    .get();
```

**✅ Good:** Parameterized queries

```dart
final users = await dataSource.query<$User>()
    .whereEquals('email', userInput)
    .get();
```

### Validate Relations Before Mutations

```dart
Future<void> assignAuthor(Post post, Author author) async {
  final validAuthor = await dataSource.query<$Author>()
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

### Use Scopes for Multi-Tenancy

```dart
context.scopeRegistry.registerScope<$Post>((query) {
  query.whereEquals('tenant_id', currentTenantId);
});

// All queries automatically filtered
final posts = await dataSource.query<$Post>().get();
// SQL: SELECT * FROM posts WHERE tenant_id = ?
```

### Limit Exposed Fields

Create DTOs for API responses:

```dart
class UserDto {
  final int id;
  final String email;
  // No passwordHash or apiToken

  factory UserDto.fromModel(User user) => UserDto(
    id: user.id,
    email: user.email,
  );
}

// Return DTOs, not models
final users = await dataSource.query<$User>().get();
return users.map(UserDto.fromModel).toList();
```

## Summary Checklist

### Query Performance
- [ ] Use eager loading instead of lazy loading in loops
- [ ] Use aggregate loaders instead of loading full collections
- [ ] Add database indexes for frequently queried columns
- [ ] Use pagination for large result sets

### Model Design
- [ ] Extend `Model<T>` for full feature support
- [ ] Use immutable models
- [ ] Add validation methods
- [ ] Use soft deletes only when needed

### Error Handling
- [ ] Catch specific exceptions
- [ ] Use transactions for critical operations
- [ ] Validate data before persistence

### Security
- [ ] Never concatenate user input in queries
- [ ] Validate relations before mutations
- [ ] Use scopes for multi-tenancy
- [ ] Create DTOs for API responses
