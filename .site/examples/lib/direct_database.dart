// Codegen-optional examples for documentation.
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

// #region direct-connect
Future<OrmDatabase> connectWithoutCodegen() {
  return SqliteDatabase.connect(path: ':memory:');
}
// #endregion direct-connect

// #region direct-schema-and-sql
Future<List<Map<String, Object?>>> directSchemaAndSql(OrmDatabase db) async {
  await db.executeSchema((schema) {
    schema.create('users', (table) {
      table.id();
      table.string('name');
      table.boolean('active').defaultValue(true);
    });
  });

  await db.executeRaw(
    'INSERT INTO users (name, active) VALUES (?, ?)',
    ['Ada', true],
  );
  return db.queryRaw('SELECT id, name FROM users WHERE active = ?', [true]);
}
// #endregion direct-schema-and-sql

// #region direct-table-query
Future<List<AdHocRow>> directTableQuery(OrmDatabase db) {
  return db
      .table('users')
      .whereEquals('active', true)
      .orderBy('name')
      .get();
}
// #endregion direct-table-query

// #region direct-transaction
Future<void> directTransaction(OrmDatabase db) async {
  await db.transaction(() async {
    await db.executeRaw(
      'INSERT INTO users (name, active) VALUES (?, ?)',
      ['Grace', true],
    );
    await db.executeRaw(
      'UPDATE users SET active = ? WHERE name = ?',
      [false, 'Ada'],
    );
  });
}
// #endregion direct-transaction

// #region direct-ad-hoc-columns
Future<List<AdHocRow>> directColumnMetadata(OrmDatabase db) {
  return db
      .table(
        'users',
        columns: const [
          AdHocColumn(name: 'id', dartType: 'int', isPrimaryKey: true),
          AdHocColumn(name: 'name', dartType: 'String'),
        ],
      )
      .get();
}
// #endregion direct-ad-hoc-columns
