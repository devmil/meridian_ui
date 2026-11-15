import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

const command = ValueKey('command'), options = ValueKey('options');

MeridianSplitButton control({
  VoidCallback? onPressed,
  bool compact = false,
  bool loading = false,
  bool success = false,
  bool optionsEnabled = true,
  FocusNode? focus,
  FocusNode? menuFocus,
  VoidCallback? alternate,
}) => MeridianSplitButton(
  label: 'Datei speichern',
  optionsLabel: 'Weitere Speicheraktionen',
  icon: MeridianIcons.save,
  compact: compact,
  loading: loading,
  success: success,
  primaryKey: command,
  optionsKey: options,
  focusNode: focus,
  optionsFocusNode: menuFocus,
  onPressed: onPressed,
  optionsEnabled: optionsEnabled,
  entries: [MeridianMenuItem(label: 'Speichern unter…', onSelected: alternate)],
);

void main() {
  for (final density in [MeridianDensity.regular, MeridianDensity.touch]) {
    for (final compact in [false, true]) {
      testWidgets('fits narrow enlarged text $density compact=$compact', (
        tester,
      ) async {
        var invoked = 0;
        await tester.pumpWidget(
          host(
            SizedBox(
              width: 220,
              child: control(compact: compact, onPressed: () => invoked++),
            ),
            density: density,
            textScale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final primary = tester.getRect(find.byKey(command));
        final caret = tester.getRect(find.byKey(options));
        expect(primary.center.dy, closeTo(caret.center.dy, 1));
        expect(primary.right, lessThanOrEqualTo(caret.left));
        final icon = tester.getRect(
          find.descendant(
            of: find.byKey(command),
            matching: find.byType(MeridianIcon),
          ),
        );
        if (compact) expect(icon.center.dx, closeTo(primary.center.dx, 1));
        final handle = tester.ensureSemantics();
        expect(
          tester.getSemantics(find.byKey(command)),
          matchesSemantics(
            label: 'Datei speichern',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
        await tester.tap(find.byKey(command));
        await tester.pump();
        expect(invoked, 1);
        handle.dispose();
      });
    }
  }

  testWidgets(
    'disabled command retains an independently available alternative',
    (tester) async {
      var invoked = 0;
      await tester.pumpWidget(host(control(alternate: () => invoked++)));
      await tester.tap(find.byKey(command));
      await tester.tap(find.byKey(options));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern unter…'));
      await tester.pumpAndSettle();
      expect(invoked, 1);
      expect(find.byType(MeridianMenuSurface), findsNothing);
    },
  );

  testWidgets('disabled options leave the command available', (tester) async {
    var invoked = 0;
    await tester.pumpWidget(
      host(control(onPressed: () => invoked++, optionsEnabled: false)),
    );
    await tester.tap(find.byKey(options));
    await tester.pumpAndSettle();
    expect(find.byType(MeridianMenuSurface), findsNothing);
    await tester.tap(find.byKey(command));
    await tester.pump();
    expect(invoked, 1);
  });

  testWidgets('native menu receives the whole control anchor', (tester) async {
    Rect? observed;
    await tester.pumpWidget(
      host(
        MeridianMenuPresenter(
          present: (context, {required Rect anchor, required entries}) async {
            observed = anchor;
          },
          child: control(onPressed: () {}),
        ),
      ),
    );
    final bounds = tester.getRect(find.byType(MeridianSplitButton));
    await tester.tap(find.byKey(options));
    await tester.pumpAndSettle();
    expect(observed, bounds);
  });

  testWidgets('keyboard dismissal restores caret focus', (tester) async {
    final menuFocus = FocusNode();
    try {
      await tester.pumpWidget(
        host(control(onPressed: () {}, menuFocus: menuFocus, alternate: () {})),
      );
      menuFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byType(MeridianMenuSurface), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(MeridianMenuSurface), findsNothing);
      expect(menuFocus.hasFocus, true);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      menuFocus.dispose();
    }
  });

  for (final compact in [false, true]) {
    testWidgets(
      'feedback suppresses activation and keeps focus compact=$compact',
      (tester) async {
        var invoked = 0;
        final focus = FocusNode();
        try {
          await tester.pumpWidget(
            host(
              control(
                compact: compact,
                focus: focus,
                onPressed: () => invoked++,
              ),
            ),
          );
          await tester.tap(find.byKey(command));
          await tester.pump();
          expect(focus.hasFocus, true);
          await tester.pumpWidget(
            host(
              control(
                compact: compact,
                focus: focus,
                loading: true,
                onPressed: () => invoked++,
              ),
            ),
          );
          await tester.pump(
            MeridianDurations.spinnerDelay + const Duration(milliseconds: 1),
          );
          expect(
            find.descendant(
              of: find.byKey(command),
              matching: find.byType(MeridianSpinner),
            ),
            findsOneWidget,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(invoked, 1);
          expect(focus.hasFocus, true);
          await tester.pumpWidget(
            host(
              control(
                compact: compact,
                focus: focus,
                success: true,
                onPressed: () => invoked++,
              ),
            ),
          );
          await tester.pump(MeridianDurations.quick);
          expect(
            find.descendant(
              of: find.byKey(command),
              matching: find.byType(MeridianStrokeIcon),
            ),
            findsOneWidget,
          );
          await tester.pump(MeridianDurations.hold + MeridianDurations.quick);
          expect(focus.hasFocus, true);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          focus.dispose();
        }
      },
    );
  }
}
