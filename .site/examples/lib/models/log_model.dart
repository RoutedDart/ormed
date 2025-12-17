// Log model without timestamps
import 'package:ormed/ormed.dart';

part 'log_model.orm.dart';

// #region no-timestamps-model
@OrmModel(table: 'logs')
class Log extends Model<Log> {
  // No timestamps mixin - manual control
  const Log({required this.id, required this.message, this.timestamp});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String message;
  final DateTime? timestamp;
}
// #endregion no-timestamps-model
