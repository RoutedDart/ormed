import 'package:ormed/ormed.dart';

/// Mongo-specific repository that enforces unsupported behaviors early.
class MongoRepository<T> extends Repository<T> {
  MongoRepository({
    required super.definition,
    required super.driverName,
    required super.codecs,
    required super.runMutation,
    required super.describeMutation,
    required super.attachRuntimeMetadata,
  });

  @override
  Future<List<T>> insertMany(List<T> models, {bool returning = false}) {
    if (returning) {
      throw UnsupportedError(
        'Mongo driver does not support RETURNING clauses.',
      );
    }
    return super.insertMany(models, returning: false);
  }
}
