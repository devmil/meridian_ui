import 'package:flutter/widgets.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'selection.dart';

/// One label and value of a [MeridianPropertyList].
@immutable
class MeridianProperty {
  const MeridianProperty({
    required this.label,
    required this.value,
    this.monospace = false,
    this.selectable = true,
    this.maxLines,
  });

  /// What the value is ("Parent PID", "Author"), in sentence case.
  final String label;

  /// The value as text. Say "Unknown" or "-" rather than leaving it empty.
  final String value;

  /// Set identifiers, paths, numbers and commands in `code` so they line up
  /// and read as something to paste.
  final bool monospace;

  /// Let people select and copy the value.
  final bool selectable;

  /// Clamp long values (a command line) to this many lines.
  final int? maxLines;
}

/// A read-only list of labelled values for inspectors and detail islands:
/// a process's parent and user, a commit's author and date, a message's
/// headers.
///
/// Wide layouts put the `caption` label in an `ink-muted` column of
/// [labelWidth] next to the value; narrow ones stack the label above it.
/// Values are selectable so identifiers can be copied.
class MeridianPropertyList extends StatelessWidget {
  const MeridianPropertyList({
    required this.properties,
    super.key,
    this.labelWidth = MeridianLayout.propertyLabelColumn,
  });

  final List<MeridianProperty> properties;

  /// Width of the label column in the side-by-side layout.
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final labelStyle = meridian.text.caption.copyWith(color: colors.inkMuted);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            meridian.density.isTouch ||
            constraints.maxWidth <
                labelWidth * MeridianLayout.propertyStackFactor;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < properties.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  top: i == 0 ? 0 : MeridianSpace.space3,
                ),
                child: _PropertyRow(
                  property: properties[i],
                  stacked: stacked,
                  labelWidth: labelWidth,
                  labelStyle: labelStyle,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({
    required this.property,
    required this.stacked,
    required this.labelWidth,
    required this.labelStyle,
  });

  final MeridianProperty property;
  final bool stacked;
  final double labelWidth;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final style = property.monospace
        ? MeridianTextStyles.numeric(meridian.text.code)
        : meridian.text.body;
    final value = property.selectable
        ? MeridianSelectableText(
            property.value,
            style: style,
            maxLines: property.maxLines,
          )
        : Text(
            property.value,
            style: style,
            maxLines: property.maxLines,
            overflow: property.maxLines == null ? null : TextOverflow.ellipsis,
          );
    final label = Text(property.label, style: labelStyle);
    return MergeSemantics(
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                label,
                const SizedBox(height: MeridianSpace.space1),
                value,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(width: labelWidth, child: label),
                const SizedBox(width: MeridianSpace.space4),
                Expanded(child: value),
              ],
            ),
    );
  }
}

/// Sort directions for [MeridianColumnHeader].
enum MeridianSortDirection { ascending, descending }

/// A column heading of a table: the label, and the sort arrow on the column
/// the table is sorted by. Clicking (or Enter) asks to sort by it; a
/// secondary click opens the column menu ([onContextMenu]), where the table
/// offers show, hide and reset.
///
/// It fills the header cell it is placed in. Put the header row on
/// `pane-alt`; the header hovers with `pane-hover`. Align numeric columns to
/// the end ([alignEnd]) so their headings sit over the numbers.
class MeridianColumnHeader extends StatelessWidget {
  const MeridianColumnHeader({
    required this.label,
    super.key,
    this.sortDirection,
    this.alignEnd = false,
    this.onPressed,
    this.onContextMenu,
    this.sortedAscendingLabel,
    this.sortedDescendingLabel,
  });

  /// The column name ("CPU", "Name"), short and in sentence case.
  final String label;

  /// The direction when the table is sorted by this column; `null` when it
  /// is not.
  final MeridianSortDirection? sortDirection;

  /// Align the label and arrow to the end (numeric columns).
  final bool alignEnd;

  /// Sorts by this column (or reverses the order). `null` makes the header
  /// static.
  final VoidCallback? onPressed;

  /// Opens the column menu at the pointer (global position).
  final ValueChanged<Offset>? onContextMenu;

  /// Announced with the label while sorted ascending ("sorted ascending").
  final String? sortedAscendingLabel;

  /// Announced with the label while sorted descending.
  final String? sortedDescendingLabel;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final sorted = sortDirection != null;
    final style = meridian.text.caption.copyWith(
      color: sorted ? colors.ink : colors.inkMuted,
      fontWeight: sorted ? FontWeight.w600 : null,
    );
    final contextMenu = onContextMenu;
    return Semantics(
      button: onPressed != null,
      label: label,
      value: switch (sortDirection) {
        MeridianSortDirection.ascending => sortedAscendingLabel,
        MeridianSortDirection.descending => sortedDescendingLabel,
        null => null,
      },
      excludeSemantics: true,
      child: MeridianInteraction(
        onTap: onPressed,
        onSecondaryTapUp: contextMenu == null
            ? null
            : (details) => contextMenu(details.globalPosition),
        cursor: onPressed == null ? SystemMouseCursors.basic : null,
        expandHitTarget: false,
        builder: (context, state) => AnimatedContainer(
          duration: meridianHoverDuration(
            context,
            state.hovered || state.pressed,
          ),
          color: state.fill(
            rest: meridianTransparent,
            hoverFill: onPressed == null
                ? meridianClear(colors.paneHover)
                : colors.paneHover,
            ink: colors.ink,
          ),
          padding: const EdgeInsets.symmetric(horizontal: MeridianSpace.space4),
          alignment: alignEnd
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              if (sortDirection case final direction?) ...[
                const SizedBox(width: MeridianSpace.space2),
                MeridianIcon(
                  direction == MeridianSortDirection.ascending
                      ? MeridianIcons.arrowUp
                      : MeridianIcons.arrowDown,
                  extent: MeridianLayout.sortIconSize,
                  color: colors.ink,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
