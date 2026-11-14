import 'package:flutter/widgets.dart';

import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';

/// A short label that appears while the pointer rests on [child], on a
/// long press, or on keyboard request: an `ink` chip with `caption` text in
/// `pane`, corners `radius-sm`, below the target (above when there is no
/// room).
///
/// It waits [MeridianDurations.tooltipWait] before it shows and leaves
/// after [MeridianDurations.exit]. Its [message] is also the child's
/// semantic tooltip unless [excludeFromSemantics] (when the child already
/// announces the same text). Built on the widgets layer's [RawTooltip].
class MeridianTooltip extends StatefulWidget {
  const MeridianTooltip({
    required this.child,
    super.key,
    this.message,
    this.richMessage,
    this.excludeFromSemantics = false,
    this.preferBelow = true,
    this.waitDuration,
    this.triggerMode = TooltipTriggerMode.longPress,
  }) : assert(
         (message == null) != (richMessage == null),
         'Give a MeridianTooltip either a message or a richMessage.',
       );

  /// The label.
  final String? message;

  /// A label with styled runs, instead of [message].
  final InlineSpan? richMessage;

  /// Leaves the label out of the child's semantics.
  final bool excludeFromSemantics;

  /// Shows the label below the target when there is room.
  final bool preferBelow;

  /// How long the pointer rests before the label shows;
  /// [MeridianDurations.tooltipWait] by default.
  final Duration? waitDuration;

  /// The touch gesture that shows the label.
  final TooltipTriggerMode triggerMode;

  final Widget child;

  @override
  State<MeridianTooltip> createState() => MeridianTooltipState();
}

/// The state of a [MeridianTooltip], to show it from code.
class MeridianTooltipState extends State<MeridianTooltip> {
  final _raw = GlobalKey<RawTooltipState>();

  String get _text => widget.message ?? widget.richMessage!.toPlainText();

  /// Shows the label now. Returns whether it was hidden before.
  bool ensureTooltipVisible() =>
      _raw.currentState?.ensureTooltipVisible() ?? false;

  @override
  Widget build(BuildContext context) {
    if (_text.isEmpty) return widget.child;
    final meridian = MeridianTheme.of(context);
    final style = meridian.text.caption.copyWith(color: meridian.colors.pane);
    final label = ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: MeridianLayout.tooltipMaxWidth,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: meridian.colors.ink,
          borderRadius: BorderRadius.circular(meridian.radius.sm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MeridianSpace.space3,
            vertical: MeridianSpace.space2,
          ),
          child: Text.rich(
            widget.richMessage ?? TextSpan(text: widget.message),
            style: style,
          ),
        ),
      ),
    );
    return RawTooltip(
      key: _raw,
      semanticsTooltip: widget.excludeFromSemantics ? null : _text,
      hoverDelay: widget.waitDuration ?? MeridianDurations.tooltipWait,
      dismissDelay: MeridianDurations.exit,
      triggerMode: widget.triggerMode,
      ignorePointer: true,
      positionDelegate: (position) => positionDependentBox(
        size: position.overlaySize,
        childSize: position.tooltipSize,
        target: position.target,
        verticalOffset: position.targetSize.height / 2 + MeridianSpace.space2,
        preferBelow: widget.preferBelow,
      ),
      tooltipBuilder: (context, animation) => FadeTransition(
        opacity: animation,
        // The overlay sits outside the app's theme scope's text style.
        child: DefaultTextStyle(style: style, child: label),
      ),
      child: widget.child,
    );
  }
}
