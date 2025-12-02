class Model {
  static void foo<T>([String? name]) {
    print('foo called for $T with name: $name');
  }
}

class User extends Model {
  static final foo = Model.foo<User>;
}

void main() {
  User.foo();
  User.foo('bar');
}
