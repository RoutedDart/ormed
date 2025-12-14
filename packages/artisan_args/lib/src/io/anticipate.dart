import 'dart:async';
import 'dart:io' as io;

import '../output/terminal.dart';
import '../style/artisan_style.dart';

/// Configuration for anticipate/autocomplete prompt.
class AnticipateConfig {
  const AnticipateConfig({
    this.maxSuggestions = 5,
    this.highlightColor = '36', // cyan
    this.pointer = '❯',
    this.minCharsToSearch = 1,
  });

  final int maxSuggestions;
  final String highlightColor;
  final String pointer;
  final int minCharsToSearch;
}

/// An input prompt with autocomplete suggestions.
///
/// ```dart
/// final anticipate = Anticipate(
///   style: style,
///   stdin: io.stdin,
///   stdout: io.stdout,
/// );
/// final result = await anticipate.run(
///   question: 'Select a country',
///   suggestions: ['USA', 'UK', 'Canada', 'Australia'],
/// );
/// ```
class Anticipate {
  Anticipate({
    required this.style,
    required io.Stdin stdin,
    required io.Stdout stdout,
    this.config = const AnticipateConfig(),
  }) : _stdin = stdin,
       _stdout = stdout,
       _terminal = Terminal(stdin: stdin, stdout: stdout);

  final ArtisanStyle style;
  final AnticipateConfig config;
  final io.Stdin _stdin;
  final io.Stdout _stdout;
  final Terminal _terminal;

  /// Runs the anticipate prompt.
  Future<String?> run({
    required String question,
    required List<String> suggestions,
    String? defaultValue,
    bool Function(String suggestion, String input)? filter,
  }) async {
    final filterFn =
        filter ??
        (suggestion, input) =>
            suggestion.toLowerCase().contains(input.toLowerCase());

    final buffer = StringBuffer();
    if (defaultValue != null) {
      buffer.write(defaultValue);
    }

    var selectedIndex = 0;
    var filteredSuggestions = <String>[];
    var previousSuggestionCount = 0;

    void updateSuggestions() {
      final input = buffer.toString();
      if (input.length < config.minCharsToSearch) {
        filteredSuggestions = [];
      } else {
        filteredSuggestions = suggestions
            .where((s) => filterFn(s, input))
            .take(config.maxSuggestions)
            .toList();
      }
      if (selectedIndex >= filteredSuggestions.length) {
        selectedIndex = filteredSuggestions.isEmpty
            ? 0
            : filteredSuggestions.length - 1;
      }
    }

    void render() {
      // Move up and clear all previous lines
      if (previousSuggestionCount > 0) {
        for (var i = 0; i < previousSuggestionCount; i++) {
          _stdout.write('\x1B[1A'); // Move up
          _stdout.write('\x1B[2K'); // Clear line
        }
      }
      // Clear current input line
      _stdout.write('\r\x1B[2K');

      // Render input line
      final inputText = buffer.isEmpty
          ? style.muted(defaultValue ?? '')
          : buffer.toString();
      _stdout.write(
        '${style.info('?')} ${style.emphasize(question)}: $inputText',
      );

      // Render suggestions below
      for (var i = 0; i < filteredSuggestions.length; i++) {
        _stdout.writeln();
        final suggestion = filteredSuggestions[i];
        if (i == selectedIndex) {
          _stdout.write(_highlight('  ${config.pointer} $suggestion'));
        } else {
          _stdout.write('    $suggestion');
        }
      }

      // Move cursor back to input line
      if (filteredSuggestions.isNotEmpty) {
        _stdout.write('\x1B[${filteredSuggestions.length}A'); // Move up
        // Position cursor at end of input
        final col =
            4 + ArtisanStyle.visibleLength(question) + 2 + buffer.length;
        _stdout.write('\r\x1B[${col}C'); // Move to column
      }

      previousSuggestionCount = filteredSuggestions.length;
    }

    void cleanup() {
      // Clear suggestions
      if (previousSuggestionCount > 0) {
        _stdout.writeln(); // Move to next line first
        for (var i = 0; i < previousSuggestionCount; i++) {
          _stdout.write('\x1B[2K'); // Clear line
          if (i < previousSuggestionCount - 1) {
            _stdout.write('\x1B[1B'); // Move down
          }
        }
        // Move back up
        for (var i = 0; i < previousSuggestionCount; i++) {
          _stdout.write('\x1B[1A');
        }
      }
      _stdout.write('\r\x1B[2K'); // Clear input line
    }

    _terminal.hideCursor();
    updateSuggestions();
    render();

    final rawMode = _terminal.enableRawMode();
    try {
      while (true) {
        final key = _stdin.readByteSync();

        if (key == KeyCode.escape) {
          final next = _stdin.readByteSync();
          if (next == 91) {
            // Arrow keys
            final code = _stdin.readByteSync();
            switch (code) {
              case KeyCode.arrowUp:
                if (filteredSuggestions.isNotEmpty && selectedIndex > 0) {
                  selectedIndex--;
                  render();
                }
              case KeyCode.arrowDown:
                if (filteredSuggestions.isNotEmpty &&
                    selectedIndex < filteredSuggestions.length - 1) {
                  selectedIndex++;
                  render();
                }
            }
          } else if (next == KeyCode.escape || next == -1) {
            // Double escape or timeout - cancel
            cleanup();
            _terminal.showCursor();
            return null;
          }
        } else if (key == KeyCode.enter || key == KeyCode.enterCR) {
          String result;
          if (filteredSuggestions.isNotEmpty &&
              selectedIndex < filteredSuggestions.length) {
            result = filteredSuggestions[selectedIndex];
          } else {
            result = buffer.isEmpty ? (defaultValue ?? '') : buffer.toString();
          }
          cleanup();
          _stdout.writeln(
            '${style.info('?')} ${style.emphasize(question)}: ${style.success(result)}',
          );
          _terminal.showCursor();
          return result;
        } else if (key == KeyCode.tab && filteredSuggestions.isNotEmpty) {
          // Tab to complete with selected suggestion
          buffer.clear();
          buffer.write(filteredSuggestions[selectedIndex]);
          updateSuggestions();
          render();
        } else if (key == KeyCode.backspace ||
            key == KeyCode.delete ||
            key == 8 ||
            key == 127) {
          // Handle backspace (127 on most terminals, 8 on some)
          if (buffer.isNotEmpty) {
            final str = buffer.toString();
            buffer.clear();
            buffer.write(str.substring(0, str.length - 1));
            selectedIndex = 0;
            updateSuggestions();
            render();
          }
        } else if (key == KeyCode.ctrlC || key == KeyCode.ctrlD) {
          cleanup();
          _terminal.showCursor();
          return null;
        } else if (KeyCode.isPrintable(key)) {
          buffer.writeCharCode(key);
          selectedIndex = 0;
          updateSuggestions();
          render();
        }
      }
    } finally {
      rawMode.restore();
      _terminal.showCursor();
    }
  }

  /// Runs anticipate with dynamic suggestions based on input.
  Future<String?> runDynamic({
    required String question,
    required FutureOr<List<String>> Function(String input) getSuggestions,
    String? defaultValue,
  }) async {
    final buffer = StringBuffer();
    if (defaultValue != null) {
      buffer.write(defaultValue);
    }

    var selectedIndex = 0;
    var filteredSuggestions = <String>[];
    var previousSuggestionCount = 0;
    var isLoading = false;

    Future<void> updateSuggestions() async {
      final input = buffer.toString();
      if (input.length < config.minCharsToSearch) {
        filteredSuggestions = [];
        return;
      }

      isLoading = true;
      try {
        final results = await getSuggestions(input);
        filteredSuggestions = results.take(config.maxSuggestions).toList();
      } finally {
        isLoading = false;
      }

      if (selectedIndex >= filteredSuggestions.length) {
        selectedIndex = filteredSuggestions.isEmpty
            ? 0
            : filteredSuggestions.length - 1;
      }
    }

    void render() {
      if (previousSuggestionCount > 0) {
        for (var i = 0; i < previousSuggestionCount; i++) {
          _stdout.write('\x1B[1A\x1B[2K');
        }
      }
      _stdout.write('\r\x1B[2K');

      final inputText = buffer.isEmpty
          ? style.muted(defaultValue ?? '')
          : buffer.toString();
      final loadingIndicator = isLoading ? ' ${style.muted('...')}' : '';
      _stdout.write(
        '${style.info('?')} ${style.emphasize(question)}: $inputText$loadingIndicator',
      );

      for (var i = 0; i < filteredSuggestions.length; i++) {
        _stdout.writeln();
        final suggestion = filteredSuggestions[i];
        if (i == selectedIndex) {
          _stdout.write(_highlight('  ${config.pointer} $suggestion'));
        } else {
          _stdout.write('    $suggestion');
        }
      }

      if (filteredSuggestions.isNotEmpty) {
        _stdout.write('\x1B[${filteredSuggestions.length}A');
        final col =
            4 + ArtisanStyle.visibleLength(question) + 2 + buffer.length;
        _stdout.write('\r\x1B[${col}C');
      }

      previousSuggestionCount = filteredSuggestions.length;
    }

    void cleanup() {
      if (previousSuggestionCount > 0) {
        _stdout.writeln();
        for (var i = 0; i < previousSuggestionCount; i++) {
          _stdout.write('\x1B[2K');
          if (i < previousSuggestionCount - 1) _stdout.write('\x1B[1B');
        }
        for (var i = 0; i < previousSuggestionCount; i++) {
          _stdout.write('\x1B[1A');
        }
      }
      _stdout.write('\r\x1B[2K');
    }

    _terminal.hideCursor();
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
                if (filteredSuggestions.isNotEmpty && selectedIndex > 0) {
                  selectedIndex--;
                  render();
                }
              case KeyCode.arrowDown:
                if (filteredSuggestions.isNotEmpty &&
                    selectedIndex < filteredSuggestions.length - 1) {
                  selectedIndex++;
                  render();
                }
            }
          } else if (next == KeyCode.escape || next == -1) {
            cleanup();
            _terminal.showCursor();
            return null;
          }
        } else if (key == KeyCode.enter || key == KeyCode.enterCR) {
          String result;
          if (filteredSuggestions.isNotEmpty &&
              selectedIndex < filteredSuggestions.length) {
            result = filteredSuggestions[selectedIndex];
          } else {
            result = buffer.isEmpty ? (defaultValue ?? '') : buffer.toString();
          }
          cleanup();
          _stdout.writeln(
            '${style.info('?')} ${style.emphasize(question)}: ${style.success(result)}',
          );
          _terminal.showCursor();
          return result;
        } else if (key == KeyCode.tab && filteredSuggestions.isNotEmpty) {
          buffer.clear();
          buffer.write(filteredSuggestions[selectedIndex]);
          await updateSuggestions();
          render();
        } else if (key == KeyCode.backspace ||
            key == KeyCode.delete ||
            key == 8 ||
            key == 127) {
          // Handle backspace (127 on most terminals, 8 on some)
          if (buffer.isNotEmpty) {
            final str = buffer.toString();
            buffer.clear();
            buffer.write(str.substring(0, str.length - 1));
            selectedIndex = 0;
            await updateSuggestions();
            render();
          }
        } else if (key == KeyCode.ctrlC || key == KeyCode.ctrlD) {
          cleanup();
          _terminal.showCursor();
          return null;
        } else if (KeyCode.isPrintable(key)) {
          buffer.writeCharCode(key);
          selectedIndex = 0;
          await updateSuggestions();
          render();
        }
      }
    } finally {
      rawMode.restore();
      _terminal.showCursor();
    }
  }

  String _highlight(String text) {
    if (!style.enabled) return text;
    return '\x1B[${config.highlightColor}m$text\x1B[0m';
  }
}
