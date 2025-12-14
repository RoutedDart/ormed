import 'base.dart';

/// A simple text component.
class Text extends CliComponent {
  const Text(this.text, {this.style});

  final String text;
  final String Function(String)? style;

  @override
  RenderResult build(ComponentContext context) {
    final output = style != null ? style!(text) : text;
    final lines = output.split('\n').length;
    return RenderResult(output: output, lineCount: lines);
  }
}

/// A styled text component using the context's style.
class StyledText extends CliComponent {
  const StyledText.info(this.text) : _type = _StyleType.info;
  const StyledText.success(this.text) : _type = _StyleType.success;
  const StyledText.warning(this.text) : _type = _StyleType.warning;
  const StyledText.error(this.text) : _type = _StyleType.error;
  const StyledText.muted(this.text) : _type = _StyleType.muted;
  const StyledText.emphasize(this.text) : _type = _StyleType.emphasize;
  const StyledText.heading(this.text) : _type = _StyleType.heading;

  final String text;
  final _StyleType _type;

  @override
  RenderResult build(ComponentContext context) {
    final output = switch (_type) {
      _StyleType.info => context.style.info(text),
      _StyleType.success => context.style.success(text),
      _StyleType.warning => context.style.warning(text),
      _StyleType.error => context.style.error(text),
      _StyleType.muted => context.style.muted(text),
      _StyleType.emphasize => context.style.emphasize(text),
      _StyleType.heading => context.style.heading(text),
    };
    return RenderResult(output: output, lineCount: 1);
  }
}

enum _StyleType { info, success, warning, error, muted, emphasize, heading }

/// A horizontal rule/separator component.
class Rule extends CliComponent {
  const Rule({this.text, this.char = '─'});

  final String? text;
  final String char;

  @override
  RenderResult build(ComponentContext context) {
    final width = context.terminalWidth;

    if (text == null) {
      return RenderResult(output: char * width, lineCount: 1);
    }

    final label = ' $text ';
    final remaining = width - label.length;
    final left = remaining ~/ 2;
    final right = remaining - left;

    return RenderResult(
      output: '${char * left}$label${char * right}',
      lineCount: 1,
    );
  }
}
