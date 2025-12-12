/// Shared soft delete comment model for driver tests.
library;

import 'package:ormed/ormed.dart';

part 'comment.orm.dart';

@OrmModel(table: 'comments')
class Comment extends Model<Comment> with ModelFactoryCapable, SoftDeletes {
  const Comment({required this.id, required this.body});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String body;
}
