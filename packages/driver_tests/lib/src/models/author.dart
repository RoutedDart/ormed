/// Test author model for driver integration.
library;

import 'package:ormed/ormed.dart';

import 'post.dart';

part 'author.orm.dart';

@OrmModel(table: 'authors')
class Author extends Model<Author> with ModelFactoryCapable{
  const Author({required this.id, required this.name}) : posts = const [];

  @OrmField(isPrimaryKey: true)
  final int id;

  final String name;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.hasMany,
    target: Post,
    foreignKey: 'author_id',
    localKey: 'id',
  )
  final List<Post> posts;
}
