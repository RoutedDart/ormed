# Ultraviolet (Go) → Dart Parity Map

This is a pragmatic mapping of upstream Ultraviolet source files to their Dart
equivalents in `packages/artisanal`.

Goal: keep “full parity” work actionable by making gaps explicit.

Legend:
- ✅ Implemented + covered by tests
- ⚠️ Implemented but incomplete / needs runtime validation
- ❌ Missing (tracked in `TODO.md`)

## Core rendering + buffers

- ✅ `third_party/ultraviolet/ansi.go` → `packages/artisanal/lib/src/uv/ansi.dart`
- ✅ `third_party/ultraviolet/cell.go` → `packages/artisanal/lib/src/uv/cell.dart`, `packages/artisanal/lib/src/uv/style_ops.dart`
- ✅ `third_party/ultraviolet/buffer.go` → `packages/artisanal/lib/src/uv/buffer.dart`
- ✅ `third_party/ultraviolet/styled.go` → `packages/artisanal/lib/src/uv/styled_string.dart`
- ✅ `third_party/ultraviolet/tabstop.go` → `packages/artisanal/lib/src/uv/tabstop.dart`
- ✅ `third_party/ultraviolet/terminal_renderer*.go` → `packages/artisanal/lib/src/uv/terminal_renderer.dart`

## Input decoding + events

- ✅ `third_party/ultraviolet/event.go` → `packages/artisanal/lib/src/uv/event.dart`
- ✅ `third_party/ultraviolet/decoder.go` → `packages/artisanal/lib/src/uv/decoder.dart`
- ✅ “UV events → TUI messages” adapter → `packages/artisanal/lib/src/uv/tui_adapter.dart`
- ⚠️ Byte-stream integration / resume/suspend correctness → `packages/artisanal/lib/src/uv/event_stream.dart`

## Keys + mouse

- ✅ `third_party/ultraviolet/key.go` → `packages/artisanal/lib/src/uv/key.dart`
- ✅ `third_party/ultraviolet/key_table.go` → `packages/artisanal/lib/src/uv/key_table.dart`
- ✅ `third_party/ultraviolet/mouse.go` → `packages/artisanal/lib/src/uv/mouse.dart`

## Layout + geometry

- ✅ `third_party/ultraviolet/layout.go` → `packages/artisanal/lib/src/uv/layout.dart`
- ✅ Geometry helpers → `packages/artisanal/lib/src/uv/geometry.dart`
- ✅ Width helpers → `packages/artisanal/lib/src/uv/width.dart`

## Terminal control / reader / cancelation

- ⚠️ `third_party/ultraviolet/terminal_reader*.go` → `packages/artisanal/lib/src/uv/terminal_reader.dart`
  - Known gap: “real-terminal” behavior still needs validation under `--uv-renderer`.
- ✅ `third_party/ultraviolet/terminal.go` + `tty_*.go` → `packages/artisanal/lib/src/uv/terminal.dart` + `packages/artisanal/lib/src/terminal/terminal_base.dart`
  - ✅ Full `(in/out)` vs `(inTty/outTty)` split plumbing implemented in `TtyTerminal`.
  - ✅ Movement optimization probing (`optimizeMovements`) implemented via `stty -a`.
- ✅ `third_party/ultraviolet/cancelreader_*.go` → `packages/artisanal/lib/src/uv/cancelreader.dart`
- ✅ Window size notifications (winch) → `packages/artisanal/lib/src/uv/winch.dart`

## Borders + screen ops (misc)

- ✅ `third_party/ultraviolet/border.go` → `packages/artisanal/lib/src/uv/border.dart`
- ✅ Screen ops → `packages/artisanal/lib/src/uv/screen_ops.dart`
- ✅ Cursor model → `packages/artisanal/lib/src/uv/cursor.dart`
- ✅ Screen/canvas substrate → `packages/artisanal/lib/src/uv/screen.dart`, `packages/artisanal/lib/src/uv/canvas.dart`, `packages/artisanal/lib/src/uv/layer.dart`
- ✅ ANSI-preserving wrap (Lip Gloss v2) → `packages/artisanal/lib/src/uv/wrap.dart` (integrated opt-in via `Style.wrapAnsi(true)`)

## Likely-missing upstream modules (audit targets)

- ✅ `third_party/ultraviolet/environ.go` → `packages/artisanal/lib/src/uv/environ.dart`
- ✅ `third_party/ultraviolet/utils.go` → `packages/artisanal/lib/src/unicode/width.dart`
- ✅ `third_party/ultraviolet/uv.go` → `packages/artisanal/lib/src/uv/cursor.dart` (Cursor), `packages/artisanal/lib/src/unicode/width.dart` (WidthMethod)
- ✅ `third_party/ultraviolet/logger.go` → `packages/artisanal/lib/src/uv/logger.dart`

## Next gaps to close (recommended)

1. [x] Fix real-terminal `--uv-renderer` reliability (blank screen + resize crash + sink binding + shared stdin).
2. [x] Implement the `/dev/tty` split plumbing so output can be redirected while keeping raw mode + resize probes on the controlling TTY.
3. [x] Port/replicate upstream movement-optimization probing (`optimizeMovements`) or expose a compatibility API for host capability bits.
4. [x] Finalize Lipgloss v2 migration guide and documentation.
