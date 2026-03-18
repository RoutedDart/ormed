import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';

void main() async {
  final registry = ModelRegistry();
  final ds = DataSource(
    registry.mySqlDataSourceOptions(
      name: 'default',
      host: 'localhost',
      port: 3306,
      database: 'my_database',
      username: 'root',
      password: 'password',
    ),
  );
  // Initialize if you want to connect:
  // await ds.init();

  print('MySQL DataSource created: ${ds.options.driver.metadata.name}');
}
