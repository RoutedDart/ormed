/// Soft-delete aware comment fixture for tests.
library;

import 'package:ormed/ormed.dart';

part 'comment.orm.dart';

@OrmModel(table: 'comments')
class Comment with ModelAttributes, ModelConnection, SoftDeletes {
  const Comment({required this.id, required this.body});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String body;
}
