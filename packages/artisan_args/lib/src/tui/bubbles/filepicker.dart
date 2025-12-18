import 'dart:io';

import 'package:artisan_args/src/style/color.dart';
import 'package:artisan_args/src/style/style.dart';
import 'package:path/path.dart' as p;

import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import 'key_binding.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Messages
// ─────────────────────────────────────────────────────────────────────────────

/// Message sent when directory contents are read.
class FilePickerReadDirMsg extends Msg {
  const FilePickerReadDirMsg(this.id, this.entries);

  /// The ID of the file picker that requested this directory read.
  final int id;

  /// The directory entries read.
  final List<FileSystemEntity> entries;
}

/// Error message when reading a directory fails.
class FilePickerErrorMsg extends Msg {
  const FilePickerErrorMsg(this.id, this.error);

  /// The ID of the file picker that encountered the error.
  final int id;

  /// The error message.
  final String error;
}

// ─────────────────────────────────────────────────────────────────────────────
// Key Map
// ─────────────────────────────────────────────────────────────────────────────

/// Key mappings for the file picker component.
class FilePickerKeyMap {
  FilePickerKeyMap()
    : goToTop = KeyBinding.withHelp(['g', 'home'], 'g/home', 'go to start'),
      goToLast = KeyBinding.withHelp(['G', 'end'], 'G/end', 'go to end'),
      down = KeyBinding.withHelp(['j', 'down', 'ctrl+n'], 'j/↓', 'down'),
      up = KeyBinding.withHelp(['k', 'up', 'ctrl+p'], 'k/↑', 'up'),
      pageUp = KeyBinding.withHelp(
        ['K', 'pgup', 'ctrl+u'],
        'K/pgup',
        'page up',
      ),
      pageDown = KeyBinding.withHelp(
        ['J', 'pgdown', 'ctrl+d'],
        'J/pgdown',
        'page down',
      ),
      toggleHidden = KeyBinding.withHelp(['.'], '.', 'toggle hidden'),
      back = KeyBinding.withHelp(
        ['h', 'backspace', 'left', 'esc'],
        'h/←',
        'go back',
      ),
      open = KeyBinding.withHelp(['l', 'right', 'enter'], 'l/→/enter', 'open'),
      select = KeyBinding.withHelp(['enter'], 'enter', 'select');

  /// Move cursor to the first item.
  final KeyBinding goToTop;

  /// Move cursor to the last item.
  final KeyBinding goToLast;

  /// Move cursor down one item.
  final KeyBinding down;

  /// Move cursor up one item.
  final KeyBinding up;

  /// Move cursor up one page.
  final KeyBinding pageUp;

  /// Move cursor down one page.
  final KeyBinding pageDown;

  /// Go back to parent directory.
  final KeyBinding back;

  /// Toggle hidden file visibility.
  final KeyBinding toggleHidden;

  /// Open the selected directory.
  final KeyBinding open;

  /// Select the current file or directory.
  final KeyBinding select;

  /// Returns a list of all key bindings for use with help views.
  List<KeyBinding> get fullHelp => [
    goToTop,
    goToLast,
    down,
    up,
    pageUp,
    pageDown,
    toggleHidden,
    back,
    open,
    select,
  ];

  /// Returns a short list of key bindings for compact help views.
  List<KeyBinding> get shortHelp => [up, down, open, back];
}

// ─────────────────────────────────────────────────────────────────────────────
// Styles
// ─────────────────────────────────────────────────────────────────────────────

/// Styles for the file picker component.
class FilePickerStyles {
  FilePickerStyles({
    Style? cursor,
    Style? symlink,
    Style? directory,
    Style? file,
    Style? permission,
    Style? selected,
    Style? disabledCursor,
    Style? disabledFile,
    Style? disabledSelected,
    Style? fileSize,
    Style? emptyDirectory,
  }) : cursor = cursor ?? Style().foreground(AnsiColor(212)),
       symlink = symlink ?? Style().foreground(AnsiColor(36)),
       directory = directory ?? Style().foreground(AnsiColor(99)),
       file = file ?? Style(),
       permission = permission ?? Style().foreground(AnsiColor(244)),
       selected = selected ?? Style().bold().foreground(AnsiColor(212)),
       disabledCursor = disabledCursor ?? Style().foreground(AnsiColor(247)),
       disabledFile = disabledFile ?? Style().foreground(AnsiColor(243)),
       disabledSelected =
           disabledSelected ?? Style().foreground(AnsiColor(247)),
       fileSize = fileSize ?? Style().foreground(AnsiColor(240)).width(7),
       emptyDirectory =
           emptyDirectory ?? Style().foreground(AnsiColor(240)).italic();

  /// Style for the cursor character.
  final Style cursor;

  /// Style for symbolic links.
  final Style symlink;

  /// Style for directories.
  final Style directory;

  /// Style for regular files.
  final Style file;

  /// Style for file permissions.
  final Style permission;

  /// Style for the selected item.
  final Style selected;

  /// Style for disabled cursor (when selecting a disabled file).
  final Style disabledCursor;

  /// Style for disabled files.
  final Style disabledFile;

  /// Style for selected disabled files.
  final Style disabledSelected;

  /// Style for file sizes.
  final Style fileSize;

  /// Style for empty directory message.
  final Style emptyDirectory;
}

// ─────────────────────────────────────────────────────────────────────────────
// View State Stack
// ─────────────────────────────────────────────────────────────────────────────

/// Stores the view state when navigating into directories.
class _ViewState {
  const _ViewState(this.selected, this.min, this.max);

  final int selected;
  final int min;
  final int max;
}

// ─────────────────────────────────────────────────────────────────────────────
// File Entry
// ─────────────────────────────────────────────────────────────────────────────

/// A file entry with cached stat information.
class FileEntry {
  FileEntry({required this.entity, this.stat});

  /// The file system entity.
  final FileSystemEntity entity;

  /// Cached stat information (optional).
  final FileStat? stat;

  /// Returns the file name.
  String get name => p.basename(entity.path);

  /// Returns whether this is a directory.
  bool get isDirectory => entity is Directory;

  /// Returns whether this is a symbolic link.
  bool get isSymlink => stat != null && stat!.type == FileSystemEntityType.link;

  /// Returns the file size.
  int get size => stat?.size ?? 0;

  /// Returns the file mode/permissions.
  int get mode => stat?.mode ?? 0;

  /// Returns permissions as a string (e.g., "rwxr-xr-x").
  String get permissions {
    if (stat == null) return '---------';
    final m = stat!.mode;
    return _modeString(m);
  }

  static String _modeString(int mode) {
    final buf = StringBuffer();
    // Owner
    buf.write(mode & 0x100 != 0 ? 'r' : '-');
    buf.write(mode & 0x80 != 0 ? 'w' : '-');
    buf.write(mode & 0x40 != 0 ? 'x' : '-');
    // Group
    buf.write(mode & 0x20 != 0 ? 'r' : '-');
    buf.write(mode & 0x10 != 0 ? 'w' : '-');
    buf.write(mode & 0x8 != 0 ? 'x' : '-');
    // Other
    buf.write(mode & 0x4 != 0 ? 'r' : '-');
    buf.write(mode & 0x2 != 0 ? 'w' : '-');
    buf.write(mode & 0x1 != 0 ? 'x' : '-');
    return buf.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global ID Counter
// ─────────────────────────────────────────────────────────────────────────────

int _lastFilePickerId = 0;

int _nextFilePickerId() {
  return _lastFilePickerId++;
}

// ─────────────────────────────────────────────────────────────────────────────
// File Picker Model
// ─────────────────────────────────────────────────────────────────────────────

/// A file picker model for navigating and selecting files.
///
/// The file picker displays a list of files and directories and allows
/// the user to navigate through the file system and select files.
///
/// Example:
/// ```dart
/// final picker = FilePickerModel(
///   currentDirectory: Directory.current.path,
///   allowedTypes: ['.dart', '.yaml'],
/// );
/// final (model, cmd) = picker.init();
/// ```
class FilePickerModel extends ViewComponent {
  /// Creates a new file picker model.
  ///
  /// [currentDirectory] is the starting directory.
  /// [allowedTypes] is a list of allowed file extensions (e.g., ['.dart', '.txt']).
  /// [fileAllowed] whether files can be selected.
  /// [dirAllowed] whether directories can be selected.
  /// [showHidden] whether to show hidden files.
  /// [showPermissions] whether to show file permissions.
  /// [showSize] whether to show file sizes.
  /// [height] is the visible height of the file list.
  FilePickerModel({
    required String currentDirectory,
    List<String>? allowedTypes,
    bool fileAllowed = true,
    bool dirAllowed = false,
    bool showHidden = false,
    bool showPermissions = true,
    bool showSize = true,
    int height = 10,
    String cursor = '> ',
    FilePickerKeyMap? keyMap,
    FilePickerStyles? styles,
  }) : _currentDirectory = currentDirectory,
       _allowedTypes = allowedTypes ?? [],
       _fileAllowed = fileAllowed,
       _dirAllowed = dirAllowed,
       _showHidden = showHidden,
       _showPermissions = showPermissions,
       _showSize = showSize,
       _height = height,
       _cursor = cursor,
       _keyMap = keyMap ?? FilePickerKeyMap(),
       _styles = styles ?? FilePickerStyles(),
       _files = [],
       _selected = 0,
       _min = 0,
       _max = height - 1,
       _selectedPath = null,
       _selectedStack = [],
       _id = _nextFilePickerId(),
       _errorMessage = null;

  /// Private constructor for copyWith.
  FilePickerModel._({
    required String currentDirectory,
    required List<String> allowedTypes,
    required bool fileAllowed,
    required bool dirAllowed,
    required bool showHidden,
    required bool showPermissions,
    required bool showSize,
    required int height,
    required String cursor,
    required FilePickerKeyMap keyMap,
    required FilePickerStyles styles,
    required List<FileEntry> files,
    required int selected,
    required int min,
    required int max,
    required String? selectedPath,
    required List<_ViewState> selectedStack,
    required int id,
    String? errorMessage,
  }) : _currentDirectory = currentDirectory,
       _allowedTypes = allowedTypes,
       _fileAllowed = fileAllowed,
       _dirAllowed = dirAllowed,
       _showHidden = showHidden,
       _showPermissions = showPermissions,
       _showSize = showSize,
       _height = height,
       _cursor = cursor,
       _keyMap = keyMap,
       _styles = styles,
       _files = files,
       _selected = selected,
       _min = min,
       _max = max,
       _selectedPath = selectedPath,
       _selectedStack = selectedStack,
       _id = id,
       _errorMessage = errorMessage;

  // ─────────────────────────────────────────────────────────────────────────────
  // Fields
  // ─────────────────────────────────────────────────────────────────────────────

  final String _currentDirectory;
  final List<String> _allowedTypes;
  final bool _fileAllowed;
  final bool _dirAllowed;
  final bool _showHidden;
  final bool _showPermissions;
  final bool _showSize;
  final int _height;
  final String _cursor;
  final FilePickerKeyMap _keyMap;
  final FilePickerStyles _styles;
  final List<FileEntry> _files;
  final int _selected;
  final int _min;
  final int _max;
  final String? _selectedPath;
  final List<_ViewState> _selectedStack;
  final int _id;
  final String? _errorMessage;

  // ─────────────────────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────────────────────

  /// The current directory being displayed.
  String get currentDirectory => _currentDirectory;

  /// The list of allowed file extensions.
  List<String> get allowedTypes => _allowedTypes;

  /// Whether files can be selected.
  bool get fileAllowed => _fileAllowed;

  /// Whether directories can be selected.
  bool get dirAllowed => _dirAllowed;

  /// Whether hidden files are shown.
  bool get showHidden => _showHidden;

  /// Whether permissions are shown.
  bool get showPermissions => _showPermissions;

  /// Whether file sizes are shown.
  bool get showSize => _showSize;

  /// The visible height of the file list.
  int get height => _height;

  /// The cursor string.
  String get cursor => _cursor;

  /// The key map.
  FilePickerKeyMap get keyMap => _keyMap;

  /// The styles.
  FilePickerStyles get styles => _styles;

  /// The files in the current directory.
  List<FileEntry> get files => _files;

  /// The currently selected index.
  int get selected => _selected;

  /// The selected file/directory path (null if nothing selected).
  String? get selectedPath => _selectedPath;

  /// Last error message (read failures, disabled selection, etc.).
  String? get errorMessage => _errorMessage;

  /// Internal ID for this file picker.
  int get id => _id;

  // ─────────────────────────────────────────────────────────────────────────────
  // Copy With
  // ─────────────────────────────────────────────────────────────────────────────

  /// Creates a copy of this model with the given fields replaced.
  FilePickerModel copyWith({
    String? currentDirectory,
    List<String>? allowedTypes,
    bool? fileAllowed,
    bool? dirAllowed,
    bool? showHidden,
    bool? showPermissions,
    bool? showSize,
    int? height,
    String? cursor,
    FilePickerKeyMap? keyMap,
    FilePickerStyles? styles,
    List<FileEntry>? files,
    int? selected,
    int? min,
    int? max,
    String? selectedPath,
    bool clearSelectedPath = false,
    List<_ViewState>? selectedStack,
    int? id,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FilePickerModel._(
      currentDirectory: currentDirectory ?? _currentDirectory,
      allowedTypes: allowedTypes ?? _allowedTypes,
      fileAllowed: fileAllowed ?? _fileAllowed,
      dirAllowed: dirAllowed ?? _dirAllowed,
      showHidden: showHidden ?? _showHidden,
      showPermissions: showPermissions ?? _showPermissions,
      showSize: showSize ?? _showSize,
      height: height ?? _height,
      cursor: cursor ?? _cursor,
      keyMap: keyMap ?? _keyMap,
      styles: styles ?? _styles,
      files: files ?? _files,
      selected: selected ?? _selected,
      min: min ?? _min,
      max: max ?? _max,
      selectedPath: clearSelectedPath ? null : (selectedPath ?? _selectedPath),
      selectedStack: selectedStack ?? _selectedStack,
      id: id ?? _id,
      errorMessage: clearError ? null : (errorMessage ?? _errorMessage),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────────────────────

  /// Initializes the file picker.
  ///
  /// Returns a command to read the initial directory.
  @override
  Cmd? init() {
    return _readDir(_currentDirectory, _showHidden);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Update
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  (FilePickerModel, Cmd?) update(Msg msg) {
    switch (msg) {
      case FilePickerReadDirMsg():
        if (msg.id != _id) return (this, null);
        return _handleReadDir(msg);

      case FilePickerErrorMsg():
        if (msg.id != _id) return (this, null);
        return (copyWith(errorMessage: msg.error), null);

      case KeyMsg():
        return _handleKeyMsg(msg);

      default:
        return (this, null);
    }
  }

  (FilePickerModel, Cmd?) _handleReadDir(FilePickerReadDirMsg msg) {
    final entries = <FileEntry>[];

    for (final entity in msg.entries) {
      // Filter hidden files
      final name = p.basename(entity.path);
      if (!_showHidden && name.startsWith('.')) continue;

      try {
        final stat = entity.statSync();
        entries.add(FileEntry(entity: entity, stat: stat));
      } catch (_) {
        // Skip files we can't stat
        entries.add(FileEntry(entity: entity));
      }
    }

    // Sort: directories first, then by name
    entries.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return (
      copyWith(
        files: entries,
        selected: 0,
        min: 0,
        max: _height - 1,
        clearError: true,
      ),
      null,
    );
  }

  (FilePickerModel, Cmd?) _handleKeyMsg(KeyMsg msg) {
    final key = msg.key;

    // Down
    if (key.matchesSingle(_keyMap.down)) {
      return _moveDown();
    }

    // Up
    if (key.matchesSingle(_keyMap.up)) {
      return _moveUp();
    }

    // Go to top
    if (key.matchesSingle(_keyMap.goToTop)) {
      return _goToTop();
    }

    // Go to last
    if (key.matchesSingle(_keyMap.goToLast)) {
      return _goToLast();
    }

    // Page down
    if (key.matchesSingle(_keyMap.pageDown)) {
      return _pageDown();
    }

    // Page up
    if (key.matchesSingle(_keyMap.pageUp)) {
      return _pageUp();
    }

    // Toggle hidden
    if (key.matchesSingle(_keyMap.toggleHidden)) {
      final newShowHidden = !_showHidden;
      return (
        copyWith(showHidden: newShowHidden, clearError: true),
        _readDir(_currentDirectory, newShowHidden),
      );
    }

    // Back
    if (key.matchesSingle(_keyMap.back)) {
      return _goBack();
    }

    // Open (includes Select behavior)
    if (key.matchesSingle(_keyMap.open)) {
      return _open(key.matchesSingle(_keyMap.select));
    }

    return (this, null);
  }

  (FilePickerModel, Cmd?) _moveDown() {
    if (_files.isEmpty) return (this, null);

    var newSelected = _selected + 1;
    if (newSelected >= _files.length) {
      newSelected = _files.length - 1;
    }

    var newMin = _min;
    var newMax = _max;
    if (newSelected > _max) {
      newMin++;
      newMax++;
    }

    return (copyWith(selected: newSelected, min: newMin, max: newMax), null);
  }

  (FilePickerModel, Cmd?) _moveUp() {
    if (_files.isEmpty) return (this, null);

    var newSelected = _selected - 1;
    if (newSelected < 0) {
      newSelected = 0;
    }

    var newMin = _min;
    var newMax = _max;
    if (newSelected < _min) {
      newMin--;
      newMax--;
    }

    return (copyWith(selected: newSelected, min: newMin, max: newMax), null);
  }

  (FilePickerModel, Cmd?) _goToTop() {
    return (copyWith(selected: 0, min: 0, max: _height - 1), null);
  }

  (FilePickerModel, Cmd?) _goToLast() {
    if (_files.isEmpty) return (this, null);

    final newSelected = _files.length - 1;
    final newMax = newSelected;
    final newMin = (newMax - _height + 1).clamp(0, newMax);

    return (copyWith(selected: newSelected, min: newMin, max: newMax), null);
  }

  (FilePickerModel, Cmd?) _pageDown() {
    if (_files.isEmpty) return (this, null);

    var newSelected = _selected + _height;
    if (newSelected >= _files.length) {
      newSelected = _files.length - 1;
    }

    var newMin = _min + _height;
    var newMax = _max + _height;

    if (newMax >= _files.length) {
      newMax = _files.length - 1;
      newMin = (newMax - _height + 1).clamp(0, newMax);
    }

    return (copyWith(selected: newSelected, min: newMin, max: newMax), null);
  }

  (FilePickerModel, Cmd?) _pageUp() {
    if (_files.isEmpty) return (this, null);

    var newSelected = _selected - _height;
    if (newSelected < 0) {
      newSelected = 0;
    }

    var newMin = _min - _height;
    var newMax = _max - _height;

    if (newMin < 0) {
      newMin = 0;
      newMax = newMin + _height - 1;
    }

    return (copyWith(selected: newSelected, min: newMin, max: newMax), null);
  }

  (FilePickerModel, Cmd?) _goBack() {
    final parentDir = p.dirname(_currentDirectory);

    // Pop view state if available
    final List<_ViewState> newStack;
    final int newSelected;
    final int newMin;
    final int newMax;

    if (_selectedStack.isNotEmpty) {
      final state = _selectedStack.last;
      newStack = _selectedStack.sublist(0, _selectedStack.length - 1);
      newSelected = state.selected;
      newMin = state.min;
      newMax = state.max;
    } else {
      newStack = [];
      newSelected = 0;
      newMin = 0;
      newMax = _height - 1;
    }

    return (
      copyWith(
        currentDirectory: parentDir,
        selectedStack: newStack,
        selected: newSelected,
        min: newMin,
        max: newMax,
      ),
      _readDir(parentDir, _showHidden),
    );
  }

  (FilePickerModel, Cmd?) _open(bool isSelect) {
    if (_files.isEmpty) return (this, null);

    final file = _files[_selected];
    final isDir = file.isDirectory;

    // Handle selection
    if (isSelect) {
      // File selection
      if (!isDir && _fileAllowed) {
        if (canSelect(file.name)) {
          final selectedPath = p.join(_currentDirectory, file.name);
          return (copyWith(selectedPath: selectedPath, clearError: true), null);
        } else {
          final msg = 'Selection disabled for ${file.name}';
          return (copyWith(errorMessage: msg), null);
        }
      }

      // Directory selection
      if (isDir && _dirAllowed) {
        final selectedPath = p.join(_currentDirectory, file.name);
        return (copyWith(selectedPath: selectedPath, clearError: true), null);
      }
    }

    // If it's not a directory, don't navigate
    if (!isDir) return (this, null);

    // Navigate into directory
    final newDir = p.join(_currentDirectory, file.name);

    // Push current view state
    final newStack = [..._selectedStack, _ViewState(_selected, _min, _max)];

    return (
      copyWith(
        currentDirectory: newDir,
        selectedStack: newStack,
        selected: 0,
        min: 0,
        max: _height - 1,
      ),
      _readDir(newDir, _showHidden),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Creates a command to read a directory.
  Cmd _readDir(String path, bool showHidden) {
    return Cmd(() async {
      try {
        final dir = Directory(path);
        final entities = await dir.list().toList();
        return FilePickerReadDirMsg(_id, entities);
      } catch (e) {
        return FilePickerErrorMsg(_id, e.toString());
      }
    });
  }

  /// Checks if a file can be selected based on allowed types.
  bool canSelect(String fileName) {
    if (_allowedTypes.isEmpty) return true;

    for (final ext in _allowedTypes) {
      if (fileName.endsWith(ext)) return true;
    }
    return false;
  }

  /// Returns whether a file was selected on this message.
  ///
  /// Returns a tuple of (didSelect, path).
  (bool, String?) didSelectFile(Msg msg) {
    if (_files.isEmpty) return (false, null);

    if (msg is! KeyMsg) return (false, null);

    if (!msg.key.matchesSingle(_keyMap.select)) {
      return (false, null);
    }

    final file = _files[_selected];
    final isDir = file.isDirectory;

    if (isDir && _dirAllowed && _selectedPath != null) {
      return (true, _selectedPath);
    }

    if (!isDir && _fileAllowed && _selectedPath != null) {
      if (canSelect(p.basename(_selectedPath))) {
        return (true, _selectedPath);
      }
    }

    return (false, null);
  }

  /// Returns whether a disabled file was selected on this message.
  (bool, String?) didSelectDisabledFile(Msg msg) {
    if (_files.isEmpty) return (false, null);

    if (msg is! KeyMsg) return (false, null);

    if (!msg.key.matchesSingle(_keyMap.select)) {
      return (false, null);
    }

    final file = _files[_selected];
    final fileName = file.name;

    if (!file.isDirectory && !canSelect(fileName)) {
      return (true, p.join(_currentDirectory, fileName));
    }

    return (false, null);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // View
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  String view() {
    if (_files.isEmpty) {
      return _styles.emptyDirectory
          .height(_height)
          .maxHeight(_height)
          .render('Folder is empty');
    }

    final buffer = StringBuffer();

    for (var i = 0; i < _files.length; i++) {
      if (i < _min || i > _max) continue;

      final file = _files[i];
      final isSelected = i == _selected;
      final disabled = !canSelect(file.name) && !file.isDirectory;

      if (isSelected) {
        _renderSelectedRow(buffer, file, disabled);
      } else {
        _renderNormalRow(buffer, file, disabled);
      }

      buffer.writeln();
    }

    // Pad with empty lines to fill height
    final visibleCount = (_max - _min + 1).clamp(0, _files.length);
    for (var i = visibleCount; i < _height; i++) {
      buffer.writeln();
    }

    final err = _errorMessage;
    if (err != null && err.isNotEmpty) {
      buffer.writeln(_styles.disabledFile.render(err));
    }

    return buffer.toString();
  }

  void _renderSelectedRow(StringBuffer buffer, FileEntry file, bool disabled) {
    final content = StringBuffer();

    if (_showPermissions) {
      content.write(' ${file.permissions}');
    }

    if (_showSize) {
      content.write(_formatSize(file.size).padLeft(8));
    }

    content.write(' ${file.name}');

    if (file.isSymlink) {
      try {
        final target = Link(file.entity.path).targetSync();
        content.write(' → $target');
      } catch (_) {}
    }

    if (disabled) {
      buffer.write(_styles.disabledCursor.render(_cursor));
      buffer.write(_styles.disabledSelected.render(content.toString()));
    } else {
      buffer.write(_styles.cursor.render(_cursor));
      buffer.write(_styles.selected.render(content.toString()));
    }
  }

  void _renderNormalRow(StringBuffer buffer, FileEntry file, bool disabled) {
    // Empty cursor space
    buffer.write(' ' * _cursor.length);

    if (_showPermissions) {
      buffer.write(' ${_styles.permission.render(file.permissions)}');
    }

    if (_showSize) {
      buffer.write(_styles.fileSize.render(_formatSize(file.size).padLeft(8)));
    }

    buffer.write(' ');

    Style style;
    if (disabled) {
      style = _styles.disabledFile;
    } else if (file.isDirectory) {
      style = _styles.directory;
    } else if (file.isSymlink) {
      style = _styles.symlink;
    } else {
      style = _styles.file;
    }

    buffer.write(style.render(file.name));

    if (file.isSymlink) {
      try {
        final target = Link(file.entity.path).targetSync();
        buffer.write(' → $target');
      } catch (_) {}
    }
  }

  /// Formats a file size in human-readable form.
  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}K';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}G';
  }
}
