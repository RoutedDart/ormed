// Driver override examples for documentation.
// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:ormed/ormed.dart';

part 'driver_overrides_examples.orm.dart';

// #region driver-overrides-codecs
class PostgresPayloadCodec extends ValueCodec<Map<String, Object?>> {
  const PostgresPayloadCodec();

  @override
  Object? encode(Map<String, Object?>? value) =>
      value == null ? null : {...value, 'encoded_by': 'postgres'};

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value == null) return null;
    final map = Map<String, Object?>.from(value as Map);
    map.remove('encoded_by');
    return map;
  }
}

class SqlitePayloadCodec extends ValueCodec<Map<String, Object?>> {
  const SqlitePayloadCodec();

  @override
  Object? encode(Map<String, Object?>? value) =>
      value == null ? null : jsonEncode(value);

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value == null) return null;
    return Map<String, Object?>.from(jsonDecode(value as String) as Map);
  }
}
// #endregion driver-overrides-codecs

// #region driver-overrides-field
@OrmModel(table: 'driver_override_examples')
class DriverOverrideExample extends Model<DriverOverrideExample> {
  const DriverOverrideExample({required this.id, required this.payload});

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
// #endregion driver-overrides-field

// #region driver-annotations-model
@OrmModel(table: 'audited_events', driverAnnotations: ['audited'])
class AuditedEvent extends Model<AuditedEvent> {
  const AuditedEvent({required this.id, required this.action});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String action;
}
// #endregion driver-annotations-model
