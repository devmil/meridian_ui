import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'scrollbar.dart';
import 'selection.dart';

/// Paints [marks] (search hits, changed words) and a [selection] behind
/// the text of its single-line or wrapping [Text] child. Ranges are UTF-16
/// offsets into the displayed text; a range past its end is clipped.
///
/// [markColor] defaults to `attention-bg`, [selectionColor] to
/// `accent-soft`. The child must be a [Text] (or [RichText]); other
/// children are painted without marks.
class MeridianLineMarks extends SingleChildRenderObjectWidget {
  const MeridianLineMarks({
    required this.marks,
    super.key,
    this.markColor,
    this.markRadius,
    this.selection,
    this.selectionColor,
    super.child,
  });

  final List<TextRange> marks;
  final Color? markColor;

  /// Defaults to `radius-xs`.
  final Radius? markRadius;
  final TextRange? selection;
  final Color? selectionColor;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    return _RenderLineMarks(
      marks,
      markColor ?? meridian.colors.attentionBg,
      markRadius ?? Radius.circular(meridian.radius.xs),
      selection,
      selectionColor ?? meridian.colors.accentSoft,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final meridian = MeridianTheme.of(context);
    (renderObject as _RenderLineMarks)
      ..marks = marks
      ..markColor = markColor ?? meridian.colors.attentionBg
      ..markRadius = markRadius ?? Radius.circular(meridian.radius.xs)
      ..selection = selection
      ..selectionColor = selectionColor ?? meridian.colors.accentSoft;
  }
}

class _RenderLineMarks extends RenderProxyBox {
  _RenderLineMarks(
    this._marks,
    this._markColor,
    this._markRadius,
    this._selection,
    this._selectionColor,
  );

  List<TextRange> _marks;
  set marks(List<TextRange> value) {
    if (listEquals(value, _marks)) return;
    _marks = value;
    markNeedsPaint();
  }

  Color _markColor;
  set markColor(Color value) {
    if (value == _markColor) return;
    _markColor = value;
    markNeedsPaint();
  }

  Radius _markRadius;
  set markRadius(Radius value) {
    if (value == _markRadius) return;
    _markRadius = value;
    markNeedsPaint();
  }

  TextRange? _selection;
  set selection(TextRange? value) {
    if (value == _selection) return;
    _selection = value;
    markNeedsPaint();
  }

  Color _selectionColor;
  set selectionColor(Color value) {
    if (value == _selectionColor) return;
    _selectionColor = value;
    markNeedsPaint();
  }

  /// The [RenderParagraph] that draws the text: the child, or the first
  /// one below it.
  RenderParagraph? get _paragraph {
    RenderObject? node = child;
    while (node != null) {
      if (node is RenderParagraph) return node;
      RenderObject? next;
      node.visitChildren((child) => next ??= child);
      node = next;
    }
    return null;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final paragraph = _paragraph;
    if (paragraph != null && paragraph.hasSize) {
      final canvas = context.canvas;
      final shift = paragraph.localToGlobal(Offset.zero, ancestor: this);
      final length = paragraph.text.toPlainText().length;
      Iterable<Rect> boxes(TextRange range) {
        final start = range.start.clamp(0, length);
        final end = range.end.clamp(0, length);
        if (end <= start) return const [];
        return paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: start, extentOffset: end),
            )
            .map((box) => box.toRect().shift(offset + shift));
      }

      final markPaint = Paint()..color = _markColor;
      for (final mark in _marks) {
        for (final rect in boxes(mark)) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, _markRadius),
            markPaint,
          );
        }
      }
      if (_selection case final selection? when !selection.isCollapsed) {
        final selectionPaint = Paint()..color = _selectionColor;
        for (final rect in boxes(selection)) {
          canvas.drawRect(rect, selectionPaint);
        }
      }
    }
    super.paint(context, offset);
  }
}

/// Scrolls the text of many rows sideways by one shared offset, while the
/// rows themselves (their gutters, backgrounds and headers) keep the
/// viewport's width: a code view, a diff, a log.
///
/// [child] holds the rows (usually a vertical list); each row wraps the
/// part that scrolls in a [MeridianHorizontalShift] with the same
/// [controller]. [contentWidth] is the widest row's text; [fixedWidth] the
/// part of a row that does not scroll (gutters, padding). With [columns]
/// side by side (a two-column diff), each column gets an equal share of
/// the width, hairlines between them excluded. While the text is wider
/// than its column a horizontal scrollbar shows in a strip below the rows
/// ([MeridianLayout.scrollbarGutter]), so it never covers the last row; the
/// rows keep their own vertical scrollbar.
class MeridianSharedHorizontalScroll extends StatelessWidget {
  const MeridianSharedHorizontalScroll({
    required this.controller,
    required this.contentWidth,
    required this.child,
    super.key,
    this.columns = 1,
    this.fixedWidth = 0,
  }) : assert(columns > 0);

  final ScrollController controller;
  final double contentWidth;
  final int columns;
  final double fixedWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context);
    return MeridianScrollbarThumb(
      controller: controller,
      thumbVisibility: true,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.horizontal,
      child: ScrollConfiguration(
        behavior: behavior.copyWith(scrollbars: false),
        child: Scrollable(
          controller: controller,
          axisDirection: AxisDirection.right,
          physics: const ClampingScrollPhysics(),
          viewportBuilder: (context, position) => _HorizontalExtent(
            position: position,
            contentWidth: contentWidth,
            columns: columns,
            fixedWidth: fixedWidth,
            // The rows keep their own vertical scrollbar.
            child: ScrollConfiguration(behavior: behavior, child: child),
          ),
        ),
      ),
    );
  }
}

class _HorizontalExtent extends SingleChildRenderObjectWidget {
  const _HorizontalExtent({
    required this.position,
    required this.contentWidth,
    required this.columns,
    required this.fixedWidth,
    super.child,
  });

  final ViewportOffset position;
  final double contentWidth;
  final int columns;
  final double fixedWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHorizontalExtent(position, contentWidth, columns, fixedWidth);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHorizontalExtent renderObject,
  ) {
    renderObject
      ..position = position
      ..contentWidth = contentWidth
      ..columns = columns
      ..fixedWidth = fixedWidth;
  }
}

class _RenderHorizontalExtent extends RenderProxyBox {
  _RenderHorizontalExtent(
    this._position,
    this._contentWidth,
    this._columns,
    this._fixedWidth,
  );

  ViewportOffset _position;
  set position(ViewportOffset value) {
    if (value == _position) return;
    _position = value;
    markNeedsLayout();
  }

  double _contentWidth;
  set contentWidth(double value) {
    if (value == _contentWidth) return;
    _contentWidth = value;
    markNeedsLayout();
  }

  int _columns;
  set columns(int value) {
    if (value == _columns) return;
    _columns = value;
    markNeedsLayout();
  }

  double _fixedWidth;
  set fixedWidth(double value) {
    if (value == _fixedWidth) return;
    _fixedWidth = value;
    markNeedsLayout();
  }

  /// The width of a column's text at a total [width].
  double _visibleFor(double width) => math.max(
    0.0,
    (width - (_columns - 1) * MeridianLayout.hairline) / _columns - _fixedWidth,
  );

  /// The strip below the rows the horizontal scrollbar takes while the
  /// text is wider than its column, so it never covers the last row.
  double _gutterFor(double width) =>
      _contentWidth > _visibleFor(width) ? MeridianLayout.scrollbarGutter : 0;

  BoxConstraints _childConstraints(BoxConstraints constraints) {
    final gutter = _gutterFor(constraints.maxWidth);
    return constraints.copyWith(
      minHeight: math.max(0.0, constraints.minHeight - gutter),
      maxHeight: math.max(0.0, constraints.maxHeight - gutter),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) + _gutterFor(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) + _gutterFor(width);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final size = child.getDryLayout(_childConstraints(constraints));
    return constraints.constrain(
      Size(size.width, size.height + _gutterFor(constraints.maxWidth)),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
    } else {
      child.layout(_childConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(
        Size(
          child.size.width,
          child.size.height + _gutterFor(constraints.maxWidth),
        ),
      );
    }
    final visible = _visibleFor(size.width);
    _position.applyViewportDimension(visible);
    _position.applyContentDimensions(0, math.max(0.0, _contentWidth - visible));
  }
}

/// The part of a row inside a [MeridianSharedHorizontalScroll] that
/// scrolls: [child] lays out at its natural width and is painted (and hit
/// tested) shifted by [controller]'s offset, clipped to the row.
class MeridianHorizontalShift extends StatelessWidget {
  const MeridianHorizontalShift({
    required this.controller,
    required this.child,
    super.key,
  });

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: _HorizontalShift(offset: controller, child: child),
  );
}

class _HorizontalShift extends SingleChildRenderObjectWidget {
  const _HorizontalShift({required this.offset, super.child});

  final ScrollController offset;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHorizontalShift(offset);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHorizontalShift renderObject,
  ) {
    renderObject.offset = offset;
  }
}

class _RenderHorizontalShift extends RenderProxyBox {
  _RenderHorizontalShift(this._offset);

  ScrollController _offset;
  set offset(ScrollController value) {
    if (value == _offset) return;
    if (attached) {
      _offset.removeListener(markNeedsPaint);
      value.addListener(markNeedsPaint);
    }
    _offset = value;
    markNeedsPaint();
  }

  double get _dx =>
      _offset.positions.length == 1 ? _offset.positions.single.pixels : 0;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsPaint);
    super.detach();
  }

  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      BoxConstraints(
        minHeight: constraints.minHeight,
        maxHeight: constraints.maxHeight,
      );

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final height =
        child?.getDryLayout(_childConstraints(constraints)).height ?? 0;
    return constraints.constrain(Size(constraints.maxWidth, height));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = constraints.constrain(Size(constraints.maxWidth, child.size.height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) context.paintChild(child, offset - Offset(_dx, 0));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: Offset(-_dx, 0),
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(-_dx, 0, 0, 1);
  }
}

/// The category of a run of code text. Plain code has no category and
/// stays `ink`.
enum MeridianSyntaxKind {
  comment,
  keyword,
  string,
  number,
  type,
  function,
  variable,
  constant,
  operator,
  punctuation,
  attribute,
  tag,
}

/// The `syntax-*` colour of each [MeridianSyntaxKind].
extension MeridianSyntaxColorsKinds on MeridianSyntaxColors {
  Color of(MeridianSyntaxKind kind) => switch (kind) {
    MeridianSyntaxKind.comment => comment,
    MeridianSyntaxKind.keyword => keyword,
    MeridianSyntaxKind.string => string,
    MeridianSyntaxKind.number => number,
    MeridianSyntaxKind.type => type,
    MeridianSyntaxKind.function => function,
    MeridianSyntaxKind.variable => variable,
    MeridianSyntaxKind.constant => constant,
    MeridianSyntaxKind.operator => operator,
    MeridianSyntaxKind.punctuation => punctuation,
    MeridianSyntaxKind.attribute => attribute,
    MeridianSyntaxKind.tag => tag,
  };
}

/// One category over the UTF-16 range [start, end) of a line's text.
@immutable
final class MeridianSyntaxRun {
  const MeridianSyntaxRun(this.start, this.end, this.kind);

  final int start;
  final int end;
  final MeridianSyntaxKind kind;

  @override
  bool operator ==(Object other) =>
      other is MeridianSyntaxRun &&
      other.start == start &&
      other.end == end &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(start, end, kind);

  @override
  String toString() => 'MeridianSyntaxRun($start, $end, ${kind.name})';
}

/// Colours code text by category: the `syntax-*` tokens, checked against
/// the surfaces the text is painted on.
///
/// A category whose colour reads below [minimumContrast] on any of the
/// opaque [backgrounds] (the line fill, a mark behind changed words, a
/// selection already blended onto the fill) keeps [ink], so an overlay
/// never makes code harder to read. Build one per surface combination and
/// reuse it; it only ever changes colours, never the font, weight or size,
/// so coloured and plain text have the same metrics.
final class MeridianSyntaxPalette {
  MeridianSyntaxPalette({
    required MeridianSyntaxColors colors,
    required this.ink,
    Iterable<Color> backgrounds = const [],
    this.minimumContrast = 4.5,
  }) : _colors = {
         for (final kind in MeridianSyntaxKind.values)
           kind: _readable(colors.of(kind), backgrounds, minimumContrast)
               ? colors.of(kind)
               : ink,
       };

  /// The palette of [context]'s theme on its `pane`.
  factory MeridianSyntaxPalette.of(
    BuildContext context, {
    Iterable<Color>? backgrounds,
  }) {
    final meridian = MeridianTheme.of(context);
    return MeridianSyntaxPalette(
      colors: meridian.syntax,
      ink: meridian.colors.ink,
      backgrounds: backgrounds ?? [meridian.colors.pane],
    );
  }

  /// Plain code, and the colour of a category that is not readable.
  final Color ink;
  final double minimumContrast;
  final Map<MeridianSyntaxKind, Color> _colors;

  /// The colour [kind] is painted in.
  Color colorOf(MeridianSyntaxKind kind) => _colors[kind]!;

  /// [text] with each of [runs] in its category's colour. Uncovered text
  /// keeps the inherited style.
  ///
  /// Runs are UTF-16 offsets into [text]: ordered, nonempty,
  /// non-overlapping, within the text and never splitting a surrogate pair.
  /// When any run breaks this, the whole text stays plain rather than
  /// partly coloured. The span's plain text always equals [text].
  TextSpan span(String text, List<MeridianSyntaxRun> runs) {
    if (runs.isEmpty || !meridianSyntaxRunsValid(text, runs)) {
      return TextSpan(text: text);
    }
    final children = <TextSpan>[];
    var cursor = 0;
    for (final run in runs) {
      if (run.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, run.start)));
      }
      children.add(
        TextSpan(
          text: text.substring(run.start, run.end),
          style: TextStyle(color: colorOf(run.kind)),
        ),
      );
      cursor = run.end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(children: children);
  }

  static bool _readable(
    Color color,
    Iterable<Color> backgrounds,
    double minimum,
  ) => backgrounds.every(
    (background) => meridianContrastRatio(color, background) >= minimum,
  );
}

/// Whether [runs] are ordered, nonempty, non-overlapping UTF-16 ranges of
/// [text] that do not split a surrogate pair.
bool meridianSyntaxRunsValid(String text, List<MeridianSyntaxRun> runs) {
  var cursor = 0;
  bool boundary(int offset) =>
      offset <= 0 ||
      offset >= text.length ||
      !_isLowSurrogate(text.codeUnitAt(offset)) ||
      !_isHighSurrogate(text.codeUnitAt(offset - 1));
  for (final run in runs) {
    if (run.start < cursor ||
        run.end <= run.start ||
        run.end > text.length ||
        !boundary(run.start) ||
        !boundary(run.end)) {
      return false;
    }
    cursor = run.end;
  }
  return true;
}

bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;
bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;

/// The WCAG contrast ratio of two opaque colours, from 1 to 21.
double meridianContrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}

/// A sign or symbol in a [MeridianCodeGutter]'s marker column: `+` in
/// `success`, a conflict marker, a breakpoint.
@immutable
class MeridianCodeMarker {
  const MeridianCodeMarker(this.text, {this.color, this.semanticLabel});

  final String text;

  /// Defaults to `ink-muted`.
  final Color? color;

  /// What the marker means ("Added"); the marker is not announced without.
  final String? semanticLabel;
}

/// The gutter before a line of code: one or more line [numbers] (two for a
/// unified diff, old and new), right-aligned in `code-sm` `ink-muted` with
/// tabular figures, then an optional [marker] column. A `null` number
/// leaves its cell empty. [highlighted] fills the number cells with
/// `accent-soft` (the selected or current line); [divider] ends the gutter
/// with a `line` hairline.
class MeridianCodeGutter extends StatelessWidget {
  const MeridianCodeGutter({
    required this.numbers,
    super.key,
    this.marker,
    this.showMarker = false,
    this.highlighted = false,
    this.divider = false,
    this.numberWidth = MeridianLayout.codeGutterWidth,
    this.height,
  });

  final List<int?> numbers;
  final MeridianCodeMarker? marker;

  /// Reserve the marker column even when [marker] is `null`, so rows with
  /// and without one align.
  final bool showMarker;
  final bool highlighted;
  final bool divider;

  /// The width of one number cell.
  final double numberWidth;

  /// The row height; defaults to the parent's.
  final double? height;

  /// The gutter's width for [numbers] cells, a marker column and a divider.
  static double widthFor({
    int numbers = 1,
    bool marker = false,
    bool divider = false,
    double numberWidth = MeridianLayout.codeGutterWidth,
  }) =>
      numbers * numberWidth +
      (marker ? MeridianLayout.codeMarkerWidth : 0) +
      (divider ? MeridianLayout.hairline : 0);

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final numberStyle = MeridianTextStyles.numeric(
      meridian.text.codeSm.copyWith(color: colors.inkMuted),
    );
    final marker = this.marker;
    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final number in numbers)
            SizedBox(
              width: numberWidth,
              child: ColoredBox(
                color: highlighted
                    ? colors.accentSoft
                    : meridianClear(colors.accentSoft),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: MeridianSpace.space4,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      number?.toString() ?? '',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: numberStyle,
                    ),
                  ),
                ),
              ),
            ),
          if (marker != null || showMarker)
            SizedBox(
              width: MeridianLayout.codeMarkerWidth,
              child: Center(
                child: Semantics(
                  label: marker?.semanticLabel,
                  excludeSemantics: true,
                  child: Text(
                    marker?.text ?? '',
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: meridian.text.code.copyWith(
                      color: marker?.color ?? colors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
          if (divider)
            MeridianHairline(axis: Axis.vertical, color: colors.line),
        ],
      ),
    );
  }
}

/// A read-only view of numbered lines of monospace text: a file's contents,
/// a log, a command's output. Each line has a [MeridianCodeGutter] and its
/// text in `code`; [marks] paint ranges behind a line's text (search hits),
/// [highlightedLines] tint whole lines `pane-hover` and [currentLine] tints
/// one `accent-soft` (the current match). [markers] put a sign in the
/// gutter.
///
/// Without [wrap] long lines scroll sideways together, with one horizontal
/// scrollbar ([MeridianSharedHorizontalScroll]); with it they wrap. The
/// text is selectable across lines when [selectable]. Indices are 0-based;
/// the gutter numbers start at [firstLineNumber].
class MeridianCodeLines extends StatefulWidget {
  const MeridianCodeLines({
    required this.lines,
    super.key,
    this.controller,
    this.horizontalController,
    this.firstLineNumber = 1,
    this.marks = const {},
    this.highlightedLines = const {},
    this.currentLine,
    this.markers = const {},
    this.syntax = const {},
    this.wrap = false,
    this.selectable = true,
    this.showLineNumbers = true,
    this.contextMenuBuilder,
    this.semanticLabel,
  });

  final List<String> lines;

  /// The vertical scroll position (for jumping to a match).
  final ScrollController? controller;

  /// The shared horizontal position; the view keeps its own when `null`.
  final ScrollController? horizontalController;
  final int firstLineNumber;

  /// Ranges to mark, by line index.
  final Map<int, List<TextRange>> marks;
  final Set<int> highlightedLines;
  final int? currentLine;

  /// Gutter signs, by line index. The marker column shows when any line
  /// has one.
  final Map<int, MeridianCodeMarker> markers;

  /// Category runs, by line index, coloured with the theme's
  /// [MeridianSyntaxPalette]; a line without runs is plain.
  final Map<int, List<MeridianSyntaxRun>> syntax;
  final bool wrap;
  final bool selectable;
  final bool showLineNumbers;

  /// The selection's context menu; the [MeridianMenuPresenter]'s text
  /// menu (or Meridian's own) by default.
  final MeridianTextMenuBuilder? contextMenuBuilder;

  /// Names the view for assistive technology ("Contents of README.md").
  final String? semanticLabel;

  /// The height of one unwrapped line.
  static const double lineHeight = MeridianLayout.codeLineHeight;

  @override
  State<MeridianCodeLines> createState() => _MeridianCodeLinesState();
}

class _MeridianCodeLinesState extends State<MeridianCodeLines> {
  ScrollController? _ownHorizontal;
  ScrollController get _horizontal =>
      widget.horizontalController ??
      (_ownHorizontal ??= ScrollController(debugLabel: 'code-horizontal'));

  double? _measured;
  TextStyle? _measuredStyle;
  List<String>? _measuredLines;

  @override
  void dispose() {
    _ownHorizontal?.dispose();
    super.dispose();
  }

  /// The widest line's text width (monospace: the longest line).
  double _contentWidth(TextStyle style, TextScaler scaler) {
    if (_measured != null &&
        identical(_measuredLines, widget.lines) &&
        _measuredStyle == style) {
      return _measured!;
    }
    var longest = '';
    for (final line in widget.lines) {
      if (line.length > longest.length) longest = line;
    }
    final painter = TextPainter(
      text: TextSpan(text: longest, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    _measuredLines = widget.lines;
    _measuredStyle = style;
    return _measured = width;
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final style = meridian.text.code.copyWith(color: colors.ink);
    final wrap = widget.wrap;
    final showMarker = widget.markers.isNotEmpty;
    final gutterWidth = widget.showLineNumbers || showMarker
        ? MeridianCodeGutter.widthFor(
            numbers: widget.showLineNumbers ? 1 : 0,
            marker: showMarker,
          )
        : 0.0;
    const endPadding = MeridianSpace.space6;
    final scaler = MediaQuery.textScalerOf(context);
    final lineHeight = scaler.scale(MeridianLayout.codeLineHeight);

    MeridianSyntaxPalette? palette;
    Widget row(BuildContext context, int index) {
      final line = widget.lines[index];
      final current = index == widget.currentLine;
      final runs = widget.syntax[index];
      final marks = widget.marks[index] ?? const <TextRange>[];
      final fill = current
          ? colors.accentSoft
          : widget.highlightedLines.contains(index)
          ? colors.paneHover
          : colors.pane;
      Widget text = MeridianLineMarks(
        marks: marks,
        child: Text.rich(
          runs == null || runs.isEmpty
              ? TextSpan(text: line)
              : (marks.isEmpty && fill == colors.pane
                        ? palette ??= MeridianSyntaxPalette.of(context)
                        : MeridianSyntaxPalette(
                            colors: meridian.syntax,
                            ink: colors.ink,
                            backgrounds: [
                              fill,
                              if (marks.isNotEmpty)
                                Color.alphaBlend(colors.attentionBg, fill),
                            ],
                          ))
                    .span(line, runs),
          maxLines: wrap ? null : 1,
          softWrap: wrap,
          overflow: TextOverflow.clip,
          style: style,
        ),
      );
      if (!wrap) {
        text = MeridianHorizontalShift(controller: _horizontal, child: text);
      }
      return ColoredBox(
        color: current
            ? colors.accentSoft
            : widget.highlightedLines.contains(index)
            ? colors.paneHover
            : meridianClear(colors.paneHover),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: lineHeight),
          child: Row(
            crossAxisAlignment: wrap
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (gutterWidth > 0)
                MeridianCodeGutter(
                  numbers: [
                    if (widget.showLineNumbers) widget.firstLineNumber + index,
                  ],
                  marker: widget.markers[index],
                  showMarker: showMarker,
                  height: lineHeight,
                ),
              const SizedBox(width: MeridianSpace.space3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: endPadding),
                  child: text,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget list = ListView.builder(
      controller: widget.controller,
      itemCount: widget.lines.length,
      itemExtent: wrap ? null : lineHeight,
      itemBuilder: row,
    );
    if (!wrap) {
      list = MeridianSharedHorizontalScroll(
        controller: _horizontal,
        contentWidth: _contentWidth(style, scaler),
        fixedWidth: gutterWidth + MeridianSpace.space3 + endPadding,
        child: list,
      );
    }
    if (widget.selectable) {
      final menu = widget.contextMenuBuilder;
      list = MeridianSelectionArea(contextMenuBuilder: menu, child: list);
    }
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      // Code reads left to right whatever the app's direction.
      child: Directionality(textDirection: TextDirection.ltr, child: list),
    );
  }
}
