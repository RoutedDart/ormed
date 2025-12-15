import '../style/color.dart';
import '../style/style.dart';
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
      TaskStatus.success => context.newStyle().foreground(Colors.success).bold().render('DONE'),
      TaskStatus.failure => context.newStyle().foreground(Colors.error).bold().render('FAIL'),
      TaskStatus.skipped => context.newStyle().foreground(Colors.warning).bold().render('SKIP'),
      TaskStatus.running => context.newStyle().foreground(Colors.info).bold().render('...'),
    };

    final descLen = Style.visibleLength(description);
    final statusLen = 4; // DONE/FAIL/SKIP
    final available = context.terminalWidth - indent - descLen - statusLen - 2;
    final fill = available > 0 ? ' ${fillChar * available} ' : ' ';

    return RenderResult(
      output: '${' ' * indent}$description$fill$statusText',
      lineCount: 1,
    );
  }
}
