/// Testing utilities for ORM applications.
///
/// This library provides helpers for database testing including:
/// - In-memory query driver for fast tests
/// - Seeding utilities
/// - Schema management with migrations and seeding
///
/// ```dart
/// import 'package:ormed/testing.dart';
///
/// // Create an isolated DataSource per test/group.
/// final manager = TestDatabaseManager(baseDataSource: baseDataSource);
/// await manager.initialize();
///
/// final testDs = await manager.createDatabase('my_test');
/// try {
///   final users = await testDs.query<User>().get();
///   // ...
/// } finally {
///   await manager.dispose();
/// }
/// ```
library;

export 'src/migrations/seeder.dart';
export 'src/testing/ormed_test.dart';
export 'src/testing/test_database_manager.dart';
export 'src/testing/test_schema_manager.dart';
