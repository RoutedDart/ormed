# Changelog

## Unreleased

### Added

- **Progress Enhancements**:
  - Added indeterminate progress mode for unknown durations.
  - Added `MultiProgressModel` for managing and rendering multiple parallel progress bars.
  - Added ETA calculation and smooth spring-based animations to `ProgressModel`.
- **Console Tag Improvements**:
  - Enhanced tag parsing to support hex colors (`<fg=#ff0000>`) and ANSI 256 codes (`<fg=208>`).
  - Added support for nested tags and multiple options (`<options=bold,italic>`).
  - Added support for terminal hyperlinks via `<href=url>` tags.
- **UI Helpers**:
  - Added `Console.logo(ascii)` for rendering ASCII art logos.
  - Added `Console.menu(title, choices)` for persistent interactive menus.
- **Ultraviolet Parity**:
  - Added `prependString` support to `Terminal` and `TerminalRenderer` for adding lines to the top of the screen.
  - Added comprehensive capability and optimization setters to `Terminal` (`setBackspace`, `setHasTab`, `setScrollOptim`, etc.).
  - Updated `WindowSizeEvent` and `Size` to include pixel dimensions.
  - Improved terminal cleanup on exit when not using the alternate screen.
- **Architecture**:
  - Established `ViewComponent` as the primary model for composable TUI widgets.
  - Migrated all interactive prompts to the Bubble Tea (TEA) architecture.

### Fixed

- Fixed nested console tags resetting to default style instead of parent style.
- Fixed "Stream already listened to" error when restarting TUI programs.
- Improved width calculation for strings containing ANSI escape sequences.

### Breaking

- Removed legacy interactive component classes in favor of the Bubble Tea-style
  bubbles architecture (`lib/src/tui/bubbles/`).
  - Removed: `InteractiveComponent<T>`, `TextInput`, `Confirm`,
    `SecretInputComponent`, `PasswordComponent`, `TextareaComponent`,
    `Select<T>`, `MultiSelect<T>`, `SearchComponent<T>`, `AnticipateComponent`,
    `WizardComponent`, `SpinnerComponent`, `PauseComponent`, `CountdownComponent`
  - Replacements: `TextInputModel`, `ConfirmModel`, `PasswordModel`,
    `PasswordConfirmModel`, `TextAreaModel`, `SelectModel<T>`,
    `MultiSelectModel<T>`, `SearchModel<T>`, `AnticipateModel`, `WizardModel`,
    `SpinnerModel`, `PauseModel`, `CountdownModel`
- Added prompt helpers to run bubbles in “artisanal prompt” mode:
  `runTextInputPrompt`, `runConfirmPrompt`, `runPasswordPrompt`,
  `runPasswordConfirmPrompt`, `runSelectPrompt`, `runMultiSelectPrompt`,
  `runSearchPrompt`, `runAnticipatePrompt`, `runTextAreaPrompt`,
  `runWizardPrompt`, `runSpinnerTask`.

See `doc/migration_guide.md`.

## 0.0.1

Initial release with Artisanal-style console primitives.

### Features

- **Command Runner** (`CommandRunner`)
  - Grouped namespaced commands in help output
  - Sectioned help formatting (Description, Usage, Options)
  - Friendly error handling without stack traces
  - Global flags: `--ansi`, `-q/--quiet`, `-v/--verbose`, `-n/--no-interaction`

- **Command Base Class** (`Command`)
  - Access to `io` helper for console output
  - Formatted help output

- **I/O Helper** (`Console`)
  - Output: `title`, `section`, `text`, `newLine`, `listing`
  - Messages: `info`, `success`, `warning`, `error`, `note`, `caution`, `alert`
  - Layout: `twoColumnDetail`, `table`
  - Progress: `createProgressBar`, `progressIterate`
  - Tasks: `task` with DONE/FAIL/SKIPPED status
  - Prompts: `confirm`, `ask`, `secret`, `choice`
  - Interactive: `selectChoice`, `multiSelectChoice` (arrow-key navigation)

- **Components Facade** (`Components`)
  - `bulletList` - formatted bullet list
  - `definitionList` - term/definition pairs with dot fill
  - `rule` - horizontal separator with optional text
  - `line` - simple line separator
  - `spin` - processing indicator with success/fail status
  - `info/success/warn/error` - titled message blocks

- **Style** (`ArtisanalStyle`)
  - ANSI color support with graceful fallback
  - Style methods: `heading`, `command`, `option`, `muted`, `success`, `warning`, `info`, `error`, `emphasize`
  - Utility: `stripAnsi`, `visibleLength`

- **Output Rendering**
  - `ArtisanalTable` - ASCII table with ANSI-aware column alignment
  - `ArtisanalProgressBar` - terminal progress bar

- **Interactive Prompts**
  - `SecretInput` - password input without echo
  - `InteractiveChoice` - arrow-key navigable choice selection
