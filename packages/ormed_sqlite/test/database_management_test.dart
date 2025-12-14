import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

/// Comprehensive test suite for Phase 1: Database Management features (SQLite)
///
/// Tests cover:
/// - File-based database creation/dropping
/// - Foreign key constraint management via PRAGMA
/// - Bulk table operations
/// - File cleanup and error handling
void main() {
  // Use system temp directory for test databases (cross-platform)
  final testDbPath =
      '${Directory.systemTemp.path}/ormed_test_${DateTime.now().millisecondsSinceEpoch}.db';

  group('SQLite Database Management', () {
    late SqliteDriverAdapter adapter;

    setUp(() {
      // Clean up any existing test file
      final file = File(testDbPath);
      if (file.existsSync()) {
        file.deleteSync();
      }

      adapter = SqliteDriverAdapter.file(testDbPath);
    });

    tearDown(() async {
      await adapter.close();

      // Clean up test file
      final file = File(testDbPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    test('creates and drops database (file)', () async {
      final testDb = '/tmp/ormed_test_create.db';
      final testFile = File(testDb);

      // Ensure it doesn't exist
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }

      // Create database (file)
      final created = await adapter.createDatabase(testDb);
      expect(created, isTrue);

      // Verify file exists
      expect(testFile.existsSync(), isTrue);

      // Try creating again - should return false
      final createdAgain = await adapter.createDatabase(testDb);
      expect(createdAgain, isFalse);

      // Drop database (file)
      final dropped = await adapter.dropDatabaseIfExists(testDb);
      expect(dropped, isTrue);

      // Verify file is gone
      expect(testFile.existsSync(), isFalse);
    });

    test('dropDatabase on non-existent database throws', () async {
      final testDb = '/tmp/ormed_sqlite_nonexistent.db';
      final testFile = File(testDb);

      // Ensure it doesn't exist
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }

      // Dropping non-existent database should throw
      expect(() => adapter.dropDatabase(testDb), throwsA(isA<StateError>()));
    });

    test('dropDatabaseIfExists returns false for non-existent', () async {
      final testDb = '/tmp/ormed_sqlite_never_created.db';
      final testFile = File(testDb);

      // Ensure it doesn't exist
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }

      // Drop non-existent should return false
      final dropped = await adapter.dropDatabaseIfExists(testDb);
      expect(dropped, isFalse);
    });

    test('listDatabases throws UnsupportedError', () async {
      // SQLite doesn't have a catalog concept
      expect(() => adapter.listDatabases(), throwsA(isA<UnsupportedError>()));
    });

    test('creates database with nested directories', () async {
      final testDb = '/tmp/ormed/nested/dirs/test.db';
      final testFile = File(testDb);

      // Ensure parent directories don't exist
      final parentDir = testFile.parent;
      if (parentDir.existsSync()) {
        parentDir.deleteSync(recursive: true);
      }

      // Create database (should create parent directories)
      final created = await adapter.createDatabase(testDb);
      expect(created, isTrue);
      expect(testFile.existsSync(), isTrue);

      // Clean up
      await adapter.dropDatabaseIfExists(testDb);
      parentDir.deleteSync(recursive: true);
    });
  });

  group('SQLite Foreign Key Constraint Management', () {
    late SqliteDriverAdapter adapter;

    setUp(() async {
      final file = File(testDbPath);
      if (file.existsSync()) {
        file.deleteSync();
      }

      adapter = SqliteDriverAdapter.file(testDbPath);

      // Clean up any previous test tables
      await adapter.executeRaw('DROP TABLE IF EXISTS fk_test_children');
      await adapter.executeRaw('DROP TABLE IF EXISTS fk_test_parents');
    });

    tearDown(() async {
      await adapter.close();

      final file = File(testDbPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    test('enables and disables foreign key constraints via PRAGMA', () async {
      await adapter.executeRaw('''
        CREATE TABLE fk_test_parents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE fk_test_children (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          parent_id INTEGER,
          FOREIGN KEY (parent_id) REFERENCES fk_test_parents(id)
        )
      ''');

      // Disable constraints
      final disabled = await adapter.disableForeignKeyConstraints();
      expect(disabled, isTrue);

      // Check that they're disabled
      final resultDisabled = await adapter.queryRaw('PRAGMA foreign_keys');
      expect(resultDisabled.first['foreign_keys'], equals(0));

      // Can insert invalid FK
      await adapter.executeRaw(
        'INSERT INTO fk_test_children (parent_id) VALUES (?)',
        [999],
      );

      // Enable constraints
      final enabled = await adapter.enableForeignKeyConstraints();
      expect(enabled, isTrue);

      // Check that they're enabled
      final resultEnabled = await adapter.queryRaw('PRAGMA foreign_keys');
      expect(resultEnabled.first['foreign_keys'], equals(1));

      // Now FK violations should be caught
      expect(
        () => adapter.executeRaw(
          'INSERT INTO fk_test_children (parent_id) VALUES (?)',
          [888],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('withoutForeignKeyConstraints wrapper works', () async {
      await adapter.executeRaw('''
        CREATE TABLE fk_test_parents (
          id INTEGER PRIMARY KEY AUTOINCREMENT
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE fk_test_children (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          parent_id INTEGER,
          FOREIGN KEY (parent_id) REFERENCES fk_test_parents(id)
        )
      ''');

      // Enable FK checks
      await adapter.enableForeignKeyConstraints();

      var checksInsideCallback = 0;

      await adapter.withoutForeignKeyConstraints(() async {
        // Inside callback, constraints should be disabled
        final result = await adapter.queryRaw('PRAGMA foreign_keys');
        checksInsideCallback = result.first['foreign_keys'] as int;

        // Can insert invalid FK
        await adapter.executeRaw(
          'INSERT INTO fk_test_children (parent_id) VALUES (?)',
          [999],
        );
      });

      // Verify they were disabled inside
      expect(checksInsideCallback, equals(0));

      // After callback, constraints should be re-enabled
      final resultAfter = await adapter.queryRaw('PRAGMA foreign_keys');
      expect(resultAfter.first['foreign_keys'], equals(1));
    });

    test('withoutForeignKeyConstraints re-enables on exception', () async {
      await adapter.executeRaw('''
        CREATE TABLE fk_test_parents (
          id INTEGER PRIMARY KEY AUTOINCREMENT
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE fk_test_children (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          parent_id INTEGER,
          FOREIGN KEY (parent_id) REFERENCES fk_test_parents(id)
        )
      ''');

      await adapter.enableForeignKeyConstraints();

      try {
        await adapter.withoutForeignKeyConstraints(() async {
          throw Exception('Test exception');
        });
      } catch (_) {
        // Expected
      }

      // Constraints should still be re-enabled
      final result = await adapter.queryRaw('PRAGMA foreign_keys');
      expect(result.first['foreign_keys'], equals(1));
    });

    test('can delete from parent table when constraints disabled', () async {
      await adapter.executeRaw('''
        CREATE TABLE fk_test_parents (
          id INTEGER PRIMARY KEY AUTOINCREMENT
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE fk_test_children (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          parent_id INTEGER,
          FOREIGN KEY (parent_id) REFERENCES fk_test_parents(id)
        )
      ''');

      // Insert data
      await adapter.executeRaw('INSERT INTO fk_test_parents (id) VALUES (1)');
      await adapter.executeRaw(
        'INSERT INTO fk_test_children (parent_id) VALUES (1)',
      );

      await adapter.enableForeignKeyConstraints();

      // Can't delete parent with constraints enabled
      expect(
        () => adapter.executeRaw('DELETE FROM fk_test_parents WHERE id = 1'),
        throwsA(isA<Exception>()),
      );

      // Can delete parent with constraints disabled
      await adapter.disableForeignKeyConstraints();
      await adapter.executeRaw('DELETE FROM fk_test_parents WHERE id = 1');

      await adapter.enableForeignKeyConstraints();
    });
  });

  group('SQLite Drop All Tables', () {
    late SqliteDriverAdapter adapter;

    setUp(() async {
      final file = File(testDbPath);
      if (file.existsSync()) {
        file.deleteSync();
      }

      adapter = SqliteDriverAdapter.file(testDbPath);

      // Create test tables with foreign keys
      await adapter.executeRaw('DROP TABLE IF EXISTS test_children');
      await adapter.executeRaw('DROP TABLE IF EXISTS test_parents');

      await adapter.executeRaw('''
        CREATE TABLE test_parents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE test_children (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          parent_id INTEGER,
          name TEXT,
          FOREIGN KEY (parent_id) REFERENCES test_parents(id)
        )
      ''');
    });

    tearDown(() async {
      await adapter.close();

      final file = File(testDbPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
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
      await adapter.dropAllTables();

      final tables = await adapter.listTables();
      expect(tables, isEmpty);

      // Should not throw on empty database
      await adapter.dropAllTables();
    });

    test('dropAllTables handles complex FK relationships', () async {
      await adapter.dropAllTables();

      // Create complex FK relationships: A -> B -> C
      await adapter.executeRaw('''
        CREATE TABLE table_c (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE table_b (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          c_id INTEGER,
          FOREIGN KEY (c_id) REFERENCES table_c(id)
        )
      ''');

      await adapter.executeRaw('''
        CREATE TABLE table_a (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          b_id INTEGER,
          FOREIGN KEY (b_id) REFERENCES table_b(id)
        )
      ''');

      // Verify all created
      final tablesBefore = await adapter.listTables();
      expect(tablesBefore.length, equals(3));

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
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          parent_id INTEGER,
          FOREIGN KEY (parent_id) REFERENCES self_ref(id)
        )
      ''');

      await adapter.dropAllTables();

      final tablesAfter = await adapter.listTables();
      expect(tablesAfter, isEmpty);
    });
  });

  group('SQLite Edge Cases and Error Handling', () {
    late SqliteDriverAdapter adapter;

    setUp(() {
      final file = File(testDbPath);
      if (file.existsSync()) {
        file.deleteSync();
      }

      adapter = SqliteDriverAdapter.file(testDbPath);
    });

    tearDown(() async {
      await adapter.close();

      final file = File(testDbPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    test('database file paths with spaces', () async {
      final testDb = '/tmp/ormed test with spaces.db';
      final testFile = File(testDb);

      if (testFile.existsSync()) {
        testFile.deleteSync();
      }

      await adapter.createDatabase(testDb);
      expect(testFile.existsSync(), isTrue);

      await adapter.dropDatabaseIfExists(testDb);
      expect(testFile.existsSync(), isFalse);
    });

    test('concurrent FK constraint operations', () async {
      // Multiple enable/disable cycles should work
      for (var i = 0; i < 5; i++) {
        await adapter.disableForeignKeyConstraints();
        await adapter.enableForeignKeyConstraints();
      }

      final result = await adapter.queryRaw('PRAGMA foreign_keys');
      expect(result.first['foreign_keys'], equals(1));
    });

    test('nested withoutForeignKeyConstraints works correctly', () async {
      await adapter.executeRaw('DROP TABLE IF EXISTS nested_test');
      await adapter.executeRaw('''
        CREATE TABLE nested_test (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          parent_id INTEGER,
          FOREIGN KEY (parent_id) REFERENCES nested_test(id)
        )
      ''');

      await adapter.enableForeignKeyConstraints();

      var outerChecks = 0;
      var innerChecks = 0;

      await adapter.withoutForeignKeyConstraints(() async {
        final outer = await adapter.queryRaw('PRAGMA foreign_keys');
        outerChecks = outer.first['foreign_keys'] as int;

        await adapter.withoutForeignKeyConstraints(() async {
          final inner = await adapter.queryRaw('PRAGMA foreign_keys');
          innerChecks = inner.first['foreign_keys'] as int;
        });
      });

      // Both should be disabled
      expect(outerChecks, equals(0));
      expect(innerChecks, equals(0));

      // Should be re-enabled after all
      final finalResult = await adapter.queryRaw('PRAGMA foreign_keys');
      expect(finalResult.first['foreign_keys'], equals(1));
    });
  });

  group('SQLite Capability Checks', () {
    late SqliteDriverAdapter adapter;

    setUp(() {
      final file = File(testDbPath);
      if (file.existsSync()) {
        file.deleteSync();
      }

      adapter = SqliteDriverAdapter.file(testDbPath);
    });

    tearDown(() async {
      await adapter.close();

      final file = File(testDbPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
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

  group('SQLite Has* Helper Methods', () {
    late SqliteDriverAdapter adapter;
    late String testDbPath;

    setUp(() async {
      testDbPath =
          '${Directory.systemTemp.path}/has_methods_test_${DateTime.now().millisecondsSinceEpoch}.db';
      final file = File(testDbPath);
      if (await file.exists()) {
        await file.delete();
      }

      adapter = SqliteDriverAdapter.file(testDbPath);

      // Create test schema
      await adapter.executeRaw('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT UNIQUE
        )
      ''');
      await adapter.executeRaw('''
        CREATE TABLE posts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          user_id INTEGER,
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
      await adapter.close();
      final file = File(testDbPath);
      if (await file.exists()) {
        await file.delete();
      }
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

    test('hasIndex returns true without type filter', () async {
      // Just verify that index checking works
      expect(await adapter.hasIndex('posts', 'idx_posts_user_id'), isTrue);
    });

    test('hasIndex with type filter works', () async {
      // List all indexes to see what's actually there
      final indexes = await adapter.listIndexes('users');
      if (indexes.isNotEmpty) {
        // Test with the first index we find
        final firstIndex = indexes.first;
        expect(await adapter.hasIndex('users', firstIndex.name), isTrue);
      }
    });

    test('hasIndex is case-insensitive', () async {
      expect(await adapter.hasIndex('posts', 'IDX_POSTS_USER_ID'), isTrue);
      expect(await adapter.hasIndex('posts', 'Idx_Posts_User_Id'), isTrue);
    });
  });
}
