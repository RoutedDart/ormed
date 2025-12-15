import '../style/border.dart' as style_border;
import '../style/color.dart';
import '../style/style.dart';
import 'base.dart';

/// Callback for per-cell styling in tables.
///
/// [row] is the row index (-1 for header row, 0+ for data rows).
/// [col] is the column index.
/// [data] is the cell content as a string.
///
/// Return a [Style] to apply to the cell, or `null` for no styling.
typedef TableStyleFunc = Style? Function(int row, int col, String data);

/// A table component with headers and rows.
///
/// ```dart
/// TableComponent(
///   headers: ['ID', 'Name', 'Status'],
///   rows: [
///     ['1', 'users', 'DONE'],
///     ['2', 'posts', 'PENDING'],
///   ],
///   styleFunc: (row, col, data) {
///     if (data == 'DONE') return Style().foreground(Colors.green);
///     return null;
///   },
/// ).renderln(context);
/// ```
class TableComponent extends CliComponent {
  const TableComponent({
    required this.headers,
    required this.rows,
    this.padding = 1,
    this.styleFunc,
  });

  final List<String> headers;
  final List<List<Object?>> rows;
  final int padding;
  final TableStyleFunc? styleFunc;

  @override
  RenderResult build(ComponentContext context) {
    final normalizedRows = rows
        .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
        .toList(growable: false);

    final columns = headers.length;
    final widths = List<int>.filled(columns, 0);

    // Calculate column widths
    for (var c = 0; c < columns; c++) {
      widths[c] = Style.visibleLength(headers[c]);
    }
    for (final row in normalizedRows) {
      for (var c = 0; c < columns; c++) {
        final cell = c < row.length ? row[c] : '';
        final len = Style.visibleLength(cell);
        if (len > widths[c]) widths[c] = len;
      }
    }

    final pad = ' ' * padding;

    String border() {
      final parts = widths.map((w) => '-' * (w + padding * 2));
      return '+${parts.join('+')}+';
    }

    String rowLine(List<String> cells, int rowIndex) {
      final parts = <String>[];
      for (var c = 0; c < columns; c++) {
        final raw = c < cells.length ? cells[c] : '';
        final visible = Style.visibleLength(raw);
        final fill = widths[c] - visible;
        final fillCount = fill > 0 ? fill : 0;

        var content = raw;
        if (styleFunc != null) {
          final style = styleFunc!(rowIndex, c, raw);
          if (style != null) {
            style.colorProfile = context.colorProfile;
            style.hasDarkBackground = context.hasDarkBackground;
            content = style.render(raw);
          }
        }

        parts.add('$pad$content${' ' * fillCount}$pad');
      }
      return '|${parts.join('|')}|';
    }

    final buffer = StringBuffer();
    buffer.writeln(border());
    buffer.writeln(rowLine(headers, -1)); // Header row is -1
    buffer.writeln(border());
    for (var i = 0; i < normalizedRows.length; i++) {
      buffer.writeln(rowLine(normalizedRows[i], i));
    }
    buffer.write(border());

    // 3 borders + header + data rows
    final lineCount = 3 + normalizedRows.length + 1;

    return RenderResult(output: buffer.toString(), lineCount: lineCount);
  }
}

/// A horizontal table component (row-as-headers style).
///
/// Unlike a regular table where headers are at the top,
/// this displays data with the first column as headers.
///
/// ```dart
/// HorizontalTableComponent(
///   data: {
///     'Name': 'John Doe',
///     'Email': 'john@example.com',
///   },
/// ).renderln(context);
/// ```
class HorizontalTableComponent extends CliComponent {
  const HorizontalTableComponent({
    required this.data,
    this.padding = 1,
    this.separator = '│',
  });

  final Map<String, Object?> data;
  final int padding;
  final String separator;

  @override
  RenderResult build(ComponentContext context) {
    if (data.isEmpty) return RenderResult.empty;

    final headers = data.keys.toList();
    final values = data.values.map((v) => v?.toString() ?? '').toList();

    final maxHeaderWidth = headers
        .map((h) => Style.visibleLength(h))
        .fold<int>(0, (m, v) => v > m ? v : m);

    final buffer = StringBuffer();
    final pad = ' ' * padding;

    for (var i = 0; i < headers.length; i++) {
      final header = headers[i];
      final value = values[i];
      final headerPadding = maxHeaderWidth - Style.visibleLength(header);

      if (i > 0) buffer.writeln();
      buffer.write(
        '$pad${context.newStyle().foreground(Colors.info).render(header)}${' ' * headerPadding}$pad$separator$pad$value',
      );
    }

    return RenderResult(output: buffer.toString(), lineCount: headers.length);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fluent Table Builder
// ─────────────────────────────────────────────────────────────────────────────

/// A fluent builder for creating styled tables.
///
/// Provides a chainable API for table configuration with support for
/// per-cell conditional styling via [styleFunc].
///
/// ```dart
/// final table = Table()
///     .headers(['Name', 'Status', 'Age'])
///     .row(['Alice', 'Active', '25'])
///     .row(['Bob', 'Inactive', '30'])
///     .styleFunc((row, col, data) {
///       if (row == Table.headerRow) {
///         return Style().bold().foreground(Colors.cyan);
///       }
///       if (col == 1 && data == 'Active') {
///         return Style().foreground(Colors.success);
///       }
///       return null;
///     })
///     .border(style_border.Border.rounded)
///     .render();
///
/// print(table);
/// ```
class Table extends FluentComponent<Table> {
  /// Creates a new empty table builder.
  Table();

  /// Row index constant for the header row in [styleFunc].
  static const int headerRow = -1;

  final List<String> _headers = [];
  final List<List<String>> _rows = [];
  TableStyleFunc? _styleFunc;
  style_border.Border _border = style_border.Border.ascii;
  int _padding = 1;
  int? _width;
  Style? _headerStyle;
  Style? _borderStyle;
  Style? _cellStyle;

  /// Sets the table headers.
  Table headers(List<String> headers) {
    _headers.clear();
    _headers.addAll(headers);
    return this;
  }

  /// Adds a row to the table.
  Table row(List<Object?> cells) {
    _rows.add(cells.map((c) => c?.toString() ?? '').toList());
    return this;
  }

  /// Adds multiple rows to the table.
  Table rows(List<List<Object?>> rows) {
    for (final r in rows) {
      row(r);
    }
    return this;
  }

  /// Sets the style function for per-cell conditional styling.
  ///
  /// The function receives [row] (-1 for header), [col], and [data],
  /// and should return a [Style] or `null`.
  Table styleFunc(TableStyleFunc func) {
    _styleFunc = func;
    return this;
  }

  /// Sets the border style.
  Table border(style_border.Border border) {
    _border = border;
    return this;
  }

  /// Sets the cell padding.
  Table padding(int value) {
    _padding = value;
    return this;
  }

  /// Sets the total table width.
  Table width(int value) {
    _width = value;
    return this;
  }

  /// Sets the header row style.
  Table headerStyle(Style style) {
    _headerStyle = style;
    return this;
  }

  /// Sets the border text style.
  Table borderStyle(Style style) {
    _borderStyle = style;
    return this;
  }

  /// Sets the default cell style.
  Table cellStyle(Style style) {
    _cellStyle = style;
    return this;
  }

  /// Renders the table to a string.
  @override
  String render() {
    if (_headers.isEmpty && _rows.isEmpty) return '';

    final columns = _headers.isNotEmpty
        ? _headers.length
        : (_rows.isNotEmpty ? _rows.first.length : 0);

    // Calculate column widths
    final widths = List<int>.filled(columns, 0);

    for (var c = 0; c < columns && c < _headers.length; c++) {
      widths[c] = Style.visibleLength(_headers[c]);
    }
    for (final row in _rows) {
      for (var c = 0; c < columns; c++) {
        final cell = c < row.length ? row[c] : '';
        final len = Style.visibleLength(cell);
        if (len > widths[c]) widths[c] = len;
      }
    }

    // Adjust for fixed width if specified
    if (_width != null) {
      final totalPadding = _padding * 2 * columns;
      final borders = columns + 1; // |col|col|col|
      final available = _width! - totalPadding - borders;
      if (available > 0) {
        final perColumn = available ~/ columns;
        for (var i = 0; i < widths.length; i++) {
          if (widths[i] < perColumn) widths[i] = perColumn;
        }
      }
    }

    final pad = ' ' * _padding;
    final b = _border;

    // Helper to style border characters
    String styleBorderText(String text) {
      if (_borderStyle == null) return text;
      return configureStyle(_borderStyle!).render(text);
    }

    // Build horizontal border line
    String buildBorder(String left, String mid, String right, String fill) {
      final parts = widths.map((w) => fill * (w + _padding * 2));
      return styleBorderText('$left${parts.join(mid)}$right');
    }

    // Build a row with optional styling
    String buildRow(List<String> cells, int rowIndex) {
      final parts = <String>[];
      for (var c = 0; c < columns; c++) {
        final raw = c < cells.length ? cells[c] : '';
        final visible = Style.visibleLength(raw);
        final fill = widths[c] - visible;
        final fillCount = fill > 0 ? fill : 0;

        var cellContent = '$pad$raw${' ' * fillCount}$pad';

        // Apply style function if provided
        if (_styleFunc != null) {
          final style = _styleFunc!(rowIndex, c, raw);
          if (style != null) {
            // Apply style to just the content, not padding
            final styledContent = configureStyle(style).render(raw);
            cellContent = '$pad$styledContent${' ' * fillCount}$pad';
          }
        } else if (rowIndex == headerRow && _headerStyle != null) {
          // Apply header style
          final styledContent = configureStyle(_headerStyle!).render(raw);
          cellContent = '$pad$styledContent${' ' * fillCount}$pad';
        } else if (_cellStyle != null) {
          // Apply default cell style
          final styledContent = configureStyle(_cellStyle!).render(raw);
          cellContent = '$pad$styledContent${' ' * fillCount}$pad';
        }

        parts.add(cellContent);
      }
      return '${styleBorderText(b.left)}${parts.join(styleBorderText(b.left))}${styleBorderText(b.right)}';
    }

    final buffer = StringBuffer();

    // Top border
    buffer.writeln(
      buildBorder(b.topLeft, b.middleTop ?? b.top, b.topRight, b.top),
    );

    // Header row
    if (_headers.isNotEmpty) {
      buffer.writeln(buildRow(_headers, headerRow));
      // Header separator
      buffer.writeln(
        buildBorder(
          b.middleLeft ?? b.left,
          b.middle ?? b.top,
          b.middleRight ?? b.right,
          b.top,
        ),
      );
    }

    // Data rows
    for (var i = 0; i < _rows.length; i++) {
      buffer.writeln(buildRow(_rows[i], i));
    }

    // Bottom border
    buffer.write(
      buildBorder(
        b.bottomLeft,
        b.middleBottom ?? b.bottom,
        b.bottomRight,
        b.bottom,
      ),
    );

    return buffer.toString();
  }

  /// Returns the number of lines in the rendered table.
  @override
  int get lineCount {
    var count = 2; // Top and bottom borders
    if (_headers.isNotEmpty) count += 2; // Header row + separator
    count += _rows.length;
    return count;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Factory Methods
// ─────────────────────────────────────────────────────────────────────────────

/// Factory methods for common table styles.
extension TableFactory on Table {
  /// Creates a simple table from headers and rows.
  static Table fromData(List<String> headers, List<List<Object?>> rows) {
    return Table()
      ..headers(headers)
      ..rows(rows);
  }

  /// Creates a table with rounded borders.
  static Table rounded(List<String> headers, List<List<Object?>> rows) {
    return Table()
      ..headers(headers)
      ..rows(rows)
      ..border(style_border.Border.rounded);
  }

  /// Creates a table with double borders.
  static Table doubleBorder(List<String> headers, List<List<Object?>> rows) {
    return Table()
      ..headers(headers)
      ..rows(rows)
      ..border(style_border.Border.double);
  }

  /// Creates a table with styled headers.
  static Table styled(
    List<String> headers,
    List<List<Object?>> rows, {
    Style? headerStyle,
    style_border.Border? border,
  }) {
    final table = Table()
      ..headers(headers)
      ..rows(rows);

    if (headerStyle != null) table.headerStyle(headerStyle);
    if (border != null) table.border(border);

    return table;
  }

  /// Creates an ASCII-compatible table.
  static Table ascii(List<String> headers, List<List<Object?>> rows) {
    return Table()
      ..headers(headers)
      ..rows(rows)
      ..border(style_border.Border.ascii);
  }

  /// Creates a table with status column styling.
  ///
  /// Automatically colors values in the specified column based on content.
  static Table withStatusColumn(
    List<String> headers,
    List<List<Object?>> rows, {
    int statusColumn = -1, // -1 means last column
    Map<String, Color>? statusColors,
  }) {
    final colors =
        statusColors ??
        {
          'active': Colors.success,
          'done': Colors.success,
          'ok': Colors.success,
          'success': Colors.success,
          'inactive': Colors.warning,
          'pending': Colors.warning,
          'waiting': Colors.warning,
          'error': Colors.error,
          'failed': Colors.error,
          'failure': Colors.error,
        };

    return Table()
      ..headers(headers)
      ..rows(rows)
      ..border(style_border.Border.rounded)
      ..styleFunc((row, col, data) {
        final targetCol = statusColumn < 0
            ? headers.length + statusColumn
            : statusColumn;

        if (row == Table.headerRow) {
          return Style().bold();
        }

        if (col == targetCol) {
          final lowerData = data.toLowerCase();
          for (final entry in colors.entries) {
            if (lowerData.contains(entry.key)) {
              return Style().foreground(entry.value);
            }
          }
        }

        return null;
      });
  }
}
