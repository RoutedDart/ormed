import 'package:test/test.dart';
import '../../driver_tests.dart';
import 'query_builder/aggregation_tests.dart';
import 'query_builder/join_clauses_tests.dart';
import 'query_builder/lazy_loading_tests.dart';
import 'query_builder/limit_offset_clauses_tests.dart';
import 'query_builder/order_by_clauses_tests.dart';
import 'query_builder/select_clauses_tests.dart';
import 'query_builder/where_clauses_tests.dart';
import 'query_builder/refresh_tests.dart';
import 'query_builder/queryrow_sync_tests.dart';

void runDriverQueryBuilderTests({
  required DriverHarnessBuilder<DriverTestHarness> createHarness,
  required DriverTestConfig config,
}) {
  group('${config.driverName} query builder', () {
    runWhereClausesTests(createHarness, config);
    runOrderByClausesTests(createHarness, config);
    runLimitOffsetClausesTests(createHarness, config);
    runSelectClausesTests(createHarness, config);
    runAggregationTests(createHarness, config);
    runJoinClausesTests(createHarness, config);
    runLazyLoadingTests(createHarness, config);
    runRefreshTests(createHarness, config);
    runQueryRowSyncTests(createHarness, config);
  });
}
