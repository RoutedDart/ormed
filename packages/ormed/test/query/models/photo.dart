/// Polymorphic child model used for morph relation tests.
library;

import 'package:ormed/ormed.dart';

part 'photo.orm.dart';

@OrmModel(table: 'photos')
class Photo {
  const Photo({
    required this.id,
    required this.imageableId,
    required this.imageableType,
    required this.path,
  });

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(columnName: 'imageable_id')
  final int imageableId;

  @OrmField(columnName: 'imageable_type')
  final String imageableType;

  final String path;
}
