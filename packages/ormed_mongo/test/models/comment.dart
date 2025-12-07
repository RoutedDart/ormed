/// Shared soft delete comment model for driver tests.

import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:ormed/ormed.dart';

part 'comment.orm.dart';

@OrmModel(table: 'comments')
class Comment extends Model<Comment> with ModelFactoryCapable, SoftDeletes {
  const Comment({this.id, required this.body});

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final ObjectId? id;

  final String body;
}
