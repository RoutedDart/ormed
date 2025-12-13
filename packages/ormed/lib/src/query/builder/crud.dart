part of '../query_builder.dart';

extension CrudExtension<T extends OrmEntity> on Query<T> {
  // ========================================================================
  // CRUD Operations
  // ========================================================================

  /// Creates a single record from the given attributes map.
  /// Returns the created model instance with its generated ID.
  ///
  /// Example:
  /// ```dart
  /// final user = await User.query().create({
  ///   'name': 'John Doe',
  ///   'email': 'john@example.com',
  /// });
  /// ```
  Future<T> create(Map<String, dynamic> attributes) async {
    final results = await createMany([attributes]);
    if (results.isEmpty) {
      throw StateError('Failed to create record');
    }
    return results.first;
  }

  /// Creates multiple records from a list of attribute maps.
  /// Returns the created model instances with their generated IDs.
  ///
  /// Example:
  /// ```dart
  /// final users = await User.query().createMany([
  ///   {'name': 'John Doe', 'email': 'john@example.com'},
  ///   {'name': 'Jane Smith', 'email': 'jane@example.com'},
  /// ]);
  /// ```
  Future<List<T>> createMany(List<Map<String, dynamic>> records) async {
    final models = records.map((attrs) {
      final normalized = _normalizeAttributeKeys(attrs);
      return definition.codec.decode(normalized, context.codecRegistry);
    }).toList();

    final repo = Repository<T>(
      definition: definition,
      driverName: context.driver.metadata.name,
      runMutation: context.runMutation,
      describeMutation: context.describeMutation,
      attachRuntimeMetadata: (model) {
        // Attach connection resolver to model if it supports it
        if (model is ModelConnection) {
          model.attachConnectionResolver(context);
        }
      },
    );

    return await repo.insertMany(
      models,
      returning:
          true, // Always request returning; drivers will use fallback if needed
    );
  }

  /// Finds the first record matching the attributes, or creates it if not found.
  ///
  /// The [attributes] map is used for searching.
  /// The [values] map provides additional attributes for creation if needed.
  ///
  /// Example:
  /// ```dart
  /// final user = await User.query().firstOrCreate(
  ///   {'email': 'john@example.com'},
  ///   {'name': 'John Doe'},
  /// });
  /// ```
  Future<T> firstOrCreate(
    Map<String, dynamic> attributes, [
    Map<String, dynamic> values = const {},
  ]) async {
    // Try to find existing
    var query = this;
    for (final entry in attributes.entries) {
      query = query.where(entry.key, entry.value, .equals);
    }

    final existing = await query.first();
    if (existing != null) {
      return existing;
    }

    // Create new record
    final combined = {...attributes, ...values};
    return await create(combined);
  }

  /// Updates the first record matching the attributes, or creates it if not found.
  ///
  /// The [attributes] map is used for searching.
  /// The [values] map provides the data to update or create with.
  ///
  /// Example:
  /// ```dart
  /// final user = await User.query().updateOrCreate(
  ///   {'email': 'john@example.com'},
  ///   {'name': 'John Updated'},
  /// );
  /// ```
  Future<T> updateOrCreate(
    Map<String, dynamic> attributes,
    Map<String, dynamic> values,
  ) async {
    // Try to find existing
    var query = this;
    for (final entry in attributes.entries) {
      query = query.where(entry.key, entry.value, PredicateOperator.equals);
    }

    final existing = await query.first();
    if (existing != null) {
      // Update existing
      await query.update(values);
      // Reload to get updated values
      return await query.first() ?? existing;
    }

    // Create new record
    final combined = {...attributes, ...values};
    return await create(combined);
  }

  /// Deletes records by their primary key(s).
  /// Accepts a single ID or a list of IDs.
  /// Returns the number of deleted rows.
  ///
  /// Example:
  /// ```dart
  /// await User.query().destroy(1);
  /// await User.query().destroy([1, 2, 3]);
  /// ```
  Future<int> destroy(dynamic ids) async {
    final pkField = definition.primaryKeyField;
    if (pkField == null) {
      throw StateError('Cannot destroy records without a primary key');
    }

    final idList = ids is List ? ids : [ids];
    if (idList.isEmpty) {
      return 0;
    }

    return await whereIn(pkField.name, idList).delete();
  }

  /// Executes the query and returns hydrated [QueryRow] objects.
  ///
  /// Each [QueryRow] contains the materialized model and its raw data.
  ///
  /// Example:
  /// ```dart
  /// final userRows = await context.query<User>().rows();
  /// for (final row in userRows) {
  ///   print('User ID: ${row.model.id}, Raw data: ${row.row}');
  /// }
  /// ```
  Future<List<QueryRow<T>>> rows() async {
    final plan = _buildPlan();
    final rows = await context.runSelect(plan);
    final queryRows = rows
        .map((row) => _hydrateRow(row, plan))
        .toList(growable: true);
    await _applyRelationHookBatch(plan, queryRows);
    return queryRows;
  }

  /// Returns only the models without the surrounding [QueryRow] metadata.
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>().get();
  /// for (final user in users) {
  ///   print('User name: ${user.name}');
  /// }
  /// ```
  Future<List<T>> get() async =>
      (await rows()).map((row) => row.model).toList(growable: false);

  /// Returns results hydrated into partial entities.
  ///
  /// Use this when you only need a subset of columns and want the
  /// type safety of the generated partial class.
  ///
  /// The [factory] parameter is the `fromRow` factory from the generated
  /// partial class (e.g., `UserPartial.fromRow`).
  ///
  /// Example:
  /// ```dart
  /// final partials = await context.query<User>()
  ///   .select(['id', 'email'])
  ///   .getPartial(UserPartial.fromRow);
  ///
  /// for (final partial in partials) {
  ///   print('User email: ${partial.email}');
  ///   // partial.toEntity() will throw if required fields are missing
  /// }
  /// ```
  Future<List<P>> getPartial<P extends PartialEntity<T>>(
    P Function(Map<String, Object?>) factory,
  ) async {
    final plan = _buildPlan();
    final rows = await context.runSelect(plan);
    return rows.map(factory).toList(growable: false);
  }

  /// Returns the first result as a partial entity or `null` if none exist.
  ///
  /// Use this when you only need a subset of columns from the first row.
  ///
  /// Example:
  /// ```dart
  /// final partial = await context.query<User>()
  ///   .where('id', 1)
  ///   .select(['id', 'email'])
  ///   .firstPartial(UserPartial.fromRow);
  ///
  /// if (partial != null) {
  ///   print('User email: ${partial.email}');
  /// }
  /// ```
  Future<P?> firstPartial<P extends PartialEntity<T>>(
    P Function(Map<String, Object?>) factory,
  ) async {
    final results = await limit(1).getPartial(factory);
    return results.isEmpty ? null : results.first;
  }

  /// Returns the first matching row or `null` if none exist.
  ///
  /// Example:
  /// ```dart
  /// final firstUserRow = await context.query<User>()
  ///   .orderBy('createdAt')
  ///   .firstRow();
  /// if (firstUserRow != null) {
  ///   print('First user: ${firstUserRow.model.name}');
  /// }
  /// ```
  Future<QueryRow<T>?> firstRow() async {
    final rows = await limit(1).rows();
    return rows.isEmpty ? null : rows.first;
  }

  /// Returns the first model instance or `null` when no rows exist.
  ///
  /// Example:
  /// ```dart
  /// final firstUser = await context.query<User>()
  ///   .orderBy('createdAt')
  ///   .first();
  /// if (firstUser != null) {
  ///   print('First user: ${firstUser.name}');
  /// }
  /// ```
  Future<T?> first() async => (await firstRow())?.model;

  /// Alias for [first] to match Laravel naming.
  Future<T?> firstOrNull() async => first();

  /// Returns the first model or throws when no records exist.
  ///
  /// Throws [ModelNotFoundException] if no record is found.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final user = await context.query<User>().where('id', 1).firstOrFail();
  ///   print('Found user: ${user.name}');
  /// } on ModelNotFoundException {
  ///   print('User with ID 1 not found.');
  /// }
  /// ```
  Future<T> firstOrFail({Object? key}) async {
    final model = await first();
    if (model != null) {
      return model;
    }
    throw ModelNotFoundException(definition.modelName, key: key);
  }

  /// Ensures there is exactly one record and returns it.
  ///
  /// Throws [ModelNotFoundException] if no record is found.
  /// Throws [MultipleRecordsFoundException] if more than one record is found.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final uniqueUser = await context.query<User>().where('email', 'unique@example.com').sole();
  ///   print('Found unique user: ${uniqueUser.name}');
  /// } on ModelNotFoundException {
  ///   print('No user found with that email.');
  /// } on MultipleRecordsFoundException {
  ///   print('Multiple users found with that email.');
  /// }
  /// ```
  Future<T> sole() async {
    final rows = await limit(2).rows();
    if (rows.isEmpty) {
      throw ModelNotFoundException(definition.modelName);
    }
    if (rows.length > 1) {
      throw MultipleRecordsFoundException(definition.modelName, rows.length);
    }
    return rows.first.model;
  }

  /// Finds a model by its primary key.
  ///
  /// Returns `null` if no model is found.
  /// Throws [StateError] if the model does not define a primary key.
  ///
  /// Example:
  /// ```dart
  /// final user = await context.query<User>().find(1);
  /// if (user != null) {
  ///   print('User found: ${user.name}');
  /// }
  /// ```
  Future<T?> find(Object key) async {
    final primaryKey = definition.primaryKeyField;
    if (primaryKey == null) {
      throw StateError(
        'Model ${definition.modelName} does not define a primary key.',
      );
    }
    return whereEquals(primaryKey.name, key).firstOrNull();
  }

  /// Finds multiple models by their primary keys.
  ///
  /// Returns an empty list if no models are found or [keys] is empty.
  /// Throws [StateError] if the model does not define a primary key.
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>().findMany([1, 2, 3]);
  /// print('Found ${users.length} users.');
  /// ```
  Future<List<T>> findMany(Iterable<Object> keys) async {
    final primaryKey = definition.primaryKeyField;
    if (primaryKey == null) {
      throw StateError(
        'Model ${definition.modelName} does not define a primary key.',
      );
    }
    final values = keys.toList(growable: false);
    if (values.isEmpty) return const [];
    return whereIn(primaryKey.name, values).get();
  }

  /// Finds a model by primary key or throws when missing.
  ///
  /// Throws [ModelNotFoundException] if no model is found.
  /// Throws [StateError] if the model does not define a primary key.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final user = await context.query<User>().findOrFail(1);
  ///   print('Found user: ${user.name}');
  /// } on ModelNotFoundException {
  ///   print('User with ID 1 not found.');
  /// }
  /// ```
  Future<T> findOrFail(Object key) async {
    final primaryKey = definition.primaryKeyField;
    if (primaryKey == null) {
      throw StateError(
        'Model ${definition.modelName} does not define a primary key.',
      );
    }
    return whereEquals(primaryKey.name, key).firstOrFail(key: key);
  }

  /// Returns a list of values from [field].
  ///
  /// This is useful for retrieving a list of scalar values from a column.
  ///
  /// Example:
  /// ```dart
  /// final userNames = await context.query<User>()
  ///   .pluck<String>('name');
  /// print('All user names: $userNames');
  /// ```
  Future<List<R>> pluck<R>(String field) async {
    final column = _ensureField(field).columnName;
    final rows = await select(<String>[field]).rows();
    return rows.map((row) => row.row[column] as R).toList(growable: false);
  }

  /// Updates rows that match the current query constraints.
  ///
  /// [values] is a map where keys are column names and values are the new values.
  ///
  /// Example:
  /// ```dart
  /// final updatedCount = await context.query<User>()
  ///   .where('id', 1)
  ///   .update({'name': 'New Name', 'email': 'new@example.com'});
  /// print('Updated $updatedCount users.');
  /// ```
  Future<int> update(Map<String, Object?> values) async {
    if (values.isEmpty) {
      return 0;
    }

    // Add automatic timestamp management for updated_at
    final valuesWithTimestamp = _addUpdateTimestamp(values);

    final payload = _normalizeUpdateValues(valuesWithTimestamp);
    if (payload.isEmpty) {
      return 0;
    }
    final mutation = _buildQueryUpdateMutation(
      values: payload.values,
      jsonUpdates: payload.jsonUpdates,
      feature: 'update',
    );
    final result = await context.runMutation(mutation);
    return result.affectedRows;
  }

  /// Adds updated_at timestamp to update values if the model has a timestamp field.
  /// Only adds if not already present in values and field exists with snake_case name.
  /// Returns the raw value (DateTime or Carbon) based on field type - not encoded since _normalizeUpdateValues will handle encoding.
  Map<String, Object?> _addUpdateTimestamp(Map<String, Object?> values) {
    // Check if model has updated_at field (snake_case only)
    try {
      final updatedAtField = definition.fields.firstWhere(
        (f) => f.columnName == 'updated_at',
      );

      final columnName = updatedAtField.columnName;

      // Only set if not already provided by user
      if (!values.containsKey(columnName)) {
        // Use Carbon for Carbon/CarbonInterface fields, DateTime for DateTime fields
        final now = Carbon.now();
        final fieldType = updatedAtField.dartType;

        if (fieldType == 'Carbon' ||
            fieldType == 'Carbon?' ||
            fieldType == 'CarbonInterface' ||
            fieldType == 'CarbonInterface?') {
          return {...values, columnName: now};
        } else {
          // Convert to DateTime for DateTime fields
          return {...values, columnName: now.toDateTime()};
        }
      }
    } catch (_) {
      // Field doesn't exist, return values as-is
    }

    return values;
  }

  /// Increments the value of a numeric [column] by [amount].
  ///
  /// [amount] defaults to 1.
  /// Throws [StateError] if the driver does not support increment operations.
  ///
  /// Example:
  /// ```dart
  /// final updatedCount = await context.query<Product>()
  ///   .where('id', 1)
  ///   .increment('stock', 5);
  /// print('Incremented stock for $updatedCount products.');
  /// ```
  Future<int> increment(String column, [num amount = 1]) {
    return _applyIncrement(column, amount, 'increment');
  }

  /// Decrements the value of a numeric [column] by [amount].
  ///
  /// [amount] defaults to 1.
  /// Throws [StateError] if the driver does not support decrement operations.
  ///
  /// Example:
  /// ```dart
  /// final updatedCount = await context.query<Product>()
  ///   .where('id', 1)
  ///   .decrement('stock', 2);
  /// print('Decremented stock for $updatedCount products.');
  /// ```
  Future<int> decrement(String column, [num amount = 1]) {
    return _applyIncrement(column, -amount.abs(), 'decrement');
  }

  /// Deletes all records matching the query conditions.
  ///
  /// Returns the number of affected rows.
  ///
  /// Example:
  /// ```dart
  /// final deletedCount = await context.query<User>()
  ///   .where('active', equals: false)
  ///   .delete();
  /// print('Deleted $deletedCount inactive users.');
  /// ```
  Future<int> delete() async {
    // If model supports soft deletes, perform soft delete instead
    final softDeleteField = _softDeleteField;
    if (softDeleteField != null) {
      final keys = await _collectPrimaryKeyConditions(this);
      if (keys.isEmpty) {
        return 0;
      }
      final now = Carbon.now();
      final rows = keys
          .map(
            (key) => MutationRow(
              values: {softDeleteField.columnName: now},
              keys: key,
            ),
          )
          .toList();
      final mutation = MutationPlan.update(
        definition: definition,
        rows: rows,
        driverName: context.driver.metadata.name,
      );
      final result = await context.runMutation(mutation);
      return result.affectedRows;
    }

    // Otherwise, perform hard delete
    final pkField = definition.primaryKeyField;
    if (pkField == null) {
      throw StateError(
        'delete requires ${definition.modelName} to declare a primary key.',
      );
    }
    final plan = _buildPlan();
    final mutation = MutationPlan.queryDelete(
      definition: definition,
      plan: plan,
      primaryKey: pkField.columnName,
      driverName: context.driver.metadata.name,
    );
    final result = await context.runMutation(mutation);
    return result.affectedRows;
  }

  /// Upserts (insert or update) a single record.
  ///
  /// If a record with the same unique key exists, it will be updated.
  /// Otherwise, a new record will be inserted.
  ///
  /// [attributes] contains the data to insert/update.
  /// [uniqueBy] specifies which fields make up the unique key (defaults to primary key).
  /// [updateColumns] specifies which columns to update on conflict (defaults to all non-unique columns).
  ///
  /// Returns the upserted model instance.
  ///
  /// Example:
  /// ```dart
  /// final user = await User.query().upsert(
  ///   {'email': 'john@example.com', 'name': 'John Doe', 'age': 30},
  ///   uniqueBy: ['email'],
  /// );
  /// ```
  Future<T> upsert(
    Map<String, dynamic> attributes, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
  }) async {
    final results = await upsertMany(
      [attributes],
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
    );
    if (results.isEmpty) {
      throw StateError('Failed to upsert record');
    }
    return results.first;
  }

  /// Upserts (inserts or updates) multiple records.
  ///
  /// If records with the same unique keys exist, they will be updated.
  /// Otherwise, new records will be inserted.
  ///
  /// [records] is a list of attribute maps to upsert.
  /// [uniqueBy] specifies which fields make up the unique key (defaults to primary key).
  /// [updateColumns] specifies which columns to update on conflict (defaults to all non-unique columns).
  ///
  /// Returns the list of upserted model instances.
  ///
  /// Example:
  /// ```dart
  /// final users = await User.query().upsertMany([
  ///   {'email': 'john@example.com', 'name': 'John Doe'},
  ///   {'email': 'jane@example.com', 'name': 'Jane Smith'},
  /// ], uniqueBy: ['email']);
  /// ```
  Future<List<T>> upsertMany(
    List<Map<String, dynamic>> records, {
    List<String>? uniqueBy,
    List<String>? updateColumns,
  }) async {
    if (records.isEmpty) return const [];

    // Normalize attribute keys but don't decode to models
    // Decoding to models would add default values like id: 0 for auto-increment fields
    final normalizedRecords = records.map((attrs) {
      return _normalizeAttributeKeys(attrs);
    }).toList();

    final repo = _buildRepository();

    // Pass maps directly - the repository handles DTOs/Maps
    return await repo.upsertMany(
      normalizedRecords,
      uniqueBy: uniqueBy,
      updateColumns: updateColumns,
      returning: true,
    );
  }

  /// Helper method to build a repository instance.
  Repository<T> _buildRepository() {
    return Repository<T>(
      definition: definition,
      driverName: context.driver.metadata.name,
      runMutation: context.runMutation,
      describeMutation: context.describeMutation,
      attachRuntimeMetadata: (model) {
        if (model is ModelConnection) {
          model.attachConnectionResolver(context);
        }
      },
    );
  }

  /// Normalizes attribute keys to use column names.
  /// Accepts both Dart property names (camelCase) and database column names (snake_case).
  Map<String, dynamic> _normalizeAttributeKeys(
    Map<String, dynamic> attributes,
  ) {
    final normalized = <String, dynamic>{};

    for (final entry in attributes.entries) {
      final key = entry.key;
      final value = entry.value;

      // Try to find field by property name first
      final fieldByName = definition.fieldByName(key);
      if (fieldByName != null) {
        normalized[fieldByName.columnName] = value;
        continue;
      }

      // Try to find by column name
      final fieldByColumn = definition.fieldByColumn(key);
      if (fieldByColumn != null) {
        normalized[key] = value;
        continue;
      }

      // If no field found, keep the original key (might be a virtual field or attribute)
      normalized[key] = value;
    }

    return normalized;
  }

  /// Updates existing record or inserts if it doesn't exist.
  ///
  /// [attributes] are used to find the record, [values] are the data to update/insert.
  ///
  /// Example:
  /// ```dart
  /// await context.query<User>()
  ///   .updateOrInsert(
  ///     {'email': 'john@example.com'},
  ///     {'name': 'John', 'age': 30},
  ///   );
  /// ```
  Future<bool> updateOrInsert(
    Map<String, Object?> attributes,
    Map<String, Object?> values,
  ) async {
    // Try to find existing record
    Query<T> query = this;
    for (final entry in attributes.entries) {
      query = query.where(entry.key, entry.value);
    }

    final existing = await query.first();
    if (existing != null) {
      // Update existing
      final updated = await query.update(values);
      return updated > 0;
    } else {
      // Insert new - this requires codec which we don't have here
      // This is a placeholder - actual implementation needs repository
      throw UnimplementedError(
        'updateOrInsert requires repository access for insertion. '
        'Use Model.updateOrCreate() instead.',
      );
    }
  }
}
