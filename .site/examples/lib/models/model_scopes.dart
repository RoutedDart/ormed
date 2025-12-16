// Scope examples for docs
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import '../orm_registry.g.dart';

// #region model-scopes-model
@OrmModel(table: 'scoped_users')
class ScopedUser extends Model<ScopedUser> {
  const ScopedUser({
    required this.id,
    required this.email,
    required this.active,
    this.role,
  });

  // #region model-scopes-fields
  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;
  final String email;
  final bool active;
  final String? role;
  // #endregion model-scopes-fields

  // #region model-scopes-global
  @OrmScope(global: true)
  static Query<$ScopedUser> activeOnly(Query<$ScopedUser> query) =>
      query.whereEquals('active', true);
  // #endregion model-scopes-global

  // #region model-scopes-local-positional
  @OrmScope()
  static Query<$ScopedUser> withDomain(
    Query<$ScopedUser> query,
    String domain,
  ) =>
      query.whereLike('email', '%@$domain');
  // #endregion model-scopes-local-positional

  // #region model-scopes-local-named
  @OrmScope()
  static Query<$ScopedUser> roleIs(
    Query<$ScopedUser> query, {
    required String role,
  }) =>
      query.whereEquals('role', role);
  // #endregion model-scopes-local-named
}
// #endregion model-scopes-model

// Full runnable example kept for completeness; docs embed smaller regions below.
Future<void> scopeUsageExample() async {
  // #region model-scopes-register
  // bootstrapOrm() wires up generated scopes (and other generated helpers).
  final registry = bootstrapOrm();
  // #endregion model-scopes-register

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'scopes-demo',
      driver: SqliteDriverAdapter.inMemory(),
      registry: registry,
    ),
  );
  await dataSource.init();

  await dataSource.repo<$ScopedUser>().insertMany([
    const $ScopedUser(id: 0, email: 'a@example.com', active: true, role: 'admin'),
    const $ScopedUser(id: 0, email: 'b@test.com', active: true, role: 'user'),
    const $ScopedUser(id: 0, email: 'c@example.com', active: false, role: 'user'),
  ]);

  // #region model-scopes-query-global
  // Global scope filters inactive rows automatically
  final active = await dataSource.context.query<$ScopedUser>().get();
  // #endregion model-scopes-query-global

  // #region model-scopes-query-local
  // Local scopes compose via generated extensions
  final admins = await dataSource.context
      .query<$ScopedUser>()
      .withDomain('example.com')
      .roleIs(role: 'admin')
      .get();
  // #endregion model-scopes-query-local

  // #region model-scopes-query-without-global
  // Opt out of globals when needed
  final allRows = await dataSource.context
      .query<$ScopedUser>()
      .withoutGlobalScope('activeOnly')
      .get();
  // #endregion model-scopes-query-without-global

  print([active.length, admins.length, allRows.length]);
}

// #region model-scopes-inline
Future<void> inlineScopeExample() async {
  final registry = ModelRegistry()..register(ScopedUserOrmDefinition.definition);
  final context = QueryContext(
    registry: registry,
    driver: SqliteDriverAdapter.inMemory(),
  );

  // #region model-scopes-inline-register
  // Register scopes at runtime without touching the model
  context.scopeRegistry.addLocalScope<$ScopedUser>(
    'byRole',
    (query, args) => query.whereEquals('role', args.first),
  );
  context.scopeRegistry.addGlobalScope<$ScopedUser>(
    'activeOnly',
    (query) => query.whereEquals('active', true),
  );
  // #endregion model-scopes-inline-register

  final admins = await context.query<$ScopedUser>().scope('byRole', ['admin']).get();
  final allWithInactive = await context
      .query<$ScopedUser>()
      .withoutGlobalScope('activeOnly')
      .get();

  print([admins.length, allWithInactive.length]);
}
// #endregion model-scopes-inline
