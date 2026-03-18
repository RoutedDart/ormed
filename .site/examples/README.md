# Ormed Documentation Examples

This package contains runnable Dart code examples that are embedded in the Ormed documentation.

## Purpose

By keeping examples in a proper Dart package:
- Code can be analyzed and type-checked
- Examples can be tested to ensure APIs are correct
- IDE support works properly for maintenance
- Documentation stays in sync with actual API

## Structure

```
examples/
├── lib/
│   ├── src/database/      # Generated scaffolding (config, datasource, registries)
│   ├── models/            # Model examples
│   ├── drivers/           # Driver usage examples
│   └── ...
├── ormed.yaml             # Optional CLI config example
├── test/
│   └── examples_test.dart # Tests to verify examples compile/run
└── pubspec.yaml
```

## Using Regions

Code is organized using region comments that can be extracted in docs:

```dart
// #region my-example
void exampleCode() {
  // This code will be embedded in documentation
}
// #endregion my-example
```

## Embedding in Documentation

In markdown files, use the code fence with `file=` meta:

````markdown
```dart file=../../examples/lib/models.dart#basic-model

```
````

This imports only the code between `// #region basic-model` and `// #endregion basic-model`.

To import an entire file (no region):

````markdown
```dart file=../../examples/lib/setup.dart

```
````

**Note:** Paths are relative to the markdown file's location.

## Running Examples

```bash
# Get dependencies
dart pub get

# Analyze code
dart analyze

# Run tests (once tests are uncommented)
dart test
```

## Adding New Examples

1. Create or edit a file in `lib/` with proper region markers
2. Reference the region in your markdown file using the syntax above
3. Run `npm run build` from `.site/` to verify it works
