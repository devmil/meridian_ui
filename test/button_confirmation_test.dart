import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets(
      'label confirmation retains width, name and focus reduced=$reduced',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final focus = FocusNode();
        var success = false;
        var completions = 0;
        late StateSetter update;
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: reduced),
                  child: MeridianButton(
                    label: 'Kennung kopieren',
                    icon: MeridianIcons.copy,
                    shortcut: const ['⌘', 'C'],
                    focusNode: focus,
                    success: success,
                    successReplacesLabel: true,
                    onSuccessFinished: () => completions++,
                    onPressed: () {},
                  ),
                );
              },
            ),
            textScale: 2,
          ),
        );
        try {
          await tester.pumpAndSettle();
          focus.requestFocus();
          await tester.pump();
          final size = tester.getSize(find.byType(MeridianButton));
          update(() => success = true);
          await tester.pump();
          await tester.pump(MeridianDurations.quick);
          expect(tester.getSize(find.byType(MeridianButton)), size);
          expect(focus.hasFocus, isTrue);
          expect(
            tester
                .getSemantics(find.bySemanticsLabel('Kennung kopieren'))
                .label,
            'Kennung kopieren',
          );
          expect(
            tester
                .widget<MeridianStrokeIcon>(find.byType(MeridianStrokeIcon))
                .drawn,
            isTrue,
          );
          final labelFade = find
              .ancestor(
                of: find.text('Kennung kopieren'),
                matching: find.byType(FadeTransition),
              )
              .first;
          expect(tester.widget<FadeTransition>(labelFade).opacity.value, 0);
          expect(completions, 0);
          await tester.pump(MeridianDurations.hold - MeridianDurations.quick);
          expect(completions, 1);
          await tester.pump(MeridianDurations.quick);
          expect(tester.widget<FadeTransition>(labelFade).opacity.value, 1);
          expect(tester.getSize(find.byType(MeridianButton)), size);
          expect(focus.hasFocus, isTrue);
          // Value refreshes cannot replay the completed edge.
          update(() {});
          await tester.pumpAndSettle();
          await tester.pump(MeridianDurations.hold);
          expect(completions, 1);
          expect(tester.binding.hasScheduledFrame, isFalse);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          focus.dispose();
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('mounting successful output cannot replay its old confirmation', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        MeridianButton(
          label: 'Copy',
          success: true,
          successReplacesLabel: true,
          onSuccessFinished: () => calls++,
          onPressed: () {},
        ),
      ),
    );
    await tester.pump(MeridianDurations.hold);
    expect(calls, 0);
    expect(
      tester.widget<MeridianStrokeIcon>(find.byType(MeridianStrokeIcon)).drawn,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final replace in [false, true]) {
    for (final interruption in ['cleared success', 'new loading', 'dispose']) {
      testWidgets('$interruption cancels success callback replace=$replace', (
        tester,
      ) async {
        var success = false;
        var loading = false;
        var calls = 0;
        late StateSetter update;
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (_, setState) {
                update = setState;
                return MeridianButton(
                  label: 'Save',
                  success: success,
                  loading: loading,
                  successReplacesLabel: replace,
                  onSuccessFinished: () => calls++,
                  onPressed: () {},
                );
              },
            ),
          ),
        );
        update(() => success = true);
        await tester.pump();
        await tester.pump(MeridianDurations.quick);
        if (interruption == 'dispose') {
          await tester.pumpWidget(const SizedBox.shrink());
        } else {
          update(() {
            if (interruption == 'new loading') {
              loading = true;
            } else {
              success = false;
            }
          });
          await tester.pump();
        }
        await tester.pump(MeridianDurations.hold);
        expect(calls, 0);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(tester.binding.hasScheduledFrame, isFalse);
      });
    }
  }

  testWidgets('hold completion stays bound to its original callback', (
    tester,
  ) async {
    var success = false;
    var first = 0;
    var later = 0;
    VoidCallback completed = () => first++;
    late StateSetter update;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (_, setState) {
            update = setState;
            return MeridianButton(
              label: 'Copy',
              success: success,
              successReplacesLabel: true,
              onSuccessFinished: completed,
              onPressed: () {},
            );
          },
        ),
      ),
    );
    update(() => success = true);
    await tester.pump();
    await tester.pump(MeridianDurations.quick);
    update(() => completed = () => later++);
    await tester.pump();
    await tester.pump(MeridianDurations.hold - MeridianDurations.quick);
    expect(first, 1);
    expect(later, 0);
    update(() => success = false);
    await tester.pump();
    update(() => success = true);
    await tester.pump();
    await tester.pump(MeridianDurations.hold);
    expect(first, 1);
    expect(later, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'replacement cancels the old hold and completes only the new one',
    (tester) async {
      var success = false;
      var calls = 0;
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, setState) {
              update = setState;
              return MeridianButton(
                label: 'Copy',
                success: success,
                successReplacesLabel: true,
                onSuccessFinished: () => calls++,
                onPressed: () {},
              );
            },
          ),
        ),
      );
      update(() => success = true);
      await tester.pump();
      await tester.pump(MeridianDurations.quick);
      update(() => success = false);
      await tester.pump();
      update(() => success = true);
      await tester.pump();
      await tester.pump(MeridianDurations.hold - MeridianDurations.quick);
      expect(calls, 0);
      await tester.pump(MeridianDurations.quick);
      expect(calls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'retained leading GlobalKey is mounted once across confirmation',
    (tester) async {
      final key = GlobalKey();
      var success = false;
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, setState) {
              update = setState;
              return MeridianButton(
                label: 'Copy',
                leading: SizedBox(key: key, width: 16, height: 16),
                success: success,
                successReplacesLabel: true,
                onPressed: () {},
              );
            },
          ),
        ),
      );
      final element = key.currentContext;
      update(() => success = true);
      await tester.pump();
      await tester.pump(MeridianDurations.hold);
      expect(key.currentContext, same(element));
      expect(find.byKey(key), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'loading ignores pointer and keyboard activation but preserves focus',
    (tester) async {
      final focus = FocusNode();
      var loading = false;
      var success = false;
      var presses = 0;
      var completed = 0;
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, setState) {
              update = setState;
              return MeridianButton(
                label: 'Copy',
                loading: loading,
                success: success,
                successReplacesLabel: true,
                focusNode: focus,
                onSuccessFinished: () => completed++,
                onPressed: () => presses++,
              );
            },
          ),
        ),
      );
      try {
        focus.requestFocus();
        await tester.pump();
        update(() => loading = true);
        await tester.pump();
        await tester.pump(MeridianDurations.spinnerDelay);
        expect(find.byType(MeridianSpinner), findsOneWidget);
        await tester.tap(find.byType(MeridianButton));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(presses, 0);
        expect(focus.hasFocus, isTrue);
        update(() {
          loading = false;
          success = true;
        });
        await tester.pump();
        await tester.pump(MeridianDurations.quick);
        expect(find.byType(MeridianSpinner), findsNothing);
        await tester.pump(MeridianDurations.hold - MeridianDurations.quick);
        expect(completed, 1);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        focus.dispose();
      }
    },
  );

  for (final brand in MeridianBrands.all) {
    for (final density in [MeridianDensity.regular, MeridianDensity.touch]) {
      testWidgets(
        'confirmation fits enlarged text ${brand.name} ${density.name}',
        (tester) async {
          var success = false;
          late StateSetter update;
          await tester.pumpWidget(
            host(
              StatefulBuilder(
                builder: (_, setState) {
                  update = setState;
                  return SizedBox(
                    width: 340,
                    child: MeridianButton(
                      label: 'Kennung kopieren',
                      success: success,
                      successReplacesLabel: true,
                      expand: true,
                      size: MeridianControlSize.small,
                      onPressed: () {},
                    ),
                  );
                },
              ),
              brand: brand,
              density: density,
              textScale: 2,
              brightness: Brightness.dark,
            ),
          );
          final size = tester.getSize(find.byType(MeridianButton));
          update(() => success = true);
          await tester.pump();
          await tester.pump(MeridianDurations.hold);
          expect(tester.getSize(find.byType(MeridianButton)), size);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
