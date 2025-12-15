import 'dart:io';
import 'package:artisan_args/artisan_args.dart';
import 'package:test/test.dart';

void main() {
  group('Table (fluent builder)', () {
    group('basic construction', () {
      test('creates empty table', () {
        final table = Table();
        expect(table.render(), isEmpty);
      });

      test('creates table with headers', () {
        final table = Table().headers(['A', 'B', 'C']);
        final result = table.render();

        expect(result, contains('A'));
        expect(result, contains('B'));
        expect(result, contains('C'));
      });

      test('creates table with rows', () {
        final table = Table().headers(['Name', 'Age']).row(['Alice', '25']).row(
          ['Bob', '30'],
        );

        final result = table.render();

        expect(result, contains('Alice'));
        expect(result, contains('25'));
        expect(result, contains('Bob'));
        expect(result, contains('30'));
      });

      test('adds multiple rows at once', () {
        final table = Table().headers(['X', 'Y']).rows([
          [1, 2],
          [3, 4],
        ]);

        final result = table.render();

        expect(result, contains('1'));
        expect(result, contains('2'));
        expect(result, contains('3'));
        expect(result, contains('4'));
      });

      test('handles null values in rows', () {
        final table = Table().headers(['A', 'B']).row(['value', null]);

        final result = table.render();

        expect(result, contains('value'));
        // null should be converted to empty string
        expect(result, isNotNull);
      });
    });

    group('borders', () {
      test('uses ASCII border by default', () {
        final table = Table().headers(['X']).row(['Y']);
        final result = table.render();

        expect(result, contains('+'));
        expect(result, contains('-'));
        expect(result, contains('|'));
      });

      test('supports rounded border', () {
        final table = Table().headers(['X']).row(['Y']).border(Border.rounded);

        final result = table.render();

        expect(result, contains('╭'));
        expect(result, contains('╰'));
      });

      test('supports thick border', () {
        final table = Table().headers(['X']).row(['Y']).border(Border.thick);

        final result = table.render();

        expect(result, contains('┏'));
        expect(result, contains('┗'));
        expect(result, contains('━'));
      });

      test('supports double border', () {
        final table = Table().headers(['X']).row(['Y']).border(Border.double);

        final result = table.render();

        expect(result, contains('╔'));
        expect(result, contains('╚'));
        expect(result, contains('═'));
      });
    });

    group('padding', () {
      test('default padding is 1', () {
        final table = Table().headers(['X']).row(['Y']);
        final result = table.render();

        // With padding 1, cell content should have space on each side
        expect(result, contains(' X '));
      });

      test('custom padding works', () {
        final table = Table().headers(['X']).row(['Y']).padding(3);

        final result = table.render();

        // With padding 3, cell content should have 3 spaces on each side
        expect(result, contains('   X   '));
      });

      test('zero padding works', () {
        final table = Table().headers(['X']).row(['Y']).padding(0);

        final result = table.render();

        expect(result, contains('|X|'));
      });
    });

    group('styleFunc', () {
      test('styleFunc is called for header row', () {
        var headerCalled = false;

        final table = Table().headers(['Name']).row(['Alice']).styleFunc((
          row,
          col,
          data,
        ) {
          if (row == Table.headerRow) {
            headerCalled = true;
          }
          return null;
        });

        table.render();

        expect(headerCalled, isTrue);
      });

      test('styleFunc is called for data rows', () {
        final rowIndices = <int>[];

        final table = Table()
            .headers(['X'])
            .row(['A'])
            .row(['B'])
            .row(['C'])
            .styleFunc((row, col, data) {
              if (row >= 0) {
                rowIndices.add(row);
              }
              return null;
            });

        table.render();

        expect(rowIndices, contains(0));
        expect(rowIndices, contains(1));
        expect(rowIndices, contains(2));
      });

      test('styleFunc receives correct column index', () {
        final colIndices = <int>{};

        final table = Table()
            .headers(['A', 'B', 'C'])
            .row(['1', '2', '3'])
            .styleFunc((row, col, data) {
              colIndices.add(col);
              return null;
            });

        table.render();

        expect(colIndices, containsAll([0, 1, 2]));
      });

      test('styleFunc receives cell data', () {
        final cellData = <String>[];

        final table = Table()
            .headers(['Name'])
            .row(['Alice'])
            .row(['Bob'])
            .styleFunc((row, col, data) {
              cellData.add(data);
              return null;
            });

        table.render();

        expect(cellData, contains('Name'));
        expect(cellData, contains('Alice'));
        expect(cellData, contains('Bob'));
      });

      test('styleFunc applies styling to cells', () {
        final table = Table()
            .headers(['Status'])
            .row(['Active'])
            .row(['Inactive'])
            .styleFunc((row, col, data) {
              if (data == 'Active') {
                return Style().bold().foreground(Colors.green);
              }
              return null;
            });

        final result = table.render();

        // Active should have ANSI codes applied
        expect(result, contains('\x1B['));
      });

      test('Table.headerRow constant is -1', () {
        expect(Table.headerRow, equals(-1));
      });
    });

    group('lineCount', () {
      test('calculates correct line count', () {
        final table = Table().headers(['A']).row(['1']).row(['2']);

        // Should be: top border, header, separator, row 1, row 2, bottom border
        expect(table.lineCount, equals(6));
      });

      test('lineCount without headers', () {
        final table = Table().row(['1']).row(['2']);

        // Should be: top border, row 1, row 2, bottom border
        expect(table.lineCount, equals(4));
      });
    });

    group('toString', () {
      test('toString returns rendered table', () {
        final table = Table().headers(['X']).row(['Y']);

        expect(table.toString(), equals(table.render()));
      });
    });

    group('fluent chaining', () {
      test('all methods return Table for chaining', () {
        final table = Table()
            .headers(['A'])
            .row(['1'])
            .rows([
              ['2'],
            ])
            .border(Border.rounded)
            .padding(2)
            .width(50)
            .colorProfile(ColorProfile.trueColor)
            .darkBackground(true)
            .styleFunc((r, c, d) => null);

        expect(table, isA<Table>());
      });
    });
  });

  group('TableStyleFunc', () {
    test('typedef accepts correct signature', () {
      TableStyleFunc func = (int row, int col, String data) {
        return Style().bold();
      };

      expect(func(0, 0, 'test'), isA<Style>());
    });

    test('can return null', () {
      TableStyleFunc func = (int row, int col, String data) {
        return null;
      };

      expect(func(0, 0, 'test'), isNull);
    });
  });

  group('TableComponent (legacy)', () {
    ComponentContext createContext({
      ColorProfile profile = ColorProfile.ascii,
      bool darkBackground = true,
    }) {
      return ComponentContext(
        stdout: stdout,
        stdin: stdin,
        renderer: StringRenderer(
          colorProfile: profile,
          hasDarkBackground: darkBackground,
        ),
      );
    }

    test('supports styleFunc parameter', () {
      final table = TableComponent(
        headers: ['A'],
        rows: [
          ['1'],
        ],
        styleFunc: (row, col, data) {
          if (data == '1') return Style().bold();
          return null;
        },
      );
      // Logic check only, rendering check below
      expect(table.styleFunc, isNotNull);
    });

    test('applies styleFunc during rendering', () {
      final table = TableComponent(
        headers: ['Status'],
        rows: [
          ['Active'],
        ],
        styleFunc: (row, col, data) {
          if (data == 'Active') return Style().foreground(Colors.green);
          return null;
        },
      );

      final result = table.build(
        createContext(profile: ColorProfile.trueColor),
      );

      expect(result.output, contains('\x1B['));
      expect(result.output, contains('Active'));
    });

    test('passes correct row/col usage', () {
      final calls = <String>[];
      final table = TableComponent(
        headers: ['H'],
        rows: [
          ['R0'],
          ['R1'],
        ],
        styleFunc: (row, col, data) {
          calls.add('$row:$col:$data');
          return null;
        },
      );

      table.build(createContext());

      expect(calls, contains('0:0:R0'));
      expect(calls, contains('1:0:R1'));
      // Headers (row -1) should not be styled by styleFunc currently?
      // In my implementation:
      // buffer.writeln(rowLine(headers, -1));
      // And in rowLine:
      // if (styleFunc != null) { style = styleFunc!(rowIndex, ...)}
      // So headers ARE passed with -1.
      expect(calls, contains('-1:0:H'));
    });
  });
}
