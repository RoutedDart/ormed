import 'package:ormed/ormed.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings.orm.dart';

@OrmModel(table: 'settings')
@JsonSerializable()
class Setting  extends Model<Setting> with ModelFactoryCapable{
  const Setting({required this.id, required this.payload});

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(cast: 'json')
  final Map<String, dynamic> payload;
}
