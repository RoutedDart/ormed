import 'base.dart';

/// A progress indicator component.
class ProgressBar extends CliComponent {
  const ProgressBar({
    required this.current,
    required this.total,
    this.width = 40,
    this.fillChar = '█',
    this.emptyChar = '░',
    this.showPercentage = true,
  });

  final int current;
  final int total;
  final int width;
  final String fillChar;
  final String emptyChar;
  final bool showPercentage;

  @override
  RenderResult build(ComponentContext context) {
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    final filled = (progress * width).round();
    final empty = width - filled;

    final bar = '${fillChar * filled}${emptyChar * empty}';
    final output = showPercentage
        ? '$bar ${(progress * 100).toStringAsFixed(0)}%'
        : bar;

    return RenderResult(output: output, lineCount: 1);
  }
}

/// A spinner frame component (for use in animations).
class SpinnerFrame extends CliComponent {
  const SpinnerFrame({required this.frame, required this.message});

  final String frame;
  final String message;

  @override
  RenderResult build(ComponentContext context) {
    return RenderResult(
      output: '${context.style.info(frame)} $message',
      lineCount: 1,
    );
  }
}
