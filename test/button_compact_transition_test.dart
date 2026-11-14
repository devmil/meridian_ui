import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  for (final density in [MeridianDensity.regular, MeridianDensity.touch]) {
    for (final size in MeridianControlSize.values) {
      testWidgets(
        'compact presentation retains feedback and focus $density $size',
        (tester) async {
          final focus = FocusNode();
          final semantics = tester.ensureSemantics();
          var compact = false, loading = false, success = false;
          var presses = 0, completions = 0;
          late StateSetter update;
          try {
            await tester.pumpWidget(
              host(
                StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return Center(
                      child: MeridianButton(
                        label: 'Datei speichern',
                        icon: MeridianIcons.save,
                        iconOnly: compact,
                        size: size,
                        focusNode: focus,
                        loading: loading,
                        success: success,
                        onSuccessFinished: () => completions++,
                        onPressed: () => presses++,
                      ),
                    );
                  },
                ),
                density: density,
                textScale: 2,
              ),
            );
            focus.requestFocus();
            await tester.pump();
            update(() => loading = true);
            await tester.pump();
            await tester.pump(MeridianDurations.spinnerDelay);
            update(() => compact = true);
            await tester.pump();
            expect(tester.takeException(), isNull);
            await tester.pump(MeridianDurations.quick ~/ 2);
            expect(tester.takeException(), isNull);
            expect(focus.hasFocus, true);
            expect(find.byType(MeridianSpinner), findsOneWidget);
            expect(
              tester
                  .getSemantics(find.bySemanticsLabel('Datei speichern'))
                  .label,
              'Datei speichern',
            );
            await tester.tap(find.byType(MeridianButton));
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            expect(presses, 0);
            update(() {
              loading = false;
              success = true;
            });
            await tester.pump();
            await tester.pump(MeridianDurations.quick);
            update(() => compact = false);
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(focus.hasFocus, true);
            await tester.pump(MeridianDurations.hold);
            expect(completions, 1);
            update(() => compact = true);
            await tester.pump();
            expect(tester.takeException(), isNull);
            await tester.pumpAndSettle();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            expect(presses, 1);
            expect(focus.hasFocus, true);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
            focus.dispose();
            semantics.dispose();
          }
        },
      );
    }
  }
}
