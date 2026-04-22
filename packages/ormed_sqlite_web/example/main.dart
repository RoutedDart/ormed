import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite_web/ormed_sqlite_web.dart';

Future<void> main() async {
  final registry = ModelRegistry();
  final ds = DataSource(
    registry.sqliteWebDataSourceOptions(
      name: 'web',
      database: 'app.sqlite',
      workerUri: 'worker.dart.js',
      wasmUri: 'sqlite3.wasm',
    ),
  );

  await ds.init();
  final rows = await ds.connection.driver.queryRaw('SELECT 1 AS ok');
  print(rows.first['ok']);
  await ds.dispose();
}
