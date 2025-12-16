import 'package:ormed_cli/runtime.dart';
import 'package:ormed/ormed.dart';

import 'database_seeder.dart';
// <ORM-SEED-IMPORTS>
// </ORM-SEED-IMPORTS>

final List<SeederRegistration> _seeders = <SeederRegistration>[
// <ORM-SEED-REGISTRY>
  SeederRegistration(
    name: 'AppDatabaseSeeder',
    factory: (context) => AppDatabaseSeeder(context.connection),
  ),
// </ORM-SEED-REGISTRY>
];

Future<void> runProjectSeeds(
  OrmConnection connection, {
  List<String>? names,
  bool pretend = false,
}) => runSeedRegistryOnConnection(
      connection,
      _seeders,
      names: names,
      pretend: pretend,
    );

Future<void> main(List<String> args) => runSeedRegistryEntrypoint(
      args: args,
      seeds: _seeders,
    );
