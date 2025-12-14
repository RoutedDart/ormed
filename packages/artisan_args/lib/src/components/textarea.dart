import 'dart:async';
import 'dart:io' as io;

import 'base.dart';

/// A textarea component that opens an external editor.
///
/// ```dart
/// final text = await TextareaComponent(
///   prompt: 'Enter description',
/// ).interact(context);
/// ```
class TextareaComponent extends InteractiveComponent<String?> {
  TextareaComponent({
    this.prompt,
    this.initialContent,
    this.extension = '.txt',
    this.helpText,
    this.editor,
  });

  final String? prompt;
  final String? initialContent;
  final String extension;
  final String? helpText;
  final String? editor;

  @override
  RenderResult build(ComponentContext context) {
    if (prompt != null) {
      return RenderResult(
        output:
            '${context.style.info('?')} ${context.style.emphasize(prompt!)}',
        lineCount: 1,
      );
    }
    return RenderResult.empty;
  }

  @override
  Future<String?> interact(ComponentContext context) async {
    final tempDir = io.Directory.systemTemp;
    final tempFile = io.File(
      '${tempDir.path}/artisan_textarea_${DateTime.now().millisecondsSinceEpoch}$extension',
    );

    try {
      // Write initial content
      final content = StringBuffer();
      if (helpText != null) {
        for (final line in helpText!.split('\n')) {
          content.writeln('# $line');
        }
        content.writeln();
      }
      if (initialContent != null) {
        content.write(initialContent);
      }
      await tempFile.writeAsString(content.toString());

      // Get editor
      final editorCmd = _getEditor();
      if (editorCmd == null) {
        throw StateError('No editor found. Set \$EDITOR environment variable.');
      }

      // Show prompt
      if (prompt != null) {
        context.writeln(
          '${context.style.info('?')} ${context.style.emphasize(prompt!)}',
        );
        context.writeln(
          context.style.muted('  Opening ${_getEditorName(editorCmd)}...'),
        );
      }

      // Open editor
      final process = await io.Process.start(editorCmd, [
        tempFile.path,
      ], mode: io.ProcessStartMode.inheritStdio);
      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        return null;
      }

      // Read result
      var editedContent = await tempFile.readAsString();

      // Remove help lines
      if (helpText != null) {
        final lines = editedContent.split('\n');
        final filteredLines = lines.where((l) => !l.startsWith('#')).toList();
        while (filteredLines.isNotEmpty && filteredLines.first.trim().isEmpty) {
          filteredLines.removeAt(0);
        }
        editedContent = filteredLines.join('\n');
      }

      return editedContent.trim();
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  String? _getEditor() {
    if (editor != null) return editor;

    final env = io.Platform.environment;
    if (env['EDITOR'] != null && env['EDITOR']!.isNotEmpty) {
      return env['EDITOR'];
    }
    if (env['VISUAL'] != null && env['VISUAL']!.isNotEmpty) {
      return env['VISUAL'];
    }

    for (final ed in ['nano', 'vim', 'vi', 'code', 'notepad']) {
      if (_commandExists(ed)) return ed;
    }

    return null;
  }

  bool _commandExists(String cmd) {
    try {
      final result = io.Process.runSync('which', [cmd]);
      return result.exitCode == 0;
    } catch (_) {
      try {
        final result = io.Process.runSync('where', [cmd]);
        return result.exitCode == 0;
      } catch (_) {
        return false;
      }
    }
  }

  String _getEditorName(String cmd) {
    final name = cmd.split('/').last.split('\\').last;
    return switch (name) {
      'vim' => 'Vim',
      'vi' => 'Vi',
      'nano' => 'Nano',
      'code' => 'VS Code',
      'notepad' => 'Notepad',
      'emacs' => 'Emacs',
      _ => name,
    };
  }
}
