import 'package:flutter/material.dart';

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
    child: Scrollbar(
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
