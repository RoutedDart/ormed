part of 'repository.dart';

/// Mixin that provides insert operations for repositories.
mixin RepositoryInsertMixin<T> on RepositoryBase<T>, RepositoryHelpersMixin<T> {
  /// Inserts a single [model] into the database.
  ///
  /// By default, the returned future completes with the same model instance
  /// that was passed in. If [returning] is `true`, the returned future
  /// completes with a new model instance that contains the values that were
  /// actually inserted into the database.
  ///
  /// Example:
  /// ```dart
  /// final user = User(name: 'John Doe');
  /// final insertedUser = await repository.insert(user, returning: true);
  /// print(insertedUser.id); // The auto-generated primary key.
  /// ```
  Future<T> insert(T model, {bool returning = false}) async {
    final inserted = await insertMany([model], returning: returning);
    return inserted.first;
  }

  /// Inserts multiple [models] into the database.
  ///
  /// By default, the returned future completes with the same model instances
  /// that were passed in. If [returning] is `true`, the returned future
  /// completes with new model instances that contain the values that were
  /// actually inserted into the database.
  ///
  /// Example:
  /// ```dart
  /// final users = [User(name: 'John Doe'), User(name: 'Jane Doe')];
  /// final insertedUsers = await repository.insertMany(users, returning: true);
  /// print(insertedUsers.map((u) => u.id).toList()); // The auto-generated primary keys.
  /// ```
  Future<List<T>> insertMany(List<T> models, {bool returning = false}) async {
    if (models.isEmpty) return const [];
    final plan = buildInsertPlan(models, returning: returning);
    final result = await runMutation(plan);

    return mapResult(models, result, returning);
  }

  /// Inserts a single [model] into the database, ignoring any conflicts.
  ///
  /// Returns the number of affected rows.
  ///
  /// Example:
  /// ```dart
  /// final user = User(id: 1, name: 'John Doe');
  /// final affectedRows = await repository.insertOrIgnore(user);
  /// print(affectedRows); // 1 if the user was inserted, 0 otherwise.
  /// ```
  Future<int> insertOrIgnore(T model) => insertOrIgnoreMany([model]);

  /// Inserts multiple [models] into the database, ignoring any conflicts.
  ///
  /// Returns the number of affected rows.
  ///
  /// Example:
  /// ```dart
  /// final users = [User(id: 1, name: 'John Doe'), User(id: 2, name: 'Jane Doe')];
  /// final affectedRows = await repository.insertOrIgnoreMany(users);
  /// print(affectedRows); // The number of users that were inserted.
  /// ```
  Future<int> insertOrIgnoreMany(List<T> models) async {
    if (models.isEmpty) return 0;
    final plan = buildInsertPlan(
      models,
      returning: false,
      ignoreConflicts: true,
    );
    final result = await runMutation(plan);
    return result.affectedRows;
  }
}
