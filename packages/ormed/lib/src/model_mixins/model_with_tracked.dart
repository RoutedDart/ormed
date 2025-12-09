/// Interface for user-defined models that have a corresponding tracked model.
/// 
/// The generated code adds a `toTracked()` method to convert the user-defined
/// model to its tracked counterpart ($Model).
abstract interface class ModelWithTracked<T> {
  /// Converts this user-defined model to its tracked counterpart.
  T toTracked();
}
