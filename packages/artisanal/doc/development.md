# Development Guide

This document contains useful commands and tips for developing `artisanal`.

## Running Examples

Most examples can be run directly from the package root.

### TUI Examples

```bash
# Basic counter
dart run example/tui/counter.dart

# Interactive input demo
dart run example/tui/input.dart

# List demo
dart run example/tui/list.dart

# Ultraviolet Renderer Demo
dart run example/tui/uv_demo.dart
```

### Ultraviolet Parity Examples

These examples are used to verify parity with the Go implementation.

```bash
# Graphics parity (Kitty, iTerm2, Sixel)
dart run example/uv_graphics_parity.dart

# Input/Event decoding demo
dart run example/tui/examples/uv-input/main.dart
```

## Running Tests

```bash
# Run all tests
dart test

# Run tests with concurrency disabled (useful for debugging TTY issues)
dart test -j 1

# Run a specific test file
dart test test/style/style_test.dart
```

## Ultraviolet Renderer Debugging

When running with `--uv-renderer`, you can enable logging to a file to avoid desyncing the terminal:

```dart
final p = Program(
  MyModel(),
  options: ProgramOptions(
    useUltravioletRenderer: true,
  ),
);
// Logs will be written to uv.log if you use the UV logger
```

## Common Issues

### "Stream already listened to"
This usually happens if you try to start a TUI `Program` multiple times without properly closing the previous one, or if multiple listeners are attached to `stdin`. Ensure you use `sharedStdinStream` if needed.

### Blank Screen in UV Renderer
Ensure that `altScreen: true` is set in `ProgramOptions` if your model expects a full-screen view, and that you are returning a non-empty string from `view()`.
