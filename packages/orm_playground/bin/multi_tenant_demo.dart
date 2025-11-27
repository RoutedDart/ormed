/// Demonstrates querying multiple tenants through the playground helpers.
library;

import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:orm_playground/orm_playground.dart';

import '../database/seeders.dart' as playground_seeders;

const _tenants = ['default', 'analytics'];

Future<void> main(List<String> arguments) async {
  final database = PlaygroundDatabase();
  final logSql = arguments.contains('--sql');

  try {
    for (final tenant in _tenants) {
      final connection = await database.open(tenant: tenant);
      await _prepareTenant(connection, tenant, logSql: logSql);
    }

    for (final tenant in _tenants) {
      final connection = await database.open(tenant: tenant);
      await _summarizeTenant(tenant, connection);
    }
  } finally {
    await database.dispose();
  }
}

/// Seeds [tenant] if it has no users and optionally logs SQL.
Future<void> _prepareTenant(
  OrmConnection connection,
  String tenant, {
  required bool logSql,
}) async {
  await connection.ensureLedgerInitialized();
  if (!await _hasUsers(connection)) {
    await playground_seeders.seedPlayground(connection);
  }
  if (logSql) {
    connection.beforeExecuting((statement) {
      stdout.writeln('[Tenant $tenant SQL] ${statement.sqlWithBindings}');
    });
  }
}

Future<bool> _hasUsers(OrmConnection connection) async {
  final rows = await connection.query<User>().limit(1).rows();
  return rows.isNotEmpty;
}

/// Prints per-tenant user counts via the generated model helper.
Future<void> _summarizeTenant(String tenant, OrmConnection connection) async {
  final binding = UserModelFactory.withConnection(connection.context);
  final rows = await binding.query().orderBy('id').rows();
  final emails = rows.map((row) => row.model.email).join(', ');
  stdout.writeln('Tenant $tenant has ${rows.length} users.');
  stdout.writeln('  Users: ${emails.isEmpty ? '<none>' : emails}');
}
