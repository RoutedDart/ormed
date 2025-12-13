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
  /// Converts an insert input to a map suitable for insertion.
  ///
  /// For tracked models (`ModelAttributes`), applies legacy sentinel filtering
  /// to maintain backward compatibility.
  Map<String, Object?> insertInputToMap(
    Object input, {
    required bool applySentinelFiltering,
  }) {
    // Handle InsertDto
    if (input is InsertDto<T>) {
      return _normalizeColumnNames(input.toMap());
    }

    // Handle raw Map
    if (input is Map<String, Object?>) {
      return _normalizeColumnNames(input);
    }

    // Handle model (T extends OrmEntity)
    if (input is T) {
      return _modelToInsertMap(input, applySentinelFiltering: applySentinelFiltering);
    }

    throw ArgumentError.value(
      input,
      'input',
      'Expected InsertDto<$T>, Map<String, Object?>, or $T, got ${input.runtimeType}',
    );
  }

  /// Converts a model to a map for insertion, with optional sentinel filtering.
  Map<String, Object?> _modelToInsertMap(
    T model, {
    required bool applySentinelFiltering,
  }) {
    final map = definition.toMap(model, registry: codecs);

    if (!applySentinelFiltering) {
      return map;
    }

    // Legacy sentinel filtering for tracked models
    final filtered = Map<String, Object?>.from(map);
    for (final field in definition.fields) {
      if (!field.isInsertable) {
        final value = map[field.columnName];
        if (_isLegacySentinelValue(value, field)) {
          filtered.remove(field.columnName);
        }
      }
    }
    return filtered;
  }

  /// Converts an update input to a map suitable for updates.
  Map<String, Object?> updateInputToMap(Object input) {
    // Handle UpdateDto
    if (input is UpdateDto<T>) {
      return _normalizeColumnNames(input.toMap());
    }

    // Handle raw Map
    if (input is Map<String, Object?>) {
      return _normalizeColumnNames(input);
    }

    // Handle model (T extends OrmEntity)
    if (input is T) {
      return _modelToUpdateMap(input);
    }

    throw ArgumentError.value(
      input,
      'input',
      'Expected UpdateDto<$T>, Map<String, Object?>, or $T, got ${input.runtimeType}',
    );
  }

  /// Converts a model to a map for updates.
  Map<String, Object?> _modelToUpdateMap(T model) {
    final allValues = definition.toMap(model, registry: codecs);

    // For updates, filter out non-updatable fields
    final values = <String, Object?>{};
    for (final field in definition.fields) {
      if (field.isUpdatable && allValues.containsKey(field.columnName)) {
        values[field.columnName] = allValues[field.columnName];
      }
    }
    return values;
  }

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

  /// Legacy sentinel value check for backward compatibility.
  ///
  /// For tracked models, sentinel values indicate "not set" for auto-increment
  /// fields and should be filtered out during inserts.
  bool _isLegacySentinelValue(Object? value, FieldDefinition field) {
    if (value == null) return true;
    if (field.autoIncrement) {
      if (value == 0 || value == -1) return true;
    }
    if (value == '') return true;
    if (field.defaultDartValue != null && value == field.defaultDartValue) {
      return true;
    }
    return false;
  }

  /// Extracts the primary key value from an input.
  ///
  /// Works with models, DTOs, and maps.
  Object? extractPrimaryKey(Object input) {
    final pkField = definition.primaryKeyField;
    if (pkField == null) {
      throw StateError(
        'Primary key required for ${definition.modelName}.',
      );
    }

    if (input is T) {
      final map = definition.toMap(input, registry: codecs);
      return map[pkField.columnName];
    }

    if (input is InsertDto<T>) {
      final map = input.toMap();
      return map[pkField.columnName] ?? map[pkField.name];
    }

    if (input is UpdateDto<T>) {
      final map = input.toMap();
      return map[pkField.columnName] ?? map[pkField.name];
    }

    if (input is Map<String, Object?>) {
      return input[pkField.columnName] ?? input[pkField.name];
    }

    throw ArgumentError.value(
      input,
      'input',
      'Cannot extract primary key from ${input.runtimeType}',
    );
  }

  /// Checks if the input is a tracked model (has ModelAttributes).
  bool isTrackedModel(Object input) => input is ModelAttributes;
}

