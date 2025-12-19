/// Unified terminal module for artisan_args.
///
/// This module provides a single source of truth for terminal operations
/// used throughout the package, including both static components and the
/// TUI runtime.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisan_args/src/terminal/terminal.dart';
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
/// stdout.write(Ansi.bold);
/// stdout.write('Bold text');
/// stdout.write(Ansi.reset);
///
/// // Check key input
/// if (Keys.isPrintable(byte)) { ... }
/// ```
///
/// ## Components
///
/// - [Terminal] - Abstract interface for terminal operations
/// - [StdioTerminal] - Standard implementation using dart:io
/// - [StringTerminal] - Test implementation that captures output
/// - [Ansi] - ANSI escape sequence constants and helpers
/// - [Key] - Parsed keyboard input event
/// - [KeyType] - Types of keyboard input
/// - [Keys] - Key code constants and helpers
library;

// ANSI escape sequences
export 'ansi.dart' show Ansi;

// Kitty Graphics Protocol
export 'kitty.dart' show KittyImage;
export 'iterm2.dart' show ITerm2Image;
export 'sixel.dart' show SixelImage;

// Key types and constants
export 'keys.dart' show Key, KeyType, Keys;

// Terminal interface and implementations
export 'terminal_base.dart'
    show
        Terminal,
        SplitTerminal,
        StdioTerminal,
        TtyTerminal,
        StringTerminal,
        RawModeGuard;
