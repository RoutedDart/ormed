import '../style/artisan_style.dart';
import 'base.dart';

/// A table component with headers and rows.
///
/// ```dart
/// TableComponent(
///   headers: ['ID', 'Name', 'Status'],
///   rows: [
///     ['1', 'users', 'DONE'],
///     ['2', 'posts', 'PENDING'],
///   ],
/// ).renderln(context);
/// ```
class TableComponent extends CliComponent {
  const TableComponent({
    required this.headers,
    required this.rows,
    this.padding = 1,
  });

  final List<String> headers;
  final List<List<Object?>> rows;
  final int padding;

  @override
  RenderResult build(ComponentContext context) {
    final normalizedRows = rows
        .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
        .toList(growable: false);

    final columns = headers.length;
    final widths = List<int>.filled(columns, 0);

    // Calculate column widths
    for (var c = 0; c < columns; c++) {
      widths[c] = ArtisanStyle.visibleLength(headers[c]);
    }
    for (final row in normalizedRows) {
      for (var c = 0; c < columns; c++) {
        final cell = c < row.length ? row[c] : '';
        final len = ArtisanStyle.visibleLength(cell);
        if (len > widths[c]) widths[c] = len;
      }
    }

    final pad = ' ' * padding;

    String border() {
      final parts = widths.map((w) => '-' * (w + padding * 2));
      return '+${parts.join('+')}+';
    }

    String rowLine(List<String> cells) {
      final parts = <String>[];
      for (var c = 0; c < columns; c++) {
        final raw = c < cells.length ? cells[c] : '';
        final visible = ArtisanStyle.visibleLength(raw);
        final fill = widths[c] - visible;
        final fillCount = fill > 0 ? fill : 0;
        parts.add('$pad$raw${' ' * fillCount}$pad');
      }
      return '|${parts.join('|')}|';
    }

    final buffer = StringBuffer();
    buffer.writeln(border());
    buffer.writeln(rowLine(headers));
    buffer.writeln(border());
    for (final row in normalizedRows) {
      buffer.writeln(rowLine(row));
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
        .map((h) => ArtisanStyle.visibleLength(h))
        .fold<int>(0, (m, v) => v > m ? v : m);

    final buffer = StringBuffer();
    final pad = ' ' * padding;

    for (var i = 0; i < headers.length; i++) {
      final header = headers[i];
      final value = values[i];
      final headerPadding = maxHeaderWidth - ArtisanStyle.visibleLength(header);

      if (i > 0) buffer.writeln();
      buffer.write(
        '$pad${context.style.info(header)}${' ' * headerPadding}$pad$separator$pad$value',
      );
    }

    return RenderResult(output: buffer.toString(), lineCount: headers.length);
  }
}
