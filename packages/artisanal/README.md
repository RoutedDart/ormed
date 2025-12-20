# artisanal

An Artisanal-style command runner UX wrapper for `package:args`.

Provides a polished CLI experience with:
- Grouped namespaced commands (e.g., `ui:*`, `db:*`)
- Formatted help output with sections
- Progress bars, tables, and task status indicators
- Interactive prompts (confirm, ask, choice, secret)
- ANSI color support with graceful fallback

## Components vs. Bubbles

- `lib/src/tui/bubbles/components/` contains **display-only** building blocks (`DisplayComponent`).
- `lib/src/tui/bubbles/` contains **interactive** components implemented as Bubble
  Tea-style `Model`s.

For migration details, see `doc/migration_guide.md`.

### Bubble Quick Start

```dart
import 'package:artisanal/artisanal.dart';

Future<void> main() async {
  final terminal = StdioTerminal();
  final name = await runTextInputPrompt(
    TextInputModel(prompt: 'Name: '),
    terminal,
  );
  print('Hello, $name');
}
```

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  artisanal:
    path: packages/artisanal  # or git/pub reference
```

## Quick Start

```dart
import 'package:artisanal/artisanal.dart';

void main(List<String> args) async {
  final runner = CommandRunner('myapp', 'My Application')
    ..addCommand(ServeCommand())
    ..addCommand(MigrateCommand());

  await runner.run(args);
}

class ServeCommand extends Command<void> {
  @override
  String get name => 'serve';

  @override
  String get description => 'Start the development server.';

  @override
  Future<void> run() async {
    io.title('Starting Server');
    
    await io.task('Compiling assets', run: () async {
      await Future.delayed(Duration(milliseconds: 100));
      return TaskResult.success;
    });
    
    io.success('Server running at http://localhost:8080');
  }
}
```

## Ultraviolet Renderer (Experimental)

`artisanal` includes a high-performance cell-buffer renderer based on [Ultraviolet](https://github.com/charmbracelet/ultraviolet). This renderer provides:
- **Flicker-free updates**: Only changed cells are sent to the terminal.
- **Complex layouts**: Support for overlapping layers and absolute positioning.
- **Lipgloss v2 Parity**: Full support for advanced styling features like hyperlinks and unified width calculation.

To enable the Ultraviolet renderer in your TUI program:

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

When using the Ultraviolet renderer, avoid direct `print()` or `stdout.write()` calls as they will desync the cell buffer. Instead, use `Cmd.println`:

```dart
@override
(Model, Cmd?) update(Msg msg) {
  if (msg is LogMsg) {
    return (this, Cmd.println('Log: ${msg.text}'));
  }
  return (this, null);
}
```

## Features

### Output Helpers

```dart
// Titles and sections
io.title('My Application');
io.section('Configuration');

// Message blocks
io.info('Starting process...');
io.success('Done!');
io.warning('Check your configuration');
io.error('Something went wrong');
io.note('Remember to...');
io.alert('Important message!');

// Lists and UI
io.listing(['Item 1', 'Item 2', 'Item 3']);
io.twoColumnDetail('Key', 'Value');
io.logo('MY APP'); // ASCII art logo
io.menu('Main Menu', ['Option 1', 'Option 2']); // Persistent menu
```

### Tables

```dart
io.table(
  headers: ['ID', 'Name', 'Status'],
  rows: [
    [1, 'users', io.style.success('DONE')],
    [2, 'posts', io.style.warning('PENDING')],
  ],
);
```

### Progress Bars

```dart
// Iterate with progress (CLI output)
for (final item in io.progressIterate(items, max: items.length)) {
  // process item
}
```

### Tasks

```dart
await io.task('Running migrations', run: () async {
  await runMigrations();
  return TaskResult.success;  // or .failure, .skipped
});
// Output: Running migrations ........................... DONE
```

### Interactive Prompts

```dart
// Yes/No confirmation
final proceed = io.confirm('Continue?', defaultValue: true);

// Text input
final name = io.ask('Your name', defaultValue: 'Anonymous');

// Secret/password (no echo)
final password = io.secret('Password');

// Basic numbered choice
final choice = io.choice(
  'Select a database',
  choices: ['SQLite', 'PostgreSQL', 'MySQL'],
);

// Interactive single-select (arrow keys)
final db = await io.selectChoice(
  'Choose database',
  choices: databases,
  defaultIndex: 0,
);

// Interactive multi-select (arrow keys + space)
final features = await io.multiSelectChoice(
  'Select features',
  choices: allFeatures,
);
```

The artisanal-style prompt APIs remain supported; interactive prompts run bubbles
under the hood.

### Components Facade

Access higher-level components via `io.components`:

```dart
io.components.bulletList(['Item 1', 'Item 2']);
io.components.definitionList({
  'Name': 'My App',
  'Version': '1.0.0',
});
io.components.rule('Section Title');
io.components.line();

await io.components.spin('Processing...', run: () async {
  // do work
  return result;
});
```

### Fluent Style System

Create advanced styles with a chainable API:

```dart
final style = Style()
    .bold()
    .foreground(Colors.green)
    .padding(1, 2)
    .border(Border.rounded);

print(style.render('Styled Text'));
```

### Console Tags

`artisanal` supports Laravel/Symfony-style console tags for inline styling:

```dart
io.text('The <fg=red;options=bold>red bold</> text.');
io.text('Hex colors: <fg=#ff0000>Red</>');
io.text('ANSI 256: <fg=208>Orange</>');
io.text('Nested: <fg=blue>Blue <fg=yellow>Yellow</> Blue</>');
```

Supported tags:
- `<fg=color>`: Foreground color (name, hex, or 256-code)
- `<bg=color>`: Background color
- `<options=bold,italic,underscore,reverse,blink,conceal,strike>`: Text options
- `<href=url>`: Terminal hyperlinks (OSC 8)

**Components with Fluent Builders:**

```dart
// Table with per-cell styling
Table()
    .headers(['Item', 'Status'])
    .row(['Task 1', 'Done'])
    .styleFunc((row, col, data) {
         if (data == 'Done') return Style().foreground(Colors.green);
         return null;
    })
    .render();

// Tree with custom enumerators
Tree()
    .root('Project')
    .child('src')
    .enumerator(TreeEnumerator.rounded)
    .render();
```

## Global Flags

The runner automatically adds these flags:

| Flag | Description |
|------|-------------|
| `--ansi` / `--no-ansi` | Force or disable ANSI colors |
| `-q`, `--quiet` | Suppress all output |
| `-v`, `--verbose` | Increase verbosity (-v, -vv, -vvv) |
| `-n`, `--no-interaction` | Disable interactive prompts |

## Project Structure

```
lib/src/
├── tui/                 # Bubble Tea-style runtime + interactive bubbles
│   ├── component.dart   # ViewComponent, StaticComponent, ComponentHost
│   ├── model.dart       # Model base class
│   ├── program.dart     # TUI event loop
│   └── bubbles/         # Stateful widgets (TEA units)
│       └── components/  # Display-only components (stateless)
│           ├── layout.dart      # CompositeComponent, ColumnComponent, RowComponent
│           ├── text.dart        # Text, StyledText, Rule
│           ├── list.dart        # BulletList, NumberedList
│           ├── box.dart         # KeyValue, Box
│           ├── progress.dart    # ProgressBar, MultiProgressModel
│           ├── table.dart       # TableComponent, HorizontalTableComponent
│           └── ...
│
├── io/                  # IO utilities
│   ├── console.dart  # Main IO facade (uses components)
│   ├── components.dart  # Components (high-level helpers)
│   └── validators.dart  # Input validators (Acanthis)
│
├── terminal/            # Terminal utilities
│   └── terminal.dart    # Terminal, Key, RawModeGuard
│
├── style/               # Styling utilities
│   ├── style.dart       # Fluent Style system (Lipgloss v2)
│   └── color.dart       # Color and ColorProfile
│
└── runner/              # Command runner
    ├── artisanal_command.dart
    └── artisanal_command_runner.dart
```

## Examples

See the `example/` directory for a complete demo application showcasing all features.

```bash
# Run from workspace root
dart run packages/artisanal/example/main.dart --help
dart run packages/artisanal/example/main.dart demo --ansi
dart run packages/artisanal/example/main.dart ui:components --ansi
```

## License

MIT
