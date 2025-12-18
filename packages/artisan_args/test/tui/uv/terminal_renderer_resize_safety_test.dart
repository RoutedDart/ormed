import 'package:artisan_args/src/tui/uv/buffer.dart';
import 'package:artisan_args/src/tui/uv/cell.dart';
import 'package:artisan_args/src/tui/uv/terminal_renderer.dart';
import 'package:test/test.dart';

final class _TestSink implements StringSink {
  final StringBuffer _b = StringBuffer();

  @override
  void write(Object? obj) => _b.write(obj);

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _b.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _b.writeCharCode(charCode);

  @override
  void writeln([Object? obj = '']) => _b.writeln(obj);
}

void main() {
  test('TerminalRenderer tolerates out-of-bounds cursor during updates', () {
    final out = _TestSink();
    final r = TerminalRenderer(out, env: const ['TERM=xterm-256color']);

    final b = Buffer.create(8, 5);
    b.setCell(0, 0, Cell(content: 'X', width: 1));
    r.render(b);
    r.flush();

    // Simulate a transient resize state where the cursor row is out of bounds.
    r.setPosition(0, b.height());

    // Force an update so rendering hits the code paths that consult the
    // current cursor position.
    b.setCell(1, 0, Cell(content: 'Y', width: 1));

    expect(() => r.render(b), returnsNormally);
  });
}
