import 'package:flutter/widgets.dart';

import '../foundation/meridian_icons.g.dart';
import 'actions.dart';
import 'menu.dart';

/// Default command and independent alternatives, with one shared menu anchor.
/// Workflows and the availability of individual entries belong to the consumer.
class MeridianSplitButton extends StatefulWidget {
  const MeridianSplitButton({
    required this.label,
    required this.optionsLabel,
    required this.onPressed,
    required this.entries,
    super.key,
    this.icon,
    this.compact = false,
    this.loading = false,
    this.success = false,
    this.optionsEnabled = true,
    this.variant = MeridianButtonVariant.primary,
    this.size = MeridianControlSize.regular,
    this.disabledReason,
    this.optionsDisabledReason,
    this.primaryKey,
    this.optionsKey,
    this.focusNode,
    this.optionsFocusNode,
  }) : assert(!compact || icon != null);

  final String label, optionsLabel;
  final VoidCallback? onPressed;
  final List<MeridianMenuEntry> entries;
  final String? icon, disabledReason, optionsDisabledReason;
  final bool compact, loading, success, optionsEnabled;
  final MeridianButtonVariant variant;
  final MeridianControlSize size;
  final Key? primaryKey, optionsKey;
  final FocusNode? focusNode, optionsFocusNode;

  @override
  State<MeridianSplitButton> createState() => _MeridianSplitButtonState();
}

class _MeridianSplitButtonState extends State<MeridianSplitButton> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => MeridianMenuAnchor(
    entries: widget.entries,
    onOpenChanged: (expanded) {
      if (mounted) setState(() => _expanded = expanded);
    },
    builder: (context, open) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: MeridianButton(
            key: widget.primaryKey,
            label: widget.label,
            icon: widget.icon,
            iconOnly: widget.compact,
            variant: widget.variant,
            size: widget.size,
            loading: widget.loading,
            success: widget.success,
            disabledReason: widget.disabledReason,
            focusNode: widget.focusNode,
            onPressed: widget.onPressed,
          ),
        ),
        Semantics(
          button: true,
          enabled: widget.optionsEnabled,
          expanded: _expanded,
          label: widget.optionsLabel,
          hint: widget.optionsEnabled ? null : widget.optionsDisabledReason,
          excludeSemantics: true,
          onTap: widget.optionsEnabled ? open : null,
          child: MeridianIconButton(
            key: widget.optionsKey,
            label: widget.optionsLabel,
            icon: MeridianIcons.chevronDown,
            size: widget.size,
            turns: _expanded ? 0.5 : 0,
            focusNode: widget.optionsFocusNode,
            disabledReason: widget.optionsDisabledReason,
            onPressed: widget.optionsEnabled ? open : null,
          ),
        ),
      ],
    ),
  );
}
