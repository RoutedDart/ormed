import 'package:ormed/ormed.dart';

part 'tag.orm.dart';

@OrmModel(table: 'tags')
class Tag {
  const Tag({this.id, required this.name, this.createdAt, this.updatedAt});

  @OrmField(isPrimaryKey: true)
  final int? id;

  final String name;

  @OrmField(columnName: 'created_at')
  final DateTime? createdAt;

  @OrmField(columnName: 'updated_at')
  final DateTime? updatedAt;
}
