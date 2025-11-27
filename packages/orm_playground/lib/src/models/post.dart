import 'package:ormed/ormed.dart';

import 'comment.dart';
import 'tag.dart';
import 'user.dart';

part 'post.orm.dart';

@OrmModel(table: 'posts')
class Post {
  const Post({
    this.id,
    required this.userId,
    required this.title,
    this.body,
    this.published = false,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  }) : author = null,
       tags = const [],
       comments = const [];

  @OrmField(isPrimaryKey: true)
  final int? id;

  @OrmField(columnName: 'user_id')
  final int userId;

  final String title;

  final String? body;

  final bool published;

  @OrmField(columnName: 'published_at')
  final DateTime? publishedAt;

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

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.manyToMany,
    target: Tag,
    through: 'post_tags',
    pivotForeignKey: 'post_id',
    pivotRelatedKey: 'tag_id',
  )
  final List<Tag> tags;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.hasMany,
    target: Comment,
    foreignKey: 'post_id',
    localKey: 'id',
  )
  final List<Comment> comments;
}
