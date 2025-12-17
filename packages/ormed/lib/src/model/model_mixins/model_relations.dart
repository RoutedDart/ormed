library;

/// Provides runtime relation caching and lazy loading support for model instances.
///
/// This mixin enables models to:
/// - Store and retrieve loaded relation data
/// - Track which relations have been loaded
/// - Support lazy loading APIs like `load()` and `loadMissing()`
/// - Integrate with eager loading to populate relation cache
///
/// Relation data is stored using [Expando] to avoid polluting model instances
/// with additional fields while maintaining instance-specific state.
mixin ModelRelations {
  static final Expando<Map<String, dynamic>> _relationValues =
      Expando<Map<String, dynamic>>('_relationValues');
  static final Expando<Set<String>> _loadedRelations = Expando<Set<String>>(
    '_loadedRelations',
  );

  /// Controls whether lazy loading is prevented globally.
  ///
  /// When set to `true`, attempting to lazy load a relation will throw
  /// a [LazyLoadingViolationException]. This is useful in production to
  /// catch N+1 query problems.
  ///
  /// Similar to Laravel's `Model::preventLazyLoading()`.
  static bool preventsLazyLoading = false;

  /// Sets a relation value and marks it as loaded.
  ///
  /// Example:
  /// ```dart
  /// post.setRelation('author', author);
  /// ```
  void setRelation(String name, dynamic value) {
    _ensureRelationMaps();
    _relationValues[this]![name] = value;
    _loadedRelations[this]!.add(name);
  }

  /// Retrieves a cached relation value typed as [T].
  ///
  /// Returns `null` if the relation hasn't been loaded or is explicitly null.
  ///
  /// Example:
  /// ```dart
  /// final author = post.getRelation<Author>('author');
  /// ```
  T? getRelation<T>(String name) {
    final relations = _relationValues[this];
    if (relations == null || !relations.containsKey(name)) {
      return null;
    }
    return relations[name] as T?;
  }

  /// Retrieves a list relation typed as [T].
  ///
  /// Returns an empty list if the relation hasn't been loaded.
  /// Returns the cached list if loaded (even if it's an empty list).
  ///
  /// Example:
  /// ```dart
  /// final posts = author.getRelationList<Post>('posts');
  /// ```
  List<T> getRelationList<T>(String name) {
    final relations = _relationValues[this];
    if (relations == null || !relations.containsKey(name)) {
      return const [];
    }
    final value = relations[name];
    if (value == null) {
      return const [];
    }
    if (value is List<T>) {
      return value;
    }
    if (value is Iterable<T>) {
      final list = List<T>.unmodifiable(value);
      relations[name] = list;
      return list;
    }
    if (value is Iterable) {
      final list = List<T>.unmodifiable(value.cast<T>());
      relations[name] = list;
      return list;
    }
    return const [];
  }

  /// Checks if a relation has been loaded.
  ///
  /// Returns `true` even if the loaded value is `null` or an empty list.
  ///
  /// Example:
  /// ```dart
  /// if (post.relationLoaded('author')) {
  ///   print('Author already loaded');
  /// }
  /// ```
  bool relationLoaded(String name) {
    final loaded = _loadedRelations[this];
    return loaded != null && loaded.contains(name);
  }

  /// Removes a relation from the cache and marks it as not loaded.
  ///
  /// Example:
  /// ```dart
  /// post.unsetRelation('author');
  /// ```
  void unsetRelation(String name) {
    _relationValues[this]?.remove(name);
    _loadedRelations[this]?.remove(name);
  }

  /// Bulk sets multiple relations at once.
  ///
  /// Example:
  /// ```dart
  /// post.setRelations({
  ///   'author': author,
  ///   'tags': [tag1, tag2],
  /// });
  /// ```
  void setRelations(Map<String, dynamic> relations) {
    for (final entry in relations.entries) {
      setRelation(entry.key, entry.value);
    }
  }

  /// Returns a snapshot of all currently loaded relations.
  ///
  /// The returned map is a copy; modifying it won't affect the cache.
  ///
  /// Example:
  /// ```dart
  /// final relations = post.loadedRelations;
  /// print('Loaded: ${relations.keys.join(', ')}');
  /// ```
  Map<String, dynamic> get loadedRelations {
    final relations = _relationValues[this];
    if (relations == null) return {};
    final loaded = _loadedRelations[this];
    if (loaded == null || loaded.isEmpty) return {};
    return Map.fromEntries(
      loaded.map((name) => MapEntry(name, relations[name])),
    );
  }

  /// Shorthand alias for [loadedRelations].
  ///
  /// Returns a snapshot of all currently loaded relations.
  ///
  /// Example:
  /// ```dart
  /// final allRelations = post.relations;
  /// for (final entry in allRelations.entries) {
  ///   print('${entry.key}: ${entry.value}');
  /// }
  /// ```
  Map<String, dynamic> get relations => loadedRelations;

  /// Syncs relations from a [QueryRow] into this model's cache.
  ///
  /// This is called internally after eager loading to make relations
  /// accessible directly on the model instance.
  ///
  /// Example (internal use):
  /// ```dart
  /// model.syncRelationsFromQueryRow(queryRow.relations);
  /// ```
  void syncRelationsFromQueryRow(Map<String, dynamic> rowRelations) {
    if (rowRelations.isEmpty) return;
    _ensureRelationMaps();
    for (final entry in rowRelations.entries) {
      _relationValues[this]![entry.key] = entry.value;
      _loadedRelations[this]!.add(entry.key);
    }
  }

  /// Returns names of all loaded relations.
  ///
  /// Example:
  /// ```dart
  /// final names = post.loadedRelationNames;
  /// print('Loaded relations: ${names.join(', ')}');
  /// ```
  Set<String> get loadedRelationNames {
    return _loadedRelations[this]?.toSet() ?? {};
  }

  /// Clears all cached relations.
  ///
  /// Useful when refreshing a model and wanting to reload all relations.
  ///
  /// Example:
  /// ```dart
  /// post.clearRelations();
  /// await post.load('author'); // Will fetch fresh
  /// ```
  void clearRelations() {
    _relationValues[this]?.clear();
    _loadedRelations[this]?.clear();
  }

  void _ensureRelationMaps() {
    _relationValues[this] ??= <String, dynamic>{};
    _loadedRelations[this] ??= <String>{};
  }
}

/// Exception thrown when attempting to lazy load a relation while
/// lazy loading is globally prevented.
///
/// See [ModelRelations.preventsLazyLoading].
class LazyLoadingViolationException implements Exception {
  LazyLoadingViolationException(this.modelType, this.relationName);

  final Type modelType;
  final String relationName;

  @override
  String toString() =>
      'LazyLoadingViolationException: '
      'Attempted to lazy load [$relationName] on [$modelType] '
      'but lazy loading is prevented. '
      'Use eager loading or enable lazy loading to proceed.';
}
