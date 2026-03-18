// Driver internals snippets for documentation.
// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import '../models/user.dart';
import 'package:ormed_examples/src/database/orm_registry.g.dart';

// #region driver-internals-datasource
Future<DataSource> createDriverInternalsDemoDataSource() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'internals-demo',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
  return dataSource;
}
// #endregion driver-internals-datasource

// #region driver-internals-describe-query
StatementPreview previewSelectSql(DataSource dataSource) {
  return dataSource.query<$User>().whereEquals('email', 'a@b.com').toSql();
}
// #endregion driver-internals-describe-query

// #region driver-internals-describe-mutation
StatementPreview previewInsertSql(DataSource dataSource) {
  final repo = dataSource.repo<$User>();
  return repo.previewInsert({'email': 'a@b.com'});
}
// #endregion driver-internals-describe-mutation

// #region driver-internals-schema-inspector
Future<bool> hasUsersTable(DataSource dataSource) async {
  final driver = dataSource.connection.driver;
  if (driver is! SchemaDriver) return false;
  final inspector = SchemaInspector(driver);
  return inspector.hasTable('users');
}
// #endregion driver-internals-schema-inspector

// #region driver-internals-schema-plan-preview
SchemaPreview previewSchemaPlan(DataSource dataSource) {
  final driver = dataSource.connection.driver;
  if (driver is! SchemaDriver) {
    throw StateError('Driver does not support schema operations.');
  }
  final plan = SchemaPlan(
    mutations: [
      SchemaMutation.rawSql(
        'CREATE TABLE IF NOT EXISTS test_table (id INTEGER PRIMARY KEY)',
      ),
    ],
    description: 'demo plan preview',
  );
  return driver.describeSchemaPlan(plan);
}
// #endregion driver-internals-schema-plan-preview

// #region driver-internals-schema-state
Future<void> dumpSchemaIfSupported(DataSource dataSource) async {
  final driver = dataSource.connection.driver;
  if (driver is! SchemaStateProvider) return;
  final state = driver.createSchemaState(
    connection: dataSource.connection,
    ledgerTable: 'orm_migrations',
  );
  if (state == null || !state.canDump) return;
  await state.dump(File('database/schema.sql'));
}

// #endregion driver-internals-schema-state
