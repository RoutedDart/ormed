import 'package:ormed/ormed.dart';

final _stageRegistry = <QueryContext, List<Map<String, Object?>>>{};

void addMongoPipelineStage(Query<dynamic> query, Map<String, Object?> stage) {
  final context = query.context;
  final existing = _stageRegistry[context];
  final updated = <Map<String, Object?>>[];
  if (existing != null) {
    updated.addAll(existing);
  }
  updated.add(stage);
  _stageRegistry[context] = List.unmodifiable(updated);
}

List<Map<String, Object?>> consumeMongoPipelineStages(QueryContext context) {
  final stages = _stageRegistry[context];
  if (stages == null) return const <Map<String, Object?>>[];
  _stageRegistry.remove(context);
  return stages;
}

extension MongoQueryPipelineExtension<T> on Query<T> {
  Query<T> withMongoPipelineStage(Map<String, Object?> stage) {
    addMongoPipelineStage(this, stage);
    return this;
  }
}
