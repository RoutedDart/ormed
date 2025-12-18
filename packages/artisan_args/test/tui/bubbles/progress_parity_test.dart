import 'package:artisan_args/src/tui/bubbles/progress.dart';
import 'package:test/test.dart';

void main() {
  group('Progress parity', () {
    test('setPercent without animation jumps immediately', () {
      final model = ProgressModel();
      final (next, cmd) = model.setPercent(0.5, animate: false);
      expect(cmd, isNull);
      expect(next.percentShown, closeTo(0.5, 1e-6));
    });

    test('animated progress advances smoothly, not all at once', () {
      final model = ProgressModel();
      final (targeted, cmd) = model.setPercent(1.0);
      expect(cmd, isNotNull);
      expect(targeted.percentShown, closeTo(0, 1e-6));

      final msg = ProgressFrameMsg(id: targeted.id, tag: targeted.tag);
      final (advanced, _) = targeted.update(msg);
      final progressed = advanced;

      expect(progressed.percentShown, greaterThan(0));
      expect(progressed.percentShown, lessThan(1));
    });
  });
}
