part of 'repository.dart';

/// Read-side helpers for repositories, delegating to the query builder.
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

  Future<T?> find(Object id) => _scopedQuery('find').find(id);

  Future<List<T>> findMany(List<Object> ids) =>
      _scopedQuery('findMany').findMany(ids);

  Future<T> findOrFail(Object id) => _scopedQuery('findOrFail').findOrFail(id);

  Future<List<T>> all() => _scopedQuery('all').get();

  Future<T?> first({Object? where}) {
    final q = applyWhere(_scopedQuery('first'), where);
    return q.first();
  }

  Future<T> firstOrFail({Object? where}) {
    final q = applyWhere(_scopedQuery('firstOrFail'), where);
    return q.firstOrFail();
  }

  Future<bool> exists({Object? where}) async {
    final q = applyWhere(_scopedQuery('exists'), where);
    return q.exists();
  }

  Future<int> count({Object? where}) async {
    final q = applyWhere(_scopedQuery('count'), where);
    return q.count();
  }

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

  T replicate(T model) {
    final map = definition.toMap(model, registry: codecs);
    final pk = definition.primaryKeyField?.columnName;
    if (pk != null) {
      map.remove(pk);
    }
    final copy = definition.fromMap(map, registry: codecs);
    return copy;
  }

  Future<int> trash(Object where) =>
      applyWhere(_requireQuery('trash'), where, feature: 'trash').delete();

  Future<int> restore(Object where) =>
      applyWhere(_requireQuery('restore'), where, feature: 'restore')
          .restore();

  Future<int> forceDelete(Object where) => applyWhere(
        _requireQuery('forceDelete'),
        where,
        feature: 'forceDelete',
      ).forceDelete();
}
