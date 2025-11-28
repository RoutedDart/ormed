library;

import 'dart:async';
import 'dart:convert';

import 'connection/connection.dart';
import 'connection/connection_manager.dart';
import 'connection/connection_resolver.dart';
import 'connection/orm_connection.dart';
import 'driver/driver.dart';
import 'model_definition.dart';
import 'model_factory.dart';
import 'model_mixins/model_attributes.dart';
import 'model_mixins/model_connection.dart';
import 'model_mixins/model_relations.dart';
import 'model_registry.dart';
import 'query/query.dart';
import 'query/query_plan.dart';
import 'query/relation_loader.dart';
import 'repository/repository.dart';
import 'value_codec.dart';

typedef ConnectionResolverFactory =
    ConnectionResolver Function(String connectionName);

/// Base class that unifies attribute storage, connection awareness, and
/// self-persisting helpers for routed ORM models.
abstract class Model<TModel extends Model<TModel>>
    with ModelAttributes, ModelConnection, ModelRelations {
  const Model();

  static ConnectionResolverFactory? _resolverFactory;
  static ConnectionManager? _connectionManager;
  static String _defaultConnectionName = 'default';
  static ConnectionRole _defaultConnectionRole = ConnectionRole.primary;

  static final Expando<bool> _modelExists = Expando<bool>('_modelExists');

  // ignore: unused_element
  bool get _exists => _modelExists[this] ?? false;
  set _exists(bool value) => _modelExists[this] = value;

  /// Binds a global resolver factory so model helpers know how to persist.
  static void bindConnectionResolver({
    ConnectionResolverFactory? resolveConnection,
    ConnectionManager? connectionManager,
    String defaultConnection = 'default',
    ConnectionRole defaultRole = ConnectionRole.primary,
  }) {
    _resolverFactory = resolveConnection;
    _connectionManager = connectionManager;
    _defaultConnectionName = defaultConnection;
    _defaultConnectionRole = defaultRole;
  }

  /// Unbinds the global resolver factory (useful for tests).
  static void unbindConnectionResolver() {
    _resolverFactory = null;
    _connectionManager = null;
    _defaultConnectionName = 'default';
    _defaultConnectionRole = ConnectionRole.primary;
  }

  /// Starts a [Query] for [TModel], honoring the model's preferred connection.
  static Query<TModel> query<TModel extends Model<TModel>>({
    String? connection,
  }) {
    final initialResolver = _resolveBoundResolver(connection);
    final definition = initialResolver.registry.expect<TModel>();
    final metadataConnection = connection ?? definition.metadata.connection;
    if (_shouldRebindResolver(connection, metadataConnection)) {
      final resolver = _resolveBoundResolver(metadataConnection);
      final context = _requireQueryContext(resolver);
      return context.queryFromDefinition(definition);
    }
    final context = _requireQueryContext(initialResolver);
    return context.queryFromDefinition(definition);
  }

  /// Returns a factory builder that mirrors Laravel’s `Model::factory()` DSL.
  static ModelFactoryBuilder<TModel> factory<TModel extends Model<TModel>>({
    GeneratorProvider? generatorProvider,
  }) {
    final definition = ModelFactoryRegistry.definitionFor<TModel>();
    return ModelFactoryBuilder<TModel>(
      definition: definition,
      generatorProvider: generatorProvider,
    );
  }

  /// Convenience to fetch every model instance.
  static Future<List<TModel>> all<TModel extends Model<TModel>>() =>
      query<TModel>().get();

  /// Creates and immediately persists [model], returning the stored instance.
  static Future<TModel> create<TModel extends Model<TModel>>(TModel model) =>
      model.save();

  /// Typed accessor to the attached [ModelDefinition], when available.
  ModelDefinition<TModel>? get definition =>
      modelDefinition as ModelDefinition<TModel>?;

  /// Whether a [ModelDefinition] has been attached to this instance.
  bool get hasDefinition => definition != null;

  /// Ensures the definition metadata is available, throwing when missing.
  ModelDefinition<TModel> expectDefinition() {
    final existing = definition;
    if (existing != null) {
      return existing;
    }
    final resolver = connectionResolver;
    if (resolver != null) {
      final def = resolver.registry.expect<TModel>();
      _attachDefinition(def);
      return def;
    }
    final fallback = _resolveBoundResolver(null);
    final def = fallback.registry.expect<TModel>();
    _attachDefinition(def);
    return def;
  }

  /// Serializes the model into a column map via its codec/definition.
  Map<String, Object?> toRecord({ValueCodecRegistry? registry}) {
    final def = expectDefinition();
    final codecs =
        registry ??
        connectionResolver?.codecRegistry ??
        ValueCodecRegistry.standard();
    return def.toMap(_self(), registry: codecs);
  }

  /// Alias for [toRecord] for ergonomics when bridging to JSON/Maps.
  Map<String, Object?> asMap({ValueCodecRegistry? registry}) =>
      toRecord(registry: registry);

  ValueCodecRegistry _effectiveCodecRegistry(ValueCodecRegistry? registry) =>
      registry ??
      connectionResolver?.codecRegistry ??
      ValueCodecRegistry.standard();

  /// Converts the model into a metadata-aware map, honoring hidden/visible lists.
  Map<String, Object?> toArray({
    ValueCodecRegistry? registry,
    bool includeHidden = false,
  }) => serializableAttributes(
    includeHidden: includeHidden,
    registry: _effectiveCodecRegistry(registry),
  );

  /// Converts the model instance into JSON, applying the attribute metadata.
  String toJson({ValueCodecRegistry? registry, bool includeHidden = false}) {
    return jsonEncode(
      toArray(
        registry: _effectiveCodecRegistry(registry),
        includeHidden: includeHidden,
      ),
    );
  }

  /// Mass assigns [attributes], honoring fillable/guarded metadata.
  Model<TModel> fill(
    Map<String, Object?> attributes, {
    bool strict = true,
    ValueCodecRegistry? registry,
  }) {
    fillAttributes(
      attributes,
      strict: strict,
      registry: _effectiveCodecRegistry(registry),
    );
    return _self();
  }

  /// Mass assigns only values that are currently absent.
  Model<TModel> fillIfAbsent(
    Map<String, Object?> attributes, {
    bool strict = true,
    ValueCodecRegistry? registry,
  }) {
    final pending = <String, Object?>{};
    final existing = this.attributes;
    for (final entry in attributes.entries) {
      if (!existing.containsKey(entry.key) || existing[entry.key] == null) {
        pending[entry.key] = entry.value;
      }
    }
    fillAttributes(
      pending,
      strict: strict,
      registry: _effectiveCodecRegistry(registry),
    );
    return _self();
  }

  /// Temporarily disables mass-assignment protection while [callback] runs.
  Model<TModel> forceFill(
    Map<String, Object?> attributes, {
    ValueCodecRegistry? registry,
  }) {
    return ModelAttributes.unguarded(
      () => fill(
        attributes,
        strict: false,
        registry: _effectiveCodecRegistry(registry),
      ),
    );
  }

  /// Queues a JSON update using Laravel-style selector syntax
  /// (`column->path`). Call [save] to persist the change.
  void jsonSet(String selector, Object? value) =>
      setJsonAttributeValue(selector, value);

  /// Queues a JSON update by explicitly providing [path] relative to [column].
  void jsonSetPath(String column, String path, Object? value) =>
      setJsonAttributeValue(column, value, pathOverride: path);

  /// Queues a JSON patch merge for [column] using the provided [delta] map.
  void jsonPatch(String column, Map<String, Object?> delta) =>
      setJsonAttributePatch(column, delta);

  /// Clears any queued JSON mutations without persisting them.
  void clearQueuedJsonMutations() => clearJsonAttributeUpdates();

  /// Persists the model using the active resolver and returns the stored copy.
  Future<TModel> save({bool returning = true}) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final repository = _repositoryFor(def, resolver);
    final pkValue = _primaryKeyValue(def);
    List<TModel> persisted;

    if (def.primaryKeyField == null || pkValue == null) {
      persisted = await repository.insertMany(<TModel>[
        _self(),
      ], returning: returning);
    } else {
      persisted = await repository.upsertMany(<TModel>[
        _self(),
      ], returning: returning);
    }

    final result = persisted.isNotEmpty ? persisted.first : _self();
    _syncFrom(result, def, resolver);
    return result;
  }

  /// Deletes the record. Soft-deletes when supported unless [force] is true.
  Future<void> delete({bool force = false}) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError(
        'Model ${def.modelName} must declare a primary key before deletion.',
      );
    }
    final key = _primaryKeyValue(def);
    if (key == null) {
      throw StateError(
        'Model ${def.modelName} is missing primary key ${pk.name}.',
      );
    }
    if (!force && def.usesSoftDeletes) {
      final column =
          def.softDeleteField?.columnName ?? def.metadata.softDeleteColumn;
      final timestamp = DateTime.now().toUtc();
      setAttribute(column, timestamp);
      final plan = MutationPlan.update(
        definition: def,
        rows: [
          MutationRow(values: {column: timestamp}, keys: {pk.columnName: key}),
        ],
        driverName: resolver.driver.metadata.name,
      );
      await resolver.runMutation(plan);
      return;
    }
    final plan = MutationPlan.delete(
      definition: def,
      rows: [
        MutationRow(values: const {}, keys: {pk.columnName: key}),
      ],
      driverName: resolver.driver.metadata.name,
    );
    await resolver.runMutation(plan);
  }

  /// Hard-deletes the record, bypassing soft-delete flows entirely.
  Future<void> forceDelete() => delete(force: true);

  /// Restores a soft-deleted record.
  Future<void> restore() async {
    final def = expectDefinition();
    if (!def.usesSoftDeletes) {
      throw StateError(
        '${def.modelName} does not support soft deletes. Enable softDeletes.',
      );
    }
    final resolver = _resolveResolverFor(def);
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError(
        'Model ${def.modelName} must declare a primary key before restore.',
      );
    }
    final key = _primaryKeyValue(def);
    if (key == null) {
      throw StateError(
        'Model ${def.modelName} is missing primary key ${pk.name}.',
      );
    }
    final column =
        def.softDeleteField?.columnName ?? def.metadata.softDeleteColumn;
    final plan = MutationPlan.update(
      definition: def,
      rows: [
        MutationRow(values: {column: null}, keys: {pk.columnName: key}),
      ],
      driverName: resolver.driver.metadata.name,
    );
    await resolver.runMutation(plan);
    setAttribute(column, null);
  }

  /// Reloads the latest row from the database, optionally including trashed.
  ///
  /// The [withRelations] parameter allows you to specify which relations
  /// should be eagerly loaded when refreshing the model.
  ///
  /// Example:
  /// ```dart
  /// await user.refresh(withRelations: ['posts', 'comments']);
  /// ```
  Future<TModel> refresh({
    bool withTrashed = false,
    Iterable<String>? withRelations,
  }) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError(
        'Model ${def.modelName} must declare a primary key to refresh.',
      );
    }
    final key = _primaryKeyValue(def);
    if (key == null) {
      throw StateError(
        'Model ${def.modelName} is missing primary key ${pk.name}.',
      );
    }
    var builder = _requireQueryContext(resolver).queryFromDefinition(def);
    if (withTrashed && def.usesSoftDeletes) {
      builder = builder.withTrashed();
    }
    // Eager load relations if specified
    if (withRelations != null) {
      for (final relation in withRelations) {
        builder = builder.withRelation(relation);
      }
    }
    final fresh = await builder.whereEquals(pk.name, key).firstOrFail(key: key);
    _syncFrom(fresh, def, resolver);
    // Sync relations from the fresh model if any were loaded
    if (withRelations != null && withRelations.isNotEmpty) {
      for (final relationName in withRelations) {
        if (fresh.relationLoaded(relationName)) {
          final value = fresh.loadedRelations[relationName];
          setRelation(relationName, value);
        }
      }
    }
    return _self();
  }

  TModel _self() => this as TModel;

  static bool _shouldRebindResolver(String? requested, String? metadata) {
    final normalizedMetadata = _normalizeConnectionNameOrNull(metadata);
    if (normalizedMetadata == null) {
      return false;
    }
    final normalizedRequested = _normalizeConnectionNameOrNull(requested);
    if (normalizedRequested == null) {
      final fallback = _normalizeConnectionNameOrNull(_defaultConnectionName);
      return fallback != normalizedMetadata;
    }
    return normalizedRequested != normalizedMetadata;
  }

  static QueryContext _requireQueryContext(ConnectionResolver resolver) {
    if (resolver is QueryContext) {
      return resolver;
    }
    if (resolver is OrmConnection) {
      return resolver.context;
    }
    throw StateError(
      'Model helpers require a QueryContext or OrmConnection. '
      'Call Model.bindConnectionResolver or register '
      'connections on ConnectionManager.',
    );
  }

  static ConnectionResolver _resolveBoundResolver(String? preferred) {
    final name = _effectiveConnectionName(preferred);
    final builder = _resolverFactory;
    if (builder != null) {
      return builder(name);
    }
    final manager = _connectionManager ?? ConnectionManager.defaultManager;
    if (!manager.isRegistered(name)) {
      throw StateError(
        'No ORM connection named $name registered. Register it on '
        'ConnectionManager or supply a custom resolver via '
        'Model.bindConnectionResolver(...) before using the helpers.',
      );
    }
    final connection = manager.connection(name, role: _defaultConnectionRole);
    return connection.context;
  }

  static String _effectiveConnectionName(String? value) {
    final normalized = _normalizeConnectionNameOrNull(value);
    if (normalized != null) {
      return normalized;
    }
    final fallback = _normalizeConnectionNameOrNull(_defaultConnectionName);
    if (fallback != null) {
      return fallback;
    }
    throw StateError(
      'No default ORM connection configured. Call '
      'Model.bindConnectionResolver(...) or supply a connection name.',
    );
  }

  static String? _normalizeConnectionNameOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  ConnectionResolver _resolveResolverFor(ModelDefinition<TModel> definition) {
    final resolver = connectionResolver;
    if (resolver != null) {
      return resolver;
    }
    return _resolveBoundResolver(definition.metadata.connection);
  }

  Repository<TModel> _repositoryFor(
    ModelDefinition<TModel> definition,
    ConnectionResolver resolver,
  ) => Repository<TModel>(
    definition: definition,
    driverName: resolver.driver.metadata.name,
    codecs: resolver.codecRegistry,
    runMutation: resolver.runMutation,
    describeMutation: resolver.describeMutation,
    attachRuntimeMetadata: (model) {
      if (model is ModelConnection) {
        model.attachConnectionResolver(resolver);
      }
    },
  );

  Object? _primaryKeyValue(ModelDefinition<TModel> definition) {
    final field = definition.primaryKeyField;
    if (field == null) {
      return null;
    }
    final keyed = getAttribute<Object?>(field.columnName);
    if (keyed != null) {
      return keyed;
    }
    final codecs =
        connectionResolver?.codecRegistry ?? ValueCodecRegistry.standard();
    final values = definition.toMap(_self(), registry: codecs);
    return values[field.columnName];
  }

  void _syncFrom(
    TModel source,
    ModelDefinition<TModel> definition,
    ConnectionResolver resolver,
  ) {
    attachConnectionResolver(resolver);
    _attachDefinition(definition);
    final values = Map<String, Object?>.from(source.attributes);
    replaceAttributes(values);
    _exists = true;
  }

  void _attachDefinition(ModelDefinition<TModel> definition) {
    attachModelDefinition(definition);
    if (definition.usesSoftDeletes) {
      attachSoftDeleteColumn(definition.metadata.softDeleteColumn);
    }
  }

  // =========================================================================
  // Lazy Loading Methods
  // =========================================================================

  /// Lazily loads a relation on this model instance.
  ///
  /// Similar to Laravel's `$model->load('relation')`.
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().first();
  /// await post.load('author'); // Lazy load author
  /// print(post.author?.name);
  /// ```
  ///
  /// With constraint:
  /// ```dart
  /// await post.load('comments', (q) => q.where('approved', true));
  /// ```
  ///
  /// Throws [LazyLoadingViolationException] if [ModelRelations.preventsLazyLoading] is true.
  Future<TModel> load(
    String relation, [
    PredicateCallback<dynamic>? constraint,
  ]) async {
    if (ModelRelations.preventsLazyLoading) {
      throw LazyLoadingViolationException(runtimeType, relation);
    }

    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final context = _requireQueryContext(resolver);

    // Find the relation definition
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relation,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError('Relation "$relation" not found on ${def.modelName}');
    }

    // Convert constraint callback to QueryPredicate
    QueryPredicate? predicate;
    if (constraint != null) {
      final target = context.registry.expectByName(relationDef.targetModel);
      final builder = PredicateBuilder<dynamic>(target);
      constraint(builder);
      predicate = builder.build();
    }

    // Create a synthetic QueryRow from current model
    final row = QueryRow<TModel>(
      model: _self(),
      row: def.toMap(_self(), registry: context.codecRegistry),
    );

    // Load the relation using RelationLoader
    final loader = RelationLoader(context);
    final relationLoad = RelationLoad(
      relation: relationDef,
      predicate: predicate,
    );

    await loader.attach(def, [row], [relationLoad]);

    // The relation should now be in row.relations and synced to model cache
    return _self();
  }

  /// Lazily loads multiple relations that haven't been loaded yet.
  ///
  /// Similar to Laravel's `$model->loadMissing(['relation1', 'relation2'])`.
  ///
  /// Only loads relations that aren't already loaded.
  ///
  /// Example:
  /// ```dart
  /// await post.loadMissing(['author', 'tags', 'comments']);
  /// ```
  Future<TModel> loadMissing(Iterable<String> relations) async {
    for (final relation in relations) {
      if (!relationLoaded(relation)) {
        await load(relation);
      }
    }
    return _self();
  }

  /// Lazily loads multiple relations with optional constraints.
  ///
  /// Similar to Laravel's `$model->load(['relation1' => callback, ...])`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadMany({
  ///   'author': null,
  ///   'comments': (q) => q.where('approved', true),
  ///   'tags': (q) => q.orderBy('name'),
  /// });
  /// ```
  Future<TModel> loadMany(
    Map<String, PredicateCallback<dynamic>?> relations,
  ) async {
    for (final entry in relations.entries) {
      await load(entry.key, entry.value);
    }
    return _self();
  }

  /// Lazily loads the count of a relation.
  ///
  /// Stores the count as an attribute with the suffix `_count`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadCount('comments');
  /// print(post.getAttribute<int>('comments_count')); // e.g., 5
  /// ```
  ///
  /// With custom alias:
  /// ```dart
  /// await post.loadCount('comments', alias: 'total_comments');
  /// print(post.getAttribute<int>('total_comments'));
  /// ```
  Future<TModel> loadCount(
    String relation, {
    String? alias,
    PredicateCallback<dynamic>? constraint,
  }) async {
    if (ModelRelations.preventsLazyLoading) {
      throw LazyLoadingViolationException(runtimeType, relation);
    }

    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final context = _requireQueryContext(resolver);

    // Find the relation definition
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relation,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError('Relation "$relation" not found on ${def.modelName}');
    }

    final countAlias = alias ?? '${relation}_count';

    // Build a query for this model with withCount
    final query = context.queryFromDefinition(def);

    // Get the primary key value
    final pkField = def.primaryKeyField;
    if (pkField == null) {
      throw StateError('Cannot load count on model without primary key');
    }

    final pkValue = getAttribute(pkField.columnName);
    if (pkValue == null) {
      throw StateError('Cannot load count on model without primary key value');
    }

    // Query for this specific model with count
    query.where(pkField.columnName, pkValue);
    query.withCount(relation, alias: countAlias, constraint: constraint);

    final rows = await query.get();
    if (rows.isNotEmpty) {
      final result = rows.first;
      final count = result.getAttribute<int>(countAlias) ?? 0;
      setAttribute(countAlias, count);
    }

    return _self();
  }

  /// Lazily loads the existence of a relation.
  ///
  /// Stores the boolean result as an attribute with the suffix `_exists`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadExists('comments');
  /// if (post.getAttribute<bool>('comments_exists') == true) {
  ///   print('Post has comments');
  /// }
  /// ```
  Future<TModel> loadExists(
    String relation, {
    String? alias,
    PredicateCallback<dynamic>? constraint,
  }) async {
    if (ModelRelations.preventsLazyLoading) {
      throw LazyLoadingViolationException(runtimeType, relation);
    }

    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final context = _requireQueryContext(resolver);

    // Find the relation definition
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relation,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError('Relation "$relation" not found on ${def.modelName}');
    }

    final existsAlias = alias ?? '${relation}_exists';

    // Build a query for this model with withExists
    final query = context.queryFromDefinition(def);

    // Get the primary key value
    final pkField = def.primaryKeyField;
    if (pkField == null) {
      throw StateError('Cannot load exists on model without primary key');
    }

    final pkValue = getAttribute(pkField.columnName);
    if (pkValue == null) {
      throw StateError('Cannot load exists on model without primary key value');
    }

    // Query for this specific model with exists
    query.where(pkField.columnName, pkValue);
    query.withExists(relation, alias: existsAlias, constraint: constraint);

    final rows = await query.get();
    if (rows.isNotEmpty) {
      final result = rows.first;
      final exists = result.getAttribute<bool>(existsAlias) ?? false;
      setAttribute(existsAlias, exists);
    }

    return _self();
  }
}

extension ModelRegistryX on ModelRegistry {
  /// Fluent helper for registering definitions tied to [Model] subclasses.
  ModelRegistry registerModel<TModel extends Model<TModel>>(
    ModelDefinition<TModel> definition,
  ) {
    register(definition);
    return this;
  }
}
