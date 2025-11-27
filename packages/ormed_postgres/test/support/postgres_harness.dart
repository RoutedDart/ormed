import 'dart:io';
import 'dart:math';

import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

class PostgresTestHarness implements DriverTestHarness {
  PostgresTestHarness._(
    this.adapter,
    this.registry,
    this.context,
    this._schema,
  );

  @override
  final PostgresDriverAdapter adapter;
  final ModelRegistry registry;
  @override
  final QueryContext context;
  final String _schema;
  String get schema => _schema;

  static Future<PostgresTestHarness> connect() async {
    final url =
        Platform.environment['POSTGRES_URL'] ??
        'postgres://postgres:postgres@localhost:6543/orm_test';
    final adapter = PostgresDriverAdapter.custom(
      config: DatabaseConfig(driver: 'postgres', options: {'url': url}),
    );
    adapter.codecs
      ..registerCodecFor(PostgresPayloadCodec, const PostgresPayloadCodec())
      ..registerCodecFor(SqlitePayloadCodec, const SqlitePayloadCodec());
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

    final schema = _randomSchemaName();
    final harness = PostgresTestHarness._(adapter, registry, context, schema);
    await harness._prepareSchema();
    await harness._recreateSchema();
    return harness;
  }

  @override
  Future<void> dispose() async {
    await adapter.executeRaw('DROP SCHEMA IF EXISTS "$_schema" CASCADE');
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

  Future<void> _prepareSchema() async {
    await adapter.executeRaw('DROP SCHEMA IF EXISTS "$_schema" CASCADE');
    await adapter.executeRaw('CREATE SCHEMA "$_schema"');
    await adapter.executeRaw('SET search_path TO "$_schema"');
  }

  Future<void> _recreateSchema() async {
    await resetDriverTestSchema(adapter);
  }

  static String _randomSchemaName() {
    final rng = Random();
    final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final randomPart = rng.nextInt(1 << 32).toRadixString(16);
    return 'orm_pg_${suffix}_$randomPart';
  }
}
