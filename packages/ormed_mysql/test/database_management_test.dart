import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';

MySqlDriverAdapter _createAdapterFromEnv() {
  final url =
      Platform.environment['MYSQL_URL'] ??
      'mysql://root:secret@localhost:6605/orm_test';

  return MySqlDriverAdapter.custom(
    config: DatabaseConfig(driver: 'mysql', options: {'url': url, 'ssl': true}),
  );
}

String _foreignKeyStatus(Map<String, Object?> row) {
  return (row['value'] ?? row['Value'] ?? '').toString().toLowerCase();
}

/// Comprehensive test suite for Phase 1: Database Management features
/// 
/// Tests cover:
/// - Database creation/dropping with various options
/// - Foreign key constraint management
/// - Bulk table operations
/// - Edge cases and error handling
void main() {
  group('MySQL Database Management', () {
    late MySqlDriverAdapter adapter;

    setUp(() {
      adapter = _createAdapterFromEnv();
    });

    tearDown(() async {
      await adapter.close();
    });

    test('creates and drops database', () async {
      const testDb = 'ormed_test_db_create';

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

    test('creates database with custom options', () async {
      const testDb = 'ormed_test_db_charset';

      await adapter.dropDatabaseIfExists(testDb);

      // Create with specific charset and collation
      await adapter.createDatabase(testDb, options: {
        'charset': 'utf8mb3',
        'collation': 'utf8mb3_general_ci',
      });

      // Verify charset (requires querying information_schema)
      final result = await adapter.queryRaw(
        'SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME '
        'FROM information_schema.SCHEMATA '
        'WHERE SCHEMA_NAME = ?',
        [testDb],
      );

      expect(result, isNotEmpty);
      expect(result.first['default_character_set_name'], equals('utf8mb3'));
      expect(
        result.first['default_collation_name'],
        equals('utf8mb3_general_ci'),
      );

      await adapter.dropDatabaseIfExists(testDb);
    });

    test('dropDatabase on non-existent database throws', () async {
      const testDb = 'ormed_nonexistent_db';

      // Ensure it doesn't exist
      await adapter.dropDatabaseIfExists(testDb);

      // Dropping non-existent database should throw
      expect(
        () => adapter.dropDatabase(testDb),
        throwsA(isA<Exception>()),
      );
    });

    test('dropDatabaseIfExists returns false for non-existent', () async {
      const testDb = 'ormed_never_created_db';

      // Ensure it doesn't exist
      await adapter.dropDatabaseIfExists(testDb);

      // Drop again should return false
      final dropped = await adapter.dropDatabaseIfExists(testDb);
      expect(dropped, isFalse);
    });

    test('listDatabases returns all accessible databases', () async {
      final databases = await adapter.listDatabases();

      // Should at least contain default databases
      expect(databases, isNotEmpty);
      expect(databases, contains('mysql'));
      expect(databases, contains('information_schema'));
    });

    test('supports default charset utf8mb4', () async {
      const testDb = 'ormed_test_default_charset';

      await adapter.dropDatabaseIfExists(testDb);
      await adapter.createDatabase(testDb); // No options = defaults

      final result = await adapter.queryRaw(
        'SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME '
        'FROM information_schema.SCHEMATA '
        'WHERE SCHEMA_NAME = ?',
        [testDb],
      );

      expect(result.first['default_character_set_name'], equals('utf8mb4'));
      expect(
        result.first['default_collation_name'],
        equals('utf8mb4_unicode_ci'),
      );

      await adapter.dropDatabaseIfExists(testDb);
    });
  });

  group('MySQL Foreign Key Constraint Management', () {
    late MySqlDriverAdapter adapter;

    setUp(() {
      adapter = _createAdapterFromEnv();
    });

    tearDown(() async {
      await adapter.close();
    });

    test('enables and disables foreign key constraints', () async {
      // Disable constraints
      final disabled = await adapter.disableForeignKeyConstraints();
      expect(disabled, isTrue);

      // Check that they're disabled
      final resultDisabled = await adapter.queryRaw(
        'SHOW VARIABLES LIKE "foreign_key_checks"',
      );
      final disabledStatus = _foreignKeyStatus(resultDisabled.first);
      expect(['0', 'off'], contains(disabledStatus));

      // Enable constraints
      final enabled = await adapter.enableForeignKeyConstraints();
      expect(enabled, isTrue);

      // Check that they're enabled
      final resultEnabled = await adapter.queryRaw(
        'SHOW VARIABLES LIKE "foreign_key_checks"',
      );
      final enabledStatus = _foreignKeyStatus(resultEnabled.first);
      expect(['1', 'on'], contains(enabledStatus));
    });

    test('withoutForeignKeyConstraints wrapper works', () async {
      // Initially enabled
      await adapter.enableForeignKeyConstraints();

      var checksInsideCallback = '';

      await adapter.withoutForeignKeyConstraints(() async {
        // Inside callback, constraints should be disabled
        final result = await adapter.queryRaw(
          'SHOW VARIABLES LIKE "foreign_key_checks"',
        );
        checksInsideCallback = _foreignKeyStatus(result.first);
      });

      // Verify they were disabled inside
      expect(['0', 'off'], contains(checksInsideCallback));

      // After callback, constraints should be re-enabled
      final resultAfter = await adapter.queryRaw(
        'SHOW VARIABLES LIKE "foreign_key_checks"',
      );
      expect(['1', 'on'], contains(_foreignKeyStatus(resultAfter.first)));
    });

    test('withoutForeignKeyConstraints re-enables on exception', () async {
      await adapter.enableForeignKeyConstraints();

      try {
        await adapter.withoutForeignKeyConstraints(() async {
          // Throw inside callback
          throw Exception('Test exception');
        });
      } catch (_) {
        // Expected
      }

      // Constraints should still be re-enabled
      final result = await adapter.queryRaw(
        'SHOW VARIABLES LIKE "foreign_key_checks"',
      );
      expect(['1', 'on'], contains(_foreignKeyStatus(result.first)));
    });

    test('can drop child table when constraints disabled', () async {
      await adapter.executeRaw('DROP TABLE IF EXISTS fk_test_children');
      await adapter.executeRaw('DROP TABLE IF EXISTS fk_test_parents');

      await adapter.executeRaw('''
        CREATE TABLE fk_test_parents (
          id INT PRIMARY KEY AUTO_INCREMENT
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE fk_test_children (
          id INT PRIMARY KEY AUTO_INCREMENT,
          parent_id INT,
          FOREIGN KEY (parent_id) REFERENCES fk_test_parents(id)
        )
      ''');

      // Can't drop parent with constraints enabled
      await adapter.enableForeignKeyConstraints();
      expect(
        () => adapter.executeRaw('DROP TABLE fk_test_parents'),
        throwsA(isA<Exception>()),
      );

      // Can drop parent with constraints disabled
      await adapter.disableForeignKeyConstraints();
      await adapter.executeRaw('DROP TABLE fk_test_parents');
      await adapter.executeRaw('DROP TABLE fk_test_children');

      await adapter.enableForeignKeyConstraints();
    });
  });

  group('MySQL Drop All Tables', () {
    late MySqlDriverAdapter adapter;

    setUp(() async {
      adapter = _createAdapterFromEnv();

      // Create test tables with foreign keys
      await adapter.executeRaw('''
        CREATE TABLE IF NOT EXISTS test_parents (
          id INT PRIMARY KEY AUTO_INCREMENT,
          name VARCHAR(255)
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE IF NOT EXISTS test_children (
          id INT PRIMARY KEY AUTO_INCREMENT,
          parent_id INT,
          name VARCHAR(255),
          FOREIGN KEY (parent_id) REFERENCES test_parents(id)
        )
      ''');
    });

    tearDown(() async {
      await adapter.close();
    });

    test('drops all tables including those with foreign keys', () async {
      // Verify tables exist
      final tablesBefore = await adapter.listTables();
      final tableNames = tablesBefore.map((t) => t.name).toList();
      expect(tableNames, contains('test_parents'));
      expect(tableNames, contains('test_children'));

      // Drop all tables
      await adapter.dropAllTables();

      // Verify tables are gone
      final tablesAfter = await adapter.listTables();
      expect(tablesAfter, isEmpty);
    });

    test('dropAllTables with empty database succeeds', () async {
      // Drop all tables first
      await adapter.dropAllTables();

      // Verify empty
      final tables = await adapter.listTables();
      expect(tables, isEmpty);

      // Should not throw on empty database
      await adapter.dropAllTables();
    });

    test('dropAllTables handles complex FK relationships', () async {
      // Clean up first
      await adapter.dropAllTables();

      // Create complex FK relationships: A -> B -> C
      await adapter.executeRaw('''
        CREATE TABLE table_c (
          id INT PRIMARY KEY AUTO_INCREMENT,
          name VARCHAR(255)
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE table_b (
          id INT PRIMARY KEY AUTO_INCREMENT,
          c_id INT,
          FOREIGN KEY (c_id) REFERENCES table_c(id)
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE table_a (
          id INT PRIMARY KEY AUTO_INCREMENT,
          b_id INT,
          FOREIGN KEY (b_id) REFERENCES table_b(id)
        )
      ''');

      // Verify all created
      final tablesBefore = await adapter.listTables();
      expect(tablesBefore.length, greaterThanOrEqualTo(3));

      // Drop all should handle FK dependencies
      await adapter.dropAllTables();

      // Verify all gone
      final tablesAfter = await adapter.listTables();
      expect(tablesAfter, isEmpty);
    });

    test('dropAllTables handles self-referencing FKs', () async {
      await adapter.dropAllTables();

      await adapter.executeRaw('''
        CREATE TABLE self_ref (
          id INT PRIMARY KEY AUTO_INCREMENT,
          parent_id INT,
          FOREIGN KEY (parent_id) REFERENCES self_ref(id)
        )
      ''');

      await adapter.dropAllTables();

      final tablesAfter = await adapter.listTables();
      expect(tablesAfter, isEmpty);
    });
  });

  group('MySQL Edge Cases and Error Handling', () {
    late MySqlDriverAdapter adapter;

    setUp(() {
      adapter = _createAdapterFromEnv();
    });

    tearDown(() async {
      await adapter.close();
    });

    test('database names with special characters', () async {
      const testDb = 'ormed_test_db_123';

      await adapter.dropDatabaseIfExists(testDb);
      await adapter.createDatabase(testDb);

      final databases = await adapter.listDatabases();
      expect(databases, contains(testDb));

      await adapter.dropDatabaseIfExists(testDb);
    });

    test('concurrent FK constraint operations', () async {
      // Multiple enable/disable cycles should work
      for (var i = 0; i < 5; i++) {
        await adapter.disableForeignKeyConstraints();
        await adapter.enableForeignKeyConstraints();
      }

      final result = await adapter.queryRaw(
        'SHOW VARIABLES LIKE "foreign_key_checks"',
      );
      expect(['1', 'on'], contains(_foreignKeyStatus(result.first)));
    });

    test('nested withoutForeignKeyConstraints works correctly', () async {
      await adapter.enableForeignKeyConstraints();

      var innerChecks = '';
      var outerChecks = '';

      await adapter.withoutForeignKeyConstraints(() async {
        final outer = await adapter.queryRaw(
          'SHOW VARIABLES LIKE "foreign_key_checks"',
        );
        outerChecks = _foreignKeyStatus(outer.first);

        await adapter.withoutForeignKeyConstraints(() async {
          final inner = await adapter.queryRaw(
            'SHOW VARIABLES LIKE "foreign_key_checks"',
          );
          innerChecks = _foreignKeyStatus(inner.first);
        });
      });

      // Both should be disabled
      expect(['0', 'off'], contains(outerChecks));
      expect(['0', 'off'], contains(innerChecks));

      // Should be re-enabled after all
      final finalResult = await adapter.queryRaw(
        'SHOW VARIABLES LIKE "foreign_key_checks"',
      );
      expect(['1', 'on'], contains(_foreignKeyStatus(finalResult.first)));
    });
  });

  group('MySQL Capability Checks', () {
    late MySqlDriverAdapter adapter;

    setUp(() {
      adapter = _createAdapterFromEnv();
    });

    tearDown(() async {
      await adapter.close();
    });

    test('metadata reports databaseManagement capability', () {
      expect(
        adapter.metadata.supportsCapability(DriverCapability.databaseManagement),
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

  group('MySQL Has* Helper Methods', () {
    late MySqlDriverAdapter adapter;
    const testDb = 'ormed_has_test_db';

    setUp(() async {
      adapter = _createAdapterFromEnv();

      // Create test database and schema
      await adapter.dropDatabaseIfExists(testDb);
      await adapter.createDatabase(testDb);
      await adapter.executeRaw('USE $testDb');

      await adapter.executeRaw('''
        CREATE TABLE users (
          id INT PRIMARY KEY AUTO_INCREMENT,
          name VARCHAR(255) NOT NULL,
          email VARCHAR(255) UNIQUE
        )
      ''');
      await adapter.executeRaw('''
        CREATE TABLE posts (
          id INT PRIMARY KEY AUTO_INCREMENT,
          title VARCHAR(255),
          user_id INT,
          FOREIGN KEY (user_id) REFERENCES users(id)
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
      await adapter.dropDatabaseIfExists(testDb);
      await adapter.close();
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
      expect(await adapter.hasColumns('users', ['id', 'name', 'email']), isTrue);
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
      expect(await adapter.hasIndex('users', 'PRIMARY', type: 'primary'), isTrue);
    });

    test('hasIndex filters by type: unique', () async {
      expect(await adapter.hasIndex('users', 'email', type: 'unique'), isTrue);
    });

    test('hasIndex is case-insensitive', () async {
      expect(await adapter.hasIndex('posts', 'IDX_POSTS_USER_ID'), isTrue);
      expect(await adapter.hasIndex('posts', 'Idx_Posts_User_Id'), isTrue);
    });
  });
}
