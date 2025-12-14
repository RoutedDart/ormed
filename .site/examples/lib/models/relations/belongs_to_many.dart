// Belongs To Many relationship example
import 'package:ormed/ormed.dart';

part 'belongs_to_many.orm.dart';

// #region relation-belongs-to-many
@OrmModel(table: 'posts')
class PostWithTags extends Model<PostWithTags> {
  const PostWithTags({
    required this.id,
    this.tags,
  });

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmRelation.belongsToMany(
    Tag,
    pivotTable: 'post_tags',
    foreignKey: 'post_id',
    relatedKey: 'tag_id',
  )
  final List<Tag>? tags;
}

@OrmModel(table: 'tags')
class Tag extends Model<Tag> {
  const Tag({
    required this.id,
    required this.name,
  });

  @OrmField(isPrimaryKey: true)
  final int id;

  final String name;
}
// #endregion relation-belongs-to-many

