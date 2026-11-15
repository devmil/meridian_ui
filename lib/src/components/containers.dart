import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import '../foundation/overlay_motion.dart';
import 'actions.dart';
import 'display.dart';
import 'tooltip.dart';
import '../foundation/meridian_localizations.dart';
import 'scaffold.dart';
import '../foundation/meridian_theme_scope.dart';

/// The window or screen canvas: `ground`, with a surface scope that tells
/// rows and buttons on it to hover with `ground-hover`. Islands sit on it
/// [MeridianSpace.space3] apart.
class MeridianGround extends StatelessWidget {
  const MeridianGround({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: MeridianTheme.of(context).colors.ground,
    child: MeridianTextScope(
      child: MeridianWindowFocusScope(
        child: MeridianSurfaceScope(onGround: true, child: child),
      ),
    ),
  );
}

/// The rounded work surface: `pane`, `radius-lg`, `shadow-pane`.
///
/// Islands sit on `ground` 6px apart and never nest. The island tracks
/// keyboard focus: while focus is inside, it draws a 1px `accent-soft` halo
/// and its rows paint the selection solid `accent`.
class MeridianIsland extends StatefulWidget {
  const MeridianIsland({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.actions = const [],
    this.expandChild = false,
    this.padding = EdgeInsets.zero,
    this.color,
    this.contentKey,
    this.icon,
    this.leading,
    this.count,
    this.headerDivider = true,
  });

  final Widget child;

  /// A Lucide icon before the header title, in `ink-muted`.
  final String? icon;

  /// A widget before the header title (a status glyph, an avatar); wins
  /// over [icon].
  final Widget? leading;

  /// A quiet count after the header title ("12" files).
  final int? count;

  /// The hairline under the header. Off when the content starts with its
  /// own edge (a toolbar, a column header).
  final bool headerDivider;

  /// What the island shows (a selected commit's id). When it changes, the
  /// new content rises `rise-content` and fades in over `motion-select`
  /// while the old fades out; changes faster than 150 ms apart (keyboard
  /// scrubbing) swap at once (MM-74). `null`: no swap animation.
  final Object? contentKey;

  /// Header title (`body-strong`). No header without a title, a leading
  /// widget or icon, or actions.
  final String? title;

  /// Header metadata next to the title (a count, a path).
  final Widget? subtitle;

  /// Header actions: small icon buttons and small buttons.
  final List<Widget> actions;

  /// Let [child] fill the island's height (lists, editors).
  final bool expandChild;
  final EdgeInsetsGeometry padding;

  /// Overrides `pane` (for example a document's paper colour).
  final Color? color;

  @override
  State<MeridianIsland> createState() => _MeridianIslandState();
}

class _MeridianIslandState extends State<MeridianIsland> {
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final radius = BorderRadius.circular(meridian.radius.lg);
    final hasHeader =
        widget.title != null ||
        widget.actions.isNotEmpty ||
        widget.icon != null ||
        widget.leading != null;
    Widget body = Padding(padding: widget.padding, child: widget.child);
    if (widget.contentKey != null) {
      body = MeridianSwap(
        swapKey: widget.contentKey,
        style: MeridianSwapStyle.rise,
        // 150 ms, the time keyboard scrubbing leaves between switches.
        skipIfFasterThan: MeridianDurations.spinnerDelay,
        alignment: AlignmentDirectional.topStart,
        fit: widget.expandChild ? StackFit.expand : StackFit.loose,
        child: body,
      );
    }
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (value) {
        if (_focused != value) setState(() => _focused = value);
      },
      child: MeridianSurfaceScope(
        focused: _focused,
        child: FocusTraversalGroup(
          // The focus halo fades in over `motion-select` and out over
          // `motion-hover-out` (MM-73).
          child: AnimatedContainer(
            duration: MeridianMotion.of(
              context,
              _focused ? MeridianDurations.select : MeridianDurations.hoverOut,
            ),
            curve: _focused
                ? MeridianDurations.selectCurve
                : MeridianDurations.hoverOutCurve,
            decoration: BoxDecoration(
              color: widget.color ?? colors.pane,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: _focused
                      ? colors.accentSoft
                      : meridianClear(colors.accentSoft),
                  spreadRadius: 1,
                ),
                ...meridian.shadows.shadowPane,
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Column(
                mainAxisSize: widget.expandChild
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasHeader)
                    MeridianSectionHeader(
                      title: widget.title,
                      icon: widget.icon,
                      leading: widget.leading,
                      count: widget.count,
                      caption: widget.subtitle,
                      actions: widget.actions,
                      divider: widget.headerDivider,
                    ),
                  if (widget.expandChild) Expanded(child: body) else body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The title size of a [MeridianSectionHeader].
enum MeridianSectionHeaderSize {
  /// `body-strong`: an island's or a pane's header.
  regular,

  /// `label` in `ink`: a section inside an island (a list's group, a
  /// detail strip under the island header).
  small,
}

/// The 36px strip that names an island, a pane or a section and holds its
/// actions: an optional [leading] widget or [icon], the [title] (or a
/// richer [titleChild]), a quiet [count], a [caption] in `caption`
/// `ink-muted` with tabular figures, an optional [middle] that takes the
/// free space (a filter field, a row of view controls) and trailing
/// [actions]. A hairline [divider] separates it from the content.
///
/// Height `size-island-header` (36px; 48px at touch density so its buttons
/// keep their target), `space-5` before and `space-3` after. The title
/// ellipsizes before the actions give way. [MeridianIsland] draws its
/// built-in header with it; use it on its own for a section inside an
/// island or for a pane header that sits on a [color] other than the
/// island's.
class MeridianSectionHeader extends StatelessWidget {
  const MeridianSectionHeader({
    super.key,
    this.title,
    this.titleChild,
    this.icon,
    this.leading,
    this.count,
    this.countLabel,
    this.caption,
    this.middle,
    this.actions = const [],
    this.divider = true,
    this.color,
    this.size = MeridianSectionHeaderSize.regular,
  });

  /// The name, announced as a header.
  final String? title;

  /// Replaces the [title] text (a path with a muted directory); [title]
  /// stays the accessible name when both are given.
  final Widget? titleChild;

  /// A Lucide icon before the title, in `ink-muted`.
  final String? icon;

  /// A widget before the title; wins over [icon].
  final Widget? leading;

  /// A quiet count after the title.
  final int? count;

  /// The count's accessible name ("12 files"); the bare number otherwise.
  final String? countLabel;

  /// Metadata after the title (a size, a path, "3 of 12").
  final Widget? caption;

  /// Content between the title and [actions] that takes the remaining
  /// width. Without it the actions sit at the end.
  final Widget? middle;

  /// Small icon buttons and small buttons, `space-1` apart.
  final List<Widget> actions;

  /// The hairline under the strip.
  final bool divider;

  /// The strip's fill; transparent (the surface below shows) by default.
  final Color? color;
  final MeridianSectionHeaderSize size;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final title = this.title;
    final style = switch (size) {
      MeridianSectionHeaderSize.regular => meridian.text.bodyStrong,
      MeridianSectionHeaderSize.small => meridian.text.label.copyWith(
        color: colors.ink,
      ),
    };
    final leading =
        this.leading ??
        switch (icon) {
          final icon? => MeridianIcon(
            icon,
            size: MeridianIconSize.small,
            color: colors.inkMuted,
          ),
          null => null,
        };
    Widget? name;
    if (titleChild case final child?) {
      name = DefaultTextStyle.merge(
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: title == null
            ? child
            : Semantics(
                header: true,
                label: title,
                excludeSemantics: true,
                child: child,
              ),
      );
    } else if (title != null) {
      name = Semantics(
        header: true,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      );
    }
    final middle = this.middle;
    // The title gives way first, then the caption; neither pushes the
    // actions out.
    final heading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (name != null) Flexible(flex: 2, child: name),
        if (count case final count?) ...[
          if (name != null) const SizedBox(width: MeridianSpace.space2),
          MeridianCount(
            label: '$count',
            tone: MeridianCountTone.quiet,
            semanticLabel: countLabel,
          ),
        ],
        if (caption case final caption?) ...[
          const SizedBox(width: MeridianSpace.space4),
          Flexible(
            child: DefaultTextStyle.merge(
              style: MeridianTextStyles.numeric(
                meridian.text.caption.copyWith(color: colors.inkMuted),
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              child: caption,
            ),
          ),
        ],
      ],
    );
    final strip = SizedBox(
      // 48px at touch so header buttons keep their target.
      height: math.max(MeridianSize.islandHeader, meridian.density.minTarget),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: MeridianSpace.space5,
          end: MeridianSpace.space3,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: MeridianSpace.space3),
              ],
              if (middle == null)
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: heading,
                  ),
                )
              else ...[
                // The heading keeps its natural width up to half the strip;
                // the middle takes everything else, so the actions sit at
                // the end.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth / 2,
                  ),
                  child: heading,
                ),
                if (name != null || leading != null || count != null)
                  const SizedBox(width: MeridianSpace.space4),
                Expanded(child: middle),
              ],
              for (final action in actions) ...[
                const SizedBox(width: MeridianSpace.space1),
                action,
              ],
            ],
          ),
        ),
      ),
    );
    final content = divider
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              strip,
              MeridianHairline(color: colors.line),
            ],
          )
        : strip;
    final color = this.color;
    return color == null ? content : ColoredBox(color: color, child: content);
  }
}

/// A collapsible group with a chevron header, replacing Material's
/// ExpansionTile. The body indents 16px.
class MeridianDisclosure extends StatefulWidget {
  const MeridianDisclosure({
    required this.title,
    required this.child,
    super.key,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpansionChanged,
    this.trailing,
    this.header,
    this.enabled = true,
  });

  /// The header text and the accessible name.
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  /// Controlled state; leave `null` to let the widget keep its own.
  final bool? expanded;
  final ValueChanged<bool>? onExpansionChanged;

  /// Shown at the end of the header (a count, a status). Keeps its own
  /// semantics.
  final Widget? trailing;

  /// Replaces the [title] text with richer content (a commit subject with
  /// its author line). The header grows to fit it; [title] stays the
  /// accessible name.
  final Widget? header;

  /// A disabled header shows `ink-faint` and does not toggle.
  final bool enabled;

  @override
  State<MeridianDisclosure> createState() => _MeridianDisclosureState();
}

class _MeridianDisclosureState extends State<MeridianDisclosure> {
  late bool _expanded = widget.expanded ?? widget.initiallyExpanded;

  /// Counts expansions, so each one brings the body in again (MM-24).
  var _expansions = 0;

  @override
  void didUpdateWidget(covariant MeridianDisclosure oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.expanded;
    if (next != null) {
      if (next && !_expanded) _expansions++;
      _expanded = next;
    }
  }

  void _toggle() {
    final next = !_expanded;
    if (widget.expanded == null) {
      setState(() {
        _expanded = next;
        if (next) _expansions++;
      });
    }
    widget.onExpansionChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final radius = BorderRadius.circular(meridian.radius.sm);
    final onGround = MeridianSurfaceScope.maybeOf(context)?.onGround ?? false;
    final enabled = widget.enabled;
    final toggle = enabled ? _toggle : null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          button: true,
          enabled: enabled,
          expanded: _expanded,
          label: widget.title,
          onTap: toggle,
          onExpand: enabled && !_expanded ? _toggle : null,
          onCollapse: enabled && _expanded ? _toggle : null,
          child: MeridianInteraction(
            onTap: toggle,
            borderRadius: radius,
            expandHitTarget: false,
            builder: (context, state) => AnimatedContainer(
              duration: meridianHoverDuration(
                context,
                state.hovered || state.pressed,
              ),
              height: widget.header == null ? meridian.density.rowExtent : null,
              constraints: widget.header == null
                  ? null
                  : BoxConstraints(minHeight: meridian.density.rowExtent),
              padding: const EdgeInsets.symmetric(
                horizontal: MeridianSpace.space2,
              ),
              decoration: BoxDecoration(
                color: state.fill(
                  rest: meridianTransparent,
                  hoverFill: onGround ? colors.groundHover : colors.paneHover,
                  ink: colors.ink,
                ),
                borderRadius: radius,
              ),
              child: Row(
                children: [
                  // The chevron turns to point down (MM-24).
                  MeridianTurns(
                    turns: _expanded ? (rtl ? -0.25 : 0.25) : 0,
                    child: MeridianIcon(
                      rtl
                          ? MeridianIcons.chevronLeft
                          : MeridianIcons.chevronRight,
                      extent: MeridianLayout.chevronSize,
                      color: enabled ? colors.inkMuted : colors.inkFaint,
                    ),
                  ),
                  const SizedBox(width: MeridianSpace.space3),
                  Expanded(
                    child:
                        widget.header ??
                        ExcludeSemantics(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: meridian.text.label.copyWith(
                              color: enabled ? colors.ink : colors.inkFaint,
                            ),
                          ),
                        ),
                  ),
                  if (widget.trailing case final trailing?)
                    Semantics(container: true, child: trailing),
                ],
              ),
            ),
          ),
        ),
        MeridianReveal(
          visible: _expanded,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: MeridianSpace.space6,
            ),
            child: _expansions == 0
                ? widget.child
                : MeridianEntrance(
                    entranceKey: (this, _expansions),
                    child: widget.child,
                  ),
          ),
        ),
      ],
    );
  }
}

/// A modal question, asked only when the answer is needed before the app
/// can go on: confirming a destructive step, or choosing options for an
/// operation.
///
/// [title] is the full command with real names ("Delete 3 notebooks"),
/// [description] the consequence. [actions] go right-aligned, Cancel first
/// and the verb last, and wrap onto their own lines when they do not fit;
/// at touch density on a phone they stack full width, the verb on top.
/// [aside] (options) sits bottom-left. The body scrolls when it does not
/// fit. Enter runs [onSubmit] unless a button or text field has focus; a
/// single-line [MeridianTextField] inside submits through
/// [MeridianDialogSubmitScope] too (see there).
/// `raised`, `radius-xl`, `shadow-float`, 460px wide
/// ([MeridianLayout.dialogConfirmWidth]; forms take
/// [MeridianLayout.dialogFormWidth], workflows
/// [MeridianLayout.dialogWorkflowWidth]), on `scrim`. Show it with
/// [showMeridianDialog] or [showMeridianConfirm].
class MeridianDialog extends StatefulWidget {
  const MeridianDialog({
    super.key,
    this.title,
    this.description,
    this.content,
    this.actions = const [],
    this.aside,
    this.width = MeridianLayout.dialogWidth,
    this.scrollable = false,
    this.onSubmit,
    this.submitDisabled = false,
    this.onClose,
  });

  final String? title;
  final String? description;
  final Widget? content;
  final List<Widget> actions;
  final Widget? aside;
  final double width;

  /// Also scroll the actions with the body. By default the body scrolls
  /// and the actions stay in view.
  final bool scrollable;

  /// The primary action, run on Enter (usually the same callback as the
  /// last action).
  final VoidCallback? onSubmit;

  /// The primary action (the last action) is disabled: Enter shakes the
  /// surface and shows the action's disabled reason (MM-47).
  final bool submitDisabled;

  /// Shows a close button at the end of the title row. Give it to dialogs
  /// that inform or manage rather than ask (details, a list of hosts, a
  /// reference): they have nothing to cancel, so they close like a
  /// [MeridianPanel] instead of with a footer "Close" button.
  final VoidCallback? onClose;

  @override
  State<MeridianDialog> createState() => _MeridianDialogState();
}

class _MeridianDialogState extends State<MeridianDialog> {
  final _focus = FocusNode(debugLabel: 'meridian-dialog');

  /// Enter presses while the primary action was disabled (MM-47).
  var _rejects = 0;
  final _primary = GlobalKey(debugLabel: 'meridian-dialog-primary');

  /// Shows the primary action's tooltip: its disabled reason.
  void _showDisabledReason() {
    MeridianTooltipState? tooltip;
    void visit(Element element) {
      if (tooltip != null) return;
      if (element is StatefulElement && element.state is MeridianTooltipState) {
        tooltip = element.state as MeridianTooltipState;
        return;
      }
      element.visitChildElements(visit);
    }

    final primary = _primary.currentContext;
    if (primary is Element) visit(primary);
    tooltip?.ensureTooltipVisible();
  }

  @override
  void initState() {
    super.initState();
    // Take focus only when no action autofocused, so Enter reaches us.
    // Autofocus is applied in a microtask after the first frame; check
    // after it, or the dialog would take focus from an autofocused Cancel.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduleMicrotask(() {
        if (!mounted || _focus.hasFocus) return;
        // Only a shown dialog takes focus, not one placed inline (a
        // gallery specimen).
        if (ModalRoute.of(context) is! PopupRoute) return;
        final scope = FocusScope.of(context);
        if (scope.focusedChild == null) _focus.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Runs the primary action, or shakes and shows why it is disabled.
  void _submit() {
    final submit = widget.onSubmit;
    if (widget.submitDisabled || submit == null) {
      setState(() => _rejects++);
      _showDisabledReason();
      return;
    }
    submit();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final submit = widget.onSubmit;
    if ((submit == null && !widget.submitDisabled) || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    // Text fields keep Enter (new lines, their own onSubmitted).
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused != null &&
        (focused.widget is EditableText ||
            focused.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return KeyEventResult.ignored;
    }
    _submit();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final touch = meridian.density.isTouch;
    final screen = MediaQuery.sizeOf(context);
    final narrow = screen.width < MeridianLayout.compactBreakpoint;
    final actions = [
      for (final (i, action) in widget.actions.indexed)
        i == widget.actions.length - 1
            ? KeyedSubtree(key: _primary, child: action)
            : action,
    ];
    final aside = widget.aside;
    final close = widget.onClose;
    final closeButton = close == null
        ? null
        : MeridianIconButton(
            label: MeridianLocalizations.of(context).close,
            icon: MeridianIcons.x,
            onPressed: close,
          );
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title case final title?)
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: meridian.text.title),
                ),
              ),
              if (closeButton != null) ...[
                const SizedBox(width: MeridianSpace.space4),
                closeButton,
              ],
            ],
          )
        else if (closeButton != null)
          Align(alignment: AlignmentDirectional.centerEnd, child: closeButton),
        if (widget.description case final description?) ...[
          const SizedBox(height: MeridianSpace.space4),
          Text(
            description,
            style: meridian.text.body.copyWith(color: colors.inkMuted),
          ),
        ],
        if (widget.content case final content?) ...[
          const SizedBox(height: MeridianSpace.space5),
          DefaultTextStyle.merge(style: meridian.text.body, child: content),
        ],
      ],
    );
    Widget? footer;
    if (actions.isNotEmpty || aside != null) {
      if (narrow && touch) {
        footer = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ?aside,
            for (final (i, action) in actions.reversed.indexed) ...[
              if (i > 0 || aside != null)
                const SizedBox(height: MeridianSpace.space3),
              action,
            ],
          ],
        );
      } else {
        final bar = OverflowBar(
          alignment: MainAxisAlignment.end,
          overflowAlignment: OverflowBarAlignment.end,
          spacing: MeridianSpace.space4,
          overflowSpacing: MeridianSpace.space3,
          children: actions,
        );
        footer = aside == null
            ? bar
            : Row(
                children: [
                  Flexible(child: aside),
                  const SizedBox(width: MeridianSpace.space4),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: bar,
                    ),
                  ),
                ],
              );
      }
    }
    final inset = touch ? MeridianSpace.space8 : MeridianSpace.space7;
    final Widget column;
    if (widget.scrollable) {
      column = SingleChildScrollView(
        padding: EdgeInsets.all(inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            body,
            if (footer != null) ...[
              const SizedBox(height: MeridianSpace.space7),
              footer,
            ],
          ],
        ),
      );
    } else {
      column = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                inset,
                inset,
                inset,
                footer == null ? inset : MeridianSpace.space7,
              ),
              child: body,
            ),
          ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(inset, 0, inset, inset),
              child: footer,
            ),
        ],
      );
    }
    return MeridianDialogSurface(
      maxWidth: widget.width,
      semanticLabel: widget.title,
      rejectCount: _rejects,
      child: Focus(
        focusNode: _focus,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: MeridianDialogSubmitScope(
          onSubmit: widget.onSubmit == null && !widget.submitDisabled
              ? null
              : _submit,
          child: column,
        ),
      ),
    );
  }
}

/// Lets Enter in a text field submit the enclosing dialog.
///
/// [MeridianDialog] puts one around its body, so a single-line
/// [MeridianTextField] inside it runs the dialog's primary action on Enter
/// (or shakes the dialog when that action is disabled) unless the field has
/// its own `onSubmitted`, is multi-line or read-only, or sets
/// `submitsDialog: false`. A dialog with its own layout on a
/// [MeridianDialogSurface] can put one around its fields itself.
class MeridianDialogSubmitScope extends InheritedWidget {
  const MeridianDialogSubmitScope({
    required this.onSubmit,
    required super.child,
    super.key,
  });

  /// Runs the dialog's primary action, or rejects the attempt when it is
  /// disabled. `null`: the dialog has no primary action, and Enter keeps the
  /// field's own behaviour.
  final VoidCallback? onSubmit;

  /// The nearest scope's submit action. With [listen] (the default) the
  /// caller rebuilds when it changes.
  static VoidCallback? maybeOf(BuildContext context, {bool listen = true}) =>
      (listen
              ? context
                    .dependOnInheritedWidgetOfExactType<
                      MeridianDialogSubmitScope
                    >()
              : context
                    .getInheritedWidgetOfExactType<MeridianDialogSubmitScope>())
          ?.onSubmit;

  @override
  bool updateShouldNotify(MeridianDialogSubmitScope oldWidget) =>
      onSubmit != oldWidget.onSubmit;
}

/// The dialog surface on its own, for dialogs with their own layout (a
/// command palette, a settings window, a full-window review): `raised`,
/// `radius-xl`, `shadow-float`, centred with [margin] around it and at most
/// [maxWidth] wide and [maxHeight] (85% of the window by default) tall.
/// Use [MeridianDialog] for a title, a body and actions. Show it with
/// [showMeridianDialog]. It stays above the on-screen keyboard.
class MeridianDialogSurface extends StatelessWidget {
  const MeridianDialogSurface({
    required this.child,
    super.key,
    this.maxWidth = MeridianLayout.dialogWidth,
    this.maxHeight,
    this.margin = const EdgeInsets.all(MeridianSpace.space6),
    this.semanticLabel,
    this.alignment = Alignment.center,
    this.rejectCount = 0,
    this.borderRadius,
  });

  final Widget child;

  /// Increment when Enter is pressed while the primary action is
  /// disabled; the surface shakes once (MM-47).
  final int rejectCount;

  /// Overrides the surface corner radius, including its clipping.
  /// Animated palette routes may update this as their source expands.
  final BorderRadiusGeometry? borderRadius;

  /// `double.infinity` fills the window up to [margin].
  final double maxWidth;

  /// Defaults to [MeridianLayout.dialogMaxHeightFraction] of the window.
  final double? maxHeight;
  final EdgeInsetsGeometry margin;

  /// Names the dialog route for assistive technology.
  final String? semanticLabel;

  /// Where the surface sits in the window: centred, or next to the control
  /// that opened it (a tool palette at the top edge on the writing hand's
  /// side).
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final screen = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context);
    final radius = borderRadius ?? BorderRadius.circular(meridian.radius.xl);
    return AnimatedPadding(
      duration: MeridianMotion.of(context, MeridianDurations.overlay),
      curve: MeridianDurations.overlayCurve,
      padding: keyboard,
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: margin,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight:
                    maxHeight ??
                    screen.height * MeridianLayout.dialogMaxHeightFraction,
              ),
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                label: semanticLabel,
                explicitChildNodes: true,
                child: MeridianShake(
                  trigger: rejectCount,
                  strength: MeridianShakeStrength.surface,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: meridian.colors.raised,
                      borderRadius: radius,
                      boxShadow: meridian.shadows.shadowFloat,
                    ),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: MeridianTextScope(child: child),
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

/// Shows [builder]'s dialog on `scrim` (a dialog opened from another dialog
/// keeps that dialog's scrim), growing in from 0.96 as it rises 8px (MM-45). A click
/// on the scrim dismisses it when [barrierDismissible]; Escape dismisses it
/// when [dismissOnEscape] (on by default, also for dialogs the scrim cannot
/// close). Local [Theme] overrides at [context] carry into the dialog.
Future<T?> showMeridianDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool dismissOnEscape = true,
  RouteTransitionsBuilder? transitionBuilder,
  Duration? transitionDuration,
  Duration? reverseTransitionDuration,
}) {
  final colors = MeridianTheme.of(context).colors;
  // A dialog opened from another dialog or a menu keeps the scrim that is
  // already there instead of dimming the window twice.
  final nested = ModalRoute.of(context) is PopupRoute;
  final navigator = Navigator.of(context, rootNavigator: true);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(
    _MeridianDialogRoute<T>(
      builder: (dialogContext) => _DialogEscape(
        enabled: dismissOnEscape,
        child: themes.wrap(builder(dialogContext)),
      ),
      barrierDismissible: barrierDismissible,
      barrierLabel: MeridianLocalizations.of(context).dismiss,
      barrierColor: nested ? meridianClear(colors.scrim) : colors.scrim,
      reduced: MeridianMotion.reduced(context),
      transition: transitionBuilder,
      transitionDuration:
          transitionDuration ??
          (MeridianMotion.reduced(context)
              ? MeridianDurations.reducedFade
              : MeridianDurations.dialog),
      reverseDuration:
          reverseTransitionDuration ??
          (MeridianMotion.reduced(context)
              ? MeridianDurations.reducedFade
              : MeridianDurations.exit),
    ),
  );
}

/// Closes its dialog on Escape, or swallows Escape when not [enabled], so
/// the framework's own dismiss never runs then.
///
/// The key handler sits on the route's focus scope: Escape bubbles there from
/// whatever has focus in the dialog, and arrives there directly while nothing
/// in it has focus yet (a dialog without an autofocused control opened by a
/// shortcut).
class _DialogEscape extends StatefulWidget {
  const _DialogEscape({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_DialogEscape> createState() => _DialogEscapeState();
}

class _DialogEscapeState extends State<_DialogEscape> {
  static const _escape = SingleActivator(LogicalKeyboardKey.escape);
  FocusScopeNode? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = FocusScope.of(context);
    if (identical(scope, _scope)) return;
    _release();
    _scope = scope..onKeyEvent = _onKey;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_escape.accepts(event, HardwareKeyboard.instance)) {
      return KeyEventResult.ignored;
    }
    if (widget.enabled) Navigator.of(context).maybePop();
    return KeyEventResult.handled;
  }

  void _release() {
    final scope = _scope;
    if (scope != null && scope.onKeyEvent == _onKey) scope.onKeyEvent = null;
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _MeridianDialogRoute<T> extends RawDialogRoute<T> {
  _MeridianDialogRoute({
    required WidgetBuilder builder,
    required super.barrierDismissible,
    required super.barrierLabel,
    required super.barrierColor,
    required super.transitionDuration,
    required this.reverseDuration,
    required this.reduced,
    this.transition,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
       );

  final Duration reverseDuration;
  final bool reduced;

  /// A custom entrance and exit (a palette growing out of its trigger).
  final RouteTransitionsBuilder? transition;

  @override
  Duration get reverseTransitionDuration => reverseDuration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final custom = transition;
    if (custom != null) {
      return custom(context, animation, secondaryAnimation, child);
    }
    // The surface fades in, grows from `dialog-enter` and rises
    // `rise-dialog`; it leaves with a fade and a slight shrink (MM-45,
    // MM-46). The scrim fades with the route.
    return meridianOverlayTransition(
      context,
      animation,
      child,
      offset: const Offset(0, MeridianMotionScales.riseDialog),
      enterScale: MeridianMotionScales.dialogEnter,
      alignment: Alignment.center,
    );
  }
}

/// Asks a yes/no question. Returns `true` when the person confirms (the
/// button, or Enter when focus is not on Cancel).
///
/// [confirmLabel] is the verb that names the command ("Delete branch",
/// "Discard 3 files"), never "OK", "Confirm" or "Continue". [title] is the
/// full command with real names. Explain the consequence in [description]
/// or, when it needs more than a sentence (a list of what is affected, a
/// command preview, an option), in [content]; both may be given, the
/// description first.
///
/// For [destructive] verbs the confirm button is `danger` and focus starts
/// on Cancel, so a hasty Enter or Space cancels; otherwise it is `primary`
/// and focus starts on it. [width] defaults to
/// [MeridianLayout.dialogConfirmWidth]; give [MeridianLayout.dialogFormWidth]
/// when [content] holds fields. [barrierDismissible] lets a click on the
/// scrim cancel (on by default); turn it off when the question must be
/// answered explicitly. Escape always cancels.
Future<bool> showMeridianConfirm(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? description,
  Widget? content,
  String? cancelLabel,
  bool destructive = false,
  double width = MeridianLayout.dialogConfirmWidth,
  bool barrierDismissible = true,
  String? confirmIcon,
}) async {
  final result = await showMeridianDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => MeridianDialog(
      title: title,
      description: description,
      content: content,
      width: width,
      onSubmit: () => Navigator.of(context).pop(true),
      actions: [
        MeridianButton(
          label: cancelLabel ?? MeridianLocalizations.of(context).cancel,
          variant: MeridianButtonVariant.quiet,
          autofocus: destructive,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        MeridianButton(
          label: confirmLabel,
          icon: confirmIcon,
          variant: destructive
              ? MeridianButtonVariant.danger
              : MeridianButtonVariant.primary,
          autofocus: !destructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A bottom sheet for touch layouts: `raised`, top corners `radius-xl`, a
/// grab handle, at most 560px wide. Show it with [showMeridianSheet].
class MeridianSheet extends StatelessWidget {
  const MeridianSheet({
    required this.child,
    super.key,
    this.title,
    this.actions = const [],
    this.showHandle = true,
  });

  final Widget child;
  final String? title;

  /// Buttons in the header row (for example Done).
  final List<Widget> actions;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final radius = Radius.circular(meridian.radius.xl);
    // Rises above the on-screen keyboard.
    final bottom =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: BorderRadius.vertical(top: radius),
        boxShadow: meridian.shadows.shadowFloat,
      ),
      child: MeridianTextScope(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHandle)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: MeridianSpace.space4),
                    width: MeridianLayout.sheetHandleWidth,
                    height: MeridianLayout.sheetHandleHeight,
                    decoration: BoxDecoration(
                      color: colors.lineStrong,
                      borderRadius: BorderRadius.circular(
                        MeridianRadiusScale.pill,
                      ),
                    ),
                  ),
                ),
              if (title != null || actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    MeridianSpace.space8,
                    MeridianSpace.space5,
                    MeridianSpace.space6,
                    MeridianSpace.space2,
                  ),
                  child: Row(
                    children: [
                      if (title != null)
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(title!, style: meridian.text.title),
                          ),
                        )
                      else
                        const Spacer(),
                      ...actions,
                    ],
                  ),
                ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slides a [MeridianSheet] up from the bottom on `scrim`. Drag down or tap
/// the scrim to dismiss.
Future<T?> showMeridianSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) => Navigator.of(context).push(
  _MeridianSheetRoute<T>(
    builder: builder,
    dismissible: isDismissible,
    theme: MeridianTheme.of(context),
    reduced: MeridianMotion.reduced(context),
    barrierLabel: MeridianLocalizations.of(context).dismiss,
  ),
);

class _MeridianSheetRoute<T> extends PopupRoute<T> {
  _MeridianSheetRoute({
    required this.builder,
    required this.dismissible,
    required this.theme,
    required this.reduced,
    required this.barrierLabel,
  });

  final WidgetBuilder builder;
  final bool dismissible;
  final MeridianTheme theme;
  final bool reduced;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => theme.colors.scrim;

  @override
  bool get barrierDismissible => dismissible;

  @override
  Duration get transitionDuration =>
      reduced ? MeridianDurations.reducedFade : MeridianDurations.sheet;

  @override
  Duration get reverseTransitionDuration =>
      reduced ? MeridianDurations.reducedFade : MeridianDurations.exit;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => MeridianThemeScope(
    theme: theme,
    child: SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: MeridianLayout.sheetMaxWidth,
          ),
          child: _SheetDrag(
            route: this,
            enabled: dismissible,
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => reduced
      ? FadeTransition(opacity: animation, child: child)
      : SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(
              parent: animation,
              curve: MeridianDurations.sheetCurve,
              reverseCurve: MeridianCurves.exit,
            ),
          ),
          child: child,
        );

  void _drag(double delta, double height) {
    controller!.value -= delta / height;
  }

  void _release(double velocity) {
    if (velocity > 700 || controller!.value < 0.5) {
      if (isCurrent) navigator?.pop();
    } else {
      controller!.forward();
    }
  }
}

/// Lets a sheet follow a downward drag and close past half its height or on
/// a fling.
class _SheetDrag extends StatefulWidget {
  const _SheetDrag({
    required this.route,
    required this.enabled,
    required this.child,
  });

  final _MeridianSheetRoute<dynamic> route;
  final bool enabled;
  final Widget child;

  @override
  State<_SheetDrag> createState() => _SheetDragState();
}

class _SheetDragState extends State<_SheetDrag> {
  final _key = GlobalKey();

  double get _height => _key.currentContext?.size?.height ?? 1;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onVerticalDragUpdate: widget.enabled
        ? (details) => widget.route._drag(details.primaryDelta!, _height)
        : null,
    onVerticalDragEnd: widget.enabled
        ? (details) => widget.route._release(details.primaryVelocity ?? 0)
        : null,
    child: KeyedSubtree(key: _key, child: widget.child),
  );
}

/// A floating panel with a header and a close button, anchored by the app
/// (an inspector, a log, an operations list). `raised`, `radius-xl`,
/// `shadow-float`; enters with a 4px rise. Escape closes it while focus is
/// inside.
class MeridianPanel extends StatefulWidget {
  const MeridianPanel({
    required this.title,
    required this.child,
    super.key,
    this.onClose,
    this.actions = const [],
    this.width = MeridianLayout.panelWidth,
    this.padding = const EdgeInsets.fromLTRB(
      MeridianSpace.space6,
      0,
      MeridianSpace.space6,
      MeridianSpace.space6,
    ),
    this.origin = Alignment.topCenter,
    this.visible = true,
    this.onHidden,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final List<Widget> actions;
  final double width;

  /// Where the panel grows from: the edge nearest the control that opened
  /// it (a toolbar button at the top trailing corner) (MM-40).
  final AlignmentGeometry origin;

  /// Keep the panel mounted through its exit and call [onHidden] afterwards.
  final bool visible;
  final VoidCallback? onHidden;

  /// Body padding. The header already spaces the body from the top.
  final EdgeInsetsGeometry padding;

  @override
  State<MeridianPanel> createState() => _MeridianPanelState();
}

class _MeridianPanelState extends State<MeridianPanel> {
  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final radius = BorderRadius.circular(meridian.radius.xl);
    final close = widget.onClose;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): ?close},
      child: FocusTraversalGroup(
        child: MeridianOverlayEntrance(
          alignment: widget.origin,
          visible: widget.visible,
          onHidden: widget.onHidden,
          child: SizedBox(
            width: widget.width,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.raised,
                borderRadius: radius,
                boxShadow: meridian.shadows.shadowFloat,
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: MeridianTextScope(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: math.max(
                          MeridianLayout.floatingPanelHeaderHeight,
                          meridian.density.minTarget,
                        ),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: MeridianSpace.space6,
                            end: MeridianSpace.space3,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: meridian.text.bodyStrong,
                                  ),
                                ),
                              ),
                              ...widget.actions,
                              if (close != null)
                                MeridianIconButton(
                                  label: MeridianLocalizations.of(context)
                                      .close,
                                  icon: MeridianIcons.x,
                                  onPressed: close,
                                ),
                            ],
                          ),
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: widget.padding,
                          child: widget.child,
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
  }
}

/// Lays out [MeridianSettingsRow]s with 16px between them.
class MeridianSettingsGroup extends StatelessWidget {
  const MeridianSettingsGroup({
    required this.children,
    super.key,
    this.title,
    this.fitLabels = false,
  });

  final List<Widget> children;

  /// Optional `overline` heading.
  final String? title;

  /// Size the label column to the widest label of the group's own
  /// [MeridianSettingsRow] children (at most the 200px settings column)
  /// instead of the fixed settings column, for forms in dialogs, where a
  /// short label in a wide column leaves the controls stranded mid-dialog.
  /// A row with an empty label lines a checkbox up with the controls.
  final bool fitLabels;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Semantics(
            header: true,
            child: Text(
              title!.toUpperCase(),
              style: meridian.text.overline.copyWith(
                color: meridian.colors.inkMuted,
              ),
            ),
          ),
          const SizedBox(height: MeridianSpace.space5),
        ],
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: MeridianSpace.space6),
          children[i],
        ],
      ],
    );
    if (!fitLabels) return column;
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var width = 0.0;
    for (final row in children.whereType<MeridianSettingsRow>()) {
      if (row.label.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: row.label, style: meridian.text.body),
        textDirection: direction,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      width = math.max(width, painter.width.ceilToDouble());
      painter.dispose();
    }
    return _MeridianSettingsLabelWidth(
      width: math.min(width, MeridianLayout.settingsLabelColumn),
      child: column,
    );
  }
}

class _MeridianSettingsLabelWidth extends InheritedWidget {
  const _MeridianSettingsLabelWidth({
    required this.width,
    required super.child,
  });

  final double width;

  @override
  bool updateShouldNotify(_MeridianSettingsLabelWidth oldWidget) =>
      width != oldWidget.width;
}

/// A settings form row. On desktop the label is right-aligned in a 200px
/// column with the controls to its right and help below them; in narrow
/// layouts the label stacks above. Inside a group with
/// [MeridianSettingsGroup.fitLabels] the column hugs the group's widest
/// label. Changes apply straight away: no Save button, no floating labels,
/// no cards.
class MeridianSettingsRow extends StatelessWidget {
  const MeridianSettingsRow({
    required this.label,
    required this.children,
    super.key,
    this.help,
  });

  final String label;
  final String? help;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: MeridianSpace.space3),
          children[i],
        ],
        if (help != null) ...[
          const SizedBox(height: MeridianSpace.space3),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: MeridianLayout.settingsHelpMaxWidth,
            ),
            child: Text(
              help!,
              style: meridian.text.caption.copyWith(color: colors.inkMuted),
            ),
          ),
        ],
      ],
    );
    final fitted = context
        .dependOnInheritedWidgetOfExactType<_MeridianSettingsLabelWidth>()
        ?.width;
    final labelWidth = fitted ?? MeridianLayout.settingsLabelColumn;
    final gap = fitted == null ? MeridianSpace.space7 : MeridianSpace.space5;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            meridian.density.isTouch ||
            constraints.maxWidth <
                (fitted == null
                    ? MeridianLayout.settingsStackBreakpoint
                    : labelWidth + gap + MeridianLayout.selectMinWidth);
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label.isNotEmpty) ...[
                Text(label, style: meridian.text.label),
                const SizedBox(height: MeridianSpace.space3),
              ],
              controls,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: meridian.density.controlExtent,
                ),
                // heightFactor: centre on the first control line, never on
                // the whole available height.
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  heightFactor: 1,
                  child: Text(
                    label,
                    textAlign: TextAlign.end,
                    style: meridian.text.body,
                  ),
                ),
              ),
            ),
            SizedBox(width: gap),
            Expanded(child: controls),
          ],
        );
      },
    );
  }
}

/// A touch app bar on `ground`: back or menu button, title, actions.
/// 56px tall, no elevation; a hairline appears when content scrolls under
/// it ([elevated]).
///
/// Without a [leading] widget it shows a back button when the route can be
/// popped, or a menu button that opens the enclosing `MeridianScaffold`'s drawer
/// ([automaticallyImplyLeading]). A long [title] ellipsizes and shows in
/// full as its tooltip; [subtitle] is a `caption` line under it (a save
/// state, a location).
class MeridianAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MeridianAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions = const [],
    this.elevated = false,
    this.centerTitle = false,
    this.subtitle,
    this.automaticallyImplyLeading = true,
  });

  final String? title;
  final Widget? leading;
  final List<Widget> actions;
  final bool elevated;
  final bool centerTitle;
  final String? subtitle;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(MeridianSize.appbarTouch);

  Widget? _impliedLeading(BuildContext context) {
    if (!automaticallyImplyLeading) return null;
    final localizations = MeridianLocalizations.of(context);
    final scaffold = MeridianScaffold.maybeOf(context);
    if (scaffold != null && scaffold.hasDrawer) {
      return MeridianIconButton(
        label: localizations.openNavigationMenu,
        icon: MeridianIcons.menu,
        onPressed: scaffold.openDrawer,
      );
    }
    final route = ModalRoute.of(context);
    if (route != null && route.impliesAppBarDismissal) {
      return MeridianIconButton(
        label: localizations.back,
        icon: MeridianIcons.arrowLeft,
        onPressed: () => Navigator.maybePop(context),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final top = MediaQuery.paddingOf(context).top;
    final leading = this.leading ?? _impliedLeading(context);
    Widget? titleWidget;
    if (title case final title?) {
      titleWidget = Semantics(
        header: true,
        child: MeridianTooltip(
          message: title,
          excludeFromSemantics: true,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: meridian.text.heading,
          ),
        ),
      );
      if (subtitle case final subtitle?) {
        titleWidget = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: centerTitle
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            titleWidget,
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: meridian.text.caption.copyWith(color: colors.inkMuted),
            ),
          ],
        );
      }
    }
    if (titleWidget != null) {
      // The bar keeps its height, so large text scales the title only so
      // far (as platform app bars do); the full title is its tooltip.
      titleWidget = MediaQuery.withClampedTextScaling(
        maxScaleFactor: MeridianLayout.appBarTitleMaxTextScale,
        child: titleWidget,
      );
    }
    return MeridianSurfaceScope(
      onGround: true,
      child: Container(
        padding: EdgeInsets.only(top: top),
        height: MeridianSize.appbarTouch + top,
        color: colors.ground,
        // Painted over the bar, so the hairline never takes a pixel from
        // the 56px content height.
        foregroundDecoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: elevated ? colors.line : meridianTransparent,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MeridianSpace.space2),
          child: NavigationToolbar(
            leading: leading,
            middle: titleWidget,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: actions),
            centerMiddle: centerTitle,
            middleSpacing: leading == null
                ? MeridianSpace.space4
                : MeridianSpace.space2,
          ),
        ),
      ),
    );
  }
}

/// The navigation drawer of a phone layout: the app's destinations on a
/// `pane` side sheet that slides in from the leading edge over `scrim`,
/// trailing corners `radius-xl`, `shadow-float`, 304px at most. Put it in
/// `MeridianScaffold.drawer` and fill it with [MeridianNavRow]s; wider layouts show
/// the same rows in a sidebar instead.
class MeridianDrawer extends StatelessWidget {
  const MeridianDrawer({
    required this.child,
    super.key,
    this.semanticLabel,
    this.width = MeridianLayout.drawerWidth,
  });

  final Widget child;

  /// Names the drawer route; defaults to the platform's "Navigation menu".
  final String? semanticLabel;
  final double width;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final radius = Radius.circular(meridian.radius.xl);
    final screen = MediaQuery.sizeOf(context).width;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: semanticLabel ?? MeridianLocalizations.of(context).navigationMenu,
      child: ConstrainedBox(
        constraints: BoxConstraints.expand(
          width: math.min(
            width,
            math.max(0, screen - MeridianLayout.sidebarRailWidth),
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: meridian.colors.pane,
            borderRadius: BorderRadiusDirectional.horizontal(end: radius)
                .resolve(Directionality.of(context)),
            boxShadow: meridian.shadows.shadowFloat,
          ),
          child: MeridianTextScope(
            child: MeridianSurfaceScope(onGround: false, child: child),
          ),
        ),
      ),
    );
  }
}
