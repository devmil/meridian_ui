import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'display.dart';
import 'feedback.dart';
import 'menu.dart';

/// Button ranks. Use [primary] at most once per island or screen.
enum MeridianButtonVariant { primary, secondary, quiet, danger, dangerQuiet }

/// Control sizes. [small] sits in island headers and rows.
enum MeridianControlSize { regular, small }

/// A filled button's hover: [fill] with the primary hover overlay of
/// [onFill] on top ("primary brightens").
Color _brighten(Color fill, Color onFill) => Color.alphaBlend(
  onFill.withValues(alpha: MeridianOpacity.primaryHoverOverlay),
  fill,
);

/// A labelled command.
///
/// The label is the verb and its object in sentence case ("Move 3 messages
/// to archive"), never "OK". The width follows the label: never fix it,
/// German runs up to 40% longer.
class MeridianButton extends StatelessWidget {
  const MeridianButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = MeridianButtonVariant.secondary,
    this.size = MeridianControlSize.regular,
    this.icon,
    this.trailingIcon,
    this.shortcut,
    this.shortcutReveal = MeridianKbdReveal.always,
    this.loading = false,
    this.expand = false,
    this.autofocus = false,
    this.focusNode,
    this.disabledReason,
    this.tooltip,
    this.leading,
    this.success = false,
    this.successReplacesLabel = false,
    this.onSuccessFinished,
    this.animateLabel = false,
    this.iconOnly = false,
  });

  final String label;

  /// Icon presentation with the same accessible name and feedback owner.
  final bool iconOnly;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final MeridianButtonVariant variant;
  final MeridianControlSize size;

  /// Leading icon name.
  final String? icon;

  /// A leading picture instead of [icon], for what a Lucide glyph cannot
  /// show: a colour dot, a pen preset, an account avatar. Keep it within
  /// the density's icon size; it is decorative (the label names the
  /// command).
  final Widget? leading;

  /// Trailing icon name (for example `chevron-down` on a menu button).
  final String? trailingIcon;

  /// Shortcut keys shown inside the button, in the platform's glyphs.
  final List<String>? shortcut;

  /// When the [shortcut] keycaps show; see [MeridianKbd.reveal].
  final MeridianKbdReveal shortcutReveal;

  /// Keeps the label and swaps the icon for a spinner. The button keeps
  /// keyboard focus while loading but ignores activation. The spinner only
  /// appears after `motion-spinner-delay`, so fast work never flashes it
  /// (MM-03).
  final bool loading;

  /// Shows a drawn check for `motion-hold`, then the normal icon (MM-04).
  /// Edge-triggered: the check shows once each time this turns true.
  final bool success;

  /// Crossfade the whole label and decorations to a centred check instead of
  /// changing only the leading icon. The normal content stays mounted to keep
  /// the width, focus and accessible command name unchanged.
  final bool successReplacesLabel;

  /// Reports a completed success hold once. A new loading operation, success
  /// turning false or disposal cancels the pending report. The callback is
  /// bound when [success] turns true, so later rebuilds cannot replace its owner.
  final VoidCallback? onSuccessFinished;

  /// Swap a changing action label with a short rise while the button follows
  /// its new width. Keep this off for labels that never change in place.
  final bool animateLabel;

  /// Fill the available width (touch layouts, dialogs on phones).
  final bool expand;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Why the button is disabled; shown as its tooltip.
  final String? disabledReason;
  final String? tooltip;

  /// Activation while loading: focus stays, nothing runs.
  static void _busy() {}

  @override
  Widget build(BuildContext context) {
    assert(!iconOnly || icon != null);
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final text = meridian.text;
    final density = meridian.density;
    final interactive = onPressed != null;
    final enabled = interactive && !loading;
    final small = size == MeridianControlSize.small;
    final primary = variant == MeridianButtonVariant.primary;
    final (rest, edge, ink, hover, lip) = switch (variant) {
      MeridianButtonVariant.primary => (
        colors.accent,
        colors.accent,
        colors.onAccent,
        _brighten(colors.accent, colors.onAccent),
        const <BoxShadow>[],
      ),
      MeridianButtonVariant.secondary => (
        colors.pane,
        colors.lineStrong,
        colors.ink,
        colors.paneHover,
        meridian.shadows.shadowControl,
      ),
      MeridianButtonVariant.quiet => (
        meridianClear(colors.paneHover),
        meridianClear(colors.lineStrong),
        colors.ink,
        MeridianSurfaceScope.hoverFillOf(context),
        const <BoxShadow>[],
      ),
      MeridianButtonVariant.danger => (
        colors.danger,
        colors.danger,
        colors.onDanger,
        _brighten(colors.danger, colors.onDanger),
        const <BoxShadow>[],
      ),
      MeridianButtonVariant.dangerQuiet => (
        meridianClear(colors.dangerBg),
        meridianClear(colors.lineStrong),
        colors.danger,
        colors.dangerBg,
        const <BoxShadow>[],
      ),
    };
    // Disabled: `ink-faint` on no fill; primary: `ink-muted` on
    // `accent-soft`. Outlined ranks keep a `line` edge so they hold shape.
    final disabledFill = primary
        ? colors.accentSoft
        : meridianClear(colors.paneHover);
    final disabledEdge =
        variant == MeridianButtonVariant.secondary ||
            variant == MeridianButtonVariant.danger
        ? colors.line
        : meridianClear(colors.line);
    final disabledInk = primary ? colors.inkMuted : colors.inkFaint;
    final radius = BorderRadius.circular(meridian.radius.md);
    final keys = shortcut ?? const <String>[];
    final message = !interactive
        ? (disabledReason ?? tooltip ?? label)
        : tooltip ?? (keys.isEmpty ? null : '$label · ${keys.join(' ')}');
    Widget button = Semantics(
      excludeSemantics: true,
      button: true,
      enabled: enabled,
      label: label,
      hint: interactive ? null : disabledReason,
      onTap: enabled ? onPressed : null,
      liveRegion: loading,
      child: MeridianInteraction(
        onTap: !interactive
            ? null
            : loading
            ? _busy
            : onPressed,
        autofocus: autofocus,
        focusNode: focusNode,
        borderRadius: radius,
        cursor: loading ? SystemMouseCursors.basic : null,
        pressScale: true,
        builder: (context, state) {
          final fill = loading || success
              ? rest
              : !enabled
              ? disabledFill
              : state.fill(rest: rest, hoverFill: hover, ink: colors.ink);
          final active = enabled || loading || success;
          final foreground = active ? ink : disabledInk;
          final content = _ButtonContent(
            iconGap: !iconOnly,
            loading: loading,
            success: success,
            color: foreground,
            spinnerSize: density.iconSmallSize,
            icon: switch ((leading, icon)) {
              (final picture?, _) => Opacity(
                opacity: active ? 1 : MeridianOpacity.disabledContent,
                child: picture,
              ),
              (null, final name?) => MeridianIcon(
                name,
                size: MeridianIconSize.small,
                color: foreground,
              ),
              _ => null,
            },
            successReplacesLabel: successReplacesLabel,
            onSuccessFinished: onSuccessFinished,
            contentBuilder: (slot) => iconOnly
                ? Center(child: slot)
                : Row(
                    mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      slot,
                      Flexible(
                        child: animateLabel
                            ? MeridianSwap(
                                swapKey: label,
                                style: MeridianSwapStyle.rise,
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.label.copyWith(color: foreground),
                                ),
                              )
                            : Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.label.copyWith(color: foreground),
                              ),
                      ),
                      if (trailingIcon case final name?) ...[
                        const SizedBox(width: MeridianSpace.space3),
                        MeridianIcon(
                          name,
                          size: MeridianIconSize.small,
                          color: foreground,
                        ),
                      ],
                      if (keys.isNotEmpty)
                        // On-accent keycaps only on an `accent` fill; the danger
                        // fill takes the regular keycap. The gap belongs to the
                        // keycaps so a hidden hint leaves no trailing space.
                        MeridianKbd(
                          keys: keys,
                          onAccent: primary && active,
                          reveal: shortcutReveal,
                          padding: const EdgeInsetsDirectional.only(
                            start: MeridianSpace.space4,
                          ),
                        ),
                    ],
                  ),
          );
          // Density sets the minimum extent. Enlarged labels need their full
          // line height plus vertical breathing room, even at small sizes.
          return SizedBox(
            height: math.max(
              small ? density.controlSmallExtent : density.controlExtent,
              iconOnly
                  ? 0
                  : MediaQuery.textScalerOf(
                              context,
                            ).scale(text.label.fontSize!) *
                            (text.label.height ?? 1) +
                        MeridianSpace.space2 * 2,
            ),
            width: iconOnly
                ? (small ? density.controlSmallExtent : density.controlExtent)
                : expand
                ? double.infinity
                : null,
            child: AnimatedContainer(
              duration: meridianHoverDuration(
                context,
                state.hovered || state.pressed,
              ),
              decoration: BoxDecoration(
                color: fill,
                border: Border.all(color: active ? edge : disabledEdge),
                borderRadius: radius,
                boxShadow: active ? lip : const <BoxShadow>[],
              ),
              // The width follows the label and the icon slot (MM-03).
              // Geometry changes together with iconOnly/size; interpolating
              // old label padding inside the compact extent squeezes its icon.
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: iconOnly
                      ? 0
                      : small
                      ? MeridianSpace.space4
                      : MeridianSpace.space5,
                ),
                child: expand ? content : MeridianResize(child: content),
              ),
            ),
          );
        },
      ),
    );
    if (message != null) button = Tooltip(message: message, child: button);
    return button;
  }
}

/// Owns the loading delay and one success hold for both button presentations.
class _ButtonContent extends StatefulWidget {
  const _ButtonContent({
    this.iconGap = true,
    required this.loading,
    required this.success,
    required this.color,
    required this.spinnerSize,
    required this.icon,
    required this.contentBuilder,
    required this.successReplacesLabel,
    required this.onSuccessFinished,
  });

  final Widget Function(Widget slot) contentBuilder;
  final bool successReplacesLabel;
  final VoidCallback? onSuccessFinished;
  final bool iconGap;
  final bool loading;
  final bool success;
  final Color color;
  final double spinnerSize;
  final Widget? icon;

  @override
  State<_ButtonContent> createState() => _ButtonContentState();
}

class _ButtonContentState extends State<_ButtonContent> {
  /// The spinner shows once loading has lasted `motion-spinner-delay`.
  late var _spinning = widget.loading;
  var _checked = false;
  Timer? _spinnerDelay;
  Timer? _hold;

  @override
  void didUpdateWidget(_ButtonContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading != oldWidget.loading) {
      _spinnerDelay?.cancel();
      if (widget.loading) {
        _spinnerDelay = Timer(
          MeridianDurations.spinnerDelay * timeDilation,
          () {
            if (mounted && widget.loading) setState(() => _spinning = true);
          },
        );
      } else {
        _spinning = false;
      }
    }
    if (widget.loading || !widget.success) {
      _hold?.cancel();
      _checked = false;
    }
    if (!widget.loading && widget.success && !oldWidget.success) {
      _checked = true;
      _hold?.cancel();
      final finished = widget.onSuccessFinished;
      _hold = Timer(MeridianDurations.hold * timeDilation, () {
        if (!mounted) return;
        setState(() => _checked = false);
        finished?.call();
      });
    }
  }

  @override
  void dispose() {
    _spinnerDelay?.cancel();
    _hold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final (Object key, Widget? content) = _spinning
        ? (
            'spinner',
            MeridianSpinner(
              size: widget.spinnerSize,
              color: widget.color,
              delayed: false,
            ),
          )
        : _checked && !widget.successReplacesLabel
        ? (
            'success',
            MeridianStrokeIcon(
              MeridianIcons.check,
              appear: true,
              duration: MeridianLayout.successCheckDraw,
              size: meridian.density.iconSmallSize,
              color: widget.color,
            ),
          )
        : ('icon', widget.icon);
    final slot = content == null
        ? const SizedBox.shrink()
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianSwap(
                swapKey: key,
                style: MeridianSwapStyle.scale,
                duration: MeridianDurations.quick,
                alignment: Alignment.center,
                child: content,
              ),
              if (widget.iconGap) const SizedBox(width: MeridianSpace.space3),
            ],
          );
    final normal = widget.contentBuilder(slot);
    if (!widget.successReplacesLabel) return normal;
    final duration = MeridianMotion.fade(context, MeridianDurations.quick);
    final curve = MeridianMotion.curve(context, MeridianCurves.standard);
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: _checked ? 0 : 1,
          duration: duration,
          curve: curve,
          child: normal,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: _checked ? 1 : 0,
                duration: duration,
                curve: curve,
                child: MeridianStrokeIcon(
                  MeridianIcons.check,
                  drawn: _checked,
                  duration: MeridianLayout.successCheckDraw,
                  size: meridian.density.iconSmallSize,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A single-icon command for toolbars, island headers and row hover
/// actions. [label] is required: it is the tooltip and the accessible name.
///
/// Use it only where the icon is unambiguous; anything else is a
/// [MeridianButton] with a label.
class MeridianIconButton extends StatefulWidget {
  const MeridianIconButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
    this.size = MeridianControlSize.regular,
    this.active,
    this.onGround,
    this.color,
    this.disabledReason,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.nudge = MeridianNudge.none,
    this.turns,
    this.spinning = false,
    this.badge,
    this.badgeTone = MeridianCountTone.accent,
  });

  final String label;
  final String icon;
  final VoidCallback? onPressed;
  final MeridianControlSize size;

  /// Toggle state: `true` paints `accent-soft` with `accent-ink`.
  final bool? active;

  /// Sits on `ground` rather than an island (hover uses `ground-hover`).
  /// Defaults to the enclosing [MeridianSurfaceScope].
  final bool? onGround;

  /// Icon colour at rest; defaults to `ink-muted`. On a solid `accent`
  /// surface (a focused selection) the icon uses `on-accent-muted` instead.
  final Color? color;
  final String? disabledReason;
  final String? tooltip;
  final FocusNode? focusNode;
  final bool autofocus;

  /// `false` keeps keyboard focus where it is when the button is clicked
  /// and leaves it out of Tab order: row actions of a tree or table whose
  /// keys belong to the list (the expand chevron, a pin), and the arrows of
  /// a find bar whose field keeps typing. Offer the same command through the
  /// list's keys or menu.
  final bool canRequestFocus;

  /// How the icon moves when the button is activated (MM-07).
  final MeridianNudge nudge;

  /// Rotates the icon to this many turns over `motion-quick`: disclosure
  /// chevrons pass 0 or 0.25 (right chevrons) and 0 or 0.5 (down chevrons)
  /// (MM-05).
  final double? turns;

  /// Spins the icon one turn per `motion-spinner` while something the button
  /// started runs (a refresh). Switching it off finishes the current turn
  /// and stops, without snapping back. Reduce motion holds the icon still.
  final bool spinning;

  /// A count at the top trailing corner (running or failed work), which
  /// pops in, rolls and shrinks away like a toolbar badge (MM-06).
  final int? badge;

  /// The badge's tone; `attention` for failures.
  final MeridianCountTone badgeTone;

  @override
  State<MeridianIconButton> createState() => _MeridianIconButtonState();
}

class _MeridianIconButtonState extends State<MeridianIconButton>
    with SingleTickerProviderStateMixin {
  var _nudges = 0;

  /// A badge was shown once: keep its slot so it can animate away.
  var _badgeShown = false;

  /// Turns of the spinning icon; unbounded, one per `motion-spinner`.
  late final AnimationController _spin = AnimationController.unbounded(
    vsync: this,
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (widget.spinning) _startSpin();
    }
  }

  void _startSpin() {
    if (MeridianMotion.reduced(context)) return;
    final from = _spin.value;
    // Repeat whole turns from wherever the icon is now.
    _spin.animateWith(_SpinSimulation(from));
  }

  void _finishSpin() {
    if (!_spin.isAnimating) return;
    final value = _spin.value;
    final target = value.ceilToDouble();
    final left = target - value;
    _spin.animateTo(
      target,
      duration: MeridianDurations.spinner * left,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  /// The toggle changed since the last build: fill and ink take
  /// `motion-select` instead of the hover timing (MM-05).
  var _toggled = false;

  @override
  void didUpdateWidget(MeridianIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _toggled = (widget.active ?? false) != (oldWidget.active ?? false);
    if (widget.spinning != oldWidget.spinning) {
      widget.spinning ? _startSpin() : _finishSpin();
    }
  }

  void _pressed() {
    if (widget.nudge != MeridianNudge.none) setState(() => _nudges++);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed;
    final active = widget.active;
    final onGround = widget.onGround;
    final size = widget.size;
    final label = widget.label;
    final icon = widget.icon;
    final color = widget.color;
    final tooltip = widget.tooltip;
    final disabledReason = widget.disabledReason;
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final density = meridian.density;
    final enabled = onPressed != null;
    final small = size == MeridianControlSize.small;
    final on = active ?? false;
    final scope = MeridianSurfaceScope.maybeOf(context);
    final ground = onGround ?? scope?.onGround ?? false;
    // On a focused selection the usual inks vanish into the accent fill.
    final onAccent = scope?.fill == colors.accent;
    final extent = small ? density.controlSmallExtent : density.controlExtent;
    final radius = BorderRadius.circular(meridian.radius.md);
    final rest = on ? colors.accentSoft : meridianClear(colors.paneHover);
    final hover = on
        ? meridianPressed(colors.accentSoft, colors.ink)
        : MeridianSurfaceScope.hoverFillOf(context, onGround: ground);
    return Tooltip(
      message: enabled
          ? (tooltip ?? label)
          : (disabledReason ?? tooltip ?? label),
      child: Semantics(
        excludeSemantics: true,
        button: true,
        enabled: enabled,
        toggled: active,
        label: label,
        onTap: onPressed,
        child: MeridianInteraction(
          onTap: onPressed == null ? null : _pressed,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          canRequestFocus: widget.canRequestFocus,
          borderRadius: radius,
          pressScale: true,
          builder: (context, state) {
            final fill = !enabled
                ? meridianClear(hover)
                : state.fill(rest: rest, hoverFill: hover, ink: colors.ink);
            final ink = onAccent
                ? !enabled
                      ? colors.onAccentMuted.withValues(
                          alpha: MeridianOpacity.disabledContent,
                        )
                      : on || state.hovered || state.pressed
                      ? colors.onAccent
                      : colors.onAccentMuted
                : !enabled
                ? colors.inkFaint
                : on
                ? colors.accentInk
                : state.hovered || state.pressed
                ? colors.ink
                : (color ?? colors.inkMuted);
            final duration = _toggled
                ? MeridianMotion.of(context, MeridianDurations.select)
                : meridianHoverDuration(
                    context,
                    state.hovered || state.pressed,
                  );
            Widget glyph = TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: ink),
              duration: duration,
              curve: _toggled
                  ? MeridianDurations.selectCurve
                  : MeridianDurations.hoverCurve,
              builder: (context, color, _) => MeridianIcon(
                icon,
                size: small ? MeridianIconSize.small : MeridianIconSize.regular,
                color: color,
              ),
            );
            if (widget.turns case final turns?) {
              glyph = MeridianTurns(turns: turns, child: glyph);
            }
            glyph = AnimatedBuilder(
              animation: _spin,
              child: glyph,
              builder: (context, child) => Transform.rotate(
                angle: (_spin.value % 1) * 2 * math.pi,
                child: child,
              ),
            );
            // The size snaps; only the fill animates.
            final button = SizedBox.square(
              dimension: extent,
              child: AnimatedContainer(
                duration: duration,
                curve: _toggled
                    ? MeridianDurations.selectCurve
                    : MeridianDurations.hoverCurve,
                decoration: BoxDecoration(color: fill, borderRadius: radius),
                child: Center(
                  child: MeridianNudgeIcon(
                    trigger: _nudges,
                    direction: widget.nudge,
                    child: glyph,
                  ),
                ),
              ),
            );
            if (widget.badge == null && !_badgeShown) return button;
            _badgeShown = true;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                button,
                PositionedDirectional(
                  top: -MeridianLayout.toolbarBadgeTop,
                  end: -MeridianLayout.toolbarBadgeRight,
                  child: _ToolbarBadge(
                    count: widget.badge,
                    tone: widget.badgeTone,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A primary command in a desktop title bar: an 18px icon over a `caption`
/// label, on `ground`. Optional [badge] count and a split [menu] for
/// variants of the command.
class MeridianToolbarButton extends StatefulWidget {
  const MeridianToolbarButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
    this.selected = false,
    this.showLabel = true,
    this.badge,
    this.menu,
    this.menuLabel,
    this.disabledReason,
    this.tooltip,
    this.nudge = MeridianNudge.none,
  });

  final String label;
  final String icon;
  final VoidCallback? onPressed;
  final bool selected;

  /// How the icon moves when the command runs: Push `up`, Pull and Fetch
  /// `down`, Refresh `rotate` (MM-07).
  final MeridianNudge nudge;

  /// Hide the caption in narrow windows; the label stays the tooltip.
  final bool showLabel;

  /// A count to act on, shown as an `accent` Count and announced as the
  /// button's value.
  final int? badge;

  /// Items for the split caret.
  final List<MeridianMenuEntry>? menu;

  /// Tooltip and accessible name of the split caret ("More send options").
  /// Defaults to the localized "Show menu".
  final String? menuLabel;
  final String? disabledReason;
  final String? tooltip;

  @override
  State<MeridianToolbarButton> createState() => _MeridianToolbarButtonState();
}

class _MeridianToolbarButtonState extends State<MeridianToolbarButton> {
  var _nudges = 0;

  void _pressed() {
    if (widget.nudge != MeridianNudge.none) setState(() => _nudges++);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed;
    final menu = widget.menu;
    final selected = widget.selected;
    final icon = widget.icon;
    final showLabel = widget.showLabel;
    final label = widget.label;
    final tooltip = widget.tooltip;
    final disabledReason = widget.disabledReason;
    final badge = widget.badge;
    final menuLabel = widget.menuLabel;
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final text = meridian.text;
    final enabled = onPressed != null;
    final entries = menu;
    final direction = Directionality.of(context);
    final radius = BorderRadius.circular(meridian.radius.md);
    final faceRadius = entries == null
        ? radius
        : BorderRadiusDirectional.horizontal(
            start: radius.topLeft,
          ).resolve(direction);
    final caretRadius = BorderRadiusDirectional.horizontal(
      end: radius.topRight,
    ).resolve(direction);
    final rest = selected
        ? colors.accentSoft
        : meridianClear(colors.groundHover);
    final hover = selected
        ? meridianPressed(colors.accentSoft, colors.ink)
        : colors.groundHover;
    Widget face(MeridianInteractionState state) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        MeridianNudgeIcon(
          trigger: _nudges,
          direction: widget.nudge,
          child: MeridianIcon(
            icon,
            size: MeridianIconSize.toolbar,
            color: enabled ? colors.ink : colors.inkFaint,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: MeridianLayout.toolbarLabelGap),
          Text(
            label.replaceAll('…', ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.caption.copyWith(
              color: !enabled
                  ? colors.inkFaint
                  : state.hovered || state.pressed
                  ? colors.ink
                  : colors.inkMuted,
            ),
          ),
        ],
      ],
    );
    final button = Tooltip(
      message: enabled
          ? (tooltip ?? label)
          : (disabledReason ?? tooltip ?? label),
      child: Semantics(
        excludeSemantics: true,
        button: true,
        selected: selected,
        enabled: enabled,
        label: label,
        value: badge?.toString(),
        onTap: onPressed,
        child: MeridianInteraction(
          onTap: onPressed == null ? null : _pressed,
          focusOnPointer: false,
          borderRadius: faceRadius,
          pressScale: true,
          builder: (context, state) => AnimatedContainer(
            duration: meridianHoverDuration(
              context,
              state.hovered || state.pressed,
            ),
            constraints: BoxConstraints(
              minWidth: showLabel
                  ? MeridianLayout.toolbarButtonMinWidth
                  : MeridianLayout.toolbarButtonCompactWidth,
            ),
            height: MeridianLayout.toolbarButtonHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: MeridianSpace.space3,
            ),
            decoration: BoxDecoration(
              color: state.fill(rest: rest, hoverFill: hover, ink: colors.ink),
              borderRadius: faceRadius,
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                face(state),
                PositionedDirectional(
                  top: MeridianLayout.toolbarBadgeTop,
                  end: -MeridianLayout.toolbarBadgeRight,
                  child: _ToolbarBadge(count: badge),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (entries == null) return button;
    final caretLabel =
        menuLabel ?? MaterialLocalizations.of(context).showMenuTooltip;
    Widget caret(VoidCallback open) => Tooltip(
      message: caretLabel,
      child: Semantics(
        excludeSemantics: true,
        button: true,
        enabled: enabled,
        label: caretLabel,
        onTap: enabled ? open : null,
        child: MeridianInteraction(
          onTap: enabled ? open : null,
          focusOnPointer: false,
          borderRadius: caretRadius,
          builder: (context, state) => AnimatedContainer(
            duration: meridianHoverDuration(
              context,
              state.hovered || state.pressed,
            ),
            width: MeridianLayout.splitCaretWidth,
            height: MeridianLayout.toolbarButtonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: state.fill(
                rest: meridianClear(colors.groundHover),
                hoverFill: colors.groundHover,
                ink: colors.ink,
              ),
              borderRadius: caretRadius,
            ),
            child: MeridianIcon(
              MeridianIcons.chevronDown,
              extent: MeridianLayout.splitCaretIconSize,
              color: enabled ? colors.inkMuted : colors.inkFaint,
            ),
          ),
        ),
      ),
    );
    // The anchor wraps the whole split button so the menu lines up with it
    // and is at least as wide.
    return MeridianMenuAnchor(
      entries: entries,
      builder: (context, open) =>
          Row(mainAxisSize: MainAxisSize.min, children: [button, caret(open)]),
    );
  }
}

/// A toolbar button's count (MM-06): pops in on `spring-pop`, shrinks to
/// 0.6 and fades over `motion-exit` when it goes, and rolls when it
/// changes (popping on increase).
class _ToolbarBadge extends StatefulWidget {
  const _ToolbarBadge({
    required this.count,
    this.tone = MeridianCountTone.accent,
  });

  final int? count;
  final MeridianCountTone tone;

  @override
  State<_ToolbarBadge> createState() => _ToolbarBadgeState();
}

class _ToolbarBadgeState extends State<_ToolbarBadge>
    with TickerProviderStateMixin {
  late int? _shown = widget.count;
  late final MeridianSpringController _scale = MeridianSpringController(
    vsync: this,
    value: widget.count == null ? 0 : 1,
  );
  late final AnimationController _opacity = AnimationController(
    vsync: this,
    value: widget.count == null ? 0 : 1,
  );

  @override
  void didUpdateWidget(_ToolbarBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = widget.count;
    final reduced = MeridianMotion.reduced(context);
    if (count != null) {
      _shown = count;
      if (oldWidget.count == null) {
        if (reduced) {
          _scale.jumpTo(1);
          _opacity.value = 1;
        } else {
          _scale
            ..jumpTo(0)
            ..animateTo(1, spring: MeridianSprings.pop);
          _opacity.animateTo(
            1,
            duration: MeridianDurations.quick,
            curve: MeridianDurations.quickCurve,
          );
        }
      }
    } else if (oldWidget.count != null) {
      if (reduced) {
        _scale.jumpTo(0);
        _opacity.value = 0;
        _shown = null;
        return;
      }
      _scale.animateToTimed(
        MeridianOpacity.badgeLeaveScale,
        duration: MeridianDurations.exit,
        curve: MeridianDurations.exitCurve,
      );
      _opacity
          .animateTo(
            0,
            duration: MeridianDurations.exit,
            curve: MeridianDurations.exitCurve,
          )
          .whenCompleteOrCancel(() {
            if (mounted && widget.count == null) setState(() => _shown = null);
          });
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    _opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    if (shown == null) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _opacity,
      child: AnimatedBuilder(
        animation: _scale.animation,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: MeridianCount(
          label: '$shown',
          tone: widget.tone,
          emphasizeIncrease: true,
        ),
      ),
    );
  }
}

/// The one prominent command of a touch screen that floats over its
/// content: create a notebook, compose a message. An `accent` square with
/// `radius-lg` corners and `shadow-float`, 56px; with [extended] it is a
/// pill that also shows the [label]. [label] is always the tooltip and the
/// accessible name.
///
/// At most one per screen, at the bottom trailing corner, clear of the
/// content's last row. Desktop layouts put the command in the toolbar.
class MeridianFloatingButton extends StatelessWidget {
  const MeridianFloatingButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
    this.extended = false,
    this.tooltip,
    this.focusNode,
  });

  final String label;
  final String icon;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  /// Show the label next to the icon.
  final bool extended;
  final String? tooltip;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(meridian.radius.lg);
    final ink = enabled ? colors.onAccent : colors.inkMuted;
    return Tooltip(
      message: tooltip ?? label,
      excludeFromSemantics: true,
      child: Semantics(
        excludeSemantics: true,
        button: true,
        enabled: enabled,
        label: label,
        onTap: onPressed,
        child: MeridianInteraction(
          onTap: onPressed,
          focusNode: focusNode,
          borderRadius: radius,
          pressScale: true,
          builder: (context, state) => AnimatedContainer(
            duration: meridianHoverDuration(
              context,
              state.hovered || state.pressed,
            ),
            height: MeridianLayout.floatingButtonSize,
            constraints: const BoxConstraints(
              minWidth: MeridianLayout.floatingButtonSize,
            ),
            padding: extended
                ? const EdgeInsetsDirectional.only(
                    start: MeridianSpace.space6,
                    end: MeridianSpace.space7,
                  )
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: enabled
                  ? state.fill(
                      rest: colors.accent,
                      hoverFill: _brighten(colors.accent, colors.onAccent),
                      ink: colors.ink,
                    )
                  : colors.accentSoft,
              borderRadius: radius,
              boxShadow: enabled
                  ? meridian.shadows.shadowFloat
                  : const <BoxShadow>[],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MeridianIcon(icon, color: ink),
                if (extended) ...[
                  const SizedBox(width: MeridianSpace.space4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: meridian.text.label.copyWith(color: ink),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Whole turns, one per `motion-spinner`, from [start].
class _SpinSimulation extends Simulation {
  _SpinSimulation(this.start);

  final double start;

  @override
  double x(double time) =>
      start +
      time *
          Duration.microsecondsPerSecond /
          MeridianDurations.spinner.inMicroseconds;

  @override
  double dx(double time) =>
      Duration.microsecondsPerSecond / MeridianDurations.spinner.inMicroseconds;

  @override
  bool isDone(double time) => false;
}
