/// Base class for ORM-managed model instances with attribute tracking.
///
/// This class combines attribute storage, connection awareness, and
/// relationship tracking for models loaded from or saved to the database.
///
/// User-defined model classes should remain simple, immutable data classes.
/// The code generator creates tracked variants that extend this class.
library;

import 'model_mixins/model_attributes.dart';
import 'model_mixins/model_connection.dart';
import 'model_mixins/model_relations.dart';

/// Base class for ORM-tracked model instances.
///
/// Tracked models are created by the ORM when loading data from the database
/// or when preparing to save data. They maintain attribute state, track changes,
/// and provide methods for interacting with relationships.
///
/// Generated code creates concrete tracked model classes that extend this base.
abstract class TrackedModel
    with ModelAttributes, ModelConnection, ModelRelations {
  TrackedModel();

  /// Whether this model instance exists in the database.
  bool get exists => _exists;

  /// Marks this model as existing in the database.
  void markAsExisting() {
    _exists = true;
  }

  bool _exists = false;
}
