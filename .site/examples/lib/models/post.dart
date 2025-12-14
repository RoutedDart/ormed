// #region relationships
import 'package:ormed/ormed.dart';

part 'post.orm.dart';

@OrmModel(table: 'posts')
class Post extends Model<Post> {
  const Post({
    required this.id,
    required this.title,
    this.content,
    this.authorId,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String title;
  final String? content;
  final int? authorId;

  // Define relationships in the generated tracked class
  // Author? get author => ...
  // List<Comment>? get comments => ...
}
// #endregion relationships
