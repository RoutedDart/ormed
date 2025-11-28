import 'package:ormed/ormed.dart';

part 'driver_override_entry.orm.dart';

@OrmModel(table: 'settings')
class DriverOverrideEntry extends Model<DriverOverrideEntry>
    with ModelFactoryCapable {
  const DriverOverrideEntry({required this.id, required this.payload});

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
