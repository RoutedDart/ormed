import 'package:ormed/ormed.dart';

import 'user.dart';

part 'comment.orm.dart';

@OrmModel(table: 'comments')
class Comment {
  const Comment({
    this.id,
    required this.postId,
    this.userId,
    required this.body,
    this.createdAt,
    this.updatedAt,
  }) : author = null;

  @OrmField(isPrimaryKey: true)
  final int? id;

  @OrmField(columnName: 'post_id')
  final int postId;

  @OrmField(columnName: 'user_id')
  final int? userId;

  final String body;

  @OrmField(columnName: 'created_at')
  final DateTime? createdAt;

  @OrmField(columnName: 'updated_at')
  final DateTime? updatedAt;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.belongsTo,
    target: User,
    foreignKey: 'user_id',
    localKey: 'id',
  )
  final User? author;
}
