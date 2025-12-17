/// Unified terminal module for artisan_args.
///
/// This library provides a single source of truth for terminal operations
/// used throughout the package, including both static components and the
/// TUI runtime.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisan_args/terminal.dart';
///
/// // Create a terminal
/// final terminal = StdioTerminal();
///
/// // Use terminal operations
/// terminal.hideCursor();
/// terminal.write('Hello, ');
/// terminal.writeln('World!');
/// terminal.showCursor();
///
/// // Use ANSI codes directly
/// import 'dart:io';
/// stdout.write(Ansi.bold);
/// stdout.write('Bold text');
/// stdout.write(Ansi.reset);
///
/// // Check key input
/// if (Keys.isPrintable(byte)) { ... }
/// ```
///
/// ## Main Exports
///
/// ### Terminal Interface
/// - [Terminal] - Abstract interface for terminal operations
/// - [StdioTerminal] - Standard implementation using dart:io
/// - [StringTerminal] - Test implementation that captures output
/// - [RawModeGuard] - Guard for restoring raw mode
///
/// ### ANSI Escape Sequences
/// - [Ansi] - ANSI escape sequence constants and helpers
///
/// ### Key Handling
/// - [Key] - Parsed keyboard input event
/// - [KeyType] - Types of keyboard input (enter, tab, arrows, etc.)
/// - [Keys] - Key code constants and helpers
library;

export 'src/terminal/terminal.dart';
