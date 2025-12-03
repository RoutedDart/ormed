import 'package:ormed/src/driver/driver_capability.dart';
import 'package:ormed/src/driver/query_row_identifier.dart';
import 'package:ormed/src/hook/query_builder_hook.dart'
    show SchemaMutationHook, RepositoryHook, QueryBuilderHook;
import 'package:ormed/src/hook/relation_hook.dart';

/// Capabilities advertised by a driver.
class DriverMetadata {
  const DriverMetadata({
    required this.name,
    this.supportsReturning = false,
    this.supportsTransactions = true,
    this.supportsQueryDeletes = false,
    this.requiresPrimaryKeyForQueryUpdate = true,
    this.queryUpdateRowIdentifier,
    Set<DriverCapability>? capabilities,
    this.annotationQueryHooks,
    this.annotationRepositoryHooks,
    this.queryBuilderHook,
    this.repositoryHook,
    this.schemaMutationHooks,
    this.relationHook,
    this.identifierQuote = '"',
  }) : _capabilities = capabilities ?? const {};

  /// The quote character used for identifiers.
  final String identifierQuote;

  /// Identifier for the driver (e.g. `sqlite`).
  final String name;

  /// Whether INSERT/UPDATE statements can return records directly.
  final bool supportsReturning;

  /// Whether the driver can wrap statements in transactions.
  final bool supportsTransactions;

  /// Whether the driver can compile query-driven DELETE statements that may
  /// include ORDER BY / LIMIT clauses.
  final bool supportsQueryDeletes;

  /// Whether query builder updates require the target model to expose a
  /// primary key column. Dialects like PostgreSQL and SQLite can target
  /// pseudo-columns (e.g. `ctid`, `rowid`) instead.
  final bool requiresPrimaryKeyForQueryUpdate;

  /// Optional fallback row identifier used when query updates run against
  /// tables without an explicit primary key.
  final QueryRowIdentifier? queryUpdateRowIdentifier;
  final Set<DriverCapability> _capabilities;
  final Map<Type, QueryBuilderHook>? annotationQueryHooks;
  final Map<Type, RepositoryHook>? annotationRepositoryHooks;
  final QueryBuilderHook? queryBuilderHook;
  final RepositoryHook? repositoryHook;
  final List<SchemaMutationHook>? schemaMutationHooks;
  final RelationHook? relationHook;

  bool supportsCapability(DriverCapability capability) {
    return _capabilities.contains(capability);
  }
}
