import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

Widget shell(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  MeridianDensity density = MeridianDensity.regular,
}) => MaterialApp(
  theme: buildMeridianTheme(
    brand: MeridianBrands.shotlama,
    brightness: Brightness.light,
    density: density,
  ),
  home: Directionality(
    textDirection: direction,
    child: Center(child: child),
  ),
);
void main() {
  for (final direction in TextDirection.values) {
    testWidgets('painted amplitude and progress follow $direction', (
      tester,
    ) async {
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        shell(
          RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: 80,
              child: MeridianWaveform(
                peaks: const [0.25, 1],
                height: 40,
                progress: 0.5,
              ),
            ),
          ),
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(MeridianWaveform));
      final colors = context.meridian.colors;
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          Color pixel(int x, int y) {
            final offset = (y * image.width + x) * 4;
            return Color.fromARGB(
              pixels.getUint8(offset + 3),
              pixels.getUint8(offset),
              pixels.getUint8(offset + 1),
              pixels.getUint8(offset + 2),
            );
          }

          final firstX = direction == TextDirection.ltr ? 20 : 60;
          final secondX = direction == TextDirection.ltr ? 60 : 20;
          expect(pixel(firstX, 20), colors.accent);
          expect(pixel(secondX, 20), colors.inkMuted);
          expect(pixel(firstX, 5).a, 0);
          expect(pixel(secondX, 5), colors.inkMuted);
        } finally {
          image.dispose();
        }
      });
    });
  }
  test('peaks are bounded normalized and copied before painting', () {
    final source = [0.25, 0.75];
    final widget = MeridianWaveform(peaks: source);
    source[0] = 1;
    expect(widget.peaks, [0.25, 0.75]);
    expect(() => widget.peaks.add(0), throwsUnsupportedError);
    for (final invalid in [
      [double.nan],
      [double.infinity],
      [-0.01],
      [1.01],
      List<double>.filled(MeridianWaveform.maximumPeaks + 1, 0),
    ]) {
      expect(() => MeridianWaveform(peaks: invalid), throwsArgumentError);
    }
    for (final invalid in [double.nan, double.infinity, -0.1, 1.1]) {
      expect(
        () => MeridianWaveform(peaks: const [], progress: invalid),
        throwsArgumentError,
      );
    }
    for (final invalid in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => MeridianWaveform(peaks: const [], height: invalid),
        throwsArgumentError,
      );
    }
  });
  for (final density in [MeridianDensity.regular, MeridianDensity.touch]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'bounded static painting $density $direction at narrow and full width',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(1400, 700);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          for (final width in [0.0, 1.0, 40.0, 390.0, 1280.0]) {
            await tester.pumpWidget(
              shell(
                SizedBox(
                  width: width,
                  child: MeridianWaveform(
                    peaks: List.generate(1024, (i) => i / 1023),
                    progress: 0.37,
                  ),
                ),
                density: density,
                direction: direction,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(tester.getSize(find.byType(MeridianWaveform)).width, width);
            expect(tester.hasRunningAnimations, isFalse);
          }
        },
      );
    }
  }
  testWidgets(
    'decorative input passes to its owner and adds no semantics or focus',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        var tapped = 0;
        await tester.pumpWidget(
          shell(
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => tapped++,
              child: SizedBox(
                width: 200,
                child: MeridianWaveform(peaks: const [0, 0.5, 1]),
              ),
            ),
          ),
        );
        await tester.tapAt(tester.getCenter(find.byType(MeridianWaveform)));
        await tester.pump();
        expect(tapped, 1);
        expect(
          find.descendant(
            of: find.byType(MeridianWaveform),
            matching: find.byType(Focus),
          ),
          findsNothing,
        );
        expect(
          tester
              .getSemantics(find.byType(MeridianWaveform))
              .getSemanticsData()
              .label,
          isEmpty,
        );
      } finally {
        handle.dispose();
      }
    },
  );
  testWidgets(
    'unbounded width uses shared fallback and confirmed progress repaints',
    (tester) async {
      await tester.pumpWidget(
        shell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianWaveform(peaks: const [0.25, 0.75]),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(MeridianWaveform)).width,
        MeridianLayout.sliderDefaultWidth,
      );
      await tester.pumpWidget(
        shell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianWaveform(peaks: const [0.75, 0.25], progress: 1),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
}
