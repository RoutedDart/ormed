import 'package:ormed_cli/runtime.dart';
import 'package:ormed/ormed.dart';
import 'package:orm_playground/orm_playground.dart';

import 'seeders/database_seeder.dart';
import 'seeders/demo_content_seeder.dart';

final List<SeederRegistration> _seeders = <SeederRegistration>[
  SeederRegistration(name: 'DatabaseSeeder', factory: DatabaseSeeder.new),
  SeederRegistration(name: 'DemoContentSeeder', factory: DemoContentSeeder.new),
];

Future<void> seedPlayground(
  OrmConnection connection, {
  List<String>? names,
  bool pretend = false,
}) => runSeedRegistryOnConnection(
  connection,
  _seeders,
  names: names,
  pretend: pretend,
  beforeRun: (conn) => conn.context.registry.registerGeneratedModels(),
);

Future<void> main(List<String> args) => runSeedRegistryEntrypoint(
  args: args,
  seeds: _seeders,
  beforeRun: (connection) =>
      connection.context.registry.registerGeneratedModels(),
);
