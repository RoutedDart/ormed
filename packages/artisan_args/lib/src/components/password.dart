import 'dart:async';

import '../output/terminal.dart';
import 'base.dart';

/// A password input component that doesn't echo characters.
///
/// ```dart
/// final password = await PasswordComponent(
///   prompt: 'Enter password',
/// ).interact(context);
/// ```
class PasswordComponent extends InteractiveComponent<String> {
  PasswordComponent({
    required this.prompt,
    this.fallback = '',
    this.confirm = false,
    this.confirmPrompt = 'Confirm password',
    this.mismatchMessage = 'Passwords do not match. Please try again.',
    this.maxAttempts = 3,
  });

  final String prompt;
  final String fallback;
  final bool confirm;
  final String confirmPrompt;
  final String mismatchMessage;
  final int maxAttempts;

  @override
  RenderResult build(ComponentContext context) {
    return RenderResult(
      output: '${context.style.emphasize(prompt)}: ',
      lineCount: 1,
    );
  }

  @override
  Future<String> interact(ComponentContext context) async {
    if (confirm) {
      return _readWithConfirmation(context);
    }
    return _readPassword(context, prompt);
  }

  Future<String> _readWithConfirmation(ComponentContext context) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final password = await _readPassword(context, prompt);
      final confirmation = await _readPassword(context, confirmPrompt);

      if (password == confirmation) {
        return password;
      }

      context.writeln(context.style.error(mismatchMessage));
    }

    throw StateError('Too many failed password confirmation attempts.');
  }

  Future<String> _readPassword(
    ComponentContext context,
    String promptText,
  ) async {
    context.write('${context.style.emphasize(promptText)}: ');

    final terminal = Terminal(stdin: context.stdin, stdout: context.stdout);

    try {
      final rawMode = terminal.enableRawMode();
      try {
        final buffer = StringBuffer();
        while (true) {
          final byte = context.stdin.readByteSync();
          if (byte == -1 || byte == KeyCode.enter || byte == KeyCode.enterCR) {
            break;
          } else if (byte == KeyCode.backspace || byte == KeyCode.delete) {
            if (buffer.isNotEmpty) {
              final str = buffer.toString();
              buffer.clear();
              buffer.write(str.substring(0, str.length - 1));
            }
          } else if (byte == KeyCode.ctrlC || byte == KeyCode.ctrlD) {
            context.writeln();
            throw StateError('Input cancelled');
          } else if (byte >= 32 && byte < 127) {
            buffer.writeCharCode(byte);
          }
        }

        context.writeln();
        final result = buffer.toString();
        return result.isEmpty ? fallback : result;
      } finally {
        rawMode.restore();
      }
    } catch (e) {
      if (e is StateError) rethrow;

      // Fallback to visible input
      context.write('(input will be visible) ');
      final line = context.stdin.readLineSync() ?? '';
      return line.isEmpty ? fallback : line;
    }
  }
}
