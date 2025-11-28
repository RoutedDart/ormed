import 'package:ormed/ormed.dart';

part 'serial_test.orm.dart';

@OrmModel(table: 'serial_tests')
class SerialTest extends Model<SerialTest> with ModelFactoryCapable {
  const SerialTest({required this.id, required this.label});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String label;
}
