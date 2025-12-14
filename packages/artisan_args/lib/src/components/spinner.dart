import 'dart:async';

import 'base.dart';

/// A spinner component for showing async progress.
class SpinnerComponent extends InteractiveComponent<void> {
  SpinnerComponent({
    required this.message,
    required this.task,
    this.frames = const ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'],
    this.interval = const Duration(milliseconds: 80),
    this.successMessage,
    this.failureMessage,
  });

  final String message;
  final Future<void> Function() task;
  final List<String> frames;
  final Duration interval;
  final String? successMessage;
  final String? failureMessage;

  @override
  RenderResult build(ComponentContext context) {
    // Initial frame
    final frame = context.style.info(frames.first);
    return RenderResult(output: '$frame $message', lineCount: 1);
  }

  @override
  Future<void> interact(ComponentContext context) async {
    var frameIndex = 0;
    var running = true;

    context.hideCursor();

    // Spinner animation
    final timer = Timer.periodic(interval, (_) {
      if (!running) return;
      context.clearLine();
      final frame = context.style.info(frames[frameIndex]);
      context.write('$frame $message');
      frameIndex = (frameIndex + 1) % frames.length;
    });

    try {
      await task();
      running = false;
      timer.cancel();
      context.clearLine();
      final successText = successMessage ?? message;
      context.writeln('${context.style.success("✓")} $successText');
    } catch (e) {
      running = false;
      timer.cancel();
      context.clearLine();
      final failText = failureMessage ?? message;
      context.writeln('${context.style.error("✗")} $failText');
      rethrow;
    } finally {
      context.showCursor();
    }
  }
}
