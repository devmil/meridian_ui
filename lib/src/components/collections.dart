import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'actions.dart';
import 'inputs.dart';
import 'menu.dart';

/// Numbered pages of a long collection that loads one page at a time
/// (search results, a server-paged list): previous, the page numbers
/// (first, last and the current page's neighbours once there are many),
/// next, and an optional field to jump to a page.
///
/// The app owns the current page and loading; set [enabled] to false while
/// a page loads. Nothing shows for a single page.
class MeridianPagination extends StatefulWidget {
  const MeridianPagination({
    required this.page,
    required this.pageCount,
    required this.onPageSelected,
    required this.previousLabel,
    required this.nextLabel,
    super.key,
    this.pageLabel,
    this.jumpLabel,
    this.jumpSemanticLabel,
    this.pageCountLabel,
    this.enabled = true,
  }) : assert(page >= 1 && page <= pageCount);

  /// The current page, starting at 1.
  final int page;
  final int pageCount;

  /// Called with a different page the person chose.
  final ValueChanged<int> onPageSelected;

  /// Tooltip and accessible name of the previous and next buttons.
  final String previousLabel;
  final String nextLabel;

  /// Tooltip and accessible name of a page button ("Page 3").
  final String Function(int page)? pageLabel;

  /// The label before the jump field ("Page"). `null` hides the field.
  final String? jumpLabel;

  /// The jump field's accessible name ("Page number, 1 to 12").
  final String Function(int pageCount)? jumpSemanticLabel;

  /// The total after the jump field ("of 12").
  final String Function(int pageCount)? pageCountLabel;

  /// `false` while a page is loading: every control is disabled.
  final bool enabled;

  /// The pages to show, `null` for a gap.
  static List<int?> visiblePages(int page, int pageCount) {
    const full = MeridianLayout.paginationFullRange;
    if (pageCount <= full) return [for (var p = 1; p <= pageCount; p++) p];
    if (page <= 4) return [1, 2, 3, 4, 5, null, pageCount];
    if (page >= pageCount - 3) {
      return [1, null, for (var p = pageCount - 4; p <= pageCount; p++) p];
    }
    return [1, null, page - 1, page, page + 1, null, pageCount];
  }

  @override
  State<MeridianPagination> createState() => _MeridianPaginationState();
}

class _MeridianPaginationState extends State<MeridianPagination> {
  late final _field = TextEditingController(text: '${widget.page}');
  final _fieldFocus = FocusNode(debugLabel: 'meridian-pagination-field');

  @override
  void initState() {
    super.initState();
    _fieldFocus.addListener(_selectAllOnFocus);
  }

  @override
  void didUpdateWidget(covariant MeridianPagination oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page ||
        (!oldWidget.enabled && widget.enabled)) {
      _field.text = '${widget.page}';
    }
  }

  @override
  void dispose() {
    _fieldFocus
      ..removeListener(_selectAllOnFocus)
      ..dispose();
    _field.dispose();
    super.dispose();
  }

  void _selectAllOnFocus() {
    if (!_fieldFocus.hasFocus) return;
    _field.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _field.text.length,
    );
  }

  void _select(int page) {
    if (widget.enabled && page != widget.page) widget.onPageSelected(page);
  }

  void _submit(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      _field.text = '${widget.page}';
      return;
    }
    final page = parsed.clamp(1, widget.pageCount);
    _field.text = '$page';
    _select(page);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageCount <= 1) return const SizedBox.shrink();
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final caption = meridian.text.caption.copyWith(color: colors.inkMuted);
    final enabled = widget.enabled;
    final jump = widget.jumpLabel;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MeridianIconButton(
          label: widget.previousLabel,
          icon: Directionality.of(context) == TextDirection.rtl
              ? MeridianIcons.chevronRight
              : MeridianIcons.chevronLeft,
          size: MeridianControlSize.small,
          onPressed: enabled && widget.page > 1
              ? () => _select(widget.page - 1)
              : null,
        ),
        const SizedBox(width: MeridianSpace.space2),
        Flexible(
          // The current page's pill glides (MM-29).
          child: MeridianGlide.custom(
            selection: widget.page,
            indicator: DecoratedBox(
              decoration: BoxDecoration(
                color: MeridianTheme.of(context).colors.accentSoft,
                borderRadius: BorderRadius.circular(
                  MeridianTheme.of(context).radius.md,
                ),
              ),
            ),
            child: Wrap(
              spacing: MeridianSpace.space2,
              runSpacing: MeridianSpace.space2,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final page in MeridianPagination.visiblePages(
                  widget.page,
                  widget.pageCount,
                ))
                  if (page == null)
                    ExcludeSemantics(child: Text('…', style: caption))
                  else
                    _PageButton(
                      page: page,
                      current: page == widget.page,
                      label: widget.pageLabel?.call(page) ?? '$page',
                      onPressed: enabled ? () => _select(page) : null,
                    ),
                if (jump != null) ...[
                  const SizedBox(width: MeridianSpace.space2),
                  Text(jump, style: caption),
                  SizedBox(
                    width: MeridianLayout.paginationFieldWidth,
                    child: Semantics(
                      label: widget.jumpSemanticLabel?.call(widget.pageCount),
                      child: MeridianTextField(
                        controller: _field,
                        focusNode: _fieldFocus,
                        width: MeridianLayout.paginationFieldWidth,
                        size: MeridianControlSize.small,
                        enabled: enabled,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.go,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(
                            MeridianLayout.paginationFieldMaxDigits,
                          ),
                        ],
                        onSubmitted: _submit,
                      ),
                    ),
                  ),
                  if (widget.pageCountLabel case final total?)
                    Text(total(widget.pageCount), style: caption),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: MeridianSpace.space2),
        MeridianIconButton(
          label: widget.nextLabel,
          icon: Directionality.of(context) == TextDirection.rtl
              ? MeridianIcons.chevronLeft
              : MeridianIcons.chevronRight,
          size: MeridianControlSize.small,
          onPressed: enabled && widget.page < widget.pageCount
              ? () => _select(widget.page + 1)
              : null,
        ),
      ],
    );
  }
}

/// One page number: the current page is `accent-soft` with `accent-ink`.
class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.current,
    required this.label,
    required this.onPressed,
  });

  final int page;
  final bool current;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final extent = meridian.density.controlSmallExtent;
    final radius = BorderRadius.circular(meridian.radius.md);
    final enabled = onPressed != null;
    // The current page's `accent-soft` pill is the glide's indicator; a
    // page paints only its hover and pressed fills.
    final rest = meridianClear(colors.paneHover);
    final hover = current
        ? colors.ink.withValues(alpha: MeridianOpacity.pressedOverlay)
        : MeridianSurfaceScope.hoverFillOf(context);
    return Tooltip(
      message: label,
      child: Semantics(
        excludeSemantics: true,
        button: true,
        selected: current,
        enabled: enabled,
        label: label,
        onTap: onPressed,
        child: MeridianInteraction(
          onTap: onPressed,
          borderRadius: radius,
          pressScale: true,
          builder: (context, state) => MeridianGlideTarget(
            selected: current,
            child: AnimatedContainer(
              duration: meridianHoverDuration(
                context,
                state.hovered || state.pressed,
              ),
              constraints: BoxConstraints(minWidth: extent),
              height: extent,
              padding: const EdgeInsets.symmetric(
                horizontal: MeridianSpace.space3,
              ),
              decoration: BoxDecoration(
                color: enabled
                    ? state.fill(rest: rest, hoverFill: hover, ink: colors.ink)
                    : rest,
                borderRadius: radius,
              ),
              // Hugs the number: an aligned container would fill the width
              // the Wrap offers.
              child: Center(
                widthFactor: 1,
                child: Text(
                  '$page',
                  style: MeridianTextStyles.numeric(
                    meridian.text.label.copyWith(
                      color: !enabled
                          ? colors.inkFaint
                          : current
                          ? colors.accentInk
                          : colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One command of a [MeridianSelectionBar]: its control in the bar and,
/// optionally, the same command as a menu entry for when the bar is too
/// narrow.
@immutable
class MeridianSelectionAction {
  const MeridianSelectionAction({
    required this.child,
    this.overflow,
    this.extent,
  });

  /// The control shown in the bar, usually a small [MeridianIconButton] or
  /// a menu anchor.
  final Widget child;

  /// The same command in the overflow menu. Actions without it never move
  /// out of the bar.
  final MeridianMenuEntry? overflow;

  /// The width [child] needs; defaults to the small control extent.
  final double? extent;
}

/// The strip that replaces a list's header while items are selected: how
/// many, the commands for them, and Clear. Commands that do not fit move,
/// last first, into a trailing "more" menu.
///
/// `accent-soft`, the count in `accent-ink`. Keep the commands the same as
/// the items' context menu.
class MeridianSelectionBar extends StatelessWidget {
  const MeridianSelectionBar({
    required this.label,
    required this.actions,
    required this.clearLabel,
    required this.onClear,
    required this.overflowLabel,
    super.key,
    this.leading,
    this.clearKey,
    this.visible = true,
  });

  /// The count ("3 selected"). A leading number rolls when it changes.
  final String label;
  final List<MeridianSelectionAction> actions;
  final String clearLabel;
  final VoidCallback onClear;

  /// Tooltip and accessible name of the "more" menu.
  final String overflowLabel;

  /// A control before the count, such as a select-all menu.
  final Widget? leading;

  /// Key of the Clear button, for tests.
  final Key? clearKey;

  /// Keep the bar in the tree and set this to false to let it leave: it
  /// fades and moves 8 px down over `motion-exit`. It arrives from 12 px
  /// below on `spring-gentle` when it appears (MM-30).
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    return _SelectionBarMotion(
      visible: visible,
      child: MeridianSurfaceScope.withFill(
        context,
        fill: colors.accentSoft,
        child: LayoutBuilder(
          builder: (context, constraints) =>
              _bar(context, constraints.maxWidth),
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, double width) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    return Container(
      height: math.max(
        meridian.density.controlExtent + MeridianSpace.space4,
        meridian.density.minTarget,
      ),
      padding: const EdgeInsets.symmetric(horizontal: MeridianSpace.space5),
      color: colors.accentSoft,
      child: Row(
        children: [
          if (leading case final control?) ...[
            control,
            const SizedBox(width: MeridianSpace.space3),
          ],
          // The count never takes more than a third, so the commands keep
          // room; it ellipsizes in a very narrow bar.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width / 3),
            child: Semantics(
              liveRegion: true,
              label: label,
              excludeSemantics: true,
              child: _SelectionCount(
                label: label,
                style: MeridianTextStyles.numeric(
                  meridian.text.label.copyWith(color: colors.accentInk),
                ),
              ),
            ),
          ),
          const SizedBox(width: MeridianSpace.space4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => _SelectionActions(
                actions: actions,
                overflowLabel: overflowLabel,
                width: constraints.maxWidth,
              ),
            ),
          ),
          const SizedBox(width: MeridianSpace.space4),
          MeridianButton(
            key: clearKey,
            label: clearLabel,
            variant: MeridianButtonVariant.quiet,
            size: MeridianControlSize.small,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _SelectionActions extends StatelessWidget {
  const _SelectionActions({
    required this.actions,
    required this.overflowLabel,
    required this.width,
  });

  final List<MeridianSelectionAction> actions;
  final String overflowLabel;
  final double width;

  @override
  Widget build(BuildContext context) {
    // At touch density each command takes its 48px target, not its visual
    // extent; budgeting less overflows the bar instead of the menu taking it.
    final density = MeridianTheme.of(context).density;
    final extent = math.max(density.controlSmallExtent, density.minTarget);
    double of(MeridianSelectionAction action) => action.extent ?? extent;
    final visible = List<bool>.filled(actions.length, true);
    var used = actions.fold<double>(0, (sum, action) => sum + of(action));
    if (used > width && actions.any((action) => action.overflow != null)) {
      used += extent;
      for (var i = actions.length - 1; i >= 0 && used > width; i--) {
        if (actions[i].overflow == null) continue;
        visible[i] = false;
        used -= of(actions[i]);
      }
    }
    final overflow = [
      for (var i = 0; i < actions.length; i++)
        if (!visible[i]) actions[i].overflow!,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < actions.length; i++)
          if (visible[i]) actions[i].child,
        if (overflow.isNotEmpty)
          MeridianMenuAnchor(
            entries: overflow,
            builder: (context, open) => MeridianIconButton(
              label: overflowLabel,
              icon: MeridianIcons.ellipsis,
              size: MeridianControlSize.small,
              onPressed: open,
            ),
          ),
      ],
    );
  }
}

/// A selection bar's count: a leading number rolls, the rest stays.
class _SelectionCount extends StatelessWidget {
  const _SelectionCount({required this.label, required this.style});

  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'^(\d+)(.*)$').firstMatch(label);
    final number = match == null ? null : int.tryParse(match.group(1)!);
    if (match == null || number == null || '$number' != match.group(1)) {
      return Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MeridianRollingNumber(value: number, style: style),
        Flexible(
          child: Text(
            match.group(2)!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

/// A selection bar's arrival and departure (MM-30).
class _SelectionBarMotion extends StatefulWidget {
  const _SelectionBarMotion({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_SelectionBarMotion> createState() => _SelectionBarMotionState();
}

class _SelectionBarMotionState extends State<_SelectionBarMotion>
    with TickerProviderStateMixin {
  /// 1 at rest; the arrival springs from 0.
  late final MeridianSpringController _rise = MeridianSpringController(
    vsync: this,
    value: 1,
  );
  late final AnimationController _opacity = AnimationController(
    vsync: this,
    value: 1,
  );
  var _leaving = false;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.visible) {
      _arrive();
    } else {
      _opacity.value = 0;
    }
  }

  @override
  void didUpdateWidget(_SelectionBarMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    widget.visible ? _arrive() : _leave();
  }

  void _arrive() {
    _leaving = false;
    if (MeridianMotion.reduced(context)) {
      _rise.jumpTo(1);
      _opacity.animateTo(
        1,
        duration: MeridianMotion.fade(context, MeridianDurations.quick),
      );
      return;
    }
    _rise
      ..jumpTo(0)
      ..animateTo(1, spring: MeridianSprings.gentle);
    _opacity
      ..value = 0
      ..animateTo(
        1,
        duration: MeridianDurations.quick,
        curve: MeridianDurations.quickCurve,
      );
  }

  void _leave() {
    setState(() => _leaving = true);
    _opacity.animateTo(
      0,
      duration: MeridianMotion.fade(context, MeridianDurations.exit),
      curve: MeridianDurations.exitCurve,
    );
  }

  @override
  void dispose() {
    _rise.dispose();
    _opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MeridianMotion.reduced(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_rise.animation, _opacity]),
      child: widget.child,
      builder: (context, child) {
        if (!widget.visible && _opacity.value <= 0) {
          return const SizedBox.shrink();
        }
        final dy = reduced
            ? 0.0
            : _leaving
            ? MeridianLayout.selectionBarLeave * (1 - _opacity.value)
            : MeridianMotionScales.offsetToast * (1 - _rise.value);
        return IgnorePointer(
          ignoring: !widget.visible,
          child: Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset(0, dy), child: child),
          ),
        );
      },
    );
  }
}
