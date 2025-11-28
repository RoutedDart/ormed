/// Test post model referencing authors.
library;

import 'package:ormed/ormed.dart';

import 'author.dart';
import 'tag.dart';
import 'photo.dart';

part 'post.orm.dart';

@OrmModel(table: 'posts')
class Post extends Model<Post> with ModelFactoryCapable {
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

  @OrmField(columnName: 'published_at')
  final DateTime publishedAt;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.belongsTo,
    target: Author,
    foreignKey: 'author_id',
    localKey: 'id',
  )
  final Author? author;

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
    kind: RelationKind.morphMany,
    target: Photo,
    foreignKey: 'imageable_id',
    morphType: 'imageable_type',
    morphClass: 'Post',
  )
  final List<Photo> photos;
}
