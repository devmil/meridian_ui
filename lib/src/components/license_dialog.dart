import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_localizations.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'actions.dart';
import 'containers.dart';
import 'feedback.dart';
import 'inputs.dart';
import 'navigation.dart';
import 'scrollbar.dart';

/// The licenses of an app and everything it bundles: a title bar with a
/// close button, the app and its packages listed on `ground` at the start,
/// and the selected package's licenses on `raised` beside them.
///
/// It reads [LicenseRegistry] (the Flutter engine's notices and every
/// license the app adds with [LicenseRegistry.addLicense]) unless
/// [licenses] supplies the entries. The package list has a filter; Up and
/// Down move between packages. License text is selectable. When the dialog
/// is narrower than [MeridianLayout.licenseDialogPagedBreakpoint] or at
/// touch density, the list and one package's licenses take turns, with a
/// back button in the title bar.
///
/// Show it with [showMeridianLicenses] or [showMeridianDialog].
class MeridianLicenseDialog extends StatefulWidget {
  const MeridianLicenseDialog({
    super.key,
    this.title,
    this.applicationName,
    this.applicationVersion,
    this.applicationIcon,
    this.applicationLegalese,
    this.licenses,
    this.onClose,
    this.width = MeridianLayout.licenseDialogWidth,
  });

  /// The title bar; "Licenses" (localized) by default.
  final String? title;

  /// The app's name, at the top of the package list.
  final String? applicationName;

  /// The app's version, in `caption` under its name.
  final String? applicationVersion;

  /// The app's mark, beside its name. Keep it to about 40px.
  final Widget? applicationIcon;

  /// A copyright line under the version.
  final String? applicationLegalese;

  /// Where the license entries come from; [LicenseRegistry.licenses] by
  /// default. Called once when the dialog opens.
  final Stream<LicenseEntry> Function()? licenses;

  /// Runs on ✕. Defaults to popping the dialog's route.
  final VoidCallback? onClose;

  /// The widest the dialog grows; [MeridianLayout.licenseDialogWidth] by
  /// default.
  final double width;

  @override
  State<MeridianLicenseDialog> createState() => _MeridianLicenseDialogState();
}

/// Shows a [MeridianLicenseDialog] with [showMeridianDialog].
Future<void> showMeridianLicenses({
  required BuildContext context,
  String? title,
  String? applicationName,
  String? applicationVersion,
  Widget? applicationIcon,
  String? applicationLegalese,
  Stream<LicenseEntry> Function()? licenses,
}) => showMeridianDialog<void>(
  context: context,
  builder: (_) => MeridianLicenseDialog(
    title: title,
    applicationName: applicationName,
    applicationVersion: applicationVersion,
    applicationIcon: applicationIcon,
    applicationLegalese: applicationLegalese,
    licenses: licenses,
  ),
);

class _LicensePackage {
  _LicensePackage(this.name);

  final String name;
  final List<LicenseEntry> entries = [];

  /// The paragraphs of every entry, parsed the first time the package is
  /// shown; `null` marks the line between two licenses.
  late final List<LicenseParagraph?> paragraphs = [
    for (final (i, entry) in entries.indexed) ...[
      if (i > 0) null,
      ...entry.paragraphs,
    ],
  ];
}

class _MeridianLicenseDialogState extends State<MeridianLicenseDialog> {
  List<_LicensePackage>? _packages;
  Object? _error;
  StreamSubscription<LicenseEntry>? _subscription;
  String? _selected;
  bool _showingPackage = false;
  bool _listFocused = false;
  String _query = '';
  final _filter = TextEditingController();
  final _listScroll = ScrollController();
  final _textScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final byName = <String, _LicensePackage>{};
    final source = widget.licenses ?? () => LicenseRegistry.licenses;
    _subscription = source().listen(
      (entry) {
        for (final name in entry.packages) {
          byName
              .putIfAbsent(name, () => _LicensePackage(name))
              .entries
              .add(entry);
        }
      },
      onError: (Object error) {
        if (mounted) setState(() => _error = error);
      },
      onDone: () {
        if (!mounted) return;
        final packages = byName.values.toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        setState(() {
          _packages = packages;
          _selected ??= packages.firstOrNull?.name;
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _filter.dispose();
    _listScroll.dispose();
    _textScroll.dispose();
    super.dispose();
  }

  List<_LicensePackage> get _visible {
    final packages = _packages ?? const [];
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return packages;
    return [
      for (final package in packages)
        if (package.name.toLowerCase().contains(query)) package,
    ];
  }

  _LicensePackage? get _selectedPackage {
    for (final package in _packages ?? const <_LicensePackage>[]) {
      if (package.name == _selected) return package;
    }
    return null;
  }

  void _select(String name) {
    setState(() {
      _showingPackage = true;
      if (name == _selected) return;
      _selected = name;
      if (_textScroll.hasClients) _textScroll.jumpTo(0);
    });
  }

  void _close() {
    final close = widget.onClose;
    if (close != null) {
      close();
    } else {
      Navigator.maybePop(context);
    }
  }

  /// Up and Down move between packages and take focus along.
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
    final visible = _visible;
    final index = visible.indexWhere((p) => p.name == _selected);
    final next = index + delta;
    if (index < 0 || next < 0 || next >= visible.length) {
      return KeyEventResult.handled;
    }
    final focused = FocusManager.instance.primaryFocus;
    _select(visible[next].name);
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
    final l10n = MeridianLocalizations.of(context);
    final touch = meridian.density.isTouch;
    final inset = touch ? MeridianSpace.space8 : MeridianSpace.space7;
    final screen = MediaQuery.sizeOf(context);
    final title = widget.title ?? l10n.licensesTitle;
    return MeridianDialogSurface(
      maxWidth: widget.width,
      maxHeight: math.min(
        MeridianLayout.licenseDialogHeight,
        screen.height * MeridianLayout.dialogMaxHeightFraction,
      ),
      semanticLabel: title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final paged =
              touch ||
              constraints.maxWidth <
                  MeridianLayout.licenseDialogPagedBreakpoint;
          final showPackage = paged && _showingPackage;
          final Widget body;
          if (_packages == null && _error == null) {
            body = Center(
              child: MeridianEmptyState(
                title: l10n.loading,
                progress: true,
                compact: true,
              ),
            );
          } else if (!paged) {
            body = Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: MeridianLayout.licenseDialogPackageListWidth,
                  child: _packageList(context, colors.ground),
                ),
                MeridianHairline(color: colors.line, axis: Axis.vertical),
                Expanded(child: _packageText(context, inset)),
              ],
            );
          } else if (showPackage) {
            body = _packageText(context, inset);
          } else {
            body = _packageList(context, colors.raised);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: showPackage ? MeridianSpace.space5 : inset,
                  end: MeridianSpace.space5,
                  top: MeridianSpace.space5,
                  bottom: MeridianSpace.space4,
                ),
                child: Row(
                  children: [
                    if (showPackage) ...[
                      MeridianIconButton(
                        key: const Key('meridian-licenses-back'),
                        label: l10n.licensesBack,
                        icon: MeridianIcons.arrowLeft,
                        onPressed: () =>
                            setState(() => _showingPackage = false),
                      ),
                      const SizedBox(width: MeridianSpace.space3),
                    ],
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
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
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }

  Widget _applicationHeader(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final name = widget.applicationName;
    final version = widget.applicationVersion;
    final legalese = widget.applicationLegalese;
    final icon = widget.applicationIcon;
    if (name == null && version == null && legalese == null && icon == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MeridianSpace.space4,
        MeridianSpace.space5,
        MeridianSpace.space4,
        MeridianSpace.space4,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            ExcludeSemantics(child: icon),
            const SizedBox(width: MeridianSpace.space4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (name != null) Text(name, style: meridian.text.bodyStrong),
                if (version != null)
                  Text(
                    version,
                    style: meridian.text.caption.copyWith(
                      color: meridian.colors.inkMuted,
                    ),
                  ),
                if (legalese != null)
                  Text(
                    legalese,
                    style: meridian.text.caption.copyWith(
                      color: meridian.colors.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _packageList(BuildContext context, Color background) {
    final l10n = MeridianLocalizations.of(context);
    final visible = _visible;
    return ColoredBox(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _applicationHeader(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MeridianSpace.space3,
              MeridianSpace.space3,
              MeridianSpace.space3,
              MeridianSpace.space2,
            ),
            child: MeridianTextField(
              key: const Key('meridian-licenses-filter'),
              controller: _filter,
              variant: MeridianTextFieldVariant.search,
              placeholder: l10n.licensesFilter,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: _error != null
                ? Center(
                    child: MeridianEmptyState(
                      title: '$_error',
                      icon: MeridianIcons.circleAlert,
                      compact: true,
                    ),
                  )
                : visible.isEmpty
                ? Center(
                    child: MeridianEmptyState(
                      title: l10n.licensesNoMatches,
                      icon: MeridianIcons.search,
                      compact: true,
                    ),
                  )
                : Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    onFocusChange: (focused) =>
                        setState(() => _listFocused = focused),
                    onKeyEvent: _onListKey,
                    child: MeridianSurfaceScope(
                      onGround:
                          background == MeridianTheme.of(context).colors.ground,
                      focused: _listFocused,
                      child: FocusTraversalGroup(
                        child: MeridianScrollbar(
                          controller: _listScroll,
                          child: ListView.builder(
                            controller: _listScroll,
                            padding: const EdgeInsets.all(MeridianSpace.space3),
                            itemCount: visible.length,
                            itemBuilder: (context, i) {
                              final package = visible[i];
                              return MeridianNavRow(
                                key: ValueKey(
                                  'meridian-license-${package.name}',
                                ),
                                label: package.name,
                                count: package.entries.length,
                                selected: package.name == _selected,
                                onTap: () => _select(package.name),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _packageText(BuildContext context, double inset) {
    final meridian = MeridianTheme.of(context);
    final l10n = MeridianLocalizations.of(context);
    final package = _selectedPackage;
    if (package == null) return const SizedBox.shrink();
    final paragraphs = package.paragraphs;
    return MeridianScrollbar(
      controller: _textScroll,
      visibility: MeridianScrollbarVisibility.always,
      child: SelectionArea(
        child: ListView.builder(
          key: ValueKey(package.name),
          controller: _textScroll,
          padding: EdgeInsets.all(inset),
          itemCount: paragraphs.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: MeridianSpace.space6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(package.name, style: meridian.text.title),
                    ),
                    const SizedBox(height: MeridianSpace.space2),
                    Text(
                      l10n.licensesCount(package.entries.length),
                      style: meridian.text.caption.copyWith(
                        color: meridian.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              );
            }
            final paragraph = paragraphs[i - 1];
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: MeridianLayout.licenseTextMaxWidth,
                ),
                child: paragraph == null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: MeridianSpace.space6,
                        ),
                        child: MeridianHairline(color: meridian.colors.line),
                      )
                    : _LicenseParagraphText(paragraph),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LicenseParagraphText extends StatelessWidget {
  const _LicenseParagraphText(this.paragraph);

  final LicenseParagraph paragraph;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final centered = paragraph.indent == LicenseParagraph.centeredIndent;
    final text = Text(
      paragraph.text,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: meridian.text.caption.copyWith(color: meridian.colors.ink),
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: centered ? 0 : paragraph.indent * MeridianLayout.licenseIndent,
        bottom: MeridianSpace.space4,
      ),
      child: centered ? SizedBox(width: double.infinity, child: text) : text,
    );
  }
}
