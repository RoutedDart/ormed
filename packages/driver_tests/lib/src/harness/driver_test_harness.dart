import 'package:ormed/ormed.dart';

import '../../models.dart';

typedef DriverHarnessBuilder<T extends DriverTestHarness> =
    Future<T> Function();

/// Contract implemented by driver-specific test harnesses.
abstract class DriverTestHarness {
  DriverAdapter get adapter;
  QueryContext get context;

  Future<void> dispose();

  Future<void> seedUsers(Iterable<User> users);
  Future<void> seedAuthors(Iterable<Author> authors);
  Future<void> seedPosts(Iterable<Post> posts);
  Future<void> seedTags(Iterable<Tag> tags);
  Future<void> seedPostTags(Iterable<PostTag> entries);
  Future<void> seedArticles(Iterable<Article> articles);
  Future<void> seedImages(Iterable<Image> images);
  Future<void> seedPhotos(Iterable<Photo> photos);
  Future<void> seedComments(Iterable<Comment> comments);
}
