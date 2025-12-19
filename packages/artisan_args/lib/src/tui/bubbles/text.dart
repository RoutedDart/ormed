import '../../style/ranges.dart' as ranges;
import '../cmd.dart';
import '../msg.dart';
import 'viewport.dart';

/// A high-level text component that supports selection, scrolling, and wrapping.
/// It is built on top of [ViewportModel] but defaults to auto-height and soft-wrap.
class TextModel extends ViewportModel {
  TextModel({
    super.width = 0,
    super.height,
    super.gutter = 0,
    super.yOffset = 0,
    super.xOffset = 0,
    super.mouseWheelEnabled = true,
    super.mouseWheelDelta = 3,
    super.horizontalStep = 0,
    super.softWrap = true,
    super.showLineNumbers = false,
    super.leftGutterFunc,
    super.highlights = const [],
    super.currentHighlightIndex = -1,
    super.selectionStart,
    super.selectionEnd,
    super.keyMap,
    super.lines,
    super.wrappedLines,
    super.originalLines,
  });

  @override
  TextModel copyWith({
    int? width,
    int? height,
    int? gutter,
    int? yOffset,
    int? xOffset,
    bool? mouseWheelEnabled,
    int? mouseWheelDelta,
    int? horizontalStep,
    bool? softWrap,
    bool? showLineNumbers,
    String Function(int)? leftGutterFunc,
    List<ranges.StyleRange>? highlights,
    int? currentHighlightIndex,
    (int, int)? selectionStart,
    (int, int)? selectionEnd,
    ViewportKeyMap? keyMap,
    List<String>? lines,
    List<String>? wrappedLines,
    List<String>? originalLines,
  }) {
    return TextModel(
      width: width ?? this.width,
      height: height ?? this.height,
      gutter: gutter ?? this.gutter,
      yOffset: yOffset ?? this.yOffset,
      xOffset: xOffset ?? this.xOffset,
      mouseWheelEnabled: mouseWheelEnabled ?? this.mouseWheelEnabled,
      mouseWheelDelta: mouseWheelDelta ?? this.mouseWheelDelta,
      horizontalStep: horizontalStep ?? this.horizontalStep,
      softWrap: softWrap ?? this.softWrap,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      leftGutterFunc: leftGutterFunc ?? this.leftGutterFunc,
      highlights: highlights ?? this.highlights,
      currentHighlightIndex: currentHighlightIndex ?? this.currentHighlightIndex,
      selectionStart: selectionStart ?? this.selectionStart,
      selectionEnd: selectionEnd ?? this.selectionEnd,
      keyMap: keyMap ?? this.keyMap,
      lines: lines ?? internalLines,
      wrappedLines: wrappedLines ?? internalWrappedLines,
      originalLines: originalLines ?? internalOriginalLines,
    );
  }

  @override
  TextModel setContent(String content) {
    return super.setContent(content) as TextModel;
  }

  @override
  (TextModel, Cmd?) update(Msg msg) {
    final (newModel, cmd) = super.update(msg);
    return (newModel as TextModel, cmd);
  }
}
