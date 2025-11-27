import 'model_definition.dart';

/// Thrown when a requested codec type is missing from the registry.
class CodecNotFound implements Exception {
  CodecNotFound(this.typeKey, this.field);

  final String typeKey;
  final FieldDefinition field;

  @override
  String toString() =>
      'CodecNotFound: no codec registered for "$typeKey" (field ${field.name}).';
}

/// Thrown when a model definition hasn't been registered in a registry.
class ModelNotRegistered implements Exception {
  ModelNotRegistered(this.type);

  final Type type;

  @override
  String toString() => 'ModelNotRegistered: $type is not registered.';
}

/// Thrown when a model is requested by name but not found in the registry.
class ModelNotRegisteredByName implements Exception {
  ModelNotRegisteredByName(this.name);

  final String name;

  @override
  String toString() => 'ModelNotRegisteredByName: $name is not registered.';
}

/// Thrown when a query expected at least one row but none were returned.
class ModelNotFoundException implements Exception {
  ModelNotFoundException(this.modelName, {this.key});

  final String modelName;
  final Object? key;

  @override
  String toString() {
    final keyMessage = key == null ? '' : ' for key $key';
    return 'ModelNotFoundException: $modelName not found$keyMessage.';
  }
}

/// Thrown when a query expected only one row but multiple were returned.
class MultipleRecordsFoundException implements Exception {
  MultipleRecordsFoundException(this.modelName, this.count);

  final String modelName;
  final int count;

  @override
  String toString() =>
      'MultipleRecordsFoundException: Expected one $modelName but found $count.';
}

class MassAssignmentException extends StateError {
  MassAssignmentException(super.message);
}
