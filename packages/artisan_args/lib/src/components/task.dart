import '../style/artisan_style.dart';
import 'base.dart';

/// Task status values.
enum TaskStatus { success, failure, skipped, running }

/// A task status component (Laravel-style).
///
/// ```dart
/// TaskComponent(
///   description: 'Running migrations',
///   status: TaskStatus.success,
/// ).renderln(context);
/// ```
class TaskComponent extends CliComponent {
  const TaskComponent({
    required this.description,
    required this.status,
    this.fillChar = '.',
    this.indent = 2,
  });

  final String description;
  final TaskStatus status;
  final String fillChar;
  final int indent;

  @override
  RenderResult build(ComponentContext context) {
    final statusText = switch (status) {
      TaskStatus.success => context.style.success('DONE'),
      TaskStatus.failure => context.style.error('FAIL'),
      TaskStatus.skipped => context.style.warning('SKIP'),
      TaskStatus.running => context.style.info('...'),
    };

    final descLen = ArtisanStyle.visibleLength(description);
    final statusLen = 4; // DONE/FAIL/SKIP
    final available = context.terminalWidth - indent - descLen - statusLen - 2;
    final fill = available > 0 ? ' ${fillChar * available} ' : ' ';

    return RenderResult(
      output: '${' ' * indent}$description$fill$statusText',
      lineCount: 1,
    );
  }
}
