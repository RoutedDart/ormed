# Relations & Lazy Loading

The routed ORM supports both eager and lazy loading of model relationships,
mirroring Laravel Eloquent's familiar patterns. This guide covers defining
relations, loading strategies, and mutation helpers for managing associations.

## Defining Relations

Annotate relation properties with `@OrmRelation` in your model classes:

```dart
import 'package:ormed/ormed.dart';

part 'post.orm.dart';

@OrmModel(table: 'posts')
class Post extends Model<Post> {
  const Post({
    required this.id,
    required this.authorId,
    required this.title,
  }) : author = null,
       tags = const [],
       comments = const [];

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(columnName: 'author_id')
  final int authorId;

  final String title;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.belongsTo,
    target: Author,
    foreignKey: 'author_id',
    localKey: 'id',
  )
  final Author? author;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.manyToMany,
    target: Tag,
    through: 'post_tags',
    pivotForeignKey: 'post_id',
    pivotRelatedKey: 'tag_id',
  )
  final List<Tag> tags;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.hasMany,
    target: Comment,
    foreignKey: 'post_id',
    localKey: 'id',
  )
  final List<Comment> comments;
}
```

### Supported Relation Kinds

| Kind | Description | Example |
|------|-------------|---------|
| `belongsTo` | Child references parent via foreign key | `Post.author` |
| `hasOne` | Parent has exactly one child | `User.profile` |
| `hasMany` | Parent has multiple children | `Author.posts` |
| `manyToMany` | Many-to-many via pivot table | `Post.tags` |
| `morphOne` | Polymorphic single relation | `Image.imageable` |
| `morphMany` | Polymorphic multiple relations | `Post.photos` |

### Relation Annotation Properties

```dart
@OrmRelation(
  kind: RelationKind.belongsTo,  // Required: relation type
  target: Author,                 // Required: related model class
  foreignKey: 'author_id',        // Foreign key column
  localKey: 'id',                 // Local key column (usually primary key)
  through: 'pivot_table',         // Pivot table name (manyToMany only)
  pivotForeignKey: 'post_id',     // This model's key in pivot table
  pivotRelatedKey: 'tag_id',      // Related model's key in pivot table
  morphType: 'imageable_type',    // Polymorphic type column
  morphClass: 'Post',             // Polymorphic class identifier
)
```

---

## Eager Loading

Eager loading fetches related models in a single query batch, avoiding N+1
query problems. Use `withRelation()` on the query builder:

```dart
// Load posts with their authors
final posts = await context
    .query<Post>()
    .withRelation('author')
    .get();

for (final post in posts) {
  print('${post.title} by ${post.author?.name}');
}
```

### Multiple Relations

Chain `withRelation()` calls or load multiple relations at once:

```dart
final posts = await context
    .query<Post>()
    .withRelation('author')
    .withRelation('tags')
    .withRelation('comments')
    .get();
```

### Constrained Eager Loading

Apply filters to related models using a callback:

```dart
final posts = await context
    .query<Post>()
    .withRelation('comments', (query) => query
        .whereEquals('approved', true)
        .orderBy('created_at', descending: true)
        .limit(5))
    .get();
```

### Eager Loading Aggregates

Load counts or existence flags without fetching full related models:

```dart
final posts = await context
    .query<Post>()
    .withCount('comments')
    .withCount('tags', alias: 'tag_count')
    .withExists('author', alias: 'has_author')
    .get();

// Access via row attributes
final rows = await context.query<Post>().withCount('comments').rows();
final count = rows.first.row['comments_count'] as int;
```

---

## Lazy Loading

Lazy loading fetches relations on-demand after the model has been hydrated.
Models must extend `Model<T>` and have an attached connection resolver.

### Basic Lazy Loading

```dart
// Fetch a post without relations
final post = await Post.query().firstOrFail();

// Lazy load the author
await post.load('author');
print(post.author?.name); // Now populated

// Lazy load with constraints
await post.load('comments', (query) => query
    .whereEquals('approved', true)
    .orderBy('created_at'));
```

### Load If Missing

Use `loadMissing()` to skip relations that are already loaded:

```dart
// Only loads relations that haven't been fetched yet
await post.loadMissing(['author', 'tags', 'comments']);
```

### Load Multiple Relations

Use `loadMany()` to load multiple relations with individual constraints:

```dart
await post.loadMany({
  'author': null,  // No constraint
  'comments': (query) => query.whereEquals('approved', true),
  'tags': (query) => query.orderBy('name'),
});
```

### Nested Relation Paths

Load nested relations using dot notation, similar to Laravel:

```dart
// Load comments and their authors in one call
await post.load('comments.author');

// The constraint applies to the final relation in the path
await post.load('comments.author', (query) => query.whereEquals('active', true));

// Access nested loaded data
for (final comment in post.comments) {
  print('Comment by: ${comment.author?.name}');
}
```

Nested loading works recursively:
1. Loads the first relation on the parent model
2. For each loaded child, loads the next relation in the path
3. Continues until the full path is loaded

---

## Batch Loading on Collections

When working with multiple models, use static batch loading methods to avoid
N+1 query problems. These methods execute a single query per resolver group.

### Load Single Relation on Multiple Models

```dart
final posts = await Post.query().get();

// Single query loads all authors
await Model.loadRelations(posts, 'author');

for (final post in posts) {
  print('${post.title} by ${post.author?.name}');
}
```

### With Constraints

```dart
await Model.loadRelations(posts, 'comments', (query) =>
    query.whereEquals('approved', true));
```

### Load Multiple Relations

```dart
final posts = await Post.query().get();

// Load multiple relations in sequence
await Model.loadRelationsMany(posts, ['author', 'tags', 'comments']);
```

### Load Missing Relations Only

```dart
// Some posts may already have relations from eager loading
final posts = await Post.query().withRelation('author').get();

// Only loads tags and comments (skips author since already loaded)
await Model.loadRelationsMissing(posts, ['author', 'tags', 'comments']);
```

### Lazy Loading Aggregates

Load counts, sums, averages, and other aggregates lazily without fetching full collections:

```dart
// Load comment count
await post.loadCount('comments');
print(post.getAttribute<int>('comments_count')); // e.g., 42

// With custom alias
await post.loadCount('comments', alias: 'total_comments');
print(post.getAttribute<int>('total_comments'));

// With constraints - count only approved comments
await post.loadCount('comments', constraint: (query) =>
    query.whereEquals('approved', true));

// Check existence - does this post have an author?
await post.loadExists('author');
print(post.getAttribute<bool>('author_exists')); // true/false

// Load sum of related values
await post.loadSum('orderItems', 'amount');
print(post.getAttribute<num>('order_items_sum_amount')); // e.g., 1250.50

// Load average
await post.loadAvg('ratings', 'score', alias: 'average_rating');
print(post.getAttribute<num>('average_rating')); // e.g., 4.5

// Load maximum value
await post.loadMax('bids', 'amount');
print(post.getAttribute<num>('bids_max_amount')); // e.g., 500.00

// Load minimum value
await post.loadMin('bids', 'amount');
print(post.getAttribute<num>('bids_min_amount')); // e.g., 10.00

// All aggregate methods support constraints
await post.loadSum('orderItems', 'amount', constraint: (query) =>
    query.whereEquals('status', 'completed'));
```

**Performance Benefit:** Aggregate loaders execute a single aggregate query (COUNT, SUM, AVG, etc.) without loading the actual related models into memory. This is far more efficient than loading all related records just to count or sum them.

### Checking Loaded State

Query whether a relation has been loaded:

```dart
if (post.relationLoaded('author')) {
  // Safe to access without additional queries
  print(post.author?.name);
}

// Get all loaded relation names
final loadedNames = post.loadedRelationNames;

// Get all loaded relations as a map
final allRelations = post.loadedRelations;
```

### Method Chaining

All lazy loading methods return `this` for fluent chaining:

```dart
final post = await Post.query().firstOrFail();

await post
    .load('author')
    .then((_) => post.load('tags'))
    .then((_) => post.loadCount('comments'));

// Or with loadMany for parallel loading
await post.loadMany({
  'author': null,
  'tags': null,
});
await post.loadCount('comments');
```

---

## Preventing Lazy Loading

In production, accidental lazy loading can cause N+1 query problems. Enable
strict mode to throw exceptions when lazy loading is attempted:

```dart
// Enable globally (typically in main() or test setUp)
ModelRelations.preventsLazyLoading = true;

// Now any lazy load attempt throws LazyLoadingViolationException
try {
  await post.load('author');
} on LazyLoadingViolationException catch (e) {
  print('Lazy loading blocked: ${e.relationName} on ${e.modelName}');
}

// Disable when needed
ModelRelations.preventsLazyLoading = false;
```

**Note:** Already-loaded relations can still be accessed—prevention only blocks
new database queries.

---

## Relation Mutation Helpers

### BelongsTo: Associate & Dissociate

Manage parent associations without manual foreign key manipulation:

```dart
final post = await Post.query().firstOrFail();
final author = await Author.query().firstOrFail();

// Associate sets the foreign key and caches the relation
post.associate('author', author);
await post.save();

print(post.authorId);       // Updated to author.id
print(post.author?.name);   // Cached from associate()

// Dissociate clears the foreign key
post.dissociate('author');
await post.save();

print(post.authorId);       // null
print(post.author);         // null (cleared from cache)
```

### ManyToMany: Attach, Detach & Sync

Manage pivot table records for many-to-many relations:

```dart
final post = await Post.query().firstOrFail();

// Attach new tags (inserts pivot records)
await post.attach('tags', [1, 2, 3]);

// Attach with pivot data (extra columns on pivot table)
await post.attach('tags', [4, 5], pivotData: {
  'created_at': DateTime.now(),
  'added_by': currentUserId,
});

// Detach specific tags (deletes pivot records)
await post.detach('tags', [1, 2]);

// Detach all tags
await post.detach('tags');

// Sync replaces all existing associations
// (detaches all current, then attaches provided IDs)
await post.sync('tags', [3, 4, 5]);

// Sync with pivot data
await post.sync('tags', [6, 7], pivotData: {
  'synced_at': DateTime.now(),
});
```

### Manual Relation Cache Management

Directly manipulate the relation cache when needed:

```dart
// Manually set a relation value
post.setRelation('author', existingAuthor);

// Remove a relation from cache
post.unsetRelation('tags');

// Clear all cached relations
post.clearRelations();

// Bulk set multiple relations
post.setRelations({
  'author': author,
  'tags': tagList,
});
```

---

## Accessing Relations on QueryRow

When using `rows()` instead of `get()`, access relations via helper methods:

```dart
final rows = await context
    .query<Post>()
    .withRelation('author')
    .withRelation('tags')
    .rows();

for (final row in rows) {
  // Single relation
  final author = row.relation<Author>('author');

  // List relation
  final tags = row.relationList<Tag>('tags');

  // Check if relation exists
  if (row.hasRelation('comments')) {
    // ...
  }

  // The model also has relations populated
  print(row.model.author?.name);
  print(row.model.tags.length);
}
```

---

## Working with the Model Base Class

For lazy loading and relation mutations to work, your model must:

1. **Extend `Model<T>`** — This mixes in `ModelRelations`, `ModelAttributes`,
   and `ModelConnection` automatically.
2. **Have an attached resolver** — Models hydrated via `QueryContext` have this
   automatically. For manually constructed models, bind a global resolver:

```dart
// Option 1: Bind global resolver (simplest)
Model.bindConnectionResolver(resolveConnection: (_) => context);

final post = const Post(id: 1, authorId: 1, title: 'Hello');
await post.load('author'); // Works because resolver is bound

// Option 2: Models from queries already have resolvers attached
final post = await Post.query().firstOrFail();
await post.load('author'); // Works automatically
```

---

## Relation Loading Strategies Comparison

| Strategy | When to Use | Pros | Cons |
|----------|-------------|------|------|
| **Eager** (`withRelation`) | Know upfront which relations you need | Single query batch, no N+1 | May over-fetch data |
| **Lazy** (`load`) | Conditionally load based on logic | On-demand, flexible | Risk of N+1 if in loops |
| **Load Missing** (`loadMissing`) | Mixed eager/lazy scenarios | Avoids duplicate loads | Slight overhead checking state |

### Best Practices

1. **Prefer eager loading** for list views and APIs where you know the shape
   of data upfront.

2. **Use lazy loading** for conditional logic:
   ```dart
   final post = await Post.query().firstOrFail();
   if (needsAuthorInfo) {
     await post.load('author');
   }
   ```

3. **Enable prevention in production** to catch accidental lazy loads:
   ```dart
   void main() {
     if (kReleaseMode) {
       ModelRelations.preventsLazyLoading = true;
     }
     runApp(MyApp());
   }
   ```

4. **Use `loadMissing`** when combining eager and lazy loading:
   ```dart
   // Controller eagerly loads 'author'
   final post = await Post.query().withRelation('author').firstOrFail();

   // Later code doesn't know what's loaded
   await post.loadMissing(['author', 'tags']); // Skips 'author', loads 'tags'
   ```

---

## Complete Example

```dart
import 'package:ormed/ormed.dart';

Future<void> main() async {
  // Setup
  final context = QueryContext(registry: registry, driver: adapter);
  Model.bindConnectionResolver(resolveConnection: (_) => context);

  // Eager loading
  final postsWithAuthors = await context
      .query<Post>()
      .withRelation('author')
      .withCount('comments')
      .orderBy('created_at', descending: true)
      .limit(10)
      .get();

  for (final post in postsWithAuthors) {
    print('${post.title} by ${post.author?.name}');
  }

  // Lazy loading
  final post = await Post.query().firstOrFail();

  if (!post.relationLoaded('tags')) {
    await post.load('tags');
  }

  print('Tags: ${post.tags.map((t) => t.name).join(', ')}');

  // Relation mutation
  final newTag = await Tag.query().whereEquals('name', 'featured').firstOrFail();
  await post.attach('tags', [newTag.id]);

  final newAuthor = await Author.query().firstOrFail();
  post.associate('author', newAuthor);
  await post.save();

  // Cleanup
  Model.unbindConnectionResolver();
  await adapter.close();
}
```

---

## Lazy Loading Control

### Preventing Lazy Loading in Development

Similar to Laravel Eloquent, you can prevent lazy loading to catch N+1 query problems during development:

```dart
// In your application bootstrap or test setup
Model.preventLazyLoading(shouldPrevent: true);

// Now any attempt to lazily load will throw
final post = await Post.query().first();
// This will throw LazyLoadingViolationException!
print(post.author?.name); 
```

**Best Practice**: Enable lazy loading prevention in development/test environments:

```dart
void main() async {
  // Prevent lazy loading in non-production
  if (environment != 'production') {
    Model.preventLazyLoading(shouldPrevent: true);
  }
  
  // Run your app
  runApp(MyApp());
}
```

### Checking Relation Load Status

Before accessing relations, check if they're loaded to avoid lazy loading:

```dart
final post = await Post.query().first();

// Check if loaded
if (post.relationLoaded('author')) {
  print(post.author!.name); // Safe - already loaded
} else {
  await post.load('author'); // Explicitly load
}

// Load only if missing
await post.loadMissing(['author', 'tags']);

// Get all loaded relations
final loaded = post.loadedRelationNames; // Set<String>
print('Loaded: ${loaded.join(', ')}');
```

---

## Relation Aggregates

Load aggregate values from relations without fetching the full collection.

### Query Builder Aggregates

```dart
// Eager load aggregate values
final authors = await context
    .query<Author>()
    .withSum('posts', 'views', alias: 'total_views')
    .withCount('posts', alias: 'post_count')
    .withAvg('posts', 'views', alias: 'avg_views')
    .withMax('posts', 'views', alias: 'max_views')
    .withMin('posts', 'views', alias: 'min_views')
    .withExists('posts', alias: 'has_posts')
    .get();

for (final author in authors) {
  final totalViews = author.getAttribute<num>('total_views');
  final postCount = author.getAttribute<int>('post_count');
  final avgViews = author.getAttribute<num>('avg_views');
  print('${author.name}: $postCount posts, $totalViews total views, $avgViews avg');
}
```

### Model Instance Aggregates

```dart
// Lazy load aggregates on model instances
final author = await Author.query().first();

await author.loadSum('posts', 'views', alias: 'total_views');
await author.loadAvg('posts', 'views', alias: 'avg_views');
await author.loadCount('posts', alias: 'post_count');
await author.loadMax('posts', 'views', alias: 'max_views');
await author.loadMin('posts', 'views', alias: 'min_views');
await author.loadExists('posts', alias: 'has_posts');

print('Total views: ${author.getAttribute<num>('total_views')}');
print('Average views: ${author.getAttribute<num>('avg_views')}');
print('Post count: ${author.getAttribute<int>('post_count')}');
```

### Aggregate Aliases

If you don't provide an alias, one is generated automatically:

```dart
await context
    .query<Author>()
    .withSum('posts', 'views') // alias: 'posts_sum_views'
    .withCount('posts')        // alias: 'posts_count'
    .withAvg('posts', 'views') // alias: 'posts_avg_views'
    .get();
```

### Aggregates with Constraints

Apply query constraints to aggregates:

```dart
// Only count published posts
final authors = await context
    .query<Author>()
    .withCount('posts', 
      alias: 'published_count',
      constraint: (q) => q.whereNotNull('published_at'),
    )
    .get();

// Sum views only for popular posts
await author.loadSum('posts', 'views',
  alias: 'popular_views',
  constraint: (q) => q.where('views', 1000, PredicateOperator.greaterThan),
);
```

---

## Driver Capabilities & Limitations

Different database drivers support different features. The ORM uses a capability system to handle this gracefully.

### MongoDB Limitations

MongoDB does **not** support certain SQL-specific features:

1. **Raw SQL Operations**: `selectRaw()`, `whereRaw()`, `havingRaw()` are not supported
2. **Relation Aggregates**: `withSum()`, `withCount()`, `loadSum()`, etc. are not available
   - This is because MongoDB doesn't support SQL-style subqueries
   - Use MongoDB's aggregation pipeline directly for complex aggregations
3. **JOINs**: Use nested document patterns or perform joins client-side

These features are automatically skipped in tests and will throw descriptive errors if used.

### SQLite Full Support

SQLite supports all features including:
- Raw SQL operations
- Relation aggregates with subqueries
- All join types (INNER, LEFT, RIGHT)
- Transactions
- Schema introspection

### Checking Capabilities at Runtime

```dart
// Check if driver supports a capability
final config = DriverTestConfig(
  driverName: 'MongoDB',
  capabilities: {
    DriverCapability.schemaIntrospection,
    DriverCapability.queryDeletes,
    // Note: relationAggregates NOT included
  },
);

if (config.supportsCapability(DriverCapability.relationAggregates)) {
  // Use aggregate methods
  await query.withSum('posts', 'views');
} else {
  // Fall back to manual aggregation
  await query.withRelation('posts');
  // Calculate sum client-side
}
```

### Available Capabilities

- `joins` - Supports SQL-style joins
- `insertUsing` - INSERT ... SELECT statements
- `queryDeletes` - DELETE with WHERE conditions
- `schemaIntrospection` - Inspect database schema
- `returning` - RETURNING clause support
- `transactions` - Database transactions
- `threadCount` - Multi-threaded operations
- `adHocQueryUpdates` - UPDATE with arbitrary conditions
- `advancedQueryBuilders` - Complex query features
- `sqlPreviews` - SQL query preview/debug
- `increment` - Atomic increment/decrement
- `rawSQL` - Raw SQL expressions
- **`relationAggregates`** - Relation aggregate queries (NEW)

---

## API Reference

### Query Builder Methods

| Method | Description |
|--------|-------------|
| `withRelation(name, [constraint])` | Eager load a relation |
| `withCount(relation, {alias, constraint})` | Eager load relation count |
| `withSum(relation, column, {alias, constraint})` | Eager load sum of relation column values (SQL drivers only) |
| `withAvg(relation, column, {alias, constraint})` | Eager load average of relation column values (SQL drivers only) |
| `withMax(relation, column, {alias, constraint})` | Eager load maximum relation column value (SQL drivers only) |
| `withMin(relation, column, {alias, constraint})` | Eager load minimum relation column value (SQL drivers only) |
| `withExists(relation, {alias, constraint})` | Eager load relation existence |
| `whereHas(relation, [constraint])` | Filter by relation existence |
| `orWhereHas(relation, [constraint])` | OR filter by relation existence |
| `joinRelation(name, {type})` | Join relation without eager loading |

### Model Lazy Loading Methods (Instance)

| Method | Description |
|--------|-------------|
| `load(relation, [constraint])` | Lazy load a single relation (supports nested paths like `'comments.author'`) |
| `loadMissing(relations)` | Load relations not already loaded |
| `loadMany(relationsMap)` | Load multiple relations with constraints |
| `loadCount(relation, {alias, constraint})` | Lazy load relation count |
| `loadSum(relation, column, {alias, constraint})` | Lazy load sum of column values in relation |
| `loadAvg(relation, column, {alias, constraint})` | Lazy load average of column values in relation |
| `loadMax(relation, column, {alias, constraint})` | Lazy load maximum column value in relation |
| `loadMin(relation, column, {alias, constraint})` | Lazy load minimum column value in relation |
| `loadExists(relation, {alias, constraint})` | Lazy load relation existence |

### Model Batch Loading Methods (Static)

| Method | Description |
|--------|-------------|
| `Model.loadRelations(models, relation, [constraint])` | Batch load a relation on multiple models |
| `Model.loadRelationsMany(models, relations)` | Batch load multiple relations on multiple models |
| `Model.loadRelationsMissing(models, relations)` | Batch load only missing relations on multiple models |

### Model Relation State Methods

| Method | Description |
|--------|-------------|
| `relationLoaded(name)` | Check if relation is loaded |
| `loadedRelationNames` | Get set of loaded relation names |
| `loadedRelations` | Get map of all loaded relations |
| `getRelation<T>(name)` | Get cached relation value |
| `getRelationList<T>(name)` | Get cached list relation |
| `setRelation(name, value)` | Manually cache a relation |
| `unsetRelation(name)` | Remove relation from cache |
| `clearRelations()` | Clear all cached relations |

### Model Relation Mutation Methods

| Method | Description |
|--------|-------------|
| `associate(relation, parent)` | Set belongsTo foreign key and cache |
| `dissociate(relation)` | Clear belongsTo foreign key and cache |
| `attach(relation, ids, {pivotData})` | Add manyToMany pivot records |
| `detach(relation, [ids])` | Remove manyToMany pivot records |
| `sync(relation, ids, {pivotData})` | Replace all manyToMany associations |

### QueryRow Helper Methods

| Method | Description |
|--------|-------------|
| `relation<T>(name)` | Get single relation from row |
| `relationList<T>(name)` | Get list relation from row |
| `hasRelation(name)` | Check if relation exists in row |