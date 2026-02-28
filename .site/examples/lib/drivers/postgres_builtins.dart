// PostgreSQL built-in type snippets.
// ignore_for_file: unused_local_variable

import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/migrations.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:uuid/uuid_value.dart';

// #region postgres-builtins-values
final uuid = UuidValue.fromString('00000000-0000-0000-0000-000000000000');
final amount = Decimal.parse('12.34');
final money = const PgMoney.fromCents(1234);
final bits = PgBitString.parse('10101010');
final timeTz = PgTimeTz(time: Time(1, 2, 3), offset: const Duration(hours: 4));
final lsn = LSN.fromString('0/10');
final snapshot = const PgSnapshot(xmin: 1, xmax: 10, xip: [2, 3]);
final location = const Point(1.5, 2.5);
final payload = Uint8List.fromList([1, 2, 3, 4]);
// #endregion postgres-builtins-values

// #region postgres-builtins-migration
class CreateHostsTable extends Migration {
  const CreateHostsTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('hosts', (table) {
      table.inet('ip');
      table.cidr('subnet');
      table.macaddr('mac');
      table.bit('flags', length: 8);
      table.varbit('tag_bits');
      table.money('balance');
      table.timetz('local_time');
      table.pgLsn('lsn');
      table.pgSnapshot('snapshot');
      table.point('location');
      table.binary('payload');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('hosts', ifExists: true, cascade: true);
  }
}
// #endregion postgres-builtins-migration
