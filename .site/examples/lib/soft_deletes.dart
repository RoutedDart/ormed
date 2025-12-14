// Soft delete examples for documentation
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

import 'models/post.dart';
import 'models/post.orm.dart';

// #region soft-delete-default
Future<void> softDeleteDefault(DataSource dataSource) async {
  // Only returns non-deleted posts
  final posts = await dataSource.query<$Post>().get();
}
// #endregion soft-delete-default

// #region soft-delete-with-trashed
Future<void> softDeleteWithTrashed(DataSource dataSource) async {
  // Returns all posts including deleted
  final allPosts = await dataSource.query<$Post>()
      .withTrashed()
      .get();
}
// #endregion soft-delete-with-trashed

// #region soft-delete-only-trashed
Future<void> softDeleteOnlyTrashed(DataSource dataSource) async {
  // Returns only deleted posts
  final trashedPosts = await dataSource.query<$Post>()
      .onlyTrashed()
      .get();
}
// #endregion soft-delete-only-trashed

// #region soft-delete-operations
Future<void> softDeleteOperations(DataSource dataSource, Post post, int postId) async {
  final repo = dataSource.repo<$Post>();

  // Soft delete (sets deleted_at)
  await repo.delete(post);
  await repo.delete({'id': postId});
}
// #endregion soft-delete-operations

// #region soft-delete-restore
Future<void> softDeleteRestore(DataSource dataSource, Post post, int postId, int userId) async {
  final repo = dataSource.repo<$Post>();

  // Restore a single record
  await repo.restore(post);
  await repo.restore({'id': postId});

  // Restore using query callback
  await repo.restore(
    (Query<$Post> q) => q.whereEquals('author_id', userId),
  );
}
// #endregion soft-delete-restore

// #region soft-delete-force
Future<void> softDeleteForce(DataSource dataSource, Post post, int postId) async {
  final repo = dataSource.repo<$Post>();

  // Permanently delete
  await repo.forceDelete(post);
  await repo.forceDelete({'id': postId});
}
// #endregion soft-delete-force

// #region soft-delete-status
Future<void> softDeleteStatus(DataSource dataSource, int postId) async {
  final post = await dataSource.query<$Post>()
      .withTrashed()
      .find(postId);

  if (post != null && post.trashed) {
    print('Post was deleted at: ${post.deletedAt}');
  }
}
// #endregion soft-delete-status

// #region soft-delete-combined-mixins
@OrmModel(table: 'posts')
class CombinedPost extends Model<CombinedPost> with Timestamps, SoftDeletes {
  const CombinedPost({required this.id, required this.title});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;
  final String title;
}

// Or timezone-aware versions
@OrmModel(table: 'tz_posts')
class CombinedPostTz extends Model<CombinedPostTz> with TimestampsTZ, SoftDeletesTZ {
  const CombinedPostTz({required this.id, required this.title});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;
  final String title;
}
// #endregion soft-delete-combined-mixins

// #region soft-delete-migration-combined
void softDeleteMigrationCombined(SchemaBuilder schema) {
  schema.create('posts', (table) {
    table.id();
    table.string('title');
    table.timestampsTz();   // created_at, updated_at
    table.softDeletesTz();  // deleted_at
  });
}
// #endregion soft-delete-migration-combined
