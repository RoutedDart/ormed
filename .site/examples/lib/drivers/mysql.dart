// Driver usage snippets for MySQL / MariaDB.
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';

import 'package:ormed_examples/src/database/orm_registry.g.dart';

// #region mysql-datasource-url
Future<DataSource> createMysqlDataSourceFromUrl() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'default',
      driver: MySqlDriverAdapter.fromUrl(
        'mysql://root:secret@localhost:3306/app',
      ),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
  return dataSource;
}
// #endregion mysql-datasource-url

// #region mysql-datasource-fields
Future<DataSource> createMysqlDataSourceFromFields() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'default',
      driver: MySqlDriverAdapter.custom(
        config: DatabaseConfig(
          driver: 'mysql',
          options: const {
            'host': '127.0.0.1',
            'port': 3306,
            'database': 'app',
            'username': 'root',
            'password': 'secret',
            'charset': 'utf8mb4',
            'collation': 'utf8mb4_general_ci',
          },
        ),
      ),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
  return dataSource;
}

// #endregion mysql-datasource-fields
