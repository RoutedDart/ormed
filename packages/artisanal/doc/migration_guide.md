# Lipgloss v2 & Ultraviolet Migration Guide

This guide covers the changes introduced in the Lipgloss v2 parity update and the new Ultraviolet renderer.

## Lipgloss v2 Parity

### Width Calculation

Width calculation has been unified. Use `Style.visibleLength(text)` for consistent results across all components. This correctly handles:
- ANSI escape sequences (ignored)
- Multi-byte UTF-8 characters
- Emoji and zero-width joiners
- Tabs (expanded to spaces)

### Hyperlinks

You can now add OSC 8 hyperlinks to your styles:

```dart
final style = Style().foreground(Colors.blue).underline().hyperlink('https://example.com');
print(style.render('Click me'));
```

### Tabs and CRLF

The renderer now correctly handles `\t` (tabs) and `\r\n` (CRLF) in input strings. Tabs are expanded based on the `tabWidth` property of the style (default is 4).

## Ultraviolet Renderer

The Ultraviolet renderer is a new, high-performance renderer that uses a cell buffer and diffing to minimize terminal updates.

### Enabling Ultraviolet

To use the new renderer, set the options in `runProgram`:

```dart
await runProgram(
  MyModel(),
  options: const ProgramOptions(
    useUltravioletRenderer: true,
    useUltravioletInputDecoder: true,
  ),
);
```

### UV-Safe Logging

**CRITICAL**: Do not use `print()` or `stdout.write()` while the Ultraviolet renderer is active. These bypass the cell buffer and will cause the TUI to flicker or desync.

Use `Cmd.println` instead:

```dart
// Inside your update() method
return (this, Cmd.println('Something happened!'));
```

### Input Handling

The Ultraviolet input decoder provides more robust handling of complex escape sequences, including mouse events and focus reporting. It is recommended to use it alongside the Ultraviolet renderer.

## API Changes

- `ProgressBarModel` has been renamed to `ProgressModel` for consistency with other bubbles.
- `key.matchesSingle` now takes a `KeyBinding` object. For simple character checks, use `key.char == 'q'`.
