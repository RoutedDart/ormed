import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';

void main() {
  group('Postgres schema integration', () {
    late DataSource dataSource;
    late PostgresDriverAdapter driverAdapter;
    late String testSchema;

    setUpAll(() async {
      final url =
          OrmedEnvironment().firstNonEmpty(['POSTGRES_URL']) ??
          'postgres://postgres:postgres@localhost:6543/orm_test';

      driverAdapter = PostgresDriverAdapter.custom(
        config: DatabaseConfig(driver: 'postgres', options: {'url': url}),
      );

      driverAdapter.codecs
        ..registerCodecFor(PostgresPayloadCodec, const PostgresPayloadCodec())
        ..registerCodecFor(SqlitePayloadCodec, const SqlitePayloadCodec());

      dataSource = DataSource(
        DataSourceOptions(
          driver: driverAdapter,
          entities: generatedOrmModelDefinitions,
        ),
      );

      await dataSource.init();
      registerOrmFactories();

      // Create a unique schema for this test run
      testSchema = 'test_schema_${DateTime.now().millisecondsSinceEpoch}';
      await driverAdapter.executeRaw(
        'CREATE SCHEMA IF NOT EXISTS "$testSchema"',
      );
      await driverAdapter.executeRaw(
        'SET search_path TO "$testSchema", public',
      );
    });

    tearDownAll(() async {
      await driverAdapter.executeRaw(
        'DROP SCHEMA IF EXISTS "$testSchema" CASCADE',
      );
      await dataSource.dispose();
    });

    test('applies complex schema plans against a real database', () async {
      final schemaDriver = driverAdapter as SchemaDriver;

      final createLibraries = SchemaBuilder()
        ..create('libraries', (table) {
          table.increments('id');
          table.primary(['id'], name: 'libraries_pkey');
          table.string('code', length: 64).unique();
          table.longText('description').nullable();
          table.boolean('is_public').defaultValue(true);
          table.decimal('lat', precision: 10, scale: 6).nullable();
          table.decimal('lng', precision: 10, scale: 6).nullable();
          table.uuid('external_id');
          table.jsonb('metadata').nullable();
          table.enum_('status', ['draft', 'published']).defaultValue('draft');
          table.timestamps(useCurrent: true);
          table.softDeletes();
          table.index([
            'code',
            'is_public',
          ], name: 'libraries_code_public_index');
        });
      await schemaDriver.applySchemaPlan(createLibraries.build());

      final createBooks = SchemaBuilder()
        ..create('books', (table) {
          table.increments('id');
          table.string('title');
          table.text('body');
          table.integer('library_id');
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
      await schemaDriver.applySchemaPlan(createBooks.build());

      final addForeignKeys = SchemaBuilder()
        ..table('books', (table) {
          table.foreign(
            ['library_id'],
            references: 'libraries',
            referencedColumns: ['id'],
            onDelete: ReferenceAction.restrict,
            onUpdate: ReferenceAction.cascade,
          );
        });
      await schemaDriver.applySchemaPlan(addForeignKeys.build());

      Future<List<Map<String, Object?>>> columnsFor(String table) {
        return driverAdapter.queryRaw(
          'SELECT column_name FROM information_schema.columns'
          ' WHERE table_schema = ? AND table_name = ? ORDER BY ordinal_position',
          [testSchema, table],
        );
      }

      final libraryColumns = await columnsFor('libraries');
      final libraryColumnNames = libraryColumns
          .map((row) => row['column_name'] as String)
          .toList();
      expect(
        libraryColumnNames,
        containsAll([
          'code',
          'description',
          'is_public',
          'metadata',
          'status',
          'deleted_at',
        ]),
      );

      final bookColumns = await columnsFor('books');
      final bookColumnNames = bookColumns
          .map((row) => row['column_name'] as String)
          .toList();
      expect(
        bookColumnNames,
        containsAll([
          'title',
          'body',
          'library_id',
          'publishable_id',
          'publishable_type',
        ]),
      );

      final bookConstraints = await driverAdapter.queryRaw(
        'SELECT constraint_name, constraint_type '
        'FROM information_schema.table_constraints '
        'WHERE table_schema = ? AND table_name = ? AND constraint_type = ?',
        [testSchema, 'books', 'FOREIGN KEY'],
      );
      expect(bookConstraints, isNotEmpty);

      final indexes = await driverAdapter.queryRaw(
        'SELECT indexname FROM pg_indexes WHERE schemaname = ? AND tablename = ?',
        [testSchema, 'books'],
      );
      final indexNames = indexes
          .map((row) => row['indexname'])
          .cast<String>()
          .toList();
      expect(indexNames, contains('books_library_published_index'));

      final alterBuilder = SchemaBuilder();
      alterBuilder.table('books', (table) {
        table.string('subtitle').nullable();
        table.renameColumn('title', 'headline');
        table.dropColumn('body');
        table.index([
          'headline',
          'library_id',
        ], name: 'books_headline_library_index');
        table.dropIndex('books_library_published_index');
      });
      alterBuilder.table('libraries', (table) {
        table.dropColumn('metadata');
      });
      alterBuilder.rename('libraries', 'archives');
      await schemaDriver.applySchemaPlan(alterBuilder.build());

      final renamedColumns = await columnsFor('books');
      final renamedNames = renamedColumns
          .map((row) => row['column_name'] as String)
          .toList();
      expect(renamedNames, containsAll(['headline', 'subtitle']));
      expect(renamedNames, isNot(contains('body')));

      final renamedTableColumns = await driverAdapter.queryRaw(
        'SELECT table_name FROM information_schema.tables WHERE table_schema = ? AND table_name = ?',
        [testSchema, 'archives'],
      );
      expect(renamedTableColumns, isNotEmpty);

      final newIndexes = await driverAdapter.queryRaw(
        'SELECT indexname FROM pg_indexes WHERE schemaname = ? AND tablename = ?',
        [testSchema, 'books'],
      );
      final newIndexNames = newIndexes
          .map((row) => row['indexname'])
          .cast<String>()
          .toList();
      expect(newIndexNames, contains('books_headline_library_index'));
      expect(newIndexNames, isNot(contains('books_library_published_index')));

      final dropBuilder = SchemaBuilder();
      dropBuilder.drop('books', ifExists: true);
      dropBuilder.drop('archives', ifExists: true, cascade: true);
      await schemaDriver.applySchemaPlan(dropBuilder.build());

      final remaining = await driverAdapter.queryRaw(
        'SELECT table_name FROM information_schema.tables '
        'WHERE table_schema = ? AND table_name IN (?, ?)',
        [testSchema, 'books', 'archives'],
      );
      expect(remaining, isEmpty);
    });

    test('drops foreign keys and indexes using schema driver', () async {
      final schemaDriver = driverAdapter as SchemaDriver;

      final createBuilder = SchemaBuilder()
        ..create('customers', (table) {
          table.increments('id');
          table.primary(['id'], name: 'customers_pkey');
          table.string('email').unique();
        })
        ..create('orders', (table) {
          table.increments('id');
          table.integer('customer_id');
          table.index(['customer_id'], name: 'orders_customer_index');
        })
        ..table('orders', (table) {
          table.foreign(
            ['customer_id'],
            references: 'customers',
            referencedColumns: ['id'],
            onDelete: ReferenceAction.cascade,
          );
        });
      await schemaDriver.applySchemaPlan(createBuilder.build());

      final fkBefore = await driverAdapter.queryRaw(
        'SELECT constraint_name FROM information_schema.table_constraints '
        'WHERE table_schema = ? AND table_name = ? AND constraint_type = ? AND constraint_name = ?',
        [testSchema, 'orders', 'FOREIGN KEY', 'orders_customer_id_foreign'],
      );
      expect(fkBefore, isNotEmpty);

      final dropBuilder = SchemaBuilder()
        ..table('orders', (table) {
          table.dropForeign('orders_customer_id_foreign');
          table.dropIndex('orders_customer_index');
        });
      await schemaDriver.applySchemaPlan(dropBuilder.build());

      final fkAfter = await driverAdapter.queryRaw(
        'SELECT constraint_name FROM information_schema.table_constraints '
        'WHERE table_schema = ? AND table_name = ? AND constraint_type = ? AND constraint_name = ?',
        [testSchema, 'orders', 'FOREIGN KEY', 'orders_customer_id_foreign'],
      );
      expect(fkAfter, isEmpty);

      final indexAfter = await driverAdapter.queryRaw(
        'SELECT indexname FROM pg_indexes WHERE schemaname = ? AND tablename = ? AND indexname = ?',
        [testSchema, 'orders', 'orders_customer_index'],
      );
      expect(indexAfter, isEmpty);

      final dropTables = SchemaBuilder()
        ..drop('orders', ifExists: true)
        ..drop('customers', ifExists: true, cascade: true);
      await schemaDriver.applySchemaPlan(dropTables.build());
    });

    test('exposes live metadata through the schema inspector', () async {
      final schemaDriver = driverAdapter as SchemaDriver;
      final builder = SchemaBuilder()
        ..create('libraries', (table) {
          table.increments('id');
          table.primary(['id']);
          table.string('code').unique();
          table.boolean('is_public').defaultValue(true);
        })
        ..create('books', (table) {
          table.increments('id');
          table.primary(['id']);
          table.string('title');
          table.integer('library_id');
          table.boolean('featured').defaultValue(false);
          table.index([
            'library_id',
            'featured',
          ], name: 'books_library_featured_index');
          table.foreign(
            ['library_id'],
            references: 'libraries',
            referencedColumns: ['id'],
            onDelete: ReferenceAction.cascade,
          );
        });
      await schemaDriver.applySchemaPlan(builder.build());
      await driverAdapter.executeRaw(
        'CREATE VIEW "$testSchema".recent_books AS '
        'SELECT title FROM "$testSchema".books WHERE featured = true',
      );

      final inspector = SchemaInspector(schemaDriver);
      expect(await inspector.hasTable('libraries', schema: testSchema), isTrue);
      expect(
        await inspector.hasColumn('books', 'library_id', schema: testSchema),
        isTrue,
      );
      expect(
        await inspector.columnType('books', 'featured', schema: testSchema),
        equals('boolean'),
      );

      final schemas = await schemaDriver.listSchemas();
      expect(schemas.map((schema) => schema.name), contains(testSchema));

      final tables = await schemaDriver.listTables(schema: testSchema);
      expect(
        tables.map((table) => table.name),
        containsAll(['libraries', 'books']),
      );

      final columns = await schemaDriver.listColumns(
        'books',
        schema: testSchema,
      );
      final idColumn = columns.firstWhere((column) => column.name == 'id');
      expect(idColumn.primaryKey, isTrue);
      expect(idColumn.autoIncrement, isTrue);

      final indexes = await schemaDriver.listIndexes(
        'books',
        schema: testSchema,
      );
      expect(
        indexes.map((index) => index.name),
        contains('books_library_featured_index'),
      );

      final foreignKeys = await schemaDriver.listForeignKeys(
        'books',
        schema: testSchema,
      );
      expect(foreignKeys, isNotEmpty);
      expect(foreignKeys.first.referencedTable, equals('libraries'));

      final views = await schemaDriver.listViews(schema: testSchema);
      final recentBooks = views.firstWhere(
        (view) => view.name == 'recent_books',
      );
      expect(recentBooks.definition, contains('SELECT title'));

      await driverAdapter.executeRaw(
        'DROP VIEW IF EXISTS "$testSchema".recent_books',
      );

      final drop = SchemaBuilder()
        ..drop('books', ifExists: true)
        ..drop('libraries', ifExists: true);
      await schemaDriver.applySchemaPlan(drop.build());
    });
  });
}
