import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:ormed/ormed.dart';

part 'derived_for_factory.orm.dart';

abstract class BaseForFactory<T extends Model<T>> extends Model<T>
    with ModelFactoryCapable {
  const BaseForFactory({this.id, this.baseName});

  @OrmField(isPrimaryKey: true, hidden: true)
  @OrmField(isPrimaryKey: true, columnName: '_id')
  final ObjectId? id;

  @OrmField(fillable: true)
  final String? baseName;
}

abstract class LevelOneForFactory<T extends Model<T>>
    extends BaseForFactory<T> {
  const LevelOneForFactory({
    required super.id,
    super.baseName,
    this.layerOneNotes,
  });

  @OrmField(cast: 'json')
  final Map<String, Object?>? layerOneNotes;
}

@OrmModel(table: 'derived_for_factories')
class DerivedForFactory extends LevelOneForFactory<DerivedForFactory> {
  const DerivedForFactory({
    required super.id,
    super.baseName,
    super.layerOneNotes,
    this.layerTwoFlag,
  });

  @OrmField(guarded: true)
  final bool? layerTwoFlag;
}
