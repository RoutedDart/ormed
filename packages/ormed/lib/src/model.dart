library;

import 'dart:async';
import 'dart:convert';

import 'package:ormed/src/annotations.dart';

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
import 'query/relation_resolver.dart';
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
  static Query<TModel> query<TModel>({String? connection}) {
    // Try to resolve and get definition
    final initialResolver = _resolveBoundResolverFlexible<TModel>(connection);
    final definition = initialResolver.registry.expect<TModel>();

    // Determine the effective connection: explicit param > model's configured connection
    final effectiveConnection = connection ?? definition.metadata.connection;

    // If we need a different connection than what we initially resolved, re-resolve
    if (_shouldRebindResolver(connection, effectiveConnection)) {
      final resolver = _resolveBoundResolver(effectiveConnection);
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
  static Future<List<TModel>> all<TModel>({String? connection}) =>
      query<TModel>(connection: connection).get();

  /// Creates and immediately persists a new model from attributes map.
  /// Note: This is a placeholder - actual implementation requires codec access.
  /// Use the generated static helper on your model class instead.
  static Future<TModel> create<TModel extends Model<TModel>>(
    Map<String, dynamic> attributes, {
    String? connection,
  }) async {
    throw UnimplementedError(
      'Model.create() requires code generation. Use YourModel.create() instead.',
    );
  }

  /// Inserts multiple records without returning model instances.
  /// Note: This is a placeholder - actual implementation requires codec access.
  /// Use the generated static helper on your model class instead.
  static Future<void> insert<TModel>(
    List<Map<String, dynamic>> records, {
    String? connection,
  }) async {
    throw UnimplementedError(
      'Model.insert() requires code generation. Use YourModel.insert() instead.',
    );
  }

  /// Starts a query with a where clause.
  static Query<TModel> where<TModel>(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => query<TModel>(connection: connection).where(column, operator, value);

  /// Starts a query with a whereIn clause.
  static Query<TModel> whereIn<TModel>(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => query<TModel>(connection: connection).whereIn(column, values);

  /// Starts a query with an orderBy clause.
  static Query<TModel> orderBy<TModel>(
    String column, {
    String direction = 'asc',
    String? connection,
  }) => query<TModel>(
    connection: connection,
  ).orderBy(column, descending: direction.toLowerCase() == 'desc');

  /// Starts a query with a limit clause.
  static Query<TModel> limit<TModel>(int count, {String? connection}) =>
      query<TModel>(connection: connection).limit(count);

  /// Find a model by its primary key, returns null if not found.
  static Future<TModel?> find<TModel>(Object id, {String? connection}) =>
      query<TModel>(connection: connection).find(id);

  /// Find a model by its primary key, throws if not found.
  static Future<TModel> findOrFail<TModel>(
    Object id, {
    String? connection,
  }) async {
    final result = await find<TModel>(id, connection: connection);
    if (result == null) {
      throw StateError('Model not found with id: $id');
    }
    return result;
  }

  /// Find multiple models by their primary keys.
  static Future<List<TModel>> findMany<TModel>(
    List<Object> ids, {
    String? connection,
  }) => query<TModel>(connection: connection).findMany(ids);

  /// Get the first model matching the query, or null.
  static Future<TModel?> first<TModel>({String? connection}) =>
      query<TModel>(connection: connection).first();

  /// Get the first model matching the query, or throw.
  static Future<TModel> firstOrFail<TModel>({String? connection}) async {
    final result = await first<TModel>(connection: connection);
    if (result == null) {
      throw StateError('No model found');
    }
    return result;
  }

  /// Count the number of models.
  static Future<int> count<TModel>({String? connection}) =>
      query<TModel>(connection: connection).count();

  /// Check if any models exist.
  static Future<bool> exists<TModel>({String? connection}) async =>
      await count<TModel>(connection: connection) > 0;

  /// Check if no models exist.
  static Future<bool> doesntExist<TModel>({String? connection}) async =>
      !await exists<TModel>(connection: connection);

  /// Delete all models matching a condition (dangerous!).
  static Future<int> destroy<TModel extends Model<TModel>>(
    List<Object> ids, {
    String? connection,
  }) async {
    final models = await findMany<TModel>(ids, connection: connection);
    for (final model in models) {
      await model.delete();
    }
    return models.length;
  }

  /// Get a single model and throw if zero or more than one result is found.
  static Future<TModel> sole<TModel>({String? connection}) =>
      query<TModel>(connection: connection).sole();

  /// Get first model or create new (but don't persist yet).
  ///
  /// Note: This is a placeholder - actual implementation requires codec access.
  /// Use the generated static helper on your model class instead.
  static Future<TModel> firstOrNew<TModel extends Model<TModel>>(
    Map<String, dynamic> attributes, {
    Map<String, dynamic> values = const {},
    String? connection,
  }) async {
    throw UnimplementedError(
      'Model.firstOrNew() requires code generation. Use YourModel.firstOrNew() instead.',
    );
  }

  /// Get first model or create and persist it.
  ///
  /// Note: This is a placeholder - actual implementation requires codec access.
  /// Use the generated static helper on your model class instead.
  static Future<TModel> firstOrCreate<TModel extends Model<TModel>>(
    Map<String, dynamic> attributes, {
    Map<String, dynamic> values = const {},
    String? connection,
  }) async {
    throw UnimplementedError(
      'Model.firstOrCreate() requires code generation. Use YourModel.firstOrCreate() instead.',
    );
  }

  /// Update existing model or create new one.
  ///
  /// Note: This is a placeholder - actual implementation requires codec access.
  /// Use the generated static helper on your model class instead.
  static Future<TModel> updateOrCreate<TModel extends Model<TModel>>(
    Map<String, dynamic> attributes,
    Map<String, dynamic> values, {
    String? connection,
  }) async {
    throw UnimplementedError(
      'Model.updateOrCreate() requires code generation. Use YourModel.updateOrCreate() instead.',
    );
  }

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

  /// Returns a fresh instance of this model from the database.
  ///
  /// Unlike [refresh], this method returns a new model instance without
  /// modifying the current one. Useful when you need the latest database
  /// state but want to preserve the current instance.
  ///
  /// The [withRelations] parameter allows you to specify which relations
  /// should be eagerly loaded on the fresh instance.
  ///
  /// Example:
  /// ```dart
  /// final freshUser = await user.fresh(withRelations: ['posts']);
  /// print(user.name); // Still has old value
  /// print(freshUser.name); // Has latest value from database
  /// ```
  Future<TModel> fresh({
    bool withTrashed = false,
    Iterable<String>? withRelations,
  }) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError(
        'Model ${def.modelName} must declare a primary key to get fresh.',
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
    return await builder.whereEquals(pk.name, key).firstOrFail(key: key);
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

  /// Flexible resolver that tries to find a connection with the model definition
  static ConnectionResolver _resolveBoundResolverFlexible<TModel>(
    String? preferred,
  ) {
    final manager = _connectionManager ?? ConnectionManager.defaultManager;
    final builder = _resolverFactory;

    // If custom resolver is set, use it
    if (builder != null) {
      final name = _effectiveConnectionName(preferred);
      return builder(name);
    }

    // Try preferred/default connection first
    final preferredName = _effectiveConnectionName(preferred);
    if (manager.isRegistered(preferredName)) {
      final connection = manager.connection(
        preferredName,
        role: _defaultConnectionRole,
      );
      if (connection.context.registry.contains<TModel>()) {
        return connection.context;
      }
    }

    // Search all registered connections for one that has this model
    for (final name in manager.registeredConnectionNames) {
      final connection = manager.connection(name, role: _defaultConnectionRole);
      if (connection.context.registry.contains<TModel>()) {
        return connection.context;
      }
    }

    throw StateError(
      'No ORM connection found with definition for $TModel. '
      'Register a DataSource containing this model on ConnectionManager.',
    );
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

  /// Lazily loads a relation on this model instance.
  ///
  /// Similar to Laravel's `$model->load('relation')`.
  ///
  /// Supports nested relation paths using dot notation:
  /// ```dart
  /// await post.load('comments.author'); // Load comments, then their authors
  /// ```
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().first();
  /// await post.load('author'); // Lazy load author
  /// print(post.author?.name);
  /// ```
  ///
  /// With constraint (applies to the final relation in nested paths):
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

    // Check if this is a nested relation path
    if (relation.contains('.')) {
      await _loadNestedRelation(relation, constraint, def, context);
      return _self();
    }

    // Find the relation definition
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relation,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError('Relation "$relation" not found on ${def.modelName}');
    }

    // Convert constraint callback to QueryPredicate using RelationResolver
    final relationResolver = RelationResolver(context);
    final predicate = relationResolver.predicateFor(relationDef, constraint);

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

  /// Internal helper for loading nested relation paths.
  ///
  /// Splits the path and recursively loads each segment.
  Future<void> _loadNestedRelation(
    String path,
    PredicateCallback<dynamic>? constraint,
    ModelDefinition<TModel> def,
    QueryContext context,
  ) async {
    final parts = path.split('.');
    final firstRelation = parts.first;
    final remainingPath = parts.skip(1).join('.');

    // Load the first relation on this model (no constraint for intermediate relations)
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == firstRelation,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$firstRelation" not found on ${def.modelName}',
      );
    }

    // Load the first relation if not already loaded
    if (!relationLoaded(firstRelation)) {
      final row = QueryRow<TModel>(
        model: _self(),
        row: def.toMap(_self(), registry: context.codecRegistry),
      );

      final loader = RelationLoader(context);
      final relationLoad = RelationLoad(relation: relationDef);
      await loader.attach(def, [row], [relationLoad]);
    }

    // If there's more path to load, recurse into the loaded relations
    if (remainingPath.isNotEmpty) {
      final loadedValue = getRelation<dynamic>(firstRelation);

      if (loadedValue == null) {
        return; // Nothing to recurse into
      }

      // Determine the constraint to pass (only for the final segment)
      final isLastSegment = !remainingPath.contains('.');
      final nextConstraint = isLastSegment ? constraint : null;

      if (loadedValue is List) {
        // Load nested relations on each item in the list
        for (final item in loadedValue) {
          if (item is Model) {
            await item.load(remainingPath, nextConstraint);
          }
        }
      } else if (loadedValue is Model) {
        // Load nested relation on the single model
        await loadedValue.load(remainingPath, nextConstraint);
      }
    }
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

  /// Lazily loads a relation on multiple models efficiently.
  ///
  /// This static method batches relation loading across multiple models,
  /// executing a single query per resolver group instead of N+1 queries.
  ///
  /// Similar to Laravel's collection-based `load()`.
  ///
  /// Example:
  /// ```dart
  /// final posts = await Post.query().get();
  /// await Model.loadRelations(posts, 'author');
  /// // All posts now have their authors loaded with a single query
  /// ```
  ///
  /// With constraint:
  /// ```dart
  /// await Model.loadRelations(posts, 'comments', (q) => q.where('approved', true));
  /// ```
  ///
  /// Throws [LazyLoadingViolationException] if [ModelRelations.preventsLazyLoading] is true.
  static Future<void> loadRelations<T extends Model<T>>(
    Iterable<T> models,
    String relation, [
    PredicateCallback<dynamic>? constraint,
  ]) async {
    if (ModelRelations.preventsLazyLoading) {
      if (models.isNotEmpty) {
        throw LazyLoadingViolationException(models.first.runtimeType, relation);
      }
      return;
    }

    final modelList = models.toList();
    if (modelList.isEmpty) return;

    // Group models by their connection resolver
    final groups = <ConnectionResolver, List<T>>{};
    for (final model in modelList) {
      final def = model.expectDefinition();
      final resolver = model._resolveResolverFor(def);
      groups.putIfAbsent(resolver, () => <T>[]).add(model);
    }

    // Load relations for each group
    for (final entry in groups.entries) {
      final resolver = entry.key;
      final groupModels = entry.value;

      if (groupModels.isEmpty) continue;

      final context = _requireQueryContext(resolver);
      final def = groupModels.first.expectDefinition();

      // Check for nested path
      if (relation.contains('.')) {
        // For nested paths, load on each model individually
        // (batch loading nested paths is complex and deferred)
        for (final model in groupModels) {
          await model.load(relation, constraint);
        }
        continue;
      }

      // Find the relation definition
      final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
        (r) => r?.name == relation,
        orElse: () => null,
      );

      if (relationDef == null) {
        throw ArgumentError(
          'Relation "$relation" not found on ${def.modelName}',
        );
      }

      // Convert constraint callback to QueryPredicate
      final relationResolver = RelationResolver(context);
      final predicate = relationResolver.predicateFor(relationDef, constraint);

      // Create synthetic QueryRows for all models in the group
      final rows = groupModels.map((model) {
        return QueryRow<T>(
          model: model,
          row: def.toMap(model, registry: context.codecRegistry),
        );
      }).toList();

      // Batch load the relation using RelationLoader
      final loader = RelationLoader(context);
      final relationLoad = RelationLoad(
        relation: relationDef,
        predicate: predicate,
      );

      await loader.attach(def, rows, [relationLoad]);
    }
  }

  /// Lazily loads multiple relations on multiple models efficiently.
  ///
  /// This is a convenience wrapper around [loadRelations] for loading
  /// multiple relations in sequence.
  ///
  /// Example:
  /// ```dart
  /// final posts = await Post.query().get();
  /// await Model.loadRelationsMany(posts, ['author', 'tags', 'comments']);
  /// ```
  static Future<void> loadRelationsMany<T extends Model<T>>(
    Iterable<T> models,
    Iterable<String> relations,
  ) async {
    for (final relation in relations) {
      await loadRelations(models, relation);
    }
  }

  /// Lazily loads relations on multiple models if not already loaded.
  ///
  /// Only loads relations that aren't already loaded on each model.
  ///
  /// Example:
  /// ```dart
  /// final posts = await Post.query().get();
  /// await Model.loadRelationsMissing(posts, ['author', 'tags']);
  /// ```
  static Future<void> loadRelationsMissing<T extends Model<T>>(
    Iterable<T> models,
    Iterable<String> relations,
  ) async {
    for (final relation in relations) {
      // Filter to models that don't have this relation loaded
      final needsLoading = models
          .where((m) => !m.relationLoaded(relation))
          .toList();
      if (needsLoading.isNotEmpty) {
        await loadRelations(needsLoading, relation);
      }
    }
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
    final queryWithAggregate = query
        .where(pkField.columnName, pkValue)
        .withExists(relation, alias: existsAlias, constraint: constraint);

    final rows = await queryWithAggregate.get();
    if (rows.isNotEmpty) {
      final result = rows.first;
      // SQL returns 1/0 for EXISTS, convert to boolean
      final value = result.getAttribute(existsAlias);
      final exists = value == true || value == 1;
      setAttribute(existsAlias, exists);
    }

    return _self();
  }

  /// Lazily loads the sum of a column in a relation.
  ///
  /// Stores the sum result as an attribute with the suffix `_sum_{column}`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadSum('comments', 'likes');
  /// final totalLikes = post.getAttribute<num>('comments_sum_likes') ?? 0;
  /// ```
  Future<TModel> loadSum(
    String relation,
    String column, {
    String? alias,
    PredicateCallback<dynamic>? constraint,
  }) async {
    return _loadAggregate(
      'sum',
      relation,
      column,
      alias: alias,
      constraint: constraint,
    );
  }

  /// Lazily loads the average of a column in a relation.
  ///
  /// Stores the average result as an attribute with the suffix `_avg_{column}`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadAvg('comments', 'rating');
  /// final avgRating = post.getAttribute<num>('comments_avg_rating') ?? 0;
  /// ```
  Future<TModel> loadAvg(
    String relation,
    String column, {
    String? alias,
    PredicateCallback<dynamic>? constraint,
  }) async {
    return _loadAggregate(
      'avg',
      relation,
      column,
      alias: alias,
      constraint: constraint,
    );
  }

  /// Lazily loads the maximum value of a column in a relation.
  ///
  /// Stores the max result as an attribute with the suffix `_max_{column}`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadMax('comments', 'created_at');
  /// final latestComment = post.getAttribute('comments_max_created_at');
  /// ```
  Future<TModel> loadMax(
    String relation,
    String column, {
    String? alias,
    PredicateCallback<dynamic>? constraint,
  }) async {
    return _loadAggregate(
      'max',
      relation,
      column,
      alias: alias,
      constraint: constraint,
    );
  }

  /// Lazily loads the minimum value of a column in a relation.
  ///
  /// Stores the min result as an attribute with the suffix `_min_{column}`.
  ///
  /// Example:
  /// ```dart
  /// await post.loadMin('comments', 'created_at');
  /// final earliestComment = post.getAttribute('comments_min_created_at');
  /// ```
  Future<TModel> loadMin(
    String relation,
    String column, {
    String? alias,
    PredicateCallback<dynamic>? constraint,
  }) async {
    return _loadAggregate(
      'min',
      relation,
      column,
      alias: alias,
      constraint: constraint,
    );
  }

  /// Internal helper to load aggregates on relations.
  Future<TModel> _loadAggregate(
    String aggregateType,
    String relation,
    String column, {
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

    final aggregateAlias =
        alias ?? '${relation}_${aggregateType}_${column.replaceAll('.', '_')}';

    // Build a query for this model with the aggregate
    final query = context.queryFromDefinition(def);

    // Get the primary key value
    final pkField = def.primaryKeyField;
    if (pkField == null) {
      throw StateError(
        'Cannot load $aggregateType on model without primary key',
      );
    }

    final pkValue = getAttribute(pkField.columnName);
    if (pkValue == null) {
      throw StateError(
        'Cannot load $aggregateType on model without primary key value',
      );
    }

    // Query for this specific model with aggregate
    var queryWithFilter = query.where(pkField.columnName, pkValue);

    // Call the appropriate withAggregate method
    final queryWithAggregate = switch (aggregateType) {
      'sum' => queryWithFilter.withSum(
        relation,
        column,
        alias: aggregateAlias,
        constraint: constraint,
      ),
      'avg' => queryWithFilter.withAvg(
        relation,
        column,
        alias: aggregateAlias,
        constraint: constraint,
      ),
      'max' => queryWithFilter.withMax(
        relation,
        column,
        alias: aggregateAlias,
        constraint: constraint,
      ),
      'min' => queryWithFilter.withMin(
        relation,
        column,
        alias: aggregateAlias,
        constraint: constraint,
      ),
      _ => throw ArgumentError('Unsupported aggregate type: $aggregateType'),
    };

    final rows = await queryWithAggregate.get();
    if (rows.isNotEmpty) {
      final result = rows.first;
      final value = result.getAttribute(aggregateAlias);
      setAttribute(aggregateAlias, value);
    }

    return _self();
  }

  /// Associates a belongsTo parent model and updates the foreign key.
  ///
  /// This is a convenient helper that:
  /// 1. Updates the foreign key field to match the parent's primary key
  /// 2. Caches the parent model in the relation cache
  /// 3. Marks the relation as loaded
  ///
  /// Example:
  /// ```dart
  /// final post = Post(id: 1, title: 'Hello');
  /// final author = Author(id: 5, name: 'Alice');
  /// await post.associate('author', author);
  /// // post.authorId is now 5
  /// // post.author is now the Alice instance
  /// ```
  Future<TModel> associate(String relationName, Model parent) async {
    final def = expectDefinition();
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.belongsTo) {
      throw ArgumentError(
        'associate() can only be used with belongsTo relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    // Get the parent's primary key value
    final resolver = _resolveResolverFor(def);
    final context = _requireQueryContext(resolver);
    final parentDef = context.registry.expectByName(relationDef.targetModel);
    final parentPk = parentDef.primaryKeyField;
    if (parentPk == null) {
      throw StateError(
        'Parent model ${parentDef.modelName} must have a primary key',
      );
    }

    final parentPkValue = parentDef.toMap(
      parent as dynamic,
      registry: context.codecRegistry,
    )[parentPk.columnName];

    if (parentPkValue == null) {
      throw StateError(
        'Parent model ${parentDef.modelName} primary key value is null',
      );
    }

    // Find the foreign key field in this model
    final foreignKeyName = relationDef.foreignKey;
    final field = def.fields.firstWhere(
      (f) => f.columnName == foreignKeyName || f.name == foreignKeyName,
    );

    // Update the foreign key attribute
    setAttribute(field.columnName, parentPkValue);

    // Cache the parent in relations
    setRelation(relationName, parent);

    return _self();
  }

  /// Dissociates a belongsTo parent model and clears the foreign key.
  ///
  /// This is a convenient helper that:
  /// 1. Sets the foreign key field to null
  /// 2. Removes the parent from the relation cache
  /// 3. Marks the relation as not loaded
  ///
  /// Example:
  /// ```dart
  /// final post = Post(id: 1, authorId: 5, title: 'Hello');
  /// await post.dissociate('author');
  /// // post.authorId is now null
  /// // post.author is now null
  /// ```
  Future<TModel> dissociate(String relationName) async {
    final def = expectDefinition();
    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.belongsTo) {
      throw ArgumentError(
        'dissociate() can only be used with belongsTo relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    // Find the foreign key field and nullify it
    final foreignKeyName = relationDef.foreignKey;
    final field = def.fields.firstWhere(
      (f) => f.columnName == foreignKeyName || f.name == foreignKeyName,
    );

    setAttribute(field.columnName, null);

    // Remove from relation cache
    unsetRelation(relationName);

    return _self();
  }

  /// Attaches related models in a manyToMany relationship.
  ///
  /// Inserts new pivot table records to establish the many-to-many relationship.
  /// Optionally accepts pivot data for additional columns on the pivot table.
  ///
  /// After attaching, the relation is reloaded to sync the cache.
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// await post.attach('tags', [1, 2, 3]);
  /// // Pivot records created for tag IDs 1, 2, 3
  ///
  /// // With pivot data:
  /// await post.attach('tags', [4], pivotData: {'order': 1});
  /// ```
  Future<TModel> attach(
    String relationName,
    List<dynamic> ids, {
    Map<String, dynamic>? pivotData,
  }) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);

    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.manyToMany) {
      throw ArgumentError(
        'attach() can only be used with manyToMany relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    if (ids.isEmpty) {
      return _self();
    }

    // Get this model's primary key value
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError('Model ${def.modelName} must have a primary key');
    }

    final pkValue = _primaryKeyValue(def);
    if (pkValue == null) {
      throw StateError('Model ${def.modelName} primary key value is null');
    }

    // Build pivot table rows
    final pivotTable = relationDef.through;
    if (pivotTable == null) {
      throw StateError(
        'Relation "$relationName" is missing pivot table name (through)',
      );
    }

    final pivotForeignKey = relationDef.pivotForeignKey!;
    final pivotRelatedKey = relationDef.pivotRelatedKey!;

    // Get the related model definition to determine column types
    final relatedModelName = relationDef.targetModel;
    final relatedDef = resolver.registry.expectByName(relatedModelName);

    final relatedPk = relatedDef.primaryKeyField;
    if (relatedPk == null) {
      throw StateError(
        'Related model $relatedModelName must have a primary key',
      );
    }

    final rows = ids.map((id) {
      final row = <String, dynamic>{
        pivotForeignKey: pkValue,
        pivotRelatedKey: id,
      };
      if (pivotData != null) {
        row.addAll(pivotData);
      }
      return row;
    }).toList();

    // Build pivot table definition with proper column types
    final pivotDef = _createPivotDefinition(pivotTable, def.schema, {
      pivotForeignKey: pk,
      pivotRelatedKey: relatedPk,
      ...?pivotData?.map((key, _) => MapEntry(key, null)),
    });

    final plan = MutationPlan.insert(definition: pivotDef, rows: rows);

    await resolver.runMutation(plan);

    // Reload the relation to sync cache
    await load(relationName);

    return _self();
  }

  /// Detaches related models in a manyToMany relationship.
  ///
  /// Deletes pivot table records. If no IDs are provided, detaches all.
  ///
  /// After detaching, the relation is reloaded to sync the cache.
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// await post.detach('tags', [1, 2]); // Detach specific tags
  /// await post.detach('tags'); // Detach all tags
  /// ```
  Future<TModel> detach(String relationName, [List<dynamic>? ids]) async {
    final def = expectDefinition();
    final resolver = _resolveResolverFor(def);

    final relationDef = def.relations.cast<RelationDefinition?>().firstWhere(
      (r) => r?.name == relationName,
      orElse: () => null,
    );

    if (relationDef == null) {
      throw ArgumentError(
        'Relation "$relationName" not found on ${def.modelName}',
      );
    }

    if (relationDef.kind != RelationKind.manyToMany) {
      throw ArgumentError(
        'detach() can only be used with manyToMany relations. '
        'Relation "$relationName" is ${relationDef.kind}',
      );
    }

    // Get this model's primary key value
    final pk = def.primaryKeyField;
    if (pk == null) {
      throw StateError('Model ${def.modelName} must have a primary key');
    }

    final pkValue = _primaryKeyValue(def);
    if (pkValue == null) {
      throw StateError('Model ${def.modelName} primary key value is null');
    }

    final pivotTable = relationDef.through;
    if (pivotTable == null) {
      throw StateError(
        'Relation "$relationName" is missing pivot table name (through)',
      );
    }

    final pivotForeignKey = relationDef.pivotForeignKey!;
    final pivotRelatedKey = relationDef.pivotRelatedKey!;

    // Get the related model definition to determine column types
    final relatedModelName = relationDef.targetModel;
    final relatedDef = resolver.registry.expectByName(relatedModelName);

    final relatedPk = relatedDef.primaryKeyField;
    if (relatedPk == null) {
      throw StateError(
        'Related model $relatedModelName must have a primary key',
      );
    }

    // Build delete keys
    final List<Map<String, Object?>> deleteKeys;

    if (ids != null && ids.isNotEmpty) {
      // Detach specific IDs
      deleteKeys = ids
          .map((id) => {pivotForeignKey: pkValue, pivotRelatedKey: id})
          .toList();
    } else {
      // Detach all - query for existing pivot records first
      final pivotDef = _createPivotDefinition(pivotTable, def.schema, {
        pivotForeignKey: pk,
        pivotRelatedKey: relatedPk,
      });

      final selectPlan = QueryPlan(
        definition: pivotDef,
        filters: [
          FilterClause(
            field: pivotForeignKey,
            operator: FilterOperator.equals,
            value: pkValue,
          ),
        ],
      );

      final results = await resolver.runSelect(selectPlan);
      deleteKeys = results
          .map(
            (row) => {
              pivotForeignKey: row[pivotForeignKey],
              pivotRelatedKey: row[pivotRelatedKey],
            },
          )
          .toList();
    }

    if (deleteKeys.isNotEmpty) {
      final pivotDef = _createPivotDefinition(pivotTable, def.schema, {
        pivotForeignKey: pk,
        pivotRelatedKey: relatedPk,
      });

      final deleteRows = deleteKeys
          .map((keys) => MutationRow(values: const {}, keys: keys))
          .toList();

      final plan = MutationPlan.delete(definition: pivotDef, rows: deleteRows);

      await resolver.runMutation(plan);
    }

    // Reload the relation to sync cache
    await load(relationName);

    return _self();
  }

  /// Syncs a manyToMany relationship to match the given IDs exactly.
  ///
  /// This replaces all existing pivot records with new ones for the given IDs.
  /// Internally calls `detach()` (all) followed by `attach()`.
  ///
  /// Example:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// // Currently has tags: [1, 2, 3]
  /// await post.sync('tags', [2, 3, 4]);
  /// // Now has tags: [2, 3, 4]
  /// ```
  Future<TModel> sync(
    String relationName,
    List<dynamic> ids, {
    Map<String, dynamic>? pivotData,
  }) async {
    // First detach all
    await detach(relationName);

    // Then attach the new IDs
    if (ids.isNotEmpty) {
      await attach(relationName, ids, pivotData: pivotData);
    }

    return _self();
  }

  /// Creates a minimal ModelDefinition for a pivot table.
  ///
  /// Uses 'int' as the type for all columns since pivot keys are typically integers.
  /// The codec handles conversion appropriately.
  static ModelDefinition<Map<String, dynamic>> _createPivotDefinition(
    String tableName,
    String? schema,
    Map<String, FieldDefinition?> columnFields,
  ) {
    final fields = columnFields.entries.map((entry) {
      final colName = entry.key;
      final fieldDef = entry.value;

      // Use the field definition's types if available, otherwise default to dynamic
      return FieldDefinition(
        name: colName,
        columnName: colName,
        dartType: fieldDef?.dartType ?? 'dynamic',
        resolvedType: fieldDef?.resolvedType ?? 'dynamic',
        isPrimaryKey: false,
        isNullable: true,
      );
    }).toList();

    return ModelDefinition<Map<String, dynamic>>(
      modelName: tableName,
      tableName: tableName,
      schema: schema,
      fields: fields,
      relations: const [],
      codec: const _PivotTableCodec(),
    );
  }
}

/// Simple codec for pivot table operations (raw maps).
class _PivotTableCodec extends ModelCodec<Map<String, dynamic>> {
  const _PivotTableCodec();

  @override
  Map<String, Object?> encode(
    Map<String, dynamic> model,
    ValueCodecRegistry registry,
  ) => model;

  @override
  Map<String, dynamic> decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) => Map<String, dynamic>.from(data);
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
