import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  testWidgets(
    'arrows wrap results and Enter activates without moving field focus',
    (tester) async {
      var selected = 0;
      var count = 3;
      final activated = <int>[];
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SizedBox(
                width: 250,
                child: MeridianResultNavigation(
                  itemCount: count,
                  selectedIndex: selected,
                  onSelected: (index) => setState(() => selected = index),
                  onActivate: activated.add,
                  child: const MeridianTextField(autofocus: true),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final focus = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(selected, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(activated, [1]);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(selected, 2);
      expect(FocusManager.instance.primaryFocus, same(focus));
      update(() => count = 0);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(activated, [1]);
    },
  );
}
