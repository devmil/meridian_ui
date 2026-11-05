import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';

/// Decorative bounded audio peaks, independent of decoding and seeking.
/// Consumers provide separate labelled controls for playback and trim.
class MeridianWaveform extends StatelessWidget {
  MeridianWaveform({
    required List<double> peaks,
    super.key,
    this.progress,
    this.height = MeridianLayout.waveformHeight,
  }) : peaks = _copyPeaks(peaks) {
    if (!height.isFinite ||
        height <= 0 ||
        progress != null &&
            (!progress!.isFinite || progress! < 0 || progress! > 1)) {
      throw ArgumentError(
        'MeridianWaveform requires valid height and progress.',
      );
    }
  }
  static const maximumPeaks = 1024;
  final List<double> peaks;
  final double? progress;
  final double height;
  static List<double> _copyPeaks(List<double> values) {
    if (values.length > maximumPeaks ||
        values.any((v) => !v.isFinite || v < 0 || v > 1)) {
      throw ArgumentError(
        'MeridianWaveform requires bounded normalized peaks.',
      );
    }
    return List<double>.unmodifiable(values);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.meridian.colors;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : MeridianLayout.sliderDefaultWidth;
              return SizedBox(
                width: width,
                child: CustomPaint(
                  painter: _WaveformPainter(
                    peaks: peaks,
                    progress: progress,
                    direction: Directionality.of(context),
                    ink: colors.inkMuted,
                    accent: colors.accent,
                    stroke: MeridianLayout.waveformMinimumPeakHeight,
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

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.peaks,
    required this.progress,
    required this.direction,
    required this.ink,
    required this.accent,
    required this.stroke,
  });
  final List<double> peaks;
  final double? progress;
  final TextDirection direction;
  final Color ink, accent;
  final double stroke;
  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty || size.isEmpty) return;
    final step = size.width / peaks.length;
    final gap = math.min(stroke / 2, step / 3);
    final path = Path();
    for (var index = 0; index < peaks.length; index++) {
      final height = math.max(
        math.min(stroke, size.height),
        peaks[index] * size.height,
      );
      final x = direction == TextDirection.rtl
          ? size.width - (index + 1) * step
          : index * step;
      path.addRect(
        Rect.fromLTWH(
          x + gap / 2,
          (size.height - height) / 2,
          step - gap,
          height,
        ),
      );
    }
    canvas.drawPath(path, Paint()..color = ink);
    if (progress != null && progress! > 0) {
      canvas.save();
      final width = size.width * progress!;
      canvas.clipRect(
        Rect.fromLTWH(
          direction == TextDirection.rtl ? size.width - width : 0,
          0,
          width,
          size.height,
        ),
      );
      canvas.drawPath(path, Paint()..color = accent);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      !listEquals(peaks, old.peaks) ||
      progress != old.progress ||
      direction != old.direction ||
      ink != old.ink ||
      accent != old.accent ||
      stroke != old.stroke;
}
