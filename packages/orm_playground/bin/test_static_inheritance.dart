class Base {
  static void staticMethod() {
    print('Base.staticMethod called');
  }
}

class Sub extends Base {}

void main() {
  // Try to call Sub.staticMethod()
  // If this compiles, then Dart supports static inheritance.
  // Sub.staticMethod();

  try {
    // Dynamic invocation is not possible for statics, so we rely on compilation.
    // I will write the code that should fail compilation if my assumption is correct.
    // I'll comment it out and ask the tool to uncomment it, or just write it and expect failure.
  } catch (e) {
    print(e);
  }
}
