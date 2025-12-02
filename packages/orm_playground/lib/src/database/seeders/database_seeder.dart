import 'package:ormed/ormed.dart' as ormed;

import 'demo_content_seeder.dart';

/// Entrypoint seeder that can fan out to other seed classes.
class DatabaseSeeder extends ormed.DatabaseSeeder {
  DatabaseSeeder(super.connection);

  @override
  Future<void> run() async {
    await call([DemoContentSeeder.new]);
  }
}
