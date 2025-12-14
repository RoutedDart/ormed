// Multi-database examples for documentation
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

import '../models/user.dart';
import '../models/user.orm.dart';
import '../models/post.dart';
import '../models/post.orm.dart';
import '../orm_registry.g.dart';

// #region multi-db-setup
Future<void> multiDatabaseSetup() async {
  // Primary database
  final primaryDs = DataSource(
    DataSourceOptions(
      name: 'primary',
      driver: InMemoryQueryExecutor(),
      entities: generatedOrmModelDefinitions,
    ),
  );

  // Analytics database
  final analyticsDs = DataSource(
    DataSourceOptions(
      name: 'analytics',
      driver: InMemoryQueryExecutor(),
      entities: generatedOrmModelDefinitions,
    ),
  );

  // Testing database
  final testingDs = DataSource(
    DataSourceOptions(
      name: 'testing',
      driver: InMemoryQueryExecutor(),
      entities: generatedOrmModelDefinitions,
    ),
  );

  await Future.wait([
    primaryDs.init(),
    analyticsDs.init(),
    testingDs.init(),
  ]);
}
// #endregion multi-db-setup

// #region multi-db-named
Future<void> namedConnectionsExample() async {
  final primaryDs = DataSource(
    DataSourceOptions(
      name: 'primary',
      driver: InMemoryQueryExecutor(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await primaryDs.init();

  final analyticsDs = DataSource(
    DataSourceOptions(
      name: 'analytics',
      driver: InMemoryQueryExecutor(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await analyticsDs.init();

  // Query from specific connection
  final users = await primaryDs.query<$User>().get();
  final analyticsData = await analyticsDs.query<$User>().get();
}
// #endregion multi-db-named

// #region multi-db-transaction-caveat
Future<void> transactionCaveatExample() async {
  final primaryDs = DataSource(
    DataSourceOptions(
      name: 'primary',
      driver: InMemoryQueryExecutor(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await primaryDs.init();

  final analyticsDs = DataSource(
    DataSourceOptions(
      name: 'analytics',
      driver: InMemoryQueryExecutor(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await analyticsDs.init();

  // Transactions are per-datasource
  await primaryDs.transaction(() async {
    await primaryDs.repo<$User>().insert(
          $User(id: 0, email: 'user@example.com'),
        );

    // This is NOT in the same transaction!
    // analyticsDs.repo<$Analytics>().insert(...)
  });
}
// #endregion multi-db-transaction-caveat

// #region multi-db-coordinating
Future<void> coordinatingDatabasesExample() async {
  final primaryDs = DataSource(
    DataSourceOptions(
      name: 'primary',
      driver: InMemoryQueryExecutor(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await primaryDs.init();

  final analyticsDs = DataSource(
    DataSourceOptions(
      name: 'analytics',
      driver: InMemoryQueryExecutor(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await analyticsDs.init();

  // Coordinate operations across databases manually
  try {
    // Step 1: Primary operation
    final user = await primaryDs.repo<$User>().insert(
          $User(id: 0, email: 'user@example.com'),
        );

    // Step 2: Analytics operation
    // await analyticsDs.repo<$UserActivity>().insert(...)

    // If step 2 fails, you may need to compensate step 1
  } catch (e) {
    // Handle compensation if needed
    rethrow;
  }
}
// #endregion multi-db-coordinating

// #region multi-db-tenant
class TenantDataSourceManager {
  final Map<String, DataSource> _dataSources = {};

  Future<DataSource> getForTenant(String tenantId) async {
    if (!_dataSources.containsKey(tenantId)) {
      final ds = DataSource(
        DataSourceOptions(
          name: 'tenant_$tenantId',
          driver: InMemoryQueryExecutor(),
          entities: generatedOrmModelDefinitions,
          tablePrefix: '${tenantId}_',
        ),
      );
      await ds.init();
      _dataSources[tenantId] = ds;
    }
    return _dataSources[tenantId]!;
  }

  Future<void> dispose() async {
    for (final ds in _dataSources.values) {
      await ds.dispose();
    }
    _dataSources.clear();
  }
}
// #endregion multi-db-tenant

// #region multi-db-tenant-scope
Future<void> tenantScopeExample() async {
  final manager = TenantDataSourceManager();

  // Get datasource for specific tenant
  final tenantDs = await manager.getForTenant('acme-corp');

  // All queries scoped to tenant
  final users = await tenantDs.query<$User>().get();
  await tenantDs.repo<$User>().insert(
        $User(id: 0, email: 'user@acme.com'),
      );

  await manager.dispose();
}
// #endregion multi-db-tenant-scope

// #region multi-db-factory
typedef DataSourceFactory = Future<DataSource> Function(String name);

DataSourceFactory createDataSourceFactory(
    List<OrmModelDefinition> definitions) {
  return (String name) async {
    final ds = DataSource(
      DataSourceOptions(
        name: name,
        driver: InMemoryQueryExecutor(),
        entities: definitions,
      ),
    );
    await ds.init();
    return ds;
  };
}
// #endregion multi-db-factory

// #region multi-db-manager
class ConnectionManager {
  final Map<String, DataSource> _connections = {};

  Future<DataSource> get(String name) async {
    if (!_connections.containsKey(name)) {
      throw Exception('Connection "$name" not registered');
    }
    return _connections[name]!;
  }

  Future<void> register(String name, DataSource ds) async {
    await ds.init();
    _connections[name] = ds;
  }

  Future<void> disposeAll() async {
    for (final ds in _connections.values) {
      await ds.dispose();
    }
    _connections.clear();
  }
}
// #endregion multi-db-manager
