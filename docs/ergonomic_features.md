# Ergonomic Features

This document highlights the developer experience (DX) improvements and ergonomic patterns available in Ormed, inspired by Laravel's Eloquent ORM.

## Static Query Helpers

All models inherit convenient static helpers for cleaner query building:

### Prerequisites

Before using static helpers, ensure you have:

1. **Registered Model Definitions** - Register your model with the definition registry:

```dart
// During application initialization
void main() async {
  // Register model definitions
  ModelDefinitionRegistry.instance.register(User, UserDefinition());
  ModelDefinitionRegistry.instance.register(Post, PostDefinition());
  
  runApp(MyApp());
}
```

2. **DataSource Setup** (Recommended) - Configure a DataSource for automatic binding:

```dart
import 'package:ormed/ormed.dart';

void main() async {
  // Create and configure DataSource
  final dataSource = DataSource(DataSourceOptions(
    name: 'myapp',  // Can be any name
    driver: SqliteDriverAdapter.file('app.db'),
    entities: [
      UserOrmDefinition.definition,
      PostOrmDefinition.definition,
      CommentOrmDefinition.definition,
    ],
  ));
  
  // Initialize database - automatically registers and sets as default if first
  await dataSource.init();
  
  // Static helpers now work automatically!
  final users = await User.all();
  
  runApp(MyApp());
}
```

> **Note**: The first DataSource initialized automatically becomes the default. For multiple DataSources, explicitly call `dataSource.setAsDefault()` on your preferred one.

3. **Manual Binding** (Alternative) - Or bind manually per query if needed:

```dart
// Explicit binding
final query = User.query();
BindingResolver.instance.bind(query, context);

// Or use with explicit connection
final users = await User.query(connection: 'admin').get();
```

### Usage

Once setup is complete, use static helpers via the generated extension:

```dart
// Note: Call via UserOrmDefinition, not User
// (Dart limitation: extension static members can't be called on the type)

// Instead of:
final users = await context.query<User>().whereEquals('active', true).get();

// You can write:
final users = await UserOrmDefinition.query().whereEquals('active', true).get();

// With custom connection:
final adminUsers = await UserOrmDefinition.query(connection: 'admin').get();
```

### Common Static Helpers

```dart
// Find by primary key
final user = await UserOrmDefinition.find(1);  // Returns null if not found
final user = await UserOrmDefinition.findOrFail(1);  // Throws if not found

// Find multiple by IDs
final users = await UserOrmDefinition.findMany([1, 2, 3]);

// Get all records
final users = await UserOrmDefinition.all();

// Get first record
final user = await UserOrmDefinition.first();  // Returns null if none
final user = await UserOrmDefinition.firstOrFail();  // Throws if none

// Create a new record
final user = User(name: 'Alice', email: 'alice@example.com');
await User.create(user);

// First or create pattern
final user = await User.firstOrCreate(
  {'email': 'alice@example.com'},  // Search criteria
  {'name': 'Alice', 'active': true},  // Additional values if creating
);

// Update or create pattern
final user = await User.updateOrCreate(
  {'email': 'alice@example.com'},  // Search criteria
  {'name': 'Alice Updated', 'active': true},  // Values to set
);

// Count records
final count = await User.count();

// Check existence
final hasUsers = await User.exists();
final noUsers = await User.doesntExist();

// Delete by IDs
final deleted = await User.destroy([1, 2, 3]);
```

## Lazy Loading Control

### Automatic Lazy Loading

Relations are automatically lazy-loaded when accessed if not already loaded:

```dart
final user = await User.query().find(1);
// Relations not loaded yet

final posts = user.posts; // Automatically lazy-loads posts
```

### Preventing N+1 Problems

Globally disable lazy loading in development to catch N+1 queries:

```dart
void main() {
  Model.preventLazyLoading(enabled: true);
  
  final user = await User.query().find(1);
  
  // This will throw LazyLoadingViolationException
  final posts = user.posts;
}
```

### Eager Loading

Load relations upfront to avoid N+1:

```dart
final users = await User.query()
    .withRelation('posts')
    .withRelation('posts.comments')
    .get();

// All relations already loaded
for (final user in users) {
  print(user.posts); // No additional queries
}
```

### Load Missing Relations

Load relations only if they haven't been loaded yet:

```dart
final user = await User.query().find(1);

// Load posts only if not already loaded
await user.loadMissing(['posts', 'profile']);

// Safe to call multiple times - won't reload
await user.loadMissing(['posts']); // No-op
```

### Check Relation Loading Status

```dart
final user = await User.query().withRelation('posts').find(1);

if (user.relationLoaded('posts')) {
  print('Posts already loaded: ${user.posts.length}');
}

if (!user.relationLoaded('comments')) {
  await user.load(['comments']);
}
```

## Relation Aggregates

Load aggregate values on relations without loading the full collection:

```dart
final user = await User.query().find(1);

// Load counts
await user.loadCount(['posts', 'comments']);
print('Posts: ${user.postsCount}, Comments: ${user.commentsCount}');

// Load other aggregates
await user.loadSum('orders', 'total');
print('Total orders value: ${user.ordersSum}');

await user.loadAvg('reviews', 'rating');
print('Average rating: ${user.reviewsAvg}');

await user.loadMax('orders', 'created_at');
print('Latest order: ${user.ordersMax}');

await user.loadMin('orders', 'created_at');
print('First order: ${user.ordersMin}');

// Check existence
await user.loadExists(['posts']);
if (user.postsExists) {
  print('User has posts');
}
```

### Eager Load Aggregates

Load aggregates while querying:

```dart
final users = await User.query()
    .withCount('posts')
    .withSum('orders', 'total')
    .withAvg('reviews', 'rating')
    .get();

for (final user in users) {
  print('${user.name}: ${user.postsCount} posts, avg rating ${user.reviewsAvg}');
}
```

## Relation Mutation Helpers

### BelongsTo Relations

```dart
final post = await Post.query().find(1);
final author = await Author.query().find(5);

// Associate a parent
await post.associate('author', author);
// Automatically updates post.authorId and caches the relation

// Dissociate
await post.dissociate('author');
// Nullifies post.authorId and clears the cached relation
```

### Many-to-Many Relations

```dart
final post = await Post.query().find(1);

// Attach tags (adds pivot records)
await post.attach('tags', [1, 2, 3]);

// Attach with pivot data
await post.attach('tags', [4], pivotData: {'created_by': 'admin'});

// Detach specific tags
await post.detach('tags', [1, 2]);

// Detach all tags
await post.detach('tags');

// Sync (replace all existing with new set)
await post.sync('tags', [2, 3, 4]);
// Removes tag 1, keeps 2 & 3, adds 4
```

### Manual Relation Setting

```dart
// Set a relation manually (useful for testing)
user.setRelation('posts', [post1, post2]);

// Unset a relation
user.unsetRelation('posts');

// Clear all relations
user.clearRelations();
```

## Cross-Driver Compatibility

### Capability Detection

Ormed automatically handles driver differences:

```dart
// These features work on SQL drivers but are limited on MongoDB:
- Raw SQL expressions (SQL only)
- Complex joins (SQL only)
- Window functions (SQL only)

// MongoDB uses its own implementations:
- Aggregation pipeline for relation aggregates
- $lookup for relation loading
- Document-based operations
```

### Driver-Specific Features

```dart
// Automatically uses correct implementation per driver
final users = await User.query()
    .withCount('posts')  // SQL: subquery, MongoDB: $lookup + $count
    .withSum('orders', 'total')  // SQL: subquery, MongoDB: $group + $sum
    .get();
```

## Performance Features

### Relation Caching

Relations are cached after loading:

```dart
final user = await User.query().withRelation('posts').find(1);

// First access: returns cached value
final posts1 = user.posts;

// Subsequent accesses: no database queries
final posts2 = user.posts;
final posts3 = user.posts;

// Force reload
await user.load(['posts']);
```

### Selective Loading

Only load what you need:

```dart
// Load only specific columns
final users = await User.query()
    .select(['id', 'name', 'email'])
    .get();

// Load relation with constraints
final users = await User.query()
    .withRelation('posts', (q) => q
        .whereEquals('published', true)
        .orderBy('created_at', descending: true)
        .limit(5))
    .get();
```

## Comparison with Laravel

| Feature | Laravel Eloquent | Ormed | Notes |
|---------|-----------------|-------|-------|
| `User::query()` | ✅ | ✅ | Static query helper |
| `User::find()` | ✅ | ✅ | Find by ID |
| `User::findOrFail()` | ✅ | ✅ | Find or throw |
| `User::findMany()` | ✅ | ✅ | Find multiple by IDs |
| `User::all()` | ✅ | ✅ | Get all records |
| `User::first()` | ✅ | ✅ | Get first record |
| `User::firstOrFail()` | ✅ | ✅ | Get first or throw |
| `User::firstOrCreate()` | ✅ | ✅ | Find or create |
| `User::updateOrCreate()` | ✅ | ✅ | Update or create |
| `User::count()` | ✅ | ✅ | Count records |
| `User::exists()` | ✅ | ✅ | Check existence |
| `User::destroy()` | ✅ | ✅ | Delete by IDs |
| `$user->posts` lazy loading | ✅ | ✅ | Automatic on first access |
| `Model::preventLazyLoading()` | ✅ | ✅ | Prevent N+1 in development |
| `$user->loadMissing()` | ✅ | ✅ | Load only if not loaded |
| `$user->relationLoaded()` | ✅ | ✅ | Check if relation is loaded |
| `withCount()` | ✅ | ✅ | Eager load counts |
| `withSum/Avg/Max/Min()` | ✅ | ✅ | Eager load aggregates |
| `$user->loadCount()` | ✅ | ✅ | Lazy load counts |
| `associate()/dissociate()` | ✅ | ✅ | BelongsTo helpers |
| `attach()/detach()/sync()` | ✅ | ✅ | Many-to-Many helpers |
| Multi-driver support | ❌ | ✅ | MongoDB + SQL |

## Best Practices

### Development Mode

Enable lazy loading detection during development:

```dart
void main() {
  if (isDebugMode) {
    Model.preventLazyLoading(enabled: true);
  }
  
  runApp(MyApp());
}
```

### Production Mode

Use eager loading for performance:

```dart
// Bad: N+1 queries
final users = await User.query().get();
for (final user in users) {
  print(user.posts.length); // Separate query per user
}

// Good: Single query with join/subquery
final users = await User.query()
    .withCount('posts')
    .get();
for (final user in users) {
  print(user.postsCount); // No additional queries
}
```

### Testing

Manually set relations in tests:

```dart
test('user with posts', () {
  final user = User(id: 1, name: 'Alice');
  user.setRelation('posts', [
    Post(id: 1, userId: 1, title: 'Hello'),
    Post(id: 2, userId: 1, title: 'World'),
  ]);
  
  expect(user.posts.length, 2);
  expect(user.relationLoaded('posts'), true);
});
```

## Migration Guide

### From Context Queries to Static Helpers

**Before:**
```dart
final users = await context.query<User>()
    .whereEquals('active', true)
    .get();
```

**After:**
```dart
final users = await User.query()
    .whereEquals('active', true)
    .get();
```

### From Manual Loading to Aggregates

**Before:**
```dart
final user = await User.query().find(1);
final posts = await user.load(['posts']);
final count = posts.length;
```

**After:**
```dart
final user = await User.query().find(1);
await user.loadCount(['posts']);
final count = user.postsCount;
```

### From Raw Pivot Manipulation to Helpers

**Before:**
```dart
await context.repository('post_tags').insert({
  'post_id': post.id,
  'tag_id': tagId,
});
```

**After:**
```dart
await post.attach('tags', [tagId]);
```
