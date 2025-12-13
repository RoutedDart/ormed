part of 'query.dart';

/// A callback for a global scope.
typedef GlobalScopeCallback<T> = Query<T> Function(Query<T> query);

/// A callback for a local scope.
typedef LocalScopeCallback<T> =
    Query<T> Function(Query<T> query, List<Object?> args);

/// A callback for a query macro.
typedef QueryMacroCallback =
    Query<dynamic> Function(Query<dynamic> query, List<Object?> args);

/// An untyped global scope.
typedef UntypedScope = Query<dynamic> Function(Query<dynamic> query);

/// An untyped local scope.
typedef UntypedLocalScope =
    Query<dynamic> Function(Query<dynamic> query, List<Object?> args);

/// A registry for query scopes and macros.
///
/// Scopes allow you to add constraints to queries for a given model.
/// Global scopes are applied to all queries for a model, while local scopes
/// can be applied on a per-query basis.
///
/// Macros allow you to add custom methods to the query builder.
class ScopeRegistry {
  /// Creates a new [ScopeRegistry].
  ScopeRegistry();

  static const String softDeleteScopeIdentifier = '__softDeletes';
  static const String adHocScopeKey = '__adHoc__';

  final Map<Type, Map<String, UntypedScope>> _globalScopes = {};
  final Map<Type, Map<String, Object>> _localScopes = {};
  final Map<String, QueryMacroCallback> _macros = {};
  final Map<String, List<_AdHocScopeRegistration>> _adHocScopes = {};
  final List<_PatternGlobalScopeRegistration> _patternGlobalScopes = [];
  final Map<String, List<_PatternLocalScopeRegistration>> _patternLocalScopes =
      {};

  /// Adds a global scope for a model of type [T].
  ///
  /// Example:
  /// ```dart
  /// registry.addGlobalScope<User>('active', (query) {
  ///   return query.where('status', '=', 'active');
  /// });
  /// ```
  void addGlobalScope<T>(String identifier, GlobalScopeCallback<T> scope) =>
      addGlobalScopeForType(
        T,
        identifier,
        (query) => scope(query as Query<T>) as Query<dynamic>,
      );

  /// Adds a global scope for a model of the given [modelType].
  void addGlobalScopeForType(
    Type modelType,
    String identifier,
    UntypedScope scope,
  ) {
    final scopes = _globalScopes.putIfAbsent(
      modelType,
      () => <String, UntypedScope>{},
    );
    scopes.putIfAbsent(identifier, () => scope);
  }

  /// Adds a global scope that applies to models matching a [pattern].
  void addGlobalScopePattern(
    String identifier,
    UntypedScope scope, {
    String pattern = '*',
  }) {
    if (identifier.trim().isEmpty) {
      throw ArgumentError.value(identifier, 'identifier', 'cannot be empty');
    }
    _patternGlobalScopes.add(
      _PatternGlobalScopeRegistration(
        identifier: identifier,
        pattern: pattern,
        scope: scope,
      ),
    );
  }

  /// Applies all registered global scopes to the given [query].
  Query<T> applyGlobalScopes<T>(Query<T> query) {
    if (query.globalScopesApplied) {
      return query;
    }
    if (query.ignoreAllGlobalScopes) {
      return _applyAdHocScopes(query).markGlobalScopesApplied();
    }
    var builder = query as Query<dynamic>;
    final modelScopes = _globalScopes[query.definition.modelType];
    if (modelScopes != null && modelScopes.isNotEmpty) {
      for (final entry in modelScopes.entries) {
        if (builder.ignoredGlobalScopes.contains(entry.key)) {
          continue;
        }
        builder = entry.value(builder);
      }
    }
    if (_patternGlobalScopes.isNotEmpty) {
      for (final registration in _patternGlobalScopes) {
        if (builder.ignoredGlobalScopes.contains(registration.identifier)) {
          continue;
        }
        if (_matchesModelPattern(registration.pattern, builder.definition)) {
          builder = registration.scope(builder);
        }
      }
    }
    return _applyAdHocScopes(builder as Query<T>).markGlobalScopesApplied();
  }

  Query<T> _applyAdHocScopes<T>(Query<T> query) {
    // Apply ad-hoc scopes to both AdHocModelDefinition and TableQueryDefinition
    if (query.definition is! AdHocModelDefinition &&
        query.definition is! TableQueryDefinition) {
      return query;
    }
    if (query.adHocScopes.isEmpty) {
      return query;
    }
    final tableName = query.definition.tableName;
    var builder = query as Query<dynamic>;
    for (final scopeName in query.adHocScopes) {
      final registrations = _adHocScopes[scopeName];
      if (registrations == null || registrations.isEmpty) {
        continue;
      }
      for (final registration in registrations) {
        if (_matches(registration.pattern, tableName)) {
          builder = registration.scope(builder);
        }
      }
    }
    return builder as Query<T>;
  }

  /// Registers a scope for an ad-hoc table query.
  void registerAdHocTableScope(
    String name,
    UntypedScope scope, {
    String pattern = '*',
  }) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Scope name cannot be empty.');
    }
    final registrations = _adHocScopes.putIfAbsent(
      normalized,
      () => <_AdHocScopeRegistration>[],
    );
    registrations.add(_AdHocScopeRegistration(pattern: pattern, scope: scope));
  }

  /// Adds a scope for an ad-hoc table query.
  @Deprecated('Use registerAdHocTableScope with a named scope instead')
  void addAdHocScope(String table, UntypedScope scope) {
    registerAdHocTableScope(table, scope, pattern: table);
  }

  bool _matches(String pattern, String table) {
    final escaped = RegExp.escape(pattern).replaceAll('\\*', '.*');
    final regex = RegExp('^$escaped\$');
    return regex.hasMatch(table);
  }

  bool _matchesModelPattern(
    String pattern,
    ModelDefinition<dynamic> definition,
  ) {
    if (_matches(pattern, definition.modelName)) {
      return true;
    }
    return _matches(pattern, definition.tableName);
  }

  /// Adds a local scope for a model of type [T].
  ///
  /// Example:
  /// ```dart
  /// registry.addLocalScope<User>('popular', (query, args) {
  ///   return query.where('votes', '>', args.first);
  /// });
  ///
  /// // Later, in a query:
  /// final popularUsers = await query.scope('popular', [100]).get();
  /// ```
  void addLocalScope<T>(String name, LocalScopeCallback<T> scope) {
    final scopes = _localScopes.putIfAbsent(T, () => <String, Object>{});
    scopes[name] = scope;
  }

  /// Adds a local scope that applies to models matching a [pattern].
  void addLocalScopePattern(
    String name,
    UntypedLocalScope scope, {
    String pattern = '*',
  }) {
    final registrations = _patternLocalScopes.putIfAbsent(
      name,
      () => <_PatternLocalScopeRegistration>[],
    );
    registrations.add(
      _PatternLocalScopeRegistration(pattern: pattern, scope: scope),
    );
  }

  /// Calls a local scope by [name] on the given [query].
  Query<T> callLocalScope<T>(
    Type modelType,
    String name,
    Query<T> query,
    List<Object?> args,
  ) {
    final scopes = _localScopes[modelType];
    final callback = scopes?[name];
    if (callback != null) {
      final typed = callback as LocalScopeCallback<T>;
      return typed(query, args);
    }
    final patternScopes = _patternLocalScopes[name];
    if (patternScopes != null) {
      for (final registration in patternScopes) {
        if (_matchesModelPattern(registration.pattern, query.definition)) {
          final result = registration.scope(query as Query<dynamic>, args);
          return result as Query<T>;
        }
      }
    }
    throw ArgumentError.value(name, 'name', 'Local scope not registered.');
  }

  /// Adds a macro to the query builder.
  ///
  /// Example:
  /// ```dart
  /// registry.addMacro('whereActive', (query, args) {
  ///   return query.where('status', '=', 'active');
  /// });
  ///
  /// // Later, in a query:
  /// final activeUsers = await query.macro('whereActive').get();
  /// ```
  void addMacro(String name, QueryMacroCallback macro) {
    _macros[name] = macro;
  }

  /// Calls a macro by [name] on the given [query].
  Query<T> callMacro<T>(String name, Query<T> query, List<Object?> args) {
    final macro = _macros[name];
    if (macro == null) {
      throw ArgumentError.value(name, 'name', 'Macro not registered.');
    }
    final result = macro(query as Query<dynamic>, args);
    return result as Query<T>;
  }
}

class _AdHocScopeRegistration {
  const _AdHocScopeRegistration({required this.pattern, required this.scope});

  final String pattern;
  final UntypedScope scope;
}

class _PatternGlobalScopeRegistration {
  const _PatternGlobalScopeRegistration({
    required this.identifier,
    required this.pattern,
    required this.scope,
  });

  final String identifier;
  final String pattern;
  final UntypedScope scope;
}

class _PatternLocalScopeRegistration {
  const _PatternLocalScopeRegistration({
    required this.pattern,
    required this.scope,
  });

  final String pattern;
  final UntypedLocalScope scope;
}
