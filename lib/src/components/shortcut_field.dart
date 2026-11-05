import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'actions.dart';
import 'display.dart';

/// Metadata for one real, non-modifier key-down. No typed character is retained.
@immutable
class MeridianShortcutStroke {
  const MeridianShortcutStroke({
    required this.physicalKey,
    required this.logicalKey,
    this.control = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
  });
  final PhysicalKeyboardKey physicalKey;
  final LogicalKeyboardKey logicalKey;
  final bool control, shift, alt, meta;
}

/// Controlled recording chrome; the consumer owns global admission and storage.
class MeridianShortcutField extends StatefulWidget {
  const MeridianShortcutField({
    super.key,
    required this.label,
    required this.emptyLabel,
    required this.recordingLabel,
    required this.preparingLabel,
    required this.clearLabel,
    this.keys = const [],
    this.onRecordRequested,
    this.onRecorded,
    this.onCancelRecording,
    this.onClear,
    this.recording = false,
    this.preparing = false,
    this.enabled = true,
    this.showLabel = true,
    this.autofocus = false,
    this.focusNode,
    this.conflict,
    this.disabledReason,
    this.width,
  });
  final String label, emptyLabel, recordingLabel, preparingLabel, clearLabel;
  final List<String> keys;
  final VoidCallback? onRecordRequested, onCancelRecording, onClear;
  final ValueChanged<MeridianShortcutStroke>? onRecorded;
  final bool recording, preparing, enabled, showLabel, autofocus;
  final FocusNode? focusNode;
  final Widget? conflict;
  final String? disabledReason;
  final double? width;
  @override
  State<MeridianShortcutField> createState() => _MeridianShortcutFieldState();
}

class _MeridianShortcutFieldState extends State<MeridianShortcutField> {
  final _ownedTrigger = FocusNode(), _capture = FocusNode();
  FocusNode get _trigger => widget.focusNode ?? _ownedTrigger;
  bool _wasCapturing = false, _cancellationRequested = false;
  bool get _enabled =>
      widget.enabled &&
      !widget.preparing &&
      widget.onRecordRequested != null &&
      widget.onRecorded != null;
  @override
  void initState() {
    super.initState();
    _capture.addListener(_focusChanged);
    if (widget.recording && _enabled) _takeCaptureFocus();
  }

  void _takeCaptureFocus() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && widget.recording && _enabled) _capture.requestFocus();
  });
  void _cancel() {
    if (!widget.recording || _cancellationRequested) return;
    _cancellationRequested = true;
    _wasCapturing = false;
    widget.onCancelRecording?.call();
  }

  void _focusChanged() {
    if (_capture.hasPrimaryFocus) {
      _wasCapturing = true;
    } else if (_wasCapturing) {
      _wasCapturing = false;
      if (widget.recording && _enabled) _cancel();
    }
  }

  @override
  void didUpdateWidget(covariant MeridianShortcutField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recording && _enabled && !oldWidget.recording) {
      _cancellationRequested = false;
      _takeCaptureFocus();
    }
    if (!widget.recording && oldWidget.recording) {
      _wasCapturing = false;
      if (_capture.hasPrimaryFocus) _trigger.requestFocus();
    }
    final wasEnabled =
        oldWidget.enabled &&
        !oldWidget.preparing &&
        oldWidget.onRecordRequested != null &&
        oldWidget.onRecorded != null;
    if (oldWidget.recording && wasEnabled && widget.recording && !_enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.recording && !_enabled) _cancel();
      });
    }
  }

  static final _modifiers = <LogicalKeyboardKey>{
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.altGraph,
    LogicalKeyboardKey.fn,
    LogicalKeyboardKey.fnLock,
    LogicalKeyboardKey.hyper,
    LogicalKeyboardKey.superKey,
    LogicalKeyboardKey.symbol,
    LogicalKeyboardKey.symbolLock,
  };
  KeyEventResult _record(FocusNode _, KeyEvent event) {
    if (!widget.recording || !_enabled) return KeyEventResult.ignored;
    if (_cancellationRequested ||
        event is! KeyDownEvent ||
        event.synthesized ||
        _modifiers.contains(event.logicalKey)) {
      return KeyEventResult.handled;
    }
    final keyboard = HardwareKeyboard.instance;
    final command =
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed;
    if (!command && event.logicalKey == LogicalKeyboardKey.tab) {
      _cancel();
      return KeyEventResult.ignored;
    }
    if (!command &&
        !keyboard.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _cancel();
      return KeyEventResult.handled;
    }
    if (event.physicalKey.usbHidUsage == 0) return KeyEventResult.handled;
    widget.onRecorded?.call(
      MeridianShortcutStroke(
        physicalKey: event.physicalKey,
        logicalKey: event.logicalKey,
        control: keyboard.isControlPressed,
        shift: keyboard.isShiftPressed,
        alt: keyboard.isAltPressed,
        meta: keyboard.isMetaPressed,
      ),
    );
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _wasCapturing = false;
    _capture.removeListener(_focusChanged);
    _capture.dispose();
    _ownedTrigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.meridian;
    final radius = BorderRadius.circular(m.radius.md);
    final value = widget.preparing
        ? widget.preparingLabel
        : widget.recording
        ? widget.recordingLabel
        : widget.keys.isEmpty
        ? widget.emptyLabel
        : widget.keys.join(' + ');
    void activate() {
      if (widget.recording) {
        _cancel();
      } else {
        widget.onRecordRequested?.call();
      }
    }

    return SizedBox(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showLabel) ...[
            Text(widget.label, style: m.text.bodyStrong),
            const SizedBox(height: MeridianSpace.space3),
          ],
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: widget.label,
                  value: value,
                  hint: widget.disabledReason,
                  button: true,
                  enabled: _enabled,
                  liveRegion: widget.recording || widget.preparing,
                  excludeSemantics: true,
                  onTap: _enabled ? activate : null,
                  child: MeridianInteraction(
                    focusNode: _trigger,
                    autofocus: widget.autofocus,
                    focusOnPointer: !widget.recording,
                    onTap: _enabled ? activate : null,
                    borderRadius: radius,
                    builder: (context, state) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: state.fill(
                          rest: m.colors.pane,
                          hoverFill: m.colors.paneHover,
                          ink: m.colors.ink,
                        ),
                        borderRadius: radius,
                        border: Border.all(
                          color: widget.recording && _enabled
                              ? m.colors.focus
                              : _enabled
                              ? m.colors.controlEdge
                              : m.colors.line,
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: m.density.controlExtent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MeridianSpace.space4,
                            vertical: MeridianSpace.space3,
                          ),
                          child: Focus(
                            focusNode: _capture,
                            canRequestFocus: widget.recording && _enabled,
                            skipTraversal: true,
                            onKeyEvent: _record,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child:
                                  !widget.recording &&
                                      !widget.preparing &&
                                      widget.keys.isNotEmpty
                                  ? Wrap(
                                      spacing: MeridianSpace.space2,
                                      runSpacing: MeridianSpace.space2,
                                      children: [
                                        for (final key in widget.keys)
                                          MeridianKbd(keys: [key]),
                                      ],
                                    )
                                  : Text(
                                      value,
                                      style: m.text.body.copyWith(
                                        color: _enabled
                                            ? m.colors.inkMuted
                                            : m.colors.inkFaint,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.keys.isNotEmpty && widget.onClear != null) ...[
                const SizedBox(width: MeridianSpace.space2),
                MeridianIconButton(
                  label: widget.clearLabel,
                  icon: MeridianIcons.x,
                  onPressed: widget.enabled && !widget.preparing
                      ? widget.onClear
                      : null,
                ),
              ],
            ],
          ),
          if (widget.conflict case final conflict?) ...[
            const SizedBox(height: MeridianSpace.space3),
            Semantics(liveRegion: true, child: conflict),
          ],
        ],
      ),
    );
  }
}
