/// Represents a $push operation.
class MongoPush {
  final Object? value;
  final bool unique;
  const MongoPush(this.value, {this.unique = false});
}

/// Represents a $pull operation.
class MongoPull {
  final Object? value;
  const MongoPull(this.value);
}

/// Represents a $unset operation.
class MongoUnset {
  const MongoUnset();
}
