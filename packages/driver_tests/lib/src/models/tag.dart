/// SQLite test tag model.
library;

import 'package:ormed/ormed.dart';

import 'post.dart';

part 'tag.orm.dart';

@OrmModel(table: 'tags')
class Tag extends Model<Tag> with ModelFactoryCapable{
  const Tag({required this.id, required this.label}) : posts = const [];

  @OrmField(isPrimaryKey: true)
  final int id;

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
