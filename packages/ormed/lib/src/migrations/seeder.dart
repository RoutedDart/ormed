import 'dart:async';

import '../connection/orm_connection.dart';
import '../data_source.dart';
import '../model.dart';

/// Base class for database seeders
///
/// Seeders allow you to populate your database with test data in a
/// structured, reusable way.
///
/// ```dart
/// class UserSeeder extends Seeder {
///   @override
///   Future<void> run(DataSource dataSource) async {
///     await User.create({'name': 'Test User', 'email': 'test@example.com'});
///     await User.create({'name': 'Jane Doe', 'email': 'jane@example.com'});
///   }
/// }
///
/// // In your test
/// await testDb.seed([UserSeeder(), PostSeeder()]);
/// ```
abstract class Seeder {
  /// Run the seeder
  Future<void> run(DataSource dataSource);

  /// Optional: Get the order in which this seeder should run
  /// Lower numbers run first. Default is 0.
  int get order => 0;
}

/// Registry and runner for database seeders
class SeederRegistry {
  final List<Seeder> _seeders = [];

  /// Register a seeder
  void register(Seeder seeder) {
    _seeders.add(seeder);
  }

  /// Register multiple seeders
  void registerAll(List<Seeder> seeders) {
    _seeders.addAll(seeders);
  }

  /// Run all registered seeders in order
  Future<void> runAll(DataSource dataSource) async {
    // Sort seeders by order
    final sortedSeeders = List<Seeder>.from(_seeders)
      ..sort((a, b) => a.order.compareTo(b.order));

    for (final seeder in sortedSeeders) {
      await seeder.run(dataSource);
    }
  }

  /// Clear all registered seeders
  void clear() {
    _seeders.clear();
  }

  /// Get count of registered seeders
  int get count => _seeders.length;
}

/// Base class for database seeders that work with OrmConnection
///
/// This is the recommended base class for test seeders.
///
/// Example:
/// ```dart
/// class UserSeeder extends DatabaseSeeder {
///   UserSeeder(super.connection);
///
///   @override
///   Future<void> run() async {
///     await seed<User>([
///       {'name': 'John Doe', 'email': 'john@example.com'},
///       {'name': 'Jane Smith', 'email': 'jane@example.com'},
///     ]);
///   }
/// }
/// ```
abstract class DatabaseSeeder {
  DatabaseSeeder(this.connection);

  final OrmConnection connection;

  /// Run the seeder
  Future<void> run();

  /// Seed multiple records for a given model type
  ///
  /// Creates model instances from the provided data maps and persists them.
  ///
  /// Example:
  /// ```dart
  /// await seed<User>([
  ///   {'name': 'John', 'email': 'john@example.com'},
  ///   {'name': 'Jane', 'email': 'jane@example.com'},
  /// ]);
  /// ```
  Future<List<TModel>> seed<TModel extends Model<TModel>>(
      List<Map<String, dynamic>> records,
      ) async {
    final results = <TModel>[];
    for (final record in records) {
      final model = await Model.create<TModel>(
        record,
        connection: connection.name,
      );
      results.add(model);
    }
    return results;
  }

  /// Call other seeders
  ///
  /// Useful for composing seeders and managing dependencies.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> run() async {
  ///   await call([UserSeeder.new, PostSeeder.new]);
  /// }
  /// ```
  Future<void> call(
      List<DatabaseSeeder Function(OrmConnection)> factories,
      ) async {
    for (final factory in factories) {
      final seeder = factory(connection);
      await seeder.run();
    }
  }
}

/// Extension on DataSource for convenient seeding
extension DataSourceSeeding on DataSource {
  /// Seed the database with the given seeders
  Future<void> seed(List<Seeder> seeders) async {
    final registry = SeederRegistry()..registerAll(seeders);
    await registry.runAll(this);
  }
}
