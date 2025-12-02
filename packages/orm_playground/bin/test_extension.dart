class Foo {}

extension FooExt on Foo {
  static void bar() => print('bar called');
}

void main() {
  // Try to call Foo.bar()
  // If this compiles and runs, then extensions can add static methods to the class namespace.
  // Foo.bar();

  // Actually, I'll try to run it and see if it fails.
  // I suspect I need to call FooExt.bar();

  try {
    // I can't write invalid code or it won't run.
    // I will write it and if it fails analysis/compilation I'll know.
    // But I'm running this via `dart run`.
  } catch (e) {
    print(e);
  }
}
