import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_mysql/ormed_mysql.dart';

class MySqlTestHarness implements DriverTestHarness {
  MySqlTestHarness._(this.adapter, this.registry, this.context);

  @override
  final MySqlDriverAdapter adapter;
  final ModelRegistry registry;
  @override
  final QueryContext context;

  static Future<MySqlTestHarness> connect() async {
    final url =
        Platform.environment['MYSQL_URL'] ??
        'mysql://root:secret@localhost:6605/orm_test';
    final adapter = MySqlDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'mysql',
        options: {'url': url, 'ssl': true},
      ),
    );
    adapter.codecs
      ..registerCodecFor(PostgresPayloadCodec, const PostgresPayloadCodec())
      ..registerCodecFor(SqlitePayloadCodec, const SqlitePayloadCodec())
      ..registerCodecFor(MariaDbPayloadCodec, const MariaDbPayloadCodec());
    final registry = ModelRegistry()
      ..registerAll(driverTestModelDefinitions);
    registerDriverTestFactories();
    final context = QueryContext(
      registry: registry,
      driver: adapter,
      codecRegistry: adapter.codecs,
      queryLogHook: (entry) {
        final params = entry.parameters.isEmpty
            ? ''
            : ' params=${entry.parameters}';
        print('[SQL][${entry.type}] ${entry.sql}$params');
      },
    );
    final harness = MySqlTestHarness._(adapter, registry, context);
    await resetDriverTestSchema(adapter);
    return harness;
  }

  @override
  Future<void> dispose() async {
    await dropDriverTestSchema(adapter);
    await adapter.close();
  }

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
    await adapter.executeRaw('SET FOREIGN_KEY_CHECKS = 0');
    try {
      await context.repository<Post>().insertMany(posts.toList());
    } finally {
      await adapter.executeRaw('SET FOREIGN_KEY_CHECKS = 1');
    }
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
  Future<void> seedImages(Iterable<Image> images) async {
    await context.repository<Image>().insertMany(images.toList());
  }

  @override
  Future<void> seedPhotos(Iterable<Photo> photos) async {
    await context.repository<Photo>().insertMany(photos.toList());
  }

  @override
  Future<void> seedComments(Iterable<Comment> comments) async {
    await context.repository<Comment>().insertMany(comments.toList());
  }

}
