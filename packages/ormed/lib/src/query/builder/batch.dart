part of '../query_builder.dart';

/// Extension providing batch operation methods for efficient bulk queries.
extension BatchOperationsExtension<T extends OrmEntity> on Query<T> {
  /// Updates multiple rows with different values in one atomic batch.
  ///
  /// This method allows you to update multiple records with different values
  /// in a single efficient operation. Each item in [updates] should be a map
  /// with the column name as key and the new value.
  ///
  /// Example:
  /// ```dart
  /// // Update scores for multiple users
  /// await context.query<User>().updateBatch([
  ///   {'id': 1, 'score': 100, 'status': 'active'},
  ///   {'id': 2, 'score': 95, 'status': 'active'},
  /// ], uniqueBy: 'id');
  /// ```
  Future<int> updateBatch(
    List<Map<String, Object?>> updates, {
    Object uniqueBy = 'id',
  }) async {
    if (updates.isEmpty) {
      return 0;
    }

    final uniqueFields = _resolveBatchUniqueFields(uniqueBy);
    final operations = <AtomicBatchOperation>[];

    for (final updateMap in updates) {
      final uniqueInputKeys = <String>{};
      var whereQuery = _copyWith();
      for (final field in uniqueFields) {
        final inputKey = _batchInputKey(updateMap, field);
        if (inputKey == null) {
          throw ArgumentError.value(
            updateMap,
            'updates',
            'Each update must include unique key "${field.name}" '
                '(${field.columnName}).',
          );
        }
        uniqueInputKeys
          ..add(inputKey)
          ..add(field.name)
          ..add(field.columnName);
        whereQuery = whereQuery.where(field.columnName, updateMap[inputKey]);
      }

      // Extract non-unique columns to update
      final updateFields = <String, Object?>{};
      for (final entry in updateMap.entries) {
        if (!uniqueInputKeys.contains(entry.key)) {
          updateFields[entry.key] = entry.value;
        }
      }

      // Only update if there are fields to update
      if (updateFields.isNotEmpty) {
        operations.add(whereQuery.batchUpdate(updateFields));
      }
    }

    if (operations.isEmpty) return 0;
    final results = await context.atomicBatch(operations);
    return results.fold<int>(0, (total, result) => total + result.affectedRows);
  }

  /// Inserts multiple records and returns all generated IDs.
  ///
  /// This method inserts multiple records in a batch and returns the list of
  /// generated IDs.
  ///
  /// Example:
  /// ```dart
  /// final ids = await context.query<User>().insertGetIds([
  ///   User(email: 'user1@example.com', name: 'User 1'),
  ///   User(email: 'user2@example.com', name: 'User 2'),
  /// ]);
  ///
  /// print('Created user IDs: $ids'); // [1, 2, 3]
  /// ```
  ///
  /// Returns: List of generated primary key values.
  Future<List<int>> insertGetIds(List<T> records) async {
    if (records.isEmpty) {
      return [];
    }

    final primaryKey = definition.primaryKeyField;
    if (primaryKey == null) {
      throw StateError(
        'insertGetIds requires ${definition.modelName} to declare a primary key.',
      );
    }

    final result = (await context.atomicBatch([
      batchInsert(records, returning: true),
    ])).single;
    final returnedIds = result.generatedIds.isNotEmpty
        ? result.generatedIds
        : result.rows
              .map((row) => row[primaryKey.columnName])
              .where((value) => value != null)
              .toList(growable: false);
    final ids = returnedIds.length == records.length
        ? returnedIds
        : records
              .map(
                (record) => definition.toMap(
                  record,
                  registry: context.codecRegistry,
                )[primaryKey.columnName],
              )
              .toList(growable: false);

    if (ids.length != records.length || ids.any((id) => id == null)) {
      throw UnsupportedError(
        '${context.driver.metadata.name} did not return generated IDs for '
        '${definition.modelName} inserts.',
      );
    }
    return ids.map(_coerceGeneratedId).toList(growable: false);
  }

  List<FieldDefinition> _resolveBatchUniqueFields(Object uniqueBy) {
    final values = switch (uniqueBy) {
      String value => <Object?>[value],
      List<Object?> values => values,
      _ => throw ArgumentError.value(
        uniqueBy,
        'uniqueBy',
        'Expected a column name or a list of column names.',
      ),
    };
    if (values.isEmpty) {
      throw ArgumentError.value(
        uniqueBy,
        'uniqueBy',
        'Must include at least one column name.',
      );
    }
    final fields = <FieldDefinition>[];
    final seen = <String>{};
    for (final value in values) {
      if (value is! String || value.isEmpty) {
        throw ArgumentError.value(
          value,
          'uniqueBy',
          'Column names must be non-empty strings.',
        );
      }
      final field = _ensureField(value);
      if (seen.add(field.columnName)) fields.add(field);
    }
    return fields;
  }

  String? _batchInputKey(Map<String, Object?> values, FieldDefinition field) {
    if (values.containsKey(field.columnName)) return field.columnName;
    if (values.containsKey(field.name)) return field.name;
    return null;
  }

  int _coerceGeneratedId(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw StateError(
      'insertGetIds expected integer primary keys but received '
      '${value.runtimeType}.',
    );
  }
}
