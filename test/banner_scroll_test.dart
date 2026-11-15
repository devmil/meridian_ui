import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  for (final width in [390.0, 720.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final density in [MeridianDensity.regular, MeridianDensity.touch]) {
        testWidgets(
          'scroll banner $width $scale $density keeps recovery reachable',
          (tester) async {
            tester.view.physicalSize = Size(width, 480);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            var retried = 0;
            await tester.pumpWidget(
              host(
                MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MeridianBanner(
                                message: 'Der Hintergrund konnte nicht vorbereitet werden.',
                                tone: MeridianBannerTone.error,
                                actions: [
                                  MeridianButton(
                                    label: 'Hintergrund erneut vorbereiten',
                                    size: MeridianControlSize.small,
                                    onPressed: () => retried++,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
                density: density,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final button = find.byType(MeridianButton);
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            await tester.tap(button);
            expect(retried, 1);
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pumpAndSettle();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            expect(retried, 2);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
