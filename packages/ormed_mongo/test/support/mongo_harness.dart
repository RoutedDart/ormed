import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_mongo/ormed_mongo.dart';

import '../shared.dart';

/// DriverTestHarness implementation that wires the Mongo adapter to the shared
/// driver test suites.
class MongoTestHarness implements DriverTestHarness {
  MongoTestHarness._(this.adapter, this.registry, this.context);

  @override
  final MongoDriverAdapter adapter;
  final ModelRegistry registry;
  @override
  final QueryContext context;

  static Future<MongoTestHarness> create() async {
    await waitForMongoReady();
    await clearDatabase();
    final adapter = createAdapter();
    final registry = ModelRegistry()
      ..registerAll([
        UserOrmDefinition.definition,
        AuthorOrmDefinition.definition,
        PostOrmDefinition.definition,
        TagOrmDefinition.definition,
        PostTagOrmDefinition.definition,
        ArticleOrmDefinition.definition,
        PhotoOrmDefinition.definition,
        ImageOrmDefinition.definition,
        CommentOrmDefinition.definition,
        DriverOverrideEntryOrmDefinition.definition,
      ]);
    final context = QueryContext(
      registry: registry,
      driver: adapter,
      codecRegistry: adapter.codecs,
    );
    return MongoTestHarness._(adapter, registry, context);
  }

  @override
  Future<void> dispose() => adapter.close();

  @override
  Future<void> seedArticles(Iterable<Article> articles) =>
      context.repository<Article>().insertMany(articles.toList());

  @override
  Future<void> seedAuthors(Iterable<Author> authors) =>
      context.repository<Author>().insertMany(authors.toList());

  @override
  Future<void> seedComments(Iterable<Comment> comments) =>
      context.repository<Comment>().insertMany(comments.toList());

  @override
  Future<void> seedImages(Iterable<Image> images) =>
      context.repository<Image>().insertMany(images.toList());

  @override
  Future<void> seedPhotos(Iterable<Photo> photos) =>
      context.repository<Photo>().insertMany(photos.toList());

  @override
  Future<void> seedPostTags(Iterable<PostTag> entries) =>
      context.repository<PostTag>().insertMany(entries.toList());

  @override
  Future<void> seedPosts(Iterable<Post> posts) =>
      context.repository<Post>().insertMany(posts.toList());

  @override
  Future<void> seedTags(Iterable<Tag> tags) =>
      context.repository<Tag>().insertMany(tags.toList());

  @override
  Future<void> seedUsers(Iterable<User> users) =>
      context.repository<User>().insertMany(users.toList());
}
