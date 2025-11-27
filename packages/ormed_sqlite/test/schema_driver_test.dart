import 'package:ormed/migrations.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteDriverAdapter schema integration', () {
    test('applies schema plan to create and drop tables', () async {
      final driver = SqliteDriverAdapter.inMemory();
      addTearDown(driver.close);
      final schemaDriver = driver as SchemaDriver;

      final createBuilder = SchemaBuilder();
      createBuilder.create('todos', (table) {
        table.increments('id');
        table.string('title');
      });

      await schemaDriver.applySchemaPlan(createBuilder.build());

      // Should be able to insert rows into the newly created table.
      await driver.executeRaw(
        'INSERT INTO "todos" ("id", "title") VALUES (?, ?)',
        [1, 'first task'],
      );

      final dropBuilder = SchemaBuilder();
      dropBuilder.drop('todos', ifExists: true);
      await schemaDriver.applySchemaPlan(dropBuilder.build());

      await expectLater(
        driver.executeRaw('INSERT INTO "todos" ("id", "title") VALUES (?, ?)', [
          2,
          'should fail',
        ]),
        throwsA(isA<Exception>()),
      );
    });

    test('exposes schema metadata via inspector helpers', () async {
      final driver = SqliteDriverAdapter.inMemory();
      addTearDown(driver.close);
      final schemaDriver = driver as SchemaDriver;
      final builder = SchemaBuilder()
        ..create('authors', (table) {
          table.increments('id');
          table.string('name');
          table.unique(['name'], name: 'authors_name_unique');
        })
        ..create('books', (table) {
          table.increments('id');
          table.string('title');
          table.integer('author_id');
          table.index(['title'], name: 'books_title_index');
          table.foreign(
            ['author_id'],
            references: 'authors',
            referencedColumns: ['id'],
            onDelete: ReferenceAction.cascade,
          );
        });
      await schemaDriver.applySchemaPlan(builder.build());
      await driver.executeRaw(
        'CREATE VIEW recent_books AS SELECT title FROM books',
      );

      final inspector = SchemaInspector(schemaDriver);
      expect(await inspector.hasTable('authors'), isTrue);
      expect(await inspector.hasColumn('books', 'author_id'), isTrue);
      expect(
        await inspector.columnType('books', 'title'),
        equals('VARCHAR(255)'),
      );

      final tables = await schemaDriver.listTables();
      expect(
        tables.map((table) => table.name),
        containsAll(['authors', 'books']),
      );

      final views = await schemaDriver.listViews();
      expect(views.map((view) => view.name), contains('recent_books'));

      final columns = await schemaDriver.listColumns('books');
      final titleColumn = columns.firstWhere((c) => c.name == 'title');
      expect(titleColumn.nullable, isFalse);
      expect(titleColumn.dataType, equals('VARCHAR(255)'));

      final indexes = await schemaDriver.listIndexes('books');
      expect(indexes.map((index) => index.name), contains('books_title_index'));
      final uniqueIndexes = await schemaDriver.listIndexes('authors');
      final authorsUnique = uniqueIndexes.firstWhere(
        (index) => index.name == 'authors_name_unique',
      );
      expect(authorsUnique.unique, isTrue);

      final foreignKeys = await schemaDriver.listForeignKeys('books');
      expect(foreignKeys, isNotEmpty);
      final fk = foreignKeys.first;
      expect(fk.referencedTable, equals('authors'));
      expect(fk.columns, equals(['author_id']));

      final schemas = await schemaDriver.listSchemas();
      expect(schemas.map((schema) => schema.name), contains('main'));

      final listing = await SchemaInspector(schemaDriver).tableListing();
      expect(listing, containsAll(['authors', 'books']));
    });
  });
}
