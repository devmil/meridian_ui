import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/meridian_localizations.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';

/// A screen's frame: an [appBar] on top, the [body], a [bottomBar] below
/// and an optional navigation [drawer] that slides in from the leading
/// edge over `scrim`.
///
/// The body gets the rest, loosely, at the top left (like Material's
/// `Scaffold`), on [backgroundColor] (`ground` by default) and
/// moves up out of the on-screen keyboard unless
/// [resizeToAvoidBottomInset] is off. Padding that the app bar and bottom
/// bar take care of is removed from the body's [MediaQuery].
///
/// The drawer opens with `MeridianScaffold.of(context).openDrawer()` (a
/// `MeridianAppBar` shows the button for it), a swipe from the leading
/// edge on touch, and closes with the scrim, Escape, the back button or
/// `Navigator.pop`, like a route.
class MeridianScaffold extends StatefulWidget {
  const MeridianScaffold({
    super.key,
    this.appBar,
    this.body,
    this.drawer,
    this.bottomBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.drawerEdgeDragWidth = 20,
  });

  /// Usually a `MeridianAppBar`; it pads itself for the status bar.
  final Widget? appBar;
  final Widget? body;

  /// Usually a `MeridianDrawer`.
  final Widget? drawer;

  /// A status bar, toolbar or navigation bar under the body.
  final Widget? bottomBar;

  /// Behind the body; `ground` by default.
  final Color? backgroundColor;

  /// Shrinks the body by the on-screen keyboard.
  final bool resizeToAvoidBottomInset;

  /// How far from the leading edge a swipe opens the drawer (touch).
  final double drawerEdgeDragWidth;

  /// The nearest scaffold's state.
  static MeridianScaffoldState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'No MeridianScaffold above this context.');
    return state!;
  }

  /// The nearest scaffold's state, or `null`.
  static MeridianScaffoldState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<MeridianScaffoldState>();

  @override
  State<MeridianScaffold> createState() => MeridianScaffoldState();
}

/// Opens and closes a [MeridianScaffold]'s drawer.
class MeridianScaffoldState extends State<MeridianScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drawer = AnimationController(
    vsync: this,
    duration: MeridianDurations.sheet,
    reverseDuration: MeridianDurations.exit,
  )..addStatusListener(_onDrawerStatus);
  final _drawerFocus = FocusScopeNode(debugLabel: 'MeridianScaffold drawer');
  LocalHistoryEntry? _history;
  var _disposing = false;
  double _drawerWidth = 304;

  /// Whether the scaffold has a drawer.
  bool get hasDrawer => widget.drawer != null;

  /// Whether the drawer is open or opening.
  bool get isDrawerOpen =>
      _drawer.status == AnimationStatus.forward ||
      _drawer.status == AnimationStatus.completed;

  void _onDrawerStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      final history = _history;
      _history = null;
      history?.remove();
      setState(() {});
    }
  }

  /// Slides the drawer in and moves focus into it.
  void openDrawer() {
    if (!hasDrawer) return;
    if (_history == null) {
      final entry = LocalHistoryEntry(onRemove: _closeFromHistory);
      _history = entry;
      ModalRoute.of(context)?.addLocalHistoryEntry(entry);
    }
    setState(() {});
    _drawer.duration = MeridianMotion.of(context, MeridianDurations.sheet);
    _drawer.forward();
    _drawerFocus.requestFocus();
  }

  /// Slides the drawer out.
  void closeDrawer() {
    final history = _history;
    if (history != null) {
      _history = null;
      history.remove();
    } else {
      _animateClosed();
    }
  }

  void _closeFromHistory() {
    _history = null;
    _animateClosed();
  }

  void _animateClosed() {
    if (!mounted || _disposing) return;
    _drawer.reverseDuration = MeridianMotion.of(
      context,
      MeridianDurations.exit,
    );
    _drawer.reverse();
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (_history == null && details.primaryDelta! != 0) openDrawer();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final delta = details.primaryDelta! / _drawerWidth;
    _drawer.value += rtl ? -delta : delta;
  }

  void _dragEnd(DragEndDetails details) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    var velocity = details.primaryVelocity ?? 0;
    if (rtl) velocity = -velocity;
    if (velocity.abs() > 365) {
      velocity > 0 ? _drawer.fling() : closeDrawer();
    } else if (_drawer.value < 0.5) {
      closeDrawer();
    } else {
      _drawer.forward();
    }
  }

  @override
  void didUpdateWidget(MeridianScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drawer != null && widget.drawer == null) {
      _history?.remove();
      _history = null;
      _drawer.value = 0;
    }
  }

  @override
  void dispose() {
    _disposing = true;
    _history?.remove();
    _drawer.dispose();
    _drawerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final media = MediaQuery.of(context);
    final keyboard = widget.resizeToAvoidBottomInset
        ? media.viewInsets.bottom
        : 0.0;
    Widget body = widget.body ?? const SizedBox.shrink();
    body = MediaQuery.removePadding(
      context: context,
      removeTop: widget.appBar != null,
      removeBottom: widget.bottomBar != null || keyboard > 0,
      child: widget.resizeToAvoidBottomInset
          ? MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: body,
            )
          : body,
    );
    Widget frame = ColoredBox(
      color: widget.backgroundColor ?? meridian.colors.ground,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?widget.appBar,
            // Like Material's Scaffold: the body gets the space between the
            // bars as loose constraints, at the top left, so a body that
            // sizes itself keeps its size.
            Expanded(
              child: Align(alignment: Alignment.topLeft, child: body),
            ),
            if (keyboard == 0) ?widget.bottomBar,
          ],
        ),
      ),
    );
    final drawer = widget.drawer;
    if (drawer == null) return frame;
    final open = _history != null || _drawer.value > 0;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    frame = Stack(
      children: [
        ExcludeFocus(
          excluding: open,
          child: ExcludeSemantics(excluding: open, child: frame),
        ),
        if (!open && meridian.density.isTouch)
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: widget.drawerEdgeDragWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              dragStartBehavior: DragStartBehavior.down,
              onHorizontalDragUpdate: _dragUpdate,
              onHorizontalDragEnd: _dragEnd,
            ),
          ),
        if (open) ...[
          Positioned.fill(
            child: Semantics(
              label: MeridianLocalizations.of(context).dismiss,
              onTap: closeDrawer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: closeDrawer,
                child: FadeTransition(
                  opacity: _drawer,
                  child: ColoredBox(color: meridian.colors.scrim),
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GestureDetector(
              onHorizontalDragUpdate: _dragUpdate,
              onHorizontalDragEnd: _dragEnd,
              child: SlideTransition(
                position:
                    Tween(
                      begin: Offset(rtl ? 1 : -1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _drawer,
                        curve: MeridianDurations.sheetCurve,
                      ),
                    ),
                child: _MeasureWidth(
                  onWidth: (width) => _drawerWidth = width,
                  // Escape reaches the bindings from the scope itself and
                  // from anything focused inside it.
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.escape):
                          closeDrawer,
                    },
                    child: FocusScope(node: _drawerFocus, child: drawer),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
    return frame;
  }
}

class _MeasureWidth extends SingleChildRenderObjectWidget {
  const _MeasureWidth({required this.onWidth, super.child});

  final ValueChanged<double> onWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureWidth(onWidth);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasureWidth renderObject,
  ) => renderObject.onWidth = onWidth;
}

class _RenderMeasureWidth extends RenderProxyBox {
  _RenderMeasureWidth(this.onWidth);

  ValueChanged<double> onWidth;

  @override
  void performLayout() {
    super.performLayout();
    if (size.width > 0) onWidth(size.width);
  }
}
