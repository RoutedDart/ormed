/// Utilities for seeding SQLite test databases.
library;

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_sqlite/src/sqlite_codecs.dart';

class SqliteTestHarness implements DriverTestHarness {
  SqliteTestHarness._(this.adapter, this.registry, this.context);

  @override
  final SqliteDriverAdapter adapter;
  final ModelRegistry registry;
  @override
  final QueryContext context;

  static Future<SqliteTestHarness> inMemory() async {
    final adapter = SqliteDriverAdapter.inMemory();
    final augmentedCodecs = augmentSqliteCodecs(
      adapter.codecs,
    ); // Augment the existing codecs
    augmentedCodecs
      ..registerCodecFor(PostgresPayloadCodec, const PostgresPayloadCodec())
      ..registerCodecFor(SqlitePayloadCodec, const SqlitePayloadCodec());
    final registry = ModelRegistry()
      ..registerAll(driverTestModelDefinitions);
    registerDriverTestFactories();
    final context = QueryContext(
      registry: registry,
      driver: adapter,
      codecRegistry: augmentedCodecs, // Use the augmented codecs
      queryLogHook: (entry) {
        print('[SQL][${entry.type}] ${entry.sql}');
      },
    );

    final harness = SqliteTestHarness._(adapter, registry, context);
    await harness._createSchema();
    return harness;
  }

  @override
  Future<void> dispose() => adapter.close();

  @override
  Future<void> seedUsers(Iterable<User> users) async {
    await context.repository<User>().insertMany(users.toList());
  }

  @override
  Future<void> seedAuthors(Iterable<Author> authors) async {
    await context.repository<Author>().insertMany(authors.toList());
  }

  @override
  Future<void> seedPosts(Iterable<Post> posts) async {
    await context.repository<Post>().insertMany(posts.toList());
  }

  @override
  Future<void> seedTags(Iterable<Tag> tags) async {
    await context.repository<Tag>().insertMany(tags.toList());
  }

  @override
  Future<void> seedPostTags(Iterable<PostTag> entries) async {
    await context.repository<PostTag>().insertMany(entries.toList());
  }

  @override
  Future<void> seedArticles(Iterable<Article> articles) async {
    await context.repository<Article>().insertMany(articles.toList());
  }

  @override
  Future<void> seedPhotos(Iterable<Photo> photos) async {
    await context.repository<Photo>().insertMany(photos.toList());
  }

  @override
  Future<void> seedComments(Iterable<Comment> comments) async {
    await context.repository<Comment>().insertMany(comments.toList());
  }

  @override
  Future<void> seedImages(Iterable<Image> images) async {
    await context.repository<Image>().insertMany(images.toList());
  }

  Future<void> _createSchema() async {
    await resetDriverTestSchema(adapter);
  }
}
