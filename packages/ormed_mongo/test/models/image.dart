/// SQLite integration fixture for morphOne parent models.

import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:ormed/ormed.dart';

import 'photo.dart';

part 'image.orm.dart';

@OrmModel(table: 'images')
class Image extends Model<Image> with ModelFactoryCapable {
  const Image({this.id, required this.label}) : primaryPhoto = null;

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final ObjectId? id;

  final String label;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.morphOne,
    target: Photo,
    foreignKey: 'imageable_id',
    morphType: 'imageable_type',
    morphClass: 'Image',
  )
  final Photo? primaryPhoto;
}
