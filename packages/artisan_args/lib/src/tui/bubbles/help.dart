import 'package:artisan_args/src/style/style.dart';
import 'package:artisan_args/src/style/color.dart';

import 'key_binding.dart';

/// Styles for the help view.
class HelpStyles {
  /// Creates help styles with defaults.
  HelpStyles({
    this.ellipsis = '…',
    this.shortSeparator = ' • ',
    this.fullSeparator = '    ',
    Style? keyStyle,
    Style? descStyle,
    Style? sepStyle,
  }) : keyStyle = keyStyle ?? Style().foreground(AnsiColor(8)), // Dark gray
       descStyle = descStyle ?? Style().foreground(AnsiColor(7)), // Light gray
       sepStyle = sepStyle ?? Style().foreground(AnsiColor(8)); // Dark gray

  /// The ellipsis character for truncated help.
  final String ellipsis;

  /// Separator for short help items.
  final String shortSeparator;

  /// Separator for full help columns.
  final String fullSeparator;

  /// Style for keys.
  final Style keyStyle;

  /// Style for descriptions.
  final Style descStyle;

  /// Style for separators.
  final Style sepStyle;

  /// Renders styled key text.
  String renderKey(String text) => keyStyle.render(text);

  /// Renders styled description text.
  String renderDesc(String text) => descStyle.render(text);

  /// Renders styled separator.
  String renderSep(String text) => sepStyle.render(text);
}

/// A help view widget for displaying key bindings.
///
/// The help view can display key bindings in two modes:
/// - Short: A single line showing the most important bindings
/// - Full: Multiple columns showing all bindings grouped
///
/// ## Example
///
/// ```dart
/// class MyKeyMap implements KeyMap {
///   final up = KeyBinding.withHelp(['up', 'k'], '↑/k', 'move up');
///   final down = KeyBinding.withHelp(['down', 'j'], '↓/j', 'move down');
///   final quit = KeyBinding.withHelp(['q'], 'q', 'quit');
///
///   @override
///   List<KeyBinding> shortHelp() => [up, down, quit];
///
///   @override
///   List<List<KeyBinding>> fullHelp() => [[up, down], [quit]];
/// }
///
/// class MyModel implements Model {
///   final HelpModel help;
///   final MyKeyMap keyMap;
///
///   MyModel({HelpModel? help, MyKeyMap? keyMap})
///       : help = help ?? HelpModel(),
///         keyMap = keyMap ?? MyKeyMap();
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     // Toggle help with ?
///     if (msg is KeyMsg && msg.key.matchesSingle(CommonKeyBindings.help)) {
///       return (
///         MyModel(help: help.copyWith(showAll: !help.showAll), keyMap: keyMap),
///         null,
///       );
///     }
///     return (this, null);
///   }
///
///   @override
///   String view() => '...\n${help.view(keyMap)}';
/// }
/// ```
class HelpModel {
  /// Creates a new help model.
  HelpModel({this.width = 0, this.showAll = false, HelpStyles? styles})
    : styles = styles ?? HelpStyles();

  /// Maximum width for the help view. 0 means no limit.
  final int width;

  /// Whether to show the full help view.
  final bool showAll;

  /// Styles for the help view.
  final HelpStyles styles;

  /// Creates a copy with the given fields replaced.
  HelpModel copyWith({int? width, bool? showAll, HelpStyles? styles}) {
    return HelpModel(
      width: width ?? this.width,
      showAll: showAll ?? this.showAll,
      styles: styles ?? this.styles,
    );
  }

  /// Renders the help view using the given key map.
  String view(KeyMap keyMap) {
    if (showAll) {
      return fullHelpView(keyMap.fullHelp());
    }
    return shortHelpView(keyMap.shortHelp());
  }

  /// Renders a short help view from a list of key bindings.
  ///
  /// Displays bindings in a single line, truncating with ellipsis if needed.
  String shortHelpView(List<KeyBinding> bindings) {
    if (bindings.isEmpty) return '';

    final buffer = StringBuffer();
    var totalWidth = 0;
    final separator = styles.renderSep(styles.shortSeparator);
    final sepWidth = styles.shortSeparator.length;

    for (var i = 0; i < bindings.length; i++) {
      final binding = bindings[i];
      if (!binding.enabled) continue;

      // Add separator if not first item
      String sep = '';
      if (totalWidth > 0) {
        sep = separator;
      }

      // Build item
      final item =
          '${styles.renderKey(binding.help.key)} '
          '${styles.renderDesc(binding.help.desc)}';
      final itemWidth = binding.help.key.length + 1 + binding.help.desc.length;

      // Check if we need to truncate
      final addedWidth = (sep.isNotEmpty ? sepWidth : 0) + itemWidth;
      if (width > 0 && totalWidth + addedWidth > width) {
        // Add ellipsis if there's room
        final ellipsis = ' ${styles.renderSep(styles.ellipsis)}';
        if (totalWidth + 2 < width) {
          buffer.write(ellipsis);
        }
        break;
      }

      buffer.write(sep);
      buffer.write(item);
      totalWidth += addedWidth;
    }

    return buffer.toString();
  }

  /// Renders a full help view from grouped key bindings.
  ///
  /// Each inner list is rendered as a column of key bindings.
  String fullHelpView(List<List<KeyBinding>> groups) {
    if (groups.isEmpty) return '';

    final columns = <String>[];
    var totalWidth = 0;

    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      if (!_shouldRenderColumn(group)) continue;

      // Build column
      final keys = <String>[];
      final descs = <String>[];

      for (final binding in group) {
        if (!binding.enabled) continue;
        keys.add(binding.help.key);
        descs.add(binding.help.desc);
      }

      // Format column with keys and descriptions side by side
      final column = _formatColumn(keys, descs, i > 0);
      final colWidth = _columnWidth(keys, descs);

      // Check if we need to truncate
      if (width > 0 && totalWidth + colWidth > width) {
        final ellipsis = ' ${styles.ellipsis}';
        if (totalWidth + ellipsis.length < width) {
          columns.add(ellipsis);
        }
        break;
      }

      columns.add(column);
      totalWidth += colWidth;
    }

    // Join columns horizontally
    return _joinColumnsHorizontally(columns);
  }

  bool _shouldRenderColumn(List<KeyBinding> bindings) {
    return bindings.any((b) => b.enabled);
  }

  String _formatColumn(List<String> keys, List<String> descs, bool addSep) {
    if (keys.isEmpty) return '';

    final maxKeyLen = keys.fold<int>(0, (m, k) => k.length > m ? k.length : m);
    final lines = <String>[];

    final sep = addSep ? styles.fullSeparator : '';

    for (var i = 0; i < keys.length; i++) {
      final paddedKey = keys[i].padRight(maxKeyLen);
      lines.add(
        '$sep${styles.renderKey(paddedKey)} '
        '${styles.renderDesc(descs[i])}',
      );
    }

    return lines.join('\n');
  }

  int _columnWidth(List<String> keys, List<String> descs) {
    final maxKeyLen = keys.fold<int>(0, (m, k) => k.length > m ? k.length : m);
    final maxDescLen = descs.fold<int>(
      0,
      (m, d) => d.length > m ? d.length : m,
    );
    return maxKeyLen + 1 + maxDescLen + styles.fullSeparator.length;
  }

  String _joinColumnsHorizontally(List<String> columns) {
    if (columns.isEmpty) return '';
    if (columns.length == 1) return columns.first;

    // Split each column into lines
    final columnLines = columns.map((c) => c.split('\n')).toList();
    final maxLines = columnLines.fold<int>(
      0,
      (m, c) => c.length > m ? c.length : m,
    );

    // Pad each column to have the same number of lines
    for (var col in columnLines) {
      while (col.length < maxLines) {
        col.add('');
      }
    }

    // Calculate the visual width of each column (without ANSI codes)
    final columnWidths = columnLines.map((col) {
      return col.fold<int>(0, (m, line) {
        final stripped = _stripAnsi(line);
        return stripped.length > m ? stripped.length : m;
      });
    }).toList();

    // Join lines from each column
    final result = <String>[];
    for (var lineIdx = 0; lineIdx < maxLines; lineIdx++) {
      final lineParts = <String>[];
      for (var colIdx = 0; colIdx < columnLines.length; colIdx++) {
        var line = columnLines[colIdx][lineIdx];
        // Pad line to column width
        final stripped = _stripAnsi(line);
        final padding = columnWidths[colIdx] - stripped.length;
        if (padding > 0) {
          line = '$line${' ' * padding}';
        }
        lineParts.add(line);
      }
      result.add(lineParts.join(''));
    }

    return result.join('\n');
  }

  /// Strips ANSI escape codes from a string.
  String _stripAnsi(String text) {
    return Style.stripAnsi(text);
  }

  @override
  String toString() => view(_EmptyKeyMap());
}

/// Empty key map for default view().
class _EmptyKeyMap implements KeyMap {
  @override
  List<KeyBinding> shortHelp() => [];

  @override
  List<List<KeyBinding>> fullHelp() => [];
}
