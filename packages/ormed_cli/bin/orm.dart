import 'package:args/command_runner.dart';

import '../lib/src/commands.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner<void>('orm', 'Routed ORM CLI')
    ..addCommand(InitCommand())
    ..addCommand(MakeCommand())
    ..addCommand(ApplyCommand())
    ..addCommand(RollbackCommand())
    ..addCommand(StatusCommand())
    ..addCommand(SchemaDescribeCommand())
    ..addCommand(SeedCommand());

  await runner.run(args);
}
