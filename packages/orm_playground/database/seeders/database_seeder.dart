import 'package:ormed_cli/runtime.dart';

import 'demo_content_seeder.dart';

/// Entrypoint seeder that can fan out to other seed classes.
class DatabaseSeeder extends Seeder {
  DatabaseSeeder(super.context);

  @override
  Future<void> run() async {
    await call([DemoContentSeeder.new]);
  }
}
