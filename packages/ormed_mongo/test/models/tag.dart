/// SQLite test tag model.

import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:ormed/ormed.dart';

import 'post.dart';

part 'tag.orm.dart';

@OrmModel(table: 'tags')
class Tag extends Model<Tag> with ModelFactoryCapable {
  const Tag({this.id, required this.label}) : posts = const [];

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final ObjectId? id;

  final String label;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.manyToMany,
    target: Post,
    through: 'post_tags',
    pivotForeignKey: 'tag_id',
    pivotRelatedKey: 'post_id',
  )
  final List<Post> posts;
}
