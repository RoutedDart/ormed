import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

import 'support/mongo_harness.dart';

void main() {
  late MongoTestHarness harness;

  setUpAll(() async {
    harness = await MongoTestHarness.create();
    await seedGraph(harness);
  });

  tearDownAll(() async => await harness.dispose());

  test('lists collections via inspector', () async {
    final tables = await harness.adapter.listTables();
    expect(tables.map((t) => t.name), contains('posts'));
    expect(tables.map((t) => t.name), contains('users'));
  });

  test('lists indexes for a collection', () async {
    final indexes = await harness.adapter.listIndexes('posts');
    expect(indexes.any((index) => index.columns.contains('_id')), isTrue);
  });

  test('exposes field metadata for collections', () async {
    final tables = await harness.adapter.listTables();
    final posts = tables.firstWhere((table) => table.name == 'posts');
    expect(posts.fields.any((field) => field.name == 'author_id'), isTrue);
    expect(
      posts.fields.firstWhere((field) => field.name == 'author_id').nullable,
      isFalse,
    );
  });
}
