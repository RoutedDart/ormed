import '../style/color.dart';
import 'base.dart';

/// A text input component.
class TextInput extends InteractiveComponent<String> {
  const TextInput({
    required this.prompt,
    this.defaultValue,
    this.validator,
    this.placeholder,
  });

  final String prompt;
  final String? defaultValue;
  final String? Function(String)? validator;
  final String? placeholder;

  @override
  RenderResult build(ComponentContext context) {
    final defaultDisplay = defaultValue != null
        ? context.newStyle().dim().render(' [$defaultValue]')
        : '';
    final placeholderDisplay = placeholder != null
        ? context.newStyle().dim().render(placeholder!)
        : '';

    return RenderResult(
      output:
          '${context.newStyle().foreground(Colors.info).render("?")} ${context.newStyle().foreground(Colors.warning).bold().render(prompt)}$defaultDisplay: $placeholderDisplay',
      lineCount: 1,
    );
  }

  @override
  Future<String?> interact(ComponentContext context) async {
    render(context);

    while (true) {
      final input = context.stdin.readLineSync() ?? '';
      final value = input.isEmpty ? (defaultValue ?? '') : input;

      if (validator != null) {
        final error = validator!(value);
        if (error != null) {
          context.writeln(
            context.newStyle().foreground(Colors.error).render('  $error'),
          );
          render(context); // Re-render prompt
          continue;
        }
      }

      return value;
    }
  }
}

/// A confirmation (yes/no) component.
class Confirm extends InteractiveComponent<bool> {
  const Confirm({required this.prompt, this.defaultValue = false});

  final String prompt;
  final bool defaultValue;

  @override
  RenderResult build(ComponentContext context) {
    final hint = defaultValue ? '[Y/n]' : '[y/N]';
    return RenderResult(
      output:
          '${context.newStyle().foreground(Colors.info).render("?")} ${context.newStyle().foreground(Colors.warning).bold().render(prompt)} ${context.newStyle().dim().render(hint)}: ',
      lineCount: 1,
    );
  }

  @override
  Future<bool?> interact(ComponentContext context) async {
    render(context);

    final input = context.stdin.readLineSync()?.toLowerCase() ?? '';
    if (input.isEmpty) return defaultValue;

    return input == 'y' || input == 'yes' || input == 'true' || input == '1';
  }
}

/// A secret/password input component (no echo).
class SecretInputComponent extends InteractiveComponent<String> {
  const SecretInputComponent({
    required this.prompt,
    this.mask = '*',
    this.showMask = false,
  });

  final String prompt;
  final String mask;
  final bool showMask;

  @override
  RenderResult build(ComponentContext context) {
    return RenderResult(
      output:
          '${context.newStyle().foreground(Colors.info).render("?")} ${context.newStyle().foreground(Colors.warning).bold().render(prompt)}: ',
      lineCount: 1,
    );
  }

  @override
  Future<String?> interact(ComponentContext context) async {
    render(context);

    try {
      final oldEchoMode = context.stdin.echoMode;
      try {
        context.stdin.echoMode = false;
        final value = context.stdin.readLineSync() ?? '';
        context.writeln();
        return value;
      } finally {
        context.stdin.echoMode = oldEchoMode;
      }
    } catch (_) {
      return context.stdin.readLineSync();
    }
  }
}
