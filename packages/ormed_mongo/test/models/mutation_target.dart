import 'package:ormed/ormed.dart';

part 'mutation_target.orm.dart';

@OrmModel(table: 'mutation_targets')
class MutationTarget extends Model<MutationTarget> with ModelFactoryCapable {
  const MutationTarget({
    required this.id,
    this.name,
    this.active,
    this.category,
  });

  @OrmField(columnName: '_id', isPrimaryKey: true)
  final String id; // MongoDB typically uses String or ObjectId for _id

  final String? name;
  final bool? active;
  final String? category;
}
