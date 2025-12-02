/// Testing utilities for ORM applications.
///
/// This library provides helpers for database testing including:
/// - In-memory query driver for fast tests
/// - Seeding utilities
/// - Schema management with migrations and seeding
library;

export 'src/migrations/seeder.dart';
export 'src/testing/test_database_manager.dart';
export 'src/testing/test_schema_manager.dart';
export 'src/testing/ormed_test.dart';
