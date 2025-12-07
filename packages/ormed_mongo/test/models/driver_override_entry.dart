import 'package:driver_tests/src/driver_override_codecs.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:ormed/ormed.dart';

part 'driver_override_entry.orm.dart';

@OrmModel(table: 'driver_override_entries')
class DriverOverrideEntry extends Model<DriverOverrideEntry>
    with ModelFactoryCapable {
  const DriverOverrideEntry({this.id, required this.payload});

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
