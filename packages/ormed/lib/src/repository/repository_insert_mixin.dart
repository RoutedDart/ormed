part of 'repository.dart';

/// Mixin that provides insert operations for repositories.
///
/// This mixin supports inserting data using:
/// - Tracked models (`$Model`)
/// - Insert DTOs (`$ModelInsertDto`)
/// - Raw maps (`Map<String, Object?>`)
mixin RepositoryInsertMixin<T extends OrmEntity>
    on RepositoryBase<T>, RepositoryHelpersMixin<T>, RepositoryInputHandlerMixin<T> {
  /// Inserts a single [model] into the database.
  ///
  /// Accepts tracked models, insert DTOs, or raw maps.
  ///
  /// By default, the returned future completes with the same model instance
  /// that was passed in (or a hydrated model if a DTO/map was used).
  /// If [returning] is `true`, the returned future completes with a new model
  /// instance that contains the values that were actually inserted into the
  /// database.
  ///
  /// Example with tracked model:
  /// ```dart
  /// final user = $User(name: 'John Doe', email: 'john@example.com');
  /// final insertedUser = await repository.insert(user, returning: true);
  /// print(insertedUser.id); // The auto-generated primary key.
  /// ```
  ///
  /// Example with insert DTO:
  /// ```dart
  /// final dto = $UserInsertDto(name: 'John Doe', email: 'john@example.com');
  /// final insertedUser = await repository.insert(dto, returning: true);
  /// ```
  ///
  /// Example with raw map:
  /// ```dart
  /// final data = {'name': 'John Doe', 'email': 'john@example.com'};
  /// final insertedUser = await repository.insert(data, returning: true);
  /// ```
  Future<T> insert(Object model, {bool returning = false}) async {
    final inserted = await insertMany([model], returning: returning);
    return inserted.first;
  }

  /// Inserts multiple items into the database.
  ///
  /// Accepts a list of tracked models, insert DTOs, or raw maps.
  /// All items in the list should be of the same type.
  ///
  /// By default, the returned future completes with the same model instances
  /// that were passed in. If [returning] is `true`, the returned future
  /// completes with new model instances that contain the values that were
  /// actually inserted into the database.
  ///
  /// Example:
  /// ```dart
  /// final users = [
  ///   $UserInsertDto(name: 'John', email: 'john@example.com'),
  ///   $UserInsertDto(name: 'Jane', email: 'jane@example.com'),
  /// ];
  /// final insertedUsers = await repository.insertMany(users, returning: true);
  /// ```
  Future<List<T>> insertMany(List<Object> inputs, {bool returning = false}) async {
    if (inputs.isEmpty) return const [];

    // Determine if we're dealing with tracked models for sentinel filtering
    final hasTrackedModels = inputs.any((input) => isTrackedModel(input));

    final plan = buildInsertPlanFromInputs(
      inputs,
      returning: returning,
      applySentinelFiltering: hasTrackedModels,
    );
    final result = await runMutation(plan);

    // For returning results, we need the original models if available
    final originalModels = inputs.whereType<T>().toList();

    // Extract the input maps from the plan for merging with returned data
    final inputMaps = plan.rows.map((r) => r.values).toList();
    return mapResultWithInputs(originalModels, inputMaps, result, returning);
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

    final hasTrackedModels = inputs.any((input) => isTrackedModel(input));

    final plan = buildInsertPlanFromInputs(
      inputs,
      returning: false,
      ignoreConflicts: true,
      applySentinelFiltering: hasTrackedModels,
    );
    final result = await runMutation(plan);
    return result.affectedRows;
  }

  /// Builds an insert plan from various input types.
  MutationPlan buildInsertPlanFromInputs(
    List<Object> inputs, {
    required bool returning,
    bool ignoreConflicts = false,
    bool applySentinelFiltering = false,
  }) {
    final rows = inputs.map((input) {
      // Apply timestamps to tracked models before serialization
      if (input is T) {
        _applyInsertTimestampsToModel(input);
      }

      final map = insertInputToMap(
        input,
        applySentinelFiltering: applySentinelFiltering && isTrackedModel(input),
      );

      // For non-tracked models, ensure timestamps in the map
      if (input is! ModelAttributes) {
        _ensureTimestampsInMap(map, isInsert: true);
      }

      return map;
    }).toList(growable: false);

    return MutationPlan.insert(
      definition: definition,
      rows: rows,
      driverName: driverName,
      returning: returning,
      ignoreConflicts: ignoreConflicts,
    );
  }
}
