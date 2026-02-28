import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

void main() async {
  final registry = ModelRegistry();
  final ds = DataSource(
    registry.sqliteFileDataSourceOptions(
      path: 'database.sqlite',
      name: 'default',
    ),
  );
  // Initialize if you want to connect:
  // await ds.init();

  print('SQLite DataSource created: ${ds.options.driver.metadata.name}');
}
