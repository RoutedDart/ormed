import 'dart:io';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';

Future<void> main() async {
  final url = Platform.environment['MYSQL_URL'] ?? 
      'mysql://root:secret@localhost:6605/orm_test';
  
  final adapter = MySqlDriverAdapter.custom(
    config: DatabaseConfig(driver: 'mysql', options: {'url': url, 'ssl': true}),
  );
  
  final dataSource = DataSource(
    DataSourceOptions(
      driver: adapter,
      entities: generatedOrmModelDefinitions,
    ),
  );
  
  await dataSource.init();
  
  final manager = createDriverTestSchemaManager(adapter);
  
  print('Purging all tables...');
  await manager.purge();
  
  await dataSource.dispose();
  print('Done!');
}
