import 'package:ormed_cli/runtime.dart';
import 'package:ormed/ormed.dart';

// #region seed-registry-imports
import 'database_seeder.dart';
// <ORM-SEED-IMPORTS>
// </ORM-SEED-IMPORTS>
// #endregion seed-registry-imports

// #region seed-registry-entries
final List<SeederRegistration> _seeders = <SeederRegistration>[
// <ORM-SEED-REGISTRY>
  SeederRegistration(
    name: 'AppDatabaseSeeder',
    factory: (context) => AppDatabaseSeeder(context.connection),
  ),
// </ORM-SEED-REGISTRY>
];
// #endregion seed-registry-entries

// #region seed-registry-run
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
// #endregion seed-registry-run

// #region seed-registry-main
Future<void> main(List<String> args) => runSeedRegistryEntrypoint(
      args: args,
      seeds: _seeders,
    );
// #endregion seed-registry-main
