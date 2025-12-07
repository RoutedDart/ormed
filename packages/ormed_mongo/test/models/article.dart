/// Test article model exercising nullable fields and numeric columns.

import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:ormed/ormed.dart';

part 'article.orm.dart';

@OrmModel(table: 'articles')
class Article extends Model<Article> with ModelFactoryCapable {
  const Article({
    this.id,
    required this.title,
    this.body,
    required this.status,
    required this.rating,
    required this.priority,
    required this.publishedAt,
    this.reviewedAt,
    required this.categoryId,
  });

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final ObjectId? id;

  final String title;

  @OrmField(isNullable: true)
  final String? body;

  final String status;

  final double rating;

  final int priority;

  @OrmField(columnName: 'published_at')
  final DateTime publishedAt;

  @OrmField(columnName: 'reviewed_at', isNullable: true)
  final DateTime? reviewedAt;

  @OrmField(columnName: 'category_id')
  final int categoryId;
}
