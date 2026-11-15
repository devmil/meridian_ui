import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('JetBrainsMono');
    loader.addFont(
      Future.value(
        ByteData.sublistView(
          await File('assets/fonts/JetBrainsMono-Regular.ttf').readAsBytes(),
        ),
      ),
    );
    await loader.load();
  });
  final brand = MeridianBrands.shotlama.copyWith(
    fonts: MeridianBrands.shotlama.fonts.copyWith(sans: 'JetBrainsMono'),
  );
  for (final density in [MeridianDensity.regular, MeridianDensity.touch]) {
    for (final direction in TextDirection.values) {
      testWidgets('long action stays readable at 200% $density $direction', (
        tester,
      ) async {
        const message = 'Unter /synthetic/export/image.png gesichert';
        const action = 'Im Ordner zeigen';
        var activated = 0;
        var dismissed = 0;
        await tester.pumpWidget(
          host(
            SizedBox(
              width: 320,
              child: MeridianToast(
                message: message,
                tone: MeridianToastTone.success,
                actionLabel: action,
                onAction: () => activated++,
                onDismiss: () => dismissed++,
              ),
            ),
            brand: brand,
            density: density,
            textScale: 2,
            textDirection: direction,
          ),
        );
        await tester.pumpAndSettle();
        final text = tester.getRect(find.text(message));
        final button = tester.getRect(
          find.byWidgetPredicate(
            (w) => w is MeridianButton && w.label == action,
          ),
        );
        final toast = tester.getRect(find.byType(MeridianToast));
        expect(text.width, greaterThan(toast.width / 2));
        expect(button.top, greaterThanOrEqualTo(text.bottom));
        expect(toast.contains(button.topLeft), true);
        expect(toast.contains(button.bottomRight - const Offset(.1, .1)), true);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(message),
        );
        expect(paragraph.didExceedMaxLines, false);
        expect(
          paragraph
              .getBoxesForSelection(
                const TextSelection(
                  baseOffset: 0,
                  extentOffset: message.length,
                ),
              )
              .length,
          lessThanOrEqualTo(5),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(action));
        expect(activated, 1);
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is MeridianIconButton && w.icon == 'x',
          ),
        );
        expect(dismissed, 1);
      });
    }
  }

  testWidgets('short action stays inline and accepts keyboard activation', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        MeridianToast(
          message: 'Saved',
          actionLabel: 'Undo',
          onAction: () => calls++,
        ),
        brand: brand,
      ),
    );
    await tester.pumpAndSettle();
    final message = tester.getRect(find.text('Saved'));
    final action = tester.getRect(find.text('Undo'));
    expect((message.center.dy - action.center.dy).abs(), lessThanOrEqualTo(1));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(calls, 1);
  });

  testWidgets('an absent action callback leaves only the complete message', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 240,
          child: MeridianToast(
            message: 'The complete result message',
            actionLabel: 'Unavailable',
          ),
        ),
        brand: brand,
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unavailable'), findsNothing);
    expect(find.text('The complete result message'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
