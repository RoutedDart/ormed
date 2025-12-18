# Ultraviolet Migration Guide

This guide explains how to migrate existing TUI applications to use the new Ultraviolet (UV) renderer and how to avoid common pitfalls.

## 1. Enabling the UV Renderer

To use the UV renderer, set the `renderer` property in `Program`:

```dart
final p = Program(
  model,
  renderer: UltravioletRenderer(), // Use UV renderer
);
```

## 2. No Direct Writes to Stdout

The UV renderer maintains an internal cell buffer and performs diff-based updates. Writing directly to `stdout` or using `print()` will desync the terminal cursor and cause rendering glitches.

**Don't:**
```dart
void update(Msg msg) {
  if (msg is LogMsg) {
    print(msg.text); // WRONG: Desyncs UV renderer
  }
}
```

**Do:**
Use `Cmd.println` (or `Cmd.printf`) to log lines safely. The UV renderer will handle these by scrolling the buffer or displaying them above the TUI area.

```dart
void update(Msg msg) {
  if (msg is LogMsg) {
    return (model, Cmd.println(msg.text)); // CORRECT: UV-safe logging
  }
}
```

## 3. Handling TUI Restarts

If your application runs multiple TUI programs in sequence (e.g., a wizard followed by a main app), you must ensure `stdin` is not closed between runs.

The `sharedStdinStream` provides a persistent broadcast stream that survives TUI exits.

```dart
import 'package:artisan_args/src/terminal/stdin_stream.dart';

// StdioTerminal and CancelReader now use this automatically.
```

## 4. Lipgloss v2 Features

The new `Style` API supports several Lipgloss v2 features:

### Hyperlinks
```dart
final style = Style().hyperlink('https://example.com', 'Click me');
```

### Underline Styles
```dart
final style = Style().underlineStyle(UnderlineStyle.double);
// Variants: single, double, curly, dotted, dashed
```

### StyleRunes
Apply styles to individual runes in a string:
```dart
final styled = styleRunes('Hello', (rune, index) {
  if (index % 2 == 0) return Style().foreground(Color('#ff0000'));
  return Style();
});
```

### Ranges
Style specific substrings by index:
```dart
final ranges = Ranges()
  ..add(0, 5, Style().bold())
  ..add(6, 11, Style().italic());
final result = ranges.apply('Hello World');
```

## 5. Width and Layout

Always use `Style.visibleLength` or `Layout.visibleLength` for width calculations. These are now ANSI-aware and correctly handle OSC 8 hyperlinks and other non-printing sequences.

```dart
final width = Style().visibleLength(myString);
```
