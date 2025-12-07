import 'package:mongo_dart/mongo_dart.dart';
import 'package:ormed/ormed.dart';

part 'serial_test.orm.dart';

@OrmModel(table: 'serial_tests')
class SerialTest extends Model<SerialTest> with ModelFactoryCapable {
  const SerialTest({this.id, required this.label});

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final ObjectId? id;

  final String label;
}
