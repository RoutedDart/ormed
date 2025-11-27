import 'package:ormed/migrations.dart';
import 'package:ormed_sqlite/src/sqlite_schema_dialect.dart';
import 'package:test/test.dart';

void main() {
  final compiler = SchemaPlanCompiler(const SqliteSchemaDialect());

  test('ignores overrides targeting other drivers', () {
    final builder = SchemaBuilder();
    builder.create('profiles', (table) {
      table.json('prefs').driverSqlType('postgres', 'JSONB');
    });

    final sql = compiler.compile(builder.build()).statements.first.sql;
    expect(sql, contains('"prefs" TEXT'));
    expect(sql, isNot(contains('JSONB')));
  });

  test('creates table and indexes', () {
    final builder = SchemaBuilder();
    builder.create('users', (table) {
      table.increments('id');
      table.string('email').unique();
      table.boolean('is_admin').defaultValue(false);
    });

    final preview = compiler.compile(builder.build());
    expect(preview.statements, isNotEmpty);
    expect(preview.statements.first.sql, contains('CREATE TABLE "users"'));
    expect(preview.statements.first.sql, contains('UNIQUE'));
  });

  test('complex schema regression: create relationships', () {
    final builder = SchemaBuilder();
    builder.create('users', (table) {
      table.increments('id');
      table.string('name');
      table.string('email').unique();
      table.boolean('is_admin').defaultValue(false);
      table.timestamp('created_at');
      table.timestamp('updated_at');
    });

    builder.create('posts', (table) {
      table.increments('id');
      table.string('title');
      table.text('body');
      table.integer('user_id');
      table.timestamp('published_at').nullable();
      table.foreign(
        ['user_id'],
        references: 'users',
        referencedColumns: ['id'],
        onDelete: ReferenceAction.cascade,
      );
    });

    final preview = compiler.compile(builder.build());
    final sql = preview.statements.map((s) => s.sql).join('\n');
    expect(
      sql,
      contains(
        'FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE',
      ),
    );
    expect(sql, contains('"body" TEXT NOT NULL'));
  });

  test('alter schema regression', () {
    final builder = SchemaBuilder();
    builder.table('users', (table) {
      table.string('nickname');
      table.renameColumn('email', 'primary_email');
      table.unique(['primary_email'], name: 'users_primary_email_unique');
    });
    builder.raw('VACUUM');

    final statements = compiler.compile(builder.build()).statements;
    expect(statements.first.sql, contains('ADD COLUMN "nickname"'));
    expect(
      statements.map((s) => s.sql).join(' ; '),
      contains('CREATE UNIQUE INDEX "users_primary_email_unique"'),
    );
    expect(statements.last.sql, equals('VACUUM'));
  });

  test('supports composite primary keys and foreign key options', () {
    final builder = SchemaBuilder();
    builder.create('members', (table) {
      table.integer('team_id');
      table.integer('user_id');
      table.primary(['team_id', 'user_id'], name: 'members_team_user_primary');
      table.foreign(
        ['team_id'],
        references: 'teams',
        referencedColumns: ['id'],
        onDelete: ReferenceAction.restrict,
        onUpdate: ReferenceAction.cascade,
      );
    });

    final sql = compiler.compile(builder.build()).statements.first.sql;
    expect(sql, contains('PRIMARY KEY ("team_id", "user_id")'));
    expect(
      sql,
      contains(
        'FOREIGN KEY ("team_id") REFERENCES "teams" ("id") ON DELETE RESTRICT ON UPDATE CASCADE',
      ),
    );
  });

  test('drop table cascade omits unsupported syntax', () {
    final builder = SchemaBuilder();
    builder.drop('widgets', ifExists: true, cascade: true);
    final statement = compiler.compile(builder.build()).statements.single.sql;
    expect(statement, equals('DROP TABLE IF EXISTS "widgets"'));
  });

  test('drop index generates IF EXISTS clause', () {
    final builder = SchemaBuilder();
    builder.table('users', (table) {
      table.dropIndex('users_email_index');
    });
    final statements = compiler.compile(builder.build()).statements;
    expect(
      statements.first.sql,
      equals('DROP INDEX IF EXISTS "users_email_index"'),
    );
  });

  test('rename table and columns emit explicit statements', () {
    final builder = SchemaBuilder();
    builder.table('files', (table) {
      table.renameColumn('path', 'full_path');
    });
    builder.rename('files', 'documents');

    final statements = compiler.compile(builder.build()).statements;
    expect(
      statements.first.sql,
      equals('ALTER TABLE "files" RENAME COLUMN "path" TO "full_path"'),
    );
    expect(
      statements.last.sql,
      equals('ALTER TABLE "files" RENAME TO "documents"'),
    );
  });

  test('schema plan compiler covers composite indexes, FKs, and renames', () {
    final builder = SchemaBuilder();
    builder.create('teams', (table) {
      table.increments('id');
      table.string('name');
      table.unique(['name'], name: 'teams_name_unique');
    });
    builder.create('members', (table) {
      table.integer('team_id');
      table.integer('user_id');
      table.string('role').defaultValue('member');
      table.primary(['team_id', 'user_id'], name: 'members_primary');
      table.index(['team_id', 'user_id'], name: 'members_team_user_index');
      table.foreign(
        ['team_id'],
        references: 'teams',
        referencedColumns: ['id'],
        onDelete: ReferenceAction.cascade,
        onUpdate: ReferenceAction.restrict,
      );
    });
    builder.table('members', (table) {
      table.renameColumn('team_id', 'group_id');
      table.index(['group_id', 'user_id'], name: 'members_group_user_index');
      table.dropIndex('members_team_user_index');
    });
    builder.rename('members', 'group_members');
    builder.drop('group_members', ifExists: true);

    final preview = compiler.compile(builder.build());
    final sql = preview.statements.map((s) => s.sql).join('\n');

    expect(sql, contains('FOREIGN KEY ("team_id") REFERENCES "teams" ("id")'));
    expect(
      sql,
      contains(
        'CREATE INDEX "members_team_user_index" ON "members" ("team_id", "user_id")',
      ),
    );
    expect(
      sql,
      contains(
        'CREATE INDEX "members_group_user_index" ON "members" ("group_id", "user_id")',
      ),
    );
    expect(
      sql,
      contains('ALTER TABLE "members" RENAME COLUMN "team_id" TO "group_id"'),
    );
    expect(sql, contains('ALTER TABLE "members" RENAME TO "group_members"'));
    expect(sql, contains('DROP TABLE IF EXISTS "group_members"'));
  });

  test('new fluent helpers compile into sqlite SQL', () {
    final builder = SchemaBuilder();
    builder.create('devices', (table) {
      table.ulid('device_ulid');
      table.char('code', length: 8);
      table.tinyText('notes');
      table.geometry('location');
      table.geography('region');
      table.vector('embedding', dimensions: 3);
      table.point('position');
      table.multiPolygon('regions');
      table.geometryCollection('shapes');
      table.double('min_lat');
      table.double('max_lat');
      table.double('min_lng');
      table.double('max_lng');
      table.computed('code_slug', 'lower(code)');
      table.year('model_year');
      table.ipAddress();
      table.macAddress();
      table.unsignedBigInteger('owner_id');
      table
          .foreign(['owner_id'], references: 'users', referencedColumns: ['id'])
          .onDelete(ReferenceAction.cascade);
      table.rememberToken();
      table.timestamps(nullable: true);
      table.nullableTimestamps();
      table.datetimes();
      table.fullText(
        ['notes'],
        name: 'devices_notes_fulltext',
        sqlite: const SqliteFullTextOptions(
          tokenizer: 'unicode61',
          prefixSizes: [2, 3],
        ),
      );
      table.spatialIndex(['location'], name: 'devices_location_spatial');
      table.spatialIndex(
        ['min_lat', 'max_lat', 'min_lng', 'max_lng'],
        name: 'devices_bounds_spatial',
        sqlite: const SqliteSpatialIndexOptions(maintainSync: false),
      );
      table.rawIndex('lower(code)', name: 'devices_code_lower_index');
    });

    final preview = compiler.compile(builder.build());
    final sql = preview.statements.first.sql;
    final indexSql = preview.statements.map((s) => s.sql).join('\n');
    expect(sql, contains('"device_ulid" VARCHAR(26)'));
    expect(sql, contains('"code" VARCHAR(8)'));
    expect(sql, contains('"location" TEXT'));
    expect(sql, contains('"region" TEXT'));
    expect(sql, contains('"embedding" TEXT'));
    expect(sql, contains('GENERATED ALWAYS AS (lower(code)) VIRTUAL'));
    expect(sql, contains('"embedding" TEXT'));
    expect(sql, contains('"position" POINT'));
    expect(sql, contains('"regions" MULTIPOLYGON'));
    expect(sql, contains('"shapes" GEOMETRYCOLLECTION'));
    expect(sql, contains('"owner_id" INTEGER'));
    expect(
      sql,
      contains(
        'FOREIGN KEY ("owner_id") REFERENCES "users" ("id") ON DELETE CASCADE',
      ),
    );
    expect(sql, contains('"remember_token" VARCHAR(100)'));
    expect(
      indexSql,
      contains(
        'CREATE VIRTUAL TABLE "devices_devices_notes_fulltext_fts" USING fts5',
      ),
    );
    expect(indexSql, contains('tokenize=unicode61'));
    expect(indexSql, contains("prefix='2 3'"));
    expect(
      indexSql,
      contains(
        'CREATE VIRTUAL TABLE "devices_devices_location_spatial_rtree" USING rtree',
      ),
    );
    expect(
      indexSql,
      contains(
        'CREATE VIRTUAL TABLE "devices_devices_bounds_spatial_rtree" USING rtree',
      ),
    );
    expect(
      indexSql,
      isNot(contains('devices_devices_bounds_spatial_rtree_ai')),
    );
    expect(indexSql, contains('lower(code)'));
  });
}
