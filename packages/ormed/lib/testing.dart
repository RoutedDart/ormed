/// Provides utilities for testing ORM applications.
///
/// This library includes helpers for database isolation, lifecycle management,
/// and automated migrations during tests.
///
/// Key features:
/// - [TestDatabaseManager] for managing test database lifecycles.
/// - [ormedGroup] and [ormedTest] for isolated test definitions.
/// - Support for multiple isolation strategies (transactions, truncation, recreation).
///
/// For a detailed guide on testing, see the [Testing Guide](https://ormed.routed.dev/docs/guides/testing).
///
/// ### Basic Usage
///
/// ```dart
/// import 'package:ormed/testing.dart';
///
/// void main() {
///   setUpOrmed(
///     dataSource: myDataSource,
///     migrations: [CreateUsersTable()],
///   );
///
///   ormedGroup('User tests', (ds) {
///     ormedTest('can create user', (ds) async {
///       final user = await ds.repo<User>().insert(User(name: 'Alice'));
///       expect(user.id, isNotNull);
///     });
///   });
/// }
/// ```
library;

export 'src/migrations/seeder.dart';
export 'src/testing/ormed_test.dart';
export 'src/testing/test_database_manager.dart';
export 'src/testing/test_schema_manager.dart';
