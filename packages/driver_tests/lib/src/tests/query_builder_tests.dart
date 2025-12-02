import 'package:ormed/ormed.dart';
import 'package:driver_tests/src/tests/query_builder/crud_operations_tests.dart';
import 'package:test/test.dart';

import '../../driver_tests.dart';
import 'query_builder/aggregation_tests.dart';
import 'query_builder/fresh_tests.dart';
import 'query_builder/join_clauses_tests.dart';
import 'query_builder/lazy_loading_tests.dart';
import 'query_builder/limit_offset_clauses_tests.dart';
import 'query_builder/order_by_clauses_tests.dart';
import 'query_builder/queryrow_sync_tests.dart';
import 'query_builder/refresh_tests.dart';
import 'query_builder/relation_aggregate_tests.dart';
import 'query_builder/relation_mutation_tests.dart';
import 'query_builder/relation_resolver_cache_tests.dart';
import 'query_builder/relations_accessor_tests.dart';
import 'query_builder/select_clauses_tests.dart';
import 'query_builder/where_clauses_tests.dart';

void runDriverQueryBuilderTests({
  required DataSource dataSource,
  required DriverTestConfig config,
}) {
  group('${config.driverName} query builder', () {
    late TestDatabaseManager manager;

    setUpAll(() async {
      await dataSource.init();
      manager = TestDatabaseManager(
        baseDataSource: dataSource,
        migrationDescriptors: driverTestMigrationEntries
            .map((e) => MigrationDescriptor.fromMigration(
                  id: e.id,
                  migration: e.migration,
                ))
            .toList(),
        strategy: DatabaseIsolationStrategy.truncate,
      );
      await manager.initialize();
    });

    setUp(() async {
      await manager.beginTest('query_builder_tests', dataSource);
    });

    tearDown(() async => manager.endTest('query_builder_tests', dataSource));

    tearDownAll(() async {
      // Schema cleanup is handled by outer test file
    });

    runWhereClausesTests(dataSource, config);
    runOrderByClausesTests(dataSource, config);
    runLimitOffsetClausesTests(dataSource, config);
    runSelectClausesTests(dataSource, config);
    runAggregationTests(dataSource, config);
    runJoinClausesTests(dataSource, config);
    runLazyLoadingTests(dataSource, config);
    runRelationAggregateTests(dataSource, config);
    runRelationMutationTests(dataSource, config);
    runRefreshTests(dataSource, config);
    runFreshTests(dataSource, config);
    runQueryRowSyncTests(dataSource, config);
    runRelationsAccessorTests(dataSource, config);
    runRelationResolverCacheTests(dataSource, config);
    runCrudOperationsTests(dataSource, config);
  });
}
