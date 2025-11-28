library;

import 'package:ormed/ormed.dart';
import 'package:ormed/test_models/derived_for_factory.dart';

import '../../models.dart';
import '../migrations/migrations.dart';

final List<ModelDefinition> driverTestModelDefinitions = [
  UserOrmDefinition.definition,
  AuthorOrmDefinition.definition,
  PostOrmDefinition.definition,
  TagOrmDefinition.definition,
  PostTagOrmDefinition.definition,
  ArticleOrmDefinition.definition,
  PhotoOrmDefinition.definition,
  ImageOrmDefinition.definition,
  CommentOrmDefinition.definition,
  DriverOverrideEntryOrmDefinition.definition,
  SettingOrmDefinition.definition,
  SerialTestOrmDefinition.definition,
  DerivedForFactoryOrmDefinition.definition,
];

final List<MigrationDescriptor> driverTestMigrations = [
  MigrationDescriptor.fromMigration(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 1), 'create_users_table'),
    migration: const CreateUsersTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 2), 'create_authors_table'),
    migration: const CreateAuthorsTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 3), 'create_posts_table'),
    migration: const CreatePostsTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 4), 'create_tags_table'),
    migration: const CreateTagsTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 5),
      'create_post_tags_table',
    ),
    migration: const CreatePostTagsTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 6), 'create_articles_table'),
    migration: const CreateArticlesTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 7), 'create_photos_table'),
    migration: const CreatePhotosTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 8), 'create_images_table'),
    migration: const CreateImagesTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 9), 'create_comments_table'),
    migration: const CreateCommentsTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 10),
      'create_driver_override_entries_table',
    ),
    migration: const CreateDriverOverrideEntriesTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 11),
      'create_settings_table',
    ),
    migration: const CreateSettingsTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 12),
      'create_serial_tests_table',
    ),
    migration: const CreateSerialTestsTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 13),
      'create_mutation_targets_table',
    ),
    migration: const CreateMutationTargetsTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 14),
      'create_derived_for_factories_table',
    ),
    migration: const CreateDerivedForFactoriesTable(),
  ),
];

const _driverTestLedgerTable = 'orm_migrations';

MigrationRunner _createRunner(SchemaDriver driver) => MigrationRunner(
  schemaDriver: driver,
  ledger: SqlMigrationLedger(driver as DriverAdapter),
  migrations: driverTestMigrations,
);

Future<void> _purgeDriverTestSchema(SchemaDriver driver) async {
  final builder = SchemaBuilder();
  final seenTables = <String>{};
  for (final definition in driverTestModelDefinitions) {
    final table = definition.tableName;
    if (seenTables.add(table)) {
      builder.drop(table, ifExists: true, cascade: true);
    }
  }
  builder.drop(_driverTestLedgerTable, ifExists: true, cascade: true);
  if (builder.isEmpty) {
    return;
  }
  final plan = builder.build(description: 'purge-driver-test-schema');
  await driver.applySchemaPlan(plan);
}

Future<void> resetDriverTestSchema(SchemaDriver driver) async {
  await dropDriverTestSchema(driver);
  final runner = _createRunner(driver);
  await runner.applyAll();
}

Future<void> dropDriverTestSchema(SchemaDriver driver) async {
  final runner = _createRunner(driver);
  final status = await runner.status();
  final appliedCount = status.where((migration) => migration.applied).length;
  if (appliedCount > 0) {
    await runner.rollback(steps: appliedCount);
  }
  await _purgeDriverTestSchema(driver);
}

void registerDriverTestFactories() {
  ModelFactoryRegistry.register<DerivedForFactory>(
    DerivedForFactoryOrmDefinition.definition,
  );
}
