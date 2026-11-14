import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_localizations.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'actions.dart';
import 'inputs.dart';

/// The strings a [MeridianFindBar] shows or announces. Each unset one falls
/// back to [MeridianLocalizations].
@immutable
class MeridianFindBarLabels {
  const MeridianFindBarLabels({
    this.placeholder,
    this.previous,
    this.next,
    this.caseSensitive,
    this.wholeWord,
    this.regex,
    this.clear,
    this.close,
    this.position,
    this.count,
    this.noMatches,
    this.searching,
  });

  /// The field's placeholder and accessible name ("Find in diff").
  final String? placeholder;
  final String? previous;
  final String? next;
  final String? caseSensitive;
  final String? wholeWord;
  final String? regex;
  final String? clear;
  final String? close;

  /// "3 of 12": the current match (from 1) of all matches.
  final String Function(int current, int total)? position;

  /// "12 matches", while no match is current.
  final String Function(int total)? count;
  final String? noMatches;
  final String? searching;
}

/// Finds text in the content it sits above: a search field with the
/// position of the current match ("3 of 12"), Previous and Next, optional
/// toggles for case, whole words and regular expressions, the owner's own
/// [trailing] controls (search scopes, a filter) and Close.
///
/// The bar is controlled: the owner searches and reports [matchCount],
/// [currentMatch] and [searching]. Typing calls [onChanged]; Enter calls
/// [onNext] and Shift+Enter [onPrevious], also before the first search (so
/// the owner can run a search on Enter); the buttons step through matches
/// once there are some. Escape clears the query (calling [onChanged] with
/// the empty text) and, on an empty field, calls [onClose].
///
/// It sits in a toolbar or a pane header, so it is `small` by default. The
/// field is [fieldWidth] wide and gives way first when space runs out; when
/// even the narrowest field does not fit beside the buttons, the field
/// takes the whole width and the buttons move below it.
/// [visible] reveals and collapses it, at once under reduced motion.
class MeridianFindBar extends StatefulWidget {
  const MeridianFindBar({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onNext,
    this.onPrevious,
    this.onClose,
    this.matchCount = 0,
    this.currentMatch,
    this.searching = false,
    this.caseSensitive = false,
    this.onCaseSensitiveChanged,
    this.wholeWord = false,
    this.onWholeWordChanged,
    this.regex = false,
    this.onRegexChanged,
    this.trailing = const [],
    this.labels = const MeridianFindBarLabels(),
    this.size = MeridianControlSize.small,
    this.fieldWidth = MeridianLayout.findFieldWidth,
    this.autofocus = false,
    this.enabled = true,
    this.visible = true,
    this.error,
    this.fieldKey,
  });

  /// The query. The bar keeps its own when `null`.
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Every edit of the query, and the empty query after Escape clears it.
  final ValueChanged<String>? onChanged;

  /// The next match: Enter, the Next button.
  final VoidCallback? onNext;

  /// The previous match: Shift+Enter, the Previous button.
  final VoidCallback? onPrevious;

  /// Closes the bar: the Close button, and Escape on an empty field. No
  /// Close button when `null`.
  final VoidCallback? onClose;

  /// How many matches the query has.
  final int matchCount;

  /// The current match, from 0; `null` while none is current.
  final int? currentMatch;

  /// A search is running: the counter says so.
  final bool searching;

  /// The case toggle; shown when [onCaseSensitiveChanged] is set.
  final bool caseSensitive;
  final ValueChanged<bool>? onCaseSensitiveChanged;

  /// The whole-word toggle; shown when [onWholeWordChanged] is set.
  final bool wholeWord;
  final ValueChanged<bool>? onWholeWordChanged;

  /// The regular-expression toggle; shown when [onRegexChanged] is set.
  final bool regex;
  final ValueChanged<bool>? onRegexChanged;

  /// The owner's own controls after the toggles (search scopes, apply a
  /// filter): small icon buttons.
  final List<Widget> trailing;
  final MeridianFindBarLabels labels;
  final MeridianControlSize size;

  /// The field's width when there is room.
  final double fieldWidth;
  final bool autofocus;
  final bool enabled;

  /// Reveals and collapses the bar.
  final bool visible;

  /// A query the owner cannot search (an invalid regular expression),
  /// shown under the field.
  final String? error;
  final Key? fieldKey;

  @override
  State<MeridianFindBar> createState() => _MeridianFindBarState();
}

class _MeridianFindBarState extends State<MeridianFindBar> {
  TextEditingController? _ownedController;
  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());
  FocusNode? _ownedFocus;
  FocusNode get _focus =>
      widget.focusNode ?? (_ownedFocus ??= FocusNode(debugLabel: 'find'));

  @override
  void dispose() {
    _ownedController?.dispose();
    _ownedFocus?.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!widget.enabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (_controller.text.isNotEmpty) {
        _controller.clear();
        widget.onChanged?.call('');
        return KeyEventResult.handled;
      }
      final close = widget.onClose;
      if (close == null) return KeyEventResult.ignored;
      close();
      return KeyEventResult.handled;
    }
    // Enter and Shift+Enter step only from the field; buttons keep Enter.
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        _focus.hasPrimaryFocus) {
      final shift = HardwareKeyboard.instance.isShiftPressed;
      final step = shift ? widget.onPrevious : widget.onNext;
      if (step == null) return KeyEventResult.ignored;
      step();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String? _counter(MeridianLocalizations l10n) {
    final labels = widget.labels;
    if (widget.searching) return labels.searching ?? l10n.findSearching;
    if (_controller.text.isEmpty) return null;
    final total = widget.matchCount;
    if (total <= 0) return labels.noMatches ?? l10n.findNoMatches;
    final current = widget.currentMatch;
    if (current == null || current < 0 || current >= total) {
      return labels.count?.call(total) ?? l10n.findMatchCount(total);
    }
    return labels.position?.call(current + 1, total) ??
        l10n.findMatchPosition(current + 1, total);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MeridianLocalizations.of(context);
    final labels = widget.labels;
    final enabled = widget.enabled;
    final hasMatches = enabled && widget.matchCount > 0;
    final placeholder = labels.placeholder ?? l10n.findPlaceholder;
    Widget toggle(
      String key,
      String icon,
      String label,
      bool value,
      ValueChanged<bool>? onChanged,
    ) => MeridianIconButton(
      key: ValueKey('meridian-find-$key'),
      label: label,
      icon: icon,
      size: widget.size,
      active: value,
      onPressed: enabled && onChanged != null ? () => onChanged(!value) : null,
    );
    Widget field(double width) => ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => MeridianTextField(
        fieldKey: widget.fieldKey,
        controller: _controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        enabled: enabled,
        width: width,
        variant: MeridianTextFieldVariant.search,
        size: widget.size,
        label: placeholder,
        showLabel: false,
        placeholder: placeholder,
        trailingText: _counter(l10n),
        error: widget.error,
        clearLabel: labels.clear ?? l10n.findClear,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        enableSuggestions: false,
        submitsDialog: false,
        onChanged: widget.onChanged,
        // A soft keyboard's search key; hardware Enter is
        // handled above, with Shift.
        onSubmitted: (_) {
          widget.onNext?.call();
          _focus.requestFocus();
        },
      ),
    );
    final buttons = <Widget>[
      MeridianIconButton(
        key: const ValueKey('meridian-find-previous'),
        label: labels.previous ?? l10n.findPrevious,
        icon: MeridianIcons.chevronUp,
        size: widget.size,
        onPressed: hasMatches ? widget.onPrevious : null,
      ),
      MeridianIconButton(
        key: const ValueKey('meridian-find-next'),
        label: labels.next ?? l10n.findNext,
        icon: MeridianIcons.chevronDown,
        size: widget.size,
        onPressed: hasMatches ? widget.onNext : null,
      ),
      if (widget.onCaseSensitiveChanged != null)
        toggle(
          'case',
          MeridianIcons.caseSensitive,
          labels.caseSensitive ?? l10n.findCaseSensitive,
          widget.caseSensitive,
          widget.onCaseSensitiveChanged,
        ),
      if (widget.onWholeWordChanged != null)
        toggle(
          'word',
          MeridianIcons.wholeWord,
          labels.wholeWord ?? l10n.findWholeWord,
          widget.wholeWord,
          widget.onWholeWordChanged,
        ),
      if (widget.onRegexChanged != null)
        toggle(
          'regex',
          MeridianIcons.regex,
          labels.regex ?? l10n.findRegex,
          widget.regex,
          widget.onRegexChanged,
        ),
      ...widget.trailing,
      if (widget.onClose case final close?) ...[
        const SizedBox(width: MeridianSpace.space1),
        MeridianIconButton(
          key: const ValueKey('meridian-find-close'),
          label: labels.close ?? l10n.findClose,
          icon: MeridianIcons.x,
          size: widget.size,
          onPressed: close,
        ),
      ],
    ];
    final density = MeridianTheme.of(context).density;
    final buttonExtent = math.max(
      density.minTarget,
      widget.size == MeridianControlSize.small
          ? density.controlSmallExtent
          : density.controlExtent,
    );
    final buttonCount =
        2 +
        (widget.onCaseSensitiveChanged == null ? 0 : 1) +
        (widget.onWholeWordChanged == null ? 0 : 1) +
        (widget.onRegexChanged == null ? 0 : 1) +
        widget.trailing.length +
        (widget.onClose == null ? 0 : 1);
    final buttonsWidth =
        buttonCount * buttonExtent +
        (widget.onClose == null ? 1 : 2) * MeridianSpace.space1;
    final bar = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final room = constraints.maxWidth - buttonsWidth;
          // The narrowest field that still shows its counter and clear
          // button at the current text size.
          final minField =
              MediaQuery.textScalerOf(context)
                  .scale(MeridianLayout.findFieldMinWidth) +
              buttonExtent;
          if (!constraints.hasBoundedWidth || room >= minField) {
            // The field gives way first, down to a usable minimum.
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                field(
                  constraints.hasBoundedWidth
                      ? math.min(math.max(widget.fieldWidth, minField), room)
                      : math.max(widget.fieldWidth, minField),
                ),
                const SizedBox(width: MeridianSpace.space1),
                ...buttons,
              ],
            );
          }
          // Too narrow for one line: the field above, the buttons below.
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              field(constraints.maxWidth),
              const SizedBox(height: MeridianSpace.space1),
              Wrap(alignment: WrapAlignment.end, children: buttons),
            ],
          );
        },
      ),
    );
    return MeridianReveal(
      visible: widget.visible,
      axis: Axis.vertical,
      child: Semantics(container: true, explicitChildNodes: true, child: bar),
    );
  }
}
