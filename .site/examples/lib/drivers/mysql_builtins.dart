// MySQL / MariaDB built-in type snippets.
// ignore_for_file: unused_local_variable

import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:uuid/uuid_value.dart';

// #region mysql-builtins-values
final uuid = UuidValue.fromString('00000000-0000-0000-0000-000000000000');
final amount = Decimal.parse('12.34');
final duration = const Duration(hours: 1, minutes: 2, seconds: 3);
final tags = <String>{'alpha', 'beta'};
final bits = MySqlBitString.parse('1010');
final geometry = MySqlGeometry.fromHex(
  '000000000101000000000000000000F03F0000000000000040',
);
final payload = Uint8List.fromList([1, 2, 3, 4]);
// #endregion mysql-builtins-values

// #region mysql-builtins-migration
class CreateMysqlBuiltinsTable extends Migration {
  const CreateMysqlBuiltinsTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('mysql_builtins', (table) {
      table.id();
      table.decimal('amount', precision: 18, scale: 6);
      table.column(
        'time_value',
        const ColumnType(ColumnTypeName.time, precision: 6),
      );
      table.uuid('uuid_value');
      table.set('tags', ['alpha', 'beta', 'gamma']);
      table.column('bit_value', const ColumnType.custom('BIT(4)')).nullable();
      table.geometry('geom').nullable();
      table.binary('payload');
      table.json('document').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('mysql_builtins', ifExists: true, cascade: true);
  }
}
// #endregion mysql-builtins-migration
