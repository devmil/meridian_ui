import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'actions.dart';
import 'containers.dart';
import 'inputs.dart';
import 'navigation.dart';

/// One page of a [MeridianSettingsDialog]: its entry in the page list and
/// the settings it shows.
@immutable
class MeridianSettingsPage {
  const MeridianSettingsPage({
    required this.label,
    required this.builder,
    this.icon,
    this.description,
    this.key,
  });

  /// Identifies the page's entry in the page list (for tests and UI
  /// automation).
  final Key? key;

  /// The page list entry and the page heading ("Appearance", "Remote
  /// hosts").
  final String label;

  /// A Meridian icon name for the page list.
  final String? icon;

  /// What the page covers, in `caption` `ink-muted` under its heading.
  final String? description;

  /// The page body, usually one or more [MeridianSettingsGroup]s. The dialog
  /// scrolls it; it is built only while the page is shown.
  final WidgetBuilder builder;
}

/// A settings window: a title bar with a close button, the pages listed on
/// `ground` at the start and the selected page on `raised` beside them.
///
/// Changes apply straight away, so there is no Save or Cancel; the dialog
/// closes with ✕ or Escape. The dialog keeps one height
/// ([MeridianLayout.settingsDialogHeight], at most 85% of the window) while
/// pages change, and each page scrolls on its own from the top. When the
/// dialog is narrower than [MeridianLayout.settingsDialogPagedBreakpoint] or
/// at touch density the page list becomes a select above the page.
/// Up and Down in the page list move to the previous or next page. A
/// [footer] under the pages reports what went wrong with the last change.
///
/// Show it with [showMeridianDialog].
class MeridianSettingsDialog extends StatefulWidget {
  const MeridianSettingsDialog({
    required this.title,
    required this.pages,
    super.key,
    this.initialPage = 0,
    this.page,
    this.onPageChanged,
    this.onClose,
    this.footer,
    this.width = MeridianLayout.settingsDialogWidth,
  }) : assert(pages.length > 0, 'A settings dialog needs at least one page.');

  final String title;
  final List<MeridianSettingsPage> pages;

  /// The index of the page shown first.
  final int initialPage;

  /// The index of the page shown, for apps that move between pages
  /// themselves (a link from one page to another). The dialog then shows
  /// what [onPageChanged] stores here instead of keeping its own page.
  final int? page;

  /// Called with the index of the page the person picked.
  final ValueChanged<int>? onPageChanged;

  /// Runs on ✕. Defaults to popping the dialog's route.
  final VoidCallback? onClose;

  /// A line under the pages for what the person must know about their last
  /// change (a shortcut that is taken, a save that failed). It stays in view
  /// while the page scrolls; keep it to a `caption` in a live region.
  final Widget? footer;

  /// The widest the dialog grows; [MeridianLayout.settingsDialogWidth] by
  /// default.
  final double width;

  @override
  State<MeridianSettingsDialog> createState() => _MeridianSettingsDialogState();
}

class _MeridianSettingsDialogState extends State<MeridianSettingsDialog> {
  late int _ownPage = _clamp(widget.initialPage);
  bool _listFocused = false;

  int _clamp(int index) => index.clamp(0, widget.pages.length - 1);

  int get _page => _clamp(widget.page ?? _ownPage);

  void _select(int index) {
    final next = _clamp(index);
    if (next == _page) return;
    if (widget.page == null) setState(() => _ownPage = next);
    widget.onPageChanged?.call(next);
  }

  void _close() {
    final close = widget.onClose;
    if (close != null) {
      close();
    } else {
      Navigator.maybePop(context);
    }
  }

  /// Up and Down move between pages and take focus along.
  KeyEventResult _onListKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.arrowUp => -1,
      _ => 0,
    };
    if (delta == 0) return KeyEventResult.ignored;
    final next = _page + delta;
    if (next < 0 || next >= widget.pages.length) return KeyEventResult.handled;
    final focused = FocusManager.instance.primaryFocus;
    _select(next);
    if (delta > 0) {
      focused?.nextFocus();
    } else {
      focused?.previousFocus();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final touch = meridian.density.isTouch;
    final inset = touch ? MeridianSpace.space8 : MeridianSpace.space7;
    final screen = MediaQuery.sizeOf(context);
    final page = widget.pages[_page];
    return MeridianDialogSurface(
      maxWidth: widget.width,
      maxHeight: math.min(
        MeridianLayout.settingsDialogHeight,
        screen.height * MeridianLayout.dialogMaxHeightFraction,
      ),
      semanticLabel: widget.title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final paged =
              touch ||
              constraints.maxWidth <
                  MeridianLayout.settingsDialogPagedBreakpoint;
          final body = Expanded(
            child: SingleChildScrollView(
              key: ValueKey(_page),
              padding: EdgeInsets.all(inset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(page.label, style: meridian.text.title),
                  ),
                  if (page.description case final description?) ...[
                    const SizedBox(height: MeridianSpace.space2),
                    Text(
                      description,
                      style: meridian.text.caption.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: MeridianSpace.space7),
                  DefaultTextStyle.merge(
                    style: meridian.text.body,
                    child: Builder(builder: page.builder),
                  ),
                ],
              ),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: inset,
                  end: MeridianSpace.space5,
                  top: MeridianSpace.space5,
                  bottom: MeridianSpace.space4,
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
                          style: meridian.text.title,
                        ),
                      ),
                    ),
                    const SizedBox(width: MeridianSpace.space4),
                    MeridianIconButton(
                      label: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      icon: MeridianIcons.x,
                      onPressed: _close,
                    ),
                  ],
                ),
              ),
              MeridianHairline(color: colors.line),
              if (paged) ...[
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: inset,
                    end: inset,
                    top: MeridianSpace.space5,
                  ),
                  child: MeridianSelect<int>(
                    label: widget.title,
                    value: _page,
                    values: [for (var i = 0; i < widget.pages.length; i++) i],
                    valueLabel: (i) => widget.pages[i].label,
                    expand: true,
                    onChanged: _select,
                  ),
                ),
                body,
              ] else
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: MeridianLayout.settingsDialogPageListWidth,
                        child: ColoredBox(
                          color: colors.ground,
                          child: Focus(
                            canRequestFocus: false,
                            skipTraversal: true,
                            onFocusChange: (focused) =>
                                setState(() => _listFocused = focused),
                            onKeyEvent: _onListKey,
                            child: MeridianSurfaceScope(
                              onGround: true,
                              focused: _listFocused,
                              child: FocusTraversalGroup(
                                child: ListView(
                                  padding: const EdgeInsets.all(
                                    MeridianSpace.space3,
                                  ),
                                  children: [
                                    for (final (i, entry)
                                        in widget.pages.indexed)
                                      MeridianNavRow(
                                        key:
                                            entry.key ??
                                            ValueKey('meridian-settings-$i'),
                                        label: entry.label,
                                        icon: entry.icon,
                                        selected: i == _page,
                                        onTap: () => _select(i),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      MeridianHairline(color: colors.line, axis: Axis.vertical),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [body],
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.footer case final footer?) ...[
                MeridianHairline(color: colors.line),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: inset,
                    vertical: MeridianSpace.space4,
                  ),
                  child: DefaultTextStyle.merge(
                    style: meridian.text.caption,
                    child: footer,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
