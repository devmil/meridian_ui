import 'package:flutter/widgets.dart';
import 'package:meridian_ui/meridian_ui.dart';

/// Demonstrates local recording only; an application owns native registration.
class ShortcutFieldDemo extends StatefulWidget {
  const ShortcutFieldDemo({
    super.key,
    this.label = 'Capture area',
    this.enabled = true,
    this.preparing = false,
    this.showLabel = true,
    this.empty = false,
    this.conflict,
  });
  final String label;
  final bool enabled, preparing, showLabel, empty;
  final String? conflict;
  @override
  State<ShortcutFieldDemo> createState() => _ShortcutFieldDemoState();
}

class _ShortcutFieldDemoState extends State<ShortcutFieldDemo> {
  bool _recording = false;
  List<String>? _keys;
  @override
  Widget build(BuildContext context) => MeridianShortcutField(
    label: widget.label,
    emptyLabel: 'No shortcut',
    recordingLabel: 'Press a shortcut',
    preparingLabel: 'Preparing recording',
    clearLabel: 'Clear shortcut',
    keys: _keys ?? (widget.empty ? const [] : const ['Ctrl', 'Shift', '4']),
    enabled: widget.enabled,
    preparing: widget.preparing,
    showLabel: widget.showLabel,
    recording: _recording,
    conflict: widget.conflict == null ? null : Text(widget.conflict!),
    onRecordRequested: () => setState(() => _recording = true),
    onCancelRecording: () => setState(() => _recording = false),
    onClear: () => setState(() {
      _keys = [];
      _recording = false;
    }),
    onRecorded: (stroke) => setState(() {
      _keys = [
        if (stroke.control) 'Ctrl',
        if (stroke.shift) 'Shift',
        if (stroke.alt) 'Alt',
        if (stroke.meta) 'Meta',
        stroke.physicalKey.debugName ?? 'Key',
      ];
      _recording = false;
    }),
  );
}
