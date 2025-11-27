import 'dart:convert';

import 'package:ormed/migrations.dart';

// <ORM-MIGRATION-IMPORTS>
import 'migrations/2025_11_15_014501_create_users_table.dart';
import 'migrations/2025_11_15_015021_create_posts_table.dart';
import 'migrations/2025_11_15_015036_create_comments_table.dart';
import 'migrations/2025_11_15_015055_create_post_tags_table.dart';
import 'migrations/2025_11_15_015222_create_tags_table.dart';// </ORM-MIGRATION-IMPORTS>

class _MigrationEntry {
  const _MigrationEntry({required this.id, required this.migration});

  final MigrationId id;
  final Migration migration;
}

final List<_MigrationEntry> _entries = [
  // <ORM-MIGRATION-REGISTRY>
  _MigrationEntry(
    id: MigrationId.parse('2025_11_15_014501_create_users_table'),
    migration: const CreateUsersTable(),
  ),
  _MigrationEntry(
    id: MigrationId.parse('2025_11_15_015021_create_posts_table'),
    migration: const CreatePostsTable(),
  ),
  _MigrationEntry(
    id: MigrationId.parse('2025_11_15_015036_create_comments_table'),
    migration: const CreateCommentsTable(),
  ),
  _MigrationEntry(
    id: MigrationId.parse('2025_11_15_015055_create_post_tags_table'),
    migration: const CreatePostTagsTable(),
  ),
  _MigrationEntry(
    id: MigrationId.parse('2025_11_15_015222_create_tags_table'),
    migration: const CreateTagsTable(),
  ),// </ORM-MIGRATION-REGISTRY>
];

List<MigrationDescriptor> buildMigrations() =>
    List.unmodifiable(_entries.map(
      (entry) => MigrationDescriptor.fromMigration(
        id: entry.id,
        migration: entry.migration,
      ),
    ));

_MigrationEntry? _findEntry(String rawId) {
  for (final entry in _entries) {
    if (entry.id.toString() == rawId) return entry;
  }
  return null;
}

void main(List<String> args) {
  if (args.contains('--dump-json')) {
    final payload = buildMigrations().map((m) => m.toJson()).toList();
    print(jsonEncode(payload));
    return;
  }

  final planIndex = args.indexOf('--plan-json');
  if (planIndex != -1) {
    final id = args[planIndex + 1];
    final entry = _findEntry(id);
    if (entry == null) {
      throw StateError('Unknown migration id $id.');
    }
    final directionName = args[args.indexOf('--direction') + 1];
    final direction = MigrationDirection.values.byName(directionName);
    final snapshotIndex = args.indexOf('--schema-snapshot');
    SchemaSnapshot? snapshot;
    if (snapshotIndex != -1) {
      final decoded =
          utf8.decode(base64.decode(args[snapshotIndex + 1]));
      final payload = jsonDecode(decoded) as Map<String, Object?>;
      snapshot = SchemaSnapshot.fromJson(payload);
    }
    final plan = entry.migration.plan(direction, snapshot: snapshot);
    print(jsonEncode(plan.toJson()));
  }
}
