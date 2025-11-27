/// Parent model exercising morphOne relations.
library;

import 'package:ormed/ormed.dart';

import 'photo.dart';

part 'image.orm.dart';

@OrmModel(table: 'images')
class Image {
  const Image({required this.id, required this.label}) : primaryPhoto = null;

  @OrmField(isPrimaryKey: true)
  final int id;

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
