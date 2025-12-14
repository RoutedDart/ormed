import 'dart:async';

import '../output/terminal.dart';
import '../style/artisan_style.dart';
import 'base.dart';

/// Configuration for anticipate/autocomplete component.
class AnticipateComponentConfig {
  const AnticipateComponentConfig({
    this.maxSuggestions = 5,
    this.highlightColor = '36',
    this.pointer = '❯',
    this.minCharsToSearch = 1,
  });

  final int maxSuggestions;
  final String highlightColor;
  final String pointer;
  final int minCharsToSearch;
}

/// An autocomplete input component with suggestions.
///
/// ```dart
/// final result = await AnticipateComponent(
///   question: 'Select a country',
///   suggestions: ['USA', 'UK', 'Canada', 'Australia'],
/// ).interact(context);
/// ```
class AnticipateComponent extends InteractiveComponent<String?> {
  AnticipateComponent({
    required this.question,
    required this.suggestions,
    this.defaultValue,
    this.filter,
    this.config = const AnticipateComponentConfig(),
  });

  final String question;
  final List<String> suggestions;
  final String? defaultValue;
  final bool Function(String suggestion, String input)? filter;
  final AnticipateComponentConfig config;

  @override
  RenderResult build(ComponentContext context) {
    final inputText = defaultValue != null
        ? context.style.muted(defaultValue!)
        : '';
    return RenderResult(
      output:
          '${context.style.info('?')} ${context.style.emphasize(question)}: $inputText',
      lineCount: 1,
    );
  }

  @override
  Future<String?> interact(ComponentContext context) async {
    final filterFn =
        filter ??
        (suggestion, input) =>
            suggestion.toLowerCase().contains(input.toLowerCase());

    final terminal = Terminal(stdin: context.stdin, stdout: context.stdout);
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
      if (previousSuggestionCount > 0) {
        for (var i = 0; i < previousSuggestionCount; i++) {
          context.stdout.write('\x1B[1A');
          context.stdout.write('\x1B[2K');
        }
      }
      context.stdout.write('\r\x1B[2K');

      final inputText = buffer.isEmpty
          ? context.style.muted(defaultValue ?? '')
          : buffer.toString();
      context.stdout.write(
        '${context.style.info('?')} ${context.style.emphasize(question)}: $inputText',
      );

      for (var i = 0; i < filteredSuggestions.length; i++) {
        context.stdout.writeln();
        final suggestion = filteredSuggestions[i];
        if (i == selectedIndex) {
          context.stdout.write(
            _highlight(context, '  ${config.pointer} $suggestion'),
          );
        } else {
          context.stdout.write('    $suggestion');
        }
      }

      if (filteredSuggestions.isNotEmpty) {
        context.stdout.write('\x1B[${filteredSuggestions.length}A');
        final col =
            4 + ArtisanStyle.visibleLength(question) + 2 + buffer.length;
        context.stdout.write('\r\x1B[${col}C');
      }

      previousSuggestionCount = filteredSuggestions.length;
    }

    void cleanup() {
      if (previousSuggestionCount > 0) {
        context.stdout.writeln();
        for (var i = 0; i < previousSuggestionCount; i++) {
          context.stdout.write('\x1B[2K');
          if (i < previousSuggestionCount - 1) {
            context.stdout.write('\x1B[1B');
          }
        }
        for (var i = 0; i < previousSuggestionCount; i++) {
          context.stdout.write('\x1B[1A');
        }
      }
      context.stdout.write('\r\x1B[2K');
    }

    context.hideCursor();
    updateSuggestions();
    render();

    final rawMode = terminal.enableRawMode();
    try {
      while (true) {
        final key = context.stdin.readByteSync();

        if (key == KeyCode.escape) {
          final next = context.stdin.readByteSync();
          if (next == 91) {
            final code = context.stdin.readByteSync();
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
            context.showCursor();
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
          context.writeln(
            '${context.style.info('?')} ${context.style.emphasize(question)}: ${context.style.success(result)}',
          );
          context.showCursor();
          return result;
        } else if (key == KeyCode.tab && filteredSuggestions.isNotEmpty) {
          buffer.clear();
          buffer.write(filteredSuggestions[selectedIndex]);
          updateSuggestions();
          render();
        } else if (key == KeyCode.backspace || key == KeyCode.delete) {
          if (buffer.isNotEmpty) {
            final str = buffer.toString();
            buffer.clear();
            buffer.write(str.substring(0, str.length - 1));
            updateSuggestions();
            render();
          }
        } else if (key == KeyCode.ctrlC || key == KeyCode.ctrlD) {
          cleanup();
          context.showCursor();
          return null;
        } else if (KeyCode.isPrintable(key)) {
          buffer.writeCharCode(key);
          updateSuggestions();
          render();
        }
      }
    } finally {
      rawMode.restore();
      context.showCursor();
    }
  }

  String _highlight(ComponentContext context, String text) {
    if (!context.style.enabled) return text;
    return '\x1B[${config.highlightColor}m$text\x1B[0m';
  }
}
