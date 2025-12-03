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

void runDriverQueryBuilderTests({required DataSource dataSource}) {
  final metadata = dataSource.connection.driver.metadata;
  group('${metadata.name} query builder', () {
    late TestDatabaseManager manager;

    setUpAll(() async {
      await dataSource.init();
      manager = TestDatabaseManager(
        baseDataSource: dataSource,
        migrationDescriptors: driverTestMigrationEntries
            .map(
              (e) => MigrationDescriptor.fromMigration(
                id: e.id,
                migration: e.migration,
              ),
            )
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

    // TODO: Update sub-tests to not require config
    // For now, we construct a dummy config or refactor sub-tests too.
    // Since sub-tests are imported, I need to check them.
    // Assuming sub-tests also need refactoring.
    // But for this step, I will just pass metadata if possible or refactor them later.
    // Wait, the instruction is to remove config.
    // I need to check if sub-tests use config.
    // The file content shows: runWhereClausesTests(dataSource, config);
    // So I need to refactor those too.
    // But I can't do that in this single tool call if they are in different files.
    // I will comment out the calls for now or pass a dummy config if I can't refactor them all at once.
    // Actually, I should refactor them.
    // But they are in `package:driver_tests/src/tests/query_builder/...`
    // I will just update this file to NOT pass config, and then I will have errors in this file until I update the sub-tests.
    // That is fine.

    runWhereClausesTests(dataSource);
    runOrderByClausesTests(dataSource);
    runLimitOffsetClausesTests(dataSource);
    runSelectClausesTests(dataSource);
    runAggregationTests(dataSource);
    runJoinClausesTests(dataSource);
    runLazyLoadingTests(dataSource);
    runRelationAggregateTests(dataSource);
    runRelationMutationTests(dataSource);
    runRefreshTests(dataSource);
    runFreshTests(dataSource);
    runQueryRowSyncTests(dataSource);
    runRelationsAccessorTests(dataSource);
    runRelationResolverCacheTests(dataSource);
    runCrudOperationsTests(dataSource);
  });
}
