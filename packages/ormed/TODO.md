# Ormed TODO - Developer Experience Improvements

## ✅ Recently Completed

### Static Query Helpers (2025-01-29)
- [x] **Added comprehensive static helpers** - Model class now provides Laravel-style static helpers: `all()`, `find()`, `findOrFail()`, `first()`, `firstOrFail()`, `count()`, `exists()`, `doesntExist()`, `where()`, `whereIn()`, `orderBy()`, `limit()`
- [x] **Relation loading helpers** - Added `loadMissing()`, `relationLoaded()`, and aggregate loaders (`loadCount()`, `loadSum()`, `loadAvg()`, `loadMax()`, `loadMin()`, `loadExists()`)
- [x] **Relation mutation helpers** - Implemented `setRelation()`, `unsetRelation()`, `clearRelations()`, `associate()`, `dissociate()`, `attach()`, `detach()`, `sync()`
- [x] **Lazy loading control** - Added `Model.preventLazyLoading()` to detect N+1 queries in development
- [x] **Relation resolution utilities** - Extracted `RelationResolver` class for shared relation path resolution logic

### Generator Optimization (2025-01-29)
- [x] **Static helpers in extensions** - Generator creates static helper methods in extensions
- [x] **ConnectionManager.instance** - Added convenient getter for accessing default connection manager
- [x] **DataSource.setDefaultDataSource()** - Helper to register a data source as 'default' connection

## Known Limitations

### Static Helper Method Syntax
**Current Limitation**: Static helper methods are generated in extensions and must be called via the extension name:
```dart
// Must use:
final users = await UserOrmDefinition.all();

// Cannot use (Dart limitation):
final users = await User.all();  // Error!
```

**Why**: Dart extensions can have static members, but they can only be called on the extension name itself, not on the type they extend.

**Potential Solutions** (for future consideration):
1. **Macro-based generation** (when Dart macros are stable) - Could inject static methods directly into the class
2. **Abstract base class pattern** - Generate an abstract base with static methods, but requires changing user code structure  
3. **Code modification** - Directly modify user files (not recommended)
4. **Accept the limitation** - Document clearly and provide good IDE autocomplete

For now, we've chosen option 4 with clear documentation and generated comments.

## Code Generation Enhancements

### 1. Type-Safe Relation Accessors
**Goal**: Generate strongly-typed getters/setters for relations to avoid string-based access.

**Current**:
```dart
final author = await post.getRelation<User>('author');
await post.load(['author', 'comments']);
```

**Proposed**:
```dart
// Generated accessors
User? get author => getRelation<User>('author');
Future<User?> loadAuthor() => load(['author']).then((_) => author);

List<Comment> get comments => getRelation<List<Comment>>('comments') ?? [];
Future<List<Comment>> loadComments() => load(['comments']).then((_) => comments);
```

**Benefits**:
- Compile-time type safety
- IDE autocomplete
- Refactoring support
- Less error-prone

---

### 2. Scoped Query Methods
**Goal**: Generate scope methods based on common queries/filters.

**Current**:
```dart
final posts = await Post.query()
  .where('published', true)
  .where('featured', true)
  .get();
```

**Proposed**:
```dart
@Model()
class Post extends BaseModel {
  @Scope()
  static Query<Post> published(Query<Post> query) => query.where('published', true);
  
  @Scope()
  static Query<Post> featured(Query<Post> query) => query.where('featured', true);
}

// Usage
final posts = await Post.query().published().featured().get();
```

**Alternative - Generate from common patterns**:
```dart
// Auto-generate boolean field scopes
final posts = await Post.query().wherePublished().whereFeatured().get();
```

---

### 3. Attribute Casting Helpers
**Goal**: Generate cast methods for custom attributes with validation.

**Current**:
```dart
@Attribute(cast: 'json')
Map<String, dynamic>? metadata;
```

**Proposed**:
```dart
// Generate typed accessors
@JsonCast(MetadataModel)
MetadataModel? get metadata => _metadata != null 
  ? MetadataModel.fromJson(_metadata!) 
  : null;

set metadata(MetadataModel? value) => 
  _metadata = value?.toJson();
```

---

### 4. Query Builder with Field Names
**Goal**: Type-safe field references in queries to avoid string typos.

**Current**:
```dart
await Post.query()
  .where('title', 'like', '%Dart%')
  .orderBy('created_at', 'desc')
  .get();
```

**Proposed**:
```dart
// Generate field name constants
class PostFields {
  static const title = 'title';
  static const createdAt = 'created_at';
  static const authorId = 'author_id';
}

// Usage
await Post.query()
  .where(PostFields.title, 'like', '%Dart%')
  .orderBy(PostFields.createdAt, 'desc')
  .get();

// Or even better - strongly typed query builder
await Post.query()
  .whereTitle.like('%Dart%')
  .orderByCreatedAt.desc()
  .get();
```

---

### 5. Validation Rules Generation
**Goal**: Generate validation methods based on column constraints.

**Proposed**:
```dart
@Column(nullable: false, maxLength: 255)
String title;

@Column(min: 0, max: 100)
int? score;

// Generated validation
@override
List<ValidationError> validate() {
  final errors = <ValidationError>[];
  
  if (title.isEmpty) {
    errors.add(ValidationError('title', 'Title is required'));
  }
  if (title.length > 255) {
    errors.add(ValidationError('title', 'Title must be 255 characters or less'));
  }
  if (score != null && (score! < 0 || score! > 100)) {
    errors.add(ValidationError('score', 'Score must be between 0 and 100'));
  }
  
  return errors;
}
```

---

### 6. Factory Constructors for Relations
**Goal**: Generate convenient constructors for creating models with relations.

**Proposed**:
```dart
// Generated
Post.withAuthor({
  required String title,
  required User author,
  String? content,
}) : this(title: title, content: content) {
  setRelation('author', author);
  authorId = author.id;
}

// Usage
final post = Post.withAuthor(
  title: 'My Post',
  author: currentUser,
);
```

---

### 7. Dirty Tracking Helpers
**Goal**: Generate methods to check which specific fields changed.

**Proposed**:
```dart
// Generated
bool get titleChanged => isDirty('title');
String? get originalTitle => getOriginal('title');
bool get wasPublished => getOriginal('published') == true;

// Usage
if (post.titleChanged) {
  print('Title changed from ${post.originalTitle} to ${post.title}');
}
```

---

### 8. Relationship Existence Queries
**Goal**: Generate helper methods for common relationship queries.

**Proposed**:
```dart
// Generated for each relation
static Query<Post> whereHasComments(Query<Post> query, 
  [void Function(Query<Comment>)? callback]) {
  return query.whereHas('comments', callback);
}

static Query<Post> whereHasAuthor(Query<Post> query,
  [void Function(Query<User>)? callback]) {
  return query.whereHas('author', callback);
}

// Usage
await Post.query()
  .whereHasComments((q) => q.where('approved', true))
  .get();
```

---

### 9. JSON Serialization Options
**Goal**: Generate customizable toJson/fromJson with field selection.

**Proposed**:
```dart
// Generated
Map<String, dynamic> toJson({
  bool includeRelations = false,
  List<String>? only,
  List<String>? except,
}) {
  // Smart serialization
}

// Usage
post.toJson(includeRelations: true, except: ['password']);
post.toJson(only: ['id', 'title', 'author']);
```

---

### 10. Bulk Operations
**Goal**: Generate efficient bulk operation methods.

**Proposed**:
```dart
// Generated
static Future<void> bulkCreate(List<Map<String, dynamic>> data) async {
  // Efficient batch insert
}

static Future<void> bulkUpdate(List<Post> posts) async {
  // Efficient batch update
}

// Usage
await Post.bulkCreate([
  {'title': 'Post 1', 'content': '...'},
  {'title': 'Post 2', 'content': '...'},
]);
```

---

### 11. Soft Delete Helpers
**Goal**: Generate soft delete query scopes and helpers.

**Proposed**:
```dart
@Model(softDelete: true)
class Post {
  // Generated
  static Query<Post> onlyTrashed(Query<Post> query) => 
    query.whereNotNull('deleted_at');
  
  static Query<Post> withTrashed(Query<Post> query) => 
    query.withTrashed();
  
  bool get trashed => deletedAt != null;
  
  Future<bool> restore() async {
    deletedAt = null;
    return await save();
  }
}
```

---

### 12. Computed/Virtual Attributes
**Goal**: Generate computed properties that can be included in serialization.

**Proposed**:
```dart
@Model()
class User {
  String firstName;
  String lastName;
  
  @Computed()
  String get fullName => '$firstName $lastName';
  
  // Generated toJson includes computed fields
  Map<String, dynamic> toJson({bool includeComputed = true}) {
    final json = {...};
    if (includeComputed) {
      json['fullName'] = fullName;
    }
    return json;
  }
}
```

---

### 13. Event Hooks Generation
**Goal**: Generate lifecycle hook methods.

**Proposed**:
```dart
@Model()
class Post {
  @BeforeCreate()
  void generateSlug() {
    slug = title.toLowerCase().replaceAll(' ', '-');
  }
  
  @AfterSave()
  void clearCache() {
    Cache.forget('posts');
  }
  
  @BeforeDelete()
  Future<void> deleteComments() async {
    await Comment.query().where('post_id', id).delete();
  }
}
```

---

## Priority

**High Priority**:
1. Type-Safe Relation Accessors (#1)
2. Query Builder with Field Names (#4)
3. Scoped Query Methods (#2)

**Medium Priority**:
4. Attribute Casting Helpers (#3)
5. Dirty Tracking Helpers (#7)
6. Soft Delete Helpers (#11)

**Nice to Have**:
7. Factory Constructors for Relations (#6)
8. Relationship Existence Queries (#8)
9. JSON Serialization Options (#9)
10. Computed/Virtual Attributes (#12)

**Future Consideration**:
11. Validation Rules Generation (#5)
12. Bulk Operations (#10)
13. Event Hooks Generation (#13)

---

## Testing Helpers (In Progress)

### Completed
- ✅ `Seeder` abstract class for database seeding
- ✅ `InMemoryQueryExecutor` for fast in-memory testing  
- ✅ Basic testing library export (`package:ormed/testing.dart`)
- ✅ Test suite verifying basic testing utilities

### TODO
- [ ] **TestDatabase** - Isolated test database instances
  - Needs proper DataSource API integration
  - Auto-registration with ConnectionManager
  - Cleanup on tearDown
  
- [ ] **DatabaseRefresher** - Database state management
  - Truncate strategy (clear all tables)
  - Migrate strategy (drop/recreate via migrations)
  - Transaction strategy (rollback after test)
  - Needs investigation of DataSource schema/migration APIs
  
- [ ] **Test Helpers**
  - `withTestDatabase()` - Scoped test database access
  - `withTransaction()` - Transaction-wrapped tests
  - Parallel test support (unique DB per test)
  
- [ ] **Documentation**
  - Testing guide in docs/
  - Examples of each testing pattern
  - Migration from other ORMs' testing approaches

---

## Implementation Notes

- All generated code should be in `.g.dart` files
- Should work seamlessly with existing manual code
- Must maintain backwards compatibility
- Consider performance implications
- Add feature flags for opt-in features
- Document all generated APIs
