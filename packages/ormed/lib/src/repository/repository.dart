/// Write-side helpers for inserting models via driver adapters.
library;

import '../driver/driver.dart';
import '../model_definition.dart';
import '../model_mixins/model_attributes.dart';
import '../query/json_path.dart' as json_path;
import '../value_codec.dart';

typedef JsonUpdateBuilder<T> = List<JsonUpdateDefinition> Function(T model);

/// A repository for a model of type [T].
///
/// Provides methods for inserting, updating, upserting and deleting models.
class Repository<T> {
  Repository({
    required this.definition,
    required this.driverName,
    required ValueCodecRegistry codecs,
    required Future<MutationResult> Function(MutationPlan plan) runMutation,
    required StatementPreview Function(MutationPlan plan) describeMutation,
    required void Function(Object? model) attachRuntimeMetadata,
  }) : _codecs = codecs,
       _runMutation = runMutation,
       _describeMutation = describeMutation,
       _attachRuntimeMetadata = attachRuntimeMetadata;

  final ModelDefinition<T> definition;
  final String driverName;
  final ValueCodecRegistry _codecs;
  final Future<MutationResult> Function(MutationPlan plan) _runMutation;
  final StatementPreview Function(MutationPlan plan) _describeMutation;
  final void Function(Object? model) _attachRuntimeMetadata;

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
    final plan = _buildInsertPlan(models, returning: returning);
    final result = await _runMutation(plan);

    return _mapResult(models, result, returning);
  }

  /// Returns the statement preview for inserting [model].
  ///
  /// Example:
  /// ```dart
  /// final user = User(name: 'John Doe');
  /// final preview = repository.previewInsert(user);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewInsert(T model) => previewInsertMany([model]);

  /// Returns the statement preview for inserting [models].
  ///
  /// Example:
  /// ```dart
  /// final users = [User(name: 'John Doe'), User(name: 'Jane Doe')];
  /// final preview = repository.previewInsertMany(users);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewInsertMany(List<T> models) {
    _requireModels(models, 'previewInsertMany');
    final plan = _buildInsertPlan(models, returning: false);
    return _describeMutation(plan);
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
    final plan = _buildInsertPlan(
      models,
      returning: false,
      ignoreConflicts: true,
    );
    final result = await _runMutation(plan);
    return result.affectedRows;
  }

  /// Returns the statement preview for inserting [models] while ignoring conflicts.
  ///
  /// Example:
  /// ```dart
  /// final users = [User(id: 1, name: 'John Doe'), User(id: 2, name: 'Jane Doe')];
  /// final preview = repository.previewInsertOrIgnoreMany(users);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewInsertOrIgnoreMany(List<T> models) {
    _requireModels(models, 'previewInsertOrIgnoreMany');
    final plan = _buildInsertPlan(
      models,
      returning: false,
      ignoreConflicts: true,
    );
    return _describeMutation(plan);
  }

  /// Updates multiple [models] in the database.
  ///
  /// By default, the returned future completes with the same model instances
  /// that were passed in. If [returning] is `true`, the returned future
  /// completes with new model instances that contain the values that were
  /// actually updated in the database.
  ///
  /// An optional [jsonUpdates] builder can be provided to update JSON fields.
  ///
  /// Example:
  /// ```dart
  /// final user = await repository.find(1);
  /// user.name = 'John Smith';
  /// final updatedUsers = await repository.updateMany([user], returning: true);
  /// print(updatedUsers.first.name); // 'John Smith'
  /// ```
  Future<List<T>> updateMany(
    List<T> models, {
    bool returning = false,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (models.isEmpty) return const [];
    final plan = _buildUpdatePlan(
      models,
      returning: returning,
      jsonUpdates: jsonUpdates,
    );
    final result = await _runMutation(plan);

    return _mapResult(models, result, returning);
  }

  /// Updates multiple [models] in the database and returns the raw result.
  Future<MutationResult> updateManyRaw(
    List<T> models, {
    bool returning = false,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (models.isEmpty) return const MutationResult(affectedRows: 0);
    final plan = _buildUpdatePlan(
      models,
      returning: returning,
      jsonUpdates: jsonUpdates,
    );
    return _runMutation(plan);
  }

  /// Returns the statement preview for updating [models].
  ///
  /// Example:
  /// ```dart
  /// final user = await repository.find(1);
  /// user.name = 'John Smith';
  /// final preview = repository.previewUpdateMany([user]);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewUpdateMany(
    List<T> models, {
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    _requireModels(models, 'previewUpdateMany');
    final plan = _buildUpdatePlan(
      models,
      returning: false,
      jsonUpdates: jsonUpdates,
    );
    return _describeMutation(plan);
  }

  /// Upserts multiple [models] in the database.
  ///
  /// If a model with the same unique key already exists, it is updated.
  /// Otherwise, a new model is inserted.
  ///
  /// The [uniqueBy] parameter specifies the fields that make up the unique key.
  /// If not provided, the primary key is used.
  ///
  /// The [updateColumns] parameter specifies which columns to update if a
  /// conflict occurs. If not provided, all columns are updated.
  ///
  /// By default, the returned future completes with the same model instances
  /// that were passed in. If [returning] is `true`, the returned future
  /// completes with new model instances that contain the values that were
  /// actually upserted in the database.
  ///
  /// An optional [jsonUpdates] builder can be provided to update JSON fields.
  ///
  /// Example:
  /// ```dart
  /// final users = [User(id: 1, name: 'John Doe'), User(name: 'Jane Doe')];
  /// final upsertedUsers = await repository.upsertMany(users, returning: true);
  /// print(upsertedUsers.map((u) => u.id).toList());
  /// ```
  Future<List<T>> upsertMany(
    List<T> models, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    bool returning = false,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) async {
    if (models.isEmpty) return const [];
    final plan = _buildUpsertPlan(
      models,
      returning: returning,
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      jsonUpdates: jsonUpdates,
    );
    final result = await _runMutation(plan);

    return _mapResult(models, result, returning);
  }

  /// Returns the statement preview for upserting [models].
  ///
  /// Example:
  /// ```dart
  /// final users = [User(id: 1, name: 'John Doe'), User(name: 'Jane Doe')];
  /// final preview = repository.previewUpsertMany(users);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewUpsertMany(
    List<T> models, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    _requireModels(models, 'previewUpsertMany');
    final plan = _buildUpsertPlan(
      models,
      returning: false,
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      jsonUpdates: jsonUpdates,
    );
    return _describeMutation(plan);
  }

  /// Deletes records from the database by their [keys].
  ///
  /// Each key is a map of column names to values.
  ///
  /// Returns the number of affected rows.
  ///
  /// Example:
  /// ```dart
  /// final affectedRows = await repository.deleteByKeys([{'id': 1}, {'id': 2}]);
  /// print(affectedRows); // The number of deleted rows.
  /// ```
  Future<int> deleteByKeys(List<Map<String, Object?>> keys) async {
    if (keys.isEmpty) return 0;
    final plan = _buildDeletePlan(keys);
    final result = await _runMutation(plan);

    return result.affectedRows;
  }

  /// Returns the statement preview for deleting records by [keys].
  ///
  /// Example:
  /// ```dart
  /// final preview = repository.previewDeleteByKeys([{'id': 1}, {'id': 2}]);
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewDeleteByKeys(List<Map<String, Object?>> keys) {
    _requireKeys(keys);
    final plan = _buildDeletePlan(keys);
    return _describeMutation(plan);
  }

  /// Returns the statement preview for deleting the row described by [key].
  ///
  /// Example:
  /// ```dart
  /// final preview = repository.previewDelete({'id': 1});
  /// print(preview.statement); // The SQL statement that would be executed.
  /// print(preview.parameters); // The parameters for the SQL statement.
  /// ```
  StatementPreview previewDelete(Map<String, Object?> key) =>
      previewDeleteByKeys([key]);

  MutationRow _mutationRowFromModel(
    T model, {
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    final values = definition.toMap(model, registry: _codecs);
    final keyColumn = definition.primaryKeyField?.columnName;
    if (keyColumn == null) {
      throw StateError(
        'Primary key required for mutations on ${definition.modelName}.',
      );
    }
    final keyValue = values[keyColumn];
    if (keyValue == null) {
      throw StateError('Primary key column $keyColumn cannot be null.');
    }
    final jsonClauses = _jsonUpdatesFor(model, jsonUpdates);
    return MutationRow(
      values: values,
      keys: {keyColumn: keyValue},
      jsonUpdates: jsonClauses,
    );
  }

  List<T> _mapResult(List<T> original, MutationResult result, bool returning) {
    // If driver returned data (e.g., lastInsertID), merge it even if returning wasn't explicitly requested
    if (result.returnedRows == null || result.returnedRows!.isEmpty) {
      return original;
    }

    // Merge returned data with original models
    // Some drivers (like MySQL) only return PKs via lastInsertID, not full rows
    final returned = <T>[];
    for (int i = 0; i < result.returnedRows!.length; i++) {
      final returnedRow = result.returnedRows![i];
      final originalModel = i < original.length ? original[i] : null;

      final Map<String, Object?> mergedData;
      if (originalModel != null) {
        // Merge returned data (e.g., auto-generated PK) with original model data
        final originalData = definition.toMap(originalModel, registry: _codecs);
        mergedData = {...originalData, ...returnedRow};
      } else {
        mergedData = returnedRow;
      }

      final model = definition.fromMap(mergedData, registry: _codecs);
      _attachRuntimeMetadata(model);
      returned.add(model);
    }
    return returned;
  }

  MutationPlan _buildInsertPlan(
    List<T> models, {
    required bool returning,
    bool ignoreConflicts = false,
  }) {
    final rows = models.map((model) {
      final map = definition.toMap(model, registry: _codecs);
      
      // Filter out auto-increment primary keys with default/zero values
      // to allow the database to generate them
      final filtered = Map<String, Object?>.from(map);
      for (final field in definition.fields) {
        if (field.isPrimaryKey && field.autoIncrement) {
          final value = map[field.columnName];
          // Remove if null, 0, or empty string (common sentinel values)
          if (value == null || value == 0 || value == '') {
            filtered.remove(field.columnName);
          }
        }
      }
      return filtered;
    }).toList(growable: false);
    
    return MutationPlan.insert(
      definition: definition,
      rows: rows,
      driverName: driverName,
      returning: returning,
      ignoreConflicts: ignoreConflicts,
    );
  }

  MutationPlan _buildUpdatePlan(
    List<T> models, {
    required bool returning,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    final rows = models
        .map((model) => _mutationRowFromModel(model, jsonUpdates: jsonUpdates))
        .toList(growable: false);
    return MutationPlan.update(
      definition: definition,
      rows: rows,
      driverName: driverName,
      returning: returning,
    );
  }

  MutationPlan _buildUpsertPlan(
    List<T> models, {
    required bool returning,
    List<String>? uniqueBy,
    List<String>? updateColumns,
    JsonUpdateBuilder<T>? jsonUpdates,
  }) {
    final rows = models
        .map((model) => _mutationRowFromModel(model, jsonUpdates: jsonUpdates))
        .toList(growable: false);
    final uniqueColumns = _resolveColumnNames(uniqueBy);
    final updateColumnNames = _resolveColumnNames(updateColumns);
    return MutationPlan.upsert(
      definition: definition,
      rows: rows,
      driverName: driverName,
      returning: returning,
      uniqueBy: uniqueColumns,
      updateColumns: updateColumnNames,
    );
  }

  MutationPlan _buildDeletePlan(List<Map<String, Object?>> keys) {
    final rows = keys
        .map((conditions) => MutationRow(values: const {}, keys: conditions))
        .toList(growable: false);
    return MutationPlan.delete(
      definition: definition,
      rows: rows,
      driverName: driverName,
    );
  }

  void _requireModels(List<T> models, String method) {
    if (models.isEmpty) {
      throw ArgumentError.value(models, 'models', '$method requires models');
    }
  }

  void _requireKeys(List<Map<String, Object?>> keys) {
    if (keys.isEmpty) {
      throw ArgumentError.value(keys, 'keys', 'At least one key required');
    }
    for (final entry in keys) {
      if (entry.isEmpty) {
        throw ArgumentError.value(entry, 'key', 'Key map cannot be empty');
      }
    }
  }

  List<String>? _resolveColumnNames(List<String>? fields) {
    if (fields == null) return null;
    if (fields.isEmpty) {
      throw ArgumentError.value(fields, 'fields', 'At least one column name.');
    }
    return fields
        .map((name) => _fieldFor(name).columnName)
        .toList(growable: false);
  }

  FieldDefinition _fieldFor(String name) {
    final match = definition.fields.firstWhere(
      (field) => field.name == name || field.columnName == name,
      orElse: () => throw ArgumentError.value(
        name,
        'field',
        'Unknown field on ${definition.modelName}.',
      ),
    );
    return match;
  }

  List<JsonUpdateClause> _jsonUpdatesFor(
    T model,
    JsonUpdateBuilder<T>? builder,
  ) {
    final clauses = <JsonUpdateClause>[];
    if (builder != null) {
      final definitions = builder(model);
      for (final candidate in definitions) {
        clauses.add(_toJsonUpdateClause(candidate));
      }
    }
    if (model is ModelAttributes) {
      final pending = model.takeJsonAttributeUpdates();
      for (final update in pending) {
        clauses.add(
          JsonUpdateClause(
            column: _resolveColumnName(update.fieldOrColumn),
            path: update.path,
            value: update.value,
            patch: update.patch,
          ),
        );
      }
    }
    return clauses;
  }

  JsonUpdateClause _toJsonUpdateClause(JsonUpdateDefinition definition) =>
      JsonUpdateClause(
        column: _resolveColumnName(definition.fieldOrColumn),
        path: definition.path,
        value: definition.value,
        patch: definition.patch,
      );

  String _resolveColumnName(String input) {
    for (final field in definition.fields) {
      if (field.name == input || field.columnName == input) {
        return field.columnName;
      }
    }
    return input;
  }
}

/// Defines a JSON update operation.
class JsonUpdateDefinition {
  /// Creates a new [JsonUpdateDefinition].
  ///
  /// The [fieldOrColumn] is the name of the field or column to update.
  /// The [path] is the JSON path to the value to update.
  /// The [value] is the new value.
  /// If [patch] is `true`, the [value] is merged with the existing value.
  JsonUpdateDefinition({
    required this.fieldOrColumn,
    required this.path,
    required this.value,
    this.patch = false,
  });

  /// Creates a new [JsonUpdateDefinition] from a [selector] and [value].
  ///
  /// The [selector] is a string that contains the field/column name and the
  /// JSON path, e.g. `meta.tags`.
  factory JsonUpdateDefinition.selector(String selector, Object? value) {
    final parsed = json_path.parseJsonSelectorExpression(selector);
    if (parsed == null) {
      return JsonUpdateDefinition(
        fieldOrColumn: selector,
        path: r'$',
        value: value,
      );
    }
    return JsonUpdateDefinition(
      fieldOrColumn: parsed.column,
      path: parsed.path,
      value: value,
    );
  }

  /// Creates a new [JsonUpdateDefinition] from a [fieldOrColumn], [path] and
  /// [value].
  factory JsonUpdateDefinition.path(
    String fieldOrColumn,
    String path,
    Object? value,
  ) => JsonUpdateDefinition(
    fieldOrColumn: fieldOrColumn,
    path: json_path.normalizeJsonPath(path),
    value: value,
  );

  /// Creates a new [JsonUpdateDefinition] for a patch operation.
  ///
  /// The [fieldOrColumn] is the name of the field or column to update.
  /// The [delta] is a map of key-value pairs to merge with the existing value.
  factory JsonUpdateDefinition.patch(
    String fieldOrColumn,
    Map<String, Object?> delta,
  ) => JsonUpdateDefinition(
    fieldOrColumn: fieldOrColumn,
    path: r'$',
    value: delta,
    patch: true,
  );

  /// The name of the field or column to update.
  final String fieldOrColumn;

  /// The JSON path to the value to update.
  final String path;

  /// The new value.
  final Object? value;

  /// Whether to merge the [value] with the existing value.
  final bool patch;
}
