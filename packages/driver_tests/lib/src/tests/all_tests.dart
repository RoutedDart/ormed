import 'package:ormed/ormed.dart';

import 'advanced_query_tests.dart';
import 'driver_override_tests.dart';
import 'factory_inheritance_tests.dart';
import 'join_tests.dart';
import 'mutation_tests.dart';
import 'query_builder_tests.dart';
import 'query_tests.dart';
import 'repository_tests.dart';
import 'transaction_tests.dart';

/// Runs all driver tests against the provided [dataSource].
void runAllDriverTests({required DataSource dataSource}) {
  runDriverQueryTests(dataSource: dataSource);
  runDriverJoinTests(dataSource: dataSource);
  runDriverAdvancedQueryTests(dataSource: dataSource);
  runDriverMutationTests(dataSource: dataSource);
  runDriverTransactionTests(dataSource: dataSource);
  runDriverOverrideTests(dataSource: dataSource);
  runDriverQueryBuilderTests(dataSource: dataSource);
  runDriverRepositoryTests(dataSource: dataSource);
  runDriverFactoryInheritanceTests(dataSource: dataSource);
}
