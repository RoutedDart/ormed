import 'package:driver_tests/src/driver_override_codecs.dart';
import 'package:ormed/ormed.dart';

part 'driver_override_entry.orm.dart';

@OrmModel(table: 'driver_override_entries')
class DriverOverrideEntry extends Model<DriverOverrideEntry>
    with ModelFactoryCapable {
  const DriverOverrideEntry({required this.id, required this.payload});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
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
      'mysql': OrmDriverFieldOverride(
        columnType: 'JSON',
        codec: MariaDbPayloadCodec,
      ),
      'mariadb': OrmDriverFieldOverride(
        columnType: 'JSON',
        codec: MariaDbPayloadCodec,
      ),
    },
  )
  final Map<String, Object?> payload;
}
