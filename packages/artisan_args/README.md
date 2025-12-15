# artisan_args

An Artisan-style command runner UX wrapper for `package:args`.

Provides a polished CLI experience with:
- Grouped namespaced commands (e.g., `ui:*`, `db:*`)
- Formatted help output with sections
- Progress bars, tables, and task status indicators
- Interactive prompts (confirm, ask, choice, secret)
- ANSI color support with graceful fallback

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  artisan_args:
    path: packages/artisan_args  # or git/pub reference
```

## Quick Start

```dart
import 'package:artisan_args/artisan_args.dart';

void main(List<String> args) async {
  final runner = ArtisanCommandRunner('myapp', 'My Application')
    ..addCommand(ServeCommand())
    ..addCommand(MigrateCommand());

  await runner.run(args);
}

class ServeCommand extends ArtisanCommand<void> {
  @override
  String get name => 'serve';

  @override
  String get description => 'Start the development server.';

  @override
  Future<void> run() async {
    io.title('Starting Server');
    
    await io.task('Compiling assets', run: () async {
      await Future.delayed(Duration(milliseconds: 100));
      return ArtisanTaskResult.success;
    });
    
    io.success('Server running at http://localhost:8080');
  }
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

// Lists
io.listing(['Item 1', 'Item 2', 'Item 3']);
io.twoColumnDetail('Key', 'Value');
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
final bar = io.createProgressBar(max: 100);
bar.start();
for (var i = 0; i < 100; i++) {
  await Future.delayed(Duration(milliseconds: 10));
  bar.advance();
}
bar.finish();

// Or iterate with progress
for (final item in io.progressIterate(items)) {
  // process item
}
```

### Tasks

```dart
await io.task('Running migrations', run: () async {
  await runMigrations();
  return ArtisanTaskResult.success;  // or .failure, .skipped
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
lib/
├── artisan_args.dart      # Main library export
└── src/
    ├── io/                # I/O and prompts
    │   ├── artisan_io.dart
    │   ├── components.dart
    │   └── prompts.dart
    ├── output/            # Output rendering
    │   ├── progress_bar.dart
    │   └── table.dart
    ├── runner/            # Command runner
    │   ├── command.dart
    │   ├── command_listing.dart
    │   └── command_runner.dart
    └── style/             # Styling
        ├── artisan_style.dart
        └── verbosity.dart
```

## Examples

See the `example/` directory for a complete demo application showcasing all features.

```bash
# Run from workspace root
dart run packages/artisan_args/example/main.dart --help
dart run packages/artisan_args/example/main.dart demo --ansi
dart run packages/artisan_args/example/main.dart ui:components --ansi
```

## License

MIT

