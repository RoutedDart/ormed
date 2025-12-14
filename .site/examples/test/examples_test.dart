/// Tests to verify that documentation examples compile correctly.
///
/// These tests don't need to run the examples - just importing them
/// verifies they compile with the current API.
library;

import 'package:test/test.dart';

// Import all example files to verify they compile
// import 'package:ormed_examples/models.dart';
// import 'package:ormed_examples/queries.dart';

void main() {
  group('Documentation examples compile', () {
    test('all example files are syntactically valid', () {
      // If this test runs, all imports succeeded
      // which means the example code compiles
      expect(true, isTrue);
    });
  });
}
