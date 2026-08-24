import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_drift/ormed_drift.dart';

const _authorColumns = [
  AdHocColumn(name: 'id', columnName: 'id', isPrimaryKey: true),
  AdHocColumn(name: 'name', columnName: 'name'),
];

Future<void> main() async {
  final driver = DriftDriverAdapter(
    NativeDatabase.memory(),
    closeDelegate: true,
  );
  final driftDatabase = drift.DatabaseConnection(driver.driftExecutor);
  OrmDatabase? database;
  StreamIterator<List<AdHocRow>>? snapshots;

  try {
    database = await OrmDatabase.connect(driver: driver);
    await database.migrate([
      MigrationEntry.named(
        'm_20260824000000_create_authors',
        const _CreateAuthorsMigration(),
      ),
    ]);
    snapshots = StreamIterator(
      database.table('authors', columns: _authorColumns).orderBy('id').watch(),
    );

    await _expectSnapshot(
      snapshots,
      expectedNames: const [],
      description: 'the initial Ormed snapshot',
    );

    // A write through Drift is visible to the Ormed watcher because both APIs
    // use the same DriftDriverAdapter and executor proxy.
    await driftDatabase.runInsert(
      'INSERT INTO authors (id, name) VALUES (?, ?)',
      [1, 'Ada'],
    );
    await _expectSnapshot(
      snapshots,
      expectedNames: const ['Ada'],
      description: 'the snapshot after a direct Drift write',
    );

    // A write through Ormed is visible through that same watcher as well.
    await database.table('authors', columns: _authorColumns).create({
      'id': 2,
      'name': 'Grace',
    });
    await _expectSnapshot(
      snapshots,
      expectedNames: const ['Ada', 'Grace'],
      description: 'the snapshot after an Ormed write',
    );

    // Drift publishes the change only when its transaction commits.
    final committed = driftDatabase.beginTransaction();
    await committed.ensureOpen(driver.executorUser);
    await committed.runInsert('INSERT INTO authors (id, name) VALUES (?, ?)', [
      3,
      'Katherine',
    ]);
    await committed.send();
    await _expectSnapshot(
      snapshots,
      expectedNames: const ['Ada', 'Grace', 'Katherine'],
      description: 'the snapshot after a committed Drift transaction',
    );

    final rolledBack = driftDatabase.beginTransaction();
    await rolledBack.ensureOpen(driver.executorUser);
    await rolledBack.runInsert('INSERT INTO authors (id, name) VALUES (?, ?)', [
      4,
      'Rolled back',
    ]);
    await rolledBack.rollback();

    final emittedAfterRollback = await snapshots.moveNext().timeout(
      const Duration(milliseconds: 250),
      onTimeout: () => false,
    );
    if (emittedAfterRollback) {
      throw StateError(
        'A rolled-back Drift transaction refreshed the watcher.',
      );
    }

    print('Drift and Ormed reactive integration validated.');
  } finally {
    await snapshots?.cancel();
    await database?.close();
  }
}

Future<void> _expectSnapshot(
  StreamIterator<List<AdHocRow>> snapshots, {
  required List<String> expectedNames,
  required String description,
}) async {
  final hasSnapshot = await snapshots.moveNext().timeout(
    const Duration(seconds: 2),
    onTimeout: () => false,
  );
  if (!hasSnapshot) {
    throw StateError('Timed out waiting for $description.');
  }

  final actualNames = snapshots.current
      .map((row) => row['name'])
      .whereType<String>()
      .toList(growable: false);
  if (actualNames.length != expectedNames.length ||
      !actualNames.every((name) => expectedNames.contains(name))) {
    throw StateError(
      'Unexpected names for $description: '
      'expected $expectedNames, got $actualNames.',
    );
  }
}

class _CreateAuthorsMigration extends Migration {
  const _CreateAuthorsMigration();

  @override
  void up(SchemaBuilder schema) {
    schema.create('authors', (table) {
      table.increments('id');
      table.string('name');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('authors', ifExists: true);
  }
}
