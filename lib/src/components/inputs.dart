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
import 'menu.dart';

/// `accent` brightened by the primary hover overlay: the hover of a
/// checked box, a chosen radio and an on switch.
Color _accentHover(MeridianColors colors) => Color.alphaBlend(
  colors.onAccent.withValues(alpha: MeridianOpacity.primaryHoverOverlay),
  colors.accent,
);

const _pill = BorderRadius.all(Radius.circular(MeridianRadiusScale.pill));

/// Text field variants. [search] is a filled `pane-alt` well with no edge
/// until focused, for filters in headers and toolbars. [plain] has no well,
/// edge or ring: the entry of a form row whose container draws the boundary
/// and shows focus (a mail subject line, recipients between chips).
enum MeridianTextFieldVariant { standard, search, plain }

/// Single- or multi-line text input.
///
/// The edge is `control-edge` (3:1); focus adds a 1px `focus` ring on a
/// `focus` edge. The label sits above (or to the left in a settings row),
/// never floating inside. An [error] replaces [message] below the field and
/// says what is wrong and how to fix it.
class MeridianTextField extends StatefulWidget {
  const MeridianTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.placeholder,
    this.icon,
    this.trailingText,
    this.trailing,
    this.variant = MeridianTextFieldVariant.standard,
    this.size = MeridianControlSize.regular,
    this.error,
    this.message,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.monospace = false,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.width,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
    this.textStyle,
    this.fieldKey,
    this.showLabel = true,
    this.expands = false,
    this.scrollController,
    this.spellCheckConfiguration,
    this.height,
    this.contextMenuBuilder,
    this.onTap,
    this.clearLabel,
    this.rejectCount = 0,
    this.programmaticClearSequence = 0,
    this.submitsDialog = true,
    this.underlay,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Shown above the field and used as the accessible name.
  final String? label;
  final String? placeholder;

  /// Leading icon; the search variant defaults to `search`.
  final String? icon;

  /// Trailing text such as a match counter or character count.
  final String? trailingText;

  /// A trailing widget such as a clear button.
  final Widget? trailing;
  final MeridianTextFieldVariant variant;
  final MeridianControlSize size;
  final String? error;
  final String? message;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;

  /// Use the `code` style (identifiers, paths, commands).
  final bool monospace;

  /// With [minLines] above [maxLines] (for example only `minLines: 3`), the
  /// field grows without a limit.
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final double? width;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool autocorrect;
  final bool enableSuggestions;
  final Iterable<String>? autofillHints;
  final TextStyle? textStyle;

  /// Key of the inner editable [TextField], for tests and focus lookups.
  final Key? fieldKey;

  /// `false` keeps [label] as the accessible name without showing it, for
  /// fields whose purpose is plain from their surroundings (a palette
  /// query, a filter next to its list).
  final bool showLabel;

  /// Fill the parent's height (a merge result editor). Needs a bounded
  /// height and leaves [minLines] and [maxLines] unset.
  final bool expands;

  /// Reads and drives the scroll offset of a multi-line field, for an owner
  /// that keeps the field in step with another pane (a merge result beside
  /// its sources). The owner disposes it.
  final ScrollController? scrollController;
  final SpellCheckConfiguration? spellCheckConfiguration;

  /// Minimum single-line control height, for a field that leads a
  /// form (a composer's subject line). Multi-line fields size to their
  /// lines.
  final double? height;

  /// The cut, copy and paste menu. Defaults to the enclosing
  /// [MeridianMenuPresenter]'s `textContextMenuBuilder`, else Flutter's
  /// adaptive toolbar.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Called when the field is tapped (a search field that opens its
  /// options).
  final VoidCallback? onTap;

  /// Shows a clear button while the field has text; the label is its
  /// tooltip and accessible name ("Clear search"). Clearing calls
  /// [onChanged] with the empty text and leaves focus where it was.
  final String? clearLabel;

  /// Increment when a submit is rejected; the field shakes once (MM-09).
  /// A new [error] without a new count does not shake.
  final int rejectCount;

  /// Increment when the owner clears [controller] programmatically. The old
  /// text fades out while the same editable field (and its focus) stays put.
  /// Ordinary edits and the field's clear button do not animate this way.
  final int programmaticClearSequence;

  /// Inside a [MeridianDialog] (or another [MeridianDialogSubmitScope]),
  /// Enter in a single-line field without its own [onSubmitted] runs the
  /// dialog's primary action, or shakes the dialog when that action is
  /// disabled, and keeps focus in the field. `false` opts this field out:
  /// Enter then only ends editing.
  final bool submitsDialog;

  /// Painted inside the well, under the text, its selection and the caret,
  /// at the size of the text area: marks an editor draws behind its lines
  /// (a merge result's chosen blocks). It takes no pointer input and is not
  /// announced. Keep it in step with the text and [scrollController] itself.
  final Widget? underlay;

  @override
  State<MeridianTextField> createState() => _MeridianTextFieldState();
}

class _MeridianTextFieldState extends State<MeridianTextField>
    with SingleTickerProviderStateMixin {
  FocusNode? _ownedFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());
  TextEditingController? _ownedController;
  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());
  var _hovered = false;
  late var _hasText = _controller.text.isNotEmpty;
  late String _lastText = _controller.text;
  String? _outgoingText;
  late final AnimationController _clearFade = AnimationController(vsync: this);

  /// Focus changed since the last build: the edge and halo take
  /// `motion-quick` instead of the hover timing (MM-08).
  var _focusChanged = false;
  var _wasFocused = false;

  /// The last note shown and whether it was an error, kept while it
  /// leaves (MM-09).
  String? _lastNote;
  var _lastNoteError = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_changed);
    _controller.addListener(_textChanged);
  }

  void _textChanged() {
    if (_controller.text.isNotEmpty) {
      _lastText = _controller.text;
      if (_clearFade.isAnimating) _clearFade.value = 1;
    }
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText && mounted) setState(() => _hasText = hasText);
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  /// Enter in a single-line field inside a dialog: the dialog's primary
  /// action, read when the key is pressed.
  void _submitDialog() =>
      MeridianDialogSubmitScope.maybeOf(context, listen: false)?.call();

  @override
  void didUpdateWidget(covariant MeridianTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.programmaticClearSequence !=
            oldWidget.programmaticClearSequence &&
        _controller.text.isEmpty &&
        _lastText.isNotEmpty) {
      _outgoingText = _lastText;
      _lastText = '';
      _clearFade
        ..duration = MeridianMotion.fade(context, MeridianDurations.quick)
        ..forward(from: 0);
    }
    if (!widget.enabled) _hovered = false;
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownedController)?.removeListener(_textChanged);
      _controller.addListener(_textChanged);
      _hasText = _controller.text.isNotEmpty;
      _lastText = _controller.text;
    }
    if (oldWidget.focusNode == widget.focusNode) return;
    (oldWidget.focusNode ?? _ownedFocusNode)?.removeListener(_changed);
    _focusNode.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _setHovered(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  @override
  void dispose() {
    _clearFade.dispose();
    _focusNode.removeListener(_changed);
    _controller.removeListener(_textChanged);
    _ownedFocusNode?.dispose();
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final text = meridian.text;
    final density = meridian.density;
    final enabled = widget.enabled;
    final focused = _focusNode.hasFocus && enabled;
    _focusChanged = focused != _wasFocused;
    _wasFocused = focused;
    final hovered = _hovered && enabled && !focused;
    final search = widget.variant == MeridianTextFieldVariant.search;
    final plain = widget.variant == MeridianTextFieldVariant.plain;
    final small = widget.size == MeridianControlSize.small;
    final obscure = widget.obscureText;
    final expands = widget.expands && !obscure;
    final minLines = obscure || expands ? null : widget.minLines;
    final maxLines = switch ((minLines, widget.maxLines)) {
      _ when obscure => 1,
      _ when expands => null,
      (final min?, final max?) when min > max => null,
      (_, final max) => max,
    };
    final area = expands || maxLines != 1 || minLines != null;
    final submitsDialog =
        widget.onSubmitted == null &&
        widget.submitsDialog &&
        !area &&
        !widget.readOnly &&
        MeridianDialogSubmitScope.maybeOf(context) != null;
    final error = widget.error;
    final icon = widget.icon ?? (search ? MeridianIcons.search : null);
    final edge = plain
        ? meridianClear(colors.controlEdge)
        : !enabled
        ? colors.line
        : error != null
        ? colors.danger
        : focused
        ? colors.focus
        : hovered
        ? (search ? colors.lineStrong : colors.inkMuted)
        : search
        ? meridianClear(colors.lineStrong)
        : colors.controlEdge;
    final baseStyle =
        widget.textStyle ??
        (widget.monospace
            ? text.code
            : small && !density.isTouch
            ? text.caption
            : text.body);
    // The editable line uses the ambient scaler even with small chrome.
    final line = TextPainter(
      text: TextSpan(text: 'Mg', style: baseStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final lineHeight = line.height;
    line.dispose();
    final singleLineHeight = math.max(
      widget.height ??
          (small ? density.controlSmallExtent : density.controlExtent),
      lineHeight.ceilToDouble() + MeridianLayout.hairline * 2,
    );
    final radius = BorderRadius.circular(meridian.radius.md);
    final well = plain
        ? meridianClear(colors.pane)
        : !enabled || (search && !focused)
        ? colors.paneAlt
        : colors.pane;
    final chrome = AnimatedContainer(
      duration: _focusChanged
          ? MeridianMotion.of(context, MeridianDurations.quick)
          : meridianHoverDuration(context, hovered),
      curve: _focusChanged
          ? MeridianDurations.quickCurve
          : MeridianDurations.hoverCurve,
      height: area ? null : singleLineHeight,
      constraints: BoxConstraints(
        minWidth: widget.width ?? MeridianLayout.textFieldMinWidth,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: plain
            ? 0
            : density.isTouch
            ? MeridianSpace.space5
            : MeridianSpace.space4,
        vertical: area ? MeridianSpace.space3 : 0,
      ),
      decoration: BoxDecoration(
        color: well,
        border: Border.all(color: edge),
        borderRadius: radius,
        // The 1px halo grows from 0 on focus (MM-08).
        boxShadow: plain
            ? null
            : [
                BoxShadow(
                  color: focused
                      ? (error != null ? colors.danger : colors.focus)
                      : meridianClear(
                          error != null ? colors.danger : colors.focus,
                        ),
                  spreadRadius: focused ? MeridianLayout.hairline : 0,
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: expands
            ? CrossAxisAlignment.stretch
            : area
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            MeridianIcon(
              icon,
              size: MeridianIconSize.small,
              color: enabled ? colors.inkMuted : colors.inkFaint,
            ),
            const SizedBox(width: MeridianSpace.space3),
          ],
          Expanded(
            // TextField needs a Material ancestor; never rely on the host.
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  if (widget.underlay case final underlay?)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ExcludeSemantics(child: underlay),
                      ),
                    ),
                  TextField(
                    key: widget.fieldKey,
                    controller: _controller,
                    onTap: widget.onTap,
                    focusNode: _focusNode,
                    autofocus: widget.autofocus,
                    obscureText: obscure,
                    enabled: enabled,
                    readOnly: widget.readOnly,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    inputFormatters: widget.inputFormatters,
                    autocorrect: widget.autocorrect,
                    enableSuggestions: widget.enableSuggestions,
                    autofillHints: widget.autofillHints,
                    minLines: minLines,
                    maxLines: maxLines,
                    expands: expands,
                    scrollController: widget.scrollController,
                    textAlignVertical: expands ? TextAlignVertical.top : null,
                    spellCheckConfiguration: widget.spellCheckConfiguration,
                    contextMenuBuilder:
                        widget.contextMenuBuilder ??
                        MeridianMenuPresenter.maybeOf(
                          context,
                        )?.textContextMenuBuilder ??
                        _adaptiveTextMenu,
                    maxLength: widget.maxLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    onChanged: widget.onChanged,
                    onSubmitted:
                        widget.onSubmitted ??
                        (submitsDialog ? (_) => _submitDialog() : null),
                    // Keep focus in the field when Enter submits the dialog,
                    // so a rejected submit leaves the person where they were.
                    onEditingComplete: submitsDialog ? () {} : null,
                    style: baseStyle.copyWith(
                      color: enabled ? colors.ink : colors.inkFaint,
                    ),
                    cursorColor: colors.accent,
                    decoration: InputDecoration.collapsed(
                      hintText: widget.placeholder,
                      hintStyle: baseStyle.copyWith(color: colors.inkFaint),
                    ).copyWith(counterText: ''),
                  ),
                  if (_outgoingText case final outgoing?)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: FadeTransition(
                            opacity: ReverseAnimation(_clearFade),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                outgoing,
                                maxLines: maxLines,
                                overflow: TextOverflow.clip,
                                style: baseStyle.copyWith(
                                  color: enabled ? colors.ink : colors.inkFaint,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.trailingText case final trailing?) ...[
            const SizedBox(width: MeridianSpace.space3),
            _TrailingText(
              text: trailing,
              style: MeridianTextStyles.numeric(
                text.caption.copyWith(color: colors.inkMuted),
              ),
            ),
          ],
          if (widget.clearLabel case final label? when _hasText && enabled)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: MeridianSpace.space2,
              ),
              child: MeridianSurfaceScope.withFill(
                context,
                fill: well,
                child: MeridianIconButton(
                  label: label,
                  icon: MeridianIcons.x,
                  size: MeridianControlSize.small,
                  canRequestFocus: false,
                  onPressed: _clear,
                ),
              ),
            ),
          if (widget.trailing case final trailing?) ...[
            const SizedBox(width: MeridianSpace.space2),
            MeridianSurfaceScope.withFill(context, fill: well, child: trailing),
          ],
        ],
      ),
    );
    final note = error ?? widget.message;
    if (note != null) {
      _lastNote = note;
      _lastNoteError = error != null;
    }
    final shownNote = _lastNote;
    final label = widget.label;
    Widget field = MouseRegion(
      onEnter: (_) => _setHovered(enabled),
      onExit: (_) => _setHovered(false),
      child: MeridianShake(trigger: widget.rejectCount, child: chrome),
    );
    if (label != null && !widget.showLabel) {
      field = Semantics(label: label, child: field);
    }
    return SizedBox(
      width: widget.width,
      child: MergeSemantics(
        child: Column(
          mainAxisSize: expands ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null && widget.showLabel) ...[
              Text(
                label,
                style: text.label.copyWith(
                  color: enabled ? colors.ink : colors.inkFaint,
                ),
              ),
              const SizedBox(height: MeridianSpace.space2),
            ],
            if (expands) Expanded(child: field) else field,
            // The message reveals and rises; it leaves the same way.
            if (shownNote != null)
              MeridianReveal(
                visible: note != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: MeridianSpace.space2),
                    MeridianSwap(
                      swapKey: shownNote,
                      style: MeridianSwapStyle.rise,
                      rise: MeridianMotionScales.riseOverlay,
                      child: Text(
                        shownNote,
                        style: text.caption.copyWith(
                          color: _lastNoteError
                              ? colors.danger
                              : colors.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A text field's trailing text: a whole number rolls (MM-70), other text
/// rolls in as a whole (MM-10).
class _TrailingText extends StatelessWidget {
  const _TrailingText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final number = int.tryParse(text);
    if (number != null && '$number' == text) {
      return MeridianRollingNumber(value: number, style: style);
    }
    return MeridianSwap(
      swapKey: text,
      style: MeridianSwapStyle.roll,
      alignment: AlignmentDirectional.centerEnd,
      child: Text(text, style: style),
    );
  }
}

/// A toggle control (box, radio, track) with a clickable label.
///
/// Only the control carries the focus ring and the 48px touch target; the
/// label toggles too and hovering or pressing it paints the control's hover
/// and pressed states.
class _ToggleRow extends StatefulWidget {
  const _ToggleRow({
    required this.onTap,
    required this.ringRadius,
    required this.control,
    this.label,
    this.labelFirst = false,
    this.alignTop = false,
    this.controlInset = 0,
  });

  final VoidCallback? onTap;
  final BorderRadius ringRadius;
  final Widget Function(BuildContext context, MeridianInteractionState state)
  control;
  final Widget? label;

  /// Label first, filling the width, control at the end.
  final bool labelFirst;

  /// Align the control with the label's first line.
  final bool alignTop;

  /// Top offset of the control when [alignTop] is set.
  final double controlInset;

  @override
  State<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<_ToggleRow> {
  var _labelHovered = false;
  var _labelPressed = false;

  @override
  void didUpdateWidget(covariant _ToggleRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onTap == null) {
      _labelHovered = false;
      _labelPressed = false;
    }
  }

  void _setHovered(bool value) {
    if (_labelHovered != value) setState(() => _labelHovered = value);
  }

  void _setPressed(bool value) {
    if (_labelPressed != value) setState(() => _labelPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    Widget control = MeridianInteraction(
      onTap: widget.onTap,
      borderRadius: widget.ringRadius,
      builder: (context, state) => widget.control(
        context,
        MeridianInteractionState(
          hovered: state.hovered || (_labelHovered && enabled),
          pressed: state.pressed || (_labelPressed && enabled),
          focused: state.focused,
          enabled: state.enabled,
        ),
      ),
    );
    final label = widget.label;
    if (label == null) return control;
    if (widget.alignTop && widget.controlInset > 0) {
      control = Padding(
        padding: EdgeInsets.only(top: widget.controlInset),
        child: control,
      );
    }
    final labelArea = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(enabled),
      onExit: (_) {
        _setHovered(false);
        _setPressed(false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: widget.onTap,
        child: Padding(
          padding: widget.labelFirst
              ? const EdgeInsetsDirectional.only(end: MeridianSpace.space4)
              : const EdgeInsetsDirectional.only(start: MeridianSpace.space4),
          child: label,
        ),
      ),
    );
    final cross = widget.alignTop
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;
    return widget.labelFirst
        ? Row(
            crossAxisAlignment: cross,
            children: [
              Expanded(child: labelArea),
              control,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: cross,
            children: [
              control,
              Flexible(child: labelArea),
            ],
          );
  }
}

/// A label with an optional `caption` description, for toggles.
class _ToggleLabel extends StatelessWidget {
  const _ToggleLabel({
    required this.label,
    required this.enabled,
    this.description,
  });

  final String label;
  final String? description;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: meridian.text.body.copyWith(
            color: enabled ? colors.ink : colors.inkFaint,
          ),
        ),
        if (description case final description?)
          Text(
            description,
            style: meridian.text.caption.copyWith(
              color: enabled ? colors.inkMuted : colors.inkFaint,
            ),
          ),
      ],
    );
  }
}

/// A checkbox with its label. Use it for options that apply when a command
/// runs ("Include attachments"); use [MeridianSwitch] for settings that
/// apply straight away. `null` [value] with [tristate] shows the mixed
/// state. Clicking the label toggles it.
class MeridianCheckbox extends StatelessWidget {
  const MeridianCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
    this.description,
    this.tristate = false,
  });

  final bool? value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? description;
  final bool tristate;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final enabled = onChanged != null;
    final mixed = tristate && value == null;
    final on = value == true || mixed;
    final alignTop = description != null && !meridian.density.isTouch;
    void toggle() => onChanged?.call(value != true);
    return Semantics(
      excludeSemantics: true,
      checked: !mixed && value == true,
      mixed: mixed,
      enabled: enabled,
      label: label,
      hint: description,
      onTap: enabled ? toggle : null,
      child: _ToggleRow(
        onTap: enabled ? toggle : null,
        ringRadius: const BorderRadius.all(
          Radius.circular(MeridianLayout.checkboxRadius),
        ),
        alignTop: alignTop,
        controlInset: MeridianLayout.checkboxLabelOffset,
        control: (context, state) =>
            _CheckboxBox(on: on, mixed: mixed, enabled: enabled, state: state),
        label: _ToggleLabel(
          label: label,
          description: description,
          enabled: enabled,
        ),
      ),
    );
  }
}

/// A switch for settings that apply straight away ("Check mail
/// automatically"). The label is required; put it after the track, or set
/// [labelFirst] in a settings list on touch.
class MeridianSwitch extends StatelessWidget {
  const MeridianSwitch({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
    this.showLabel = true,
    this.labelFirst = false,
    this.description,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  /// A `caption` line under the label that explains the setting.
  final String? description;

  /// Hide the visible label when a settings row already shows it.
  final bool showLabel;

  /// Put the label before the track and push the track to the end.
  final bool labelFirst;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    void toggle() => onChanged?.call(!value);
    return Semantics(
      excludeSemantics: true,
      toggled: value,
      enabled: enabled,
      label: label,
      hint: description,
      onTap: enabled ? toggle : null,
      child: _ToggleRow(
        onTap: enabled ? toggle : null,
        ringRadius: _pill,
        labelFirst: labelFirst,
        control: (context, state) =>
            _SwitchTrack(value: value, enabled: enabled, state: state),
        label: showLabel
            ? _ToggleLabel(
                label: label,
                description: description,
                enabled: enabled,
              )
            : null,
      ),
    );
  }
}

/// One option of a radio group. Build a group as a column of these sharing
/// the same [groupValue].
class MeridianRadio<T> extends StatelessWidget {
  const MeridianRadio({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    super.key,
    this.description,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;
  final String label;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final enabled = onChanged != null;
    final on = value == groupValue;
    final alignTop = description != null && !meridian.density.isTouch;
    void choose() => onChanged?.call(value);
    return Semantics(
      excludeSemantics: true,
      inMutuallyExclusiveGroup: true,
      checked: on,
      enabled: enabled,
      label: label,
      hint: description,
      onTap: enabled ? choose : null,
      child: _ToggleRow(
        onTap: enabled ? choose : null,
        ringRadius: _pill,
        alignTop: alignTop,
        controlInset: MeridianLayout.checkboxLabelOffset,
        control: (context, state) =>
            _RadioControl(on: on, enabled: enabled, state: state),
        label: _ToggleLabel(
          label: label,
          description: description,
          enabled: enabled,
        ),
      ),
    );
  }
}

/// Meridian's checkbox box on its own, for a row that owns the interaction
/// (a checklist [MeridianListRow]): the same visuals and motion as
/// [MeridianCheckbox], following the row's [state]. It is not a focus stop
/// and has no semantics of its own. Package-internal: the library hides it.
class MeridianCheckboxMark extends StatelessWidget {
  const MeridianCheckboxMark({
    required this.checked,
    required this.enabled,
    required this.state,
    super.key,
    this.onAccent = false,
  });

  final bool checked;
  final bool enabled;
  final MeridianInteractionState state;

  /// Drawn on a solid `accent` fill (a strong selection): the box takes
  /// `on-accent` and the check `accent`, so it stays legible.
  final bool onAccent;

  @override
  Widget build(BuildContext context) => _CheckboxBox(
    on: checked,
    mixed: false,
    enabled: enabled,
    state: state,
    onAccent: onAccent,
  );
}

/// A checkbox's box (MM-11): the `accent` fill scales 0.6 → 1 on
/// `spring-pop` while it fades in, and the check draws in 140 ms after
/// 40 ms. Unchecking fades the fill over `motion-exit` and erases the
/// check. The mixed dash draws from the centre outwards.
class _CheckboxBox extends StatefulWidget {
  const _CheckboxBox({
    required this.on,
    required this.mixed,
    required this.enabled,
    required this.state,
    this.onAccent = false,
  });

  final bool on;
  final bool mixed;
  final bool enabled;
  final MeridianInteractionState state;

  /// Inverted for a solid `accent` ground; see [MeridianCheckboxMark].
  final bool onAccent;

  @override
  State<_CheckboxBox> createState() => _CheckboxBoxState();
}

class _CheckboxBoxState extends State<_CheckboxBox>
    with TickerProviderStateMixin {
  late final MeridianSpringController _scale = MeridianSpringController(
    vsync: this,
    value: 1,
  );
  late final AnimationController _fill = AnimationController(
    vsync: this,
    value: widget.on ? 1 : 0,
  );

  /// The check's stroke: drawn in 140 ms after 40 ms, erased over
  /// `motion-exit`. At rest the icon itself shows.
  late final AnimationController _check = AnimationController(
    vsync: this,
    value: widget.on ? 1 : 0,
  );

  @override
  void didUpdateWidget(_CheckboxBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.on == oldWidget.on) return;
    final reduced = MeridianMotion.reduced(context);
    if (widget.on) {
      final total =
          MeridianLayout.checkboxCheckDelay + MeridianLayout.checkboxCheckDraw;
      if (reduced) {
        _check.value = 1;
      } else {
        _check.animateTo(
          1,
          duration: total,
          curve: Interval(
            MeridianLayout.checkboxCheckDelay.inMicroseconds /
                total.inMicroseconds,
            1,
            curve: MeridianDurations.quickCurve,
          ),
        );
      }
    } else {
      _check.animateTo(
        0,
        duration: MeridianMotion.of(context, MeridianDurations.exit),
        curve: MeridianDurations.exitCurve,
      );
    }
    if (widget.on) {
      if (reduced) {
        _scale.jumpTo(1);
        _fill.value = 1;
        return;
      }
      _scale
        ..jumpTo(MeridianOpacity.badgeLeaveScale)
        ..animateTo(1, spring: MeridianSprings.pop);
      _fill.animateTo(
        1,
        duration: MeridianDurations.quick,
        curve: MeridianDurations.quickCurve,
      );
    } else {
      _fill.animateTo(
        0,
        duration: MeridianMotion.of(context, MeridianDurations.exit),
        curve: MeridianDurations.exitCurve,
      );
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    _fill.dispose();
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = MeridianTheme.of(context).colors;
    final state = widget.state;
    final enabled = widget.enabled;
    final on = widget.on;
    final inverse = widget.onAccent && enabled;
    final onFill = !enabled
        ? colors.inkFaint
        : inverse
        ? colors.onAccent
        : state.fill(
            rest: colors.accent,
            hoverFill: _accentHover(colors),
            ink: colors.ink,
          );
    final offFill = !enabled
        ? colors.paneAlt
        : inverse
        ? meridianClear(colors.accent)
        : state.fill(
            rest: colors.pane,
            hoverFill: colors.paneHover,
            ink: colors.ink,
          );
    final edge = on
        ? onFill
        : !enabled
        ? colors.line
        : inverse
        ? colors.onAccent
        : state.hovered || state.pressed
        ? colors.inkMuted
        : colors.controlEdge;
    const radius = BorderRadius.all(
      Radius.circular(MeridianLayout.checkboxRadius),
    );
    final duration = meridianHoverDuration(
      context,
      state.hovered || state.pressed,
    );
    final checkColor = inverse
        ? colors.accent
        : enabled
        ? colors.onAccent
        : colors.pane;
    return SizedBox.square(
      dimension: MeridianLayout.checkboxSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Once the fill has popped in, the box takes its colour too, so a
          // checked box at rest paints exactly one solid square.
          AnimatedBuilder(
            animation: Listenable.merge([_scale.animation, _fill]),
            builder: (context, _) {
              final settled =
                  on && _fill.value >= 1 && (_scale.value - 1).abs() < 0.001;
              return AnimatedContainer(
                duration: duration,
                decoration: BoxDecoration(
                  color: settled ? onFill : offFill,
                  border: Border.all(color: edge),
                  borderRadius: radius,
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_scale.animation, _fill]),
            builder: (context, child) {
              final settled =
                  on && _fill.value >= 1 && (_scale.value - 1).abs() < 0.001;
              // At rest the box above carries the fill: one layer, so the
              // corners anti-alias as before.
              return Opacity(
                opacity: settled ? 0 : _fill.value.clamp(0.0, 1.0),
                child: Transform.scale(scale: _scale.value, child: child),
              );
            },
            child: AnimatedContainer(
              duration: duration,
              decoration: BoxDecoration(color: onFill, borderRadius: radius),
            ),
          ),
          Center(
            child: widget.mixed
                ? MeridianAnimatedValue(
                    value: on ? 1 : 0,
                    duration: MeridianDurations.quick,
                    curve: MeridianDurations.quickCurve,
                    builder: (context, t, child) => t >= 1
                        ? child!
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(t, 1, 1),
                            child: child,
                          ),
                    child: MeridianIcon(
                      MeridianIcons.minus,
                      extent: MeridianLayout.checkboxIconSize,
                      color: checkColor,
                    ),
                  )
                : AnimatedBuilder(
                    animation: _check,
                    builder: (context, _) {
                      final t = _check.value;
                      if (t <= 0) return const SizedBox.shrink();
                      // At rest the Lucide icon itself; its stroke only
                      // while it draws or erases.
                      if (t >= 1 && !_check.isAnimating) {
                        return MeridianIcon(
                          MeridianIcons.check,
                          extent: MeridianLayout.checkboxIconSize,
                          color: checkColor,
                        );
                      }
                      return SizedBox.square(
                        dimension: MeridianLayout.checkboxIconSize,
                        child: CustomPaint(
                          painter: MeridianStrokePainter(
                            path: (size) => meridianStrokeIconPath(
                              MeridianIcons.check,
                              size,
                            ),
                            color: checkColor,
                            progress: t,
                            strokeWidth:
                                2 * MeridianLayout.checkboxIconSize / 24,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// A switch's track and thumb (MM-12): the thumb travels on
/// `spring-snappy` and stretches towards its travel while pressed; the
/// track colour follows over `motion-select`. Reduce motion: the thumb
/// jumps and the colour crossfades.
class _SwitchTrack extends StatefulWidget {
  const _SwitchTrack({
    required this.value,
    required this.enabled,
    required this.state,
  });

  final bool value;
  final bool enabled;
  final MeridianInteractionState state;

  @override
  State<_SwitchTrack> createState() => _SwitchTrackState();
}

class _SwitchTrackState extends State<_SwitchTrack>
    with SingleTickerProviderStateMixin {
  late final MeridianSpringController _travel = MeridianSpringController(
    vsync: this,
    value: widget.value ? 1 : 0,
  );

  @override
  void didUpdateWidget(_SwitchTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _travel.animateTo(
        widget.value ? 1 : 0,
        spring: MeridianSprings.snappy,
        reduced: MeridianMotion.reduced(context),
      );
    }
  }

  @override
  void dispose() {
    _travel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final state = widget.state;
    final enabled = widget.enabled;
    final value = widget.value;
    final touch = meridian.density.isTouch;
    final width = touch
        ? MeridianLayout.switchWidthTouch
        : MeridianLayout.switchWidth;
    final height = touch
        ? MeridianLayout.switchHeightTouch
        : MeridianLayout.switchHeight;
    final thumb = touch
        ? MeridianLayout.switchThumbTouch
        : MeridianLayout.switchThumb;
    // The 1px track edge counts towards the thumb inset.
    const inset = MeridianLayout.switchThumbInset - MeridianLayout.hairline;
    final track = !enabled
        ? colors.line
        : state.fill(
            rest: value ? colors.accent : colors.lineStrong,
            hoverFill: value ? _accentHover(colors) : colors.lineStrong,
            ink: colors.ink,
          );
    final edge = value || !enabled
        ? meridianClear(colors.controlEdge)
        : state.hovered || state.pressed
        ? colors.inkMuted
        : colors.controlEdge;
    final stretched =
        enabled && state.pressed && !MeridianMotion.reduced(context);
    final inner = width - MeridianLayout.hairline * 2;
    return AnimatedContainer(
      duration: MeridianMotion.fade(context, MeridianDurations.select),
      curve: MeridianDurations.selectCurve,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: track,
        border: Border.all(color: edge),
        borderRadius: _pill,
      ),
      child: MeridianAnimatedValue(
        value: stretched ? MeridianLayout.switchThumbStretch : 0,
        duration: MeridianDurations.quick,
        curve: MeridianDurations.quickCurve,
        builder: (context, stretch, _) => AnimatedBuilder(
          animation: _travel.animation,
          builder: (context, _) {
            final thumbWidth = thumb + stretch;
            final travel = inner - inset * 2 - thumbWidth;
            final left = inset + travel * _travel.value;
            return Stack(
              children: [
                PositionedDirectional(
                  start: left,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: thumbWidth,
                      height: thumb,
                      decoration: BoxDecoration(
                        color: enabled ? colors.pane : colors.paneAlt,
                        borderRadius: _pill,
                        boxShadow: [
                          BoxShadow(
                            color: colors.ink.withValues(
                              alpha: MeridianOpacity.switchThumbShadow,
                            ),
                            blurRadius: MeridianLayout.switchThumbShadowBlur,
                            offset: const Offset(
                              0,
                              MeridianLayout.switchThumbShadowOffset,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A radio's circle (MM-13): the inner dot scales 0 → 1 on `spring-pop`
/// and shrinks out over `motion-exit`.
class _RadioControl extends StatefulWidget {
  const _RadioControl({
    required this.on,
    required this.enabled,
    required this.state,
  });

  final bool on;
  final bool enabled;
  final MeridianInteractionState state;

  @override
  State<_RadioControl> createState() => _RadioControlState();
}

class _RadioControlState extends State<_RadioControl>
    with SingleTickerProviderStateMixin {
  late final MeridianSpringController _dot = MeridianSpringController(
    vsync: this,
    value: widget.on ? 1 : 0,
  );

  @override
  void didUpdateWidget(_RadioControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.on == oldWidget.on) return;
    if (widget.on) {
      _dot
        ..jumpTo(MeridianMotion.reduced(context) ? 1 : 0)
        ..animateTo(
          1,
          spring: MeridianSprings.pop,
          reduced: MeridianMotion.reduced(context),
        );
    } else {
      _dot.animateToTimed(
        0,
        duration: MeridianMotion.of(context, MeridianDurations.exit),
        curve: MeridianDurations.exitCurve,
      );
    }
  }

  @override
  void dispose() {
    _dot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = MeridianTheme.of(context).colors;
    final state = widget.state;
    final enabled = widget.enabled;
    final on = widget.on;
    final fill = !enabled
        ? colors.pane
        : on
        ? state.fill(
            rest: colors.accent,
            hoverFill: _accentHover(colors),
            ink: colors.ink,
          )
        : state.fill(
            rest: colors.pane,
            hoverFill: colors.paneHover,
            ink: colors.ink,
          );
    final edge = !enabled
        ? colors.line
        : on
        ? fill
        : state.hovered || state.pressed
        ? colors.inkMuted
        : colors.controlEdge;
    return AnimatedContainer(
      duration: MeridianMotion.of(context, MeridianDurations.select),
      curve: MeridianDurations.selectCurve,
      width: MeridianLayout.checkboxSize,
      height: MeridianLayout.checkboxSize,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: edge),
      ),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _dot.animation,
        builder: (context, child) => _dot.value <= 0
            ? const SizedBox.shrink()
            : Transform.scale(scale: _dot.value, child: child),
        child: Container(
          width: MeridianLayout.radioDot,
          height: MeridianLayout.radioDot,
          decoration: BoxDecoration(
            color: enabled ? colors.onAccent : colors.inkFaint,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// One option of a [MeridianSegmented].
@immutable
class MeridianSegment<T> {
  const MeridianSegment({
    required this.value,
    this.label,
    this.icon,
    this.tooltip,
    this.enabled = true,
  }) : assert(label != null || icon != null);

  final T value;
  final String? label;
  final String? icon;

  /// Required for icon-only segments. On a disabled segment it says why the
  /// option is unavailable; it still shows on hover.
  final String? tooltip;

  /// A disabled segment reads `ink-faint`, takes no pointer or keyboard
  /// selection and is skipped by the arrow keys. It may still be the
  /// selected value: the tile stays on it, muted.
  final bool enabled;
}

/// Picks one of 2–4 peer options that change a view (list or grid, day or
/// week, light or dark). Never for commands; more than four options is a
/// [MeridianSelect]. Arrow keys move the selection.
class MeridianSegmented<T> extends StatefulWidget {
  const MeridianSegmented({
    required this.label,
    required this.segments,
    required this.value,
    required this.onChanged,
    super.key,
    this.size = MeridianControlSize.regular,
    this.expand = false,
    this.manualActivation = false,
  });

  /// Accessible name of the group.
  final String label;
  final List<MeridianSegment<T>> segments;
  final T value;
  final ValueChanged<T>? onChanged;
  final MeridianControlSize size;

  /// Stretch segments to fill the width (touch layouts).
  final bool expand;

  /// The arrow keys move a focus highlight instead of the value, and Space
  /// or Enter selects it. Use it when a change is expensive (it reloads a
  /// list), so arrowing across the options does not run every one.
  final bool manualActivation;

  @override
  State<MeridianSegmented<T>> createState() => _MeridianSegmentedState<T>();
}

class _MeridianSegmentedState<T> extends State<MeridianSegmented<T>> {
  int? _hovered;
  int? _pressed;

  /// The keyboard highlight with [MeridianSegmented.manualActivation].
  int? _active;
  final _focusNode = FocusNode(debugLabel: 'meridian-segmented');
  var _focusVisible = false;
  var _pointerFocused = false;

  @override
  void didUpdateWidget(covariant MeridianSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onChanged == null) {
      _hovered = null;
      _pressed = null;
    }
    if (oldWidget.value != widget.value) _active = null;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _setHovered(int? index) {
    if (_hovered != index) setState(() => _hovered = index);
  }

  void _setPressed(int? index) {
    if (_pressed != index) setState(() => _pressed = index);
  }

  void _select(T value) {
    // A pointer focuses the group without the ring.
    _pointerFocused = true;
    _active = null;
    if (_focusVisible) setState(() => _focusVisible = false);
    _focusNode.requestFocus();
    widget.onChanged?.call(value);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && _pointerFocused) {
      setState(() {
        _pointerFocused = false;
        _focusVisible = _focusNode.hasFocus;
      });
    }
    final onChanged = widget.onChanged;
    if (event is! KeyDownEvent || onChanged == null) {
      return KeyEventResult.ignored;
    }
    final segments = widget.segments;
    final values = [for (final s in segments) s.value];
    if (values.isEmpty) return KeyEventResult.ignored;
    final manual = widget.manualActivation;
    final current = manual && _active != null
        ? _active!
        : values.indexOf(widget.value);
    if (manual &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      if (current >= 0 &&
          segments[current].enabled &&
          values[current] != widget.value) {
        onChanged(values[current]);
      }
      return KeyEventResult.handled;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final last = values.length - 1;
    // The arrow keys step over disabled segments; Home and End land on the
    // first and last enabled one.
    final next = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => _nextEnabled(current, rtl ? 1 : -1),
      LogicalKeyboardKey.arrowRight => _nextEnabled(current, rtl ? -1 : 1),
      LogicalKeyboardKey.home => _nextEnabled(-1, 1),
      LogicalKeyboardKey.end => _nextEnabled(values.length, -1),
      _ => null,
    };
    if (next == null) return KeyEventResult.ignored;
    final target = next.clamp(0, last);
    if (!segments[target].enabled) return KeyEventResult.handled;
    if (manual) {
      setState(() => _active = target);
    } else {
      onChanged(values[target]);
    }
    return KeyEventResult.handled;
  }

  /// The first enabled segment from [from] in direction [step], or [from]
  /// itself (clamped by the caller) when there is none.
  int _nextEnabled(int from, int step) {
    final segments = widget.segments;
    for (var i = from + step; i >= 0 && i < segments.length; i += step) {
      if (segments[i].enabled) return i;
    }
    // Past the end: stay put, as the clamped index always did.
    return from < 0 || from >= segments.length ? from + step : from;
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final density = meridian.density;
    final small = widget.size == MeridianControlSize.small;
    const inset =
        MeridianLayout.segmentedTrackPadding + MeridianLayout.hairline;
    // Density sets the minimum track height; scaled label glyphs grow the
    // tiles (and the track around them) instead of being clipped.
    final tileHeight = math.max(
      (small ? density.controlSmallExtent : density.controlExtent) - inset * 2,
      _labelLineHeight(context, meridian.text.label) +
          MeridianLayout.hairline * 2,
    );
    final height = tileHeight + inset * 2;
    // The track is drawn at the control height; the hit area around it
    // grows to the density's minimum target.
    final outer = math.max(height, density.minTarget);
    final selected = widget.segments.indexWhere((s) => s.value == widget.value);
    final ringIndex = _active ?? (selected < 0 ? 0 : selected);
    return Semantics(
      container: true,
      label: widget.label,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: FocusableActionDetector(
          focusNode: _focusNode,
          enabled: widget.onChanged != null,
          onFocusChange: (focused) {
            if (!focused) {
              _pointerFocused = false;
              if (_active != null) setState(() => _active = null);
            }
          },
          onShowFocusHighlight: (value) {
            final visible = value && !_pointerFocused;
            if (_focusVisible != visible) {
              setState(() => _focusVisible = visible);
            }
          },
          child: SizedBox(
            height: outer,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: colors.paneAlt,
                        border: Border.all(color: colors.line),
                        borderRadius: BorderRadius.circular(meridian.radius.md),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: inset),
                  // The raised tile glides between segments (MM-14).
                  child: MeridianGlide.custom(
                    selection: selected,
                    indicator: _tileIndicator(context),
                    child: Row(
                      mainAxisSize: widget.expand
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      children: [
                        for (var i = 0; i < widget.segments.length; i++) ...[
                          if (i > 0)
                            const SizedBox(width: MeridianSpace.space1),
                          if (widget.expand)
                            Expanded(
                              child: _segment(
                                context,
                                i,
                                small: small,
                                outer: outer,
                                tileHeight: tileHeight,
                                ring: i == ringIndex,
                              ),
                            )
                          else
                            // Natural width when there is room; shares and
                            // ellipsizes in a narrow space instead of
                            // overflowing.
                            Flexible(
                              child: IntrinsicWidth(
                                child: _segment(
                                  context,
                                  i,
                                  small: small,
                                  outer: outer,
                                  tileHeight: tileHeight,
                                  ring: i == ringIndex,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Labels drop the line height's leading above and below, so the glyphs
  /// fit the density's tile and only scaled text grows it.
  static const _segmentLabelHeight = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  /// The height of one scaled label line, or 0 without labels.
  double _labelLineHeight(BuildContext context, TextStyle style) {
    final label = widget.segments
        .map((segment) => segment.label)
        .whereType<String>()
        .firstOrNull;
    if (label == null) return 0;
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
      textHeightBehavior: _segmentLabelHeight,
      text: TextSpan(text: label, style: style),
    )..layout();
    final height = painter.height.ceilToDouble();
    painter.dispose();
    return height;
  }

  /// The selected segment's raised tile, painted by the glide.
  Widget _tileIndicator(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final selected = widget.segments.indexWhere((s) => s.value == widget.value);
    final enabled =
        widget.onChanged != null &&
        (selected < 0 || widget.segments[selected].enabled);
    final pressed = enabled && _pressed == selected;
    return AnimatedContainer(
      duration: meridianHoverDuration(context, pressed),
      decoration: BoxDecoration(
        color: pressed ? meridianPressed(colors.pane, colors.ink) : colors.pane,
        border: Border.all(color: colors.lineStrong),
        borderRadius: BorderRadius.circular(meridian.radius.sm),
        boxShadow: meridian.shadows.shadowControl,
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    int index, {
    required bool small,
    required double outer,
    required double tileHeight,
    required bool ring,
  }) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final segment = widget.segments[index];
    final selected = segment.value == widget.value;
    final enabled = widget.onChanged != null && segment.enabled;
    final hovered = enabled && _hovered == index;
    final pressed = enabled && _pressed == index;
    final ink = !enabled
        ? colors.inkFaint
        : selected || hovered || pressed
        ? colors.ink
        : colors.inkMuted;
    // The selected tile is painted by the glide under the segments
    // (MM-14); a segment paints only its hover and pressed fills.
    final base = selected
        ? meridianClear(colors.paneHover)
        : hovered || pressed
        ? colors.paneHover
        : meridianClear(colors.paneHover);
    final fill = pressed && !selected
        ? meridianPressed(base, colors.ink)
        : base;
    final radius = BorderRadius.circular(meridian.radius.sm);
    final tile = CustomPaint(
      foregroundPainter: MeridianFocusRingPainter(
        visible: ring && _focusVisible,
        color: colors.focus,
        radius: radius,
      ),
      child: MeridianGlideTarget(
        selected: selected,
        child: AnimatedContainer(
          duration: meridianHoverDuration(context, hovered || pressed),
          height: tileHeight,
          width: widget.expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: small ? MeridianSpace.space3 : MeridianSpace.space4,
          ),
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: meridianClear(colors.lineStrong)),
            borderRadius: radius,
          ),
          alignment: Alignment.center,
          // Labels crossfade their colour with the selection (MM-14).
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: ink),
            duration: MeridianMotion.of(context, MeridianDurations.select),
            curve: MeridianDurations.selectCurve,
            builder: (context, ink, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (segment.icon case final icon?) ...[
                  MeridianIcon(icon, size: MeridianIconSize.small, color: ink),
                  if (segment.label != null)
                    const SizedBox(width: MeridianSpace.space2),
                ],
                if (segment.label case final label?)
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textHeightBehavior: _segmentLabelHeight,
                      style: meridian.text.label.copyWith(color: ink),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    Widget hit = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(enabled ? index : null),
      onExit: (_) {
        _setHovered(null);
        _setPressed(null);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(index) : null,
        onTapUp: enabled ? (_) => _setPressed(null) : null,
        onTapCancel: enabled ? () => _setPressed(null) : null,
        onTap: enabled ? () => _select(segment.value) : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: meridian.density.minTarget,
            minHeight: outer,
            maxHeight: outer,
          ),
          child: Center(child: tile),
        ),
      ),
    );
    hit = Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      // A disabled segment keeps its own name; its tooltip is the reason.
      label: segment.enabled
          ? segment.tooltip ?? segment.label
          : segment.label ?? segment.tooltip,
      onTap: enabled ? () => widget.onChanged?.call(segment.value) : null,
      excludeSemantics: true,
      child: hit,
    );
    return switch (segment.tooltip) {
      final message? => Tooltip(message: message, child: hit),
      null => hit,
    };
  }
}

/// A continuous value: zoom, stroke width, opacity, a comparison slider.
/// Arrow keys move it by [step]. Show the value next to it when it matters.
class MeridianSlider extends StatefulWidget {
  const MeridianSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max = 1,
    this.step,
    this.valueLabel,
    this.onChangeEnd,
    this.track,
  }) : assert(min <= max),
       assert(step == null || step > 0);

  final String label;
  final double value;
  final ValueChanged<double>? onChanged;

  /// Paints the whole track with this gradient instead of the `accent`
  /// value fill: the range of a colour channel (hue, red, brightness). The
  /// track thickens so the colours read. Build it with
  /// [AlignmentDirectional] ends so it follows a right-to-left slider.
  final Gradient? track;

  /// Called with the final value when a drag or tap ends, and after each
  /// keyboard or assistive step.
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;

  /// Keyboard step and snapping; defaults to 5% of the range.
  final double? step;

  /// How to announce the value, for example `(v) => '${v.round()} pt'`.
  final String Function(double value)? valueLabel;

  @override
  State<MeridianSlider> createState() => _MeridianSliderState();
}

class _MeridianSliderState extends State<MeridianSlider> {
  final _focus = FocusNode(debugLabel: 'meridian-slider');
  var _focusVisible = false;
  var _pointerFocused = false;
  var _hovered = false;
  var _active = false;
  double? _last;

  double get _span => widget.max - widget.min;
  double get _step => widget.step ?? _span / 20;

  @override
  void didUpdateWidget(covariant MeridianSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onChanged == null) {
      _hovered = false;
      _active = false;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  double _snap(double v) {
    if (_span <= 0) return widget.min;
    final clamped = v.clamp(widget.min, widget.max);
    final step = widget.step;
    if (step == null || step <= 0) return clamped;
    final steps = ((clamped - widget.min) / step).round();
    return (widget.min + steps * step).clamp(widget.min, widget.max);
  }

  void _set(double v) {
    final next = _snap(v);
    _last = next;
    widget.onChanged?.call(next);
  }

  void _end() => widget.onChangeEnd?.call(_last ?? widget.value);

  void _step1(double delta) {
    _set(widget.value + delta);
    _end();
  }

  String _announce(double v) {
    final custom = widget.valueLabel;
    if (custom != null) return custom(v);
    if (_span <= 0) return '0%';
    return '${((v - widget.min) / _span * 100).round()}%';
  }

  void _pointerFocus() {
    _pointerFocused = true;
    if (_focusVisible) setState(() => _focusVisible = false);
    _focus.requestFocus();
  }

  void _setActive(bool value) {
    if (_active != value) setState(() => _active = value);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && _pointerFocused) {
      setState(() {
        _pointerFocused = false;
        _focusVisible = _focus.hasFocus;
      });
    }
    if (widget.onChanged == null ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final forward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final back = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == forward || key == LogicalKeyboardKey.arrowUp) {
      _step1(_step);
      return KeyEventResult.handled;
    }
    if (key == back || key == LogicalKeyboardKey.arrowDown) {
      _step1(-_step);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _set(widget.min);
      _end();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _set(widget.max);
      _end();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final density = meridian.density;
    final enabled = widget.onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final thumb = density.isTouch
        ? MeridianLayout.sliderThumbTouch
        : MeridianLayout.sliderThumb;
    final hitHeight = math.max(density.controlExtent, density.minTarget);
    final fraction = _span <= 0
        ? 0.0
        : ((widget.value - widget.min) / _span).clamp(0.0, 1.0);
    final emphasis = enabled && (_hovered || _active);
    return Semantics(
      label: widget.label,
      slider: true,
      enabled: enabled,
      value: _announce(widget.value),
      increasedValue: _announce(_snap(widget.value + _step)),
      decreasedValue: _announce(_snap(widget.value - _step)),
      onIncrease: enabled ? () => _step1(_step) : null,
      onDecrease: enabled ? () => _step1(-_step) : null,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: FocusableActionDetector(
          focusNode: _focus,
          enabled: enabled,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onFocusChange: (focused) {
            if (!focused) _pointerFocused = false;
          },
          onShowFocusHighlight: (value) {
            final visible = value && !_pointerFocused;
            if (_focusVisible != visible) {
              setState(() => _focusVisible = visible);
            }
          },
          onShowHoverHighlight: (value) {
            if (_hovered != value) setState(() => _hovered = value);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : MeridianLayout.sliderDefaultWidth;
              final travel = math.max(0.0, width - thumb);
              double valueAt(double dx) {
                if (travel <= 0) return widget.min;
                final t = ((dx - thumb / 2) / travel).clamp(0.0, 1.0);
                return widget.min + (rtl ? 1 - t : t) * _span;
              }

              final thumbLeft = travel * (rtl ? 1 - fraction : fraction);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: enabled
                    ? (d) {
                        _pointerFocus();
                        _setActive(true);
                        _set(valueAt(d.localPosition.dx));
                      }
                    : null,
                onTapUp: enabled
                    ? (_) {
                        _setActive(false);
                        _end();
                      }
                    : null,
                onTapCancel: enabled ? () => _setActive(false) : null,
                onHorizontalDragStart: enabled
                    ? (d) {
                        _pointerFocus();
                        _setActive(true);
                        _set(valueAt(d.localPosition.dx));
                      }
                    : null,
                onHorizontalDragUpdate: enabled
                    ? (d) => _set(valueAt(d.localPosition.dx))
                    : null,
                onHorizontalDragEnd: enabled
                    ? (_) {
                        _setActive(false);
                        _end();
                      }
                    : null,
                onHorizontalDragCancel: enabled
                    ? () => _setActive(false)
                    : null,
                child: SizedBox(
                  width: width,
                  height: hitHeight,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      if (widget.track case final gradient?)
                        Positioned(
                          left: thumb / 2,
                          right: thumb / 2,
                          child: Opacity(
                            opacity: enabled
                                ? 1
                                : MeridianOpacity.disabledContent,
                            child: Container(
                              height: density.isTouch
                                  ? MeridianLayout.sliderColorTrackTouch
                                  : MeridianLayout.sliderColorTrack,
                              decoration: BoxDecoration(
                                gradient: gradient,
                                borderRadius: _pill,
                                border: Border.all(color: colors.lineStrong),
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          left: thumb / 2,
                          right: thumb / 2,
                          child: Container(
                            height: MeridianLayout.sliderTrack,
                            decoration: BoxDecoration(
                              color: colors.lineStrong,
                              borderRadius: _pill,
                            ),
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: fraction,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: enabled
                                      ? colors.accent
                                      : colors.inkFaint,
                                  borderRadius: _pill,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: thumbLeft,
                        child: CustomPaint(
                          foregroundPainter: MeridianFocusRingPainter(
                            visible: _focusVisible,
                            color: colors.focus,
                            radius: _pill,
                          ),
                          // The thumb grows while hovered or dragged
                          // (MM-15); the fill follows the pointer exactly.
                          child: MeridianAnimatedValue(
                            value: emphasis && !MeridianMotion.reduced(context)
                                ? MeridianLayout.sliderThumbActiveScale
                                : 1,
                            duration: MeridianDurations.quick,
                            curve: MeridianDurations.quickCurve,
                            builder: (context, scale, child) =>
                                Transform.scale(scale: scale, child: child),
                            child: Container(
                              width: thumb,
                              height: thumb,
                              decoration: BoxDecoration(
                                color: enabled && _active
                                    ? meridianPressed(colors.pane, colors.ink)
                                    : colors.pane,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: enabled
                                      ? colors.accent
                                      : colors.inkFaint,
                                  width: emphasis
                                      ? MeridianLayout.sliderThumbBorderActive
                                      : MeridianLayout.sliderThumbBorder,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A trigger that looks like a secondary button showing the current value,
/// and opens a menu of the choices with the current one checked.
class MeridianSelect<T> extends StatefulWidget {
  const MeridianSelect({
    required this.value,
    required this.values,
    required this.valueLabel,
    required this.onChanged,
    super.key,
    this.label,
    this.width,
    this.minWidth = MeridianLayout.selectMinWidth,
    this.size = MeridianControlSize.regular,
    this.showLabel = false,
    this.expand = false,
    this.animateValue = false,
  });

  final T value;
  final List<T> values;
  final String Function(T value) valueLabel;
  final ValueChanged<T>? onChanged;

  /// Accessible name ("Sort by").
  final String? label;

  /// Show [label] above the trigger, as a `MeridianTextField` does, for
  /// selects in forms and dialogs.
  final bool showLabel;

  /// Fill the available width (forms, touch layouts). Overrides [width].
  final bool expand;

  /// Swap the selected label with a short rise when [value] changes.
  /// The menu and its focus remain on the same select control.
  final bool animateValue;

  /// A fixed width. Without it the trigger fits its longest choice, so it
  /// keeps its size when the value changes.
  final double? width;

  /// The narrowest the fitted trigger gets. Pass 0 for a trigger that only
  /// fits its choices, such as a remote picker that usually holds one name.
  final double minWidth;
  final MeridianControlSize size;

  @override
  State<MeridianSelect<T>> createState() => _MeridianSelectState<T>();
}

class _MeridianSelectState<T> extends State<MeridianSelect<T>> {
  /// The menu is open: the chevron turns half a turn (MM-16).
  var _open = false;

  void _setOpen(bool value) {
    if (mounted && _open != value) setState(() => _open = value);
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final values = widget.values;
    final valueLabel = widget.valueLabel;
    final onChanged = widget.onChanged;
    final label = widget.label;
    final showLabel = widget.showLabel;
    final width = widget.width;
    final minWidth = widget.minWidth;
    final expand = widget.expand;
    final size = widget.size;
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final density = meridian.density;
    final enabled = onChanged != null;
    final radius = BorderRadius.circular(meridian.radius.md);
    final small = size == MeridianControlSize.small;
    final textStyle = meridian.text.body.copyWith(
      color: enabled ? colors.ink : colors.inkFaint,
    );
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
      text: TextSpan(text: valueLabel(value), style: textStyle),
    )..layout();
    // Density extents are minimum targets, not a ceiling on scaled glyphs.
    final verticalPadding = small ? MeridianSpace.space1 : MeridianSpace.space2;
    final extent = math
        .max(
          small ? density.controlSmallExtent : density.controlExtent,
          painter.height + verticalPadding * 2,
        )
        .ceilToDouble();
    // Fit the longest choice so a value change does not move the chevron.
    var fitted = 0.0;
    if (width == null && !expand) {
      var longest = 0.0;
      for (final choice in {...values, value}) {
        painter.text = TextSpan(text: valueLabel(choice), style: textStyle);
        painter.layout();
        longest = math.max(longest, painter.width);
      }
      fitted =
          (MeridianSpace.space4 +
                  longest +
                  MeridianSpace.space4 +
                  density.iconSmallSize +
                  MeridianSpace.space3 +
                  2)
              .ceilToDouble();
    }
    painter.dispose();
    final trigger = MeridianMenuAnchor(
      width: expand ? null : width,
      onOpenChanged: _setOpen,
      entries: [
        for (final choice in values)
          MeridianMenuItem(
            label: valueLabel(choice),
            checked: choice == value,
            onSelected: switch (onChanged) {
              final change? => () => change(choice),
              null => null,
            },
          ),
      ],
      builder: (context, open) => Semantics(
        excludeSemantics: true,
        button: true,
        enabled: enabled,
        label: label,
        value: valueLabel(value),
        onTap: enabled ? open : null,
        child: MeridianInteraction(
          onTap: enabled ? open : null,
          borderRadius: radius,
          builder: (context, state) => AnimatedContainer(
            duration: meridianHoverDuration(
              context,
              state.hovered || state.pressed,
            ),
            width: expand ? double.infinity : width,
            constraints: expand
                ? null
                : BoxConstraints(minWidth: width ?? math.max(minWidth, fitted)),
            height: extent,
            padding: const EdgeInsetsDirectional.only(
              start: MeridianSpace.space4,
              end: MeridianSpace.space3,
            ),
            decoration: BoxDecoration(
              color: !enabled
                  ? colors.paneAlt
                  : state.fill(
                      rest: colors.pane,
                      hoverFill: colors.paneHover,
                      ink: colors.ink,
                    ),
              border: Border.all(
                color: enabled ? colors.lineStrong : colors.line,
              ),
              borderRadius: radius,
              boxShadow: enabled ? meridian.shadows.shadowControl : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              // The chevron stays at the trailing edge when the trigger is
              // wider than its text.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  fit: width == null && !expand ? FlexFit.loose : FlexFit.tight,
                  child: widget.animateValue
                      ? MeridianSwap(
                          swapKey: value,
                          style: MeridianSwapStyle.rise,
                          child: Text(
                            valueLabel(value),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle,
                          ),
                        )
                      : Text(
                          valueLabel(value),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                        ),
                ),
                const SizedBox(width: MeridianSpace.space4),
                MeridianTurns(
                  turns: _open ? 0.5 : 0,
                  child: MeridianIcon(
                    MeridianIcons.chevronDown,
                    size: MeridianIconSize.small,
                    color: enabled ? colors.inkMuted : colors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final visibleLabel = showLabel ? label : null;
    if (visibleLabel == null) return trigger;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: expand
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            visibleLabel,
            style: meridian.text.label.copyWith(
              color: enabled ? colors.ink : colors.inkFaint,
            ),
          ),
        ),
        const SizedBox(height: MeridianSpace.space2),
        trigger,
      ],
    );
  }
}

/// Flutter's own text field menu, the default when no builder is set.
Widget _adaptiveTextMenu(BuildContext context, EditableTextState editable) =>
    AdaptiveTextSelectionToolbar.editableText(editableTextState: editable);

/// One colour in a palette: a pen colour, a cover colour, a label colour.
/// A [color] disc with a `line-strong` edge (so white reads on white);
/// selected, it gains a check and a 2px `accent` ring 2px outside. Build a
/// palette as a `Wrap` of swatches with [MeridianSpace.space2] gaps.
///
/// [color] is content, not a theme token: it never changes with the theme.
/// [label] names the colour ("Blue", "Ink #18304F") for the tooltip and
/// assistive technology. 24px, 32px at touch density with a 48px target.
class MeridianColorSwatch extends StatelessWidget {
  const MeridianColorSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
    this.focusNode,
  });

  final Color color;
  final String label;
  final bool selected;

  /// `null` disables the swatch.
  final VoidCallback? onPressed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final enabled = onPressed != null;
    final disc = meridian.density.isTouch
        ? MeridianLayout.swatchSizeTouch
        : MeridianLayout.swatchSize;
    const ring = MeridianLayout.swatchRingWidth + MeridianLayout.swatchRingGap;
    // The check contrasts with the content colour, not with the theme.
    final light = MeridianColors.resolve(
      Brightness.light,
      meridian.brand.light,
    );
    final check = color.computeLuminance() > 0.4 ? light.ink : light.pane;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        excludeSemantics: true,
        button: true,
        selected: selected,
        enabled: enabled,
        label: label,
        onTap: onPressed,
        child: MeridianInteraction(
          onTap: onPressed,
          focusNode: focusNode,
          borderRadius: const BorderRadius.all(
            Radius.circular(MeridianRadiusScale.pill),
          ),
          builder: (context, state) {
            final edge = !enabled
                ? colors.line
                : state.hovered || state.pressed
                ? colors.inkMuted
                : colors.lineStrong;
            return AnimatedContainer(
              duration: MeridianMotion.of(context, MeridianDurations.select),
              width: disc + 2 * ring,
              height: disc + 2 * ring,
              padding: const EdgeInsets.all(MeridianLayout.swatchRingGap),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: MeridianLayout.swatchRingWidth,
                  color: selected
                      ? colors.accent
                      : meridianClear(colors.accent),
                ),
              ),
              child: Opacity(
                opacity: enabled ? 1 : MeridianOpacity.disabledContent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: edge),
                  ),
                  child: selected
                      ? Center(
                          child: MeridianIcon(
                            MeridianIcons.check,
                            size: MeridianIconSize.small,
                            color: check,
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
