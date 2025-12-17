// #region comment-model
import 'package:ormed/ormed.dart';

part 'comment.orm.dart';

@OrmModel(table: 'comments')
class Comment extends Model<Comment> {
  const Comment({required this.id, required this.body, this.postId});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String body;
  final int? postId;
}

// #endregion comment-model
