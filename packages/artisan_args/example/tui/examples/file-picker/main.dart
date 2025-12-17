/// File picker example ported from Bubble Tea.
library;

import 'dart:io' as io;

import 'package:artisan_args/tui.dart' as tui;

class ClearErrorMsg extends tui.Msg {
  const ClearErrorMsg();
}

tui.Cmd _clearErrorAfter(Duration d) =>
    tui.Cmd.tick(d, (_) => const ClearErrorMsg());

class FilePickerExampleModel implements tui.Model {
  FilePickerExampleModel({
    required this.filepicker,
    this.selectedFile = '',
    this.quitting = false,
    this.error,
  });

  final tui.FilePickerModel filepicker;
  final String selectedFile;
  final bool quitting;
  final String? error;

  @override
  tui.Cmd? init() => filepicker.init();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        final rune = key.runes.isNotEmpty ? key.runes.first : -1;
        if (key.ctrl && rune == 0x63 || rune == 0x71) {
          return (copyWith(quitting: true), tui.Cmd.quit());
        }
      case ClearErrorMsg():
        return (copyWith(error: null), null);
    }

    final cmds = <tui.Cmd?>[];
    final (nextPicker, cmd) = filepicker.update(msg);
    cmds.add(cmd);

    var model = copyWith(filepicker: nextPicker as tui.FilePickerModel);

    final (didSelect, path) = model.filepicker.didSelectFile(msg);
    if (didSelect && path != null) {
      model = model.copyWith(selectedFile: path);
    }

    final (didSelectDisabled, disabledPath) = model.filepicker
        .didSelectDisabledFile(msg);
    if (didSelectDisabled && disabledPath != null) {
      model = model.copyWith(
        selectedFile: '',
        error: '$disabledPath is not valid.',
      );
      cmds.add(_clearErrorAfter(const Duration(seconds: 2)));
    }

    return (model, _batch(cmds));
  }

  FilePickerExampleModel copyWith({
    tui.FilePickerModel? filepicker,
    String? selectedFile,
    bool? quitting,
    String? error,
  }) {
    return FilePickerExampleModel(
      filepicker: filepicker ?? this.filepicker,
      selectedFile: selectedFile ?? this.selectedFile,
      quitting: quitting ?? this.quitting,
      error: error ?? this.error,
    );
  }

  @override
  String view() {
    if (quitting) return '';
    final buffer = StringBuffer()..write('\n  ');
    if (error != null) {
      buffer.write(filepicker.styles.disabledFile.render(error!));
    } else if (selectedFile.isEmpty) {
      buffer.write('Pick a file:');
    } else {
      buffer.write(
        'Selected file: ' + filepicker.styles.selected.render(selectedFile),
      );
    }
    buffer
      ..write('\n\n')
      ..write(filepicker.view())
      ..write('\n');
    return buffer.toString();
  }
}

tui.Cmd? _batch(List<tui.Cmd?> cmds) {
  final filtered = cmds.whereType<tui.Cmd>().toList();
  return filtered.isEmpty ? null : tui.Cmd.batch(filtered);
}

Future<void> main() async {
  final home =
      io.Platform.environment['HOME'] ??
      (io.Platform.isWindows
          ? (io.Platform.environment['USERPROFILE'] ?? '.')
          : '.');
  final picker = tui.FilePickerModel(
    currentDirectory: home,
    allowedTypes: const ['.mod', '.sum', '.go', '.txt', '.md'],
  );

  final result =
      await tui.runProgramWithResult(
            FilePickerExampleModel(filepicker: picker),
            options: const tui.ProgramOptions(
              altScreen: false,
              hideCursor: false,
            ),
          )
          as FilePickerExampleModel;

  final selected = result.selectedFile.isEmpty
      ? '<none>'
      : result.filepicker.styles.selected.render(result.selectedFile);
  io.stdout.writeln('\n  You selected: $selected\n');
}
