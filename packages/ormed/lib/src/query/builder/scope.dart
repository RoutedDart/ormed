part of '../query_builder.dart';

/// Extension providing scope and query customization methods.
extension ScopeExtension<T> on Query<T> {
  /// Removes a global scope by [identifier] from the query.
  ///
  /// This allows you to temporarily disable a global scope that would otherwise
  /// be applied to all queries of this model type.
  ///
  /// Example:
  /// ```dart
  /// // Get all users, including soft-deleted ones
  /// final allUsers = await context.query<User>()
  ///   .withoutGlobalScope(ScopeRegistry.softDeleteScopeIdentifier)
  ///   .get();
  /// ```
  Query<T> withoutGlobalScope(String identifier) {
    final updated = {..._ignoredGlobalScopes, identifier};
    return _copyWith(ignoredScopes: updated, globalScopesApplied: false);
  }

  /// Removes multiple global scopes or all global scopes from the query.
  ///
  /// If [identifiers] is `null`, all global scopes will be ignored.
  /// Otherwise, only the global scopes with the specified identifiers will be ignored.
  ///
  /// Example:
  /// ```dart
  /// // Get all users, ignoring all global scopes
  /// final allUsers = await context.query<User>()
  ///   .withoutGlobalScopes()
  ///   .get();
  ///
  /// // Ignore specific global scopes
  /// final users = await context.query<User>()
  ///   .withoutGlobalScopes(['scope1', 'scope2'])
  ///   .get();
  /// ```
  Query<T> withoutGlobalScopes([List<String>? identifiers]) {
    if (identifiers == null) {
      return _copyWith(ignoreAllGlobalScopes: true, globalScopesApplied: false);
    }
    final updated = {..._ignoredGlobalScopes, ...identifiers};
    return _copyWith(ignoredScopes: updated, globalScopesApplied: false);
  }

  /// Applies a named local scope to the query.
  ///
  /// Local scopes are reusable query constraints defined on the model.
  ///
  /// [name] is the name of the local scope.
  /// [args] are optional arguments to pass to the local scope.
  ///
  /// Example:
  /// ```dart
  /// // Assuming a local scope 'active' is defined on User model
  /// final activeUsers = await context.query<User>()
  ///   .scope('active')
  ///   .get();
  ///
  /// // With arguments
  /// final usersByRole = await context.query<User>()
  ///   .scope('byRole', ['admin'])
  ///   .get();
  /// ```
  Query<T> scope(String name, [List<Object?> args = const []]) => context
      .scopeRegistry
      .callLocalScope(definition.modelType, name, this, args);

  /// Calls a registered query macro.
  ///
  /// Macros provide a way to extend the query builder with custom, reusable logic.
  ///
  /// [name] is the name of the macro.
  /// [args] are optional arguments to pass to the macro.
  ///
  /// Example:
  /// ```dart
  /// // Assuming a macro 'recent' is defined
  /// final recentPosts = await context.query<Post>()
  ///   .macro('recent', [Duration(days: 7)])
  ///   .get();
  /// ```
  Query<T> macro(String name, [List<Object?> args = const []]) =>
      context.scopeRegistry.callMacro(name, this, args);

  /// Limits the number of rows returned per group.
  ///
  /// This is useful for "top N per group" queries.
  ///
  /// [limit] is the maximum number of rows to return for each group.
  /// [column] is the column used for grouping.
  /// [offset] is an optional offset within each group.
  ///
  /// Example:
  /// ```dart
  /// // Get the 3 latest posts for each user
  /// final latestPostsPerUser = await context.query<Post>()
  ///   .orderBy('createdAt', descending: true)
  ///   .limitPerGroup(3, 'userId')
  ///   .get();
  /// ```
  Query<T> limitPerGroup(int limit, String column, {int? offset}) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be greater than zero');
    }
    if (offset != null && offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Must be non-negative');
    }
    final resolved = _resolveGroupLimitColumn(column);
    final next = GroupLimit(column: resolved, limit: limit, offset: offset);
    return _copyWith(groupLimit: next);
  }

  /// Applies ad-hoc table scopes to the query.
  ///
  /// This is typically used internally or for dynamic table-specific scopes.
  Query<T> withTableScopes(List<String> scopes) => _copyWith(
    adHocScopes: [..._adHocScopes, ...scopes],
    globalScopesApplied: false,
  );

  /// Sets an alias for the main table in the query.
  ///
  /// Example:
  /// ```dart
  /// final aliasedUsers = await context.query<User>()
  ///   .withAlias('u')
  ///   .where('u.isActive', true)
  ///   .get();
  /// ```
  Query<T> withAlias(String alias) => _copyWith(tableAlias: alias);

  /// Marks global scopes as having been applied to this query.
  ///
  /// This is typically used internally by the query builder.
  Query<T> markGlobalScopesApplied() => _copyWith(globalScopesApplied: true);

  /// Applies the soft delete filter to the query.
  ///
  /// This is typically used internally to apply soft delete scoping.
  Query<T> applySoftDeleteFilter(FieldDefinition field) {
    final predicate = FieldPredicate(
      field: field.columnName,
      operator: PredicateOperator.isNull,
      value: null,
    );
    return _appendPredicate(predicate, PredicateLogicalOperator.and);
  }
}
