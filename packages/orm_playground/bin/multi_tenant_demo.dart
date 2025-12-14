/// Demonstrates querying multiple tenants using the DataSource API.
library;

import 'dart:io';

import 'package:orm_playground/src/database/seeders.dart' as playground_seeders;
import 'package:ormed/ormed.dart';
import 'package:orm_playground/orm_playground.dart';

Future<void> main(List<String> arguments) async {
  final database = PlaygroundDatabase();
  final logSql = arguments.contains('--sql');

  // Get available tenants from configuration
  final tenants = database.tenantNames.toList();
  stdout.writeln('Available tenants: ${tenants.join(', ')}');

  // Store data sources for each tenant
  final dataSources = <String, DataSource>{};

  try {
    // Initialize and prepare each tenant
    for (final tenant in tenants) {
      final ds = await database.dataSource(tenant: tenant);
      dataSources[tenant] = ds;
      await _prepareTenant(ds, tenant, logSql: logSql);
    }

    stdout.writeln('\n--- Tenant Summary ---');

    // Summarize each tenant
    for (final tenant in tenants) {
      final ds = dataSources[tenant]!;
      await _summarizeTenant(tenant, ds);
    }

    // Demonstrate tenant isolation
    stdout.writeln('\n--- Tenant Isolation Demo ---');
    await _demonstrateTenantIsolation(dataSources);
  } finally {
    await database.dispose();
  }
}

/// Seeds [tenant] if it has no users and optionally logs SQL.
Future<void> _prepareTenant(
  DataSource ds,
  String tenant, {
  required bool logSql,
}) async {
  if (!await _hasUsers(ds)) {
    // Seed using the underlying connection for compatibility
    await playground_seeders.seedPlayground(ds.connection);
    stdout.writeln('Seeded tenant: $tenant');
  }

  if (logSql) {
    ds.beforeExecuting((statement) {
      stdout.writeln('[Tenant $tenant SQL] ${statement.sqlWithBindings}');
    });
  }
}

Future<bool> _hasUsers(DataSource ds) async {
  final users = await ds.query<User>().limit(1).get();
  return users.isNotEmpty;
}

/// Prints per-tenant user counts using the DataSource API.
Future<void> _summarizeTenant(String tenant, DataSource ds) async {
  final users = await ds.query<User>().orderBy('id').get();
  final emails = users.map((user) => user.email).join(', ');

  stdout.writeln('Tenant "$tenant" has ${users.length} users.');
  stdout.writeln('  Users: ${emails.isEmpty ? '<none>' : emails}');

  // Also show post counts
  final postCount = await ds.query<Post>().count();
  stdout.writeln('  Posts: $postCount');
}

/// Demonstrates that each DataSource operates independently.
Future<void> _demonstrateTenantIsolation(
  Map<String, DataSource> dataSources,
) async {
  final defaultDs = dataSources['default'];
  final analyticsDs = dataSources['analytics'];

  if (defaultDs == null || analyticsDs == null) {
    stdout.writeln('Not all tenants available for isolation demo.');
    return;
  }

  // Count users in each tenant
  final defaultUserCount = await defaultDs.query<User>().count();
  final analyticsUserCount = await analyticsDs.query<User>().count();

  stdout.writeln('Default tenant users: $defaultUserCount');
  stdout.writeln('Analytics tenant users: $analyticsUserCount');

  // Demonstrate using repo<T>() and query<T>() on different tenants
  stdout.writeln('\nLatest user from each tenant:');

  final latestDefault = await defaultDs
      .query<User>()
      .orderBy('id', descending: true)
      .firstOrNull();
  if (latestDefault != null) {
    stdout.writeln('  Default: ${latestDefault.email}');
  }

  final latestAnalytics = await analyticsDs
      .query<User>()
      .orderBy('id', descending: true)
      .firstOrNull();
  if (latestAnalytics != null) {
    stdout.writeln('  Analytics: ${latestAnalytics.email}');
  }

  // Demonstrate transaction on specific tenant
  stdout.writeln('\nRunning transaction on default tenant...');
  final now = DateTime.now().toUtc();
  final tempTagName = 'multi-tenant-demo-${now.microsecondsSinceEpoch}';

  await defaultDs.transaction(() async {
    await defaultDs.repo<Tag>().insert(
      Tag(name: tempTagName, createdAt: now, updatedAt: now),
    );

    // Verify it doesn't exist in analytics tenant
    final existsInAnalytics = await analyticsDs
        .query<Tag>()
        .whereEquals('name', tempTagName)
        .exists();
    stdout.writeln(
      '  Tag "$tempTagName" exists in analytics: $existsInAnalytics',
    );

    // Clean up
    await defaultDs.query<Tag>().whereEquals('name', tempTagName).forceDelete();
  });

  stdout.writeln('Transaction completed - tenants remain isolated.');
}
