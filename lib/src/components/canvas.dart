import 'package:flutter/widgets.dart';

import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';

/// The desk behind documents: `canvas`.
///
/// Page feeds, scan and image viewers and print previews sit on it. Pages are
/// [MeridianPaper]; tools float over it in a [MeridianToolDock]. Chrome text on
/// the canvas (a page number, a zoom level) uses `ink` or `ink-muted`.
class MeridianCanvas extends StatelessWidget {
  const MeridianCanvas({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final canvas = MeridianTheme.of(context).colors.canvas;
    return ColoredBox(
      color: canvas,
      child: MeridianSurfaceScope(onGround: true, fill: canvas, child: child),
    );
  }
}

/// A document page resting on the canvas.
///
/// [color] is content (the page's paper) and never follows the theme. The
/// page takes `shadow-pane` as its edge and `paperRadius` corners; a
/// [selected] page gets a 2px `accent` ring outside its edge, so the paper
/// itself never changes colour.
class MeridianPaper extends StatelessWidget {
  const MeridianPaper({
    required this.color,
    super.key,
    this.child,
    this.aspectRatio,
    this.selected = false,
    this.semanticLabel,
  });

  /// The paper colour: document content, not a theme colour.
  final Color color;
  final Widget? child;

  /// Width / height of the page, from the document. `null` fills the space.
  final double? aspectRatio;

  /// Draws the accent ring (a page picked in an organiser).
  final bool selected;

  /// Names the page for screen readers ("Page 3 of 12").
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    const radius = BorderRadius.all(
      Radius.circular(MeridianLayout.paperRadius),
    );
    Widget page = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        boxShadow: [
          if (selected)
            BoxShadow(
              color: colors.accent,
              spreadRadius: MeridianLayout.focusRingWidth,
            ),
          ...meridian.shadows.shadowPane,
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: child ?? const SizedBox.expand(),
      ),
    );
    if (aspectRatio != null) {
      page = AspectRatio(aspectRatio: aspectRatio!, child: page);
    }
    return Semantics(
      container: true,
      label: semanticLabel,
      selected: selected,
      child: page,
    );
  }
}

/// The floating tool palette of a document screen: one `raised` island with
/// `shadow-float` and `radius-xl` corners, holding tool buttons.
///
/// Put [MeridianIconButton]s (with `active` for the current tool),
/// [MeridianColorSwatch]es and [MeridianToolDockDivider]s in [children]. The
/// dock sizes to its content; the screen places it (bottom centre on
/// phones, top or the writing hand's side on tablets) and decides what
/// moves into an overflow menu.
class MeridianToolDock extends StatelessWidget {
  const MeridianToolDock({
    required this.children,
    super.key,
    this.axis = Axis.horizontal,
    this.semanticLabel,
  });

  final List<Widget> children;

  /// A horizontal bar or a vertical rail.
  final Axis axis;

  /// Names the group for screen readers ("Tools").
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final radius = BorderRadius.circular(meridian.radius.xl);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: FocusTraversalGroup(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.raised,
            borderRadius: radius,
            boxShadow: meridian.shadows.shadowFloat,
          ),
          child: MeridianSurfaceScope(
            fill: colors.raised,
            child: Padding(
              padding: const EdgeInsets.all(MeridianLayout.toolDockPadding),
              child: _DockAxis(
                axis: axis,
                child: Flex(
                  direction: axis,
                  mainAxisSize: MainAxisSize.min,
                  spacing: MeridianSpace.space1,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tells [MeridianToolDockDivider] which way the dock runs.
class _DockAxis extends InheritedWidget {
  const _DockAxis({required this.axis, required super.child});

  final Axis axis;

  @override
  bool updateShouldNotify(_DockAxis oldWidget) => oldWidget.axis != axis;
}

/// A `line-strong` hairline between tool groups in a [MeridianToolDock],
/// running across the dock.
class MeridianToolDockDivider extends StatelessWidget {
  const MeridianToolDockDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final axis =
        context.dependOnInheritedWidgetOfExactType<_DockAxis>()?.axis ??
        Axis.horizontal;
    final color = MeridianTheme.of(context).colors.lineStrong;
    return Padding(
      padding: axis == Axis.horizontal
          ? const EdgeInsets.symmetric(horizontal: MeridianSpace.space2)
          : const EdgeInsets.symmetric(vertical: MeridianSpace.space2),
      child: SizedBox(
        width: axis == Axis.horizontal
            ? MeridianLayout.hairline
            : MeridianLayout.toolDockDividerLength,
        height: axis == Axis.horizontal
            ? MeridianLayout.toolDockDividerLength
            : MeridianLayout.hairline,
        child: ColoredBox(color: color),
      ),
    );
  }
}
