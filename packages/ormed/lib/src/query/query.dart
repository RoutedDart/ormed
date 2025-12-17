/// Query builder and runtime context for Ormed.
///
/// {@category Queries}
///
/// {@template ormed.query}
/// Starts building a query for a registered model type.
///
/// A [Query] is always bound to a [QueryContext] (model registry, driver, and
/// hooks). Most applications obtain queries through one of these entry points:
///
/// ```dart
/// final users1 = await dataSource.query<User>().where('active', true).get();
/// final users2 = await dataSource.context.query<User>().where('active', true).get();
/// final users3 = await Model.query<User>().where('active', true).get();
/// ```
///
/// Queries return tracked model instances for generated ORM models.
/// {@endtemplate}
///
library;

import 'dart:async';

import 'package:ormed/src/query/query_builder.dart';

import '../connection/connection_resolver.dart';
import '../contracts.dart';
import '../driver/driver.dart';
import '../events/event_bus.dart';
import '../hook/query_builder_hook.dart';
import '../model/model.dart';
import '../repository/repository.dart';
import '../value_codec.dart';
import 'cache/query_cache.dart';
import 'query_plan.dart';

export 'cache/cache_events.dart';
export 'cache/query_cache.dart';
export 'json_path.dart';
export 'query_builder.dart';
export 'query_plan.dart';
export 'relation_loader.dart';
export 'relation_resolver.dart';

part 'query_context.dart';
part 'query_instrumentation.dart';
part 'query_results.dart';
part 'scope_registry.dart';
