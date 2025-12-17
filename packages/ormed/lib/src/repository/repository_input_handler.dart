part of 'repository.dart';

/// Union type representing valid inputs for repository insert operations.
///
/// This allows insert methods to accept:
/// - Tracked models (`T extends OrmEntity`)
/// - Insert DTOs (`InsertDto<T>`)
/// - Raw maps (`Map<String, Object?>`)
sealed class InsertInput<T extends OrmEntity> {
  const InsertInput();

  /// Creates an insert input from a model instance.
  const factory InsertInput.model(T model) = ModelInsertInput<T>;

  /// Creates an insert input from an insert DTO.
  const factory InsertInput.dto(InsertDto<T> dto) = DtoInsertInput<T>;

  /// Creates an insert input from a raw map.
  const factory InsertInput.map(Map<String, Object?> data) = MapInsertInput<T>;
}

/// Insert input wrapper for model instances.
final class ModelInsertInput<T extends OrmEntity> extends InsertInput<T> {
  const ModelInsertInput(this.model);

  final T model;
}

/// Insert input wrapper for insert DTOs.
final class DtoInsertInput<T extends OrmEntity> extends InsertInput<T> {
  const DtoInsertInput(this.dto);

  final InsertDto<T> dto;
}

/// Insert input wrapper for raw maps.
final class MapInsertInput<T extends OrmEntity> extends InsertInput<T> {
  const MapInsertInput(this.data);

  final Map<String, Object?> data;
}

/// Union type representing valid inputs for repository update operations.
///
/// This allows update methods to accept:
/// - Tracked models (`T extends OrmEntity`)
/// - Update DTOs (`UpdateDto<T>`)
/// - Raw maps (`Map<String, Object?>`)
sealed class UpdateInput<T extends OrmEntity> {
  const UpdateInput();

  /// Creates an update input from a model instance.
  const factory UpdateInput.model(T model) = ModelUpdateInput<T>;

  /// Creates an update input from an update DTO.
  const factory UpdateInput.dto(UpdateDto<T> dto) = DtoUpdateInput<T>;

  /// Creates an update input from a raw map.
  const factory UpdateInput.map(Map<String, Object?> data) = MapUpdateInput<T>;
}

/// Update input wrapper for model instances.
final class ModelUpdateInput<T extends OrmEntity> extends UpdateInput<T> {
  const ModelUpdateInput(this.model);

  final T model;
}

/// Update input wrapper for update DTOs.
final class DtoUpdateInput<T extends OrmEntity> extends UpdateInput<T> {
  const DtoUpdateInput(this.dto);

  final UpdateDto<T> dto;
}

/// Update input wrapper for raw maps.
final class MapUpdateInput<T extends OrmEntity> extends UpdateInput<T> {
  const MapUpdateInput(this.data);

  final Map<String, Object?> data;
}

/// Mixin that provides input handling utilities for repositories.
///
/// This mixin converts various input types (models, DTOs, maps) into
/// the map format required for mutation plans.
mixin RepositoryInputHandlerMixin<T extends OrmEntity> on RepositoryBase<T> {
  MutationInputHelper<T> get _inputHelper =>
      MutationInputHelper<T>(definition: definition, codecs: codecs);

  /// Converts an insert input to a map suitable for insertion.
  ///
  /// For tracked models (`ModelAttributes`), applies legacy sentinel filtering
  /// to maintain backward compatibility.
  ///
  /// Supports the following input types:
  /// - `T` (tracked model like `$User`) - Uses definition encoding with optional sentinel filtering
  /// - `InsertDto<T>` (like `UserInsertDto`) - Uses the DTO's `toMap()` directly
  /// - `UpdateDto<T>` (like `UserUpdateDto`) - Uses the DTO's `toMap()` (for upserts)
  /// - `Map<String, Object?>` - Uses as-is with column name normalization
  Map<String, Object?> insertInputToMap(
    Object input, {
    required bool applySentinelFiltering,
  }) {
    return _inputHelper.insertInputToMap(
      input,
      applySentinelFiltering: applySentinelFiltering,
    );
  }

  /// Converts an update input to a map suitable for updates.
  ///
  /// Supports the following input types:
  /// - `T` (tracked model like `$User`) - Uses definition encoding, filtering non-updatable fields
  /// - `UpdateDto<T>` (like `UserUpdateDto`) - Uses the DTO's `toMap()` directly
  /// - `InsertDto<T>` (like `UserInsertDto`) - Uses the DTO's `toMap()` (for flexibility)
  /// - `Map<String, Object?>` - Uses as-is with column name normalization
  Map<String, Object?> updateInputToMap(Object input) =>
      _inputHelper.updateInputToMap(input);

  /// Normalizes field names to column names if needed.
  ///
  /// DTOs and maps may use either field names or column names.
  /// This ensures all keys are column names.
  Map<String, Object?> _normalizeColumnNames(Map<String, Object?> input) {
    final result = <String, Object?>{};
    for (final entry in input.entries) {
      final columnName = _fieldToColumnName(entry.key);
      result[columnName] = entry.value;
    }
    return result;
  }

  /// Converts a field name to its corresponding column name.
  String _fieldToColumnName(String fieldOrColumn) {
    // First check if it's already a column name
    for (final field in definition.fields) {
      if (field.columnName == fieldOrColumn) {
        return fieldOrColumn;
      }
    }
    // Try to find by field name
    for (final field in definition.fields) {
      if (field.name == fieldOrColumn) {
        return field.columnName;
      }
    }
    // Return as-is if not found (could be a custom column)
    return fieldOrColumn;
  }

  /// Extracts the primary key value from an input.
  ///
  /// Works with models, DTOs, and maps.
  Object? extractPrimaryKey(Object input) {
    return _inputHelper.extractPrimaryKey(input);
  }

  /// Converts a "where" input to a map suitable for WHERE clauses.
  ///
  /// Supports the following input types:
  /// - `T` (tracked model like `$User`) - Extracts all column values
  /// - `PartialEntity<T>` (like `$UserPartial`) - Uses the partial's `toMap()`
  /// - `InsertDto<T>` (like `$UserInsertDto`) - Uses the DTO's `toMap()`
  /// - `UpdateDto<T>` (like `$UserUpdateDto`) - Uses the DTO's `toMap()`
  /// - `Map<String, Object?>` - Uses as-is with column name normalization
  /// - `null` - Returns null (no where clause)
  ///
  /// Example:
  /// ```dart
  /// // All of these work for where clauses:
  /// final map1 = whereInputToMap({'id': 1});
  /// final map2 = whereInputToMap($UserPartial(id: 1));
  /// final map3 = whereInputToMap($UserUpdateDto(id: 1));
  /// final map4 = whereInputToMap(existingUser);
  /// ```
  Map<String, Object?>? whereInputToMap(Object? input) =>
      _inputHelper.whereInputToMap(input);

  /// Checks if the input is a tracked model (has ModelAttributes).
  bool isTrackedModel(Object input) => input is ModelAttributes;
}
