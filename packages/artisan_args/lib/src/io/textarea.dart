import 'dart:io' as io;

import '../style/artisan_style.dart';

/// Opens an external editor for multi-line text input.
///
/// ```dart
/// final textarea = Textarea(style: style);
/// final text = await textarea.edit(
///   prompt: 'Enter your message',
///   initialContent: 'Default text...',
/// );
/// ```
class Textarea {
  Textarea({required this.style, this.editor});

  final ArtisanStyle style;

  /// The editor command to use. If null, uses $EDITOR or falls back to common editors.
  final String? editor;

  /// Opens an editor for multi-line text input.
  ///
  /// Returns the edited text, or null if cancelled/failed.
  Future<String?> edit({
    String? prompt,
    String? initialContent,
    String? extension,
    String? helpText,
  }) async {
    // Create temp file
    final tempDir = io.Directory.systemTemp;
    final ext = extension ?? '.txt';
    final tempFile = io.File(
      '${tempDir.path}/artisan_textarea_${DateTime.now().millisecondsSinceEpoch}$ext',
    );

    try {
      // Write initial content with optional help text
      final content = StringBuffer();
      if (helpText != null) {
        for (final line in helpText.split('\n')) {
          content.writeln('# $line');
        }
        content.writeln();
      }
      if (initialContent != null) {
        content.write(initialContent);
      }
      await tempFile.writeAsString(content.toString());

      // Get editor command
      final editorCmd = _getEditor();
      if (editorCmd == null) {
        throw StateError(
          'No editor found. Set \$EDITOR environment variable or install vim/nano/vi.',
        );
      }

      // Show prompt
      if (prompt != null) {
        io.stdout.writeln('${style.info('?')} ${style.emphasize(prompt)}');
        io.stdout.writeln(
          style.muted('  Opening ${_getEditorName(editorCmd)}...'),
        );
      }

      // Open editor - use Process.start with inheritStdio for interactive editors
      final process = await io.Process.start(editorCmd, [
        tempFile.path,
      ], mode: io.ProcessStartMode.inheritStdio);
      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        return null;
      }

      // Read edited content
      var editedContent = await tempFile.readAsString();

      // Remove help text lines (lines starting with #)
      if (helpText != null) {
        final lines = editedContent.split('\n');
        final filteredLines = lines
            .where((line) => !line.startsWith('#'))
            .toList();
        // Remove leading empty lines
        while (filteredLines.isNotEmpty && filteredLines.first.trim().isEmpty) {
          filteredLines.removeAt(0);
        }
        editedContent = filteredLines.join('\n');
      }

      return editedContent.trim();
    } finally {
      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Opens an editor with a template file.
  Future<String?> editWithTemplate({
    String? prompt,
    required String template,
    String? extension,
  }) async {
    return edit(prompt: prompt, initialContent: template, extension: extension);
  }

  String? _getEditor() {
    if (editor != null) return editor;

    // Check environment variable
    final envEditor = io.Platform.environment['EDITOR'];
    if (envEditor != null && envEditor.isNotEmpty) {
      return envEditor;
    }

    // Check VISUAL
    final visual = io.Platform.environment['VISUAL'];
    if (visual != null && visual.isNotEmpty) {
      return visual;
    }

    // Try common editors
    final commonEditors = ['nano', 'vim', 'vi', 'code', 'notepad'];
    for (final ed in commonEditors) {
      if (_commandExists(ed)) {
        return ed;
      }
    }

    return null;
  }

  bool _commandExists(String command) {
    try {
      final result = io.Process.runSync('which', [command]);
      return result.exitCode == 0;
    } catch (_) {
      // On Windows, try where
      try {
        final result = io.Process.runSync('where', [command]);
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

/// Simple function to open editor for text input.
///
/// ```dart
/// final text = await editText(
///   prompt: 'Enter description',
///   style: style,
/// );
/// ```
Future<String?> editText({
  String? prompt,
  String? initialContent,
  String? extension,
  String? helpText,
  required ArtisanStyle style,
  String? editor,
}) async {
  final textarea = Textarea(style: style, editor: editor);
  return textarea.edit(
    prompt: prompt,
    initialContent: initialContent,
    extension: extension,
    helpText: helpText,
  );
}
