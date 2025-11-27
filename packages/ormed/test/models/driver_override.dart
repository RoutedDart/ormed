import 'package:ormed/ormed.dart';

part 'driver_override.orm.dart';

@OrmModel(table: 'driver_overrides')
class DriverOverrideModel {
  const DriverOverrideModel({required this.id, required this.payload});

  @OrmField(isPrimaryKey: true)
  final int id;

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
