import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_motion.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'display.dart';
import 'inputs.dart' show MeridianCheckboxMark;
import 'tooltip.dart';
import '../foundation/meridian_localizations.dart';

/// Reports whether focus is anywhere inside [child] (focus-within), without
/// taking part in traversal itself.
class _FocusWithin extends StatelessWidget {
  const _FocusWithin({required this.onChanged, required this.child});

  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: onChanged,
    child: child,
  );
}

/// The inset list that holds [MeridianListRow]s: `space-3` in from the
/// island edge on every side, so the rounded selection bar never touches it.
///
/// Use [MeridianList.builder] for long or live lists; it builds only the
/// visible rows.
class MeridianList extends StatefulWidget {
  const MeridianList({
    required List<Widget> this.children,
    super.key,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
  }) : itemCount = null,
       itemBuilder = null,
       itemExtent = null,
       selectedIndex = null;

  const MeridianList.builder({
    required int this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
    super.key,
    this.itemExtent,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.selectedIndex,
  }) : children = null;

  final List<Widget>? children;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;

  /// A fixed row height (for example the density's `rowExtent`) lets the
  /// list skip measuring rows.
  final double? itemExtent;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// The selected row. With [itemExtent] the selection bar glides between
  /// rows on `spring-snappy` and scrolls with them; rows paint their
  /// selected fill transparent (MM-20). Longer jumps crossfade.
  final int? selectedIndex;

  @override
  State<MeridianList> createState() => _MeridianListState();
}

class _MeridianListState extends State<MeridianList> {
  ScrollController? _owned;

  ScrollController get _controller =>
      widget.controller ?? (_owned ??= ScrollController());

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.all(MeridianSpace.space3);
    final rows = widget.children;
    if (rows != null) {
      return ListView(
        controller: widget.controller,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        padding: padding,
        children: rows,
      );
    }
    final extent = widget.itemExtent;
    final glide = extent != null && widget.selectedIndex != null;
    final list = ListView.builder(
      controller: glide ? _controller : widget.controller,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: padding,
      itemExtent: extent,
      itemCount: widget.itemCount,
      itemBuilder: widget.itemBuilder!,
    );
    if (!glide) return list;
    return MeridianSelectionGlide(
      controller: _controller,
      itemExtent: extent,
      selectedIndex: widget.selectedIndex,
      padding: padding,
      indicator: const MeridianSelectionFill(),
      child: list,
    );
  }
}

/// The selection bar a [MeridianSelectionGlide] paints under the rows: the
/// same fill a selected [MeridianListRow] paints (`accent` or
/// `accent-soft`), crossfading over `motion-select` when the island or the
/// window gains or loses focus (MM-78).
class MeridianSelectionFill extends StatelessWidget {
  const MeridianSelectionFill({super.key, this.borderRadius});

  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final paint = MeridianRowColors.resolve(
      context,
      selected: true,
      hovered: false,
    );
    return AnimatedContainer(
      duration: MeridianMotion.of(context, MeridianDurations.select),
      curve: MeridianDurations.selectCurve,
      decoration: BoxDecoration(
        color: paint.fill,
        borderRadius: borderRadius ?? BorderRadius.circular(meridian.radius.sm),
      ),
    );
  }
}

/// A row in a list: messages, processes, notebooks, files.
///
/// The selection is an inset rounded bar (`radius-sm`), never full-bleed:
/// solid `accent` when the enclosing island has keyboard focus,
/// `accent-soft` otherwise. [hoverActions] replace [meta] on hover or focus
/// and must also be reachable from the context menu. Put rows in a
/// [MeridianList] for the `space-3` inset.
class MeridianListRow extends StatefulWidget {
  const MeridianListRow({
    required this.title,
    super.key,
    this.leading,
    this.subtitle,
    this.meta,
    this.trailing,
    this.hoverActions = const [],
    this.selected = false,
    this.emphasized = false,
    this.dimmed = false,
    this.enabled = true,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onContextMenu,
    this.twoLine = false,
    this.semanticLabel,
    this.match,
    this.titleTrailing,
    this.semanticValue,
    this.revealKey,
    this.attention = 0,
    this.checked,
  });

  final String title;

  /// An icon, avatar or status glyph.
  final Widget? leading;

  /// Secondary text: inline after the title, or on a second line with
  /// [twoLine].
  final String? subtitle;

  /// Right-aligned metadata text (a date, a size). Gives way to
  /// [hoverActions].
  final String? meta;

  /// A trailing widget (a count, a status dot). Always shown.
  final Widget? trailing;

  /// Small icon buttons revealed on hover or keyboard focus.
  final List<Widget> hoverActions;
  final bool selected;

  /// `body-strong` title: the current item, an unread message.
  final bool emphasized;

  /// Faded (45%): filtered out, ignored, terminated.
  final bool dimmed;

  /// A disabled row fades everything to `ink-faint` and ignores input.
  final bool enabled;

  /// Runs immediately on every tap, also the first of a double tap.
  final VoidCallback? onTap;

  /// Runs on the second tap of a double tap (open, rename). It never delays
  /// [onTap].
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;

  /// Called with the pointer's global position for a secondary click.
  final ValueChanged<Offset>? onContextMenu;

  /// Title and subtitle on two lines (mail lists, touch lists).
  final bool twoLine;
  final String? semanticLabel;

  /// A filter or search query. Its case-insensitive occurrences in [title]
  /// are set in `accent`, bold and underlined (`on-accent` on a solid
  /// selection).
  final String? match;

  /// A small widget right after the title (a count, a check status) that
  /// stays with the title instead of moving to the row's end.
  final Widget? titleTrailing;

  /// The accessible value, for state the title does not say ("Current").
  final String? semanticValue;

  /// A stable identity for a live row. The first time a key is built
  /// (per [MeridianMotionMemory]) the row enters with [MeridianReveal]; a
  /// recycled row does not (MM-22). To animate a removal, keep the row for
  /// a moment in a [MeridianRemovingRow].
  final Object? revealKey;

  /// Increment when the row changed underneath the person; it plays one
  /// `accent-soft` attention tint (MM-23), once per value for [revealKey].
  final int attention;

  /// Makes the row an item of a multi-select checklist ("pick files to
  /// stash"). `null` (the default) draws no checkbox. Otherwise the row
  /// starts with Meridian's checkbox mark, before [leading], drawn with the
  /// visuals and motion of [MeridianCheckbox] and following the row's hover,
  /// press and disabled state. The mark is not a separate focus stop:
  /// a tap, Space or Enter on the row calls [onTap], and the caller toggles
  /// the value. Assistive technology reads the row as a checkbox with this
  /// checked state instead of a button.
  ///
  /// On a solid (focused) [selected] row the mark inverts to `on-accent` so
  /// it stays legible; a checklist usually leaves [selected] off.
  final bool? checked;

  @override
  State<MeridianListRow> createState() => _MeridianListRowState();
}

class _MeridianListRowState extends State<MeridianListRow> {
  var _actionsFocused = false;

  /// First sighting of [MeridianListRow.revealKey]: grow in once.
  bool? _appear;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final key = widget.revealKey;
    _appear ??=
        key != null &&
        !MeridianMotion.reduced(context) &&
        MeridianMotionMemory.of(context).markSeen(('meridian-row', key));
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final text = meridian.text;
    final density = meridian.density;
    final touch = density.isTouch;
    final enabled = widget.enabled;
    final radius = BorderRadius.circular(meridian.radius.sm);
    // Under a selection glide the bar is painted for the row (MM-20).
    final glided = widget.selected && MeridianSelectionGlideScope.of(context);
    final height = widget.twoLine
        ? density.rowExtent +
              (touch
                  ? MeridianLayout.rowTwoLineExtraTouch
                  : MeridianLayout.rowTwoLineExtra)
        : density.rowExtent;
    final tappable = widget.onTap != null || widget.onDoubleTap != null;
    Widget row(MeridianInteractionState state) {
      final paint = MeridianRowColors.resolve(
        context,
        selected: widget.selected,
        hovered: state.hovered || state.pressed,
      );
      final base = glided ? meridianClear(paint.fill) : paint.fill;
      final fill = state.pressed
          ? (glided
                ? colors.ink.withValues(alpha: MeridianOpacity.pressedOverlay)
                : meridianPressed(base, colors.ink))
          : base;
      final primary = enabled ? paint.primary : colors.inkFaint;
      final secondaryInk = enabled ? paint.secondary : colors.inkFaint;
      final iconInk = enabled ? paint.icon : colors.inkFaint;
      final titleStyle = (widget.emphasized ? text.bodyStrong : text.body)
          .copyWith(color: primary);
      final secondary = text.caption.copyWith(color: secondaryInk);
      final showActions =
          enabled &&
          widget.hoverActions.isNotEmpty &&
          (state.hovered || state.focused || _actionsFocused);
      Widget line(String value, TextStyle style) => Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
      Widget titleLine() {
        final query = widget.match?.trim() ?? '';
        final Widget title = query.isEmpty
            ? line(widget.title, titleStyle)
            : Text.rich(
                TextSpan(
                  children: _matchSpans(
                    widget.title,
                    query,
                    titleStyle,
                    text.match(
                      titleStyle,
                      enabled
                          ? (paint.strong ? colors.onAccent : colors.accent)
                          : colors.inkFaint,
                    ),
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
        final extra = widget.titleTrailing;
        if (extra == null) return title;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: title),
            const SizedBox(width: MeridianSpace.space2),
            IconTheme.merge(
              data: IconThemeData(color: iconInk),
              child: DefaultTextStyle.merge(style: secondary, child: extra),
            ),
          ],
        );
      }

      // Only the fill animates: the height snaps, so two-line content never
      // sits in a one-line row mid-transition. The row keeps its density
      // height and grows only when large text needs more.
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: AnimatedContainer(
          duration: state.hovered || state.pressed
              ? meridianHoverDuration(context, true)
              : MeridianMotion.of(context, MeridianDurations.select),
          padding: EdgeInsets.symmetric(
            horizontal: touch ? MeridianSpace.space6 : MeridianSpace.space4,
            vertical: MeridianSpace.space1,
          ),
          decoration: BoxDecoration(color: fill, borderRadius: radius),
          child: Opacity(
            opacity: widget.dimmed ? MeridianOpacity.dimmedRow : 1,
            child: _RowContent(
              child: Row(
                children: [
                  if (widget.checked case final checked?) ...[
                    MeridianCheckboxMark(
                      checked: checked,
                      enabled: enabled,
                      state: state,
                      onAccent: paint.strong,
                    ),
                    const SizedBox(width: MeridianSpace.space4),
                  ],
                  if (widget.leading case final leading?) ...[
                    IconTheme.merge(
                      data: IconThemeData(color: iconInk),
                      child: leading,
                    ),
                    SizedBox(
                      width: touch
                          ? MeridianSpace.space5
                          : MeridianSpace.space4,
                    ),
                  ],
                  Expanded(
                    child: widget.twoLine
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              titleLine(),
                              if (widget.subtitle case final subtitle?)
                                line(subtitle, secondary),
                            ],
                          )
                        : switch (widget.subtitle) {
                            // The title keeps its natural width; the
                            // subtitle takes what is left and gives way
                            // first.
                            final subtitle? => _TitleFirstLine(
                              gap: MeridianSpace.space4,
                              subtitleStyle: secondary,
                              textScaler: MediaQuery.textScalerOf(context),
                              title: titleLine(),
                              subtitle: line(subtitle, secondary),
                            ),
                            null => Row(
                              children: [Flexible(child: titleLine())],
                            ),
                          },
                  ),
                  if (widget.hoverActions.isNotEmpty || widget.meta != null)
                    _HoverSlot(
                      showActions: showActions || _actionsFocused,
                      actions: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: MeridianSpace.space3,
                        ),
                        // Stays mounted while focus is inside, so Tab can
                        // walk the actions without them vanishing under it.
                        child: _FocusWithin(
                          onChanged: (value) {
                            if (_actionsFocused != value) {
                              setState(() => _actionsFocused = value);
                            }
                          },
                          child: MeridianSurfaceScope(
                            onGround:
                                MeridianSurfaceScope.maybeOf(context)
                                    ?.onGround ??
                                false,
                            fill: fill,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.hoverActions,
                            ),
                          ),
                        ),
                      ),
                      meta: switch (widget.meta) {
                        final meta? => Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: MeridianSpace.space4,
                          ),
                          child: Text(
                            meta,
                            style: MeridianTextStyles.numeric(secondary),
                          ),
                        ),
                        null => null,
                      },
                    ),
                  if (widget.trailing case final trailing?) ...[
                    const SizedBox(width: MeridianSpace.space4),
                    MeridianSurfaceScope.withFill(
                      context,
                      fill: fill,
                      child: IconTheme.merge(
                        data: IconThemeData(color: iconInk),
                        child: DefaultTextStyle.merge(
                          style: secondary,
                          child: trailing,
                        ),
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

    final contextMenu = widget.onContextMenu;
    Widget result = Semantics(
      excludeSemantics: true,
      button: widget.checked == null && widget.onTap != null,
      checked: widget.checked,
      enabled: enabled,
      selected: widget.selected,
      value: widget.semanticValue,
      label:
          widget.semanticLabel ??
          [
            widget.title,
            widget.subtitle,
            widget.meta,
          ].whereType<String>().join(', '),
      onTap: enabled ? widget.onTap : null,
      onLongPress: enabled ? widget.onLongPress : null,
      // A tint when the row changed underneath the person (MM-23).
      child: MeridianAttention(
        trigger: widget.attention,
        memoryKey: widget.revealKey ?? widget.key,
        borderRadius: radius,
        child: MeridianInteraction(
          onTap: enabled && tappable ? widget.onTap : null,
          onDoubleTap: enabled ? widget.onDoubleTap : null,
          onLongPress: enabled ? widget.onLongPress : null,
          onSecondaryTapUp: enabled && contextMenu != null
              ? (details) => contextMenu(details.globalPosition)
              : null,
          borderRadius: radius,
          expandHitTarget: false,
          builder: (context, state) => row(state),
        ),
      ),
    );
    if (widget.revealKey != null) {
      result = MeridianReveal(
        visible: true,
        appear: _appear ?? false,
        child: result,
      );
    }
    return result;
  }
}

/// The trailing slot of a [MeridianListRow] (MM-21): hover actions fade in
/// and slide `rise-overlay` px from the trailing edge over `motion-quick`,
/// replacing the meta text; when they go, the meta returns and the actions
/// fade out over `motion-exit` on top of it. Reduce motion: fade only.
class _HoverSlot extends StatefulWidget {
  const _HoverSlot({
    required this.showActions,
    required this.actions,
    required this.meta,
  });

  final bool showActions;
  final Widget actions;
  final Widget? meta;

  @override
  State<_HoverSlot> createState() => _HoverSlotState();
}

class _HoverSlotState extends State<_HoverSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shown = AnimationController(
    vsync: this,
    value: widget.showActions ? 1 : 0,
  );

  @override
  void didUpdateWidget(_HoverSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showActions == oldWidget.showActions) return;
    if (widget.showActions) {
      _shown.animateTo(
        1,
        duration: MeridianMotion.fade(context, MeridianDurations.quick),
        curve: MeridianDurations.quickCurve,
      );
    } else {
      _shown.animateBack(
        0,
        duration: MeridianMotion.fade(context, MeridianDurations.exit),
        curve: MeridianDurations.exitCurve,
      );
    }
  }

  @override
  void dispose() {
    _shown.dispose();
    super.dispose();
  }

  Widget _animated(Widget child) {
    final reduced = MeridianMotion.reduced(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: _shown,
      child: child,
      builder: (context, child) {
        final t = _shown.value;
        final entering = widget.showActions && !reduced;
        final dx = entering
            ? MeridianMotionScales.riseOverlay * (1 - t) * (rtl ? -1 : 1)
            : 0.0;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showActions) return _animated(widget.actions);
    final meta = widget.meta ?? const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _shown,
      builder: (context, _) => _shown.value <= 0
          ? meta
          : Stack(
              alignment: AlignmentDirectional.centerEnd,
              children: [
                meta,
                IgnorePointer(
                  child: ExcludeSemantics(child: _animated(widget.actions)),
                ),
              ],
            ),
    );
  }
}

/// A section of a navigation sidebar: an `overline` title with an optional
/// count and an action revealed on hover or focus (always on touch), then
/// its rows.
class MeridianNavSection extends StatefulWidget {
  const MeridianNavSection({
    required this.title,
    required this.children,
    super.key,
    this.count,
    this.action,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  final String title;
  final List<Widget> children;
  final int? count;

  /// A small icon button (for example "New folder"), shown on hover.
  final Widget? action;
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  State<MeridianNavSection> createState() => _MeridianNavSectionState();
}

class _MeridianNavSectionState extends State<MeridianNavSection> {
  late bool _expanded = widget.initiallyExpanded;
  var _hovered = false;
  var _actionFocused = false;

  /// Counts expansions, so each one staggers its rows in again (MM-24).
  var _expansions = 0;

  void _toggle() => setState(() {
    _expanded = !_expanded;
    if (_expanded) _expansions++;
  });

  void _setHovered(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final density = meridian.density;
    final touch = density.isTouch;
    final radius = BorderRadius.circular(meridian.radius.sm);
    final onGround = MeridianSurfaceScope.maybeOf(context)?.onGround ?? true;
    final height = math.max(MeridianLayout.navSectionHeight, density.minTarget);
    Widget header(MeridianInteractionState? state) {
      final showAction =
          touch || _hovered || _actionFocused || (state?.focused ?? false);
      return AnimatedContainer(
        duration: meridianHoverDuration(
          context,
          _hovered || (state?.pressed ?? false),
        ),
        height: height,
        padding: EdgeInsets.symmetric(
          horizontal: touch ? MeridianSpace.space6 : MeridianSpace.space4,
        ),
        decoration: BoxDecoration(
          color: state?.fill(
            rest: meridianTransparent,
            hoverFill: onGround ? colors.groundHover : colors.paneHover,
            ink: colors.ink,
          ),
          borderRadius: radius,
        ),
        child: Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                excluding: widget.collapsible,
                child: Semantics(
                  header: true,
                  child: Text(
                    widget.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: meridian.text.overline.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.action case final action?)
              // Focusable only where it can be seen: focus reveals it.
              _FocusWithin(
                onChanged: (value) {
                  if (_actionFocused != value) {
                    setState(() => _actionFocused = value);
                  }
                },
                child: IgnorePointer(
                  ignoring: !showAction,
                  child: Opacity(
                    opacity: showAction ? 1 : 0,
                    alwaysIncludeSemantics: true,
                    child: Semantics(
                      container: true,
                      child: MeridianSurfaceScope.withFill(
                        context,
                        fill: state?.fill(
                          rest: meridianTransparent,
                          hoverFill: onGround
                              ? colors.groundHover
                              : colors.paneHover,
                          ink: colors.ink,
                        ),
                        child: action,
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.count case final count?) ...[
              const SizedBox(width: MeridianSpace.space2),
              ExcludeSemantics(
                excluding: widget.collapsible,
                child: MeridianCount(
                  label: '$count',
                  tone: MeridianCountTone.quiet,
                ),
              ),
            ],
            if (widget.collapsible) ...[
              const SizedBox(width: MeridianSpace.space2),
              // The chevron turns to point down (MM-24).
              MeridianTurns(
                turns: _expanded ? _expandedTurns(context) : 0,
                child: MeridianIcon(
                  _collapsedChevron(context),
                  extent: MeridianLayout.chevronSize,
                  color: colors.inkMuted,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final Widget title;
    if (widget.collapsible) {
      title = Semantics(
        container: true,
        header: true,
        button: true,
        expanded: _expanded,
        label: widget.count == null
            ? widget.title
            : '${widget.title}, ${widget.count}',
        onTap: _toggle,
        onExpand: _expanded ? null : _toggle,
        onCollapse: _expanded ? _toggle : null,
        child: MeridianInteraction(
          onTap: _toggle,
          borderRadius: radius,
          expandHitTarget: false,
          builder: (context, state) => header(state),
        ),
      );
    } else {
      title = header(null);
    }
    return Padding(
      padding: const EdgeInsets.only(top: MeridianSpace.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            onEnter: (_) => _setHovered(true),
            onExit: (_) => _setHovered(false),
            child: title,
          ),
          // Rows reveal, the first ones staggered, on each expansion; the
          // current mark travels between rows (MM-24, MM-25).
          MeridianReveal(
            visible: _expanded,
            child: MeridianGlide.custom(
              selection: null,
              foreground: true,
              indicator: Align(
                alignment: Alignment.center,
                child: MeridianIcon(
                  MeridianIcons.check,
                  size: MeridianIconSize.small,
                  color: colors.accentInk,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.children.length; i++)
                    if (_expansions > 0 && i < MeridianMotionScales.staggerMax)
                      MeridianEntrance(
                        entranceKey: (this, _expansions, i),
                        index: i,
                        child: widget.children[i],
                      )
                    else
                      widget.children[i],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What a drop target shows while something is dragged over it.
enum MeridianDropFeedback {
  /// Nothing is dragged over it.
  none,

  /// The dragged items can go here: `accent-soft` with an `accent` edge.
  accept,

  /// The dragged items cannot go here: the row fades to `ink-faint`.
  reject,
}

/// A row of a navigation sidebar (folders, labels, views, branches). Sits on
/// `ground`: hover is `ground-hover`, the active row `accent-soft` (solid
/// `accent` while the sidebar has keyboard focus). [current] marks where the
/// person is (a check mark and `body-strong`).
class MeridianNavRow extends StatelessWidget {
  const MeridianNavRow({
    required this.label,
    super.key,
    this.icon,
    this.iconColor,
    this.leading,
    this.count,
    this.countTone = MeridianCountTone.quiet,
    this.trailing,
    this.depth = 0,
    this.expandable = false,
    this.expanded = false,
    this.onToggleExpanded,
    this.selected = false,
    this.current = false,
    this.onTap,
    this.onContextMenu,
    this.enabled = true,
    this.drop = MeridianDropFeedback.none,
  });

  final String label;
  final String? icon;

  /// Icon tint, for example a label's `series` colour.
  final Color? iconColor;

  /// A picture in the icon slot instead of [icon]: an app's own icon, an
  /// avatar. Keep it to the small icon size of the density.
  final Widget? leading;
  final int? count;
  final MeridianCountTone countTone;
  final Widget? trailing;

  /// Tree depth; each level indents 14px.
  final int depth;
  final bool expandable;
  final bool expanded;
  final VoidCallback? onToggleExpanded;
  final bool selected;
  final bool current;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onContextMenu;

  /// A disabled row fades to `ink-faint` and ignores input.
  final bool enabled;

  /// Feedback while something is dragged over the row (moving mail to a
  /// folder, a file to a location). The app owns the drag target.
  final MeridianDropFeedback drop;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final text = meridian.text;
    final density = meridian.density;
    final touch = density.isTouch;
    final radius = BorderRadius.circular(meridian.radius.sm);
    final toggle = enabled && expandable ? onToggleExpanded : null;
    final accept = drop == MeridianDropFeedback.accept;
    final reject = drop == MeridianDropFeedback.reject;
    final contextMenu = onContextMenu;
    // The chevron is its own target; its slot also indents leaf rows so
    // labels line up.
    final slot = math.max(MeridianLayout.navChevronTarget, density.minTarget);
    final slotInset = (slot - MeridianLayout.chevronSize) / 2;
    final edge = touch ? MeridianSpace.space6 : MeridianSpace.space4;
    final hasSlot = expandable || depth > 0;
    final localizations = MeridianLocalizations.of(context);
    return Semantics(
      excludeSemantics: true,
      button: true,
      enabled: enabled,
      selected: selected,
      expanded: expandable ? expanded : null,
      label: count == null ? label : '$label, $count',
      onTap: enabled ? onTap : null,
      onExpand: toggle != null && !expanded ? toggle : null,
      onCollapse: toggle != null && expanded ? toggle : null,
      child: Shortcuts(
        shortcuts: {
          if (toggle != null) ...{
            const SingleActivator(LogicalKeyboardKey.arrowRight):
                const _ToggleIntent(true),
            const SingleActivator(LogicalKeyboardKey.arrowLeft):
                const _ToggleIntent(false),
          },
        },
        child: Actions(
          actions: {
            _ToggleIntent: CallbackAction<_ToggleIntent>(
              onInvoke: (intent) {
                if (intent.open != expanded) toggle?.call();
                return null;
              },
            ),
          },
          child: MeridianInteraction(
            onTap: enabled ? onTap : null,
            onSecondaryTapUp: enabled && contextMenu != null
                ? (d) => contextMenu(d.globalPosition)
                : null,
            borderRadius: radius,
            expandHitTarget: false,
            builder: (context, state) {
              final paint = MeridianRowColors.resolve(
                context,
                selected: selected,
                hovered: state.hovered || state.pressed,
                onGround:
                    MeridianSurfaceScope.maybeOf(context)?.onGround ?? true,
              );
              final fill = accept
                  ? colors.accentSoft
                  : state.pressed
                  ? meridianPressed(paint.fill, colors.ink)
                  : paint.fill;
              final faded = !enabled || reject;
              final primary = faded
                  ? colors.inkFaint
                  : accept
                  ? colors.accentInk
                  : paint.primary;
              final secondary = faded ? colors.inkFaint : paint.secondary;
              final iconInk = faded
                  ? colors.inkFaint
                  : accept
                  ? colors.accentInk
                  : paint.strong
                  ? paint.icon
                  : current
                  ? colors.accentInk
                  : iconColor ?? paint.icon;
              // The density height, grown only when large text needs it.
              return ConstrainedBox(
                constraints: BoxConstraints(minHeight: density.rowExtent),
                child: AnimatedContainer(
                  duration: MeridianMotion.of(
                    context,
                    MeridianDurations.select,
                  ),
                  padding: EdgeInsetsDirectional.only(
                    start:
                        (hasSlot ? math.max(0.0, edge - slotInset) : edge) +
                        depth * MeridianLayout.treeIndent,
                    end: edge,
                  ),
                  decoration: BoxDecoration(color: fill, borderRadius: radius),
                  // Painted over the row so the edge takes no layout space.
                  foregroundDecoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: accept
                          ? colors.accent
                          : meridianClear(colors.accent),
                    ),
                  ),
                  child: _RowContent(
                    child: Row(
                      children: [
                        if (expandable)
                          _Chevron(
                            expanded: expanded,
                            onPressed: toggle,
                            rowFill: fill,
                            color: secondary,
                            label: expanded
                                ? localizations.collapse
                                : localizations.expand,
                          )
                        else if (depth > 0)
                          SizedBox(width: slot),
                        if (leading case final picture?) ...[
                          picture,
                          const SizedBox(width: MeridianSpace.space3),
                        ] else if (icon case final name?) ...[
                          MeridianIcon(
                            name,
                            size: MeridianIconSize.small,
                            color: iconInk,
                          ),
                          const SizedBox(width: MeridianSpace.space3),
                        ],
                        Expanded(
                          // The weight crossfades when the row becomes
                          // current (MM-25).
                          child: TweenAnimationBuilder<TextStyle>(
                            tween: TextStyleTween(
                              end: (current ? text.bodyStrong : text.body)
                                  .copyWith(color: primary),
                            ),
                            duration: MeridianMotion.of(
                              context,
                              MeridianDurations.select,
                            ),
                            curve: MeridianDurations.selectCurve,
                            builder: (context, style, _) => Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: style,
                            ),
                          ),
                        ),
                        if (current) ...[
                          const SizedBox(width: MeridianSpace.space2),
                          // In a section the check travels here from the
                          // previous current row.
                          MeridianGlideTarget(
                            selected: true,
                            child: MeridianIcon(
                              MeridianIcons.check,
                              size: MeridianIconSize.small,
                              color: !enabled
                                  ? colors.inkFaint
                                  : paint.strong
                                  ? paint.icon
                                  : colors.accentInk,
                            ),
                          ),
                        ],
                        if (trailing case final widget?) ...[
                          const SizedBox(width: MeridianSpace.space3),
                          DefaultTextStyle.merge(
                            style: text.caption.copyWith(color: secondary),
                            child: widget,
                          ),
                        ],
                        if (count case final value?) ...[
                          const SizedBox(width: MeridianSpace.space3),
                          (paint.strong &&
                                      countTone == MeridianCountTone.quiet) ||
                                  !enabled
                              ? Text(
                                  '$value',
                                  style: MeridianTextStyles.numeric(
                                    text.caption.copyWith(color: secondary),
                                  ),
                                )
                              : MeridianCount(label: '$value', tone: countTone),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The expand/collapse chevron of a tree row: its own focusable target, at
/// least 48px at touch density.
class _Chevron extends StatelessWidget {
  const _Chevron({
    required this.expanded,
    required this.onPressed,
    required this.rowFill,
    required this.color,
    required this.label,
  });

  final bool expanded;
  final VoidCallback? onPressed;
  final Color rowFill;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final radius = BorderRadius.circular(meridian.radius.xs);
    return MeridianTooltip(
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
          width: MeridianLayout.navChevronTarget,
          height: MeridianLayout.navChevronTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: state.fill(
              rest: meridianTransparent,
              hoverFill: meridianPressed(rowFill, meridian.colors.ink),
              ink: meridian.colors.ink,
            ),
            borderRadius: radius,
          ),
          child: MeridianIcon(
            expanded ? MeridianIcons.chevronDown : _collapsedChevron(context),
            extent: MeridianLayout.chevronSize,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// How far a collapsed chevron turns to point down.
double _expandedTurns(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl ? -0.25 : 0.25;

/// A collapsed chevron points along the reading direction.
String _collapsedChevron(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
    ? MeridianIcons.chevronLeft
    : MeridianIcons.chevronRight;

class _ToggleIntent extends Intent {
  const _ToggleIntent(this.open);

  final bool open;
}

/// One tab of a [MeridianTabs].
@immutable
class MeridianTab {
  const MeridianTab({
    required this.label,
    this.icon,
    this.count,
    this.dirty = false,
    this.enabled = true,
    this.semanticLabel,
  });

  final String label;
  final String? icon;
  final int? count;

  /// A 6px `warning` dot for unsaved changes.
  final bool dirty;

  /// A disabled tab is shown in `ink-faint` and skipped by the arrow keys.
  final bool enabled;

  /// Overrides the announced name. By default the label, count and dirty
  /// state are read together ("Drafts, 3, unsaved changes").
  final String? semanticLabel;
}

/// Tab styles. [underline] switches views inside an island (a 2px `accent`
/// rule slides under the active tab). [pill] switches documents on `ground`
/// (the active tab is a `pane` pill that reads as the top of the island
/// below).
enum MeridianTabsStyle { underline, pill }

/// A row of tabs. Arrow keys, Home and End move the selection and focus
/// together; disabled tabs are skipped.
class MeridianTabs extends StatefulWidget {
  const MeridianTabs({
    required this.tabs,
    required this.index,
    required this.onChanged,
    super.key,
    this.style = MeridianTabsStyle.underline,
    this.onClose,
    this.closeLabel,
    this.scrollable = true,
    this.dirtyLabel,
    this.tabKeys,
  });

  final List<MeridianTab> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  final MeridianTabsStyle style;

  /// Pill tabs only: shows a close button on hover, on focus and on the
  /// active tab.
  final ValueChanged<int>? onClose;
  final String Function(String tab)? closeLabel;
  final bool scrollable;

  /// How a dirty tab is announced; defaults to "unsaved changes".
  final String? dirtyLabel;

  /// A stable identity per tab (a document id), parallel to [tabs]. A new
  /// key grows its tab in from zero width; a missing one fades its tab out
  /// and collapses it (MM-27). Without keys the labels identify the tabs.
  final List<Object>? tabKeys;

  @override
  State<MeridianTabs> createState() => _MeridianTabsState();
}

class _MeridianTabsState extends State<MeridianTabs> {
  final List<GlobalKey> _keys = [];
  final List<FocusNode> _nodes = [];
  final Set<int> _closeFocused = {};

  /// Tabs opened since the last frame: they grow in (MM-27).
  final Set<Object> _opening = {};

  /// Closed tabs still fading and collapsing, with where they stood.
  final List<(Object, MeridianTab, int)> _closing = [];

  List<Object> _identities(MeridianTabs tabs) =>
      tabs.tabKeys ?? [for (final tab in tabs.tabs) tab.label];

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant MeridianTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
    final before = _identities(oldWidget);
    final after = _identities(widget);
    if (MeridianMotion.reduced(context)) return;
    final added = after.toSet().difference(before.toSet());
    _opening.addAll(added);
    for (var i = 0; i < before.length; i++) {
      final key = before[i];
      if (after.contains(key) || i >= oldWidget.tabs.length) continue;
      _closing
        ..removeWhere((ghost) => ghost.$1 == key)
        ..add((key, oldWidget.tabs[i], i));
    }
    if (_opening.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _opening.clear());
    }
  }

  void _sync() {
    final length = widget.tabs.length;
    while (_keys.length < length) {
      _keys.add(GlobalKey());
      _nodes.add(FocusNode(debugLabel: 'meridian-tab-${_nodes.length}'));
    }
    if (_keys.length > length) {
      _keys.removeRange(length, _keys.length);
      for (final node in _nodes.sublist(length)) {
        node.dispose();
      }
      _nodes.removeRange(length, _nodes.length);
      _closeFocused.removeWhere((i) => i >= length);
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// The next enabled tab from [from] in [delta]'s direction.
  int? _step(int from, int delta) {
    final length = widget.tabs.length;
    for (var k = 1; k <= length; k++) {
      final i = (from + delta * k) % length;
      if (widget.tabs[i].enabled) return i;
    }
    return null;
  }

  void _select(int i, {bool focus = false}) {
    if (i != widget.index) widget.onChanged(i);
    if (!focus) return;
    _nodes[i].requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tabContext = _keys[i].currentContext;
      if (!mounted || tabContext == null) return;
      if (Scrollable.maybeOf(tabContext) == null) return;
      Scrollable.ensureVisible(
        tabContext,
        duration: MeridianMotion.of(context, MeridianDurations.select),
        alignment: 0.5,
      );
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final length = widget.tabs.length;
    if (length == 0) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final from = widget.index.clamp(0, length - 1);
    final int? target = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => _step(from, rtl ? -1 : 1),
      LogicalKeyboardKey.arrowLeft => _step(from, rtl ? 1 : -1),
      LogicalKeyboardKey.home => _step(length - 1, 1),
      LogicalKeyboardKey.end => _step(0, -1),
      _ => -1,
    };
    if (target == -1) return KeyEventResult.ignored;
    if (target != null) _select(target, focus: true);
    return KeyEventResult.handled;
  }

  String _semanticLabel(MeridianTab tab) =>
      tab.semanticLabel ??
      [
        tab.label,
        if (tab.count case final count?) '$count',
        if (tab.dirty) widget.dirtyLabel ?? 'unsaved changes',
      ].join(', ');

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final underline = widget.style == MeridianTabsStyle.underline;
    final identities = _identities(widget);
    final children = <Widget>[
      for (var i = 0; i < widget.tabs.length; i++)
        KeyedSubtree(
          key: ValueKey(('tab', identities[i])),
          child: MeridianReveal(
            visible: true,
            appear: _opening.contains(identities[i]),
            axis: Axis.horizontal,
            child: KeyedSubtree(key: _keys[i], child: _tab(context, i)),
          ),
        ),
    ];
    for (final (key, tab, index) in _closing) {
      children.insert(
        index.clamp(0, children.length),
        KeyedSubtree(
          key: ValueKey(('closing', key)),
          child: MeridianRemovingRow(
            axis: Axis.horizontal,
            onRemoved: () {
              if (mounted) {
                setState(() => _closing.removeWhere((g) => g.$1 == key));
              }
            },
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: ExcludeFocus(child: _tab(context, -1, ghost: tab)),
              ),
            ),
          ),
        ),
      );
    }
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: underline ? 0 : MeridianSpace.space2,
      children: children,
    );
    // The rule or the active pill glides between tabs (MM-26).
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: underline ? 0 : MeridianSpace.space3,
      ),
      child: MeridianGlide.custom(
        selection: widget.index,
        indicator: underline
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MeridianSpace.space4,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: MeridianLayout.tabRuleHeight,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(
                          MeridianRadiusScale.pill,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.pane,
                  borderRadius: BorderRadius.circular(meridian.radius.md),
                  boxShadow: meridian.shadows.shadowPane,
                ),
              ),
        child: row,
      ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Focus(
        skipTraversal: true,
        canRequestFocus: false,
        onKeyEvent: _onKey,
        child: SizedBox(
          height: underline
              ? meridian.density.controlExtent + MeridianSpace.space3
              : MeridianLayout.tabStripHeight,
          child: widget.scrollable
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: content,
                )
              : content,
        ),
      ),
    );
  }

  /// The tab at [i], or the closing [ghost] (painted, never interactive).
  Widget _tab(BuildContext context, int i, {MeridianTab? ghost}) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final text = meridian.text;
    final tab = ghost ?? widget.tabs[i];
    final active = ghost == null && i == widget.index;
    final enabled = tab.enabled;
    final underline = widget.style == MeridianTabsStyle.underline;
    final radius = BorderRadius.circular(meridian.radius.md);
    final select = enabled && ghost == null ? () => _select(i) : null;
    final close = ghost == null ? widget.onClose : null;
    return Semantics(
      container: true,
      selected: active,
      button: true,
      enabled: enabled,
      label: _semanticLabel(tab),
      onTap: select,
      child: MeridianInteraction(
        onTap: select,
        focusNode: ghost == null ? _nodes[i] : null,
        borderRadius: radius,
        expandHitTarget: false,
        builder: (context, state) {
          final ink = !enabled
              ? colors.inkFaint
              : active || state.hovered || state.pressed
              ? colors.ink
              : colors.inkMuted;
          final showClose =
              active ||
              state.hovered ||
              state.focused ||
              (ghost == null && _closeFocused.contains(i));
          final body = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tab.icon case final icon?) ...[
                      MeridianIcon(
                        icon,
                        size: MeridianIconSize.small,
                        color: ink,
                      ),
                      const SizedBox(width: MeridianSpace.space3),
                    ],
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: MeridianLayout.tabLabelMaxWidth,
                      ),
                      child: Text(
                        tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (underline && active
                                    ? text.label.copyWith(
                                        fontWeight: FontWeight.w600,
                                      )
                                    : text.label)
                                .copyWith(color: ink),
                      ),
                    ),
                    if (tab.dirty) ...[
                      const SizedBox(width: MeridianSpace.space3),
                      Container(
                        width: MeridianLayout.statusDot,
                        height: MeridianLayout.statusDot,
                        decoration: BoxDecoration(
                          color: colors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    if (tab.count case final count?) ...[
                      const SizedBox(width: MeridianSpace.space3),
                      MeridianCount(label: '$count'),
                    ],
                  ],
                ),
              ),
              if (!underline && close != null) ...[
                const SizedBox(width: MeridianSpace.space2),
                _FocusWithin(
                  onChanged: (value) => setState(() {
                    value ? _closeFocused.add(i) : _closeFocused.remove(i);
                  }),
                  // Hidden close buttons take no pointer or focus; screen
                  // readers still find them.
                  child: IgnorePointer(
                    ignoring: !showClose,
                    child: ExcludeFocus(
                      excluding: !showClose,
                      child: Opacity(
                        opacity: showClose ? 1 : 0,
                        alwaysIncludeSemantics: true,
                        child: _TabClose(
                          label:
                              widget.closeLabel?.call(tab.label) ??
                              'Close ${tab.label}',
                          onPressed: () => close(i),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
          if (underline) {
            return MeridianGlideTarget(
              selected: active,
              child: Container(
                height: meridian.density.controlExtent + MeridianSpace.space3,
                padding: const EdgeInsets.symmetric(
                  horizontal: MeridianSpace.space4,
                ),
                alignment: Alignment.center,
                child: body,
              ),
            );
          }
          return Center(
            child: MeridianGlideTarget(
              selected: active,
              child: AnimatedContainer(
                duration: meridianHoverDuration(
                  context,
                  state.hovered || state.pressed,
                ),
                height: MeridianLayout.tabPillHeight,
                constraints: const BoxConstraints(
                  minWidth: MeridianLayout.tabPillMinWidth,
                ),
                padding: const EdgeInsetsDirectional.only(
                  start: MeridianSpace.space4,
                  end: MeridianSpace.space3,
                ),
                // The active pill is the glide's indicator; the tab paints
                // only its hover and pressed fills.
                decoration: BoxDecoration(
                  color: active
                      ? (state.pressed
                            ? colors.ink.withValues(
                                alpha: MeridianOpacity.pressedOverlay,
                              )
                            : meridianClear(colors.groundHover))
                      : state.fill(
                          rest: meridianClear(colors.groundHover),
                          hoverFill: colors.groundHover,
                          ink: colors.ink,
                        ),
                  borderRadius: radius,
                ),
                alignment: AlignmentDirectional.centerStart,
                child: body,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabClose extends StatelessWidget {
  const _TabClose({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final radius = BorderRadius.circular(meridian.radius.xs);
    return Semantics(
      container: true,
      button: true,
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
            width: MeridianLayout.tabCloseSize,
            height: MeridianLayout.tabCloseSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: state.fill(
                rest: meridianTransparent,
                hoverFill: colors.ink.withValues(
                  alpha: MeridianOpacity.primaryHoverOverlay,
                ),
                ink: colors.ink,
              ),
              borderRadius: radius,
            ),
            child: MeridianIcon(
              MeridianIcons.x,
              extent: MeridianLayout.tabCloseIconSize,
              color: state.hovered || state.pressed
                  ? colors.ink
                  : colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// [text] split into spans with the case-insensitive occurrences of [query]
/// in [matchStyle].
List<InlineSpan> _matchSpans(
  String text,
  String query,
  TextStyle style,
  TextStyle matchStyle,
) {
  final lowerText = text.toLowerCase();
  final lowerQuery = query.toLowerCase();
  // Lower-casing can change the length (İ); then offsets would not line up.
  if (lowerText.length != text.length || lowerQuery.length != query.length) {
    return [TextSpan(text: text, style: style)];
  }
  final spans = <InlineSpan>[];
  var offset = 0;
  while (offset < text.length) {
    final index = lowerText.indexOf(lowerQuery, offset);
    if (index < 0) break;
    if (index > offset) {
      spans.add(TextSpan(text: text.substring(offset, index), style: style));
    }
    spans.add(
      TextSpan(
        text: text.substring(index, index + query.length),
        style: matchStyle,
      ),
    );
    offset = index + query.length;
  }
  if (offset < text.length) {
    spans.add(TextSpan(text: text.substring(offset), style: style));
  }
  return spans;
}

/// Centres a row's content vertically in the row's minimum height without
/// stretching the row to the height it is offered.
class _RowContent extends StatelessWidget {
  const _RowContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    heightFactor: 1,
    child: child,
  );
}

/// A one-line row's title and inline subtitle, the title first.
///
/// The title keeps its natural width up to the line's width less [gap] and
/// a subtitle ellipsis (`…` in [subtitleStyle], or the whole subtitle when
/// it is narrower); the subtitle takes the rest and truncates first. When
/// the line cannot hold even that, the title takes the whole width and the
/// subtitle is not shown.
class _TitleFirstLine extends MultiChildRenderObjectWidget {
  _TitleFirstLine({
    required this.gap,
    required this.subtitleStyle,
    required this.textScaler,
    required Widget title,
    required Widget subtitle,
  }) : super(children: [title, subtitle]);

  final double gap;
  final TextStyle subtitleStyle;
  final TextScaler textScaler;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTitleFirstLine(
        gap: gap,
        subtitleStyle: subtitleStyle,
        textScaler: textScaler,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTitleFirstLine renderObject,
  ) {
    renderObject
      ..gap = gap
      ..subtitleStyle = subtitleStyle
      ..textScaler = textScaler
      ..textDirection = Directionality.of(context);
  }
}

class _TitleFirstParentData extends ContainerBoxParentData<RenderBox> {}

/// The widths [_RenderTitleFirstLine] gives its children.
typedef _TitleFirstPlan = ({double title, double? subtitle});

class _RenderTitleFirstLine extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TitleFirstParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TitleFirstParentData> {
  _RenderTitleFirstLine({
    required this._gap,
    required this._subtitleStyle,
    required this._textScaler,
    required this._textDirection,
  });

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  TextStyle _subtitleStyle;
  set subtitleStyle(TextStyle value) {
    if (value == _subtitleStyle) return;
    _subtitleStyle = value;
    _ellipsis = null;
    markNeedsLayout();
  }

  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (value == _textScaler) return;
    _textScaler = value;
    _ellipsis = null;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    _ellipsis = null;
    markNeedsLayout();
  }

  /// Whether the last layout showed the subtitle.
  var _subtitleShown = true;

  double? _ellipsis;

  /// The width of `…` in the subtitle's style.
  double get _ellipsisWidth => _ellipsis ??= () {
    final painter = TextPainter(
      text: TextSpan(text: '…', style: _subtitleStyle),
      textDirection: _textDirection,
      textScaler: _textScaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }();

  RenderBox get _title => firstChild!;
  RenderBox get _subtitle => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TitleFirstParentData) {
      child.parentData = _TitleFirstParentData();
    }
  }

  /// The title's and the subtitle's maximum widths in [maxWidth]; a null
  /// subtitle width hides it.
  _TitleFirstPlan _plan(double maxWidth) {
    if (!maxWidth.isFinite) {
      return (title: double.infinity, subtitle: double.infinity);
    }
    final subtitleNatural = _subtitle.getMaxIntrinsicWidth(double.infinity);
    final reserve = math.min(subtitleNatural, _ellipsisWidth);
    final titleNatural = _title.getMaxIntrinsicWidth(double.infinity);
    final titleCap = maxWidth - _gap - reserve;
    // Not even the subtitle's ellipsis fits beside a visible title: the
    // title takes the whole line.
    if (titleCap < math.min(titleNatural, _ellipsisWidth)) {
      return (title: maxWidth, subtitle: null);
    }
    final title = math.min(titleNatural, titleCap);
    return (title: title, subtitle: maxWidth - title - _gap);
  }

  Size _layout(BoxConstraints constraints, ChildLayouter layoutChild) {
    final plan = _plan(constraints.maxWidth);
    final title = layoutChild(
      _title,
      BoxConstraints(maxWidth: plan.title, maxHeight: constraints.maxHeight),
    );
    var width = title.width;
    var height = title.height;
    if (plan.subtitle case final subtitleWidth?) {
      final subtitle = layoutChild(
        _subtitle,
        BoxConstraints(
          maxWidth: subtitleWidth,
          maxHeight: constraints.maxHeight,
        ),
      );
      width += _gap + subtitle.width;
      height = math.max(height, subtitle.height);
    }
    return constraints.constrain(
      Size(constraints.hasBoundedWidth ? constraints.maxWidth : width, height),
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _layout(constraints, ChildLayoutHelper.dryLayoutChild);

  @override
  void performLayout() {
    final plan = _plan(constraints.maxWidth);
    _subtitleShown = plan.subtitle != null;
    if (!_subtitleShown) {
      // Laid out so it keeps a size, but neither painted nor hit.
      _subtitle.layout(BoxConstraints.tight(Size.zero), parentUsesSize: true);
    }
    size = _layout(constraints, ChildLayoutHelper.layoutChild);
    final rtl = _textDirection == TextDirection.rtl;
    final title = _title.size;
    (_title.parentData! as _TitleFirstParentData).offset = Offset(
      rtl ? size.width - title.width : 0,
      (size.height - title.height) / 2,
    );
    final subtitle = _subtitle.size;
    final start = title.width + _gap;
    (_subtitle.parentData! as _TitleFirstParentData).offset = Offset(
      rtl ? size.width - start - subtitle.width : start,
      (size.height - subtitle.height) / 2,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _title.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _title.getMaxIntrinsicWidth(height) +
      _gap +
      _subtitle.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    _title.getMinIntrinsicHeight(width),
    _subtitle.getMinIntrinsicHeight(width),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    _title.getMaxIntrinsicHeight(width),
    _subtitle.getMaxIntrinsicHeight(width),
  );

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) {
    context.paintChild(
      _title,
      offset + (_title.parentData! as _TitleFirstParentData).offset,
    );
    if (_subtitleShown) {
      context.paintChild(
        _subtitle,
        offset + (_subtitle.parentData! as _TitleFirstParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [if (_subtitleShown) _subtitle, _title]) {
      final offset = (child.parentData! as _TitleFirstParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

/// One step of a [MeridianBreadcrumbs] trail.
class MeridianBreadcrumb {
  const MeridianBreadcrumb({
    required this.label,
    this.leading,
    this.mono = false,
    this.onActivate,
    this.onContextMenu,
    this.semanticLabel,
    this.emphasis = false,
  });

  final String label;

  /// A small picture before the label: a [MeridianIcon], or an icon with a
  /// short code (a commit hash).
  final Widget? leading;

  /// Sets the label in `code-sm`: hashes, identifiers.
  final bool mono;

  /// Click, Enter or Space. Null makes the crumb plain text.
  final VoidCallback? onActivate;

  /// A secondary click, the context-menu key or Shift+F10, with the global
  /// position the app's native menu opens at.
  final ValueChanged<Offset>? onContextMenu;

  /// The accessible name; defaults to [label].
  final String? semanticLabel;

  /// `body-strong` in `ink`: the current location, usually the last crumb.
  final bool emphasis;
}

/// A one-line trail of where the person is: a commit, its folders, a file.
///
/// Crumbs are separated by a small `chevron-right` in `ink-faint`. The first
/// and last crumbs always stay. When the row is too narrow the middle crumbs
/// fold, from the second onwards, into one `…` crumb that calls
/// [onOverflow] with the hidden crumbs (the app shows them in a native
/// menu). If it is still too narrow the first crumb's label ellipsizes,
/// then the last one's.
class MeridianBreadcrumbs extends StatelessWidget {
  const MeridianBreadcrumbs({
    required this.crumbs,
    this.onOverflow,
    this.overflowLabel,
    this.semanticLabel,
    super.key,
  });

  final List<MeridianBreadcrumb> crumbs;

  /// Called with the hidden crumbs when the person activates the `…` crumb,
  /// and the global position to open a menu at.
  final void Function(List<MeridianBreadcrumb> hidden, Offset globalPosition)?
  onOverflow;

  /// The accessible name of the `…` crumb; defaults to the hidden labels.
  final String? overflowLabel;

  /// Names the whole trail for assistive technology ("Location"), read as a
  /// header.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget trail = _Breadcrumbs(
      crumbs: crumbs,
      onOverflow: onOverflow,
      overflowLabel: overflowLabel,
    );
    if (semanticLabel case final label?) {
      trail = Semantics(
        container: true,
        explicitChildNodes: true,
        header: true,
        label: label,
        child: trail,
      );
    }
    return trail;
  }
}

class _Breadcrumbs extends StatefulWidget {
  const _Breadcrumbs({
    required this.crumbs,
    required this.onOverflow,
    required this.overflowLabel,
  });

  final List<MeridianBreadcrumb> crumbs;
  final void Function(List<MeridianBreadcrumb>, Offset)? onOverflow;
  final String? overflowLabel;

  @override
  State<_Breadcrumbs> createState() => _BreadcrumbsState();
}

class _BreadcrumbsState extends State<_Breadcrumbs> {
  /// The number of middle crumbs folded into `…` at the last layout. Layout
  /// decides it; the next frame takes the folded crumbs out of focus
  /// traversal.
  var _folded = 0;

  void _onFolded(int folded) {
    if (folded == _folded) return;
    meridianAfterFrame(this, () {
      if (_folded != folded) setState(() => _folded = folded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final crumbs = widget.crumbs;
    final count = crumbs.length;
    final folded = count >= 3 ? math.min(_folded, count - 2) : 0;
    final hidden = count >= 3
        ? crumbs.sublist(1, 1 + folded)
        : const <MeridianBreadcrumb>[];
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final separator = MeridianIcon(
      rtl ? MeridianIcons.chevronLeft : MeridianIcons.chevronRight,
      size: MeridianIconSize.small,
      color: MeridianTheme.of(context).colors.inkFaint,
    );
    final onOverflow = widget.onOverflow;
    return _BreadcrumbLayout(
      crumbCount: count,
      onFolded: _onFolded,
      children: [
        for (var i = 0; i < count; i++)
          ExcludeFocus(
            excluding: i >= 1 && i <= folded && i < count - 1,
            child: _Crumb(crumb: crumbs[i]),
          ),
        for (var i = 0; i < count - 1; i++) ExcludeSemantics(child: separator),
        if (count >= 3)
          ExcludeFocus(
            excluding: folded == 0,
            child: _Crumb(
              crumb: MeridianBreadcrumb(
                label: '…',
                semanticLabel:
                    widget.overflowLabel ??
                    hidden.map((crumb) => crumb.label).join(', '),
              ),
              onActivateAt: onOverflow == null
                  ? null
                  : (position) => onOverflow(hidden, position),
            ),
          ),
      ],
    );
  }
}

/// The global point under [context]'s box where a menu for it opens.
Offset _menuPoint(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return Offset.zero;
  return box.localToGlobal(Offset(0, box.size.height));
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.crumb, this.onActivateAt});

  final MeridianBreadcrumb crumb;

  /// Activation that needs the crumb's position (the `…` crumb).
  final ValueChanged<Offset>? onActivateAt;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final text = meridian.text;
    final density = meridian.density;
    final radius = BorderRadius.circular(meridian.radius.sm);
    final activateAt = onActivateAt;
    final VoidCallback? activate =
        crumb.onActivate ??
        (activateAt == null ? null : () => activateAt(_menuPoint(context)));
    final contextMenu = crumb.onContextMenu;
    final interactive = activate != null;
    final hover = MeridianSurfaceScope.hoverFillOf(context);
    final base = crumb.mono
        ? text.codeSm
        : crumb.emphasis
        ? text.bodyStrong
        : text.body;
    Widget content(MeridianInteractionState state) {
      final lit = state.hovered || state.pressed;
      final ink = crumb.emphasis || (interactive && lit)
          ? colors.ink
          : colors.inkMuted;
      final fill = interactive
          ? state.fill(
              rest: meridianClear(hover),
              hoverFill: hover,
              ink: colors.ink,
            )
          : meridianClear(hover);
      // The height is a minimum: large text grows the crumb instead of
      // clipping it.
      return AnimatedContainer(
        duration: meridianHoverDuration(context, lit),
        curve: MeridianDurations.hoverCurve,
        constraints: BoxConstraints(minHeight: density.controlSmallExtent),
        padding: const EdgeInsets.symmetric(horizontal: MeridianSpace.space2),
        decoration: BoxDecoration(color: fill, borderRadius: radius),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: IconTheme.merge(
            data: IconThemeData(color: ink),
            child: DefaultTextStyle.merge(
              style: text.body.copyWith(color: ink),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (crumb.leading case final leading?) ...[
                    leading,
                    const SizedBox(width: MeridianSpace.space2),
                  ],
                  Flexible(
                    child: _ShrinkableLabel(
                      child: Text(
                        crumb.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: base.copyWith(color: ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!interactive && contextMenu == null) {
      return Semantics(
        excludeSemantics: true,
        label: crumb.semanticLabel ?? crumb.label,
        child: content(
          const MeridianInteractionState(
            hovered: false,
            pressed: false,
            focused: false,
            enabled: false,
          ),
        ),
      );
    }
    return Semantics(
      excludeSemantics: true,
      button: interactive,
      label: crumb.semanticLabel ?? crumb.label,
      onTap: activate,
      onLongPress: contextMenu == null
          ? null
          : () => contextMenu(_menuPoint(context)),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: contextMenu == null
            ? null
            : (node, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.contextMenu ||
                        (event.logicalKey == LogicalKeyboardKey.f10 &&
                            HardwareKeyboard.instance.isShiftPressed))) {
                  contextMenu(_menuPoint(context));
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
        child: MeridianInteraction(
          onTap: activate,
          onSecondaryTapUp: contextMenu == null
              ? null
              : (details) => contextMenu(details.globalPosition),
          focusOnPointer: false,
          borderRadius: radius,
          expandHitTarget: false,
          cursor: interactive ? null : SystemMouseCursors.basic,
          builder: (context, state) => content(state),
        ),
      ),
    );
  }
}

/// Reports no minimum width, so a crumb's minimum intrinsic width is what
/// it needs apart from its ellipsizing label.
class _ShrinkableLabel extends SingleChildRenderObjectWidget {
  const _ShrinkableLabel({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderShrinkableLabel();
}

class _RenderShrinkableLabel extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) => 0;
}

/// Lays out `crumbCount` crumbs, then `crumbCount - 1` separators, then the
/// `…` crumb (with three or more crumbs) in one line, folding middle crumbs
/// and ellipsizing the ends to fit the width.
class _BreadcrumbLayout extends MultiChildRenderObjectWidget {
  const _BreadcrumbLayout({
    required this.crumbCount,
    required this.onFolded,
    required super.children,
  });

  final int crumbCount;
  final ValueChanged<int> onFolded;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBreadcrumbs(
    crumbCount: crumbCount,
    onFolded: onFolded,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderBreadcrumbs renderObject,
  ) {
    renderObject
      ..crumbCount = crumbCount
      ..onFolded = onFolded
      ..textDirection = Directionality.of(context);
  }
}

class _BreadcrumbParentData extends ContainerBoxParentData<RenderBox> {
  bool shown = false;
}

/// Which children show and how wide the shrinkable ends may be.
class _BreadcrumbPlan {
  const _BreadcrumbPlan(this.folded, this.firstWidth, this.lastWidth);

  /// Middle crumbs folded into `…`, counted from the second crumb.
  final int folded;
  final double firstWidth;
  final double lastWidth;
}

class _RenderBreadcrumbs extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BreadcrumbParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BreadcrumbParentData> {
  _RenderBreadcrumbs({
    required this._crumbCount,
    required this.onFolded,
    required this._textDirection,
  });

  int _crumbCount;
  set crumbCount(int value) {
    if (value == _crumbCount) return;
    _crumbCount = value;
    markNeedsLayout();
  }

  ValueChanged<int> onFolded;

  /// Still wider than the row after folding and ellipsizing.
  var _overflows = false;

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BreadcrumbParentData) {
      child.parentData = _BreadcrumbParentData();
    }
  }

  List<RenderBox> get _children => getChildrenAsList();

  /// The visible children in reading order for [plan].
  List<RenderBox> _visible(List<RenderBox> all, int folded) {
    final n = _crumbCount;
    if (n == 0) return const [];
    RenderBox crumb(int i) => all[i];
    RenderBox separator(int i) => all[n + i];
    final out = <RenderBox>[crumb(0)];
    if (folded > 0) {
      out
        ..add(separator(0))
        ..add(all[2 * n - 1])
        ..add(separator(folded));
    } else if (n > 1) {
      out.add(separator(0));
    }
    for (var i = folded + 1; i < n; i++) {
      out.add(crumb(i));
      if (i < n - 1) out.add(separator(i));
    }
    return out;
  }

  _BreadcrumbPlan _plan(List<RenderBox> all, double maxWidth, double height) {
    final n = _crumbCount;
    double natural(RenderBox child) => child.getMaxIntrinsicWidth(height);
    double total(int folded) =>
        _visible(all, folded).fold(0.0, (sum, child) => sum + natural(child));
    var folded = 0;
    if (n >= 3) {
      while (folded < n - 2 && total(folded) > maxWidth) {
        folded++;
      }
    }
    // A crumb never shrinks below what it needs besides its label (its
    // leading and padding).
    double least(RenderBox child) =>
        math.min(natural(child), child.getMinIntrinsicWidth(height));
    final first = natural(all[0]);
    final last = n > 1 ? natural(all[n - 1]) : 0.0;
    var excess = total(folded) - maxWidth;
    if (n == 1) {
      return _BreadcrumbPlan(
        0,
        math.max(least(all[0]), math.min(first, maxWidth)),
        0,
      );
    }
    if (excess <= 0) return _BreadcrumbPlan(folded, first, last);
    final firstFloor = math.max(
      least(all[0]),
      math.min(first, MeridianLayout.breadcrumbMinWidth),
    );
    final firstWidth = math.max(firstFloor, first - excess);
    excess -= first - firstWidth;
    final lastWidth = math.max(least(all[n - 1]), last - math.max(0.0, excess));
    return _BreadcrumbPlan(folded, firstWidth, lastWidth);
  }

  BoxConstraints _childConstraints(double height) =>
      BoxConstraints(maxHeight: height);

  @override
  double computeMinIntrinsicWidth(double height) {
    final all = _children;
    if (all.isEmpty || _crumbCount == 0) return 0;
    final first = all[0].getMaxIntrinsicWidth(height);
    return math.max(
      math.min(first, all[0].getMinIntrinsicWidth(height)),
      math.min(first, MeridianLayout.breadcrumbMinWidth),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final all = _children;
    if (all.isEmpty || _crumbCount == 0) return 0;
    return _visible(
      all,
      0,
    ).fold(0.0, (sum, child) => sum + child.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMinIntrinsicHeight(double width) => _children.fold(
    0.0,
    (height, child) => math.max(height, child.getMinIntrinsicHeight(width)),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => _children.fold(
    0.0,
    (height, child) => math.max(height, child.getMaxIntrinsicHeight(width)),
  );

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final all = _children;
    if (all.isEmpty || _crumbCount == 0) return constraints.smallest;
    final plan = _plan(all, constraints.maxWidth, constraints.maxHeight);
    var width = 0.0;
    var height = 0.0;
    for (final child in _visible(all, plan.folded)) {
      final size = child.getDryLayout(
        _constraintsFor(child, all, plan, constraints.maxHeight),
      );
      width += size.width;
      height = math.max(height, size.height);
    }
    return constraints.constrain(Size(width, height));
  }

  BoxConstraints _constraintsFor(
    RenderBox child,
    List<RenderBox> all,
    _BreadcrumbPlan plan,
    double height,
  ) {
    final base = _childConstraints(height);
    if (identical(child, all[0])) {
      return base.copyWith(maxWidth: plan.firstWidth);
    }
    if (_crumbCount > 1 && identical(child, all[_crumbCount - 1])) {
      return base.copyWith(maxWidth: plan.lastWidth);
    }
    return base;
  }

  @override
  void performLayout() {
    final all = _children;
    if (all.isEmpty || _crumbCount == 0) {
      size = constraints.smallest;
      return;
    }
    final plan = _plan(all, constraints.maxWidth, constraints.maxHeight);
    final visible = _visible(all, plan.folded);
    for (final child in all) {
      (child.parentData! as _BreadcrumbParentData).shown = false;
    }
    var height = 0.0;
    for (final child in all) {
      final shown = visible.contains(child);
      child.layout(
        shown
            ? _constraintsFor(child, all, plan, constraints.maxHeight)
            : _childConstraints(constraints.maxHeight),
        parentUsesSize: true,
      );
      if (shown) height = math.max(height, child.size.height);
    }
    final width = visible.fold(0.0, (sum, child) => sum + child.size.width);
    size = constraints.constrain(Size(width, height));
    _overflows = width > size.width;
    var x = 0.0;
    for (final child in visible) {
      final data = child.parentData! as _BreadcrumbParentData;
      data
        ..shown = true
        ..offset = Offset(
          _textDirection == TextDirection.rtl
              ? size.width - x - child.size.width
              : x,
          (size.height - child.size.height) / 2,
        );
      x += child.size.width;
    }
    onFolded(plan.folded);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void paintShown(PaintingContext context, Offset offset) {
      for (final child in _children) {
        final data = child.parentData! as _BreadcrumbParentData;
        if (data.shown) context.paintChild(child, offset + data.offset);
      }
    }

    if (!_overflows) {
      paintShown(context, offset);
      return;
    }
    // Clip only the sides, so focus rings above and below stay whole.
    const ring = MeridianLayout.focusRingWidth + MeridianLayout.focusRingOffset;
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTRB(0, -ring, size.width, size.height + ring),
      paintShown,
      oldLayer: _clip.layer,
    );
  }

  final _clip = LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in _children.reversed) {
      final data = child.parentData! as _BreadcrumbParentData;
      if (!data.shown) continue;
      final hit = result.addWithPaintOffset(
        offset: data.offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    for (final child in _children) {
      if ((child.parentData! as _BreadcrumbParentData).shown) visitor(child);
    }
  }
}
