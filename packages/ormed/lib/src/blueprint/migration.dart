import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'schema_builder.dart';
import 'schema_plan.dart';
import 'schema_snapshot.dart';

/// Directions supported by a migration lifecycle.
enum MigrationDirection { up, down }

/// Base contract migrations extend.
abstract class Migration {
  const Migration();

  void up(SchemaBuilder schema);
  void down(SchemaBuilder schema);

  /// Builds a plan for the requested direction.
  SchemaPlan plan(MigrationDirection direction, {SchemaSnapshot? snapshot}) {
    final builder = SchemaBuilder(snapshot: snapshot);
    switch (direction) {
      case MigrationDirection.up:
        up(builder);
        break;
      case MigrationDirection.down:
        down(builder);
        break;
    }

    final description = '${direction.name}:${runtimeType.toString()}';
    return builder.build(description: description);
  }
}

/// Value object representing a migration identifier derived from its file name.
class MigrationId {
  const MigrationId(this.timestamp, this.slug);

  factory MigrationId.parse(String value) {
    final segments = value.split('_');
    if (segments.length < 5) {
      throw FormatException(
        'Invalid migration id "$value". Expected YYYY_MM_DD_HHMMSS_slug format.',
      );
    }

    final year = int.tryParse(segments[0]);
    final month = int.tryParse(segments[1]);
    final day = int.tryParse(segments[2]);
    final time = segments[3];

    if (year == null || month == null || day == null || time.length != 6) {
      throw FormatException('Invalid migration timestamp in "$value".');
    }

    final hour = int.tryParse(time.substring(0, 2));
    final minute = int.tryParse(time.substring(2, 4));
    final second = int.tryParse(time.substring(4, 6));

    if (hour == null || minute == null || second == null) {
      throw FormatException('Invalid migration time in "$value".');
    }

    final timestamp = DateTime.utc(year, month, day, hour, minute, second);
    final slug = segments.sublist(4).join('_');

    return MigrationId(timestamp, slug);
  }

  final DateTime timestamp;
  final String slug;

  String toFileName() => '${_formatTimestamp(timestamp)}_$slug';

  @override
  String toString() => toFileName();

  @override
  bool operator ==(Object other) {
    return other is MigrationId &&
        other.timestamp == timestamp &&
        other.slug == slug;
  }

  @override
  int get hashCode => Object.hash(timestamp, slug);
}

/// Snapshot of a compiled migration ready to be logged inside the ledger.
class MigrationDescriptor {
  MigrationDescriptor({
    required this.id,
    required this.up,
    required this.down,
    required this.checksum,
  });

  factory MigrationDescriptor.fromMigration({
    required MigrationId id,
    required Migration migration,
  }) {
    final upPlan = migration.plan(MigrationDirection.up);
    final downPlan = migration.plan(MigrationDirection.down);
    final checksum = _checksumForPlans(upPlan, downPlan);
    return MigrationDescriptor(
      id: id,
      up: upPlan,
      down: downPlan,
      checksum: checksum,
    );
  }

  final MigrationId id;
  final SchemaPlan up;
  final SchemaPlan down;
  final String checksum;

  Map<String, Object?> toJson() => {
    'id': id.toString(),
    'checksum': checksum,
    'up': up.toJson(),
    'down': down.toJson(),
  };

  factory MigrationDescriptor.fromJson(Map<String, Object?> json) {
    final id = MigrationId.parse(json['id'] as String);
    final up = SchemaPlan.fromJson(json['up'] as Map<String, Object?>);
    final down = SchemaPlan.fromJson(json['down'] as Map<String, Object?>);
    return MigrationDescriptor(
      id: id,
      checksum: json['checksum'] as String,
      up: up,
      down: down,
    );
  }
}

String _checksumForPlans(SchemaPlan up, SchemaPlan down) {
  final payload = jsonEncode({'up': up.toJson(), 'down': down.toJson()});
  return sha1.convert(utf8.encode(payload)).toString();
}

String _formatTimestamp(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '${year}_${month}_${day}_$hour$minute$second';
}
