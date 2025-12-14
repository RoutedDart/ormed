import 'dart:async';
import 'dart:io' as io;

import '../style/artisan_style.dart';

/// Configuration for interactive choice selection.
class ChoiceConfig {
  /// Creates a new choice configuration.
  const ChoiceConfig({
    this.pointer = '❯',
    this.selectedPrefix = '●',
    this.unselectedPrefix = '○',
    this.highlightColor = '36', // cyan
    this.maxDisplay = 10,
  });

  /// The pointer character for the current selection.
  final String pointer;

  /// The prefix for selected items in multi-select.
  final String selectedPrefix;

  /// The prefix for unselected items in multi-select.
  final String unselectedPrefix;

  /// The ANSI color code for highlighted items.
  final String highlightColor;

  /// Maximum number of choices to display at once.
  final int maxDisplay;
}

/// Result of an interactive choice selection.
class ChoiceResult<T> {
  /// Creates a new choice result.
  ChoiceResult({required this.selected, required this.cancelled});

  /// The selected items.
  final List<T> selected;

  /// Whether the selection was cancelled.
  final bool cancelled;

  /// The single selected item (or null if none/cancelled).
  T? get single => selected.isEmpty ? null : selected.first;

  /// Whether no items were selected.
  bool get isEmpty => selected.isEmpty;
}

/// Interactive choice prompt with arrow-key navigation.
///
/// Provides a rich terminal UX for single and multi-select choices.
class InteractiveChoice {
  /// Creates a new interactive choice prompt.
  InteractiveChoice({
    required this.style,
    required this.write,
    required this.writeln,
    this.config = const ChoiceConfig(),
    io.Stdin? stdin,
    io.Stdout? stdout,
  }) : _stdin = stdin ?? io.stdin,
       _stdout = stdout ?? io.stdout;

  /// The style configuration.
  final ArtisanStyle style;

  /// Callback for writing text.
  final void Function(String) write;

  /// Callback for writing a line.
  final void Function(String) writeln;

  /// The choice configuration.
  final ChoiceConfig config;

  final io.Stdin _stdin;
  final io.Stdout _stdout;

  /// Displays an interactive single-select prompt.
  Future<T?> select<T>(
    String question, {
    required List<T> choices,
    int? defaultIndex,
    String Function(T)? display,
  }) async {
    final result = await _run(
      question,
      choices: choices,
      defaultIndex: defaultIndex,
      multiSelect: false,
      display: display ?? (v) => v.toString(),
    );
    return result.single;
  }

  /// Displays an interactive multi-select prompt.
  Future<List<T>> multiSelect<T>(
    String question, {
    required List<T> choices,
    List<int> defaultSelected = const [],
    String Function(T)? display,
  }) async {
    final result = await _run(
      question,
      choices: choices,
      multiSelect: true,
      initialSelected: defaultSelected.toSet(),
      display: display ?? (v) => v.toString(),
    );
    return result.selected;
  }

  Future<ChoiceResult<T>> _run<T>(
    String question, {
    required List<T> choices,
    required bool multiSelect,
    required String Function(T) display,
    int? defaultIndex,
    Set<int>? initialSelected,
  }) async {
    if (choices.isEmpty) {
      return ChoiceResult(selected: [], cancelled: false);
    }

    var cursor = defaultIndex?.clamp(0, choices.length - 1) ?? 0;
    final selected = initialSelected?.toSet() ?? <int>{};
    var scrollOffset = 0;

    writeln(style.emphasize(question));

    void render() {
      final displayCount = choices.length.clamp(1, config.maxDisplay);
      _stdout.write('\x1B[${displayCount}A\x1B[J');

      if (cursor < scrollOffset) {
        scrollOffset = cursor;
      } else if (cursor >= scrollOffset + config.maxDisplay) {
        scrollOffset = cursor - config.maxDisplay + 1;
      }

      final end = (scrollOffset + config.maxDisplay).clamp(0, choices.length);
      for (var i = scrollOffset; i < end; i++) {
        final item = choices[i];
        final isHighlighted = i == cursor;
        final isSelected = selected.contains(i);
        final label = display(item);

        String line;
        if (multiSelect) {
          final check = isSelected
              ? style.success(config.selectedPrefix)
              : style.muted(config.unselectedPrefix);
          final pointer = isHighlighted ? config.pointer : ' ';
          line = ' $pointer $check $label';
        } else {
          final pointer = isHighlighted ? config.pointer : ' ';
          line = ' $pointer $label';
        }

        if (isHighlighted) {
          writeln(_highlight(line));
        } else {
          writeln(line);
        }
      }
    }

    final displayCount = choices.length.clamp(1, config.maxDisplay);
    for (var i = 0; i < displayCount; i++) {
      writeln('');
    }
    render();

    final oldEchoMode = _stdin.echoMode;
    final oldLineMode = _stdin.lineMode;
    try {
      _stdin.echoMode = false;
      _stdin.lineMode = false;

      while (true) {
        final key = _stdin.readByteSync();

        if (key == 27) {
          final next = _stdin.readByteSync();
          if (next == 91) {
            final code = _stdin.readByteSync();
            switch (code) {
              case 65: // Up arrow
                cursor = (cursor - 1) % choices.length;
                if (cursor < 0) cursor = choices.length - 1;
                render();
              case 66: // Down arrow
                cursor = (cursor + 1) % choices.length;
                render();
              case 67: // Right arrow
              case 68: // Left arrow
            }
          } else if (next == 27 || next == -1) {
            _clearRender(displayCount);
            return ChoiceResult(selected: [], cancelled: true);
          }
        } else if (key == 10 || key == 13) {
          _clearRender(displayCount);
          if (multiSelect) {
            final result = selected.map((i) => choices[i]).toList();
            return ChoiceResult(selected: result, cancelled: false);
          } else {
            return ChoiceResult(selected: [choices[cursor]], cancelled: false);
          }
        } else if (key == 32 && multiSelect) {
          if (selected.contains(cursor)) {
            selected.remove(cursor);
          } else {
            selected.add(cursor);
          }
          render();
        } else if (key == 3 || key == 4) {
          _clearRender(displayCount);
          return ChoiceResult(selected: [], cancelled: true);
        } else if (key == 113 || key == 81) {
          _clearRender(displayCount);
          return ChoiceResult(selected: [], cancelled: true);
        }
      }
    } finally {
      _stdin.echoMode = oldEchoMode;
      _stdin.lineMode = oldLineMode;
    }
  }

  void _clearRender(int lines) {
    _stdout.write('\x1B[${lines}A\x1B[J');
  }

  String _highlight(String text) {
    if (!style.enabled) return text;
    return '\x1B[${config.highlightColor}m$text\x1B[0m';
  }
}

/// Reads a password/secret input without echoing to the terminal.
class SecretInput {
  /// Creates a new secret input reader.
  SecretInput({
    required this.style,
    required this.write,
    required this.writeln,
    io.Stdin? stdin,
    io.Stdout? stdout,
  }) : _stdin = stdin ?? io.stdin,
       _stdout = stdout ?? io.stdout;

  /// The style configuration.
  final ArtisanStyle style;

  /// Callback for writing text.
  final void Function(String) write;

  /// Callback for writing a line.
  final void Function(String) writeln;

  final io.Stdin _stdin;
  final io.Stdout _stdout;

  /// Reads a secret/password input without echoing characters.
  String read(String prompt, {String? fallback}) {
    write('${style.emphasize(prompt)}: ');

    try {
      final oldEchoMode = _stdin.echoMode;
      final oldLineMode = _stdin.lineMode;
      try {
        _stdin.echoMode = false;
        _stdin.lineMode = false;

        final buffer = StringBuffer();
        while (true) {
          final byte = _stdin.readByteSync();
          if (byte == -1 || byte == 10 || byte == 13) {
            break;
          } else if (byte == 127 || byte == 8) {
            if (buffer.isNotEmpty) {
              final str = buffer.toString();
              buffer.clear();
              buffer.write(str.substring(0, str.length - 1));
            }
          } else if (byte == 3 || byte == 4) {
            writeln('');
            throw StateError('Input cancelled');
          } else if (byte >= 32 && byte < 127) {
            buffer.writeCharCode(byte);
          }
        }

        writeln('');
        final result = buffer.toString();
        return result.isEmpty ? (fallback ?? '') : result;
      } finally {
        _stdin.echoMode = oldEchoMode;
        _stdin.lineMode = oldLineMode;
      }
    } catch (e) {
      if (e is StateError) rethrow;

      _stdout.write('(input will be visible) ');
      final line = _stdin.readLineSync() ?? '';
      return line.isEmpty ? (fallback ?? '') : line;
    }
  }

  /// Reads a secret input asynchronously.
  Future<String> readAsync(String prompt, {String? fallback}) async {
    return Future(() => read(prompt, fallback: fallback));
  }

  /// Reads a password with optional confirmation.
  ///
  /// If [confirm] is true, prompts the user to re-enter the password
  /// and validates that both entries match.
  ///
  /// ```dart
  /// final password = secretInput.readPassword(
  ///   'Password',
  ///   confirm: true,
  ///   confirmPrompt: 'Confirm password',
  /// );
  /// ```
  String readPassword(
    String prompt, {
    bool confirm = false,
    String confirmPrompt = 'Confirm password',
    String mismatchMessage = 'Passwords do not match. Please try again.',
    int maxAttempts = 3,
    String? fallback,
  }) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final password = read(prompt, fallback: fallback);

      if (!confirm) {
        return password;
      }

      final confirmation = read(confirmPrompt, fallback: fallback);

      if (password == confirmation) {
        return password;
      }

      writeln(style.error(mismatchMessage));
    }

    throw StateError('Too many failed password confirmation attempts.');
  }
}
