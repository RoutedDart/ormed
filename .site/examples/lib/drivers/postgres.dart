// Driver usage snippets for PostgreSQL.
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

import '../orm_registry.g.dart';

// #region postgres-datasource-url
Future<DataSource> createPostgresDataSourceFromUrl() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'default',
      driver: PostgresDriverAdapter.fromUrl(
        'postgres://postgres:postgres@localhost:5432/app',
      ),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
  return dataSource;
}
// #endregion postgres-datasource-url

// #region postgres-datasource-fields
Future<DataSource> createPostgresDataSourceFromFields() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'default',
      driver: PostgresDriverAdapter.custom(
        config: DatabaseConfig(
          driver: 'postgres',
          options: const {
            'host': 'localhost',
            'port': 5432,
            'database': 'app',
            'username': 'postgres',
            'password': 'postgres',
            'schema': 'public',
          },
        ),
      ),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
  return dataSource;
}
// #endregion postgres-datasource-fields
