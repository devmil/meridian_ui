import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import '../foundation/meridian_interaction.dart';

/// When a [MeridianScrollbar] shows its thumb.
enum MeridianScrollbarVisibility {
  /// As long as the view has more than it shows.
  always,

  /// While the pointer is over the view and while the view scrolls.
  hover,

  /// Only while the view scrolls.
  scrolling,
}

/// The scrollbar of one scroll view that decides when its thumb shows: a
/// sidebar or a list beside the content, where a thumb that is always there
/// competes with the rows.
///
/// [child] holds the scroll view that uses [controller]. The thumb fades in
/// and out; its thickness, colour and radius come from the Meridian theme.
/// The scrollbar the platform adds to a scroll view is switched off below
/// this widget, so wrap one view, not a screen.
class MeridianScrollbar extends StatefulWidget {
  const MeridianScrollbar({
    required this.controller,
    required this.child,
    this.visibility = MeridianScrollbarVisibility.hover,
    super.key,
  });

  /// The controller of the scroll view in [child].
  final ScrollController controller;

  final MeridianScrollbarVisibility visibility;

  final Widget child;

  @override
  State<MeridianScrollbar> createState() => _MeridianScrollbarState();
}

class _MeridianScrollbarState extends State<MeridianScrollbar> {
  var _hovered = false;

  void _setHovered(bool hovered) {
    if (hovered != _hovered) setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    opaque: false,
    onEnter: (_) => _setHovered(true),
    onExit: (_) => _setHovered(false),
    // The thumb follows the widget's own visibility: a change fades it, which
    // a change of the scrollbar theme alone does not.
    child: MeridianScrollbarThumb(
      controller: widget.controller,
      thumbVisibility: switch (widget.visibility) {
        MeridianScrollbarVisibility.always => true,
        MeridianScrollbarVisibility.hover => _hovered,
        MeridianScrollbarVisibility.scrolling => false,
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: widget.child,
      ),
    ),
  );
}

/// Meridian's scrollbar thumb on the widgets layer's [RawScrollbar]: a
/// pill in `line-strong` that thickens and darkens to `control-edge` while
/// the pointer is over it or drags it. It fades in while the view scrolls
/// and out after it stops.
///
/// [MeridianScrollbar] and `MeridianScrollBehavior` draw it. Use it directly
/// only for a view that needs [notificationPredicate] (a horizontal bar
/// over nested vertical scrolling).
class MeridianScrollbarThumb extends RawScrollbar {
  const MeridianScrollbarThumb({
    required super.child,
    super.key,
    super.controller,
    super.thumbVisibility,
    super.notificationPredicate,
    super.interactive,
    super.scrollbarOrientation,
  }) : super(
         fadeDuration: _fade,
         timeToFade: _timeToFade,
         pressDuration: Duration.zero,
       );

  static const _fade = Duration(milliseconds: 300);
  static const _timeToFade = Duration(milliseconds: 600);

  @override
  RawScrollbarState<MeridianScrollbarThumb> createState() =>
      _MeridianScrollbarThumbState();
}

class _MeridianScrollbarThumbState
    extends RawScrollbarState<MeridianScrollbarThumb> {
  late final AnimationController _hover = AnimationController(
    vsync: this,
    duration: MeridianDurations.overlay,
  )..addListener(updateScrollbarPainter);
  var _dragging = false;
  var _hovering = false;

  @override
  bool get showScrollbar => widget.thumbVisibility ?? false;

  @override
  void updateScrollbarPainter() {
    final colors = MeridianTheme.of(context).colors;
    final t = _dragging ? 1.0 : _hover.value;
    scrollbarPainter
      ..color = Color.lerp(colors.lineStrong, colors.controlEdge, t)!
      ..trackColor = meridianTransparent
      ..trackBorderColor = meridianTransparent
      ..textDirection = Directionality.of(context)
      ..thickness =
          MeridianLayout.scrollbarThickness +
          (MeridianLayout.scrollbarThicknessHover -
                  MeridianLayout.scrollbarThickness) *
              t
      ..radius = const Radius.circular(MeridianRadiusScale.pill)
      ..crossAxisMargin = MeridianLayout.scrollbarMargin
      ..mainAxisMargin = 0
      ..minLength = MeridianLayout.scrollbarMinLength
      ..padding = MediaQuery.paddingOf(context)
      ..scrollbarOrientation = widget.scrollbarOrientation
      ..ignorePointer = !enableGestures;
  }

  @override
  void handleThumbPressStart(Offset localPosition) {
    super.handleThumbPressStart(localPosition);
    setState(() => _dragging = true);
  }

  @override
  void handleThumbPressEnd(Offset localPosition, Velocity velocity) {
    super.handleThumbPressEnd(localPosition, velocity);
    setState(() => _dragging = false);
  }

  @override
  void handleHover(PointerHoverEvent event) {
    super.handleHover(event);
    final over = isPointerOverScrollbar(
      event.position,
      event.kind,
      forHover: true,
    );
    if (over == _hovering) return;
    setState(() => _hovering = over);
    over ? _hover.forward() : _hover.reverse();
  }

  @override
  void handleHoverExit(PointerExitEvent event) {
    super.handleHoverExit(event);
    setState(() => _hovering = false);
    _hover.reverse();
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }
}
