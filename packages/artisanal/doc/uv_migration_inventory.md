# UV Migration Inventory (Examples + Bubbles)

This document is a living inventory of places that still assume the “old”
string-renderer world (direct stdout writes, code-unit slicing, etc.) and will
need updates for **lipgloss v2 / Ultraviolet** parity.

The guiding rule for UV runs:

> During a running TUI, **do not write to stdout/terminal directly**. All output
> must go through the TUI pipeline (Msgs/Cmds + renderer).

---

## 1) Direct Output Writes (UV-unsafe during a running TUI)

### 1.1 Runtime (must fix)

- `packages/artisanal/lib/src/tui/program.dart:809`
  - Uses `print('Input error: ...')` from the stdin listener error handler.
  - Status: fixed (routes through the TUI pipeline via `PrintLineMsg`, no raw `print`).

### 1.2 “Interactive writer” components (must decide)

These are fine as **CLI-only** utilities, but are UV-unsafe if used while a TUI
program is running.

- `packages/artisanal/lib/src/tui/bubbles/components/progress_bar.dart:65`
  - `ProgressBarComponent.iterate(...)` writes directly to `Terminal` (`clearLine`,
    `write`, `writeln`) while work is running.
  - Options:
    - Status: a UV-safe model exists (`ProgressBarModel` + `progressIterateCmd`);
      legacy terminal-writing helpers are now deprecated and should not be used
      inside a running TUI.

### 1.3 Examples that print *during* the program (must migrate)

These examples currently write directly while the TUI is running.

- `packages/artisanal/example/tui/examples/chat/main.dart:82`
  - Prints the textarea content during `update()` on exit.
  - Action: return a `Cmd.println(textarea.value)` and then quit, OR switch to
    `runProgramWithResult` and print after the program stops.

---

## 2) Examples That Print After TUI Exit (generally OK)

These are typically safe because the program has already restored terminal
state, but they should still be reviewed if they enable UV + alt-screen combos.

- `packages/artisanal/example/tui/input.dart:293` (prints result after exit)
- `packages/artisanal/example/tui/list.dart:137` (prints result after exit, UV enabled)
- `packages/artisanal/example/tui/examples/result/main.dart:71` (prints result after exit)
- `packages/artisanal/example/tui/examples/file-picker/main.dart:119` (prints selection after exit)

Recommendation: prefer `runProgramWithResult` and print only after the program
returns.

---

## 3) Width / Slicing Hotspots (potential correctness gaps vs v2)

These sites use `.length` (code units) for layout/slicing in ways that can
break with ANSI, grapheme clusters, or wide characters.

### 3.1 Rule label width uses `.length`

- `packages/artisanal/lib/src/tui/bubbles/components/text.dart:86`
  - `final remaining = width - label.length;`
  - Status: fixed (`Style.visibleLength(label)`).

### 3.2 StyledBlock uses `.length` for prefix padding

- `packages/artisanal/lib/src/tui/bubbles/components/styled_block.dart:73`
  - Uses `prefixText.length` to compute `blockWidth`.
- `packages/artisanal/lib/src/tui/bubbles/components/styled_block.dart:82`
  - Uses `prefixText.length` to compute trailing spaces.
  - Status: fixed (`Style.visibleLength(prefixText)`).

### 3.3 Viewport horizontal scrolling slices by code units

- `packages/artisanal/lib/src/tui/bubbles/viewport.dart:249`
  - Uses `line.length` + `substring(xOffset, end)`.
  - Risks:
    - breaks grapheme clusters
    - breaks ANSI sequences if content contains escape codes
    - treats “columns” as code units rather than terminal cells
  - Status: fixed (uses ANSI-aware cell slicing via `cutAnsiByCells`).

### 3.4 Help bubble column widths use stripped `.length`

- `packages/artisanal/lib/src/tui/bubbles/help.dart:268`
  - `stripped.length` is used to compute column widths/padding.
  - Status: fixed (`Style.visibleLength(line)`).

### 3.5 TextInput cursor math uses code-unit indices

- `packages/artisanal/lib/src/tui/bubbles/textinput.dart`
  - Status: fixed (value/cursor now operate on grapheme clusters; cursor/edit ops no longer split combining marks).

### 3.6 Autocomplete (Anticipate) edits by code units

- `packages/artisanal/lib/src/tui/bubbles/anticipate.dart`
  - Status: fixed (backspace now deletes by grapheme cluster; `minCharsToSearch` counts graphemes).

### 3.7 Confirm labels slice by code units

- `packages/artisanal/lib/src/tui/bubbles/confirm.dart`
  - Status: fixed (inline mode now splits labels by grapheme boundary).

---

## 4) Next Audit Passes (recommended)

- Scan `example/tui/examples/*` for:
  - direct `print`/`stdout` usage inside models (UV-unsafe)
  - direct `Terminal` writes (UV-unsafe)
- Scan bubbles/models for:
  - slicing based on `.length` where the intention is “terminal columns”
  - ANSI stripping using local regexes rather than `Ansi.stripAnsi`
