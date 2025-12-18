# Ultraviolet (Go) → Dart Parity Map

This is a pragmatic mapping of upstream Ultraviolet source files to their Dart
equivalents in `packages/artisan_args`.

Goal: keep “full parity” work actionable by making gaps explicit.

Legend:
- ✅ Implemented + covered by tests
- ⚠️ Implemented but incomplete / needs runtime validation
- ❌ Missing (tracked in `TODO.md`)

## Core rendering + buffers

- ✅ `third_party/ultraviolet/ansi.go` → `packages/artisan_args/lib/src/tui/uv/ansi.dart`
- ✅ `third_party/ultraviolet/cell.go` → `packages/artisan_args/lib/src/tui/uv/cell.dart`, `packages/artisan_args/lib/src/tui/uv/style_ops.dart`
- ✅ `third_party/ultraviolet/buffer.go` → `packages/artisan_args/lib/src/tui/uv/buffer.dart`
- ✅ `third_party/ultraviolet/styled.go` → `packages/artisan_args/lib/src/tui/uv/styled_string.dart`
- ✅ `third_party/ultraviolet/tabstop.go` → `packages/artisan_args/lib/src/tui/uv/tabstop.dart`
- ✅ `third_party/ultraviolet/terminal_renderer*.go` → `packages/artisan_args/lib/src/tui/uv/terminal_renderer.dart`

## Input decoding + events

- ✅ `third_party/ultraviolet/event.go` → `packages/artisan_args/lib/src/tui/uv/event.dart`
- ✅ `third_party/ultraviolet/decoder.go` → `packages/artisan_args/lib/src/tui/uv/decoder.dart`
- ✅ “UV events → TUI messages” adapter → `packages/artisan_args/lib/src/tui/uv/tui_adapter.dart`
- ⚠️ Byte-stream integration / resume/suspend correctness → `packages/artisan_args/lib/src/tui/uv/event_stream.dart`

## Keys + mouse

- ✅ `third_party/ultraviolet/key.go` → `packages/artisan_args/lib/src/tui/uv/key.dart`
- ✅ `third_party/ultraviolet/key_table.go` → `packages/artisan_args/lib/src/tui/uv/key_table.dart`
- ✅ `third_party/ultraviolet/mouse.go` → `packages/artisan_args/lib/src/tui/uv/mouse.dart`

## Layout + geometry

- ✅ `third_party/ultraviolet/layout.go` → `packages/artisan_args/lib/src/tui/uv/layout.dart`
- ✅ Geometry helpers → `packages/artisan_args/lib/src/tui/uv/geometry.dart`
- ✅ Width helpers → `packages/artisan_args/lib/src/tui/uv/width.dart`

## Terminal control / reader / cancelation

- ⚠️ `third_party/ultraviolet/terminal_reader*.go` → `packages/artisan_args/lib/src/tui/uv/terminal_reader.dart`
  - Known gap: “real-terminal” behavior still needs validation under `--uv-renderer`.
- ✅ `third_party/ultraviolet/terminal.go` + `tty_*.go` → `packages/artisan_args/lib/src/tui/uv/terminal.dart` + `packages/artisan_args/lib/src/terminal/terminal_base.dart`
  - ✅ Full `(in/out)` vs `(inTty/outTty)` split plumbing implemented in `TtyTerminal`.
  - ✅ Movement optimization probing (`optimizeMovements`) implemented via `stty -a`.
- ✅ `third_party/ultraviolet/cancelreader_*.go` → `packages/artisan_args/lib/src/tui/uv/cancelreader.dart`
- ✅ Window size notifications (winch) → `packages/artisan_args/lib/src/tui/uv/winch.dart`

## Borders + screen ops (misc)

- ✅ `third_party/ultraviolet/border.go` → `packages/artisan_args/lib/src/tui/uv/border.dart`
- ✅ Screen ops → `packages/artisan_args/lib/src/tui/uv/screen_ops.dart`
- ✅ Cursor model → `packages/artisan_args/lib/src/tui/uv/cursor.dart`
- ✅ Screen/canvas substrate → `packages/artisan_args/lib/src/tui/uv/screen.dart`, `packages/artisan_args/lib/src/tui/uv/canvas.dart`, `packages/artisan_args/lib/src/tui/uv/layer.dart`
- ✅ ANSI-preserving wrap (Lip Gloss v2) → `packages/artisan_args/lib/src/tui/uv/wrap.dart` (integrated opt-in via `Style.wrapAnsi(true)`)

## Likely-missing upstream modules (audit targets)

- ❌ `third_party/ultraviolet/environ.go` (env parsing helpers; we currently use `dart:io Platform.environment`)
- ❌ `third_party/ultraviolet/utils.go` (misc helpers; likely split across `geometry.dart`, `width.dart`, `color_utils.dart`)
- ❌ `third_party/ultraviolet/uv.go` (package-level API glue; Dart exposes pieces via TUI runtime)
- ⚠️ `third_party/ultraviolet/logger.go` (we have internal log hooks in some modules, but not a unified logger API)

## Next gaps to close (recommended)

1. Fix real-terminal `--uv-renderer` reliability (blank screen + resize crash + sink binding).
2. Implement the `/dev/tty` split plumbing so output can be redirected while keeping raw mode + resize probes on the controlling TTY.
3. Port/replicate upstream movement-optimization probing (`optimizeMovements`) or expose a compatibility API for host capability bits.
