// Setup examples for documentation
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import 'models/user.dart';
import 'models/user.orm.dart';
import 'models/post.dart';
import 'models/post.orm.dart';
import 'orm_registry.g.dart';

// #region quickstart-user-model
// See models/user.dart for the User model definition
// #endregion quickstart-user-model

// #region quickstart-setup
Future<void> quickstartSetup() async {
  // Create a SQLite adapter (file-backed)
  final driver = SqliteDriverAdapter.file('database.sqlite');

  // Use the generated registry helper
  final registry = buildOrmRegistry();

  // Create data source
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'primary',
      driver: driver,
      entities: registry.definitions.values.toList(),
    ),
  );

  await dataSource.init();

  // Now use the ORM!
  await useOrm(dataSource);

  await dataSource.dispose();
}

Future<void> useOrm(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();

  // Insert a user
  final user = await userRepo.insert(
    $User(id: 0, email: 'john@example.com', name: 'John Doe'),
  );
  print('Created user: ${user.id}');

  // Query users
  final users = await dataSource
      .query<$User>()
      .whereEquals('name', 'John Doe')
      .get();
  print('Found users: ${users.length}');

  // Update a user
  user.setAttribute('name', 'John Smith');
  final updated = await userRepo.update(user);
  print('Updated name: ${updated.name}');

  // Delete a user
  await userRepo.delete({'id': user.id});
  print('User deleted');
}
// #endregion quickstart-setup

// #region programmatic-config
Future<void> programmaticConfig() async {
  // Create driver
  final driver = InMemoryQueryExecutor();

  // Use the generated registry helper (includes all models)
  final registry = buildOrmRegistry();

  // Or with factory support
  final registryWithFactories = buildOrmRegistryWithFactories();

  // Or manually extend an existing registry
  final customRegistry = ModelRegistry()..registerGeneratedModels();

  // Create data source
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'primary',
      driver: driver,
      entities: registry.definitions.values.toList(),
    ),
  );

  await dataSource.init();
  // Use the data source...
}
// #endregion programmatic-config

// #region registry-usage
Future<void> registryUsage() async {
  // Pre-populated registry
  final registry = buildOrmRegistry();

  // Registry with factory support
  final registryWithFactories = buildOrmRegistryWithFactories();

  // Extension method
  final customRegistry = ModelRegistry()..registerGeneratedModels();

  // Direct access to definitions
  final definitions = generatedOrmModelDefinitions;
}
// #endregion registry-usage

// #region manual-registration
void manualRegistration() {
  final registry = ModelRegistry()
    ..register(UserOrmDefinition.definition)
    ..register(PostOrmDefinition.definition)
    ..registerTypeAlias<User>(UserOrmDefinition.definition);
}
// #endregion manual-registration

// #region constructor-targeting
// Override with the `constructor` parameter:
// @OrmModel(
//   table: 'users',
//   constructor: 'fromDatabase',
// )
// class User extends Model<User> {
//   // Default constructor - NOT used by generator
//   const User({required this.id, required this.email});
//
//   // Named constructor that the generator will use
//   const User.fromDatabase({required this.id, required this.email});
//
//   @OrmField(isPrimaryKey: true)
//   final int id;
//   final String email;
// }
// #endregion constructor-targeting

// #region generated-relation-getters
// Generated relation getters for lazy loading integration:
//
// **Single relations** (`belongsTo`, `hasOne`):
// @override
// Author? get author {
//   if (relationLoaded('author')) {
//     return getRelation<Author>('author');
//   }
//   return super.author;
// }
//
// **List relations** (`hasMany`, `manyToMany`):
// @override
// List<Tag> get tags {
//   if (relationLoaded('tags')) {
//     return getRelationList<Tag>('tags');
//   }
//   return super.tags;
// }
// #endregion generated-relation-getters

// #region driver-field-overrides
// Use driverOverrides for per-driver behavior:
// @OrmField(
//   columnType: 'TEXT',
//   driverOverrides: {
//     'postgres': OrmDriverFieldOverride(
//       columnType: 'jsonb',
//       codec: PostgresPayloadCodec,
//     ),
//     'sqlite': OrmDriverFieldOverride(
//       columnType: 'TEXT',
//       codec: SqlitePayloadCodec,
//     ),
//   },
// )
// final Map<String, Object?> payload;
// #endregion driver-field-overrides
