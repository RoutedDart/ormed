/// Demonstrates querying multiple tenants using the DataSource API.
library;

import 'dart:io';

import 'package:artisan_args/artisan_args.dart';
import 'package:orm_playground/src/database/seeders.dart' as playground_seeders;
import 'package:ormed/ormed.dart';
import 'package:orm_playground/orm_playground.dart';

/// Shared CLI IO for styled output.
final io = ArtisanIO(
  style: ArtisanStyle(ansi: stdout.supportsAnsiEscapes),
  out: stdout.writeln,
  err: stderr.writeln,
);

Future<void> main(List<String> arguments) async {
  final database = PlaygroundDatabase();
  final logSql = arguments.contains('--sql');

  io.title('Multi-Tenant Demo');

  // Get available tenants from configuration
  final tenants = database.tenantNames.toList();
  io.twoColumnDetail('Available tenants', tenants.join(', '));
  io.newLine();

  // Store data sources for each tenant
  final dataSources = <String, DataSource>{};

  try {
    // Initialize and prepare each tenant
    io.section('Initializing Tenants');
    for (final tenant in tenants) {
      final ds = await database.dataSource(tenant: tenant);
      dataSources[tenant] = ds;
      await _prepareTenant(ds, tenant, logSql: logSql);
    }

    io.newLine();
    io.section('Tenant Summary');

    // Summarize each tenant
    for (final tenant in tenants) {
      final ds = dataSources[tenant]!;
      await _summarizeTenant(tenant, ds);
    }

    // Demonstrate tenant isolation
    io.newLine();
    io.section('Tenant Isolation Demo');
    await _demonstrateTenantIsolation(dataSources);

    io.newLine();
    io.success('Multi-tenant demo completed successfully.');
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
    io.writeln(
      '${io.style.success('✓')} Seeded tenant: ${io.style.emphasize(tenant)}',
    );
  } else {
    io.writeln(
      '${io.style.muted('○')} Tenant ${io.style.emphasize(tenant)} already has data',
    );
  }

  if (logSql) {
    ds.beforeExecuting((statement) {
      io.writeln(
        io.style.muted('[Tenant $tenant SQL] ${statement.sqlWithBindings}'),
      );
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
  final postCount = await ds.query<Post>().count();

  io.writeln(io.style.emphasize('Tenant "$tenant"'));
  io.twoColumnDetail(
    '  Users',
    '${users.length} (${emails.isEmpty ? 'none' : emails})',
  );
  io.twoColumnDetail('  Posts', '$postCount');
}

/// Demonstrates that each DataSource operates independently.
Future<void> _demonstrateTenantIsolation(
  Map<String, DataSource> dataSources,
) async {
  final defaultDs = dataSources['default'];
  final analyticsDs = dataSources['analytics'];

  if (defaultDs == null || analyticsDs == null) {
    io.warning('Not all tenants available for isolation demo.');
    return;
  }

  // Count users in each tenant
  final defaultUserCount = await defaultDs.query<User>().count();
  final analyticsUserCount = await analyticsDs.query<User>().count();

  io.twoColumnDetail('Default tenant users', '$defaultUserCount');
  io.twoColumnDetail('Analytics tenant users', '$analyticsUserCount');

  // Demonstrate using repo<T>() and query<T>() on different tenants
  io.newLine();
  io.info('Latest user from each tenant:');

  final latestDefault = await defaultDs
      .query<User>()
      .orderBy('id', descending: true)
      .firstOrNull();
  if (latestDefault != null) {
    io.twoColumnDetail('  Default', latestDefault.email);
  }

  final latestAnalytics = await analyticsDs
      .query<User>()
      .orderBy('id', descending: true)
      .firstOrNull();
  if (latestAnalytics != null) {
    io.twoColumnDetail('  Analytics', latestAnalytics.email);
  }

  // Demonstrate transaction on specific tenant
  io.newLine();
  io.info('Running transaction on default tenant...');
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
    io.twoColumnDetail(
      '  Tag exists in analytics',
      existsInAnalytics ? 'yes' : 'no',
    );

    // Clean up
    await defaultDs.query<Tag>().whereEquals('name', tempTagName).forceDelete();
  });

  io.success('Transaction completed - tenants remain isolated.');
}
