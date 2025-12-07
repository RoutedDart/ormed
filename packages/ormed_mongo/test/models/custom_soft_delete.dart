import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:ormed/ormed.dart';

part 'custom_soft_delete.orm.dart';

@OrmModel(
  table: 'custom_soft_delete_models',
  softDeletes: true,
  softDeletesColumn: 'removed_on',
)
class CustomSoftDelete extends Model<CustomSoftDelete> with SoftDeletes {
  const CustomSoftDelete({this.id, required this.title});

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final ObjectId? id;

  final String title;
}
