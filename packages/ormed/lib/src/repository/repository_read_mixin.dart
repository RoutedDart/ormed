part of 'repository.dart';

/// Read-side helpers for repositories, delegating to the query builder.
///
/// These methods provide a repository-centric façade over the corresponding
/// [Query] read operations.
mixin RepositoryReadMixin<T extends OrmEntity>
    on
        RepositoryBase<T>,
        RepositoryHelpersMixin<T>,
        RepositoryInsertMixin<T>,
        RepositoryUpsertMixin<T> {
  Query<T> _scopedQuery(String method) {
    final ctx = queryContext;
    if (ctx == null) {
      throw StateError(
        '$method requires a QueryContext; construct Repository via QueryContext.repository().',
      );
    }
    return ctx.query<T>();
  }

  /// Finds a record by primary key.
  ///
  /// Returns `null` when no record exists.
  Future<T?> find(Object id) => _scopedQuery('find').find(id);

  /// Finds multiple records by their primary keys.
  ///
  /// Returns an empty list when [ids] is empty or none of the records exist.
  Future<List<T>> findMany(List<Object> ids) =>
      _scopedQuery('findMany').findMany(ids);

  /// Finds a record by primary key or throws when missing.
  ///
  /// Throws [ModelNotFoundException] when no record is found.
  Future<T> findOrFail(Object id) => _scopedQuery('findOrFail').findOrFail(id);

  /// Returns all records for this model.
  Future<List<T>> all() => _scopedQuery('all').get();

  /// Returns the first record that matches [where], or `null` when none exist.
  ///
  /// {@macro ormed.query.where_input}
  Future<T?> first({Object? where}) {
    final q = applyWhere(_scopedQuery('first'), where);
    return q.first();
  }

  /// Returns the first record that matches [where] or throws when none exist.
  ///
  /// Throws [ModelNotFoundException] when no record is found.
  ///
  /// {@macro ormed.query.where_input}
  Future<T> firstOrFail({Object? where}) {
    final q = applyWhere(_scopedQuery('firstOrFail'), where);
    return q.firstOrFail();
  }

  /// Returns `true` when at least one record matches [where].
  ///
  /// {@macro ormed.query.where_input}
  Future<bool> exists({Object? where}) async {
    final q = applyWhere(_scopedQuery('exists'), where);
    return q.exists();
  }

  /// Returns the count of records that match [where].
  ///
  /// {@macro ormed.query.where_input}
  Future<int> count({Object? where}) async {
    final q = applyWhere(_scopedQuery('count'), where);
    return q.count();
  }

  /// Inserts or upserts [model], based on whether a primary key is present.
  ///
  /// If [model] has no primary key (or no primary key can be extracted), this
  /// delegates to [insert]. Otherwise it delegates to [upsert].
  ///
  /// This method accepts the same inputs as the write-side repository methods
  /// (tracked models, DTOs, or maps).
  ///
  /// ```dart
  /// final inserted = await repo.save($UserInsertDto(email: 'john@example.com'));
  /// final updated = await repo.save(
  ///   $UserUpdateDto(id: inserted.id, name: 'John'),
  /// );
  /// ```
  Future<T> save(Object model) async {
    final query = _requireQuery('save');
    final helper = MutationInputHelper<T>(
      definition: definition,
      codecs: query.context.codecRegistry,
    );

    final pk = helper.extractPrimaryKey(model);
    if (pk == null) {
      final inserted = await insert(model);
      return inserted;
    }
    final upserted = await upsert(model);
    return upserted;
  }

  /// Saves multiple inputs by inserting those without primary keys and
  /// upserting those with primary keys.
  ///
  /// Returns the concatenation of inserted and upserted results.
  Future<List<T>> saveMany(List<Object> models) async {
    if (models.isEmpty) return const [];
    final helper = MutationInputHelper<T>(
      definition: definition,
      codecs: codecs,
    );
    final withPk = <Object>[];
    final withoutPk = <Object>[];
    for (final m in models) {
      final pk = helper.extractPrimaryKey(m);
      if (pk == null) {
        withoutPk.add(m);
      } else {
        withPk.add(m);
      }
    }
    final results = <T>[];
    if (withoutPk.isNotEmpty) {
      results.addAll(await insertMany(withoutPk));
    }
    if (withPk.isNotEmpty) {
      results.addAll(await upsertMany(withPk));
    }
    return results;
  }

  /// Reloads [model] from the database by its primary key.
  ///
  /// Throws [StateError] when a primary key cannot be extracted.
  Future<T> refresh(T model) async {
    final query = _requireQuery('refresh');
    final helper = MutationInputHelper<T>(
      definition: definition,
      codecs: query.context.codecRegistry,
    );
    final pk = helper.extractPrimaryKey(model);
    if (pk == null) {
      throw StateError(
        'refresh requires a primary key for ${definition.modelName}.',
      );
    }
    return query.findOrFail(pk);
  }

  /// Creates an in-memory copy of [model] without persisting it.
  ///
  /// This emits a [ModelReplicatingEvent] and returns [model] unchanged if the
  /// event is cancelled.
  ///
  /// The returned copy has the primary key removed (when the model declares
  /// one), so it can be inserted as a new record.
  T replicate(T model) {
    final bus = queryContext?.events ?? EventBus.instance;
    final replicating = ModelReplicatingEvent(
      modelType: definition.modelType,
      tableName: definition.tableName,
      model: model,
    );
    bus.emit(replicating);
    if (replicating.isCancelled) return model;

    final map = definition.toMap(model, registry: codecs);
    final pk = definition.primaryKeyField?.columnName;
    if (pk != null) {
      map.remove(pk);
    }
    final copy = definition.fromMap(map, registry: codecs);
    return copy;
  }

  /// Soft-deletes or deletes records that match [where].
  ///
  /// For models that support soft deletes, this sets the soft-delete timestamp.
  /// For models that do not, this performs a hard delete.
  ///
  /// {@macro ormed.query.where_input}
  Future<int> trash(Object where) =>
      applyWhere(_requireQuery('trash'), where, feature: 'trash').delete();

  /// Restores soft-deleted records that match [where].
  ///
  /// Throws [StateError] when the model does not support soft deletes.
  ///
  /// {@macro ormed.query.where_input}
  Future<int> restore(Object where) =>
      applyWhere(_requireQuery('restore'), where, feature: 'restore').restore();

  /// Permanently deletes records that match [where], bypassing soft deletes.
  ///
  /// {@macro ormed.query.where_input}
  Future<int> forceDelete(Object where) => applyWhere(
    _requireQuery('forceDelete'),
    where,
    feature: 'forceDelete',
  ).forceDelete();
}
