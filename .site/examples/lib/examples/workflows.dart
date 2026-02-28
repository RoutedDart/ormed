// End-to-end workflow examples for documentation
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import '../models/user.dart';
import '../models/user.orm.dart';
import '../models/post.dart';
import '../models/post.orm.dart';
import '../src/database/datasource.dart';
import '../src/database/orm_registry.g.dart';

// #region sqlite-model
// See models/user.dart for the User model definition
// #endregion sqlite-model

// #region sqlite-query
Future<void> sqliteQueryExample() async {
  // Uses generated code-first runtime configuration.
  final dataSource = createDefaultDataSource();
  await dataSource.init();

  // Insert a user
  final user = await dataSource.repo<$User>().insert(
    $User(id: 0, email: 'john@example.com', name: 'John'),
  );

  // Query users
  final users = await dataSource
      .query<$User>()
      .whereEquals('name', 'John')
      .get();

  // Update
  user.setAttribute('name', 'John Smith');
  await dataSource.repo<$User>().update(user);

  // Delete
  await dataSource.repo<$User>().delete(user);

  await dataSource.dispose();
}
// #endregion sqlite-query

// #region static-helpers-pattern
Future<void> staticHelpersPattern() async {
  final dataSource = createDefaultDataSource();
  await dataSource.init();

  // Now static helpers work automatically!
  final users = await Users.query().get();
  final post = await Posts.find(1);

  await dataSource.dispose();
}
// #endregion static-helpers-pattern

// #region query-context-example
Future<void> queryContextExample() async {
  final registry = bootstrapOrm();
  final context = QueryContext(
    registry: registry,
    driver: SqliteDriverAdapter.inMemory(),
  );

  final users = await context.query<$User>().get();
  print('Users: ${users.length}');
}
// #endregion query-context-example

// #region observability-example
Future<void> observabilityExample() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'primary',
      driver: SqliteDriverAdapter.file('database.sqlite'),
      entities: generatedOrmModelDefinitions,
      logging: true,
    ),
  );
  await dataSource.init();

  // Log all queries
  dataSource.onQuery((entry) {
    print('Query: ${entry.sql}');
    print('Duration: ${entry.duration}ms');
  });

  await dataSource.query<$User>().get();
}
// #endregion observability-example

// #region eager-loading-example
Future<void> eagerLoadingExample(DataSource dataSource) async {
  // Load posts with their authors and comments
  final posts = await dataSource
      .query<$Post>()
      .with_(['author', 'comments'])
      .whereEquals('published', true)
      .orderBy('createdAt', descending: true)
      .limit(10)
      .get();

  for (final post in posts) {
    print('${post.title} by ${post.author?.name}');
    print('Comments: ${post.comments?.length}');
  }
}
// #endregion eager-loading-example

// #region eager-aggregates-example
Future<void> eagerAggregatesExample(DataSource dataSource) async {
  // Load users with post counts (without loading all posts)
  final users = await dataSource.query<$User>().get();

  for (final user in users) {
    await user.loadCount(['posts']);
    print('${user.name}: ${user.getAttribute<int>("posts_count")} posts');
  }

  // Or with withCount (if available on query builder)
  // final users = await dataSource.query<$User>()
  //     .withCount(['posts'])
  //     .get();
}
// #endregion eager-aggregates-example

// #region lazy-loading
Future<void> lazyLoadingExample(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().firstOrFail();

  // Lazy load when needed
  await post.load(['author']);
  print('Author: ${post.author?.name}');

  // Load multiple if not already loaded
  await post.loadMissing(['tags', 'comments']);

  // Nested relation loading
  await post.load(['comments.author']);
}
// #endregion lazy-loading

// #region lazy-loading-aggregates
Future<void> lazyLoadingAggregatesExample(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().firstOrFail();

  await post.loadCount(['comments']);
  print('Comments: ${post.getAttribute<int>("comments_count")}');

  await post.loadSum(['orders'], 'total', alias: 'order_total');
  print('Total: \$${post.getAttribute<num>("order_total")}');
}
// #endregion lazy-loading-aggregates

// #region relation-mutations
Future<void> relationMutationsExample(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().firstOrFail();

  // BelongsTo: Associate & Dissociate
  final author = await dataSource
      .query<$User>()
      .whereEquals('email', 'john@example.com')
      .firstOrFail();
  post.associate('author', author);
  await post.save();

  post.dissociate('author');
  await post.save();

  // ManyToMany: Attach, Detach & Sync
  await post.attach('tags', [1, 2, 3]);
  await post.detach('tags', [1]);
  await post.sync('tags', [4, 5, 6]);

  // With pivot data
  await post.attach(
    'tags',
    [7],
    pivotData: {'created_at': DateTime.now(), 'priority': 'high'},
  );
}
// #endregion relation-mutations

// #region batch-loading
Future<void> batchLoadingExample(DataSource dataSource) async {
  final posts = await dataSource.query<$Post>().limit(10).get();

  // Single query loads all authors
  await Model.loadRelations(posts, 'author');

  // Load multiple relations
  await Model.loadRelationsMany(posts, ['author', 'tags', 'comments']);

  // Load only missing relations
  await Model.loadRelationsMissing(posts, ['author', 'tags']);
}
// #endregion batch-loading

// #region prevent-lazy-loading
Future<void> preventLazyLoadingExample(DataSource dataSource) async {
  const environment = 'development';
  final post = await dataSource.query<$Post>().firstOrFail();

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
}
// #endregion prevent-lazy-loading

// #region manual-join
Future<void> manualJoinExample(DataSource dataSource) async {
  final recentPosts = await dataSource
      .query<$Post>()
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
    return '${model.title} by $author (${tag ?? "untagged"})';
  });
}
// #endregion manual-join

// #region seeding-data
Future<void> seedingDataExample(DataSource dataSource) async {
  // Truncate and seed
  await dataSource.repo<$User>().query().delete();

  final admin = await dataSource.repo<$User>().insert(
    $User(id: 0, email: 'admin@example.com', name: 'Admin'),
  );

  await dataSource.repo<$Post>().insertMany([
    $Post(id: 0, userId: admin.id, title: 'Hello', content: '...'),
    $Post(id: 0, userId: admin.id, title: 'Another', content: '...'),
  ]);
}

// #endregion seeding-data
