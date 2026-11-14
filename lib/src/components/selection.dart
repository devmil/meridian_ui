import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../foundation/meridian_localizations.dart';
import '../foundation/meridian_theme.dart';
import 'menu.dart';

/// What a text menu (cut, copy, paste, select all) shows and where: the
/// editing actions of a text field or a selection, and the point to open
/// at. Call [hide] once the menu is gone.
@immutable
class MeridianTextMenuRequest {
  const MeridianTextMenuRequest({
    required this.items,
    required this.anchors,
    required this.hide,
  });

  /// From an [EditableText] (a `MeridianTextField`).
  MeridianTextMenuRequest.editable(EditableTextState state)
    : this(
        items: state.contextMenuButtonItems,
        anchors: state.contextMenuAnchors,
        hide: state.hideToolbar,
      );

  /// From a [SelectableRegion] (a `MeridianSelectionArea`).
  MeridianTextMenuRequest.selectable(SelectableRegionState state)
    : this(
        items: state.contextMenuButtonItems,
        anchors: state.contextMenuAnchors,
        hide: state.hideToolbar,
      );

  final List<ContextMenuButtonItem> items;
  final TextSelectionToolbarAnchors anchors;
  final VoidCallback hide;
}

/// Builds the menu for a [MeridianTextMenuRequest]: [meridianTextMenu] by
/// default, a native menu under `MeridianNativeMenus`.
typedef MeridianTextMenuBuilder = Widget Function(
  BuildContext context,
  MeridianTextMenuRequest request,
);

/// The label of a text editing action ("Copy", "Kopieren").
String meridianTextMenuLabel(BuildContext context, ContextMenuButtonItem item) {
  if (item.label case final label?) return label;
  final widgets = WidgetsLocalizations.of(context);
  final meridian = MeridianLocalizations.of(context);
  return switch (item.type) {
    ContextMenuButtonType.cut => widgets.cutButtonLabel,
    ContextMenuButtonType.copy => widgets.copyButtonLabel,
    ContextMenuButtonType.paste => widgets.pasteButtonLabel,
    ContextMenuButtonType.selectAll => widgets.selectAllButtonLabel,
    ContextMenuButtonType.lookUp => widgets.lookUpButtonLabel,
    ContextMenuButtonType.searchWeb => widgets.searchWebButtonLabel,
    ContextMenuButtonType.share => widgets.shareButtonLabel,
    ContextMenuButtonType.delete => meridian.textDelete,
    ContextMenuButtonType.liveTextInput => meridian.textScan,
    ContextMenuButtonType.custom => '',
  };
}

/// Meridian's text menu: the editing actions as a Meridian menu at the
/// pointer or above the selection. It does not take focus, so the field
/// or selection keeps it.
Widget meridianTextMenu(
  BuildContext context,
  MeridianTextMenuRequest request,
) => _MeridianTextMenu(request: request);

/// The builder a [MeridianTextMenuBuilder] resolves to: [builder], else
/// the app's `MeridianMenuPresenter.textContextMenuBuilder`, else
/// [meridianTextMenu].
MeridianTextMenuBuilder resolveMeridianTextMenu(
  BuildContext context, [
  MeridianTextMenuBuilder? builder,
]) =>
    builder ??
    MeridianMenuPresenter.maybeOf(context)?.textContextMenuBuilder ??
    meridianTextMenu;

class _MeridianTextMenu extends StatelessWidget {
  const _MeridianTextMenu({required this.request});

  final MeridianTextMenuRequest request;

  @override
  Widget build(BuildContext context) {
    final entries = <MeridianMenuEntry>[
      for (final item in request.items)
        MeridianMenuItem(
          label: meridianTextMenuLabel(context, item),
          onSelected: item.onPressed,
        ),
    ];
    if (entries.isEmpty) return const SizedBox.shrink();
    return CustomSingleChildLayout(
      delegate: DesktopTextSelectionToolbarLayoutDelegate(
        anchor: request.anchors.primaryAnchor,
      ),
      child: MeridianMenuSurface(
        entries: entries,
        autofocus: false,
        onSelected: (item) => item.onSelected?.call(),
        onDismiss: request.hide,
      ),
    );
  }
}

/// Selection handles for touch: an `accent` drop under each end of the
/// selection (and under the caret of a field), 22px.
class MeridianTextSelectionControls extends TextSelectionControls
    with TextSelectionHandleControls {
  static const double _size = 22;

  @override
  Size getHandleSize(double textLineHeight) => const Size(_size, _size);

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      switch (type) {
        TextSelectionHandleType.left => const Offset(_size, 0),
        TextSelectionHandleType.right => Offset.zero,
        TextSelectionHandleType.collapsed => const Offset(_size / 2, -4),
      };

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    final color = MeridianTheme.of(context).colors.accent;
    final handle = SizedBox.square(
      dimension: _size,
      child: CustomPaint(painter: _HandlePainter(color)),
    );
    final turned = switch (type) {
      TextSelectionHandleType.left => Transform.rotate(
        angle: math.pi / 2,
        child: handle,
      ),
      TextSelectionHandleType.right => handle,
      TextSelectionHandleType.collapsed => Transform.rotate(
        angle: math.pi / 4,
        child: handle,
      ),
    };
    return GestureDetector(
      onTap: onTap,
      dragStartBehavior: DragStartBehavior.down,
      child: turned,
    );
  }
}

/// The shared [MeridianTextSelectionControls].
final meridianTextSelectionControls = MeridianTextSelectionControls();

class _HandlePainter extends CustomPainter {
  const _HandlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = size.width / 2;
    final circle = Rect.fromCircle(
      center: Offset(radius, radius),
      radius: radius,
    );
    final point = Rect.fromLTWH(0, 0, radius, radius);
    canvas.drawPath(
      Path()
        ..addOval(circle)
        ..addRect(point),
      paint,
    );
  }

  @override
  bool shouldRepaint(_HandlePainter oldDelegate) => color != oldDelegate.color;
}

/// Makes the text in [child] selectable with the pointer, the keyboard
/// (Shift+arrows, select all) and touch handles, and copyable through
/// [contextMenuBuilder] (the app's text menu by default). Selection uses
/// `accent-soft`. Built on the widgets layer's [SelectableRegion].
class MeridianSelectionArea extends StatefulWidget {
  const MeridianSelectionArea({
    required this.child,
    super.key,
    this.focusNode,
    this.contextMenuBuilder,
    this.onSelectionChanged,
  });

  final Widget child;
  final FocusNode? focusNode;

  /// The menu on a secondary click or long press.
  final MeridianTextMenuBuilder? contextMenuBuilder;

  /// Called with the selected content as it changes.
  final ValueChanged<SelectedContent?>? onSelectionChanged;

  @override
  State<MeridianSelectionArea> createState() => _MeridianSelectionAreaState();
}

class _MeridianSelectionAreaState extends State<MeridianSelectionArea> {
  FocusNode? _ownFocus;

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'MeridianSelectionArea'));

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = resolveMeridianTextMenu(context, widget.contextMenuBuilder);
    final colors = MeridianTheme.of(context).colors;
    return DefaultSelectionStyle(
      selectionColor: colors.accentSoft,
      cursorColor: colors.accent,
      child: SelectableRegion(
        focusNode: _focus,
        selectionControls: meridianTextSelectionControls,
        onSelectionChanged: widget.onSelectionChanged,
        contextMenuBuilder: (context, state) =>
            menu(context, MeridianTextMenuRequest.selectable(state)),
        child: widget.child,
      ),
    );
  }
}

/// Text the person can select and copy: a [Text] in a
/// [MeridianSelectionArea]. Use it for values people copy (a hash, a path,
/// an error), not for labels.
class MeridianSelectableText extends StatelessWidget {
  const MeridianSelectableText(
    String this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticsLabel,
    this.contextMenuBuilder,
    this.focusNode,
  }) : span = null;

  const MeridianSelectableText.rich(
    InlineSpan this.span, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticsLabel,
    this.contextMenuBuilder,
    this.focusNode,
  }) : data = null;

  final String? data;
  final InlineSpan? span;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? semanticsLabel;
  final MeridianTextMenuBuilder? contextMenuBuilder;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => MeridianSelectionArea(
    focusNode: focusNode,
    contextMenuBuilder: contextMenuBuilder,
    child: Text.rich(
      span ?? TextSpan(text: data),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      semanticsLabel: semanticsLabel,
    ),
  );
}
