import 'dart:io';

import 'package:ormed/migrations.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  group('SqliteDriverAdapter schema stress', () {
    test('executes complex schema plans against a real database', () async {
      final tempDir = await Directory.systemTemp.createTemp('sqlite_stress');
      final dbPath = p.join(tempDir.path, 'stress.sqlite');

      final driver = SqliteDriverAdapter.file(dbPath);
      addTearDown(() async {
        await driver.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final schemaDriver = driver as SchemaDriver;

      final createBuilder = SchemaBuilder();
      createBuilder.create('libraries', (table) {
        table.useEngine('InnoDB');
        table.charset('utf8mb4');
        table.collation('utf8mb4_unicode_ci');
        table.setTableComment('System libraries');

        table.increments('id');
        table.string('code', length: 32).unique();
        table.longText('description').nullable();
        table.boolean('is_public').defaultValue(true);
        table.decimal('lat', precision: 10, scale: 6).nullable();
        table.decimal('lng', precision: 10, scale: 6).nullable();
        table.uuid('external_id');
        table.binary('logo').nullable();
        table.jsonb('metadata').nullable();
        table.enum_('status', ['draft', 'published']).defaultValue('draft');
        table.set('tags', ['fiction', 'biography', 'science']).nullable();
        table.timestamps(useCurrent: true);
        table.softDeletes();
        table.index(['code', 'is_public'], name: 'libraries_code_public_index');
      });

      createBuilder.create('books', (table) {
        table.increments('id');
        table.string('title');
        table.longText('body');
        table.foreignId('library_id', constrainedTable: 'libraries');
        table.integer('inventory').defaultExpression('0');
        table.boolean('featured').defaultValue(false);
        table.dateTimeTz('published_at').nullable();
        table.timestamp('archived_at').nullable();
        table.morphs('publishable');
        table.index([
          'library_id',
          'published_at',
        ], name: 'books_library_published_index');
      });

      await schemaDriver.applySchemaPlan(createBuilder.build());

      final inspector = sqlite.sqlite3.open(dbPath);
      addTearDown(inspector.dispose);

      final libraryColumns = inspector.select('PRAGMA table_info("libraries")');
      final libraryColumnNames = libraryColumns
          .map((row) => row['name'])
          .toList();
      expect(
        libraryColumnNames,
        containsAll([
          'code',
          'description',
          'is_public',
          'lat',
          'lng',
          'external_id',
          'metadata',
          'status',
          'tags',
          'deleted_at',
        ]),
      );

      final bookColumns = inspector.select('PRAGMA table_info("books")');
      final bookColumnNames = bookColumns.map((row) => row['name']).toList();
      expect(
        bookColumnNames,
        containsAll([
          'title',
          'body',
          'library_id',
          'inventory',
          'featured',
          'publishable_id',
          'publishable_type',
        ]),
      );

      final fkList = inspector.select('PRAGMA foreign_key_list("books")');
      expect(fkList, isNotEmpty);

      final alterBuilder = SchemaBuilder();
      alterBuilder.table('books', (table) {
        table.string('subtitle').nullable();
        table.dropColumn('body');
        table.renameColumn('title', 'headline');
        table.index([
          'headline',
          'library_id',
        ], name: 'books_headline_library_index');
        table.dropIndex('books_library_published_index');
      });
      alterBuilder.table('libraries', (table) {
        table.dropColumn('logo');
      });
      alterBuilder.rename('libraries', 'archives');
      alterBuilder.raw('PRAGMA user_version = 2');
      await schemaDriver.applySchemaPlan(alterBuilder.build());

      final renamedLibraries = inspector.select(
        "SELECT name FROM sqlite_master WHERE name = 'archives'",
      );
      expect(renamedLibraries, isNotEmpty);

      final updatedBookColumns = inspector.select('PRAGMA table_info("books")');
      final updatedColumnNames = updatedBookColumns
          .map((row) => row['name'])
          .toList();
      expect(updatedColumnNames, containsAll(['headline', 'subtitle']));
      expect(updatedColumnNames, isNot(contains('body')));

      final indexes = inspector.select(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'books'",
      );
      final indexNames = indexes.map((row) => row['name']).toList();
      expect(indexNames, contains('books_headline_library_index'));
      expect(indexNames, isNot(contains('books_library_published_index')));

      final userVersion = inspector.select('PRAGMA user_version');
      expect(userVersion.single['user_version'], 2);

      final dropBuilder = SchemaBuilder();
      dropBuilder.drop('books', ifExists: true);
      dropBuilder.drop('archives', ifExists: true);
      await schemaDriver.applySchemaPlan(dropBuilder.build());

      expect(
        inspector.select("SELECT name FROM sqlite_master WHERE name = 'books'"),
        isEmpty,
      );
      expect(
        inspector.select(
          "SELECT name FROM sqlite_master WHERE name = 'archives'",
        ),
        isEmpty,
      );
    });

    test('renames tables and rebuilds composite indexes', () async {
      final tempDir = await Directory.systemTemp.createTemp('sqlite_schema');
      final dbPath = p.join(tempDir.path, 'rename.sqlite');

      final driver = SqliteDriverAdapter.file(dbPath);
      addTearDown(() async {
        await driver.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final schemaDriver = driver as SchemaDriver;

      final createBuilder = SchemaBuilder()
        ..create('projects', (table) {
          table.increments('id');
          table.string('code');
          table.integer('owner_id');
          table.unique([
            'code',
            'owner_id',
          ], name: 'projects_code_owner_unique');
          table.index(['owner_id', 'code'], name: 'projects_owner_code_index');
        });
      await schemaDriver.applySchemaPlan(createBuilder.build());

      final inspector = sqlite.sqlite3.open(dbPath);
      addTearDown(inspector.dispose);

      final originalIndexes = inspector.select(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'projects'",
      );
      expect(
        originalIndexes.map((row) => row['name']),
        contains('projects_owner_code_index'),
      );

      final alterBuilder = SchemaBuilder()
        ..table('projects', (table) {
          table.renameColumn('owner_id', 'user_id');
          table.dropIndex('projects_owner_code_index');
          table.index(['user_id', 'code'], name: 'projects_user_code_index');
        })
        ..rename('projects', 'team_projects');
      await schemaDriver.applySchemaPlan(alterBuilder.build());

      final renamedIndexes = inspector.select(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'team_projects'",
      );
      final indexNames = renamedIndexes
          .map((row) => row['name'])
          .cast<String>()
          .toList();
      expect(indexNames, contains('projects_user_code_index'));
      expect(indexNames, isNot(contains('projects_owner_code_index')));

      final renamedTable = inspector.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'team_projects'",
      );
      expect(renamedTable, isNotEmpty);

      final dropBuilder = SchemaBuilder()
        ..drop('team_projects', ifExists: true);
      await schemaDriver.applySchemaPlan(dropBuilder.build());
      final remaining = inspector.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'team_projects'",
      );
      expect(remaining, isEmpty);
    });
  });
}
