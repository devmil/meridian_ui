import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// One line of text that keeps both ends when it is too long.
///
/// A name whose end tells instances apart (a branch, a file path, an
/// identifier) loses its meaning under an end ellipsis. This shows the whole
/// text while it fits and replaces the middle with `…` when it does not.
///
/// The width follows the shown text up to the available width, so a parent
/// that hugs its content never grows beyond what is drawn. The shortened text
/// is chosen during layout and kept until the text, its style or the
/// available width changes; building the widget measures nothing.
class MeridianMiddleEllipsis extends LeafRenderObjectWidget {
  const MeridianMiddleEllipsis(
    this.text, {
    super.key,
    this.style,
    this.semanticsLabel,
  });

  final String text;

  /// Merged over the ambient [DefaultTextStyle].
  final TextStyle? style;

  /// Read by assistive technology instead of [text]. The complete [text] is
  /// read when this is null, never the shortened one.
  final String? semanticsLabel;

  TextStyle _style(BuildContext context) {
    final ambient = DefaultTextStyle.of(context).style;
    final style = this.style;
    return style == null || !style.inherit
        ? style ?? ambient
        : ambient.merge(style);
  }

  @override
  RenderMeridianMiddleEllipsis createRenderObject(BuildContext context) =>
      RenderMeridianMiddleEllipsis(
        text: text,
        style: _style(context),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        semanticsLabel: semanticsLabel,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMeridianMiddleEllipsis renderObject,
  ) {
    renderObject
      ..text = text
      ..style = _style(context)
      ..textDirection = Directionality.of(context)
      ..textScaler = MediaQuery.textScalerOf(context)
      ..locale = Localizations.maybeLocaleOf(context)
      ..semanticsLabel = semanticsLabel;
  }
}

class RenderMeridianMiddleEllipsis extends RenderBox {
  RenderMeridianMiddleEllipsis({
    required String text,
    required TextStyle style,
    required TextDirection textDirection,
    required TextScaler textScaler,
    Locale? locale,
    String? semanticsLabel,
  }) : _text = text,
       _style = style,
       _textDirection = textDirection,
       _textScaler = textScaler,
       _locale = locale,
       _semanticsLabel = semanticsLabel;

  static const _ellipsis = '…';

  final TextPainter _painter = TextPainter(maxLines: 1);

  /// The text [_painter] holds now.
  String? _laidOut;

  /// Unbounded width of the complete text, measured once per text and style.
  double? _fullWidth;
  double? _height;

  /// The shortened text chosen for [_fittedWidth].
  String? _fitted;
  double? _fittedWidth;

  String get text => _text;
  String _text;
  set text(String value) {
    if (_text == value) return;
    _text = value;
    _invalidate();
    markNeedsSemanticsUpdate();
  }

  TextStyle get style => _style;
  TextStyle _style;
  set style(TextStyle value) {
    if (_style == value) return;
    final comparison = _style.compareTo(value);
    _style = value;
    if (comparison == RenderComparison.layout) {
      _invalidate();
    } else {
      // A colour change keeps every measurement.
      _laidOut = null;
      markNeedsPaint();
    }
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _invalidate();
    markNeedsSemanticsUpdate();
  }

  TextScaler get textScaler => _textScaler;
  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (_textScaler == value) return;
    _textScaler = value;
    _invalidate();
  }

  Locale? get locale => _locale;
  Locale? _locale;
  set locale(Locale? value) {
    if (_locale == value) return;
    _locale = value;
    _invalidate();
  }

  String? get semanticsLabel => _semanticsLabel;
  String? _semanticsLabel;
  set semanticsLabel(String? value) {
    if (_semanticsLabel == value) return;
    _semanticsLabel = value;
    markNeedsSemanticsUpdate();
  }

  /// The text on screen: [text], or its ends around an ellipsis.
  String get shownText => _laidOut ?? _text;

  void _invalidate() {
    _laidOut = null;
    _fullWidth = null;
    _height = null;
    _fitted = null;
    _fittedWidth = null;
    markNeedsLayout();
  }

  double _layoutText(String value) {
    _painter
      ..text = TextSpan(text: value, style: _style)
      ..textDirection = _textDirection
      ..textScaler = _textScaler
      ..locale = _locale
      ..layout();
    _laidOut = value;
    _height ??= _painter.height;
    return _painter.width;
  }

  double get _measuredFullWidth => _fullWidth ??= _layoutText(_text);

  /// The longest text with both ends of [text] that is at most [maxWidth]
  /// wide.
  String _fit(double maxWidth) {
    if (!maxWidth.isFinite || _measuredFullWidth <= maxWidth) return _text;
    if (_fitted != null && _fittedWidth == maxWidth) return _fitted!;
    // Whole characters, so an emoji or a combined letter is never split.
    final characters = _text.characters.toList(growable: false);
    var low = 0;
    var high = characters.length - 1;
    var best = _ellipsis;
    while (low <= high) {
      final kept = (low + high) ~/ 2;
      final leading = (kept + 1) ~/ 2;
      final trailing = kept - leading;
      final candidate = StringBuffer()
        ..writeAll(characters.take(leading))
        ..write(_ellipsis)
        ..writeAll(characters.skip(characters.length - trailing));
      final value = candidate.toString();
      if (_layoutText(value) <= maxWidth) {
        best = value;
        low = kept + 1;
      } else {
        high = kept - 1;
      }
    }
    _fitted = best;
    _fittedWidth = maxWidth;
    return best;
  }

  Size _sizeFor(BoxConstraints constraints) {
    final shown = _fit(constraints.maxWidth);
    if (_laidOut != shown) _layoutText(shown);
    return constraints.constrain(Size(_painter.width, _painter.height));
  }

  @override
  void performLayout() => size = _sizeFor(constraints);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _sizeFor(constraints);

  @override
  double computeMinIntrinsicWidth(double height) {
    final full = _measuredFullWidth;
    final least = _layoutText(_ellipsis);
    return least < full ? least : full;
  }

  @override
  double computeMaxIntrinsicWidth(double height) => _measuredFullWidth;

  @override
  double computeMinIntrinsicHeight(double width) => _lineHeight;

  @override
  double computeMaxIntrinsicHeight(double width) => _lineHeight;

  double get _lineHeight {
    _measuredFullWidth;
    return _height ??= _painter.height;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final shown = _fit(constraints.maxWidth);
    if (_laidOut != shown) _layoutText(shown);
    return _painter.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final shown = _fit(constraints.maxWidth);
    if (_laidOut != shown) _layoutText(shown);
    _painter.paint(context.canvas, offset);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..label = _semanticsLabel ?? _text
      ..textDirection = _textDirection;
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }
}
