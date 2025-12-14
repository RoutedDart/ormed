part of 'repository.dart';

/// Mixin that provides upsert operations for repositories.
///
/// This mixin supports upserting data using:
/// - Tracked models (`$Model`)
/// - Insert DTOs (`$ModelInsertDto`)
/// - Update DTOs (`$ModelUpdateDto`)
/// - Raw maps (`Map<String, Object?>`)
mixin RepositoryUpsertMixin<T extends OrmEntity>
    on
        RepositoryBase<T>,
        RepositoryHelpersMixin<T>,
        RepositoryInputHandlerMixin<T> {
  /// Upserts a single item in the database and returns the result.
  ///
  /// Accepts tracked models, insert DTOs, update DTOs, or raw maps.
  ///
  /// If an item with the same unique key already exists, it is updated.
  /// Otherwise, a new item is inserted.
  ///
  /// The [uniqueBy] parameter specifies the fields that make up the unique key.
  /// If not provided, the primary key is used.
  ///
  /// The [updateColumns] parameter specifies which columns to update if a
  /// conflict occurs. If not provided, all columns are updated.
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
  /// Accepts a list of tracked models, insert DTOs, update DTOs, or raw maps.
  ///
  /// If an item with the same unique key already exists, it is updated.
  /// Otherwise, a new item is inserted.
  ///
  /// The [uniqueBy] parameter specifies the fields that make up the unique key.
  /// If not provided, the primary key is used.
  ///
  /// The [updateColumns] parameter specifies which columns to update if a
  /// conflict occurs. If not provided, all columns are updated.
  ///
  /// An optional [jsonUpdates] builder can be provided to update JSON fields.
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
    );
  }

  /// Extracts upsert values and keys from a tracked model.
}
