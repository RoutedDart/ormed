// Examples for casting documentation.
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

part 'casting_examples.orm.dart';

// #region casts-model-level
@OrmModel(
  table: 'settings',
  casts: {
    // Stored as JSON string, read as Map<String, Object?>
    'metadata': 'json',
    // Stored/read as DateTime (or parsed from ISO-8601 string)
    'createdAt': 'datetime',
  },
)
class Settings extends Model<Settings> {
  const Settings({required this.id, this.metadata, this.createdAt});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final Map<String, Object?>? metadata;
  final DateTime? createdAt;
}
// #endregion casts-model-level

// #region casts-field-level
@OrmModel(table: 'field_cast_settings')
class FieldCastSettings extends Model<FieldCastSettings> {
  const FieldCastSettings({required this.id, this.metadata});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  @OrmField(cast: 'json')
  final Map<String, Object?>? metadata;
}
// #endregion casts-field-level

// #region casts-custom-codec
class UriCodec extends ValueCodec<Uri> {
  const UriCodec();

  @override
  Object? encode(Uri? value) => value?.toString();

  @override
  Uri? decode(Object? value) =>
      value == null ? null : Uri.parse(value as String);
}
// #endregion casts-custom-codec

// #region casts-custom-use
@OrmModel(table: 'links', casts: {'website': 'uri'})
class Link extends Model<Link> {
  const Link({required this.id, this.website});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final Uri? website;
}
// #endregion casts-custom-use

// #region casts-custom-register
DataSource buildDataSource(DriverAdapter driver) {
  return DataSource(
    DataSourceOptions(
      driver: driver,
      entities: [
        SettingsOrmDefinition.definition,
        FieldCastSettingsOrmDefinition.definition,
        LinkOrmDefinition.definition,
      ],
      codecs: {'uri': const UriCodec()},
    ),
  );
}
// #endregion casts-custom-register
