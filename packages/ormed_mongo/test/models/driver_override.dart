import 'package:driver_tests/driver_tests.dart' show PostgresPayloadCodec, SqlitePayloadCodec;
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:ormed/ormed.dart';

part 'driver_override.orm.dart';

@OrmModel(table: 'driver_overrides')
class DriverOverrideModel {
  const DriverOverrideModel({this.id, required this.payload});

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final ObjectId? id;

  @OrmField(
    columnType: 'TEXT',
    driverOverrides: {
      'postgres': OrmDriverFieldOverride(
        columnType: 'jsonb',
        codec: PostgresPayloadCodec,
      ),
      'sqlite': OrmDriverFieldOverride(
        columnType: 'TEXT',
        codec: SqlitePayloadCodec,
      ),
    },
  )
  final Map<String, Object?> payload;
}
