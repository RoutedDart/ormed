part of '../query_builder.dart';

extension ScopeExtension<T extends OrmEntity> on Query<T> {
  /// Applies a registered local scope to the query.
  ///
  /// Local scopes allow you to define reusable query constraints that can be
  /// applied to specific queries.
  ///
  /// Example:
  /// ```dart
  /// // Register a local scope
  /// context.scopeRegistry.addLocalScope<User>('active', (query, args) {
  ///   return query.where('status', 'active');
  /// });
  ///
  /// // Apply the scope to a query
  /// final activeUsers = await context.query<User>()
  ///   .scope('active')
  ///   .get();
  /// ```
  Query<T> scope(String name, [List<Object?> args = const []]) {
    final scopeRegistry = context.scopeRegistry;

    try {
      return scopeRegistry.callLocalScope(T, name, this, args);
    } catch (e) {
      throw ArgumentError('Local scope "$name" not found for ${T.toString()}');
    }
  }

  /// Applies a registered query macro to the query.
  ///
  /// Query macros are global reusable query constraints that can be applied
  /// to any query, regardless of model type.
  ///
  /// Example:
  /// ```dart
  /// // Register a macro
  /// context.scopeRegistry.addMacro('recent', (query, args) {
  ///   final days = args.isNotEmpty ? args[0] as int : 7;
  ///   final cutoff = DateTime.now().subtract(Duration(days: days));
  ///   return query.where('createdAt', cutoff, PredicateOperator.greaterThan);
  /// });
  ///
  /// // Apply the macro to any query
  /// final recentPosts = await context.query<Post>()
  ///   .macro('recent', [7])
  ///   .get();
  /// ```
  Query<T> macro(String name, [List<Object?> args = const []]) {
    final scopeRegistry = context.scopeRegistry;

    try {
      return scopeRegistry.callMacro(name, this, args);
    } catch (e) {
      throw ArgumentError('Query macro "$name" not found');
    }
  }

  /// Removes all global scopes from the query.
  ///
  /// This method allows you to retrieve all records, even those that would
  /// normally be filtered by global scopes (like soft-deleted records).
  ///
  /// Example:
  /// ```dart
  /// // Get all posts, including soft-deleted ones
  /// final allPosts = await context.query<Post>()
  ///   .withoutGlobalScopes()
  ///   .get();
  /// ```
  Query<T> withoutGlobalScopes([List<String>? scopes]) {
    if (scopes == null || scopes.isEmpty) {
      return _copyWith(ignoreAllGlobalScopes: true);
    }

    final currentIgnored = ignoredGlobalScopes;
    currentIgnored.addAll(scopes);
    return _copyWith(ignoredScopes: currentIgnored);
  }

  /// Removes a specific global scope from the query.
  ///
  /// Example:
  /// ```dart
  /// // Get all posts, including soft-deleted ones
  /// final allPosts = await context.query<Post>()
  ///   .withoutGlobalScope('softDeletes')
  ///   .get();
  /// ```
  Query<T> withoutGlobalScope(String scope) {
    final currentIgnored = ignoredGlobalScopes;
    currentIgnored.add(scope);
    return _copyWith(ignoredScopes: currentIgnored);
  }
}

