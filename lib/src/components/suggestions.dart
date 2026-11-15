import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';

/// The floating list under a field that suggests completions (branch
/// names, recipients, tags): `raised`, `radius-xl`, `shadow-float`, at most
/// [maxHeight] tall. The field keeps keyboard focus; it moves the
/// highlight with the arrow keys and accepts with Enter. Put
/// [MeridianSuggestionRow]s and [MeridianSuggestionHeader]s in a scrolling
/// [child].
class MeridianSuggestionSurface extends StatelessWidget {
  const MeridianSuggestionSurface({
    required this.child,
    super.key,
    this.maxHeight = MeridianLayout.suggestionMaxHeight,
  });

  final Widget child;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    // Part of the field's tap region: a click on a suggestion must not take
    // focus (and the caret) from the field it completes.
    return TextFieldTapRegion(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.all(MeridianSpace.space2),
        decoration: BoxDecoration(
          color: meridian.colors.raised,
          borderRadius: BorderRadius.circular(meridian.radius.xl),
          boxShadow: meridian.shadows.shadowFloat,
        ),
        child: MeridianTextScope(child: child),
      ),
    );
  }
}

/// One suggestion: an optional icon, the [label] and a `caption` [hint]
/// (where it comes from, a path). The [highlighted] row is the one Enter
/// accepts; it paints solid `accent`, like a keyboard-highlighted menu row.
/// Suggestions never take focus, so the field keeps the caret.
class MeridianSuggestionRow extends StatelessWidget {
  const MeridianSuggestionRow({
    required this.label,
    required this.onTap,
    super.key,
    this.hint,
    this.icon,
    this.leading,
    this.highlighted = false,
  });

  final String label;
  final String? hint;
  final String? icon;

  /// A picture instead of [icon]: a person's avatar for a recipient.
  final Widget? leading;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final density = meridian.density;
    final radius = BorderRadius.circular(meridian.radius.sm);
    return Semantics(
      button: true,
      selected: highlighted,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: MeridianInteraction(
        onTap: onTap,
        canRequestFocus: false,
        borderRadius: radius,
        expandHitTarget: false,
        builder: (context, state) {
          final fill = highlighted
              ? colors.accent
              : state.fill(
                  rest: meridianClear(colors.paneHover),
                  hoverFill: colors.paneHover,
                  ink: colors.ink,
                );
          return AnimatedContainer(
            duration: meridianHoverDuration(
              context,
              state.hovered || state.pressed,
            ),
            height: density.rowExtent,
            padding: EdgeInsets.symmetric(
              horizontal: density.isTouch
                  ? MeridianSpace.space6
                  : MeridianSpace.space4,
            ),
            decoration: BoxDecoration(color: fill, borderRadius: radius),
            child: Row(
              children: [
                if (leading case final picture?) ...[
                  picture,
                  const SizedBox(width: MeridianSpace.space4),
                ] else if (icon case final icon?) ...[
                  MeridianIcon(
                    icon,
                    color: highlighted ? colors.onAccent : colors.inkMuted,
                  ),
                  const SizedBox(width: MeridianSpace.space4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: meridian.text.body.copyWith(
                      color: highlighted ? colors.onAccent : colors.ink,
                    ),
                  ),
                ),
                if (hint case final hint?) ...[
                  const SizedBox(width: MeridianSpace.space4),
                  Flexible(
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: meridian.text.caption.copyWith(
                        color: highlighted
                            ? colors.onAccentMuted
                            : colors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// An `overline` group title inside a [MeridianSuggestionSurface]
/// ("Local branches", "Tags").
class MeridianSuggestionHeader extends StatelessWidget {
  const MeridianSuggestionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: MeridianSpace.space3,
        start: MeridianSpace.space4,
        end: MeridianSpace.space4,
        bottom: MeridianSpace.space2,
      ),
      child: Semantics(
        header: true,
        child: Text(
          label.toUpperCase(),
          style: meridian.text.overline.copyWith(
            color: meridian.colors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Arrow and Enter bindings for a result list whose search field keeps focus.
/// The owner supplies the selected index and rejects disabled activations.
class MeridianResultNavigation extends StatelessWidget {
  const MeridianResultNavigation({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.onSelected,
    required this.onActivate,
    required this.child,
  });

  final int itemCount;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onActivate;
  final Widget child;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.arrowDown): () {
        if (itemCount > 0) onSelected((selectedIndex + 1) % itemCount);
      },
      const SingleActivator(LogicalKeyboardKey.arrowUp): () {
        if (itemCount > 0) onSelected((selectedIndex - 1) % itemCount);
      },
      const SingleActivator(LogicalKeyboardKey.enter): () {
        if (selectedIndex >= 0 && selectedIndex < itemCount) {
          onActivate(selectedIndex);
        }
      },
    },
    child: child,
  );
}
