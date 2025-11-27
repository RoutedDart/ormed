import 'package:ormed/ormed.dart';

part 'orm_migration_record.orm.dart';

@OrmModel(table: 'orm_migrations')
class OrmMigrationRecord extends Model<OrmMigrationRecord> {
  const OrmMigrationRecord({
    required this.id,
    required this.checksum,
    required this.appliedAt,
    required this.batch,
  });

  @OrmField(isPrimaryKey: true)
  final String id;

  @OrmField()
  final String checksum;

  @OrmField(columnName: 'applied_at')
  final DateTime appliedAt;

  @OrmField()
  final int batch;
}
