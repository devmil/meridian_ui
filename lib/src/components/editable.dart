import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/meridian_theme.dart';
import 'selection.dart';

/// The editable text inside a `MeridianTextField`: an [EditableText] with
/// the platform's pointer and touch selection gestures, Meridian's caret,
/// selection colour, handles and text menu, and a [placeholder] while it is
/// empty. It draws no well, edge or label; the field does.
class MeridianEditableText extends StatefulWidget {
  const MeridianEditableText({
    required this.controller,
    required this.focusNode,
    required this.style,
    super.key,
    this.placeholder,
    this.placeholderStyle,
    this.onTap,
    this.autofocus = false,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
    this.minLines,
    this.maxLines = 1,
    this.expands = false,
    this.scrollController,
    this.spellCheckConfiguration,
    this.contextMenuBuilder,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle style;
  final String? placeholder;
  final TextStyle? placeholderStyle;
  final VoidCallback? onTap;
  final bool autofocus;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool autocorrect;
  final bool enableSuggestions;
  final Iterable<String>? autofillHints;
  final int? minLines;
  final int? maxLines;
  final bool expands;
  final ScrollController? scrollController;
  final SpellCheckConfiguration? spellCheckConfiguration;

  /// The cut, copy and paste menu; the app's text menu by default.
  final MeridianTextMenuBuilder? contextMenuBuilder;

  /// The most characters the field takes; longer input is cut off.
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final TextAlign textAlign;

  @override
  State<MeridianEditableText> createState() => _MeridianEditableTextState();
}

class _MeridianEditableTextState extends State<MeridianEditableText>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => !widget.obscureText || widget.readOnly;

  late final _gestures = _GestureBuilder(this);
  var _showHandles = false;

  bool _shouldShowHandles(SelectionChangedCause? cause) {
    if (!_gestures.shouldShowSelectionToolbar ||
        !_gestures.shouldShowSelectionHandles) {
      return false;
    }
    if (cause == SelectionChangedCause.keyboard || !widget.enabled) {
      return false;
    }
    if (widget.readOnly && widget.controller.selection.isCollapsed) {
      return false;
    }
    if (cause == SelectionChangedCause.longPress ||
        cause == SelectionChangedCause.stylusHandwriting) {
      return true;
    }
    return widget.controller.text.isNotEmpty;
  }

  void _onSelectionChanged(TextSelection selection, SelectionChangedCause? c) {
    final show = _shouldShowHandles(c);
    if (show != _showHandles) setState(() => _showHandles = show);
    if (c == SelectionChangedCause.longPress) {
      editableTextKey.currentState?.bringIntoView(selection.extent);
    }
    if (c == SelectionChangedCause.drag &&
        switch (defaultTargetPlatform) {
          TargetPlatform.macOS ||
          TargetPlatform.linux ||
          TargetPlatform.windows => true,
          _ => false,
        }) {
      editableTextKey.currentState?.hideToolbar();
    }
  }

  void _requestKeyboard() => editableTextKey.currentState?.requestKeyboard();

  @override
  void didUpdateWidget(MeridianEditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && widget.focusNode.hasFocus) {
      widget.focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final menu = resolveMeridianTextMenu(context, widget.contextMenuBuilder);
    final formatters = [
      ...?widget.inputFormatters,
      if (widget.maxLength case final max? when max > 0)
        LengthLimitingTextInputFormatter(
          max,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
        ),
    ];
    final spellCheck = widget.spellCheckConfiguration;
    final editable = EditableText(
      key: editableTextKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      readOnly: widget.readOnly || !widget.enabled,
      showSelectionHandles: _showHandles,
      style: widget.style,
      textAlign: widget.textAlign,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: formatters,
      autofillHints: widget.autofillHints,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      expands: widget.expands,
      scrollController: widget.scrollController,
      cursorColor: colors.accent,
      backgroundCursorColor: colors.inkFaint,
      selectionColor: widget.focusNode.hasFocus ? colors.accentSoft : null,
      selectionControls: selectionEnabled
          ? meridianTextSelectionControls
          : null,
      enableInteractiveSelection: selectionEnabled,
      onSelectionChanged: _onSelectionChanged,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      rendererIgnoresPointer: true,
      mouseCursor: MouseCursor.defer,
      contextMenuBuilder: (context, state) =>
          menu(context, MeridianTextMenuRequest.editable(state)),
      spellCheckConfiguration:
          spellCheck == null || !spellCheck.spellCheckEnabled
          ? null
          : spellCheck.copyWith(
              misspelledTextStyle:
                  spellCheck.misspelledTextStyle ??
                  TextStyle(
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.wavy,
                    decorationColor: colors.danger,
                  ),
            ),
    );
    final placeholder = widget.placeholder;
    Widget field = placeholder == null
        ? editable
        : Stack(
            alignment: widget.expands || (widget.maxLines ?? 2) > 1
                ? AlignmentDirectional.topStart
                : AlignmentDirectional.centerStart,
            children: [
              ValueListenableBuilder(
                valueListenable: widget.controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? IgnorePointer(
                        child: ExcludeSemantics(
                          child: Text(
                            placeholder,
                            maxLines: widget.maxLines,
                            overflow: TextOverflow.ellipsis,
                            textAlign: widget.textAlign,
                            style: widget.placeholderStyle ?? widget.style,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              editable,
            ],
          );
    // An expanding field fills the height it is given, like Material's.
    if (widget.expands) field = SizedBox.expand(child: field);
    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      child: TextFieldTapRegion(
        child: IgnorePointer(
          ignoring: !widget.enabled,
          child: Semantics(
            enabled: widget.enabled,
            hint: placeholder,
            maxValueLength: widget.maxLength,
            onTap: widget.readOnly || !widget.enabled
                ? null
                : () {
                    if (!widget.controller.selection.isValid) {
                      widget.controller.selection = TextSelection.collapsed(
                        offset: widget.controller.text.length,
                      );
                    }
                    _requestKeyboard();
                  },
            child: _gestures.buildGestureDetector(
              behavior: HitTestBehavior.translucent,
              child: field,
            ),
          ),
        ),
      ),
    );
  }
}

class _GestureBuilder extends TextSelectionGestureDetectorBuilder {
  _GestureBuilder(this._state) : super(delegate: _state);

  final _MeridianEditableTextState _state;

  @override
  void onUserTap() => _state.widget.onTap?.call();
}
