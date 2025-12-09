import 'package:ormed/migrations.dart';
import 'package:test/test.dart';

import 'package:ormed_mysql/src/mysql_schema_dialect.dart';

void main() {
  final compiler = SchemaPlanCompiler(
    const MySqlSchemaDialect(isMariaDb: true),
  );

  test('new fluent helpers compile into mariadb SQL', () {
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
      table.softDeletes();
      table.fullText(['notes'], name: 'devices_notes_fulltext');
      table.spatialIndex(['location'], name: 'devices_location_spatial');
      table.rawIndex('lower(code)', name: 'devices_code_lower_index');
    });

    final preview = compiler.compile(builder.build());
    final sql = preview.statements.first.sql;
    final indexSql = preview.statements.map((s) => s.sql).join('\n');
    expect(sql, contains('`device_ulid` VARCHAR(26)'));
    expect(sql, contains('`code` VARCHAR(8)'));
    expect(sql, contains('`location` GEOMETRY'));
    expect(sql, contains('`region` GEOMETRY'));
    expect(sql, contains('`embedding` JSON'));
    expect(sql, contains('`position` POINT'));
    expect(sql, contains('`regions` MULTIPOLYGON'));
    expect(sql, contains('`shapes` GEOMETRYCOLLECTION'));
    expect(sql, contains('GENERATED AS (lower(code)) VIRTUAL'));
    expect(sql, contains('`owner_id` BIGINT UNSIGNED'));
    expect(sql, contains('`remember_token` VARCHAR(100)'));
    expect(sql, contains('`deleted_at` DATETIME(3)'));
    expect(
      sql,
      contains(
        'FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE',
      ),
    );
    expect(
      indexSql,
      contains('CREATE FULLTEXT INDEX `devices_notes_fulltext`'),
    );
    expect(
      indexSql,
      contains('CREATE SPATIAL INDEX `devices_location_spatial`'),
    );
    expect(indexSql, contains('lower(code)'));
  });
}
