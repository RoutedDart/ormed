import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'support/sqlite_test_harness.dart';

Future<void> main() async {
  final harness = await createSqliteTestHarness();

  tearDownAll(() async {
    await harness.dispose();
  });

  ormedTest('insertMany with typed repo - requires id', (dataSource) async {
    // Using typed repo - id is required but defaults to 0 for auto-increment
    await dataSource.repo<$Author>().insertMany([
      $Author(name: 'Alice', active: true),  // id defaults to 0, skipped on insert
      $Author(name: 'Bob', active: true),
      $Author(name: 'Charlie', active: true),
    ]);

    final authors = await dataSource.context.query<$Author>().get();

    print('Inserted ${authors.length} authors via typed repo');
    for (final author in authors) {
      print('  - ${author.id}: ${author.name}');
    }

    expect(authors.length, equals(3));
    expect(
      authors.map((a) => a.name).toList(),
      containsAll(['Alice', 'Bob', 'Charlie']),
    );
  });

  ormedTest('createMany with table() - untyped but flexible', (dataSource) async {
    // Using table() - no typing but doesn't require model fields
    await dataSource.table("authors").createMany([
      {"name": "Alice", "active": true},
      {"name": "Bob", "active": true},
      {"name": "Charlie", "active": true},
    ]);

    final authors = await dataSource.context.query<$Author>().get();

    print('Inserted ${authors.length} authors via table()');
    for (final author in authors) {
      print('  - ${author.id}: ${author.name}');
    }

    expect(authors.length, equals(3));
    expect(
      authors.map((a) => a.name).toList(),
      containsAll(['Alice', 'Bob', 'Charlie']),
    );
  });
}
