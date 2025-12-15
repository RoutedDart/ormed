import 'dart:async';

import '../output/terminal.dart';
import '../style/color.dart';
import 'base.dart';

/// Configuration for search component.
class SearchComponentConfig {
  const SearchComponentConfig({
    this.placeholder = 'Type to search...',
    this.emptyMessage = 'No matches found',
    this.maxResults = 10,
    this.highlightColor = '36',
    this.pointer = '❯',
  });

  final String placeholder;
  final String emptyMessage;
  final int maxResults;
  final String highlightColor;
  final String pointer;
}

/// A search prompt component with fuzzy filtering.
///
/// ```dart
/// final result = await SearchComponent<String>(
///   question: 'Select a package',
///   choices: ['flutter', 'dart', 'pub'],
/// ).interact(context);
/// ```
class SearchComponent<T> extends InteractiveComponent<T?> {
  SearchComponent({
    required this.question,
    required this.choices,
    this.display,
    this.filter,
    this.config = const SearchComponentConfig(),
  });

  final String question;
  final List<T> choices;
  final String Function(T)? display;
  final bool Function(T, String)? filter;
  final SearchComponentConfig config;

  @override
  RenderResult build(ComponentContext context) {
    final buffer = StringBuffer();
    buffer.writeln(
      context.newStyle().foreground(Colors.warning).bold().render(question),
    );
    buffer.write(
      '${context.newStyle().foreground(Colors.info).render('/')} ${context.newStyle().dim().render(config.placeholder)}',
    );
    return RenderResult(output: buffer.toString(), lineCount: 2);
  }

  @override
  Future<T?> interact(ComponentContext context) async {
    final displayFn = display ?? (v) => v.toString();
    final filterFn =
        filter ??
        (item, query) =>
            displayFn(item).toLowerCase().contains(query.toLowerCase());

    final terminal = Terminal(stdin: context.stdin, stdout: context.stdout);
    final buffer = StringBuffer();
    var cursor = 0;
    var filteredChoices = choices.toList();

    context.hideCursor();
    context.writeln(
      context.newStyle().foreground(Colors.warning).bold().render(question),
    );

    void render() {
      terminal.clearPreviousLines(
        filteredChoices.length.clamp(1, config.maxResults) + 1,
      );

      final searchText = buffer.isEmpty
          ? context.newStyle().dim().render(config.placeholder)
          : buffer.toString();
      context.writeln(
        '${context.newStyle().foreground(Colors.info).render('/')} $searchText',
      );

      final query = buffer.toString();
      filteredChoices = query.isEmpty
          ? choices.toList()
          : choices.where((c) => filterFn(c, query)).toList();

      if (filteredChoices.isEmpty) {
        context.writeln(
          context.newStyle().dim().render('  ${config.emptyMessage}'),
        );
        return;
      }

      if (cursor >= filteredChoices.length) {
        cursor = filteredChoices.length - 1;
      }
      if (cursor < 0) cursor = 0;

      final displayCount = filteredChoices.length.clamp(1, config.maxResults);
      for (var i = 0; i < displayCount; i++) {
        final item = filteredChoices[i];
        final label = displayFn(item);
        final isHighlighted = i == cursor;

        if (isHighlighted) {
          context.writeln(_highlight(context, ' ${config.pointer} $label'));
        } else {
          context.writeln('   $label');
        }
      }
    }

    // Initial render
    context.writeln(context.newStyle().dim().render('  ${config.placeholder}'));
    for (var i = 0; i < choices.length.clamp(1, config.maxResults); i++) {
      context.writeln('');
    }
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
                cursor = (cursor - 1).clamp(0, filteredChoices.length - 1);
                render();
              case KeyCode.arrowDown:
                cursor = (cursor + 1).clamp(0, filteredChoices.length - 1);
                render();
            }
          } else if (next == KeyCode.escape || next == -1) {
            _finish(terminal, filteredChoices.length);
            return null;
          }
        } else if (key == KeyCode.enter || key == KeyCode.enterCR) {
          _finish(terminal, filteredChoices.length);
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
          _finish(terminal, filteredChoices.length);
          return null;
        } else if (KeyCode.isPrintable(key)) {
          buffer.writeCharCode(key);
          cursor = 0;
          render();
        }
      }
    } finally {
      rawMode.restore();
      context.showCursor();
    }
  }

  void _finish(Terminal terminal, int displayedLines) {
    terminal.clearPreviousLines(displayedLines.clamp(1, config.maxResults) + 1);
  }

  String _highlight(ComponentContext context, String text) {
    if (context.colorProfile == ColorProfile.ascii) return text;
    return '\x1B[${config.highlightColor}m$text\x1B[0m';
  }
}

/// A pause component that waits for any key press.
///
/// ```dart
/// await PauseComponent(
///   message: 'Press any key to continue...',
/// ).interact(context);
/// ```
class PauseComponent extends InteractiveComponent<void> {
  PauseComponent({this.message = 'Press any key to continue...'});

  final String message;

  @override
  RenderResult build(ComponentContext context) {
    return RenderResult(
      output: context.newStyle().dim().render(message),
      lineCount: 1,
    );
  }

  @override
  Future<void> interact(ComponentContext context) async {
    context.write(context.newStyle().dim().render(message));

    final terminal = Terminal(stdin: context.stdin, stdout: context.stdout);
    final rawMode = terminal.enableRawMode();
    try {
      context.stdin.readByteSync();
      context.writeln();
    } finally {
      rawMode.restore();
    }
  }
}

/// A countdown component that displays a timer.
///
/// ```dart
/// await CountdownComponent(
///   seconds: 5,
///   message: 'Starting in',
/// ).interact(context);
/// ```
class CountdownComponent extends InteractiveComponent<void> {
  CountdownComponent({
    required this.seconds,
    this.message = 'Continuing in',
    this.onComplete,
  });

  final int seconds;
  final String message;
  final void Function()? onComplete;

  @override
  RenderResult build(ComponentContext context) {
    return RenderResult(
      output:
          '${context.newStyle().dim().render(message)} ${context.newStyle().foreground(Colors.warning).bold().render('$seconds')}${context.newStyle().dim().render('...')}',
      lineCount: 1,
    );
  }

  @override
  Future<void> interact(ComponentContext context) async {
    context.hideCursor();
    try {
      for (var i = seconds; i > 0; i--) {
        context.write(
          '\r${context.newStyle().dim().render(message)} ${context.newStyle().foreground(Colors.warning).bold().render('$i')}${context.newStyle().dim().render('...')}   ',
        );
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      context.clearLine();
      onComplete?.call();
    } finally {
      context.showCursor();
    }
  }
}
