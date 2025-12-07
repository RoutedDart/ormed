/// Test author model for driver integration.

import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:ormed/ormed.dart';

import 'post.dart';

part 'author.orm.dart';

@OrmModel(table: 'authors')
class Author extends Model<Author> with ModelFactoryCapable {
  const Author({this.id, required this.name, this.active = false})
    : posts = const [];

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final ObjectId? id;

  final String name;

  final bool active;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.hasMany,
    target: Post,
    foreignKey: 'author_id',
    localKey: 'id',
  )
  final List<Post> posts;
}
