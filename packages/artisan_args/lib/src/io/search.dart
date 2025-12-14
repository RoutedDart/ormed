import 'dart:async';
import 'dart:io' as io;

import '../style/artisan_style.dart';
import '../output/terminal.dart';

/// Configuration for search prompt.
class SearchConfig {
  const SearchConfig({
    this.placeholder = 'Type to search...',
    this.emptyMessage = 'No matches found',
    this.maxResults = 10,
    this.highlightColor = '36', // cyan
    this.pointer = '❯',
  });

  final String placeholder;
  final String emptyMessage;
  final int maxResults;
  final String highlightColor;
  final String pointer;
}

/// A search prompt with fuzzy filtering.
///
/// ```dart
/// final search = SearchPrompt(
///   style: style,
///   stdin: io.stdin,
///   stdout: io.stdout,
/// );
/// final result = await search.run(
///   question: 'Select a package',
///   choices: ['flutter', 'dart', 'pub'],
/// );
/// ```
class SearchPrompt {
  SearchPrompt({
    required this.style,
    required io.Stdin stdin,
    required io.Stdout stdout,
    this.config = const SearchConfig(),
  }) : _stdin = stdin,
       _stdout = stdout,
       _terminal = Terminal(stdin: stdin, stdout: stdout);

  final ArtisanStyle style;
  final SearchConfig config;
  final io.Stdin _stdin;
  final io.Stdout _stdout;
  final Terminal _terminal;

  /// Runs the search prompt.
  Future<T?> run<T>({
    required String question,
    required List<T> choices,
    String Function(T)? display,
    bool Function(T, String)? filter,
  }) async {
    final displayFn = display ?? (v) => v.toString();
    final filterFn =
        filter ??
        (item, query) {
          return displayFn(item).toLowerCase().contains(query.toLowerCase());
        };

    final buffer = StringBuffer();
    var cursor = 0;
    var filteredChoices = choices.toList();

    _terminal.hideCursor();
    _stdout.writeln(style.emphasize(question));

    void render() {
      // Clear previous render
      _terminal.clearPreviousLines(
        filteredChoices.length.clamp(1, config.maxResults) + 1,
      );

      // Search input
      final searchText = buffer.isEmpty
          ? style.muted(config.placeholder)
          : buffer.toString();
      _stdout.writeln('${style.info('/')} $searchText');

      // Filter choices
      final query = buffer.toString();
      filteredChoices = query.isEmpty
          ? choices.toList()
          : choices.where((c) => filterFn(c, query)).toList();

      if (filteredChoices.isEmpty) {
        _stdout.writeln(style.muted('  ${config.emptyMessage}'));
        return;
      }

      // Clamp cursor
      if (cursor >= filteredChoices.length) {
        cursor = filteredChoices.length - 1;
      }
      if (cursor < 0) cursor = 0;

      // Render choices
      final displayCount = filteredChoices.length.clamp(1, config.maxResults);
      for (var i = 0; i < displayCount; i++) {
        final item = filteredChoices[i];
        final label = displayFn(item);
        final isHighlighted = i == cursor;

        if (isHighlighted) {
          _stdout.writeln(_highlight(' ${config.pointer} $label'));
        } else {
          _stdout.writeln('   $label');
        }
      }
    }

    // Initial render
    _stdout.writeln(style.muted('  ${config.placeholder}'));
    for (var i = 0; i < choices.length.clamp(1, config.maxResults); i++) {
      _stdout.writeln('');
    }
    render();

    final rawMode = _terminal.enableRawMode();
    try {
      while (true) {
        final key = _stdin.readByteSync();

        if (key == KeyCode.escape) {
          final next = _stdin.readByteSync();
          if (next == 91) {
            final code = _stdin.readByteSync();
            switch (code) {
              case KeyCode.arrowUp:
                cursor = (cursor - 1).clamp(0, filteredChoices.length - 1);
                render();
              case KeyCode.arrowDown:
                cursor = (cursor + 1).clamp(0, filteredChoices.length - 1);
                render();
            }
          } else if (next == KeyCode.escape || next == -1) {
            // Double escape = cancel
            _finish(filteredChoices.length);
            return null;
          }
        } else if (key == KeyCode.enter || key == KeyCode.enterCR) {
          _finish(filteredChoices.length);
          return filteredChoices.isNotEmpty ? filteredChoices[cursor] : null;
        } else if (key == KeyCode.backspace || key == KeyCode.delete) {
          if (buffer.isNotEmpty) {
            final str = buffer.toString();
            buffer.clear();
            buffer.write(str.substring(0, str.length - 1));
            cursor = 0;
            render();
          }
        } else if (key == KeyCode.ctrlC || key == KeyCode.ctrlD) {
          _finish(filteredChoices.length);
          return null;
        } else if (KeyCode.isPrintable(key)) {
          buffer.writeCharCode(key);
          cursor = 0;
          render();
        }
      }
    } finally {
      rawMode.restore();
      _terminal.showCursor();
    }
  }

  void _finish(int displayedLines) {
    _terminal.clearPreviousLines(
      displayedLines.clamp(1, config.maxResults) + 1,
    );
  }

  String _highlight(String text) {
    if (!style.enabled) return text;
    return '\x1B[${config.highlightColor}m$text\x1B[0m';
  }
}

/// Pauses and waits for any key press.
///
/// ```dart
/// await pause(
///   message: 'Press any key to continue...',
///   stdout: io.stdout,
///   stdin: io.stdin,
/// );
/// ```
Future<void> pause({
  String message = 'Press any key to continue...',
  required io.Stdout stdout,
  required io.Stdin stdin,
  ArtisanStyle? style,
}) async {
  final styleFn = style?.muted ?? ((s) => s);
  stdout.write(styleFn(message));

  final terminal = Terminal(stdin: stdin, stdout: stdout);
  final rawMode = terminal.enableRawMode();
  try {
    stdin.readByteSync();
    stdout.writeln();
  } finally {
    rawMode.restore();
  }
}

/// A countdown timer display.
///
/// ```dart
/// await countdown(
///   seconds: 5,
///   message: 'Starting in',
///   stdout: io.stdout,
///   style: style,
/// );
/// ```
Future<void> countdown({
  required int seconds,
  required io.Stdout stdout,
  String message = 'Continuing in',
  ArtisanStyle? style,
  void Function()? onComplete,
}) async {
  final styleFn = style ?? ArtisanStyle(ansi: stdout.supportsAnsiEscapes);
  final terminal = Terminal(stdout: stdout);

  terminal.hideCursor();
  try {
    for (var i = seconds; i > 0; i--) {
      stdout.write(
        '\r${styleFn.muted(message)} ${styleFn.emphasize('$i')}${styleFn.muted('...')}   ',
      );
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    terminal.clearLine();
    onComplete?.call();
  } finally {
    terminal.showCursor();
  }
}
