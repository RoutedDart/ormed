import '../output/terminal.dart';
import 'base.dart';

/// An interactive single-select component with arrow-key navigation.
class Select<T> extends InteractiveComponent<T> {
  const Select({
    required this.prompt,
    required this.options,
    this.defaultIndex = 0,
    this.display,
    this.maxVisible = 10,
    this.pointer = '❯',
  });

  final String prompt;
  final List<T> options;
  final int defaultIndex;
  final String Function(T)? display;
  final int maxVisible;
  final String pointer;

  @override
  RenderResult build(ComponentContext context) {
    final buffer = StringBuffer();
    buffer.writeln(context.style.emphasize(prompt));

    final displayFn = display ?? (v) => v.toString();
    final displayCount = options.length.clamp(1, maxVisible);

    for (var i = 0; i < displayCount && i < options.length; i++) {
      final item = options[i];
      final label = displayFn(item);
      final isHighlighted = i == defaultIndex;

      if (isHighlighted) {
        buffer.writeln(context.style.info(' $pointer $label'));
      } else {
        buffer.writeln('   $label');
      }
    }

    return RenderResult(output: buffer.toString(), lineCount: displayCount + 1);
  }

  @override
  Future<T?> interact(ComponentContext context) async {
    if (options.isEmpty) return null;

    final displayFn = display ?? (v) => v.toString();
    var cursor = defaultIndex.clamp(0, options.length - 1);
    var scrollOffset = 0;

    void render({bool initial = false}) {
      final displayCount = options.length.clamp(1, maxVisible);

      if (!initial) {
        // Clear previous render
        context.cursorUp(displayCount);
        for (var i = 0; i < displayCount; i++) {
          context.clearLine();
          if (i < displayCount - 1) context.cursorDown();
        }
        context.cursorUp(displayCount - 1);
      }

      // Adjust scroll
      if (cursor < scrollOffset) {
        scrollOffset = cursor;
      } else if (cursor >= scrollOffset + maxVisible) {
        scrollOffset = cursor - maxVisible + 1;
      }

      // Render options
      final end = (scrollOffset + maxVisible).clamp(0, options.length);
      for (var i = scrollOffset; i < end; i++) {
        final item = options[i];
        final label = displayFn(item);
        final isHighlighted = i == cursor;

        if (isHighlighted) {
          context.writeln(context.style.info(' $pointer $label'));
        } else {
          context.writeln('   $label');
        }
      }
    }

    // Initial render
    context.writeln(context.style.emphasize(prompt));
    render(initial: true);

    context.hideCursor();
    final oldEchoMode = context.stdin.echoMode;
    final oldLineMode = context.stdin.lineMode;

    try {
      context.stdin.echoMode = false;
      context.stdin.lineMode = false;

      while (true) {
        final key = context.stdin.readByteSync();

        if (key == KeyCode.escape) {
          final next = context.stdin.readByteSync();
          if (next == 91) {
            final code = context.stdin.readByteSync();
            switch (code) {
              case KeyCode.arrowUp:
                if (cursor > 0) {
                  cursor--;
                  render();
                }
              case KeyCode.arrowDown:
                if (cursor < options.length - 1) {
                  cursor++;
                  render();
                }
            }
          } else if (next == KeyCode.escape || next == -1) {
            // Cancel
            _clearRender(context, options.length.clamp(1, maxVisible) + 1);
            context.showCursor();
            return null;
          }
        } else if (key == KeyCode.enter || key == KeyCode.enterCR) {
          _clearRender(context, options.length.clamp(1, maxVisible) + 1);
          final selected = options[cursor];
          context.writeln(
            '${context.style.emphasize(prompt)}: ${context.style.success(displayFn(selected))}',
          );
          context.showCursor();
          return selected;
        } else if (key == KeyCode.ctrlC || key == KeyCode.ctrlD) {
          _clearRender(context, options.length.clamp(1, maxVisible) + 1);
          context.showCursor();
          return null;
        }
      }
    } finally {
      context.stdin.echoMode = oldEchoMode;
      context.stdin.lineMode = oldLineMode;
      context.showCursor();
    }
  }

  void _clearRender(ComponentContext context, int lines) {
    context.cursorUp(lines);
    for (var i = 0; i < lines; i++) {
      context.clearLine();
      if (i < lines - 1) context.cursorDown();
    }
    context.cursorUp(lines - 1);
  }
}

/// An interactive multi-select component with arrow-key navigation.
class MultiSelect<T> extends InteractiveComponent<List<T>> {
  const MultiSelect({
    required this.prompt,
    required this.options,
    this.defaultSelected = const [],
    this.display,
    this.maxVisible = 10,
    this.pointer = '❯',
    this.selectedIcon = '●',
    this.unselectedIcon = '○',
    this.hint = '(Space to toggle, Enter to confirm)',
  });

  final String prompt;
  final List<T> options;
  final List<int> defaultSelected;
  final String Function(T)? display;
  final int maxVisible;
  final String pointer;
  final String selectedIcon;
  final String unselectedIcon;
  final String? hint;

  @override
  RenderResult build(ComponentContext context) {
    final buffer = StringBuffer();
    final displayFn = display ?? (v) => v.toString();

    buffer.writeln(context.style.emphasize(prompt));
    if (hint != null) {
      buffer.writeln(context.style.muted('  $hint'));
    }

    final displayCount = options.length.clamp(1, maxVisible);
    for (var i = 0; i < displayCount && i < options.length; i++) {
      final item = options[i];
      final label = displayFn(item);
      final isHighlighted = i == 0;
      final isSelected = defaultSelected.contains(i);

      final icon = isSelected
          ? context.style.success(selectedIcon)
          : context.style.muted(unselectedIcon);
      final ptr = isHighlighted ? pointer : ' ';
      final text = isHighlighted ? context.style.info(label) : label;

      buffer.writeln('  $ptr $icon $text');
    }

    final headerLines = hint != null ? 2 : 1;
    return RenderResult(
      output: buffer.toString(),
      lineCount: displayCount + headerLines,
    );
  }

  @override
  Future<List<T>?> interact(ComponentContext context) async {
    if (options.isEmpty) return [];

    final displayFn = display ?? (v) => v.toString();
    var cursor = 0;
    var scrollOffset = 0;
    final selected = Set<int>.from(defaultSelected);

    void render({bool initial = false}) {
      final displayCount = options.length.clamp(1, maxVisible);
      final headerLines = hint != null ? 2 : 1;
      final totalLines = displayCount + headerLines;

      if (!initial) {
        context.cursorUp(totalLines);
        for (var i = 0; i < totalLines; i++) {
          context.clearLine();
          if (i < totalLines - 1) context.cursorDown();
        }
        context.cursorUp(totalLines - 1);
      }

      // Header
      context.writeln(context.style.emphasize(prompt));
      if (hint != null) {
        context.writeln(context.style.muted('  $hint'));
      }

      // Adjust scroll
      if (cursor < scrollOffset) {
        scrollOffset = cursor;
      } else if (cursor >= scrollOffset + maxVisible) {
        scrollOffset = cursor - maxVisible + 1;
      }

      // Render options
      final end = (scrollOffset + maxVisible).clamp(0, options.length);
      for (var i = scrollOffset; i < end; i++) {
        final item = options[i];
        final label = displayFn(item);
        final isHighlighted = i == cursor;
        final isSelected = selected.contains(i);

        final icon = isSelected
            ? context.style.success(selectedIcon)
            : context.style.muted(unselectedIcon);
        final ptr = isHighlighted ? pointer : ' ';
        final text = isHighlighted ? context.style.info(label) : label;

        context.writeln('  $ptr $icon $text');
      }
    }

    render(initial: true);

    context.hideCursor();
    final oldEchoMode = context.stdin.echoMode;
    final oldLineMode = context.stdin.lineMode;

    try {
      context.stdin.echoMode = false;
      context.stdin.lineMode = false;

      while (true) {
        final key = context.stdin.readByteSync();

        if (key == KeyCode.escape) {
          final next = context.stdin.readByteSync();
          if (next == 91) {
            final code = context.stdin.readByteSync();
            switch (code) {
              case KeyCode.arrowUp:
                if (cursor > 0) {
                  cursor--;
                  render();
                }
              case KeyCode.arrowDown:
                if (cursor < options.length - 1) {
                  cursor++;
                  render();
                }
            }
          } else if (next == KeyCode.escape || next == -1) {
            _clearRender(context, _totalLines);
            context.showCursor();
            return null;
          }
        } else if (key == KeyCode.space) {
          if (selected.contains(cursor)) {
            selected.remove(cursor);
          } else {
            selected.add(cursor);
          }
          render();
        } else if (key == KeyCode.enter || key == KeyCode.enterCR) {
          _clearRender(context, _totalLines);
          final result = selected.toList()
            ..sort()
            ..map((i) => options[i]).toList();
          final values = result.map((i) => options[i]).toList();
          final displayStr = values.isEmpty
              ? context.style.muted('(none)')
              : context.style.success(values.map(displayFn).join(', '));
          context.writeln('${context.style.emphasize(prompt)}: $displayStr');
          context.showCursor();
          return values;
        } else if (key == KeyCode.ctrlC || key == KeyCode.ctrlD) {
          _clearRender(context, _totalLines);
          context.showCursor();
          return null;
        } else if (key == 97) {
          // 'a' to toggle all
          if (selected.length == options.length) {
            selected.clear();
          } else {
            selected.addAll(List.generate(options.length, (i) => i));
          }
          render();
        }
      }
    } finally {
      context.stdin.echoMode = oldEchoMode;
      context.stdin.lineMode = oldLineMode;
      context.showCursor();
    }
  }

  int get _totalLines {
    final displayCount = options.length.clamp(1, maxVisible);
    return displayCount + (hint != null ? 2 : 1);
  }

  void _clearRender(ComponentContext context, int lines) {
    context.cursorUp(lines);
    for (var i = 0; i < lines; i++) {
      context.clearLine();
      if (i < lines - 1) context.cursorDown();
    }
    context.cursorUp(lines - 1);
  }
}
