import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_drift/ormed_drift.dart';
import 'package:test/test.dart';

void main() {
  late drift.DatabaseConnection driftConnection;
  late DriftDriverAdapter driver;
  late OrmDatabase database;

  const columns = [
    AdHocColumn(name: 'id', columnName: 'id', isPrimaryKey: true),
    AdHocColumn(name: 'name', columnName: 'name'),
  ];

  setUp(() async {
    driver = DriftDriverAdapter(NativeDatabase.memory(), closeDelegate: true);
    driftConnection = drift.DatabaseConnection(driver.driftExecutor);
    await driftConnection.ensureOpen(_TestQueryExecutorUser());
    await driftConnection.runCustom('''
      CREATE TABLE authors (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
    database = await OrmDatabase.connect(driver: driver);
  });

  tearDown(() => database.close());

  Stream<List<AdHocRow>> watchAuthors() =>
      database.table('authors', columns: columns).orderBy('id').watch();

  test('refreshes Ormed watchers after writes from either API', () async {
    final iterator = StreamIterator(watchAuthors());

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, isEmpty);

    await driftConnection.runInsert(
      'INSERT INTO authors (id, name) VALUES (?, ?)',
      [1, 'Alice'],
    );
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.single['name'], 'Alice');

    await database.executeRaw('INSERT INTO authors (id, name) VALUES (?, ?)', [
      2,
      'Bob',
    ]);
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.map((row) => row['name']), ['Alice', 'Bob']);

    await iterator.cancel();
  });

  test(
    'publishes direct Drift changes only after transaction commit',
    () async {
      final snapshots = <List<AdHocRow>>[];
      final subscription = watchAuthors().listen(snapshots.add);
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(snapshots, hasLength(1));
      expect(snapshots.single, isEmpty);

      final committed = driftConnection.beginTransaction();
      await committed.ensureOpen(_TestQueryExecutorUser());
      await committed.runInsert(
        'INSERT INTO authors (id, name) VALUES (?, ?)',
        [1, 'Committed'],
      );
      await committed.send();
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(snapshots, hasLength(2));
      expect(snapshots.last.single['name'], 'Committed');

      final rolledBack = driftConnection.beginTransaction();
      await rolledBack.ensureOpen(_TestQueryExecutorUser());
      await rolledBack.runInsert(
        'INSERT INTO authors (id, name) VALUES (?, ?)',
        [2, 'Rolled back'],
      );
      await rolledBack.rollback();

      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(snapshots, hasLength(2));

      await subscription.cancel();
    },
  );

  test('opens the wrapped executor through Ormed database startup', () async {
    final unopened = DriftDriverAdapter(
      NativeDatabase.memory(),
      closeDelegate: true,
    );
    final opened = await OrmDatabase.connect(driver: unopened);
    addTearDown(opened.close);

    await opened.executeRaw('CREATE TABLE lifecycle_check (id INTEGER)');
    expect(
      await opened.queryRaw('SELECT name FROM sqlite_master WHERE name = ?', [
        'lifecycle_check',
      ]),
      hasLength(1),
    );
  });

  test('sync callback invalidates Ormed watchers', () async {
    var syncCalls = 0;
    final syncDriver = DriftDriverAdapter(
      NativeDatabase.memory(),
      closeDelegate: true,
      synchronize: () async {
        syncCalls++;
      },
    );
    final syncDatabase = await OrmDatabase.connect(driver: syncDriver);
    addTearDown(syncDatabase.close);
    await syncDatabase.executeRaw('''
      CREATE TABLE sync_check (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    final query = syncDatabase.table(
      'sync_check',
      columns: const [
        AdHocColumn(name: 'id', columnName: 'id', isPrimaryKey: true),
        AdHocColumn(name: 'name', columnName: 'name'),
      ],
    );
    final iterator = StreamIterator(query.watch());
    expect(await iterator.moveNext(), isTrue);

    await syncDriver.sync();
    expect(await iterator.moveNext(), isTrue);
    expect(syncCalls, 1);

    await iterator.cancel();
  });

  test(
    'exposes a PostgreSQL Drift profile without changing SQLite defaults',
    () {
      final postgres = DriftDriverAdapter.postgres(
        NativeDatabase.memory(),
        closeDelegate: true,
      );
      addTearDown(postgres.close);

      expect(postgres.metadata.name, 'postgres');
      expect(
        postgres.metadata.supportsCapability(DriverCapability.distinctOn),
        isTrue,
      );
      expect(
        postgres.profile.prepareSql("SELECT '?' AS literal, ? AS value"),
        r"SELECT '?' AS literal, $1 AS value",
      );
      expect(postgres.profile.insertPrefix(true), 'INSERT');
      expect(
        postgres.profile.insertConflictSuffix(true),
        ' ON CONFLICT DO NOTHING',
      );
    },
  );
}

class _TestQueryExecutorUser implements drift.QueryExecutorUser {
  @override
  Future<void> beforeOpen(
    drift.QueryExecutor executor,
    drift.OpeningDetails details,
  ) async {}

  @override
  int get schemaVersion => 1;
}
