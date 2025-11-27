/// Test model representing the child side of the author relation.
library;

import 'package:ormed/ormed.dart';

import 'author.dart';
import 'tag.dart';
import 'photo.dart';

part 'post.orm.dart';

/// Post fixture used by relation and query builder tests.
@OrmModel(table: 'posts')
class Post {
  /// Creates a post and defaults relation fields for serialization.
  const Post({
    required this.id,
    required this.authorId,
    required this.title,
    required this.publishedAt,
  }) : author = null,
       tags = const [],
       photos = const [];

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(columnName: 'author_id')
  final int authorId;

  final String title;

  final DateTime publishedAt;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.belongsTo,
    target: Author,
    foreignKey: 'author_id',
    localKey: 'id',
  )
  /// The parent author when eager-loading belongs-to relations.
  final Author? author;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.manyToMany,
    target: Tag,
    through: 'post_tags',
    pivotForeignKey: 'post_id',
    pivotRelatedKey: 'tag_id',
  )
  /// Tags linked via the `post_tags` pivot table.
  final List<Tag> tags;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.morphMany,
    target: Photo,
    foreignKey: 'imageable_id',
    morphType: 'imageable_type',
    morphClass: 'Post',
  )
  /// Polymorphic photos linked to the post.
  final List<Photo> photos;
}
