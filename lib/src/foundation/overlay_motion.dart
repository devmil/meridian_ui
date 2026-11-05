import 'package:flutter/widgets.dart';

import 'meridian_theme.dart';
import 'meridian_tokens.g.dart';

/// The entrance and exit of an overlay driven by a route or controller
/// [animation] that runs 0 → 1 linearly (MM-40, MM-41, MM-45, MM-46).
///
/// Entering: fades in, scales from [enterScale] to 1 around [alignment] and
/// moves in from [offset] (the rise), on `curve-enter`. Leaving (the
/// animation reversing): fades out and scales to `overlay-enter` on
/// `curve-exit`, without moving. Reduce motion keeps only the fade.
///
/// Menus and popovers pass `offset: Offset(0, -rise-overlay)` (they open
/// below their anchor and move away from it) and `alignment: topCenter`;
/// dialogs pass `dialog-enter`, `Offset(0, rise-dialog)` and `center`.
///
/// Internal to meridian_ui; not exported.
Widget meridianOverlayTransition(
  BuildContext context,
  Animation<double> animation,
  Widget child, {
  Offset offset = const Offset(0, -MeridianMotionScales.riseOverlay),
  double enterScale = MeridianMotionScales.overlayEnter,
  AlignmentGeometry alignment = Alignment.topCenter,
}) {
  final reduced = MeridianMotion.reduced(context);
  if (reduced) return FadeTransition(opacity: animation, child: child);
  return AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final leaving = animation.status == AnimationStatus.reverse;
      final v = animation.value.clamp(0.0, 1.0);
      if (leaving) {
        final e = MeridianCurves.exit.transform(1 - v);
        return Opacity(
          opacity: 1 - e,
          child: Transform.scale(
            scale: 1 - (1 - MeridianMotionScales.overlayEnter) * e,
            alignment: alignment.resolve(Directionality.maybeOf(context)),
            child: child,
          ),
        );
      }
      final t = MeridianCurves.enter.transform(v);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: offset * (1 - t),
          child: Transform.scale(
            scale: enterScale + (1 - enterScale) * t,
            alignment: alignment.resolve(Directionality.maybeOf(context)),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Plays [meridianOverlayTransition] once when it is first built: an
/// overlay shown without a route (a submenu, a panel).
class MeridianOverlayEntrance extends StatefulWidget {
  const MeridianOverlayEntrance({
    super.key,
    required this.child,
    this.offset = const Offset(0, -MeridianMotionScales.riseOverlay),
    this.alignment = Alignment.topCenter,
    this.visible = true,
    this.onHidden,
  });

  final Widget child;
  final Offset offset;
  final AlignmentGeometry alignment;

  /// Set to false to play the exit; [onHidden] runs once it has finished.
  final bool visible;
  final VoidCallback? onHidden;

  @override
  State<MeridianOverlayEntrance> createState() =>
      _MeridianOverlayEntranceState();
}

class _MeridianOverlayEntranceState extends State<MeridianOverlayEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MeridianDurations.overlay,
    reverseDuration: MeridianDurations.exit,
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MeridianMotion.reduced(context);
    _controller
      ..duration = reduced
          ? MeridianMotion.fade(context, MeridianDurations.overlay)
          : MeridianDurations.overlay
      ..reverseDuration = reduced
          ? MeridianMotion.fade(context, MeridianDurations.exit)
          : MeridianDurations.exit;
    if (_started) return;
    _started = true;
    if (widget.visible) _controller.forward();
  }

  @override
  void didUpdateWidget(MeridianOverlayEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse().whenCompleteOrCancel(() {
        if (mounted && !widget.visible && _controller.isDismissed) {
          widget.onHidden?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => meridianOverlayTransition(
    context,
    _controller,
    widget.child,
    offset: widget.offset,
    alignment: widget.alignment,
  );
}
