import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_localizations.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'inputs.dart';
import 'menu.dart';

/// A titled row of colours that a [MeridianColorPicker] offers as swatches:
/// a palette, the colours used last, the colours already in a document.
@immutable
class MeridianColorGroup {
  const MeridianColorGroup({
    required this.title,
    required this.colors,
    this.labels,
  });

  /// Names the row ("Recent", "In this notebook").
  final String title;
  final List<Color> colors;

  /// Names for the swatches ("Ink"), one for each of [colors] in their
  /// order. Without them a swatch is named by its hex value.
  final List<String>? labels;
}

/// The channels a [MeridianColorPicker]'s sliders edit.
enum MeridianColorModel { hsv, rgb }

/// How a [MeridianColorPicker] arranges its wheel and controls.
enum MeridianColorPickerLayout {
  /// [wide] where the picker has [MeridianLayout.colorPickerWide] and the
  /// density is not touch, else [stacked].
  auto,

  /// The wheel above the hex field and sliders: a sheet, a narrow panel.
  stacked,

  /// The wheel at the start, the hex field and sliders beside it: a
  /// desktop dialog or popover.
  wide,
}

/// The strings a [MeridianColorPicker] shows or announces. Each unset one
/// falls back to [MeridianLocalizations] (English or German, by locale).
@immutable
class MeridianColorPickerLabels {
  const MeridianColorPickerLabels({
    this.wheel,
    this.hue,
    this.saturation,
    this.brightness,
    this.red,
    this.green,
    this.blue,
    this.hsv,
    this.rgb,
    this.channels,
    this.hex,
    this.invalidHex,
    this.original,
    this.current,
    this.swatch,
    this.degrees,
    this.percent,
  });

  /// The hue and saturation wheel.
  final String? wheel;
  final String? hue;
  final String? saturation;
  final String? brightness;
  final String? red;
  final String? green;
  final String? blue;

  /// The segments that switch the sliders between models, and their group.
  final String? hsv;
  final String? rgb;
  final String? channels;

  /// The hex field and its error.
  final String? hex;
  final String? invalidHex;

  /// The colour before this edit, which a tap restores, and the new one.
  final String? original;
  final String? current;

  /// `Colour <hex>`, for a swatch without a label.
  final String Function(String hex)? swatch;

  /// `<n>°`, a hue.
  final String Function(int degrees)? degrees;

  /// `<n>%`, a saturation or brightness.
  final String Function(int percent)? percent;

  /// These labels, with every unset one taken from [localizations]
  /// (Meridian's own English or German strings).
  MeridianColorPickerLabels withDefaults(MeridianLocalizations localizations) =>
      MeridianColorPickerLabels(
        wheel: wheel ?? localizations.colorPickerWheel,
        hue: hue ?? localizations.colorPickerHue,
        saturation: saturation ?? localizations.colorPickerSaturation,
        brightness: brightness ?? localizations.colorPickerBrightness,
        red: red ?? localizations.colorPickerRed,
        green: green ?? localizations.colorPickerGreen,
        blue: blue ?? localizations.colorPickerBlue,
        hsv: hsv ?? localizations.colorPickerHsb,
        rgb: rgb ?? localizations.colorPickerRgb,
        channels: channels ?? localizations.colorPickerModel,
        hex: hex ?? localizations.colorPickerHex,
        invalidHex: invalidHex ?? localizations.colorPickerInvalidHex,
        original: original ?? localizations.colorPickerOriginal,
        current: current ?? localizations.colorPickerNew,
        swatch: swatch ?? localizations.colorPickerSwatch,
        degrees: degrees ?? localizations.degrees,
        percent: percent ?? localizations.percent,
      );
}

/// Picks a colour by eye or by number: rows of offered colours
/// ([groups]), a hue and saturation wheel, the colour before and after
/// with its hex value, and sliders for hue, saturation and brightness or
/// for red, green and blue.
///
/// [color] is content, not a theme token. The picker keeps its alpha and
/// edits the rest. [onChanged] follows every drag and keystroke;
/// [onChangeEnd] gets the colour when a drag ends, a swatch is chosen, a
/// hex value is submitted or a slider steps. `null` [onChanged] disables
/// the picker.
///
/// Every value can be set exactly from the keyboard: the wheel turns the
/// hue with Left and Right and changes the saturation with Up and Down;
/// the sliders step by one unit.
///
/// [layout] puts the wheel beside the controls where there is room on a
/// desktop density, and above them otherwise.
class MeridianColorPicker extends StatefulWidget {
  const MeridianColorPicker({
    required this.color,
    required this.onChanged,
    super.key,
    this.onChangeEnd,
    this.original,
    this.groups = const [],
    this.model = MeridianColorModel.hsv,
    this.layout = MeridianColorPickerLayout.auto,
    this.labels = const MeridianColorPickerLabels(),
  });

  final Color color;
  final ValueChanged<Color>? onChanged;
  final ValueChanged<Color>? onChangeEnd;

  /// The colour before this edit, shown beside [color]; a tap on it
  /// restores it. `null` shows only [color].
  final Color? original;
  final List<MeridianColorGroup> groups;

  /// The model the sliders start in.
  final MeridianColorModel model;
  final MeridianColorPickerLayout layout;
  final MeridianColorPickerLabels labels;

  @override
  State<MeridianColorPicker> createState() => _MeridianColorPickerState();
}

/// `#RRGGBB` of [color], without its alpha.
String _hexOf(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

int _channel(double value) => (value * 255).round();

/// [hsv] turned by [hue] degrees, with [saturation] added.
HSVColor _stepHsv(HSVColor hsv, {double hue = 0, double saturation = 0}) => hsv
    .withHue((hsv.hue + hue) % 360)
    .withSaturation((hsv.saturation + saturation).clamp(0.0, 1.0));

class _MeridianColorPickerState extends State<MeridianColorPicker> {
  late HSVColor _hsv = HSVColor.fromColor(widget.color);
  late MeridianColorModel _model = widget.model;
  late final _hex = TextEditingController(text: _hexOf(widget.color));
  final _hexFocus = FocusNode(debugLabel: 'meridian-color-hex');
  String? _hexError;

  Color get _color => _hsv.toColor();
  bool get _enabled => widget.onChanged != null;
  MeridianLocalizations _localizations = const MeridianLocalizationsEn();
  MeridianColorPickerLabels get _labels =>
      widget.labels.withDefaults(_localizations);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localizations = MeridianLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _hexFocus.addListener(_hexFocusChanged);
  }

  @override
  void didUpdateWidget(covariant MeridianColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color.toARGB32() != _color.toARGB32()) {
      _hsv = _keepHue(HSVColor.fromColor(widget.color));
      _showHex();
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  /// [next], with the current hue (and saturation) where [next] has none:
  /// a grey or black keeps the hue the wheel was turned to.
  HSVColor _keepHue(HSVColor next) {
    if (next.value == 0) {
      return next.withHue(_hsv.hue).withSaturation(_hsv.saturation);
    }
    if (next.saturation == 0) return next.withHue(_hsv.hue);
    return next;
  }

  void _showHex() {
    if (_hexFocus.hasFocus) return;
    _hex.text = _hexOf(_color);
    _hexError = null;
  }

  /// Leaving the field tidies a valid value; an invalid one stays with
  /// its error until it is fixed or the colour changes.
  void _hexFocusChanged() {
    if (!_hexFocus.hasFocus && _hexError == null) setState(_showHex);
  }

  void _change(HSVColor next, {bool end = false}) {
    if (!_enabled) return;
    setState(() {
      _hsv = next;
      _showHex();
    });
    widget.onChanged!(_color);
    if (end) widget.onChangeEnd?.call(_color);
  }

  void _end() => widget.onChangeEnd?.call(_color);

  /// Turns the wheel from the current colour, which may be newer than the
  /// wheel's last build when keys repeat quickly.
  void _stepWheel({double hue = 0, double saturation = 0}) =>
      _change(_stepHsv(_hsv, hue: hue, saturation: saturation), end: true);

  void _choose(Color color) => _change(
    _keepHue(HSVColor.fromColor(color.withValues(alpha: widget.color.a))),
    end: true,
  );

  /// Parses `RRGGBB`, `#RRGGBB` or `RGB`; `null` if it is none of them.
  static int? _parseHex(String text) {
    var value = text.trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (RegExp(r'^[0-9a-fA-F]{3}$').hasMatch(value)) {
      value = [for (final digit in value.split('')) '$digit$digit'].join();
    }
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) return null;
    return int.parse(value, radix: 16);
  }

  void _typedHex(String text) {
    final rgb = _parseHex(text);
    if (rgb == null) return;
    setState(() => _hexError = null);
    final alpha = _channel(widget.color.a);
    final next = _keepHue(HSVColor.fromColor(Color(alpha << 24 | rgb)));
    setState(() => _hsv = next);
    widget.onChanged?.call(_color);
  }

  void _submittedHex(String text) {
    if (_parseHex(text) == null) {
      setState(
        () => _hexError =
            _labels.invalidHex ?? 'Enter six hex digits, such as #18304F',
      );
      _hexFocus.requestFocus();
      return;
    }
    _typedHex(text);
    _end();
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final caption = meridian.text.caption.copyWith(color: colors.inkMuted);
    final color = _color;
    String degrees(int value) => _labels.degrees?.call(value) ?? '$value°';
    String percent(int value) => _labels.percent?.call(value) ?? '$value%';

    Widget channel({
      required String name,
      required String shown,
      required double value,
      required double max,
      required Gradient track,
      required ValueChanged<double> onChanged,
      String Function(double value)? announce,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The slider announces the name and value itself.
        ExcludeSemantics(
          child: Row(
            children: [
              Expanded(child: Text(name, style: caption)),
              Text(shown, style: meridian.text.label),
            ],
          ),
        ),
        MeridianSlider(
          label: name,
          value: value,
          max: max,
          step: 1,
          track: track,
          valueLabel: announce ?? (_) => shown,
          onChanged: _enabled ? onChanged : null,
          onChangeEnd: _enabled ? (_) => _end() : null,
        ),
      ],
    );

    LinearGradient along(List<Color> stops) => LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: stops,
    );

    final hue = _hsv.hue.round();
    final saturation = (_hsv.saturation * 100).round();
    final brightness = (_hsv.value * 100).round();
    final red = _channel(color.r);
    final green = _channel(color.g);
    final blue = _channel(color.b);
    Color rgb(int r, int g, int b) =>
        Color.fromARGB(_channel(widget.color.a), r, g, b);
    void setRgb(int r, int g, int b) =>
        _change(_keepHue(HSVColor.fromColor(rgb(r, g, b))));

    final sliders = switch (_model) {
      MeridianColorModel.hsv => [
        channel(
          name: _labels.hue ?? 'Hue',
          shown: degrees(hue),
          value: _hsv.hue,
          max: 360,
          track: along([
            for (var h = 0; h <= 360; h += 60)
              HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
          ]),
          onChanged: (v) => _change(_hsv.withHue(v)),
        ),
        channel(
          name: _labels.saturation ?? 'Saturation',
          shown: percent(saturation),
          value: saturation.toDouble(),
          max: 100,
          track: along([
            _hsv.withSaturation(0).withAlpha(1).toColor(),
            _hsv.withSaturation(1).withAlpha(1).toColor(),
          ]),
          onChanged: (v) => _change(_hsv.withSaturation(v / 100)),
        ),
        channel(
          name: _labels.brightness ?? 'Brightness',
          shown: percent(brightness),
          value: brightness.toDouble(),
          max: 100,
          track: along([
            _hsv.withValue(0).withAlpha(1).toColor(),
            _hsv.withValue(1).withAlpha(1).toColor(),
          ]),
          onChanged: (v) => _change(_hsv.withValue(v / 100)),
        ),
      ],
      MeridianColorModel.rgb => [
        channel(
          name: _labels.red ?? 'Red',
          shown: '$red',
          value: red.toDouble(),
          max: 255,
          track: along([rgb(0, green, blue), rgb(255, green, blue)]),
          onChanged: (v) => setRgb(v.round(), green, blue),
        ),
        channel(
          name: _labels.green ?? 'Green',
          shown: '$green',
          value: green.toDouble(),
          max: 255,
          track: along([rgb(red, 0, blue), rgb(red, 255, blue)]),
          onChanged: (v) => setRgb(red, v.round(), blue),
        ),
        channel(
          name: _labels.blue ?? 'Blue',
          shown: '$blue',
          value: blue.toDouble(),
          max: 255,
          track: along([rgb(red, green, 0), rgb(red, green, 255)]),
          onChanged: (v) => setRgb(red, green, v.round()),
        ),
      ],
    };

    Widget group(MeridianColorGroup group) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: MeridianSpace.space2,
      children: [
        Semantics(header: true, child: Text(group.title, style: caption)),
        Wrap(
          spacing: MeridianSpace.space2,
          runSpacing: MeridianSpace.space2,
          children: [
            for (final (i, swatch) in group.colors.indexed)
              MeridianColorSwatch(
                color: swatch,
                label:
                    group.labels?[i] ??
                    _labels.swatch?.call(_hexOf(swatch)) ??
                    'Colour ${_hexOf(swatch)}',
                selected:
                    swatch.toARGB32() & 0xFFFFFF == color.toARGB32() & 0xFFFFFF,
                onPressed: _enabled ? () => _choose(swatch) : null,
              ),
          ],
        ),
      ],
    );

    final wheel = _HueWheel(
      hsv: _hsv,
      label: _labels.wheel ?? 'Hue and saturation',
      describe: (hsv) =>
          '${_labels.hue ?? 'Hue'} ${degrees(hsv.hue.round())}, '
          '${_labels.saturation ?? 'Saturation'} '
          '${percent((hsv.saturation * 100).round())}',
      onChanged: _enabled ? _change : null,
      onStep: _enabled ? _stepWheel : null,
      onChangeEnd: _enabled ? _end : null,
    );
    final controls = [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: MeridianSpace.space4,
        children: [
          _ColorPreview(
            original: widget.original,
            color: color,
            originalLabel: _labels.original ?? 'Original colour',
            currentLabel: _labels.current ?? 'New colour',
            onRestore: _enabled && widget.original != null
                ? () => _choose(widget.original!)
                : null,
          ),
          Expanded(
            child: MeridianTextField(
              controller: _hex,
              focusNode: _hexFocus,
              enabled: _enabled,
              label: _labels.hex ?? 'Hex',
              showLabel: false,
              monospace: true,
              error: _hexError,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
                LengthLimitingTextInputFormatter(7),
              ],
              onChanged: _typedHex,
              onSubmitted: _submittedHex,
            ),
          ),
        ],
      ),
      MeridianSegmented<MeridianColorModel>(
        label: _labels.channels ?? 'Colour model',
        value: _model,
        expand: true,
        segments: [
          MeridianSegment(
            value: MeridianColorModel.hsv,
            label: _labels.hsv ?? 'HSB',
          ),
          MeridianSegment(
            value: MeridianColorModel.rgb,
            label: _labels.rgb ?? 'RGB',
          ),
        ],
        onChanged: (value) => setState(() => _model = value),
      ),
      ...sliders,
    ];
    final groups = [
      for (final value in widget.groups)
        if (value.colors.isNotEmpty) group(value),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = switch (widget.layout) {
          MeridianColorPickerLayout.stacked => false,
          MeridianColorPickerLayout.wide => true,
          MeridianColorPickerLayout.auto =>
            !meridian.density.isTouch &&
                constraints.maxWidth >= MeridianLayout.colorPickerWide,
        };
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: MeridianSpace.space5,
            children: [
              ...groups,
              Center(child: wheel),
              ...controls,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: MeridianSpace.space5,
          children: [
            ...groups,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: MeridianSpace.space8,
              children: [
                // The wheel keeps its size; the controls take the rest.
                SizedBox(
                  width: meridian.density.isTouch
                      ? MeridianLayout.colorWheelTouch
                      : MeridianLayout.colorWheel,
                  child: wheel,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: MeridianSpace.space4,
                    children: controls,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// The colour before the edit (a tap restores it) above the new one, or the
/// new one alone.
class _ColorPreview extends StatelessWidget {
  const _ColorPreview({
    required this.original,
    required this.color,
    required this.originalLabel,
    required this.currentLabel,
    required this.onRestore,
  });

  final Color? original;
  final Color color;
  final String originalLabel;
  final String currentLabel;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final radius = BorderRadius.circular(meridian.radius.md);
    Widget fill(Color color) => DecoratedBox(
      decoration: BoxDecoration(color: color),
      child: const SizedBox.expand(),
    );
    // As tall as the hex field beside it; the halves share the height, so
    // the restore target cannot grow past it.
    return SizedBox(
      width: MeridianLayout.colorPreview,
      height: meridian.density.controlExtent,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: colors.lineStrong),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (original case final before?)
                Expanded(
                  child: Tooltip(
                    message: originalLabel,
                    excludeFromSemantics: true,
                    child: Semantics(
                      button: true,
                      enabled: onRestore != null,
                      label: originalLabel,
                      value: _hexOf(before),
                      onTap: onRestore,
                      excludeSemantics: true,
                      child: MeridianInteraction(
                        onTap: onRestore,
                        builder: (context, state) => fill(before),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Semantics(
                  label: currentLabel,
                  value: _hexOf(color),
                  child: fill(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A disc of hues around its centre, saturated at the rim and white at the
/// centre. It stays at full brightness, so dark colours are still picked by
/// eye; its thumb shows the colour itself.
class _HueWheel extends StatefulWidget {
  const _HueWheel({
    required this.hsv,
    required this.label,
    required this.describe,
    required this.onChanged,
    required this.onStep,
    required this.onChangeEnd,
  });

  final HSVColor hsv;
  final String label;

  /// Announces a hue and saturation.
  final String Function(HSVColor hsv) describe;
  final void Function(HSVColor value, {bool end})? onChanged;

  /// Moves the hue by degrees and the saturation by a fraction.
  final void Function({double hue, double saturation})? onStep;
  final VoidCallback? onChangeEnd;

  @override
  State<_HueWheel> createState() => _HueWheelState();
}

class _HueWheelState extends State<_HueWheel> {
  final _focus = FocusNode(debugLabel: 'meridian-color-wheel');
  var _focusVisible = false;

  bool get _enabled => widget.onChanged != null;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _at(Offset position, double size) {
    final center = Offset(size / 2, size / 2);
    final offset = position - center;
    var angle = math.atan2(offset.dy, offset.dx) * 180 / math.pi;
    if (angle < 0) angle += 360;
    final saturation = (offset.distance / (size / 2)).clamp(0.0, 1.0);
    widget.onChanged!(
      widget.hsv.withHue(angle % 360).withSaturation(saturation),
    );
  }

  void _step({double hue = 0, double saturation = 0}) =>
      widget.onStep!(hue: hue, saturation: saturation);

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_enabled || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final degrees = shift ? 10.0 : 1.0;
    final percent = shift ? .1 : .01;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        _step(hue: rtl ? -degrees : degrees);
      case LogicalKeyboardKey.arrowLeft:
        _step(hue: rtl ? degrees : -degrees);
      case LogicalKeyboardKey.arrowUp:
        _step(saturation: percent);
      case LogicalKeyboardKey.arrowDown:
        _step(saturation: -percent);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final touch = meridian.density.isTouch;
    final thumb = touch
        ? MeridianLayout.colorWheelThumbTouch
        : MeridianLayout.colorWheelThumb;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(
          touch ? MeridianLayout.colorWheelTouch : MeridianLayout.colorWheel,
          constraints.maxWidth,
        );
        final hsv = widget.hsv;
        final angle = hsv.hue * math.pi / 180;
        final reach = hsv.saturation * size / 2;
        final at =
            Offset(size / 2, size / 2) +
            Offset(math.cos(angle), math.sin(angle)) * reach;
        return Semantics(
          label: widget.label,
          value: widget.describe(hsv),
          increasedValue: widget.describe(_stepHsv(hsv, hue: 1)),
          decreasedValue: widget.describe(_stepHsv(hsv, hue: -1)),
          slider: true,
          enabled: _enabled,
          onIncrease: _enabled ? () => _step(hue: 1) : null,
          onDecrease: _enabled ? () => _step(hue: -1) : null,
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _onKey,
            child: FocusableActionDetector(
              focusNode: _focus,
              enabled: _enabled,
              mouseCursor: _enabled
                  ? SystemMouseCursors.precise
                  : SystemMouseCursors.basic,
              onShowFocusHighlight: (value) {
                if (_focusVisible != value) {
                  setState(() => _focusVisible = value);
                }
              },
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: {
                  if (_enabled)
                    _ImmediatePanGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          _ImmediatePanGestureRecognizer
                        >(_ImmediatePanGestureRecognizer.new, (recognizer) {
                          recognizer
                            ..onDown = (details) {
                              _focus.requestFocus();
                              _at(details.localPosition, size);
                            }
                            ..onUpdate = (details) {
                              _at(details.localPosition, size);
                            }
                            ..onEnd = (_) {
                              widget.onChangeEnd?.call();
                            }
                            ..onCancel = () {
                              widget.onChangeEnd?.call();
                            };
                        }),
                },
                child: Opacity(
                  opacity: _enabled ? 1 : MeridianOpacity.disabledContent,
                  child: CustomPaint(
                    size: Size.square(size),
                    painter: _WheelPainter(edge: colors.lineStrong),
                    foregroundPainter: MeridianFocusRingPainter(
                      visible: _focusVisible,
                      color: colors.focus,
                      radius: BorderRadius.circular(MeridianRadiusScale.pill),
                    ),
                    child: SizedBox.square(
                      dimension: size,
                      child: Stack(
                        children: [
                          Positioned(
                            left: at.dx - thumb / 2,
                            top: at.dy - thumb / 2,
                            child: IgnorePointer(
                              child: Container(
                                width: thumb,
                                height: thumb,
                                decoration: BoxDecoration(
                                  color: hsv.withAlpha(1).toColor(),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.pane,
                                    width: MeridianLayout.colorWheelThumbRing,
                                    strokeAlign: BorderSide.strokeAlignOutside,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.ink,
                                      spreadRadius:
                                          MeridianLayout.colorWheelThumbRing +
                                          MeridianLayout.hairline,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A pan that wins at once, so a drag on the wheel never scrolls the
/// dialog or sheet the picker is in.
class _ImmediatePanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({required this.edge});

  final Color edge;

  /// Colour arithmetic, not theme colours: the wheel shows content.
  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: [
            for (var h = 0; h <= 360; h += 60)
              HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
          ],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [_white, _white.withValues(alpha: 0)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius - MeridianLayout.hairline / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = MeridianLayout.hairline
        ..color = edge,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.edge != edge;
}

/// A swatch that opens a [MeridianColorPicker] in a popover: the custom
/// colour beside a palette of [MeridianColorSwatch]es, the way a desktop
/// app offers "any other colour".
///
/// It shows [color] inside a ring of hues, or the hues and a plus while
/// there is no custom colour yet. The popover's picker starts from
/// [color] (or [initial]) and reports every change to [onChanged], so the
/// owner shows it at once; [onChangeEnd] gets the colour when a drag ends,
/// a swatch is chosen or a value is submitted. A click outside or Escape
/// closes the popover, and focus returns to the well. `null` [onChanged]
/// disables the well.
class MeridianColorWell extends StatelessWidget {
  const MeridianColorWell({
    required this.color,
    required this.label,
    required this.onChanged,
    super.key,
    this.selected = false,
    this.initial,
    this.onChangeEnd,
    this.groups = const [],
    this.model = MeridianColorModel.hsv,
    this.labels = const MeridianColorPickerLabels(),
    this.focusNode,
  });

  /// The custom colour, or `null` while there is none.
  final Color? color;

  /// Names the well ("Custom colour").
  final String label;
  final ValueChanged<Color>? onChanged;
  final ValueChanged<Color>? onChangeEnd;

  /// Whether the custom colour is the chosen one, as on a swatch.
  final bool selected;

  /// Where the picker starts while there is no [color]: usually the
  /// colour chosen from the palette.
  final Color? initial;
  final List<MeridianColorGroup> groups;
  final MeridianColorModel model;
  final MeridianColorPickerLabels labels;
  final FocusNode? focusNode;

  void _open(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final start =
        color ?? initial ?? const HSVColor.fromAHSV(1, 0, 1, 1).toColor();
    showMeridianPopover<void>(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      width: MeridianLayout.colorWellPopover,
      builder: (context) => _ColorWellPopover(
        start: start,
        original: color ?? initial,
        groups: groups,
        model: model,
        labels: labels,
        onChanged: (value) => onChanged?.call(value),
        onChangeEnd: onChangeEnd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final enabled = onChanged != null;
    final disc = meridian.density.isTouch
        ? MeridianLayout.swatchSizeTouch
        : MeridianLayout.swatchSize;
    const ring = MeridianLayout.swatchRingWidth + MeridianLayout.swatchRingGap;
    final color = this.color;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        excludeSemantics: true,
        button: true,
        selected: selected,
        enabled: enabled,
        label: label,
        value: color == null ? null : _hexOf(color),
        onTap: enabled ? () => _open(context) : null,
        child: MeridianInteraction(
          onTap: enabled ? () => _open(context) : null,
          focusNode: focusNode,
          borderRadius: const BorderRadius.all(
            Radius.circular(MeridianRadiusScale.pill),
          ),
          builder: (context, state) {
            final edge = !enabled
                ? colors.line
                : state.hovered || state.pressed
                ? colors.inkMuted
                : colors.lineStrong;
            return AnimatedContainer(
              duration: MeridianMotion.of(context, MeridianDurations.select),
              width: disc + 2 * ring,
              height: disc + 2 * ring,
              padding: const EdgeInsets.all(MeridianLayout.swatchRingGap),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: MeridianLayout.swatchRingWidth,
                  color: selected
                      ? colors.accent
                      : meridianClear(colors.accent),
                ),
              ),
              child: Opacity(
                opacity: enabled ? 1 : MeridianOpacity.disabledContent,
                child: CustomPaint(
                  painter: _WellPainter(edge: edge),
                  child: Center(
                    child: Container(
                      width: disc * MeridianLayout.colorWellCore,
                      height: disc * MeridianLayout.colorWellCore,
                      decoration: BoxDecoration(
                        color: color ?? colors.pane,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.pane),
                      ),
                      child: color == null
                          ? Center(
                              child: MeridianIcon(
                                MeridianIcons.plus,
                                size: MeridianIconSize.small,
                                color: colors.ink,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The picker inside a [MeridianColorWell]'s popover, holding the colour
/// while it is edited.
class _ColorWellPopover extends StatefulWidget {
  const _ColorWellPopover({
    required this.start,
    required this.original,
    required this.groups,
    required this.model,
    required this.labels,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final Color start;
  final Color? original;
  final List<MeridianColorGroup> groups;
  final MeridianColorModel model;
  final MeridianColorPickerLabels labels;
  final ValueChanged<Color> onChanged;
  final ValueChanged<Color>? onChangeEnd;

  @override
  State<_ColorWellPopover> createState() => _ColorWellPopoverState();
}

class _ColorWellPopoverState extends State<_ColorWellPopover> {
  late Color _color = widget.start;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(MeridianSpace.space6),
    child: MeridianColorPicker(
      color: _color,
      original: widget.original,
      groups: widget.groups,
      model: widget.model,
      labels: widget.labels,
      onChanged: (color) {
        setState(() => _color = color);
        widget.onChanged(color);
      },
      onChangeEnd: widget.onChangeEnd,
    ),
  );
}

/// A well's ring of hues with its edge.
class _WellPainter extends CustomPainter {
  const _WellPainter({required this.edge});

  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: [
            for (var h = 0; h <= 360; h += 60)
              HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
          ],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius - MeridianLayout.hairline / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = MeridianLayout.hairline
        ..color = edge,
    );
  }

  @override
  bool shouldRepaint(covariant _WellPainter oldDelegate) =>
      oldDelegate.edge != edge;
}

/// A colour chosen in a [MeridianColorChoiceRow]: one of the theme's
/// categorical colours ([MeridianSeriesColor]), which follows light and
/// dark, or a [MeridianCustomColor], which stays the same in both.
sealed class MeridianColorChoice {
  const MeridianColorChoice();

  /// The colour to draw in [colors].
  Color resolve(MeridianColors colors);
}

/// `series-(index + 1)` of the theme: blue, teal, amber, orange, rose,
/// violet, cyan, olive.
@immutable
final class MeridianSeriesColor extends MeridianColorChoice {
  const MeridianSeriesColor(this.index) : assert(index >= 0 && index < 8);

  final int index;

  @override
  Color resolve(MeridianColors colors) => colors.series[index];

  @override
  bool operator ==(Object other) =>
      other is MeridianSeriesColor && other.index == index;

  @override
  int get hashCode => Object.hash(MeridianSeriesColor, index);
}

/// A colour the person picked; its alpha is ignored.
@immutable
final class MeridianCustomColor extends MeridianColorChoice {
  const MeridianCustomColor(this.color);

  final Color color;

  /// `#RRGGBB`.
  String get hex => _hexOf(color);

  @override
  Color resolve(MeridianColors colors) => color.withAlpha(0xFF);

  @override
  bool operator ==(Object other) =>
      other is MeridianCustomColor &&
      other.color.toARGB32() & 0xFFFFFF == color.toARGB32() & 0xFFFFFF;

  @override
  int get hashCode =>
      Object.hash(MeridianCustomColor, color.toARGB32() & 0xFFFFFF);
}

/// The theme's categorical colours as swatches, optionally led by a "no
/// colour" swatch and followed by a [MeridianColorWell] for any other
/// colour: a label, a tab group, a calendar's colour.
///
/// [value] is the chosen colour; `null` is no colour. Swatches are named
/// with Meridian's own localized colour names (Blue, Teal, Amber, Orange,
/// Rose, Violet, Cyan, Olive; [seriesLabels] overrides them), and the
/// custom well by its hex value. A custom colour picked here stays in the
/// well while a palette colour is chosen, so it can be chosen again.
/// `null` [onChanged] disables the row.
class MeridianColorChoiceRow extends StatefulWidget {
  const MeridianColorChoiceRow({
    required this.value,
    required this.onChanged,
    super.key,
    this.allowNone = false,
    this.noneLabel,
    this.allowCustom = true,
    this.customLabel,
    this.series = const [0, 1, 2, 3, 4, 5, 6, 7],
    this.seriesLabels,
    this.pickerLabels = const MeridianColorPickerLabels(),
  });

  final MeridianColorChoice? value;
  final ValueChanged<MeridianColorChoice?>? onChanged;

  /// Offer "no colour" as the first swatch.
  final bool allowNone;

  /// Names the "no colour" swatch; defaults to the localized "No colour".
  final String? noneLabel;

  /// Offer a well that opens a [MeridianColorPicker].
  final bool allowCustom;

  /// Names the well while it holds no colour; defaults to the localized
  /// "Custom colour".
  final String? customLabel;

  /// Which categorical colours to offer, by index, in order.
  final List<int> series;

  /// Names for all eight categorical colours, in series order.
  final List<String>? seriesLabels;
  final MeridianColorPickerLabels pickerLabels;

  @override
  State<MeridianColorChoiceRow> createState() => _MeridianColorChoiceRowState();
}

class _MeridianColorChoiceRowState extends State<MeridianColorChoiceRow> {
  late MeridianCustomColor? _custom = switch (widget.value) {
    final MeridianCustomColor custom => custom,
    _ => null,
  };

  @override
  void didUpdateWidget(covariant MeridianColorChoiceRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value case final MeridianCustomColor custom) _custom = custom;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MeridianLocalizations.of(context);
    final colors = MeridianTheme.of(context).colors;
    final value = widget.value;
    final onChanged = widget.onChanged;
    final names = widget.seriesLabels ?? l10n.seriesColorNames;
    final custom = _custom;
    return Wrap(
      spacing: MeridianSpace.space2,
      runSpacing: MeridianSpace.space2,
      children: [
        if (widget.allowNone)
          MeridianColorSwatch(
            key: const ValueKey('meridian-color-none'),
            color: colors.inkMuted,
            label: widget.noneLabel ?? l10n.colorNone,
            selected: value == null,
            onPressed: onChanged == null ? null : () => onChanged(null),
          ),
        for (final index in widget.series)
          MeridianColorSwatch(
            key: ValueKey('meridian-color-series-$index'),
            color: colors.series[index],
            label: names[index],
            selected: value == MeridianSeriesColor(index),
            onPressed: onChanged == null
                ? null
                : () => onChanged(MeridianSeriesColor(index)),
          ),
        if (widget.allowCustom)
          MeridianColorWell(
            key: const ValueKey('meridian-color-custom'),
            color: custom?.resolve(colors),
            label: custom == null
                ? widget.customLabel ?? l10n.colorCustom
                : l10n.colorCustomValue(custom.hex),
            selected: value is MeridianCustomColor,
            // The picker starts from the colour in use.
            initial: value?.resolve(colors),
            labels: widget.pickerLabels,
            onChanged: onChanged == null
                ? null
                : (color) {
                    final next = MeridianCustomColor(color);
                    setState(() => _custom = next);
                    onChanged(next);
                  },
          ),
      ],
    );
  }
}
