# artisanal

Artisanal is a full‑stack terminal toolkit for Dart: polished CLI output, a Lip Gloss‑style styling system, a Bubble Tea‑style TUI runtime, reusable widgets (“bubbles”), and an Ultraviolet‑based cell renderer.

It is designed to let you build everything from rich command‑line tools to complex interactive TUI apps, with a consistent API surface.

## What’s inside

- **CLI I/O**: High‑level `Console` helpers for status lines, tables, tasks, and prompts.
- **Styling**: Lip Gloss‑style `Style`, borders, layout helpers, and **ThemePalette** support.
- **TUI runtime**: Elm Architecture (`Model`/`Msg`/`Cmd`) with a fully featured `Program`.
- **Bubbles**: Reusable components (inputs, lists, spinners, viewports, tables, progress bars, etc.).
- **Ultraviolet (UV)**: High‑performance cell‑buffer renderer and ANSI input decoder.

## Installation

```yaml
dependencies:
  artisanal: ^0.0.1
```

> Workspace users: this repo is `publish_to: none`. Use a path or git reference while developing.

## Quick Start: CLI Output

```dart
import 'package:artisanal/artisanal.dart';

Future<void> main() async {
  final io = Console();

  io.title('My App');
  io.section('Setup');
  io.info('Checking configuration...');

  await io.task('Running migrations', run: () async {
    await Future.delayed(const Duration(milliseconds: 200));
    return TaskResult.success;
  });

  io.table(
    headers: ['ID', 'Name', 'Status'],
    rows: [
      [1, 'users', io.style.success('DONE')],
      [2, 'posts', io.style.warning('PENDING')],
    ],
  );

  final proceed = io.confirm('Continue?', defaultValue: true);
  if (!proceed) return;

  io.success('All good.');
}
```

## Quick Start: TUI

```dart
import 'package:artisanal/tui.dart';

class CounterModel implements Model {
  final int count;
  const CounterModel([this.count = 0]);

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.up)) => (CounterModel(count + 1), null),
      KeyMsg(key: Key(type: KeyType.down)) => (CounterModel(count - 1), null),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  String view() => 'Count: $count\n\nUse ↑/↓ to change, q to quit';
}

Future<void> main() async {
  await runProgram(CounterModel());
}
```

## Ultraviolet Renderer (High‑performance)

The UV renderer diffs cell buffers for flicker‑free updates and supports layered composition.

Enable it in a TUI program:

```dart
await runProgram(
  MyModel(),
  options: const ProgramOptions(
    useUltravioletRenderer: true,
    useUltravioletInputDecoder: true,
  ),
);
```

### UV‑safe logging

Avoid direct `print()` or `stdout.write()` while UV is active, or the buffer will desync. Use `Cmd.println`:

```dart
@override
(Model, Cmd?) update(Msg msg) {
  if (msg is LogMsg) {
    return (this, Cmd.println('Log: ${msg.text}'));
  }
  return (this, null);
}
```

## Theme Palette

Artisanal ships theme palettes for consistent UI styling.

```dart
import 'package:artisanal/style.dart';

final theme = ThemePalette.byName('dark');
final title = Style().foreground(theme.accentBold).bold().render('Dashboard');
```

Available themes: `ThemePalette.names`.

## Bubbles (Reusable components)

Use components like text inputs, lists, viewports, and progress bars from `package:artisanal/bubbles.dart`:

```dart
import 'package:artisanal/bubbles.dart';

final input = TextInputModel(prompt: 'Name: ');
```

## Examples

Explore working demos under `packages/artisanal/example/` and
`packages/artisanal/example/tui/examples/`.

Notable demos:
- Kitchen sink (widgets + renderer + unicode + colors)
- Command center dashboard
- Trello board
- Progress, spinners, tables, text inputs, etc.

## Project structure

- `package:artisanal/artisanal.dart` – full kit (CLI + style + terminal)
- `package:artisanal/args.dart` – command runner utilities
- `package:artisanal/style.dart` – styling + layout + themes
- `package:artisanal/tui.dart` – TUI runtime and program loop
- `package:artisanal/bubbles.dart` – reusable widgets
- `package:artisanal/uv.dart` – low‑level renderer & input decoder

## Notes

- For migration details, see `packages/artisanal/MIGRATION_GUIDE.md`.
- UV parity notes live in `packages/artisanal/UV_PARITY_MAP.md`.

---

If you want a docs site or API reference, the `packages/artisanal/site/` folder is ready for content.
