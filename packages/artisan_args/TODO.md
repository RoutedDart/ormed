# artisan_args TODO

## Console Primitives (Artisan Parity) ✅

- [x] Add `ArtisanIO` (input/output wrapper) with Laravel-ish helpers:
  - [x] `title`, `section`, `text`, `line`, `newLine`
  - [x] `info`, `success`, `warning`, `error`, `note`, `caution`
  - [x] `listing` / `bulletList`
- [x] Add table rendering primitives:
  - [x] `table(headers, rows)`
  - [x] `horizontalTable(...)` (via components)
  - [x] `definitionList(...)` (via components)
- [x] Add interactive prompt primitives (with injectable stdin for tests):
  - [x] `confirm(question, default)`
  - [x] `ask(question, default, validator?)`
  - [x] `secret(question, fallback?)` - no-echo input
  - [x] `choice(question, choices, default, multiSelect)` - basic numbered
  - [x] `selectChoice(...)` - interactive arrow-key navigation
  - [x] `multiSelectChoice(...)` - interactive multi-select with space to toggle
- [x] Add progress primitives:
  - [x] `createProgressBar(max)`
  - [x] `progressIterate(iterable)` / `withProgressBar` equivalent
- [x] Add "components" parity with Laravel's `outputComponents()`:
  - [x] `task(description, taskFn)` → dotted fill + DONE/FAIL/SKIPPED
  - [x] `twoColumnDetail(left, right)` → aligned columns
  - [x] `alert(message)` → boxed output
  - [x] `bulletList(items)` → bullet-point list
  - [x] `definitionList(map)` → term/definition with dot fill
  - [x] `rule([text])` → horizontal separator with optional centered text
  - [x] `spin(message, run)` → spinner with success/fail indicator
  - [x] `info/success/warn/error(title, message)` → titled message blocks
  - [x] `line([width])` → simple line separator
  - [x] `comment(message)` → dimmed comment text
  - [x] `horizontalTable(data)` → row-as-headers layout
  - [x] `renderException(e, stack)` → pretty exception rendering

## CLI Runner UX ✅

- [x] Add global flags parity options:
  - [x] `-q, --quiet` (suppress all output)
  - [x] `-v|-vv|-vvv, --verbose` (verbosity levels)
  - [x] `-n, --no-interaction` (disable prompts)
  - [x] `--ansi/--no-ansi` (already present)
- [x] Add a single `ArtisanIO` instance accessible to commands (e.g. `command.io`).
- [ ] Add snapshot-style tests for formatted usage output (ANSI on/off).

## Advanced CLI UIs (Implemented)

### Output Components ✅
- [x] `Panel` - boxed panel with optional title (rounded, single, double, heavy, ascii)
- [x] `Columns` - multi-column layout for lists
- [x] `Tree` - tree structure display
- [x] `BoxChars` - box drawing character sets
- [x] `HorizontalTable` - row-as-headers table layout
- [x] `ExceptionRenderer` - pretty exception/stack trace formatting
- [x] `StyledBlock` - Symfony-style block output

### Progress & Async ✅
- [x] `Spinner` - animated spinner (dots, line, circle, arc, arrows, clock)
- [x] `SpinnerFrames` - predefined spinner frame sets
- [x] `withSpinner(message, callback)` - auto-finish spinner helper

### Interactive UI ✅
- [x] `SearchPrompt` - fuzzy-searchable choice selection
- [x] `pause(message?)` - "Press any key to continue..."
- [x] `countdown(seconds, message)` - countdown timer display
- [x] `SecretInput.readPassword(confirm?)` - password with confirmation

### Terminal Utilities ✅
- [x] `Terminal` - low-level terminal control
- [x] Cursor control (hide, show, move, save, restore)
- [x] Screen control (clear, scroll)
- [x] Raw mode input handling
- [x] `KeyCode` - common key code constants

### Styling ✅
- [x] `ArtisanChalk` - advanced color support using chalkdart
- [x] 256 colors and true color (RGB/hex)
- [x] Basic styles (bold, dim, italic, underline, inverse, strikethrough)
- [x] `ColorPresets` - common color hex codes

### Input Validation ✅ (powered by Acanthis)
- [x] `Validators.required()` - non-empty validation
- [x] `Validators.email()` - email format
- [x] `Validators.url()` / `uri()` - URL/URI format validation
- [x] `Validators.uuid()` - UUID format
- [x] `Validators.jwt()` / `base64()` - token formats
- [x] `Validators.hexColor()` - hex color codes
- [x] `Validators.dateTime()` - date-time strings
- [x] `Validators.numeric()` - numeric input
- [x] `Validators.integer(min, max)` - integer with range
- [x] `Validators.positive()` / `negative()` - sign validation
- [x] `Validators.between(min, max)` - range validation
- [x] `Validators.pattern(regex)` - custom regex
- [x] `Validators.letters()` / `digits()` / `alphanumeric()`
- [x] `Validators.uppercase()` / `lowercase()`
- [x] `Validators.startsWith()` / `endsWith()` / `contains()`
- [x] `Validators.inList(values)` / `notIn(values)`
- [x] `Validators.minLength(n)` / `maxLength(n)`
- [x] `Validators.ip()` / `port()` - network validation
- [x] `Validators.identifier()` - valid identifier format
- [x] `Validators.combine([...])` - chain validators
- [x] `Validators.optional(validator)` - make validator optional
- [x] `Validators.fromSchema(acanthisSchema)` - use Acanthis directly
- [x] `AcanthisString.toValidator()` - convert schema to validator

### Input/Prompts (newly added) ✅
- [x] `Anticipate` - autocomplete/typeahead input with suggestions
- [x] `Anticipate.runDynamic()` - async suggestions based on input
- [x] `Textarea` / `editText()` - multi-line input via external editor
- [x] `Wizard` - multi-step wizard flow with conditional steps
- [x] `WizardStep.ask/confirm/choice/multiChoice/secret` - basic step types
- [x] `WizardStep.select()` - interactive single-select with arrow keys
- [x] `WizardStep.multiSelect()` - interactive multi-select with arrow keys + space
- [x] `WizardStep.conditional()` - conditional step based on previous answers
- [x] `WizardStep.group()` - group related steps together

### Terminal Links ✅
- [x] `TerminalLink` - OSC 8 clickable hyperlinks
- [x] `link()` function - simple link creation
- [x] `LinkGroup` - related links for footnotes

### Component System ✅ (Flutter-like API)
- [x] `CliComponent` - base class for all components
- [x] `InteractiveComponent<T>` - base for interactive components
- [x] `ComponentContext` - context passed to components
- [x] `RenderResult` - output from build()
- [x] **Static Components:**
  - [x] `Text` - plain text
  - [x] `StyledText` - styled text (info/success/warning/error/muted)
  - [x] `Rule` - horizontal separator
  - [x] `BulletList` / `NumberedList` - list components
  - [x] `KeyValue` - key-value with dot fill
  - [x] `Box` - boxed message with border styles
  - [x] `ProgressBar` - progress indicator
  - [x] `SpinnerFrame` - single spinner frame
- [x] **Interactive Components:**
  - [x] `TextInput` - text input with validation
  - [x] `Confirm` - yes/no confirmation
  - [x] `SecretInputComponent` - password input
  - [x] `Select<T>` - single select with arrow keys
  - [x] `MultiSelect<T>` - multi select with arrow keys
  - [x] `SpinnerComponent` - async spinner
  - [x] `SearchComponent<T>` - fuzzy search selection
  - [x] `AnticipateComponent` - autocomplete input
  - [x] `PasswordComponent` - password input (no echo, confirmation)
  - [x] `PauseComponent` - press any key to continue
  - [x] `CountdownComponent` - countdown timer
- [x] **Composition:**
  - [x] `CompositeComponent` - combine components
  - [x] `ColumnComponent` - vertical layout
  - [x] `RowComponent` - horizontal layout
- [x] **Output Components:**
  - [x] `PanelComponent` - boxed panel with title
  - [x] `TreeComponent` - tree structure display
  - [x] `ColumnsComponent` - multi-column layout
  - [x] `DefinitionListComponent` - term:description pairs
  - [x] `TwoColumnDetailComponent` - dot-fill key-value
  - [x] `TaskComponent` - Laravel-style task status
  - [x] `AlertComponent` - info/success/warning/error blocks
  - [x] `TableComponent` - ASCII table with headers/rows
  - [x] `HorizontalTableComponent` - row-as-headers table
  - [x] `StyledBlockComponent` - Symfony-style block
  - [x] `CommentComponent` - dimmed comment text
  - [x] `ExceptionComponent` - pretty exception rendering
  - [x] `SimpleExceptionComponent` - one-line exception
  - [x] `LinkComponent` - clickable terminal link (OSC 8)
  - [x] `LinkGroupComponent` - grouped links with footnotes
  - [x] `SpinnerComponent` - animated spinner (interactive)
  - [x] `StatefulSpinner` - manual control spinner
  - [x] `ProgressBarComponent` - static progress bar
  - [x] `StatefulProgressBar` - manual control progress bar

## Package Structure

```
lib/src/
├── components/          # All components (29 files)
│   ├── base.dart        # CliComponent, InteractiveComponent, ComponentContext
│   ├── layout.dart      # CompositeComponent, ColumnComponent, RowComponent
│   ├── text.dart        # Text, StyledText, Rule
│   ├── list.dart        # BulletList, NumberedList
│   ├── box.dart         # KeyValue, Box
│   ├── progress.dart    # ProgressBar (static), SpinnerFrame
│   ├── progress_bar.dart # ProgressBarComponent, StatefulProgressBar
│   ├── spinner.dart     # SpinnerComponent, StatefulSpinner, SpinnerFrames
│   ├── input.dart       # TextInput, Confirm, SecretInputComponent
│   ├── select.dart      # Select, MultiSelect
│   ├── search.dart      # SearchComponent, PauseComponent, CountdownComponent
│   ├── anticipate.dart  # AnticipateComponent
│   ├── password.dart    # PasswordComponent
│   ├── textarea.dart    # TextareaComponent (external editor)
│   ├── wizard.dart      # WizardComponent, WizardStep
│   ├── panel.dart       # PanelComponent
│   ├── tree.dart        # TreeComponent
│   ├── columns.dart     # ColumnsComponent
│   ├── table.dart       # TableComponent, HorizontalTableComponent
│   ├── alert.dart       # AlertComponent
│   ├── task.dart        # TaskComponent
│   ├── styled_block.dart # StyledBlockComponent, CommentComponent
│   ├── exception.dart   # ExceptionComponent, SimpleExceptionComponent
│   └── link.dart        # LinkComponent, LinkGroupComponent
│
├── io/                  # IO utilities (3 files)
│   ├── artisan_io.dart  # Main IO facade (uses components)
│   ├── components.dart  # ArtisanComponents (high-level helpers)
│   └── validators.dart  # Input validators (Acanthis)
│
├── output/              # Terminal utilities (1 file)
│   └── terminal.dart    # Terminal, KeyCode, RawModeState
│
├── style/               # Styling utilities
│   ├── artisan_style.dart # ArtisanStyle
│   ├── verbosity.dart   # ArtisanVerbosity
│   └── chalk.dart       # ArtisanChalk, ColorPresets
│
└── runner/              # Command runner
    ├── artisan_command.dart
    └── artisan_command_runner.dart
```

## Still Missing (Future Enhancements)

### Progress & Async (Priority: Low)
- [ ] Indeterminate progress bar (unknown max)
- [ ] Nested/stacked progress bars
- [ ] Progress with ETA calculation
- [ ] Parallel task display (multiple tasks running)

### Interactive UI (Priority: Low)
- [ ] `menu(title, choices)` - persistent menu
- [ ] Form builder (multiple prompts in sequence)

### Utilities (Priority: Low)
- [ ] Terminal resize events
- [ ] Clipboard support
- [ ] `logo(ascii)` - ASCII art logo display
