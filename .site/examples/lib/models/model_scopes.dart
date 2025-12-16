// Scope examples for docs
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';
import '../orm_registry.g.dart';

// #region model-scopes-definition
@OrmModel(table: 'scoped_users')
class ScopedUser extends Model<ScopedUser> {
  const ScopedUser({
    required this.id,
    required this.email,
    required this.active,
    this.role,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;
  final String email;
  final bool active;
  final String? role;

  @OrmScope(global: true)
  static Query<$ScopedUser> activeOnly(Query<$ScopedUser> query) =>
      query.whereEquals('active', true);

  @OrmScope()
  static Query<$ScopedUser> withDomain(
    Query<$ScopedUser> query,
    String domain,
  ) =>
      query.whereLike('email', '%@$domain');

  @OrmScope()
  static Query<$ScopedUser> roleIs(
    Query<$ScopedUser> query, {
    required String role,
  }) =>
      query.whereEquals('role', role);
}
// #endregion model-scopes-definition

// #region model-scopes-usage
Future<void> scopeUsageExample() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'scopes-demo',
      driver: InMemoryQueryExecutor(),
      entities: [ScopedUserOrmDefinition.definition],
      registry: ModelRegistry()..register(ScopedUserOrmDefinition.definition),
    ),
  );
  await dataSource.init();
  registerScopedUserScopes(dataSource.context.scopeRegistry);

  await dataSource.repo<$ScopedUser>().insertMany([
    const $ScopedUser(id: 0, email: 'a@example.com', active: true, role: 'admin'),
    const $ScopedUser(id: 0, email: 'b@test.com', active: true, role: 'user'),
    const $ScopedUser(id: 0, email: 'c@example.com', active: false, role: 'user'),
  ]);

  // Global scope filters inactive rows automatically
  final active = await dataSource.context.query<$ScopedUser>().get();

  // Local scopes compose via generated extensions
  final admins = await dataSource.context
      .query<$ScopedUser>()
      .withDomain('example.com')
      .roleIs(role: 'admin')
      .get();

  // Opt out of globals when needed
  final allRows = await dataSource.context
      .query<$ScopedUser>()
      .withoutGlobalScope('activeOnly')
      .get();

  print([active.length, admins.length, allRows.length]);
}
// #endregion model-scopes-usage

// #region model-scopes-inline
Future<void> inlineScopeExample() async {
  final registry = ModelRegistry()..register(ScopedUserOrmDefinition.definition);
  final context = QueryContext(
    registry: registry,
    driver: InMemoryQueryExecutor(),
  );

  // Register scopes at runtime without touching the model
  context.scopeRegistry.addLocalScope<$ScopedUser>(
    'byRole',
    (query, args) => query.whereEquals('role', args.first),
  );
  context.scopeRegistry.addGlobalScope<$ScopedUser>(
    'activeOnly',
    (query) => query.whereEquals('active', true),
  );

  final admins = await context.query<$ScopedUser>().scope('byRole', ['admin']).get();
  final allWithInactive = await context
      .query<$ScopedUser>()
      .withoutGlobalScope('activeOnly')
      .get();

  print([admins.length, allWithInactive.length]);
}
// #endregion model-scopes-inline
