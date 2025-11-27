import 'package:ormed/ormed.dart';

part 'todo.orm.dart';

@OrmModel(table: 'todos')
class Todo extends Model<Todo> {
  const Todo({required this.id, required this.title, this.completed = false});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String title;

  final bool completed;
}
