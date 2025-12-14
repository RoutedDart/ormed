---
sidebar_position: 3
---

# Loading Relations

Ormed provides multiple ways to load relationships between models.

## Eager Loading

Load relations upfront with your query to avoid N+1 problems.

### Basic Eager Loading

```dart
// Load a single relation
final posts = await dataSource.query<$Post>()
    .with_(['author'])
    .get();

for (final post in posts) {
  print(post.author?.name);  // Already loaded, no additional query
}
```

### Multiple Relations

```dart
final posts = await dataSource.query<$Post>()
    .with_(['author', 'tags', 'comments'])
    .get();
```

### Nested Relations

```dart
// Load author's profile along with author
final posts = await dataSource.query<$Post>()
    .with_(['author.profile'])
    .get();

// Multiple levels
final posts = await dataSource.query<$Post>()
    .with_(['author.profile', 'comments.user.profile'])
    .get();
```

## Lazy Loading

Load relations on-demand after fetching the model.

### Load Relations

```dart
final post = await dataSource.query<$Post>().find(1);

// Load after fetching
await post.load(['author', 'tags']);

print(post.author?.name);
```

### Load Missing Only

Only loads relations that haven't been loaded yet:

```dart
await post.loadMissing(['author', 'comments']);
```

### Check If Loaded

```dart
if (post.relationLoaded('author')) {
  print(post.author?.name);
} else {
  await post.load(['author']);
}
```

## Accessing Relations

### Get Relation

```dart
// Returns the relation value (throws if not loaded)
final author = post.getRelation<User>('author');

// For has-many relations
final comments = post.getRelation<List<Comment>>('comments');
```

### Set Relation

```dart
// Manually set a relation
post.setRelation('author', user);

// Unset a relation
post.unsetRelation('author');

// Clear all loaded relations
post.clearRelations();
```

## Relation Aggregates

Load aggregate values without fetching all related models.

### Count

```dart
await user.loadCount(['posts', 'comments']);
print('Posts: ${user.postsCount}');
print('Comments: ${user.commentsCount}');
```

### Sum

```dart
await user.loadSum(['posts'], 'views');
print('Total views: ${user.postsViewsSum}');
```

### Other Aggregates

```dart
await user.loadAvg(['posts'], 'rating');
await user.loadMax(['posts'], 'views');
await user.loadMin(['posts'], 'views');
```

### Exists

```dart
await user.loadExists(['posts']);
if (user.postsExists) {
  print('User has posts');
}
```

## Many-to-Many Operations

### Attach

Add related models to a many-to-many relationship:

```dart
await post.attach('tags', [tag1.id, tag2.id]);

// With pivot data
await post.attach('tags', [tag1.id], pivot: {'added_by': userId});
```

### Detach

Remove related models:

```dart
await post.detach('tags', [tag1.id]);

// Detach all
await post.detach('tags');
```

### Sync

Replace all related models:

```dart
// Replaces all existing tags with these
await post.sync('tags', [tag1.id, tag2.id, tag3.id]);
```

### Toggle

Add if not present, remove if present:

```dart
await post.toggle('tags', [tag1.id, tag2.id]);
```

## Belongs To Operations

### Associate

Set a belongs-to relationship:

```dart
post.associate('author', user);
await postRepo.update(post);
```

### Dissociate

Remove a belongs-to relationship:

```dart
post.dissociate('author');
await postRepo.update(post);
```

## Preventing N+1 Queries

Enable lazy loading prevention in development:

```dart
void main() {
  if (kDebugMode) {
    Model.preventLazyLoading();
  }
  
  runApp(MyApp());
}
```

This throws an exception when you try to access a relation that hasn't been eager-loaded, helping catch N+1 issues during development.

```dart
final posts = await dataSource.query<$Post>().get();

for (final post in posts) {
  // This throws LazyLoadingException in debug mode
  // because 'author' wasn't eager-loaded
  print(post.author?.name);
}
```

Fix by eager loading:

```dart
final posts = await dataSource.query<$Post>()
    .with_(['author'])  // Eager load author
    .get();

for (final post in posts) {
  print(post.author?.name);  // Works!
}
```
