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
          table.bit('bits', length: 8);
          table.varbit('varbits');
          table.timetz('tz_time');
          table.money('cash');
          table.pgLsn('lsn');
          table.pgSnapshot('snap');
          table.txidSnapshot('tx_snap');
          table.xml('payload');
          table.line('l');
          table.lseg('s');
          table.box('b');
          table.path('p');
          table.circle('c');
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
      expect(sql, contains('"bits" bit(8)'));
      expect(sql, contains('"varbits" varbit'));
      expect(sql, contains('"tz_time" timetz'));
      expect(sql, contains('"cash" money'));
      expect(sql, contains('"lsn" pg_lsn'));
      expect(sql, contains('"snap" pg_snapshot'));
      expect(sql, contains('"tx_snap" txid_snapshot'));
      expect(sql, contains('"payload" xml'));
      expect(sql, contains('"l" line'));
      expect(sql, contains('"s" lseg'));
      expect(sql, contains('"b" box'));
      expect(sql, contains('"p" path'));
      expect(sql, contains('"c" circle'));
    });
  });
}
