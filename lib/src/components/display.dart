import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_icons.g.dart';

import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'tooltip.dart';

/// Keyboard keys for a shortcut, in the platform's glyphs: ⌘ ⇧ ⌥ ↵ on
/// macOS, the words Ctrl, Shift, Alt, Enter elsewhere.
class MeridianKbd extends StatelessWidget {
  const MeridianKbd({
    required this.keys,
    super.key,
    this.onAccent = false,
    this.reveal = MeridianKbdReveal.always,
    this.padding = EdgeInsets.zero,
    this.pressed,
  });

  final List<String> keys;

  /// Draws the caps pressed: sunk 1 px without their lip (MM-17). `null`
  /// follows the keyboard: a shortcut with a command modifier shows pressed
  /// while its whole chord is held.
  final bool? pressed;

  /// Drawn inside an `accent` fill (primary button, highlighted menu row).
  final bool onAccent;

  /// When the keycaps show. Hints on permanent chrome (buttons, the title
  /// bar) use [MeridianKbdReveal.whileModifierHeld]; menus, the palette and
  /// shortcut references keep [MeridianKbdReveal.always].
  final MeridianKbdReveal reveal;

  /// Space around the keycaps, collapsed with them while they are hidden.
  final EdgeInsetsGeometry padding;

  /// The command modifiers named in [keys]: ⌘/Cmd/Meta, ⌃/Ctrl, ⌥/Alt.
  static Set<MeridianModifier> modifiersOf(List<String> keys) => {
    for (final key in keys)
      ?switch (key.toLowerCase()) {
        '⌘' || 'cmd' || 'command' || 'meta' => MeridianModifier.meta,
        '⌃' || 'ctrl' || 'control' => MeridianModifier.control,
        '⌥' || 'alt' || 'option' => MeridianModifier.alt,
        _ => null,
      },
  };

  /// Whether every key of [keys] is held right now.
  bool _chordHeld(Set<MeridianModifier> modifiers) {
    final held = MeridianHeldModifiers.instance;
    if (modifiers.isEmpty || !held.value.containsAll(modifiers)) return false;
    final down = held.keys;
    for (final key in keys) {
      final lower = key.toLowerCase();
      if (modifiersOf([key]).isNotEmpty) continue;
      final matches = switch (lower) {
        '⇧' || 'shift' => HardwareKeyboard.instance.isShiftPressed,
        '↵' || 'enter' || 'return' => down.contains(LogicalKeyboardKey.enter),
        _ => down.any((k) => k.keyLabel.toLowerCase() == lower),
      };
      if (!matches) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final modifiers = modifiersOf(keys);
    final follow = pressed == null && modifiers.isNotEmpty;
    if ((reveal == MeridianKbdReveal.always || modifiers.isEmpty) && !follow) {
      return _keycaps(context, pressed ?? false);
    }
    const duration = MeridianDurations.hover;
    return ValueListenableBuilder<Set<MeridianModifier>>(
      valueListenable: MeridianHeldModifiers.instance,
      builder: (context, held, _) {
        final down = pressed ?? _chordHeld(modifiers);
        if (reveal == MeridianKbdReveal.always || modifiers.isEmpty) {
          return _keycaps(context, down);
        }
        final visible = held.any(modifiers.contains);
        return MeridianReveal(
          visible: visible,
          axis: Axis.horizontal,
          duration: duration,
          child: _keycaps(context, down),
        );
      },
    );
  }

  Widget _keycaps(BuildContext context, bool down) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    return ExcludeSemantics(
      child: Padding(
        padding: padding,
        child: Wrap(
          spacing: MeridianLayout.kbdGap,
          runSpacing: MeridianLayout.kbdGap,
          children: [
            for (var i = 0; i < keys.length; i++)
              IntrinsicWidth(
                child: _KeyCap(
                  down: down,
                  // Grows with large text instead of clipping the glyph.
                  constraints: const BoxConstraints(
                    minWidth: MeridianLayout.kbdMinWidth,
                    minHeight: MeridianLayout.kbdHeight,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: MeridianLayout.kbdPaddingX,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: onAccent ? const Color(0x00000000) : colors.paneAlt,
                    border: Border.all(
                      color: onAccent
                          ? colors.onAccentMuted
                          : colors.lineStrong,
                    ),
                    borderRadius: BorderRadius.circular(meridian.radius.xs),
                    boxShadow: onAccent
                        ? const []
                        : [
                            BoxShadow(
                              offset: const Offset(0, MeridianLayout.hairline),
                              color: colors.lineStrong,
                            ),
                          ],
                  ),
                  child: Text(
                    keys[i],
                    style: meridian.text.caption.copyWith(
                      color: onAccent ? colors.onAccent : colors.inkMuted,
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

/// One keycap. While [down] it sinks 1 px and loses its lip over
/// `motion-hover` (MM-17); reduce motion keeps only the lip change.
class _KeyCap extends StatelessWidget {
  const _KeyCap({
    required this.down,
    required this.constraints,
    required this.padding,
    required this.alignment,
    required this.decoration,
    required this.child,
  });

  final bool down;
  final BoxConstraints constraints;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final BoxDecoration decoration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MeridianMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: down ? 1 : 0),
      duration: MeridianMotion.of(context, MeridianDurations.hover),
      builder: (context, t, child) {
        final shadows = decoration.boxShadow;
        return Transform.translate(
          offset: Offset(0, reduced ? 0 : MeridianLayout.hairline * t),
          child: Container(
            constraints: constraints,
            padding: padding,
            decoration: decoration.copyWith(
              boxShadow: shadows == null || t == 0
                  ? shadows
                  : [for (final s in shadows) s.scale(1 - t)],
            ),
            // Hugs the glyph: a taller slot (a pill or row that centres
            // its children) must not stretch the cap to its own height.
            child: Align(
              alignment: alignment,
              widthFactor: 1,
              heightFactor: 1,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// When a [MeridianKbd] shows its keycaps.
enum MeridianKbdReveal {
  /// Always.
  always,

  /// Only while one of its command modifiers (⌘, Ctrl, ⌥) is held, so the
  /// hint appears when the person reaches for the shortcut. Keys without a
  /// command modifier always show.
  whileModifierHeld,
}

/// Count badge tones.
enum MeridianCountTone { neutral, accent, attention, danger, quiet }

/// A pill number: unread mail, items to act on, section totals.
///
/// [MeridianCountTone.accent] marks something actionable, `attention` work
/// to do, `danger` failures, `quiet` a bare `ink-muted` number (section
/// headers).
class MeridianCount extends StatelessWidget {
  const MeridianCount({
    required this.label,
    super.key,
    this.tone = MeridianCountTone.neutral,
    this.semanticLabel,
    this.emphasizeIncrease = false,
  });

  /// A whole number rolls digit by digit when it changes; other labels roll
  /// in as a whole (MM-70).
  final String label;
  final MeridianCountTone tone;
  final String? semanticLabel;

  /// Pop (`spring-pop`) when the number grows: new work to act on.
  final bool emphasizeIncrease;

  @override
  Widget build(BuildContext context) {
    final colors = MeridianTheme.of(context).colors;
    final (fill, ink) = switch (tone) {
      MeridianCountTone.neutral => (colors.line, colors.ink),
      MeridianCountTone.accent => (colors.accent, colors.onAccent),
      MeridianCountTone.attention => (colors.attention, colors.onAttention),
      MeridianCountTone.danger => (colors.danger, colors.onDanger),
      MeridianCountTone.quiet => (const Color(0x00000000), colors.inkMuted),
    };
    final quiet = tone == MeridianCountTone.quiet;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Container(
        // Minimums, not a fixed size: large text grows the pill.
        constraints: BoxConstraints(
          minWidth: quiet ? 0 : MeridianLayout.countMinWidth,
          minHeight: MeridianLayout.countHeight,
        ),
        padding: quiet
            ? null
            : const EdgeInsets.symmetric(
                horizontal: MeridianLayout.countPaddingX,
              ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(MeridianRadiusScale.pill),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: _countLabel(
            TextStyle(
              fontFamily: MeridianTheme.of(context).brand.fonts.sans,
              fontSize: MeridianLayout.countFontSize,
              height: MeridianLayout.countLineHeight,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}

extension on MeridianCount {
  Widget _countLabel(TextStyle style) {
    final number = int.tryParse(label);
    if (number != null && '$number' == label) {
      return MeridianRollingNumber(
        value: number,
        style: style,
        popOnIncrease: emphasizeIncrease,
      );
    }
    return MeridianSwap(
      swapKey: label,
      style: MeridianSwapStyle.roll,
      alignment: Alignment.center,
      child: Text(label, style: style),
    );
  }
}

/// Avatar sizes: 16px in rows, 20px in touch rows, 28px in headers and
/// mail rows, 40px for the person a page is about (an account, a contact).
enum MeridianAvatarSize { small, medium, large, xLarge }

/// A person's initials on a categorical colour picked from a stable hash of
/// their name, so the same person keeps the same colour everywhere.
///
/// Decorative: it always sits next to the name as text.
class MeridianAvatar extends StatelessWidget {
  const MeridianAvatar({
    required this.name,
    super.key,
    this.size = MeridianAvatarSize.small,
    this.image,
    this.colorKey,
    this.monogram,
    this.onPressed,
    this.tooltip,
  });

  final String name;
  final MeridianAvatarSize size;

  /// Makes the avatar a button (open a profile, offer to load pictures),
  /// with a focus ring and the pressed state. It is announced as a button
  /// named [tooltip] (or [name]).
  final VoidCallback? onPressed;

  /// The hover tooltip of a pressable avatar; defaults to [name].
  final String? tooltip;

  /// An optional picture that replaces the fill (same size and shape). The
  /// initials show while it loads and when it fails. A loaded picture sits on
  /// `pane`, so a logo with a transparent background never shows the fill or
  /// the initials through it.
  final ImageProvider? image;

  /// Hash this instead of [name] (for example an email address).
  final String? colorKey;

  /// Overrides the initials derived from [name] (at most two characters),
  /// for an app that already knows them.
  final String? monogram;

  static const _order = [0, 1, 5, 4, 6, 3, 2, 7];

  /// Up to two initials from [name].
  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'[\s._@-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  /// The index into `series` for [key].
  static int colorIndex(String key) {
    var hash = 0;
    for (final unit in key.toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _order[hash % _order.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = MeridianTheme.of(context).colors;
    final dimension = switch (size) {
      MeridianAvatarSize.small => MeridianLayout.avatarSmall,
      MeridianAvatarSize.medium => MeridianLayout.avatarMedium,
      MeridianAvatarSize.large => MeridianLayout.avatarLarge,
      MeridianAvatarSize.xLarge => MeridianLayout.avatarXLarge,
    };
    final fontSize = switch (size) {
      MeridianAvatarSize.small => MeridianLayout.avatarFontSmall,
      MeridianAvatarSize.medium => MeridianLayout.avatarFontMedium,
      MeridianAvatarSize.large => MeridianLayout.avatarFontLarge,
      MeridianAvatarSize.xLarge => MeridianLayout.avatarFontXLarge,
    };
    final fill = colors.series[colorIndex(colorKey ?? name)];
    final given = monogram?.trim();
    // The circle has a fixed size; large text scales the initials down to
    // fit rather than clipping them.
    final letters = Padding(
      padding: const EdgeInsets.all(MeridianSpace.space1),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          given == null || given.isEmpty
              ? initials(name)
              : given.characters.take(2).toString().toUpperCase(),
          maxLines: 1,
          style: TextStyle(
            fontFamily: MeridianTheme.of(context).brand.fonts.sans,
            fontSize: fontSize,
            height: 1,
            fontWeight: FontWeight.w700,
            color: colors.pane,
          ),
        ),
      ),
    );
    final picture = image;
    final avatar = ExcludeSemantics(
      child: Container(
        width: dimension,
        height: dimension,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: picture == null
            ? letters
            : Image(
                image: picture,
                width: dimension,
                height: dimension,
                fit: BoxFit.cover,
                // A loaded image fades in over the initials (MM-71) on an
                // opaque backing that hides them.
                frameBuilder: (context, child, frame, synchronous) {
                  final backed = ColoredBox(color: colors.pane, child: child);
                  return synchronous
                      ? backed
                      : Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.center,
                          children: [
                            Center(child: letters),
                            AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: MeridianMotion.of(
                                context,
                                MeridianDurations.quick,
                              ),
                              curve: MeridianDurations.quickCurve,
                              child: backed,
                            ),
                          ],
                        );
                },
                errorBuilder: (context, error, stackTrace) => letters,
              ),
      ),
    );
    final onPressed = this.onPressed;
    if (onPressed == null) return avatar;
    final label = tooltip ?? name;
    return MeridianTooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        onTap: onPressed,
        child: MeridianInteraction(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(dimension / 2),
          builder: (context, state) => AnimatedOpacity(
            opacity: state.pressed ? MeridianOpacity.avatarPressed : 1,
            duration: meridianHoverDuration(context, state.pressed),
            child: avatar,
          ),
        ),
      ),
    );
  }
}

/// Chip tones. [neutral] is an outlined label, [accent] a selected filter or
/// an entity of the app's own (a local account, the current folder).
enum MeridianChipTone { neutral, accent, success, warning, danger, attention }

/// A compact label: a filter, a tag, a recipient, an attachment.
///
/// Tappable when [onPressed] is set, removable when [onRemove] is set, a
/// toggle when [selected] is set. [dotColor] adds a category dot (use a
/// `series` colour) that always goes with the text. At touch density the
/// remove button is its own 48px target.
class MeridianChip extends StatelessWidget {
  const MeridianChip({
    required this.label,
    super.key,
    this.icon,
    this.dotColor,
    this.tone = MeridianChipTone.neutral,
    this.selected,
    this.onPressed,
    this.onRemove,
    this.removeLabel,
    this.maxWidth = MeridianLayout.chipMaxWidth,
    this.enabled = true,
    this.visible = true,
  });

  final String label;
  final String? icon;
  final Color? dotColor;
  final MeridianChipTone tone;

  /// Toggle state for filter chips.
  final bool? selected;
  final VoidCallback? onPressed;
  final VoidCallback? onRemove;

  /// Accessible label of the remove button, for example "Remove Anna".
  final String? removeLabel;
  final double maxWidth;

  /// A disabled chip keeps its shape in `ink-faint` and ignores input.
  final bool enabled;

  /// Set to false to remove the chip: it fades and its width collapses
  /// over `motion-layout` (MM-72).
  final bool visible;

  @override
  Widget build(BuildContext context) => MeridianReveal(
    visible: visible,
    axis: Axis.horizontal,
    child: _chip(context),
  );

  Widget _chip(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final density = meridian.density;
    final touch = density.isTouch;
    final on = selected ?? false;
    final (fill, ink, edge) = !enabled
        ? (meridianClear(colors.paneHover), colors.inkFaint, colors.line)
        : on
        ? (
            colors.accentSoft,
            colors.accentInk,
            meridianClear(colors.lineStrong),
          )
        : switch (tone) {
            MeridianChipTone.neutral => (
              meridianClear(colors.paneHover),
              colors.ink,
              colors.lineStrong,
            ),
            MeridianChipTone.accent => (
              colors.accentSoft,
              colors.accentInk,
              meridianClear(colors.lineStrong),
            ),
            MeridianChipTone.success => (
              colors.successBg,
              colors.success,
              meridianClear(colors.lineStrong),
            ),
            MeridianChipTone.warning => (
              colors.warningBg,
              colors.warning,
              meridianClear(colors.lineStrong),
            ),
            MeridianChipTone.danger => (
              colors.dangerBg,
              colors.danger,
              meridianClear(colors.lineStrong),
            ),
            MeridianChipTone.attention => (
              colors.attentionBg,
              colors.attention,
              meridianClear(colors.lineStrong),
            ),
          };
    // Every tone hovers except a selected filter, which only shows press.
    final hover = on
        ? fill
        : fill.a == 0
        ? colors.paneHover
        : meridianPressed(fill, colors.ink);
    final radius = BorderRadius.circular(meridian.radius.sm);
    final height = math.max(
      touch ? MeridianLayout.chipHeightTouch : MeridianLayout.chipHeight,
      MediaQuery.textScalerOf(context).scale(meridian.text.label.fontSize!) *
              (meridian.text.label.height ?? 1) +
          MeridianSpace.space1 * 2,
    );
    final press = enabled ? onPressed : null;
    final remove = enabled ? onRemove : null;
    final removable = onRemove != null;
    final side = touch ? MeridianSpace.space5 : MeridianSpace.space4;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dotColor case final dot?) ...[
          Opacity(
            opacity: enabled ? 1 : MeridianOpacity.disabledContent,
            child: Container(
              width: MeridianLayout.statusDot,
              height: MeridianLayout.statusDot,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: MeridianSpace.space3),
        ] else if (on && icon == null) ...[
          MeridianIcon(
            MeridianIcons.check,
            size: MeridianIconSize.small,
            color: ink,
          ),
          const SizedBox(width: MeridianSpace.space2),
        ] else if (icon case final name?) ...[
          MeridianIcon(name, size: MeridianIconSize.small, color: ink),
          const SizedBox(width: MeridianSpace.space2),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: meridian.text.label.copyWith(color: ink),
          ),
        ),
      ],
    );

    Color faceFill(MeridianInteractionState? state) => state == null
        ? fill
        : state.fill(rest: fill, hoverFill: hover, ink: colors.ink);

    if (!removable) {
      Widget pill(MeridianInteractionState? state) => AnimatedContainer(
        duration: meridianHoverDuration(
          context,
          (state?.hovered ?? false) || (state?.pressed ?? false),
        ),
        height: height,
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(horizontal: side),
        decoration: BoxDecoration(
          color: faceFill(state),
          border: Border.all(color: edge),
          borderRadius: radius,
        ),
        child: content,
      );
      if (onPressed == null) {
        return Semantics(
          label: label,
          enabled: enabled ? null : false,
          child: ExcludeSemantics(child: pill(null)),
        );
      }
      return Semantics(
        excludeSemantics: true,
        button: true,
        enabled: enabled,
        selected: selected,
        label: label,
        onTap: press,
        child: MeridianInteraction(
          onTap: press,
          borderRadius: radius,
          pressScale: true,
          builder: (context, state) => pill(state),
        ),
      );
    }

    // Removable: the face and the remove button are separate targets on one
    // pill. The remove target may be taller and wider than the pill (48px at
    // touch); the pill is painted inset behind them so every pixel of both
    // targets is hit-testable.
    final removeVisual = touch
        ? MeridianLayout.chipRemoveSizeTouch
        : MeridianLayout.chipRemoveSize;
    final removeBox = math.max(removeVisual, density.minTarget);
    final overhang = math.max(
      0.0,
      (removeBox - removeVisual) / 2 - MeridianSpace.space1,
    );
    final rowHeight = math.max(height, removeBox);
    final inset = (rowHeight - height) / 2;
    final directional = Directionality.of(context);
    final faceRadius = BorderRadiusDirectional.horizontal(start: radius.topLeft)
        .resolve(directional);
    Widget face(MeridianInteractionState? state) => AnimatedContainer(
      duration: meridianHoverDuration(
        context,
        (state?.hovered ?? false) || (state?.pressed ?? false),
      ),
      height: height,
      padding: EdgeInsetsDirectional.only(
        start: side,
        end: MeridianSpace.space1,
      ),
      decoration: BoxDecoration(
        color: state == null ? null : faceFill(state),
        borderRadius: faceRadius,
      ),
      child: content,
    );
    final faceTarget = onPressed == null
        ? ExcludeSemantics(child: face(null))
        : Semantics(
            excludeSemantics: true,
            button: true,
            enabled: enabled,
            selected: selected,
            label: label,
            onTap: press,
            child: MeridianInteraction(
              onTap: press,
              borderRadius: faceRadius,
              expandHitTarget: false,
              builder: (context, state) => face(state),
            ),
          );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: onPressed == null ? label : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth + overhang),
        child: SizedBox(
          height: rowHeight,
          child: Stack(
            children: [
              PositionedDirectional(
                start: 0,
                end: overhang,
                top: inset,
                bottom: inset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fill,
                    border: Border.all(color: edge),
                    borderRadius: radius,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: faceTarget),
                  _RemoveButton(
                    label: removeLabel ?? 'Remove $label',
                    color: ink,
                    extent: removeVisual,
                    onPressed: remove,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({
    required this.label,
    required this.color,
    required this.extent,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final double extent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final radius = BorderRadius.circular(meridian.radius.xs);
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: MeridianTooltip(
        message: label,
        excludeFromSemantics: true,
        child: MeridianInteraction(
          onTap: onPressed,
          borderRadius: radius,
          builder: (context, state) => AnimatedContainer(
            duration: meridianHoverDuration(
              context,
              state.hovered || state.pressed,
            ),
            width: extent,
            height: extent,
            decoration: BoxDecoration(
              color: state.fill(
                rest: const Color(0x00000000),
                hoverFill: colors.ink.withValues(
                  alpha: MeridianOpacity.primaryHoverOverlay,
                ),
                ink: colors.ink,
              ),
              borderRadius: radius,
            ),
            alignment: Alignment.center,
            child: MeridianIcon(
              MeridianIcons.x,
              extent: MeridianLayout.chipRemoveIconSize,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Status tones for [MeridianStatusDot].
enum MeridianStatusTone { neutral, accent, success, warning, danger, attention }

/// A 6px state dot with its label: running, synced, offline. Never colour
/// alone: the label always goes with it (or [semanticLabel] when the label is
/// elsewhere in the row).
class MeridianStatusDot extends StatelessWidget {
  const MeridianStatusDot({
    super.key,
    this.tone = MeridianStatusTone.neutral,
    this.label,
    this.semanticLabel,
    this.halo = false,
    this.live = false,
  });

  final MeridianStatusTone tone;
  final String? label;
  final String? semanticLabel;

  /// A soft ring, for a live or running state.
  final bool halo;

  /// Live activity: a halo that grows and fades, looping every
  /// `motion-pulse` (MM-69). Reduce motion holds it still.
  final bool live;

  static Color colorFor(MeridianColors colors, MeridianStatusTone tone) =>
      switch (tone) {
        MeridianStatusTone.neutral => colors.inkFaint,
        MeridianStatusTone.accent => colors.accent,
        MeridianStatusTone.success => colors.success,
        MeridianStatusTone.warning => colors.warning,
        MeridianStatusTone.danger => colors.danger,
        MeridianStatusTone.attention => colors.attention,
      };

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final color = colorFor(meridian.colors, tone);
    final dot = Container(
      width: MeridianLayout.statusDot,
      height: MeridianLayout.statusDot,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: halo
            ? [
                BoxShadow(
                  color: color.withValues(alpha: MeridianOpacity.statusHalo),
                  spreadRadius: MeridianLayout.statusHaloSpread,
                ),
              ]
            : null,
      ),
    );
    final Widget mark = live
        ? MeridianPulse(
            active: true,
            color: color,
            size: MeridianLayout.statusDot,
            child: dot,
          )
        : dot;
    return Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: label == null
          ? mark
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                mark,
                const SizedBox(width: MeridianSpace.space3),
                Flexible(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: meridian.text.caption.copyWith(
                      color: meridian.colors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
