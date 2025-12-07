import 'package:ormed/ormed.dart';

/// MongoDB-specific blueprint extensions for schema operations.
///
/// This provides MongoDB-native operations that extend the base TableBlueprint functionality,
/// similar to Laravel MongoDB's Blueprint class.
extension MongoBlueprintExtensions on TableBlueprint {
  /// Create an ObjectId primary key field (_id) for MongoDB.
  ///
  /// Unlike SQL databases, MongoDB uses ObjectId for its _id field by default.
  /// This method ensures proper ObjectId handling.
  ///
  /// Example:
  /// ```dart
  /// blueprint.objectId();
  /// ```
  ColumnBuilder objectId({String name = '_id'}) {
    return column(
      name,
      const ColumnType.custom('ObjectId'), // MongoDB ObjectId type
    ).primaryKey();
  }

  /// Create a sparse index on the collection.
  ///
  /// Sparse indexes only contain entries for documents that have the indexed field.
  /// Documents without the field are not included in the index.
  ///
  /// Example:
  /// ```dart
  /// blueprint.sparse(['email']);
  /// ```
  IndexDefinition sparse(List<String> columns, {String? name}) {
    return index(
      columns,
      name: name,
      driverOptions: {
        'mongodb': {'sparse': true},
      },
    );
  }

  /// Create a sparse and unique index on the collection.
  ///
  /// Combines sparse and unique constraints - useful for optional unique fields.
  ///
  /// Example:
  /// ```dart
  /// blueprint.sparseAndUnique(['optional_unique_field']);
  /// ```
  IndexDefinition sparseAndUnique(List<String> columns, {String? name}) {
    return unique(
      columns,
      name: name,
      driverOptions: {
        'mongodb': {'sparse': true},
      },
    );
  }

  /// Create a geospatial index on the collection.
  ///
  /// [indexType] can be '2d' for flat geometries or '2dsphere' for spherical geometries.
  ///
  /// Example:
  /// ```dart
  /// blueprint.geospatial(['location'], indexType: '2dsphere');
  /// ```
  IndexDefinition geospatial(
    List<String> columns, {
    String? name,
    String indexType = '2dsphere',
  }) {
    if (indexType != '2d' && indexType != '2dsphere') {
      throw ArgumentError(
        'indexType must be either "2d" or "2dsphere", got: $indexType',
      );
    }

    return index(
      columns,
      name: name,
      driverOptions: {
        'mongodb': {'type': indexType},
      },
    );
  }

  /// Create a TTL (Time To Live) index that automatically expires documents.
  ///
  /// Documents will be automatically deleted after [seconds] from the date
  /// stored in the indexed field.
  ///
  /// Example:
  /// ```dart
  /// // Delete sessions 3600 seconds (1 hour) after their created_at timestamp
  /// blueprint.expire('created_at', 3600);
  /// ```
  IndexDefinition expire(String column, int seconds, {String? name}) {
    return index(
      [column],
      name: name,
      driverOptions: {
        'mongodb': {'expireAfterSeconds': seconds},
      },
    );
  }

  /// Create a text index for full-text search.
  ///
  /// Text indexes support text search queries on string content.
  ///
  /// Example:
  /// ```dart
  /// blueprint.textIndex(['title', 'content']);
  /// ```
  IndexDefinition textIndex(List<String> columns, {String? name}) {
    return index(
      columns,
      name: name,
      driverOptions: {
        'mongodb': {'type': 'text'},
      },
    );
  }

  /// Create a hashed index on the collection.
  ///
  /// Hashed indexes use a hash of the value of the indexed field,
  /// useful for sharding.
  ///
  /// Example:
  /// ```dart
  /// blueprint.hashed('user_id');
  /// ```
  IndexDefinition hashed(String column, {String? name}) {
    return index(
      [column],
      name: name,
      driverOptions: {
        'mongodb': {'type': 'hashed'},
      },
    );
  }

  /// Create a wildcard index on the collection.
  ///
  /// Wildcard indexes support queries against unknown or arbitrary fields.
  ///
  /// Example:
  /// ```dart
  /// // Index all fields
  /// blueprint.wildcard(['\$**']);
  ///
  /// // Index all fields under userMetadata
  /// blueprint.wildcard(['userMetadata.\$**']);
  /// ```
  IndexDefinition wildcard(List<String> columns, {String? name}) {
    return index(
      columns,
      name: name,
      driverOptions: {
        'mongodb': {'type': 'wildcard'},
      },
    );
  }

  /// Define a JSON Schema validator for the collection.
  ///
  /// This corresponds to the $jsonSchema operator in MongoDB.
  ///
  /// Example:
  /// ```dart
  /// blueprint.jsonSchema({
  ///   'bsonType': 'object',
  ///   'required': ['name', 'email'],
  ///   'properties': {
  ///     'name': {
  ///       'bsonType': 'string',
  ///       'description': 'must be a string and is required'
  ///     },
  ///     'email': {
  ///       'bsonType': 'string',
  ///       'pattern': '^.+@.+$',
  ///       'description': 'must be a valid email address and is required'
  ///     }
  ///   }
  /// });
  /// ```
  void jsonSchema(
    Map<String, Object?> schema, {
    String? validationLevel,
    String? validationAction,
  }) {
    // We use a special index definition to carry this metadata
    // since TableBlueprint doesn't support arbitrary collection options.
    index(
      [],
      name: '_json_schema_',
      driverOptions: {
        'mongodb': {
          'jsonSchema': schema,
          if (validationLevel != null) 'validationLevel': validationLevel,
          if (validationAction != null) 'validationAction': validationAction,
        },
      },
    );
  }

  /// Create an Atlas Search Index.
  ///
  /// Example:
  /// ```dart
  /// blueprint.searchIndex({
  ///   'mappings': {
  ///     'dynamic': true
  ///   }
  /// }, name: 'default');
  /// ```
  void searchIndex(Map<String, Object?> definition, {String name = 'default'}) {
    index(
      [],
      name: name,
      driverOptions: {
        'mongodb': {'type': 'search', 'definition': definition},
      },
    );
  }

  /// Create an Atlas Vector Search Index.
  ///
  /// Example:
  /// ```dart
  /// blueprint.vectorSearchIndex({
  ///   'fields': {
  ///     'embedding': {
  ///       'type': 'vector',
  ///       'dimensions': 1536,
  ///       'similarity': 'cosine'
  ///     }
  ///   }
  /// }, name: 'vector_index');
  /// ```
  void vectorSearchIndex(
    Map<String, Object?> definition, {
    String name = 'default',
  }) {
    index(
      [],
      name: name,
      driverOptions: {
        'mongodb': {'type': 'vectorSearch', 'definition': definition},
      },
    );
  }

  /// Drop an Atlas Search Index.
  void dropSearchIndex(String name) {
    // We use a special index definition to signal dropping a search index
    index(
      [],
      name: name,
      driverOptions: {
        'mongodb': {'type': 'dropSearchIndex'},
      },
    );
  }
}
