// Soft deletes model example
import 'package:ormed/ormed.dart';

part 'soft_delete_model.orm.dart';

// #region soft-deletes-model
@OrmModel(table: 'posts')
class SoftDeletePost extends Model<SoftDeletePost> with SoftDeletes {
  const SoftDeletePost({required this.id, required this.title});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String title;
}
// #endregion soft-deletes-model

// #region soft-deletes-tz
@OrmModel(table: 'articles')
class SoftDeleteArticleTz extends Model<SoftDeleteArticleTz>
    with SoftDeletesTZ {
  const SoftDeleteArticleTz({required this.id, required this.title});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String title;
}

// #endregion soft-deletes-tz
