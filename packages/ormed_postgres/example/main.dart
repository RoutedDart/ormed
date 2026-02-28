import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

void main() async {
  final registry = ModelRegistry();
  final ds = DataSource(
    registry.postgresDataSourceOptions(
      name: 'default',
      host: 'localhost',
      port: 5432,
      database: 'my_database',
      username: 'postgres',
      password: 'password',
    ),
  );
  // Initialize if you want to connect:
  // await ds.init();

  print('PostgreSQL DataSource created: ${ds.options.driver.metadata.name}');
}
