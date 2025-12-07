/// Shared polymorphic photo model for SQLite integration tests.

import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:ormed/ormed.dart';

part 'photo.orm.dart';

@OrmModel(table: 'photos')
class Photo extends Model<Photo> with ModelFactoryCapable {
  const Photo({
    this.id,
    required this.imageableId,
    required this.imageableType,
    required this.path,
  });

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final ObjectId? id;

  @OrmField(columnName: 'imageable_id')
  final int imageableId;

  @OrmField(columnName: 'imageable_type')
  final String imageableType;

  final String path;
}
