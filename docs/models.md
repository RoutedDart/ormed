# Models

Models in Ormed represent your application's data and business logic. They provide a clean, object-oriented interface to interact with your database.

## Table of Contents

- [Defining Models](#defining-models)
- [Static Query Helpers](#static-query-helpers)
- [Attribute Management](#attribute-management)
- [Model State](#model-state)
- [Relationships](#relationships)
- [Mass Assignment](#mass-assignment)
- [Multiple Data Sources](#multiple-data-sources)

## Defining Models

Models are defined using the `@Orm()` annotation and extend the `Model` base class:

```dart
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@Orm()
class User extends Model<User> {
  @PrimaryKey(autoIncrement: true)
  int? id;

  @Column()
  String name;

  @Column()
  String email;

  @Timestamp()
  DateTime? createdAt;

  @Timestamp()
  DateTime? updatedAt;

  User({this.id, required this.name, required this.email});
}
```

Run code generation to create the ORM definitions:

```bash
dart run build_runner build
```

## Static Query Helpers

The `Model` base class provides static helper methods that make querying more ergonomic. These helpers automatically resolve the connection from the default `DataSource`:

### Basic Querying

```dart
// Get all records
final users = await User.all();

// Find by primary key
final user = await User.find(1);

// Find or throw exception
final user = await User.findOrFail(1);

// Find multiple by primary keys
final users = await User.findMany([1, 2, 3]);

// Get first record
final user = await User.first();

// Check if records exist
final exists = await User.exists();

// Count records
final count = await User.count();
```

### Query Builder Access

Get a query builder instance for complex queries:

```dart
// Start a query
final query = User.query();

// Chain query methods
final activeUsers = await User.query()
  .where('status', '=', 'active')
  .orderBy('name')
  .get();

// Use aggregates
final avgAge = await User.query().avg('age');
final maxAge = await User.query().max('age');
```

### Creating Records

```dart
// Create a new record
final user = await User.create({
  'name': 'John Doe',
  'email': 'john@example.com',
});

// Create or update (upsert)
final user = await User.createOrFirst(
  {'email': 'john@example.com'},
  {'name': 'John Doe'},
);

// Update or create
final user = await User.updateOrCreate(
  {'email': 'john@example.com'},
  {'name': 'John Updated'},
);

// First or create
final user = await User.firstOrCreate(
  {'email': 'john@example.com'},
  {'name': 'John Doe'},
);

// First or new (doesn't save)
final user = await User.firstOrNew(
  {'email': 'john@example.com'},
  {'name': 'John Doe'},
);
```

### Setup Required

For static helpers to work, you must initialize and register a `DataSource`:

```dart
void main() async {
  // Create and initialize DataSource
  final dataSource = DataSource(DataSourceOptions(
    name: 'main',
    driver: SqliteDriverAdapter.file('app.sqlite'),
    entities: [UserOrmDefinition.definition],
  ));
  
  await dataSource.init();
  
  // Static helpers now work automatically
  final users = await User.all();
  final user = await User.find(1);
}
```

The `DataSource` automatically registers itself with the `ConnectionManager` during initialization, making static helpers work seamlessly.

## Attribute Management

Models provide several methods for working with attributes (database columns):

### Getting Attributes

```dart
final user = await User.find(1);

// Get single attribute
final name = user.getAttribute('name');

// Get all attributes as Map
final attrs = user.getAttributes();

// Check if attribute exists
if (user.hasAttribute('email')) {
  print(user.getAttribute('email'));
}
```

### Setting Attributes

```dart
final user = User(name: 'John', email: 'john@example.com');

// Set single attribute
user.setAttribute('name', 'Jane');

// Set multiple attributes
user.setAttributes({
  'name': 'Jane Doe',
  'email': 'jane@example.com',
});

// Fill from Map (respects fillable/guarded)
user.fill({
  'name': 'Jane',
  'email': 'jane@example.com',
  'password': 'secret',  // Only set if in fillable
});

// Force fill (bypasses fillable/guarded)
user.forceFill({
  'name': 'Jane',
  'admin': true,  // Set even if guarded
});
```

### Original Values

Track changes to attributes:

```dart
final user = await User.find(1);
user.setAttribute('name', 'Jane');

// Get original value before changes
final originalName = user.getOriginal('name'); // 'John'

// Check if attribute was changed
if (user.isDirty('name')) {
  print('Name changed from ${user.getOriginal('name')} to ${user.getAttribute('name')}');
}

// Get all changed attributes
final changes = user.getDirty(); // {'name': 'Jane'}

// Check if any attributes changed
if (user.isDirty()) {
  print('Model has unsaved changes');
}

// Sync original to current (mark as unchanged)
user.syncOriginal();
```

## Model State

Track the state of your model instances:

### Existence State

```dart
final user = User(name: 'John', email: 'john@example.com');

// Check if model exists in database
user.exists; // false

await user.save();
user.exists; // true

// Check if model is new (not persisted)
if (!user.exists) {
  print('This is a new record');
}
```

### Change Tracking

```dart
final user = await User.find(1);

// Check for changes
user.isDirty(); // false
user.isDirty('name'); // false

user.name = 'Jane';
user.isDirty(); // true
user.isDirty('name'); // true

// Get changes
user.getChanges(); // {'name': 'Jane'}
user.getDirty(); // Same as getChanges()

// Get original values
user.getOriginal(); // All original attributes
user.getOriginal('name'); // Original name value

// Discard changes
user.syncOriginal(); // Mark current state as original
user.isDirty(); // false
```

### Fresh & Refresh

```dart
// Get a fresh copy from database (doesn't modify current instance)
final freshUser = await user.fresh();

// Refresh current instance with latest data
await user.refresh();
```

## Relationships

Models can define and work with relationships. See [Relations Documentation](relations.md) for details.

### Loading Relations

```dart
// Eager load on query
final users = await User.query().with_(['posts', 'comments']).get();

// Lazy load
final user = await User.find(1);
await user.load('posts');

// Load missing (only if not already loaded)
await user.loadMissing(['posts', 'comments']);

// Check if relation is loaded
if (user.relationLoaded('posts')) {
  final posts = user.getRelation('posts');
}

// Load aggregates without loading full relation
await user.loadCount('posts'); // Adds posts_count attribute
await user.loadSum('orders', 'total'); // Adds orders_sum_total attribute
await user.loadAvg('orders', 'amount');
await user.loadMax('posts', 'views');
await user.loadMin('posts', 'views');
```

### Managing Relations

```dart
// BelongsTo: Associate/Dissociate
final post = await Post.find(1);
final author = await User.find(1);
await post.associate('author', author);
await post.dissociate('author');

// ManyToMany: Attach/Detach/Sync
final user = await User.find(1);
await user.attach('roles', [1, 2, 3]);
await user.detach('roles', [2]); // Detach specific
await user.detach('roles'); // Detach all
await user.sync('roles', [1, 3, 4]); // Replace all with these
```

### Preventing Lazy Loading

In development, detect N+1 queries by preventing lazy loading:

```dart
// Globally prevent lazy loading
Model.preventLazyLoading();

// Now this will throw an exception
final user = await User.find(1);
final posts = user.posts; // LazyLoadingViolationError!

// Allow lazy loading again
Model.allowLazyLoading();
```

## Mass Assignment

Control which attributes can be mass-assigned:

### Fillable (Whitelist)

```dart
@Orm()
class User extends Model<User> {
  static const fillable = ['name', 'email', 'password'];
  
  int? id;
  String name;
  String email;
  String password;
  bool isAdmin;

  User({this.id, required this.name, required this.email, required this.password, this.isAdmin = false});
}

// Only fillable attributes are set
final user = await User.create({
  'name': 'John',
  'email': 'john@example.com',
  'password': 'secret',
  'isAdmin': true, // Ignored!
});
```

### Guarded (Blacklist)

```dart
@Orm()
class User extends Model<User> {
  static const guarded = ['isAdmin', 'permissions'];
  
  // All other attributes are fillable
}

// Guarded attributes are protected
final user = await User.create({
  'name': 'John',
  'email': 'john@example.com',
  'isAdmin': true, // Ignored!
});
```

### Force Fill

Bypass fillable/guarded protection:

```dart
final user = User(name: 'John', email: 'john@example.com', password: 'secret');

// This respects fillable/guarded
user.fill({'isAdmin': true}); // Ignored if guarded

// This bypasses protection
user.forceFill({'isAdmin': true}); // Set even if guarded
```

## Multiple Data Sources

Work with multiple databases:

### Named Connections

```dart
// Setup multiple data sources
final mainDb = DataSource(DataSourceOptions(
  name: 'main',
  driver: SqliteDriverAdapter.file('main.sqlite'),
  entities: [UserOrmDefinition.definition],
));

final analyticsDb = DataSource(DataSourceOptions(
  name: 'analytics',
  driver: PostgresDriverAdapter(/* ... */),
  entities: [EventOrmDefinition.definition],
));

await mainDb.init();
await analyticsDb.init();

// Use specific connection
final users = await User.query(connection: 'main').get();
final events = await Event.query(connection: 'analytics').get();

// Instance methods also accept connection
final user = User(name: 'John', email: 'john@example.com');
await user.save(connection: 'main');
```

### Custom Connection Resolver

For advanced scenarios, provide a custom resolver:

```dart
ModelContext Function(Type modelType)? customResolver(String? name) {
  if (name == 'tenant') {
    // Return tenant-specific connection
    return (Type modelType) => getTenantConnection();
  }
  return null;
}

Model.bindConnectionResolver(customResolver);

// Now uses custom resolver
final users = await User.query(connection: 'tenant').get();
```

## Best Practices

1. **Use Static Helpers**: For simple queries, use static helpers like `User.all()` instead of `User.query().get()`

2. **Eager Load Relations**: Prevent N+1 queries by eager loading relations with `with_()`

3. **Enable Lazy Loading Prevention**: In development, use `Model.preventLazyLoading()` to catch N+1 issues

4. **Use Mass Assignment Protection**: Define `fillable` or `guarded` to protect sensitive attributes

5. **Track Changes**: Use `isDirty()` and `getChanges()` before saving to optimize updates

6. **Connection Management**: Use named connections for multi-database scenarios

7. **Leverage Aggregates**: Use `loadCount()`, `loadSum()`, etc. instead of loading full relations when you only need aggregate data

## See Also

- [Query Builder](query_builder.md) - Advanced querying
- [Relations](relations.md) - Working with relationships
- [Data Source](data_source.md) - Connection management
- [Code Generation](code_generation.md) - Model generation
