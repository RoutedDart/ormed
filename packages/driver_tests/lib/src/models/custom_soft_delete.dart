import 'package:ormed/ormed.dart';

part 'custom_soft_delete.orm.dart';

@OrmModel(
  table: 'custom_soft_delete_models',
  softDeletes: true,
  softDeletesColumn: 'removed_on',
)
class CustomSoftDelete extends Model<CustomSoftDelete> with ModelFactoryCapable, SoftDeletes {
  const CustomSoftDelete({required this.id, required this.title});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String title;
}
