import 'package:artisan_args/artisan_args.dart';

import '../lib/src/commands.dart';

Future<void> main(List<String> args) async {
  final runner = ArtisanCommandRunner<void>('orm', 'Routed ORM CLI')
    ..addCommand(InitCommand())
    ..addCommand(MakeCommand())
    ..addCommand(ApplyCommand())
    ..addCommand(RollbackCommand())
    ..addCommand(StatusCommand())
    ..addCommand(SchemaDumpCommand())
    ..addCommand(SchemaDescribeCommand())
    ..addCommand(SeedCommand());

  await runner.run(args);
}
