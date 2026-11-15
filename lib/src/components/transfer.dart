import 'dart:ui' show PathMetric;

import 'package:flutter/widgets.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';

/// What a [MeridianDropZone] shows.
enum MeridianDropZoneState {
  /// Nothing is dragged over it: a `line-strong` dashed edge.
  idle,

  /// Acceptable files are over it: `accent` edge on `accent-soft`.
  active,

  /// The dragged files cannot go here: `danger` edge and text.
  invalid,
}

/// A dashed area that takes dropped files (attachments, imports), with an
/// icon, a label and an optional [message]. With [onBrowse] it is also a
/// button that opens a file picker, so the drop is never the only way.
///
/// The app owns the drag transport and sets [state]; the zone only draws.
class MeridianDropZone extends StatelessWidget {
  const MeridianDropZone({
    required this.label,
    super.key,
    this.message,
    this.icon = MeridianIcons.upload,
    this.state = MeridianDropZoneState.idle,
    this.onBrowse,
  });

  /// What to do ("Drop files to attach").
  final String label;

  /// A detail under the label ("Up to 25 MB").
  final String? message;
  final String icon;
  final MeridianDropZoneState state;

  /// Opens a file picker on click, Enter or Space.
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final radius = BorderRadius.circular(meridian.radius.lg);
    final (edge, ink, fill) = switch (state) {
      MeridianDropZoneState.idle => (
        colors.lineStrong,
        colors.inkMuted,
        meridianClear(colors.accentSoft),
      ),
      MeridianDropZoneState.active => (
        colors.accent,
        colors.accentInk,
        colors.accentSoft,
      ),
      MeridianDropZoneState.invalid => (
        colors.danger,
        colors.danger,
        meridianClear(colors.accentSoft),
      ),
    };
    final duration = MeridianMotion.of(context, MeridianDurations.select);
    Widget zone(MeridianInteractionState? interaction) {
      final hovered = interaction != null && interaction.hovered;
      return TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: hovered ? colors.inkMuted : edge),
        duration: duration,
        curve: MeridianDurations.selectCurve,
        // While a drag is over it the dashes march (MM-77).
        builder: (context, color, child) => _Marching(
          active: state == MeridianDropZoneState.active,
          builder: (phase) => CustomPaint(
            foregroundPainter: _DashedEdgePainter(
              color: color ?? edge,
              radius: radius,
              phase: phase,
            ),
            child: child,
          ),
        ),
        child: AnimatedContainer(
          duration: MeridianMotion.of(context, MeridianDurations.quick),
          curve: MeridianDurations.quickCurve,
          constraints: const BoxConstraints(
            minHeight: MeridianLayout.dropZoneMinHeight,
          ),
          padding: const EdgeInsets.all(MeridianSpace.space6),
          decoration: BoxDecoration(color: fill, borderRadius: radius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MeridianIcon(
                icon,
                extent: MeridianLayout.dropZoneIconSize,
                color: ink,
              ),
              const SizedBox(height: MeridianSpace.space3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: meridian.text.label.copyWith(color: ink),
              ),
              if (message case final detail?) ...[
                const SizedBox(height: MeridianSpace.space1),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: meridian.text.caption.copyWith(
                    color: state == MeridianDropZoneState.invalid
                        ? colors.danger
                        : colors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final browse = onBrowse;
    if (browse == null) {
      return Semantics(
        container: true,
        label: [label, message].whereType<String>().join(', '),
        excludeSemantics: true,
        child: zone(null),
      );
    }
    return Semantics(
      excludeSemantics: true,
      button: true,
      label: [label, message].whereType<String>().join(', '),
      onTap: browse,
      child: MeridianInteraction(
        onTap: browse,
        borderRadius: radius,
        builder: (context, state) => zone(state),
      ),
    );
  }
}

/// Advances a dash phase 0 → 1 every `motion-march` while [active];
/// still under reduce motion.
class _Marching extends StatefulWidget {
  const _Marching({required this.active, required this.builder});

  final bool active;
  final Widget Function(double phase) builder;

  @override
  State<_Marching> createState() => _MarchingState();
}

class _MarchingState extends State<_Marching>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phase = AnimationController(
    vsync: this,
    duration: MeridianDurations.march,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Marching oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final march = widget.active && !MeridianMotion.reduced(context);
    if (march && !_phase.isAnimating) {
      _phase.repeat();
    } else if (!march && _phase.isAnimating) {
      _phase.stop();
    }
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _phase,
    builder: (context, _) => widget.builder(_phase.value),
  );
}

class _DashedEdgePainter extends CustomPainter {
  const _DashedEdgePainter({
    required this.color,
    required this.radius,
    this.phase = 0,
  });

  final Color color;
  final BorderRadius radius;

  /// How far the dashes have marched, in dash periods.
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = MeridianLayout.hairline;
    final rrect = radius.toRRect(Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const period = MeridianLayout.dropZoneDash + MeridianLayout.dropZoneDashGap;
    for (final PathMetric metric
        in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = phase == 0 ? 0.0 : (phase - 1) * period;
      while (distance < metric.length) {
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + MeridianLayout.dropZoneDash).clamp(
          0.0,
          metric.length,
        );
        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }
        distance += period;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedEdgePainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      phase != oldDelegate.phase;
}
