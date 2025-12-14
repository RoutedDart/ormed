import '../style/artisan_style.dart';

/// Renders ASCII tables with proper column alignment.
///
/// Handles ANSI sequences correctly when calculating column widths.
///
/// ```dart
/// final table = ArtisanTable(style: style);
/// final output = table.render(
///   headers: ['id', 'name', 'status'],
///   rows: [
///     [1, 'users', 'DONE'],
///     [2, 'posts', 'PENDING'],
///   ],
/// );
/// print(output);
/// ```
class ArtisanTable {
  ArtisanTable({required this.style, this.padding = 1});

  final ArtisanStyle style;
  final int padding;

  /// Renders the table and returns the formatted string.
  String render({
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {
    final normalizedRows = rows
        .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
        .toList(growable: false);

    final columns = headers.length;
    final widths = List<int>.filled(columns, 0);

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
    buffer.writeln(border());
    return buffer.toString().trimRight();
  }
}
