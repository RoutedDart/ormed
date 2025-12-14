// Belongs To relationship example
import 'package:ormed/ormed.dart';

part 'belongs_to.orm.dart';

// #region relation-belongs-to
@OrmModel(table: 'posts')
class PostWithAuthor extends Model<PostWithAuthor> {
  const PostWithAuthor({
    required this.id,
    required this.authorId,
    required this.title,
    this.author,
  });

  @OrmField(isPrimaryKey: true)
  final int id;

  final int authorId;
  final String title;

  @OrmRelation.belongsTo(PostAuthor, foreignKey: 'author_id')
  final PostAuthor? author;
}

@OrmModel(table: 'users')
class PostAuthor extends Model<PostAuthor> {
  const PostAuthor({
    required this.id,
    required this.name,
  });

  @OrmField(isPrimaryKey: true)
  final int id;

  final String name;
}
// #endregion relation-belongs-to

