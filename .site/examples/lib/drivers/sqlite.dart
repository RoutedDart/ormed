// Driver usage snippets for SQLite.
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import '../orm_registry.g.dart';

// #region sqlite-datasource
Future<DataSource> createSqliteDataSource() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'default',
      driver: SqliteDriverAdapter.file('database.sqlite'),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
  return dataSource;
}
// #endregion sqlite-datasource

// #region sqlite-inmemory
DataSource createInMemorySqliteDataSource() {
  return DataSource(
    DataSourceOptions(
      name: 'test',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
}
// #endregion sqlite-inmemory
