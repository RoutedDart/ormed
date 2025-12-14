part of 'repository.dart';

/// Mixin that provides insert operations for repositories.
///
/// This mixin supports inserting data using:
/// - Tracked models (`$Model`)
/// - Insert DTOs (`$ModelInsertDto`)
/// - Raw maps (`Map<String, Object?>`)
mixin RepositoryInsertMixin<T extends OrmEntity>
    on
        RepositoryBase<T>,
        RepositoryHelpersMixin<T>,
        RepositoryInputHandlerMixin<T> {
  /// Inserts a single [model] into the database and returns the inserted record.
  ///
  /// Accepts tracked models, insert DTOs, or raw maps.
  ///
  /// The returned model contains the actual values from the database,
  /// including any auto-generated fields (like primary keys).
  ///
  /// Example with tracked model:
  /// ```dart
  /// final user = $User(name: 'John Doe', email: 'john@example.com');
  /// final insertedUser = await repository.insert(user);
  /// print(insertedUser.id); // The auto-generated primary key.
  /// ```
  ///
  /// Example with insert DTO:
  /// ```dart
  /// final dto = $UserInsertDto(name: 'John Doe', email: 'john@example.com');
  /// final insertedUser = await repository.insert(dto);
  /// ```
  ///
  /// Example with raw map:
  /// ```dart
  /// final data = {'name': 'John Doe', 'email': 'john@example.com'};
  /// final insertedUser = await repository.insert(data);
  /// ```
  Future<T> insert(Object model) async {
    final query = _queryOrNull;
    if (query != null) {
      final inserted = await query.insertManyInputs([model]);
      return inserted.first;
    }

    final inserted = await insertMany([model]);
    return inserted.first;
  }

  /// Inserts multiple items into the database and returns the inserted records.
  ///
  /// Accepts a list of tracked models, insert DTOs, or raw maps.
  /// All items in the list should be of the same type.
  ///
  /// The returned models contain the actual values from the database,
  /// including any auto-generated fields (like primary keys).
  ///
  /// Example:
  /// ```dart
  /// final users = [
  ///   $UserInsertDto(name: 'John', email: 'john@example.com'),
  ///   $UserInsertDto(name: 'Jane', email: 'jane@example.com'),
  /// ];
  /// final insertedUsers = await repository.insertMany(users);
  /// ```
  Future<List<T>> insertMany(
    List<Object> inputs, {
    bool returning = true,
  }) async {
    if (inputs.isEmpty) return const [];

    final query = _requireQuery('insertMany');
    return query.insertManyInputs(
      inputs,
      ignoreConflicts: false,
      returning: returning,
    );
  }

  /// Inserts a single item into the database, ignoring any conflicts.
  ///
  /// Accepts tracked models, insert DTOs, or raw maps.
  /// Returns the number of affected rows.
  ///
  /// Example:
  /// ```dart
  /// final dto = $UserInsertDto(id: 1, name: 'John Doe', email: 'john@example.com');
  /// final affectedRows = await repository.insertOrIgnore(dto);
  /// print(affectedRows); // 1 if the user was inserted, 0 otherwise.
  /// ```
  Future<int> insertOrIgnore(Object model) => insertOrIgnoreMany([model]);

  /// Inserts multiple items into the database, ignoring any conflicts.
  ///
  /// Accepts a list of tracked models, insert DTOs, or raw maps.
  /// Returns the number of affected rows.
  ///
  /// Example:
  /// ```dart
  /// final users = [
  ///   {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'},
  ///   {'id': 2, 'name': 'Jane Doe', 'email': 'jane@example.com'},
  /// ];
  /// final affectedRows = await repository.insertOrIgnoreMany(users);
  /// ```
  Future<int> insertOrIgnoreMany(List<Object> inputs) async {
    if (inputs.isEmpty) return 0;

    final query = _requireQuery('insertOrIgnoreMany');
    final result = await query.insertManyInputsRaw(
      inputs,
      ignoreConflicts: true,
    );
    return result.affectedRows;
  }
}
