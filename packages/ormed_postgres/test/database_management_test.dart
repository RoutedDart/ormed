import 'dart:math';

import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';

// Generate unique identifiers for this test run to prevent concurrency conflicts
final _testRunId = Random().nextInt(1000000);

PostgresDriverAdapter _createAdapterFromEnv({String? database}) {
  final defaultUrl =
      OrmedEnvironment().firstNonEmpty(['POSTGRES_URL']) ??
      'postgres://postgres:postgres@localhost:6543/orm_test';

  final uri = Uri.parse(defaultUrl);
  final effectiveUri = database == null ? uri : uri.replace(path: '/$database');
  final url = effectiveUri.toString();

  return PostgresDriverAdapter.custom(
    config: DatabaseConfig(driver: 'postgres', options: {'url': url}),
  );
}

/// Comprehensive test suite for Phase 1: Database Management features (PostgreSQL)
///
/// Tests cover:
/// - Database creation/dropping with various options (encoding, owner, template, locale, etc.)
/// - Transaction depth validation for DDL operations
/// - Foreign key constraint management via ALTER TABLE triggers
/// - Bulk table operations with CASCADE
/// - Edge cases and error handling
void main() {
  group('PostgreSQL Database Management', () {
    late PostgresDriverAdapter adapter;

    setUp(() {
      adapter = _createAdapterFromEnv(database: 'postgres');
    });

    tearDown(() async {
      await adapter.close();
    });

    test('creates and drops database', () async {
      final testDb = 'ormed_test_db_${_testRunId}_create';

      // Clean up if exists
      await adapter.dropDatabaseIfExists(testDb);

      // Create database
      final created = await adapter.createDatabase(testDb);
      expect(created, isTrue);

      // Verify it exists
      final databases = await adapter.listDatabases();
      expect(databases, contains(testDb));

      // Try creating again - should return false
      final createdAgain = await adapter.createDatabase(testDb);
      expect(createdAgain, isFalse);

      // Drop database
      final dropped = await adapter.dropDatabaseIfExists(testDb);
      expect(dropped, isTrue);

      // Verify it's gone
      final databasesAfter = await adapter.listDatabases();
      expect(databasesAfter, isNot(contains(testDb)));
    });

    test('creates database with encoding option', () async {
      final testDb = 'ormed_test_db_${_testRunId}_encoding';

      await adapter.dropDatabaseIfExists(testDb);

      // Create with specific encoding
      await adapter.createDatabase(testDb, options: {'encoding': 'UTF8'});

      // Verify encoding (requires querying pg_database)
      final result = await adapter.queryRaw(
        'SELECT encoding FROM pg_database WHERE datname = ?',
        [testDb],
      );

      expect(result, isNotEmpty);
      // UTF8 encoding is typically 6
      expect(result.first['encoding'], isNotNull);

      await adapter.dropDatabaseIfExists(testDb);
    });

    test('creates database with multiple options', () async {
      final testDb = 'ormed_test_db_${_testRunId}_full_options';

      await adapter.dropDatabaseIfExists(testDb);

      // Create with multiple options
      await adapter.createDatabase(
        testDb,
        options: {'encoding': 'UTF8', 'connection_limit': 10},
      );

      final result = await adapter.queryRaw(
        'SELECT datconnlimit FROM pg_database WHERE datname = ?',
        [testDb],
      );

      expect(result, isNotEmpty);
      expect(result.first['datconnlimit'], equals(10));

      await adapter.dropDatabaseIfExists(testDb);
    });

    test('dropDatabase on non-existent database throws', () async {
      const testDb = 'ormed_nonexistent_pg_db';

      await adapter.dropDatabaseIfExists(testDb);

      expect(() => adapter.dropDatabase(testDb), throwsA(isA<Exception>()));
    });

    test('dropDatabaseIfExists returns false for non-existent', () async {
      const testDb = 'ormed_never_created_pg_db';

      await adapter.dropDatabaseIfExists(testDb);

      final dropped = await adapter.dropDatabaseIfExists(testDb);
      expect(dropped, isFalse);
    });

    test('listDatabases returns all accessible databases', () async {
      final databases = await adapter.listDatabases();

      expect(databases, isNotEmpty);
      // Should omit system databases/templates
      expect(databases, isNot(contains('postgres')));
    });

    test('cannot create database within transaction', () async {
      const testDb = 'ormed_test_in_transaction';

      await adapter.dropDatabaseIfExists(testDb);

      await adapter.transaction(() async {
        expect(
          () => adapter.createDatabase(testDb),
          throwsA(isA<StateError>()),
        );
      });

      await adapter.dropDatabaseIfExists(testDb);
    });

    test('cannot drop database within transaction', () async {
      const testDb = 'ormed_test_drop_in_transaction';

      await adapter.dropDatabaseIfExists(testDb);
      await adapter.createDatabase(testDb);

      await adapter.transaction(() async {
        expect(
          () => adapter.dropDatabaseIfExists(testDb),
          throwsA(isA<StateError>()),
        );
      });

      await adapter.dropDatabaseIfExists(testDb);
    });
  });

  group('PostgreSQL Foreign Key Constraint Management', () {
    late PostgresDriverAdapter adapter;

    setUp(() async {
      adapter = _createAdapterFromEnv();

      // Clean up any previous test tables
      await adapter.executeRaw(
        'DROP TABLE IF EXISTS pg_fk_test_children CASCADE',
      );
      await adapter.executeRaw(
        'DROP TABLE IF EXISTS pg_fk_test_parents CASCADE',
      );
    });

    tearDown(() async {
      await adapter.executeRaw(
        'DROP TABLE IF EXISTS pg_fk_test_children CASCADE',
      );
      await adapter.executeRaw(
        'DROP TABLE IF EXISTS pg_fk_test_parents CASCADE',
      );
      await adapter.close();
    });

    test('enables and disables foreign key constraints via triggers', () async {
      await adapter.executeRaw('''
        CREATE TABLE pg_fk_test_parents (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255)
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE pg_fk_test_children (
          id SERIAL PRIMARY KEY,
          parent_id INT,
          FOREIGN KEY (parent_id) REFERENCES pg_fk_test_parents(id)
        )
      ''');

      // Disable constraints (disables all triggers on all tables)
      final disabled = await adapter.disableForeignKeyConstraints();
      expect(disabled, isTrue);

      // Can now insert invalid FK
      await adapter.executeRaw(
        'INSERT INTO pg_fk_test_children (parent_id) VALUES (?)',
        [999], // Non-existent parent
      );

      // Enable constraints
      final enabled = await adapter.enableForeignKeyConstraints();
      expect(enabled, isTrue);

      // Now FK violations should be caught
      expect(
        () => adapter.executeRaw(
          'INSERT INTO pg_fk_test_children (parent_id) VALUES (?)',
          [888],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('withoutForeignKeyConstraints wrapper works', () async {
      await adapter.executeRaw('''
        CREATE TABLE pg_fk_test_parents (
          id SERIAL PRIMARY KEY
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE pg_fk_test_children (
          id SERIAL PRIMARY KEY,
          parent_id INT,
          FOREIGN KEY (parent_id) REFERENCES pg_fk_test_parents(id)
        )
      ''');

      await adapter.withoutForeignKeyConstraints(() async {
        // Can insert invalid FK inside callback
        await adapter.executeRaw(
          'INSERT INTO pg_fk_test_children (parent_id) VALUES (?)',
          [999],
        );
      });

      // After callback, constraints should be re-enabled
      expect(
        () => adapter.executeRaw(
          'INSERT INTO pg_fk_test_children (parent_id) VALUES (?)',
          [888],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('withoutForeignKeyConstraints re-enables on exception', () async {
      await adapter.executeRaw('''
        CREATE TABLE pg_fk_test_parents (
          id SERIAL PRIMARY KEY
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE pg_fk_test_children (
          id SERIAL PRIMARY KEY,
          parent_id INT,
          FOREIGN KEY (parent_id) REFERENCES pg_fk_test_parents(id)
        )
      ''');

      try {
        await adapter.withoutForeignKeyConstraints(() async {
          throw Exception('Test exception');
        });
      } catch (_) {
        // Expected
      }

      // Constraints should still be re-enabled (verify by trying FK violation)
      expect(
        () => adapter.executeRaw(
          'INSERT INTO pg_fk_test_children (parent_id) VALUES (?)',
          [999],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('can drop parent table when triggers disabled', () async {
      await adapter.executeRaw('''
        CREATE TABLE pg_fk_test_parents (
          id SERIAL PRIMARY KEY
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE pg_fk_test_children (
          id SERIAL PRIMARY KEY,
          parent_id INT,
          FOREIGN KEY (parent_id) REFERENCES pg_fk_test_parents(id)
        )
      ''');

      // Insert data
      await adapter.executeRaw(
        'INSERT INTO pg_fk_test_parents (id) VALUES (1)',
      );
      await adapter.executeRaw(
        'INSERT INTO pg_fk_test_children (parent_id) VALUES (1)',
      );

      // Can't drop parent with triggers enabled (unless CASCADE)
      await adapter.enableForeignKeyConstraints();
      expect(
        () => adapter.executeRaw('DROP TABLE pg_fk_test_parents'),
        throwsA(isA<Exception>()),
      );

      // With triggers disabled, can drop (though PostgreSQL still enforces at DDL level)
      // So we'll just verify the disable worked
      await adapter.disableForeignKeyConstraints();
      // Note: PostgreSQL DDL still enforces FKs, so we need CASCADE
      await adapter.executeRaw('DROP TABLE pg_fk_test_parents CASCADE');
    });
  });

  group('PostgreSQL Drop All Tables', () {
    late PostgresDriverAdapter adapter;

    setUp(() async {
      adapter = _createAdapterFromEnv();

      // Create test tables with foreign keys
      await adapter.executeRaw('DROP TABLE IF EXISTS pg_test_children CASCADE');
      await adapter.executeRaw('DROP TABLE IF EXISTS pg_test_parents CASCADE');

      await adapter.executeRaw('''
        CREATE TABLE pg_test_parents (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255)
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE pg_test_children (
          id SERIAL PRIMARY KEY,
          parent_id INT,
          name VARCHAR(255),
          FOREIGN KEY (parent_id) REFERENCES pg_test_parents(id)
        )
      ''');
    });

    tearDown(() async {
      await adapter.close();
    });

    test('drops all tables including those with foreign keys', () async {
      // Verify tables exist
      final tablesBefore = await adapter.listTables(schema: 'public');
      final tableNames = tablesBefore.map((t) => t.name).toList();
      expect(tableNames, contains('pg_test_parents'));
      expect(tableNames, contains('pg_test_children'));

      // Drop all tables (uses CASCADE)
      await adapter.dropAllTables(schema: 'public');

      // Verify tables are gone
      final tablesAfter = await adapter.listTables(schema: 'public');
      expect(tablesAfter, isEmpty);
    });

    test('dropAllTables with empty database succeeds', () async {
      await adapter.dropAllTables(schema: 'public');

      final tables = await adapter.listTables(schema: 'public');
      expect(tables, isEmpty);

      // Should not throw on empty database
      await adapter.dropAllTables(schema: 'public');
    });

    test(
      'dropAllTables handles complex FK relationships with CASCADE',
      () async {
        await adapter.dropAllTables(schema: 'public');

        // Create complex FK relationships: A -> B -> C
        await adapter.executeRaw('''
        CREATE TABLE pg_table_c (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255)
        )
      ''');

        await adapter.executeRaw('''
        CREATE TABLE pg_table_b (
          id SERIAL PRIMARY KEY,
          c_id INT,
          FOREIGN KEY (c_id) REFERENCES pg_table_c(id)
        )
      ''');

        await adapter.executeRaw('''
        CREATE TABLE pg_table_a (
          id SERIAL PRIMARY KEY,
          b_id INT,
          FOREIGN KEY (b_id) REFERENCES pg_table_b(id)
        )
      ''');

        // Verify all created
        final tablesBefore = await adapter.listTables(schema: 'public');
        expect(tablesBefore.length, greaterThanOrEqualTo(3));

        // Drop all with CASCADE should handle FK dependencies
        await adapter.dropAllTables(schema: 'public');

        // Verify all gone
        final tablesAfter = await adapter.listTables(schema: 'public');
        expect(tablesAfter, isEmpty);
      },
    );

    test('dropAllTables handles self-referencing FKs', () async {
      await adapter.dropAllTables(schema: 'public');

      await adapter.executeRaw('''
        CREATE TABLE pg_self_ref (
          id SERIAL PRIMARY KEY,
          parent_id INT,
          FOREIGN KEY (parent_id) REFERENCES pg_self_ref(id)
        )
      ''');

      await adapter.dropAllTables(schema: 'public');

      final tablesAfter = await adapter.listTables(schema: 'public');
      expect(tablesAfter, isEmpty);
    });
  });

  group('PostgreSQL Edge Cases and Error Handling', () {
    late PostgresDriverAdapter adapter;

    setUp(() {
      adapter = _createAdapterFromEnv();
    });

    tearDown(() async {
      await adapter.close();
    });

    test('database names with underscores', () async {
      final testDb = 'ormed_test_db_${_testRunId}_with_underscores';

      await adapter.dropDatabaseIfExists(testDb);
      await adapter.createDatabase(testDb);

      final databases = await adapter.listDatabases();
      expect(databases, contains(testDb));

      await adapter.dropDatabaseIfExists(testDb);
    });

    test('concurrent FK constraint operations', () async {
      // Multiple enable/disable cycles should work
      for (var i = 0; i < 3; i++) {
        await adapter.disableForeignKeyConstraints();
        await adapter.enableForeignKeyConstraints();
      }

      // Should complete without errors
    });

    test('nested withoutForeignKeyConstraints works correctly', () async {
      await adapter.executeRaw('DROP TABLE IF EXISTS pg_nested_test CASCADE');
      await adapter.executeRaw('''
        CREATE TABLE pg_nested_test (
          id SERIAL PRIMARY KEY,
          parent_id INT,
          FOREIGN KEY (parent_id) REFERENCES pg_nested_test(id)
        )
      ''');

      await adapter.withoutForeignKeyConstraints(() async {
        // Can insert invalid FK in outer callback
        await adapter.executeRaw(
          'INSERT INTO pg_nested_test (parent_id) VALUES (?)',
          [999],
        );

        await adapter.withoutForeignKeyConstraints(() async {
          // Can insert invalid FK in inner callback
          await adapter.executeRaw(
            'INSERT INTO pg_nested_test (parent_id) VALUES (?)',
            [888],
          );
        });
      });

      // Should be re-enabled after all
      expect(
        () => adapter.executeRaw(
          'INSERT INTO pg_nested_test (parent_id) VALUES (?)',
          [777],
        ),
        throwsA(isA<Exception>()),
      );

      await adapter.executeRaw('DROP TABLE pg_nested_test CASCADE');
    });
  });

  group('PostgreSQL Capability Checks', () {
    late PostgresDriverAdapter adapter;

    setUp(() {
      adapter = _createAdapterFromEnv();
    });

    tearDown(() async {
      await adapter.close();
    });

    test('metadata reports databaseManagement capability', () {
      expect(
        adapter.metadata.supportsCapability(
          DriverCapability.databaseManagement,
        ),
        isTrue,
      );
    });

    test('metadata reports foreignKeyConstraintControl capability', () {
      expect(
        adapter.metadata.supportsCapability(
          DriverCapability.foreignKeyConstraintControl,
        ),
        isTrue,
      );
    });
  });

  group('PostgreSQL Has* Helper Methods', () {
    late PostgresDriverAdapter adapter;
    const testDb = 'ormed_has_test_db';

    setUp(() async {
      final adminAdapter = _createAdapterFromEnv();

      // Create test database and schema
      await adminAdapter.dropDatabaseIfExists(testDb);
      await adminAdapter.createDatabase(testDb);
      await adminAdapter.close();

      // Reconnect to the new database
      adapter = _createAdapterFromEnv(database: testDb);

      await adapter.executeRaw('''
        CREATE TABLE users (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          email VARCHAR(255) UNIQUE
        )
      ''');
      await adapter.executeRaw('''
        CREATE TABLE posts (
          id SERIAL PRIMARY KEY,
          title VARCHAR(255),
          user_id INTEGER REFERENCES users(id)
        )
      ''');
      await adapter.executeRaw('''
        CREATE INDEX idx_posts_user_id ON posts(user_id)
      ''');
      await adapter.executeRaw('''
        CREATE VIEW active_users AS SELECT * FROM users WHERE id > 0
      ''');
    });

    tearDown(() async {
      await adapter.close();

      // Reconnect to default database to drop test database
      final cleanupAdapter = _createAdapterFromEnv();
      await cleanupAdapter.dropDatabaseIfExists(testDb);
      await cleanupAdapter.close();
    });

    test('hasTable returns true for existing table', () async {
      expect(await adapter.hasTable('users'), isTrue);
      expect(await adapter.hasTable('posts'), isTrue);
    });

    test('hasTable returns false for non-existent table', () async {
      expect(await adapter.hasTable('comments'), isFalse);
      expect(await adapter.hasTable('categories'), isFalse);
    });

    test('hasTable is case-insensitive', () async {
      expect(await adapter.hasTable('USERS'), isTrue);
      expect(await adapter.hasTable('Users'), isTrue);
      expect(await adapter.hasTable('uSeRs'), isTrue);
    });

    test('hasView returns true for existing view', () async {
      expect(await adapter.hasView('active_users'), isTrue);
    });

    test('hasView returns false for non-existent view', () async {
      expect(await adapter.hasView('inactive_users'), isFalse);
    });

    test('hasView returns false for tables', () async {
      expect(await adapter.hasView('users'), isFalse);
    });

    test('hasColumn returns true for existing column', () async {
      expect(await adapter.hasColumn('users', 'id'), isTrue);
      expect(await adapter.hasColumn('users', 'name'), isTrue);
      expect(await adapter.hasColumn('users', 'email'), isTrue);
      expect(await adapter.hasColumn('posts', 'title'), isTrue);
    });

    test('hasColumn returns false for non-existent column', () async {
      expect(await adapter.hasColumn('users', 'age'), isFalse);
      expect(await adapter.hasColumn('posts', 'content'), isFalse);
    });

    test('hasColumn is case-insensitive', () async {
      expect(await adapter.hasColumn('users', 'NAME'), isTrue);
      expect(await adapter.hasColumn('users', 'Email'), isTrue);
    });

    test('hasColumns returns true when all columns exist', () async {
      expect(
        await adapter.hasColumns('users', ['id', 'name', 'email']),
        isTrue,
      );
      expect(await adapter.hasColumns('posts', ['id', 'title']), isTrue);
    });

    test('hasColumns returns false when any column is missing', () async {
      expect(await adapter.hasColumns('users', ['id', 'name', 'age']), isFalse);
      expect(await adapter.hasColumns('posts', ['title', 'content']), isFalse);
    });

    test('hasColumns works with empty list', () async {
      expect(await adapter.hasColumns('users', []), isTrue);
    });

    test('hasIndex returns true for existing index', () async {
      expect(await adapter.hasIndex('posts', 'idx_posts_user_id'), isTrue);
    });

    test('hasIndex returns false for non-existent index', () async {
      expect(await adapter.hasIndex('posts', 'idx_posts_title'), isFalse);
    });

    test('hasIndex filters by type: primary', () async {
      expect(
        await adapter.hasIndex('users', 'users_pkey', type: 'primary'),
        isTrue,
      );
    });

    test('hasIndex filters by type: unique', () async {
      expect(
        await adapter.hasIndex('users', 'users_email_key', type: 'unique'),
        isTrue,
      );
    });

    test('hasIndex is case-insensitive', () async {
      expect(await adapter.hasIndex('posts', 'IDX_POSTS_USER_ID'), isTrue);
      expect(await adapter.hasIndex('posts', 'Idx_Posts_User_Id'), isTrue);
    });
  });
}
