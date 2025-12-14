# Changelog

## 0.0.1

Initial release with Artisan-style console primitives.

### Features

- **Command Runner** (`ArtisanCommandRunner`)
  - Grouped namespaced commands in help output
  - Sectioned help formatting (Description, Usage, Options)
  - Friendly error handling without stack traces
  - Global flags: `--ansi`, `-q/--quiet`, `-v/--verbose`, `-n/--no-interaction`

- **Command Base Class** (`ArtisanCommand`)
  - Access to `io` helper for console output
  - Formatted help output

- **I/O Helper** (`ArtisanIO`)
  - Output: `title`, `section`, `text`, `newLine`, `listing`
  - Messages: `info`, `success`, `warning`, `error`, `note`, `caution`, `alert`
  - Layout: `twoColumnDetail`, `table`
  - Progress: `createProgressBar`, `progressIterate`
  - Tasks: `task` with DONE/FAIL/SKIPPED status
  - Prompts: `confirm`, `ask`, `secret`, `choice`
  - Interactive: `selectChoice`, `multiSelectChoice` (arrow-key navigation)

- **Components Facade** (`ArtisanComponents`)
  - `bulletList` - formatted bullet list
  - `definitionList` - term/definition pairs with dot fill
  - `rule` - horizontal separator with optional text
  - `line` - simple line separator
  - `spin` - processing indicator with success/fail status
  - `info/success/warn/error` - titled message blocks

- **Style** (`ArtisanStyle`)
  - ANSI color support with graceful fallback
  - Style methods: `heading`, `command`, `option`, `muted`, `success`, `warning`, `info`, `error`, `emphasize`
  - Utility: `stripAnsi`, `visibleLength`

- **Output Rendering**
  - `ArtisanTable` - ASCII table with ANSI-aware column alignment
  - `ArtisanProgressBar` - terminal progress bar

- **Interactive Prompts**
  - `SecretInput` - password input without echo
  - `InteractiveChoice` - arrow-key navigable choice selection

