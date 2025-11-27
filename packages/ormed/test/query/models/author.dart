/// Test model used to exercise the query builder relation flows.
library;

import 'package:ormed/ormed.dart';

import 'post.dart';

part 'author.orm.dart';

/// Author fixture representing the parent side of relations.
@OrmModel(table: 'authors')
class Author {
  /// Creates an author and defaults [posts] to an empty list.
  const Author({required this.id, required this.name, required this.active})
    : posts = const [];

  @OrmField(isPrimaryKey: true)
  final int id;

  final String name;

  final bool active;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.hasMany,
    target: Post,
    foreignKey: 'author_id',
    localKey: 'id',
  )
  /// Related posts captured when eager-loading.
  final List<Post> posts;
}
