import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:orm_playground/orm_playground.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('defaults to database.sqlite under current directory', () {
    final database = PlaygroundDatabase();
    final expected = p.normalize(
      p.join(Directory.current.path, 'database.sqlite'),
    );
    expect(database.databasePath, expected);
  });

  test('model registry registers generated definitions', () {
    final registry = buildOrmRegistry();
    expect(registry.contains<User>(), isTrue);
    expect(registry.contains<Post>(), isTrue);
    expect(registry.contains<Comment>(), isTrue);
  });

  test('dataSource creates and caches instances per tenant', () async {
    final database = PlaygroundDatabase();

    try {
      final defaultDs = await database.dataSource();
      final analyticsDs = await database.dataSource(tenant: 'analytics');

      // Verify they are initialized
      expect(defaultDs.isInitialized, isTrue);
      expect(analyticsDs.isInitialized, isTrue);

      // Verify they have different names
      expect(defaultDs.name, 'default');
      expect(analyticsDs.name, 'analytics');

      // Verify caching - same tenant returns same instance
      final defaultDs2 = await database.dataSource();
      expect(identical(defaultDs, defaultDs2), isTrue);
    } finally {
      await database.dispose();
    }
  });

  test('dataSource provides query and repo helpers', () async {
    final database = PlaygroundDatabase();

    try {
      final ds = await database.dataSource();

      // Verify query<T>() returns a Query
      final query = ds.query<User>();
      expect(query, isA<Query<User>>());

      // Verify repo<T>() returns a Repository
      final repo = ds.repo<User>();
      expect(repo, isA<Repository<User>>());

      // Verify table() returns an ad-hoc query
      final tableQuery = ds.table('users');
      expect(tableQuery, isA<Query<Map<String, Object?>>>());
    } finally {
      await database.dispose();
    }
  });

  test('dispose releases all data sources', () async {
    final database = PlaygroundDatabase();

    final defaultDs = await database.dataSource();
    final analyticsDs = await database.dataSource(tenant: 'analytics');

    expect(defaultDs.isInitialized, isTrue);
    expect(analyticsDs.isInitialized, isTrue);

    await database.dispose();

    expect(defaultDs.isInitialized, isFalse);
    expect(analyticsDs.isInitialized, isFalse);
  });

  test('generatedOrmModelDefinitions contains all models', () {
    final definitions = generatedOrmModelDefinitions;

    expect(definitions, isNotEmpty);
    expect(definitions.any((d) => d.modelName == 'User'), isTrue);
    expect(definitions.any((d) => d.modelName == 'Post'), isTrue);
    expect(definitions.any((d) => d.modelName == 'Comment'), isTrue);
    expect(definitions.any((d) => d.modelName == 'Tag'), isTrue);
  });
}
