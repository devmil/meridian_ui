import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'support.dart';

void main() {
  for (final reduced in [false, true]) {
    for (final dismiss in ['pointer', 'keyboard', 'escape', 'barrier']) {
      testWidgets(
        'popover result follows teardown: $dismiss reduced=$reduced',
        (tester) async {
          tester.view.physicalSize = const Size(390, 600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          var completions = 0;
          String? result;
          var surfaceGone = false;
          await tester.pumpWidget(
            host(
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: reduced),
                  child: Builder(
                    builder: (context) => MeridianButton(
                      label: 'Open',
                      onPressed: () async {
                        result = await showMeridianPopover<String>(
                          context,
                          anchor: const Rect.fromLTWH(20, 40, 100, 40),
                          builder: (context) => MeridianButton(
                            label: 'Confirm',
                            onPressed: () =>
                                Navigator.of(context).pop('confirmed'),
                          ),
                        );
                        completions++;
                        surfaceGone = find
                            .byType(MeridianPopoverSurface)
                            .evaluate()
                            .isEmpty;
                      },
                    ),
                  ),
                ),
              ),
              density: MeridianDensity.touch,
            ),
          );
          for (var cycle = 0; cycle < 2; cycle++) {
            await tester.tap(find.text('Open'));
            await tester.pumpAndSettle();
            expect(find.byType(MeridianPopoverSurface), findsOneWidget);
            switch (dismiss) {
              case 'pointer':
                await tester.tap(find.text('Confirm'));
              case 'keyboard':
                await tester.sendKeyEvent(LogicalKeyboardKey.tab);
                await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              case 'escape':
                await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              case 'barrier':
                await tester.tapAt(const Offset(5, 580));
            }
            await tester.pump();
            if (find.byType(MeridianPopoverSurface).evaluate().isNotEmpty) {
              expect(completions, cycle);
            }
            await tester.pumpAndSettle();
            expect(completions, cycle + 1);
            expect(surfaceGone, isTrue);
            expect(
              result,
              ['pointer', 'keyboard'].contains(dismiss) ? 'confirmed' : null,
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets('unmounted popover trigger completes after surface removal', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    var completed = false;
    var surfaceGone = false;
    await tester.pumpWidget(
      host(
        ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (context, value, _) => value
              ? MeridianButton(
                  label: 'Open',
                  onPressed: () async {
                    await showMeridianPopover<void>(
                      context,
                      anchor: const Rect.fromLTWH(20, 40, 100, 40),
                      builder: (context) => MeridianButton(
                        label: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    );
                    completed = true;
                    surfaceGone = find
                        .byType(MeridianPopoverSurface)
                        .evaluate()
                        .isEmpty;
                  },
                )
              : const SizedBox(),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    visible.value = false;
    await tester.pump();
    if (find.byType(MeridianPopoverSurface).evaluate().isNotEmpty) {
      expect(completed, isFalse);
    }
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(surfaceGone, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    visible.dispose();
  });
}
