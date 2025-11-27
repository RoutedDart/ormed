import 'package:ormed/ormed.dart';

part 'post_tag.orm.dart';

@OrmModel(table: 'post_tags')
class PostTag {
  const PostTag({required this.postId, required this.tagId});

  @OrmField(isPrimaryKey: true, columnName: 'post_id')
  final int postId;

  @OrmField(columnName: 'tag_id')
  final int tagId;
}
