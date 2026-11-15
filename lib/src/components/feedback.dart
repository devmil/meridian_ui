import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'actions.dart';
import '../foundation/meridian_localizations.dart';

/// A 12px spinner that replaces an icon while something runs. It turns
/// slowly (2 s) with reduce motion.
///
/// It paints nothing for `motion-spinner-delay`, then fades in over
/// `motion-quick`, so fast work never flashes it (MM-60). Places that
/// already waited pass `delayed: false`.
class MeridianSpinner extends StatefulWidget {
  const MeridianSpinner({
    super.key,
    this.size = MeridianLayout.spinnerSize,
    this.color,
    this.semanticLabel,
    this.delayed = true,
  });

  final double size;
  final Color? color;
  final String? semanticLabel;
  final bool delayed;

  @override
  State<MeridianSpinner> createState() => _MeridianSpinnerState();
}

class _MeridianSpinnerState extends State<MeridianSpinner>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MeridianDurations.spinner,
  )..repeat();

  /// The appearance: nothing for `motion-spinner-delay`, then a fade.
  late final AnimationController _appear = AnimationController(
    vsync: this,
    value: widget.delayed ? 0 : 1,
    duration: MeridianDurations.spinnerDelay + MeridianDurations.quick,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _appear,
    curve: Interval(
      MeridianDurations.spinnerDelay.inMicroseconds /
          (MeridianDurations.spinnerDelay + MeridianDurations.quick)
              .inMicroseconds,
      1,
      curve: MeridianDurations.quickCurve,
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.delayed) _appear.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final duration = MeridianMotion.reduced(context)
        ? MeridianDurations.spinnerReduced
        : MeridianDurations.spinner;
    if (_controller.duration != duration) {
      _controller
        ..duration = duration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _appear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? MeridianTheme.of(context).colors.ink;
    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox.square(
        dimension: widget.size,
        child: FadeTransition(
          opacity: _opacity,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _SpinnerPainter(color: color, turn: _controller.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.color, required this.turn});

  final Color color;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = MeridianLayout.spinnerStroke;
    final rect =
        const Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    canvas.drawArc(
      rect,
      turn * math.pi * 2,
      math.pi * 1.5,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) =>
      color != oldDelegate.color || turn != oldDelegate.turn;
}

/// A 2px progress rule in `accent`. Indeterminate (a sliding 30% bar) until
/// [value] is known, then determinate. Set [track] to draw the `line` track
/// (standalone bars); leave it off when the rule runs along an edge.
///
/// Motion (MM-61 to MM-63): values move over `motion-emphasized`; when the
/// value becomes known, the sweeping bar morphs into the value bar over
/// `motion-layout`; on reaching 100% the bar holds `motion-progress-hold`
/// and fades out over `motion-exit`, unless [persistent].
class MeridianProgressBar extends StatefulWidget {
  const MeridianProgressBar({
    super.key,
    this.value,
    this.track = false,
    this.height = MeridianLayout.progressHeight,
    this.semanticLabel,
    this.persistent = false,
  });

  /// 0–1, or `null` for indeterminate.
  final double? value;
  final bool track;
  final double height;
  final String? semanticLabel;

  /// Keep a full bar on screen instead of fading it out.
  final bool persistent;

  @override
  State<MeridianProgressBar> createState() => _MeridianProgressBarState();
}

class _MeridianProgressBarState extends State<MeridianProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MeridianDurations.progress,
  );
  late final CurvedAnimation _sweep = CurvedAnimation(
    parent: _controller,
    curve: MeridianDurations.progressCurve,
  );

  /// The determinate end, moving over `motion-emphasized`.
  late final AnimationController _end = AnimationController(
    vsync: this,
    value: widget.value?.clamp(0.0, 1.0) ?? 0,
  );

  /// The sweep-to-value morph, 0 → 1 over `motion-layout`.
  late final AnimationController _morph = AnimationController(
    vsync: this,
    value: 1,
  );
  (double, double) _morphFrom = (0, 0);

  /// The fade after reaching 100%: hold, then out.
  late final AnimationController _done = AnimationController(vsync: this);
  var _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MeridianMotion.reduced(context);
    _sync();
  }

  @override
  void didUpdateWidget(covariant MeridianProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.value?.clamp(0.0, 1.0);
    final old = oldWidget.value?.clamp(0.0, 1.0);
    if (value != null && old == null) {
      // Indeterminate → determinate: morph from where the sweep is.
      _morphFrom = _sweepRect();
      _end.value = value;
      if (_reduced) {
        _morph.value = 1;
      } else {
        _morph
          ..value = 0
          ..animateTo(
            1,
            duration: MeridianDurations.layout,
            curve: MeridianDurations.layoutCurve,
          );
      }
    } else if (value != null && value != old) {
      _end.animateTo(
        value,
        duration: MeridianMotion.of(context, MeridianDurations.emphasized),
        curve: MeridianDurations.emphasizedCurve,
      );
    }
    if (value != null && value >= 1 && (old == null || old < 1)) {
      _finish();
    } else if (value == null || value < 1) {
      _done
        ..stop()
        ..value = 0;
    }
    _sync();
  }

  void _finish() {
    if (widget.persistent) return;
    if (_reduced) {
      _done.value = 1;
      return;
    }
    _done
      ..duration = MeridianDurations.progressHold + MeridianDurations.exit
      ..forward(from: 0);
  }

  /// The indeterminate bar's current start and end, as fractions.
  (double, double) _sweepRect() {
    const f = MeridianLayout.progressIndeterminateFraction;
    if (_reduced) return (0, f);
    final start = -f + (1 + f) * _sweep.value;
    return (start, start + f);
  }

  /// Sweeps only while indeterminate and motion is allowed.
  void _sync() {
    final sweep = widget.value == null && !_reduced;
    if (sweep && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!sweep && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    _controller.dispose();
    _end.dispose();
    _morph.dispose();
    _done.dispose();
    super.dispose();
  }

  /// Opacity after reaching 100%: 1 through the hold, then the exit fade.
  double get _opacity {
    if (!_done.isAnimating && _done.value == 0) return 1;
    if (_done.value >= 1) return 0;
    final total = _done.duration!.inMicroseconds;
    final hold = MeridianDurations.progressHold.inMicroseconds / total;
    if (_done.value <= hold) return 1;
    final t = (_done.value - hold) / (1 - hold);
    return 1 - MeridianDurations.exitCurve.transform(t.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final value = widget.value?.clamp(0.0, 1.0);
    return Semantics(
      label: widget.semanticLabel,
      value: value == null ? null : '${(value * 100).round()}%',
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: Listenable.merge([_sweep, _end, _morph, _done]),
          builder: (context, _) {
            final (double, double) rect;
            if (value == null) {
              rect = _sweepRect();
            } else {
              final target = (0.0, _end.value);
              final t = _morph.value;
              rect = t >= 1
                  ? target
                  : (
                      _morphFrom.$1 + (target.$1 - _morphFrom.$1) * t,
                      _morphFrom.$2 + (target.$2 - _morphFrom.$2) * t,
                    );
            }
            return Opacity(
              opacity: _opacity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(MeridianRadiusScale.pill),
                child: ColoredBox(
                  color: widget.track
                      ? meridian.colors.line
                      : meridianClear(meridian.colors.line),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      assert(
                        constraints.hasBoundedWidth,
                        'MeridianProgressBar needs a bounded width. Give it '
                        'a width or put it in an Expanded or a stretched '
                        'Column.',
                      );
                      final width = constraints.maxWidth;
                      final start = width * rect.$1;
                      final length = math.max(0.0, width * (rect.$2 - rect.$1));
                      return Stack(
                        children: [
                          PositionedDirectional(
                            start: start,
                            top: 0,
                            bottom: 0,
                            width: length,
                            child: ColoredBox(color: meridian.colors.accent),
                          ),
                        ],
                      );
                    },
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

/// A 3px value bar for a metric (CPU, storage, quota). The fill animates
/// toward new values and turns `warning` or `danger` past its thresholds.
/// Always shown next to the number it draws.
class MeridianMeter extends StatelessWidget {
  const MeridianMeter({
    required this.value,
    super.key,
    this.warningAt,
    this.dangerAt,
    this.height = MeridianLayout.meterHeight,
    this.color,
  });

  /// 0–1.
  final double value;
  final double? warningAt;
  final double? dangerAt;
  final double height;

  /// Overrides the fill colour (for example a `series` colour).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = MeridianTheme.of(context).colors;
    final v = value.clamp(0.0, 1.0);
    final fill =
        color ??
        (dangerAt != null && v >= dangerAt!
            ? colors.danger
            : warningAt != null && v >= warningAt!
            ? colors.warning
            : colors.accent);
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MeridianRadiusScale.pill),
          child: ColoredBox(
            color: colors.line,
            child: LayoutBuilder(
              builder: (context, constraints) {
                assert(
                  constraints.hasBoundedWidth,
                  'MeridianMeter needs a bounded width. Give it a width or '
                  'put it in an Expanded or a stretched Column.',
                );
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AnimatedFractionallySizedBox(
                    duration: MeridianMotion.of(
                      context,
                      MeridianDurations.emphasized,
                    ),
                    curve: MeridianDurations.emphasizedCurve,
                    widthFactor: v,
                    heightFactor: 1,
                    child: ColoredBox(color: fill),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner tones.
enum MeridianBannerTone { info, success, warning, attention, error }

/// A persistent inline message about the state of the island or screen it
/// sits in: a bold title sentence, the detail, at most two actions.
///
/// Transient results ("Sent", "Archived 3 messages") are toasts, not
/// banners. Use [MeridianBannerTone.attention] for work to do (a paused
/// operation, a pending review), `error` only for failures.
class MeridianBanner extends StatelessWidget {
  const MeridianBanner({
    required this.message,
    super.key,
    this.title,
    this.tone = MeridianBannerTone.info,
    this.icon,
    this.actions = const [],
    this.onDismiss,
    this.dismissLabel,
    this.visible = true,
  });

  final String message;
  final String? title;
  final MeridianBannerTone tone;

  /// Keep the banner in the tree and switch this to show or hide it: it
  /// reveals with `motion-layout` while its content rises, and collapses
  /// when hidden (MM-65). A tone change animates its colours and swaps the
  /// icon (MM-66).

  /// Overrides the tone's icon.
  final String? icon;

  /// Small buttons (use `MeridianControlSize.small`).
  final List<Widget> actions;
  final VoidCallback? onDismiss;
  final String? dismissLabel;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final (fill, glyph, ink) = switch (tone) {
      MeridianBannerTone.info => (colors.paneAlt, 'info', colors.accentInk),
      MeridianBannerTone.success => (
        colors.successBg,
        'circle-check',
        colors.success,
      ),
      MeridianBannerTone.warning => (
        colors.warningBg,
        'triangle-alert',
        colors.warning,
      ),
      MeridianBannerTone.attention => (
        colors.attentionBg,
        'circle-alert',
        colors.attention,
      ),
      MeridianBannerTone.error => (colors.dangerBg, 'circle-x', colors.danger),
    };
    // Checked here, not in the constructor, so `const` banners still work.
    assert(
      actions.length <= MeridianLayout.bannerMaxActions,
      'A banner has at most two actions.',
    );
    // The text is one live node; the actions stay separate buttons so
    // assistive technology can reach them.
    final body = MergeSemantics(
      child: Semantics(
        liveRegion:
            tone == MeridianBannerTone.error ||
            tone == MeridianBannerTone.attention,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) Text(title!, style: meridian.text.bodyStrong),
            Text(message, style: meridian.text.body),
          ],
        ),
      ),
    );
    Widget content(BoxConstraints constraints) {
      // Enlarged labels also need the full width: side actions can otherwise
      // consume the row and squeeze the message to a word per line.
      final labelSize = meridian.text.label.fontSize!;
      final narrow =
          meridian.density.isTouch ||
          MediaQuery.textScalerOf(context).scale(labelSize) > labelSize ||
          constraints.maxWidth < MeridianLayout.bannerStackBreakpoint;
      final side = !narrow && (actions.isNotEmpty || onDismiss != null);
      // Side actions centre on the text block; the icon stays on the
      // first line.
      Widget centred(Widget child) => side ? Center(child: child) : child;
      return _MaybeIntrinsicHeight(
        enabled: side,
        child: Row(
          crossAxisAlignment: side
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: MeridianLayout.bannerIconNudge,
                ),
                child: MeridianSwap(
                  swapKey: (icon ?? glyph, tone),
                  style: MeridianSwapStyle.scale,
                  alignment: Alignment.center,
                  child: MeridianIcon(icon ?? glyph, color: ink),
                ),
              ),
            ),
            const SizedBox(width: MeridianSpace.space4),
            Expanded(
              child: narrow && actions.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        body,
                        const SizedBox(height: MeridianSpace.space4),
                        Wrap(
                          spacing: MeridianSpace.space3,
                          runSpacing: MeridianSpace.space3,
                          children: actions,
                        ),
                      ],
                    )
                  : Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: body,
                    ),
            ),
            if (!narrow)
              for (final action in actions) ...[
                const SizedBox(width: MeridianSpace.space3),
                centred(action),
              ],
            if (onDismiss != null) ...[
              const SizedBox(width: MeridianSpace.space2),
              centred(
                MeridianIconButton(
                  label:
                      dismissLabel ?? MeridianLocalizations.of(context).close,
                  icon: MeridianIcons.x,
                  size: MeridianControlSize.small,
                  onPressed: onDismiss,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return MeridianReveal(
      visible: visible,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: AnimatedContainer(
          duration: MeridianMotion.of(context, MeridianDurations.layout),
          curve: MeridianDurations.layoutCurve,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(meridian.radius.lg),
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(
            MeridianSpace.space5,
            MeridianSpace.space4,
            MeridianSpace.space4,
            MeridianSpace.space4,
          ),
          child: _BannerRise(
            visible: visible,
            child: LayoutBuilder(
              builder: (context, constraints) => content(constraints),
            ),
          ),
        ),
      ),
    );
  }
}

/// A banner's content rises `rise-content` each time the banner is shown.
class _BannerRise extends StatefulWidget {
  const _BannerRise({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_BannerRise> createState() => _BannerRiseState();
}

class _BannerRiseState extends State<_BannerRise> {
  var _shows = 0;

  @override
  void didUpdateWidget(_BannerRise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _shows++;
  }

  @override
  Widget build(BuildContext context) => _shows == 0
      ? widget.child
      : MeridianEntrance(
          key: ValueKey(_shows),
          entranceKey: (this, _shows),
          child: widget.child,
        );
}

class _MaybeIntrinsicHeight extends StatelessWidget {
  const _MaybeIntrinsicHeight({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      enabled ? IntrinsicHeight(child: child) : child;
}

/// Toast tones.
enum MeridianToastTone { neutral, success, warning, error }

/// A transient confirmation that floats at the bottom of the window:
/// "Archived 3 messages", with at most one action (usually Undo).
///
/// Show it with [showMeridianToast]. Errors that need a decision are
/// banners or dialogs, not toasts.
class MeridianToast extends StatelessWidget {
  const MeridianToast({
    required this.message,
    super.key,
    this.tone = MeridianToastTone.neutral,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.liveRegion = true,
  });

  final String message;
  final MeridianToastTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  /// Mark the toast as a live region. [showMeridianToast] turns this off
  /// and announces the message itself, which also works on iOS and macOS.
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final icon = switch (tone) {
      MeridianToastTone.neutral => null,
      MeridianToastTone.success => ('circle-check', colors.success),
      MeridianToastTone.warning => ('triangle-alert', colors.warning),
      MeridianToastTone.error => ('circle-x', colors.danger),
    };
    return Semantics(
      liveRegion: liveRegion,
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: MeridianLayout.toastWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.raised,
            borderRadius: BorderRadius.circular(meridian.radius.xl),
            boxShadow: meridian.shadows.shadowFloat,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              MeridianSpace.space6,
              MeridianSpace.space4,
              MeridianSpace.space3,
              MeridianSpace.space4,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final action = actionLabel != null && onAction != null
                    ? MeridianButton(
                        label: actionLabel!,
                        variant: MeridianButtonVariant.quiet,
                        size: MeridianControlSize.small,
                        onPressed: onAction,
                      )
                    : null;
                final dismiss = onDismiss != null
                    ? MeridianIconButton(
                        label: MeridianLocalizations.of(context).close,
                        icon: 'x',
                        size: MeridianControlSize.small,
                        onPressed: onDismiss,
                      )
                    : null;
                double textWidth(String value, TextStyle style) {
                  final painter = TextPainter(
                    text: TextSpan(text: value, style: style),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    locale: Localizations.maybeLocaleOf(context),
                  )..layout();
                  final width = painter.width;
                  painter.dispose();
                  return width;
                }

                final fixedWidth =
                    (icon == null
                        ? 0
                        : MeridianSize.icon + MeridianSpace.space4) +
                    (dismiss == null
                        ? MeridianSpace.space3
                        : meridian.density.controlSmallExtent +
                              MeridianSpace.space2);
                final actionWidth = action == null
                    ? 0
                    : textWidth(actionLabel!, meridian.text.label) +
                          MeridianSpace.space4 * 2 +
                          MeridianLayout.hairline * 2 +
                          MeridianSpace.space4;
                // Keep the full message readable. When the natural contents do
                // not fit side by side, the action gets a separate bounded row.
                final stacked =
                    action != null &&
                    textWidth(message, meridian.text.body) +
                            fixedWidth +
                            actionWidth >
                        constraints.maxWidth;
                final messageRow = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      MeridianIcon(icon.$1, color: icon.$2),
                      const SizedBox(width: MeridianSpace.space4),
                    ],
                    Flexible(child: Text(message, style: meridian.text.body)),
                    if (!stacked && action != null) ...[
                      const SizedBox(width: MeridianSpace.space4),
                      action,
                    ],
                    if (dismiss != null) ...[
                      const SizedBox(width: MeridianSpace.space2),
                      dismiss,
                    ] else
                      const SizedBox(width: MeridianSpace.space3),
                  ],
                );
                return stacked
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          messageRow,
                          const SizedBox(height: MeridianSpace.space2),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: action,
                          ),
                        ],
                      )
                    : messageRow;
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The toast on screen. Showing another replaces it.
_ToastHandle? _currentToast;

class _ToastHandle {
  final key = GlobalKey<_ToastHostState>();
  late final OverlayEntry entry;
  var _removed = false;

  /// Fades the toast out, then removes it.
  void dismiss() {
    final host = key.currentState;
    host == null ? removeNow() : host.exit();
  }

  /// Removes and disposes the entry straight away.
  void removeNow() {
    if (_removed) return;
    _removed = true;
    if (identical(_currentToast, this)) _currentToast = null;
    entry
      ..remove()
      ..dispose();
  }
}

/// Shows a [MeridianToast] above everything in the root overlay, arriving on a spring
/// as it fades in, and announces it to assistive technology. It stays for
/// [duration] (`motion-toast`, or `motion-toast-action` with an action);
/// hovering or focusing it pauses the countdown, which resumes when the
/// pointer and focus leave. Only one toast shows at a time: a new one
/// replaces the current one. Returns a callback that dismisses it early.
VoidCallback showMeridianToast(
  BuildContext context, {
  required String message,
  MeridianToastTone tone = MeridianToastTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  return _showToast(
    overlay,
    InheritedTheme.capture(from: context, to: overlay.context),
    message: message,
    tone: tone,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );
}

/// [showMeridianToast] in [overlay], with the theme above it. For a result
/// that arrives after the screen that started the work has closed: take
/// `Overlay.of(context, rootOverlay: true)` before the `await` and check
/// `overlay.mounted` after it. Does nothing when [overlay] is gone.
VoidCallback showMeridianToastIn(
  OverlayState overlay, {
  required String message,
  MeridianToastTone tone = MeridianToastTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) {
  if (!overlay.mounted) return () {};
  return _showToast(
    overlay,
    InheritedTheme.capture(from: overlay.context, to: overlay.context),
    message: message,
    tone: tone,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );
}

/// Fades out the toast that is showing, if any: when the state it reported
/// has been superseded.
void hideMeridianToast() => _currentToast?.dismiss();

VoidCallback _showToast(
  OverlayState overlay,
  CapturedThemes themes, {
  required String message,
  required MeridianToastTone tone,
  required String? actionLabel,
  required VoidCallback? onAction,
  required Duration? duration,
}) {
  _currentToast?.removeNow();
  final handle = _ToastHandle();
  handle.entry = OverlayEntry(
    builder: (context) => Positioned(
      left: MeridianSpace.space6,
      right: MeridianSpace.space6,
      bottom: MeridianSpace.space8 + MediaQuery.paddingOf(context).bottom,
      child: themes.wrap(
        Center(
          child: _ToastHost(
            key: handle.key,
            message: message,
            duration:
                duration ??
                (actionLabel == null
                    ? MeridianDurations.toast
                    : MeridianDurations.toastAction),
            onGone: handle.removeNow,
            timeRule: actionLabel != null,
            child: MeridianTextScope(
              child: MeridianToast(
                message: message,
                tone: tone,
                actionLabel: actionLabel,
                liveRegion: false,
                onAction: onAction == null
                    ? null
                    : () {
                        handle.dismiss();
                        onAction();
                      },
                onDismiss: handle.dismiss,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  _currentToast = handle;
  overlay.insert(handle.entry);
  return handle.dismiss;
}

/// Owns a shown toast's countdown, entrance and exit. The timer lives and
/// dies with the overlay entry.
class _ToastHost extends StatefulWidget {
  const _ToastHost({
    required this.message,
    required this.duration,
    required this.onGone,
    required this.child,
    super.key,
    this.timeRule = false,
  });

  final String message;
  final Duration duration;

  /// Show the shrinking time rule (toasts with an action, MM-49).
  final bool timeRule;
  final VoidCallback onGone;
  final Widget child;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost> with TickerProviderStateMixin {
  /// The arrival: 0 → 1 on `spring-gentle`.
  late final MeridianSpringController _arrive = MeridianSpringController(
    vsync: this,
  );
  late final AnimationController _opacity = AnimationController(vsync: this);

  /// The time rule of an action toast: 1 → 0 over its lifetime.
  late final AnimationController _rule = AnimationController(
    vsync: this,
    value: 1,
    duration: widget.duration,
  );
  Timer? _timer;
  final _clock = Stopwatch();
  late var _remaining = widget.duration;
  var _announced = false;
  var _hovered = false;
  var _focused = false;
  var _exiting = false;
  var _started = false;

  bool get _hasRule => widget.timeRule;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final reduced = MeridianMotion.reduced(context);
      if (reduced) {
        _arrive.jumpTo(1);
        _opacity.animateTo(
          1,
          duration: MeridianMotion.fade(context, MeridianDurations.quick),
        );
      } else {
        _arrive.animateTo(1, spring: MeridianSprings.gentle);
        _opacity.animateTo(
          1,
          duration: MeridianDurations.quick,
          curve: MeridianDurations.quickCurve,
        );
      }
      _schedule();
    }
    if (!_announced) {
      _announced = true;
      SemanticsService.sendAnnouncement(
        View.of(context),
        widget.message,
        Directionality.of(context),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _arrive.dispose();
    _opacity.dispose();
    _rule.dispose();
    super.dispose();
  }

  /// Runs the countdown, or pauses it while hovered or focused; a pause
  /// keeps the time left (MM-49).
  void _schedule() {
    final paused = _hovered || _focused || _exiting;
    if (paused) {
      if (_timer != null) {
        _timer!.cancel();
        _timer = null;
        _remaining -= _clock.elapsed;
        _clock
          ..stop()
          ..reset();
      }
      _rule.stop();
      return;
    }
    if (_timer != null) return;
    _clock
      ..reset()
      ..start();
    _timer = Timer(_remaining, exit);
    if (_hasRule && !MeridianMotion.reduced(context)) {
      _rule.animateTo(0, duration: _remaining);
    }
  }

  /// Fades out and moves away, then asks the handle to remove the entry.
  void exit() {
    if (_exiting) return;
    setState(() => _exiting = true);
    _timer?.cancel();
    _rule.stop();
    _opacity
        .animateTo(
          0,
          duration: MeridianMotion.fade(context, MeridianDurations.exit),
          curve: MeridianDurations.exitCurve,
        )
        .whenCompleteOrCancel(widget.onGone);
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final touch = meridian.density.isTouch;
    final reduced = MeridianMotion.reduced(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final side = touch ? 0.0 : (rtl ? -1.0 : 1.0);
    return MouseRegion(
      onEnter: (_) {
        _hovered = true;
        _schedule();
      },
      onExit: (_) {
        _hovered = false;
        _schedule();
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (value) {
          _focused = value;
          _schedule();
        },
        child: IgnorePointer(
          ignoring: _exiting,
          child: AnimatedBuilder(
            animation: Listenable.merge([_arrive.animation, _opacity]),
            child: _hasRule ? _withRule(context, widget.child) : widget.child,
            builder: (context, child) {
              // Arrives from `offset-toast` below (below and to the
              // trailing side on desktop); leaves 8 px outwards.
              final Offset offset;
              if (reduced) {
                offset = Offset.zero;
              } else if (_exiting) {
                final away =
                    MeridianLayout.selectionBarLeave * (1 - _opacity.value);
                offset = touch ? Offset(0, away) : Offset(away * side, 0);
              } else {
                final left =
                    MeridianMotionScales.offsetToast * (1 - _arrive.value);
                offset = Offset(left * side, left);
              }
              return Opacity(
                opacity: _opacity.value.clamp(0.0, 1.0),
                child: Transform.translate(offset: offset, child: child),
              );
            },
          ),
        ),
      ),
    );
  }

  /// An action toast's time rule: 1 px `line-strong` along its bottom that
  /// shrinks over its lifetime and pauses with the countdown.
  Widget _withRule(BuildContext context, Widget toast) {
    final meridian = MeridianTheme.of(context);
    final radius = BorderRadius.circular(meridian.radius.xl);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          toast,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MeridianLayout.hairline,
            child: AnimatedBuilder(
              animation: _rule,
              builder: (context, _) => FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: _rule.value,
                child: ColoredBox(color: meridian.colors.lineStrong),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What an empty list or screen says: an icon, a headline, one sentence on
/// what to do, and at most one action. Never a mascot or emoji.
///
/// With [progress] it says what is loading instead: a spinner takes the
/// icon's place (it waits `motion-spinner-delay` before it shows, so quick
/// loads never flash it) and the title is announced politely. With
/// [progressValue] a determinate bar follows the title. [compact] is the
/// in-pane variant for small islands and detail panes: the title in `body`,
/// the message in `caption`, tighter spacing.
class MeridianEmptyState extends StatelessWidget {
  const MeridianEmptyState({
    required this.title,
    super.key,
    this.icon,
    this.message,
    this.action,
    this.headline = false,
    this.progress = false,
    this.progressValue,
    this.compact = false,
  });

  final String title;
  final String? icon;
  final String? message;
  final Widget? action;

  /// Use the `display` style (first-run and welcome screens only).
  final bool headline;

  /// Something is loading: a spinner replaces [icon] and the title is a
  /// live region.
  final bool progress;

  /// How far the load is (0 to 1), shown as a bar under the title while
  /// [progress]; `null` shows only the spinner.
  final double? progressValue;

  /// The in-pane variant: `body` title, `caption` message, tighter gaps.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final touch = meridian.density.isTouch;
    final gap = compact
        ? MeridianSpace.space6
        : touch
        ? MeridianSpace.space10
        : MeridianSpace.space9;
    final titleStyle = compact
        ? meridian.text.body.copyWith(color: colors.ink)
        : headline
        ? meridian.text.display
        : meridian.text.heading;
    final messageStyle = (compact ? meridian.text.caption : meridian.text.body)
        .copyWith(color: colors.inkMuted);
    final icon = this.icon;
    final Widget? mark = progress
        ? MeridianSpinner(
            size: MeridianLayout.emptyStateIconSize,
            color: colors.inkMuted,
          )
        : icon == null
        ? null
        : MeridianIcon(
            icon,
            extent: MeridianLayout.emptyStateIconSize,
            color: colors.inkMuted,
          );
    // Scrolls rather than overflowing in a short island.
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: gap,
          horizontal: MeridianSpace.space6,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: MeridianLayout.emptyStateMaxWidth,
          ),
          // Icon, headline, text and action enter one after the other the
          // first time this empty state shows (MM-67).
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mark != null) ...[
                MeridianEntrance(
                  entranceKey: ('meridian-empty', title, 0),
                  child: mark,
                ),
                SizedBox(
                  height: compact ? MeridianSpace.space4 : MeridianSpace.space5,
                ),
              ],
              MeridianEntrance(
                entranceKey: ('meridian-empty', title, 1),
                index: 1,
                child: Semantics(
                  liveRegion: progress,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: titleStyle,
                  ),
                ),
              ),
              if (progress && progressValue != null) ...[
                const SizedBox(height: MeridianSpace.space4),
                SizedBox(
                  width: MeridianLayout.emptyStateProgressWidth,
                  child: MeridianProgressBar(
                    value: progressValue,
                    track: true,
                    persistent: true,
                  ),
                ),
              ],
              if (message != null) ...[
                SizedBox(
                  height: compact ? MeridianSpace.space2 : MeridianSpace.space3,
                ),
                MeridianEntrance(
                  entranceKey: ('meridian-empty', title, 2),
                  index: 2,
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: messageStyle,
                  ),
                ),
              ],
              if (action != null) ...[
                SizedBox(
                  height: compact ? MeridianSpace.space5 : MeridianSpace.space7,
                ),
                MeridianEntrance(
                  entranceKey: ('meridian-empty', title, 3),
                  index: 3,
                  child: action!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A placeholder bar for content that is loading. It breathes gently
/// (opacity 0.55 ↔ 1, `motion-skeleton-pulse`, MM-64) with no shimmer, so it
/// stays calm; use a few bars of different widths per row. Reduce motion
/// holds it at 0.7.
///
/// Pass `delay: MeridianDurations.skeletonDelay` so loads that finish
/// quickly never flash placeholders; the space is reserved meanwhile.
/// [MeridianSkeleton.swap] crossfades the loaded content in.
class MeridianSkeleton extends StatefulWidget {
  const MeridianSkeleton({
    super.key,
    this.width,
    this.height = MeridianLayout.skeletonHeight,
    this.delay = Duration.zero,
  });

  final double? width;
  final double height;

  /// How long to wait before the bar appears.
  final Duration delay;

  /// Shows [skeleton] until [loaded], then crossfades to [child] over
  /// `motion-quick` (MM-64).
  static Widget swap({
    required bool loaded,
    required Widget skeleton,
    required Widget child,
  }) => MeridianSwap(
    swapKey: loaded,
    duration: MeridianDurations.quick,
    child: loaded ? child : skeleton,
  );

  @override
  State<MeridianSkeleton> createState() => _MeridianSkeletonState();
}

class _MeridianSkeletonState extends State<MeridianSkeleton>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late bool _visible = widget.delay <= Duration.zero;
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: MeridianDurations.skeletonPulse,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _breath,
    curve: MeridianDurations.skeletonPulseCurve,
  );

  @override
  void initState() {
    super.initState();
    if (!_visible) {
      _timer = Timer(widget.delay, () {
        if (mounted) {
          setState(() => _visible = true);
          _sync();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  /// Breathes while visible and motion is allowed.
  void _sync() {
    final breathe = _visible && !MeridianMotion.reduced(context);
    if (breathe && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!breathe && _breath.isAnimating) {
      _breath.stop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final reduced = MeridianMotion.reduced(context);
    final bar = Container(
      width: widget.width,
      height: widget.height,
      decoration: _visible
          ? BoxDecoration(
              color: meridian.colors.paneHover,
              borderRadius: BorderRadius.circular(meridian.radius.xs),
            )
          : null,
    );
    return ExcludeSemantics(
      child: reduced
          ? Opacity(opacity: MeridianOpacity.skeletonStatic, child: bar)
          : AnimatedBuilder(
              animation: _curve,
              child: bar,
              builder: (context, child) => Opacity(
                // Breathes from full to `skeletonLow` and back.
                opacity: 1 - (1 - MeridianOpacity.skeletonLow) * _curve.value,
                child: child,
              ),
            ),
    );
  }
}

/// Covers a page or island while a blocking operation runs (signing in,
/// verifying): the content dims under a light `scrim` and takes no input,
/// and a `raised` pill shows a spinner and what is happening.
///
/// [action] (usually a quiet Cancel button) sits at the pill's end and stays
/// usable. Keep keyboard focus out of the covered content as well, for
/// example with [ExcludeFocus].
///
/// Prefer a button's `loading` state; use this only when the whole surface
/// must wait.
class MeridianBusyOverlay extends StatelessWidget {
  const MeridianBusyOverlay({super.key, this.message, this.action});

  /// What is happening ("Verifying…"), announced when it appears.
  final String? message;

  /// The one thing the user can still do, such as cancelling.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final action = this.action;
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      // Blocks input at once; shows only after `motion-spinner-delay`,
      // fading in over `motion-quick`, so fast work never flashes it
      // (MM-68).
      child: _DelayedFade(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AbsorbPointer(
              child: ColoredBox(
                color: colors.scrim.withValues(
                  alpha: colors.scrim.a * MeridianOpacity.busyScrim,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(MeridianSpace.space5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.raised,
                    borderRadius: BorderRadius.circular(meridian.radius.xl),
                    boxShadow: meridian.shadows.shadowFloat,
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: MeridianSpace.space6,
                      end: action == null
                          ? MeridianSpace.space6
                          : MeridianSpace.space3,
                      top: action == null
                          ? MeridianSpace.space5
                          : MeridianSpace.space3,
                      bottom: action == null
                          ? MeridianSpace.space5
                          : MeridianSpace.space3,
                    ),
                    child: MeridianTextScope(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MeridianSpinner(
                            size: meridian.density.iconSize,
                            color: colors.accent,
                            delayed: false,
                          ),
                          if (message case final text?) ...[
                            const SizedBox(width: MeridianSpace.space4),
                            Flexible(
                              child: Text(
                                text,
                                style: meridian.text.bodyStrong,
                              ),
                            ),
                          ],
                          if (action != null) ...[
                            const SizedBox(width: MeridianSpace.space4),
                            action,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows [child] after `motion-spinner-delay`, fading in over
/// `motion-quick`.
class _DelayedFade extends StatefulWidget {
  const _DelayedFade({required this.child});

  final Widget child;

  @override
  State<_DelayedFade> createState() => _DelayedFadeState();
}

class _DelayedFadeState extends State<_DelayedFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MeridianDurations.spinnerDelay + MeridianDurations.quick,
  )..forward();
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      MeridianDurations.spinnerDelay.inMicroseconds /
          (MeridianDurations.spinnerDelay + MeridianDurations.quick)
              .inMicroseconds,
      1,
      curve: MeridianDurations.quickCurve,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
