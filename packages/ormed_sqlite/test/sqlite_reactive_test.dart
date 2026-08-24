import 'dart:async';

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  late OrmDatabase database;

  const columns = [
    AdHocColumn(name: 'id', columnName: 'id', isPrimaryKey: true),
    AdHocColumn(name: 'name', columnName: 'name'),
  ];

  setUp(() async {
    database = await SqliteDatabase.connect(name: 'sqlite_reactive_test');
    await database.executeRaw('''
      CREATE TABLE authors (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  });

  tearDown(() => database.close());

  Stream<List<AdHocRow>> watchAuthors() =>
      database.table('authors', columns: columns).orderBy('id').watch();

  test('direct adapter writes refresh Ormed watchers', () async {
    final iterator = StreamIterator(watchAuthors());

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, isEmpty);

    await database.driver.executeRaw(
      'INSERT INTO authors (id, name) VALUES (?, ?)',
      [1, 'Alice'],
    );

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.single['name'], 'Alice');

    await iterator.cancel();
  });

  test('opaque CTE writes conservatively refresh Ormed watchers', () async {
    final iterator = StreamIterator(watchAuthors());

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, isEmpty);

    await database.driver.executeRaw(
      '''
      WITH new_author(id, name) AS (VALUES (?, ?))
      INSERT INTO authors (id, name)
      SELECT id, name FROM new_author
    ''',
      [1, 'Alice'],
    );

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.single['name'], 'Alice');

    await iterator.cancel();
  });

  test('adapter transaction changes publish only after commit', () async {
    final snapshots = <List<AdHocRow>>[];
    final subscription = watchAuthors().listen(snapshots.add);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, hasLength(1));

    await database.driver.beginTransaction();
    await database.driver.executeRaw(
      'INSERT INTO authors (id, name) VALUES (?, ?)',
      [1, 'Committed'],
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, hasLength(1));

    await database.driver.commitTransaction();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, hasLength(2));
    expect(snapshots.last.single['name'], 'Committed');

    await database.driver.beginTransaction();
    await database.driver.executeRaw(
      'INSERT INTO authors (id, name) VALUES (?, ?)',
      [2, 'Rolled back'],
    );
    await database.driver.rollbackTransaction();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, hasLength(2));

    await subscription.cancel();
  });

  test('manual Ormed transactions defer structured mutation changes', () async {
    final snapshots = <List<AdHocRow>>[];
    final subscription = watchAuthors().listen(snapshots.add);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, hasLength(1));

    await database.beginTransaction();
    await database.table('authors', columns: columns).create({
      'id': 1,
      'name': 'Committed',
    });
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, hasLength(1));

    await database.commit();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, hasLength(2));
    expect(snapshots.last.single['name'], 'Committed');

    await database.beginTransaction();
    await database.table('authors', columns: columns).create({
      'id': 2,
      'name': 'Rolled back',
    });
    await database.rollback();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(snapshots, hasLength(2));

    await subscription.cancel();
  });
}
