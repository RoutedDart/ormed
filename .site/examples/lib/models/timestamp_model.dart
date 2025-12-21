// Timestamp model examples
import 'package:ormed/ormed.dart';

part 'timestamp_model.orm.dart';

// #region timestamps-model
@OrmModel(table: 'posts')
class TimestampPost extends Model<TimestampPost> with Timestamps {
  const TimestampPost({required this.id, required this.title});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String title;
}
// #endregion timestamps-model

// #region timestamps-tz
@OrmModel(table: 'articles')
class TimestampArticleTz extends Model<TimestampArticleTz> with TimestampsTZ {
  const TimestampArticleTz({required this.id, required this.title});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String title;
}
// #endregion timestamps-tz

// #region timestamps-manual
// You can manually set timestamps using DateTime or Carbon:
// final post = $TimestampPost(
//   id: 0,
//   title: 'My Post',
//   createdAt: DateTime(2024, 1, 1),
//   updatedAt: Carbon.now().subDays(1),
// );
// #endregion timestamps-manual
