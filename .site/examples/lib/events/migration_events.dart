// Migration and seeding event examples for documentation
// ignore_for_file: unused_import, unused_local_variable

import 'package:ormed/ormed.dart';

import '../migrations/basic.dart';
import '../models/user.dart';
import '../models/user.orm.dart';
import '../orm_registry.g.dart';

// #region migration-event-listeners
Future<void> migrationEventsExample(DriverAdapter schemaDriver) async {
  final bus = EventBus.instance;

  // #region migration-event-subscribe
  bus.on<MigrationBatchStartedEvent>((event) {
    print('Migration batch ${event.batch} started');
  });

  bus.on<MigrationStartedEvent>((event) {
    print('Applying ${event.id}');
  });

  bus.on<MigrationCompletedEvent>((event) {
    print('Applied ${event.id} in ${event.duration.inMilliseconds}ms');
  });

  bus.on<MigrationFailedEvent>((event) {
    print('Failed ${event.id}: ${event.error}');
  });
  // #endregion migration-event-subscribe

  // #region migration-event-runner
  final descriptors = MigrationEntry.buildDescriptors([
    MigrationEntry(
      id: MigrationId.parse('m_20241201000000_create_users_table'),
      migration: const CreateUsersTable(),
    ),
  ]);

  final runner = MigrationRunner(
    schemaDriver: schemaDriver,
    ledger: SqlMigrationLedger(schemaDriver, tableName: '_orm_migrations'),
    migrations: descriptors,
    events: bus,
  );

  await runner.applyAll();
  // #endregion migration-event-runner
}
// #endregion migration-event-listeners

// #region seeding-event-listeners
// #region seeding-seeder-class
class DemoUserSeeder extends DatabaseSeeder {
  DemoUserSeeder(super.connection);

  @override
  Future<void> run() async {
    await seed<User>([
      {'name': 'Demo', 'email': 'demo@example.com'},
    ]);
  }
}
// #endregion seeding-seeder-class

Future<void> seedingEventsExample(DataSource dataSource) async {
  await dataSource.init();

  final bus = EventBus.instance;

  // #region seeding-event-subscribe
  bus.on<SeedingStartedEvent>((event) {
    print('Seeding started: ${event.seederNames.join(', ')}');
  });

  bus.on<SeederStartedEvent>((event) {
    print('Running seeder ${event.seederName} (${event.index}/${event.total})');
  });

  bus.on<SeederCompletedEvent>((event) {
    print('Seeder ${event.seederName} finished in ${event.duration}');
  });

  bus.on<SeederFailedEvent>((event) {
    print('Seeder ${event.seederName} failed: ${event.error}');
  });

  bus.on<SeedingCompletedEvent>((event) {
    print('Seeding complete (${event.count} seeders) in ${event.duration}');
  });
  // #endregion seeding-event-subscribe

  // #region seeding-event-runner
  final runner = SeederRunner(events: bus);
  await runner.run(
    connection: dataSource.connection,
    seeders: const [
      SeederRegistration(name: 'DemoUserSeeder', factory: DemoUserSeeder.new),
    ],
  );
  // #endregion seeding-event-runner
}
// #endregion seeding-event-listeners
