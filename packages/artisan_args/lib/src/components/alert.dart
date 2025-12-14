import 'base.dart';

/// Alert types.
enum AlertType { info, success, warning, error, note }

/// An alert/notice block component.
///
/// ```dart
/// AlertComponent(
///   message: 'This is important!',
///   type: AlertType.warning,
/// ).renderln(context);
/// ```
class AlertComponent extends CliComponent {
  const AlertComponent({required this.message, this.type = AlertType.info});

  final String message;
  final AlertType type;

  @override
  RenderResult build(ComponentContext context) {
    final (prefix, styleFn) = switch (type) {
      AlertType.info => ('[INFO]', context.style.info),
      AlertType.success => ('[OK]', context.style.success),
      AlertType.warning => ('[WARN]', context.style.warning),
      AlertType.error => ('[ERROR]', context.style.error),
      AlertType.note => ('[NOTE]', context.style.muted),
    };

    return RenderResult(output: '${styleFn(prefix)} $message', lineCount: 1);
  }
}
