import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  for (final contextMenu in [false, true]) {
    for (final keyboard in [false, true]) {
      for (final reduced in [false, true]) {
        testWidgets(
          'selection waits for actual teardown, keyboard=$keyboard reduced=$reduced context=$contextMenu',
          (tester) async {
            tester.view.physicalSize = const Size(240, 400);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            var calls = 0;
            var menuGone = false;
            await tester.pumpWidget(
              host(
                Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(disableAnimations: reduced),
                    child: Builder(
                      builder: (context) {
                        final entries = <MeridianMenuEntry>[
                          const MeridianMenuItem(label: 'Unavailable'),
                          MeridianMenuItem(
                            label: 'Save As',
                            onSelected: () {
                              calls++;
                              menuGone = find
                                  .byType(MeridianMenuSurface)
                                  .evaluate()
                                  .isEmpty;
                              showMeridianDialog<void>(
                                context: context,
                                builder: (context) => MeridianDialog(
                                  title: 'Export',
                                  content: const Text('Choose format'),
                                  actions: [
                                    MeridianButton(
                                      label: 'Cancel',
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ];
                        if (contextMenu) {
                          return MeridianButton(
                            label: 'More',
                            onPressed: () => showMeridianContextMenu(
                              context,
                              globalPosition: const Offset(20, 50),
                              entries: entries,
                            ),
                          );
                        }
                        return MeridianMenuAnchor(
                          entries: entries,
                          builder: (context, open) =>
                              MeridianButton(label: 'More', onPressed: open),
                        );
                      },
                    ),
                  ),
                ),
                density: contextMenu
                    ? MeridianDensity.touch
                    : MeridianDensity.regular,
              ),
            );
            for (var cycle = 0; cycle < 2; cycle++) {
              await tester.tap(find.text('More'));
              await tester.pumpAndSettle();
              if (keyboard) {
                await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
                await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              } else {
                await tester.tap(find.text('Save As'));
              }
              await tester.pump();
              if (find.byType(MeridianMenuSurface).evaluate().isNotEmpty) {
                expect(calls, cycle);
              }
              await tester.pumpAndSettle();
              expect(calls, cycle + 1);
              expect(menuGone, isTrue);
              expect(find.byType(MeridianMenuSurface), findsNothing);
              expect(find.text('Choose format'), findsOneWidget);
              await tester.tap(find.text('Cancel'));
              await tester.pumpAndSettle();
            }
            await tester.tap(find.text('More'));
            await tester.pumpAndSettle();
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
            expect(calls, 2);
            expect(find.byType(MeridianMenuSurface), findsNothing);
          },
        );
      }
    }
  }
  testWidgets(
    'unmounted trigger cannot dispatch a selected action after exit',
    (tester) async {
      var calls = 0;
      final visible = ValueNotifier(true);
      await tester.pumpWidget(
        host(
          ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (context, value, _) => value
                ? Builder(
                    builder: (context) => MeridianMenuAnchor(
                      entries: [
                        MeridianMenuItem(
                          label: 'Save As',
                          onSelected: () => calls++,
                        ),
                      ],
                      builder: (context, open) =>
                          MeridianButton(label: 'More', onPressed: open),
                    ),
                  )
                : const SizedBox(),
          ),
        ),
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save As'));
      visible.value = false;
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.pumpWidget(const SizedBox());
      visible.dispose();
    },
  );
}
