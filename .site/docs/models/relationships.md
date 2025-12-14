---
sidebar_position: 2
---

# Relationships

Ormed supports common relationship types between models using the `@OrmRelation` annotation.

## Relationship Types

### Has One

A one-to-one relationship where the related model has the foreign key:

```dart
@OrmModel(table: 'users')
class User extends Model<User> {
  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmRelation.hasOne(Profile, foreignKey: 'user_id')
  Profile? profile;
}

@OrmModel(table: 'profiles')
class Profile extends Model<Profile> {
  @OrmField(isPrimaryKey: true)
  final int id;

  final int userId;
  final String bio;
}
```

### Has Many

A one-to-many relationship:

```dart
@OrmModel(table: 'users')
class User extends Model<User> {
  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmRelation.hasMany(Post, foreignKey: 'author_id')
  List<Post>? posts;
}

@OrmModel(table: 'posts')
class Post extends Model<Post> {
  @OrmField(isPrimaryKey: true)
  final int id;

  final int authorId;
  final String title;
}
```

### Belongs To

The inverse of hasOne/hasMany - this model has the foreign key:

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> {
  @OrmField(isPrimaryKey: true)
  final int id;

  final int authorId;
  final String title;

  @OrmRelation.belongsTo(User, foreignKey: 'author_id')
  User? author;
}
```

### Belongs To Many

A many-to-many relationship using a pivot table:

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> {
  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmRelation.belongsToMany(
    Tag,
    pivotTable: 'post_tags',
    foreignKey: 'post_id',
    relatedKey: 'tag_id',
  )
  List<Tag>? tags;
}

@OrmModel(table: 'tags')
class Tag extends Model<Tag> {
  @OrmField(isPrimaryKey: true)
  final int id;

  final String name;
}
```

## Loading Relations

### Eager Loading

Load relations upfront with the query:

```dart
// Load a single relation
final posts = await dataSource.query<$Post>()
    .with_(['author'])
    .get();

// Load multiple relations
final posts = await dataSource.query<$Post>()
    .with_(['author', 'tags'])
    .get();

// Nested relations
final posts = await dataSource.query<$Post>()
    .with_(['author.profile', 'comments.user'])
    .get();
```

### Lazy Loading

Load relations on-demand:

```dart
final post = await dataSource.query<$Post>().find(1);

// Load relation after fetching
await post.load(['author']);
print(post.author?.name);

// Load missing relations only
await post.loadMissing(['author', 'tags']);
```

### Checking Relation Status

```dart
// Check if a relation has been loaded
if (post.relationLoaded('author')) {
  print(post.author?.name);
}

// Get a relation (throws if not loaded)
final author = post.getRelation<User>('author');
```

## Relation Manipulation

### Setting Relations

```dart
// Set a belongsTo relation
post.associate('author', user);

// Remove a belongsTo relation
post.dissociate('author');
```

### Many-to-Many Operations

```dart
// Attach related models
await post.attach('tags', [tag1.id, tag2.id]);

// Detach related models
await post.detach('tags', [tag1.id]);

// Sync relations (add/remove to match)
await post.sync('tags', [tag1.id, tag2.id, tag3.id]);
```

## Aggregate Loading

Load aggregate values without fetching all related models:

```dart
// Count related models
await user.loadCount(['posts', 'comments']);
print(user.postsCount);

// Sum a column
await user.loadSum(['posts'], 'views');
print(user.postsViewsSum);

// Other aggregates
await user.loadAvg(['posts'], 'rating');
await user.loadMax(['posts'], 'views');
await user.loadMin(['posts'], 'views');

// Check existence
await user.loadExists(['posts']);
print(user.postsExists);  // true/false
```

## Preventing N+1 Queries

Use `Model.preventLazyLoading()` in development to catch N+1 issues:

```dart
void main() {
  // Enable in development
  if (kDebugMode) {
    Model.preventLazyLoading();
  }
}
```

This throws an exception when accessing relations that haven't been eager-loaded, helping you identify performance issues early.
