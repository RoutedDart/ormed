import 'package:ormed_postgres/migrations.dart';
import 'package:ormed_postgres/ormed_postgres.dart' show PostgresSchemaDialect;
import 'package:test/test.dart';

void main() {
  group('Postgres migrations extensions', () {
    test('enableExtension emits CREATE EXTENSION statement', () {
      final builder = SchemaBuilder()..enableExtension('citext');
      final plan = builder.build();
      final dialect = PostgresSchemaDialect();
      final statements = plan.mutations
          .expand((m) => dialect.compileMutation(m))
          .toList(growable: false);
      expect(statements.single.sql, 'CREATE EXTENSION IF NOT EXISTS "citext"');
    });

    test('blueprint helpers compile to expected types', () {
      final builder = SchemaBuilder()
        ..create('t', (table) {
          table.inet('ip');
          table.cidr('subnet');
          table.macaddr('mac');
          table.tsvector('document');
          table.tsquery('query');
          table.interval('duration');
          table.int4range('r1');
          table.daterange('r2');
          table.tstzrange('r3');
          table.uuidArray('uuids');
        });

      final plan = builder.build();
      final dialect = PostgresSchemaDialect();
      final statements = plan.mutations
          .expand((m) => dialect.compileMutation(m))
          .toList(growable: false);

      final sql = statements.single.sql;
      expect(sql, contains('"ip" inet'));
      expect(sql, contains('"subnet" cidr'));
      expect(sql, contains('"mac" macaddr'));
      expect(sql, contains('"document" tsvector'));
      expect(sql, contains('"query" tsquery'));
      expect(sql, contains('"duration" interval'));
      expect(sql, contains('"r1" int4range'));
      expect(sql, contains('"r2" daterange'));
      expect(sql, contains('"r3" tstzrange'));
      expect(sql, contains('"uuids" uuid[]'));
    });
  });
}
