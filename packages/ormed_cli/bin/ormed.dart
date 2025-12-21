import 'package:artisanal/args.dart';

import '../lib/src/commands.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner<void>('ormed', 'Routed ORM CLI')
    ..addCommand(InitCommand())
    ..addCommand(MakeCommand())
    ..addCommand(ApplyCommand())
    ..addCommand(ExportCommand())
    ..addCommand(RollbackCommand())
    ..addCommand(ResetCommand())
    ..addCommand(RefreshCommand())
    ..addCommand(FreshCommand())
    ..addCommand(StatusCommand())
    ..addCommand(SchemaDumpCommand())
    ..addCommand(SchemaDescribeCommand())
    ..addCommand(WipeCommand())
    ..addCommand(SeedCommand());

  await runner.run(args);
}
