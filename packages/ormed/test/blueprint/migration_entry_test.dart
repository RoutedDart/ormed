import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

class CreateUsersTable extends Migration {
  const CreateUsersTable();

  @override
  Future<void> up(SchemaBuilder schema) async {
    schema.create('users', (table) {
      table.id();
      table.string('name');
    });
  }

  @override
  Future<void> down(SchemaBuilder schema) async {
    schema.drop('users');
  }
}

class AddEmailToUsers extends Migration {
  const AddEmailToUsers();

  @override
  Future<void> up(SchemaBuilder schema) async {
    schema.table('users', (table) {
      table.string('email');
    });
  }

  @override
  Future<void> down(SchemaBuilder schema) async {
    schema.table('users', (table) {
      table.dropColumn('email');
    });
  }
}

class CreatePostsTable extends Migration {
  const CreatePostsTable();

  @override
  Future<void> up(SchemaBuilder schema) async {
    schema.create('posts', (table) {
      table.id();
      table.string('title');
    });
  }

  @override
  Future<void> down(SchemaBuilder schema) async {
    schema.drop('posts');
  }
}

void main() {
  group('MigrationEntry', () {
    test('named constructor parses the migration id string', () {
      final entry = MigrationEntry.named(
        'm_20251130100000_create_users',
        const CreateUsersTable(),
      );

      expect(entry.id.toString(), 'm_20251130100000_create_users');
      expect(entry.migration, isA<CreateUsersTable>());
    });

    test('buildDescriptors sorts migrations by timestamp (oldest first)', () {
      // Create entries in random order
      final entries = [
        MigrationEntry(
          id: MigrationId.parse('m_20251130120000_create_posts'),
          migration: const CreatePostsTable(),
        ),
        MigrationEntry(
          id: MigrationId.parse('m_20251130100000_create_users'),
          migration: const CreateUsersTable(),
        ),
        MigrationEntry(
          id: MigrationId.parse('m_20251130110000_add_email'),
          migration: const AddEmailToUsers(),
        ),
      ];

      final descriptors = MigrationEntry.buildDescriptors(entries);

      // Verify correct order (oldest first)
      expect(descriptors.length, 3);
      expect(descriptors[0].id.toString(), 'm_20251130100000_create_users');
      expect(descriptors[1].id.toString(), 'm_20251130110000_add_email');
      expect(descriptors[2].id.toString(), 'm_20251130120000_create_posts');
    });

    test('buildDescriptors handles already sorted entries', () {
      final entries = [
        MigrationEntry(
          id: MigrationId.parse('m_20251130100000_create_users'),
          migration: const CreateUsersTable(),
        ),
        MigrationEntry(
          id: MigrationId.parse('m_20251130110000_add_email'),
          migration: const AddEmailToUsers(),
        ),
        MigrationEntry(
          id: MigrationId.parse('m_20251130120000_create_posts'),
          migration: const CreatePostsTable(),
        ),
      ];

      final descriptors = MigrationEntry.buildDescriptors(entries);

      // Verify order maintained
      expect(descriptors[0].id.toString(), 'm_20251130100000_create_users');
      expect(descriptors[1].id.toString(), 'm_20251130110000_add_email');
      expect(descriptors[2].id.toString(), 'm_20251130120000_create_posts');
    });

    test('buildDescriptors creates MigrationDescriptor with correct ID', () {
      final entry = MigrationEntry(
        id: MigrationId.parse('m_20251130100000_create_users'),
        migration: const CreateUsersTable(),
      );

      final descriptors = MigrationEntry.buildDescriptors([entry]);

      expect(descriptors.length, 1);
      expect(descriptors[0].id, entry.id);
      expect(descriptors[0].up, isNotNull);
      expect(descriptors[0].down, isNotNull);
    });

    test('buildDescriptors returns immutable list', () {
      final entries = [
        MigrationEntry(
          id: MigrationId.parse('m_20251130100000_create_users'),
          migration: const CreateUsersTable(),
        ),
      ];

      final descriptors = MigrationEntry.buildDescriptors(entries);

      // Verify list is unmodifiable
      expect(() => descriptors.add(descriptors[0]), throwsUnsupportedError);
    });

    test('buildDescriptors handles empty list', () {
      final descriptors = MigrationEntry.buildDescriptors([]);

      expect(descriptors, isEmpty);
    });

    test('buildDescriptors does not mutate input list', () {
      final entries = [
        MigrationEntry(
          id: MigrationId.parse('m_20251130120000_create_posts'),
          migration: const CreatePostsTable(),
        ),
        MigrationEntry(
          id: MigrationId.parse('m_20251130100000_create_users'),
          migration: const CreateUsersTable(),
        ),
      ];

      // Remember original order
      final originalFirst = entries[0].id.toString();
      final originalSecond = entries[1].id.toString();

      MigrationEntry.buildDescriptors(entries);

      // Verify input list unchanged
      expect(entries[0].id.toString(), originalFirst);
      expect(entries[1].id.toString(), originalSecond);
    });

    test('buildDescriptors works with old format IDs', () {
      final entries = [
        MigrationEntry(
          id: MigrationId.parse('2025_11_30_120000_create_posts'),
          migration: const CreatePostsTable(),
        ),
        MigrationEntry(
          id: MigrationId.parse('2025_11_30_100000_create_users'),
          migration: const CreateUsersTable(),
        ),
      ];

      final descriptors = MigrationEntry.buildDescriptors(entries);

      // Verify correct sorting even with old format
      expect(descriptors[0].id.timestamp.hour, 10);
      expect(descriptors[1].id.timestamp.hour, 12);
    });

    test('buildDescriptors handles identical timestamps', () {
      final timestamp = DateTime.utc(2025, 11, 30, 10, 0, 0);
      final entries = [
        MigrationEntry(
          id: MigrationId(timestamp, 'migration_b'),
          migration: const CreatePostsTable(),
        ),
        MigrationEntry(
          id: MigrationId(timestamp, 'migration_a'),
          migration: const CreateUsersTable(),
        ),
      ];

      final descriptors = MigrationEntry.buildDescriptors(entries);

      // Both should be included
      expect(descriptors.length, 2);
      // Order is stable (preserves input order for equal timestamps)
      expect(descriptors[0].id.slug, 'migration_b');
      expect(descriptors[1].id.slug, 'migration_a');
    });
  });
}
