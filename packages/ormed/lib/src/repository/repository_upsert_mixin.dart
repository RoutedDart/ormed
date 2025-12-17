part of 'repository.dart';

/// Mixin that provides upsert operations for repositories.
///
/// {@macro ormed.query.insert_inputs}
///
/// {@macro ormed.query.upsert_options}
mixin RepositoryUpsertMixin<T extends OrmEntity>
    on
        RepositoryBase<T>,
        RepositoryHelpersMixin<T>,
        RepositoryInputHandlerMixin<T> {
  /// Upserts a single item in the database and returns the result.
  ///
  /// {@macro ormed.query.insert_inputs}
  ///
  /// If an item with the same unique key already exists, it is updated.
  /// Otherwise, a new item is inserted.
  ///
  /// {@macro ormed.query.upsert_options}
  ///
  /// Example with tracked model:
  /// ```dart
  /// final user = $User(id: 1, name: 'John Doe', email: 'john@example.com');
  /// final upserted = await repository.upsert(user);
  /// ```
  ///
  /// Example with insert DTO:
  /// ```dart
  /// final dto = $UserInsertDto(name: 'John Doe', email: 'john@example.com');
  /// final upserted = await repository.upsert(dto, uniqueBy: ['email']);
  /// ```
  Future<T> upsert(
    Object model, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    final upserted = await upsertMany(
      [model],
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      jsonUpdates: jsonUpdates,
    );
    return upserted.first;
  }

  /// Upserts multiple items in the database and returns the results.
  ///
  /// {@macro ormed.query.insert_inputs}
  ///
  /// If an item with the same unique key already exists, it is updated.
  /// Otherwise, a new item is inserted.
  ///
  /// {@macro ormed.query.upsert_options}
  ///
  /// {@macro ormed.mutation.json_updates}
  ///
  /// Example:
  /// ```dart
  /// final users = [
  ///   $UserInsertDto(name: 'John', email: 'john@example.com'),
  ///   $UserInsertDto(name: 'Jane', email: 'jane@example.com'),
  /// ];
  /// final upsertedUsers = await repository.upsertMany(
  ///   users,
  ///   uniqueBy: ['email'],
  /// );
  /// ```
  Future<List<T>> upsertMany(
    List<Object> inputs, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (inputs.isEmpty) return const [];

    final query = _requireQuery('upsertMany');
    return query.upsertInputs(
      inputs,
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      jsonUpdates: jsonUpdates,
    );
  }

  /// Extracts upsert values and keys from a tracked model.
}
