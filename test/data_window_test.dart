import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

const _properties = [
  MeridianProperty(label: 'Parent PID', value: '1', monospace: true),
  MeridianProperty(label: 'Status', value: 'Running'),
];

void main() {
  group('MeridianPropertyList', () {
    testWidgets('puts labels beside values when wide', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 400,
            child: MeridianPropertyList(properties: _properties),
          ),
        ),
      );
      final label = tester.getTopLeft(find.text('Parent PID'));
      final value = tester.getTopLeft(find.text('1'));
      expect(value.dx - label.dx, greaterThanOrEqualTo(112));
      expect((value.dy - label.dy).abs(), lessThan(MeridianSpace.space4));
      expect(textColor(tester, 'Parent PID'), colorsOf(tester).inkMuted);
    });

    testWidgets('stacks labels above values when narrow', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            child: MeridianPropertyList(properties: _properties),
          ),
        ),
      );
      final label = tester.getRect(find.text('Parent PID'));
      final value = tester.getTopLeft(find.text('1'));
      expect(value.dx, closeTo(label.left, 0.5));
      expect(value.dy, greaterThanOrEqualTo(label.bottom));
    });

    testWidgets('sets monospace values in the code face with tabular '
        'figures', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 400,
            child: MeridianPropertyList(properties: _properties),
          ),
        ),
      );
      final value = tester.widget<SelectableText>(
        find.widgetWithText(SelectableText, '1'),
      );
      final meridian = MeridianTheme.of(tester.element(find.text('1')));
      expect(value.style?.fontFamily, meridian.text.code.fontFamily);
      expect(
        value.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    testWidgets('always stacks at touch density', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 600,
            child: MeridianPropertyList(properties: _properties),
          ),
          brand: MeridianBrands.nibluma,
        ),
      );
      final label = tester.getRect(find.text('Status'));
      expect(
        tester.getTopLeft(find.text('Running')).dy,
        greaterThanOrEqualTo(label.bottom),
      );
    });
  });

  group('MeridianColumnHeader', () {
    testWidgets('sorts on click and Enter, opens the menu on secondary '
        'click', (tester) async {
      useDesktopHighlights();
      var sorts = 0;
      Offset? menuAt;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 120,
            height: 26,
            child: MeridianColumnHeader(
              label: 'CPU',
              sortDirection: MeridianSortDirection.descending,
              alignEnd: true,
              onPressed: () => sorts++,
              onContextMenu: (position) => menuAt = position,
            ),
          ),
        ),
      );
      await tester.tap(find.text('CPU'));
      expect(sorts, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(sorts, 2);

      await tester.tap(find.text('CPU'), buttons: kSecondaryButton);
      expect(menuAt, isNotNull);
      expect(sorts, 2);
    });

    testWidgets('shows the arrow and ink only on the sorted column', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                height: 26,
                child: MeridianColumnHeader(
                  label: 'Name',
                  sortDirection: MeridianSortDirection.ascending,
                ),
              ),
              SizedBox(
                width: 120,
                height: 26,
                child: MeridianColumnHeader(label: 'PID', alignEnd: true),
              ),
            ],
          ),
        ),
      );
      final colors = colorsOf(tester);
      expect(textColor(tester, 'Name'), colors.ink);
      expect(textColor(tester, 'PID'), colors.inkMuted);
      expect(
        find.descendant(
          of: find.widgetWithText(MeridianColumnHeader, 'Name'),
          matching: find.byType(MeridianIcon),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(MeridianColumnHeader, 'PID'),
          matching: find.byType(MeridianIcon),
        ),
        findsNothing,
      );
      // alignEnd puts the label against the end of its cell.
      expect(
        tester.getTopRight(find.text('PID')).dx,
        closeTo(tester.getTopRight(find.byType(SizedBox).last).dx - 8, 1),
      );
    });

    testWidgets('announces the sort direction', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 120,
            height: 26,
            child: MeridianColumnHeader(
              label: 'CPU',
              sortDirection: MeridianSortDirection.descending,
              sortedDescendingLabel: 'sorted descending',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(MeridianColumnHeader)),
        matchesSemantics(
          label: 'CPU',
          value: 'sorted descending',
          isButton: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('MeridianResizeHandle', () {
    Widget handle({
      required ValueChanged<double> onDrag,
      VoidCallback? onReset,
    }) => SizedBox(
      height: 200,
      child: MeridianResizeHandle(
        semanticLabel: 'Resize inspector',
        onDrag: onDrag,
        onReset: onReset,
      ),
    );

    testWidgets('reports drags, arrow keys and resets', (tester) async {
      final moves = <double>[];
      var resets = 0;
      await tester.pumpWidget(
        host(handle(onDrag: moves.add, onReset: () => resets++)),
      );
      expect(
        tester.getSize(find.byType(MeridianResizeHandle)).width,
        MeridianSpace.space3,
      );

      await tester.dragFrom(
        tester.getCenter(find.byType(MeridianResizeHandle)),
        const Offset(-40, 0),
      );
      // Let the double-tap recognizer's timer run out.
      await tester.pump(kDoubleTapTimeout);
      expect(moves.fold<double>(0, (a, b) => a + b), lessThan(0));

      moves.clear();
      Focus.of(tester.element(find.byType(MouseRegion).last)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(moves, [
        MeridianLayout.resizeKeyboardStep,
        -MeridianLayout.resizeKeyboardStep,
      ]);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(resets, 1);

      await tester.tap(find.byType(MeridianResizeHandle));
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(find.byType(MeridianResizeHandle));
      await tester.pump(kDoubleTapTimeout);
      expect(resets, 2);
    });

    testWidgets('shows its rule on hover and accent while dragging', (
      tester,
    ) async {
      await tester.pumpWidget(host(handle(onDrag: (_) {})));
      final colors = colorsOf(tester);
      Color? rule() =>
          (tester
                      .widget<AnimatedContainer>(
                        find.descendant(
                          of: find.byType(MeridianResizeHandle),
                          matching: find.byType(AnimatedContainer),
                        ),
                      )
                      .decoration
                  as BoxDecoration?)
              ?.color;
      expect(rule(), meridianClear(colors.accent));

      final center = tester.getCenter(find.byType(MeridianResizeHandle));
      final mouse = await hoverAt(tester, center);
      // Hover draws an `accent` line that grows from the centre after
      // 150 ms (MM-75).
      expect(rule(), colors.accent);

      await mouse.down(center);
      await mouse.moveBy(const Offset(20, 0));
      await tester.pump();
      expect(rule(), colors.accent);
      // The pointer left the 6px gutter while dragging; the rule stays
      // accent until release, then clears.
      await mouse.up();
      await tester.pump();
      expect(rule(), meridianClear(colors.accent));
    });
  });

  group('MeridianStatusBar', () {
    testWidgets('sets caption ink-muted text with tabular figures', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 600,
            child: MeridianStatusBar(
              leading: [Text('Polling every second')],
              trailing: [Text('412 processes')],
            ),
          ),
        ),
      );
      final style = DefaultTextStyle.of(
        tester.element(find.text('412 processes')),
      ).style;
      final colors = colorsOf(tester);
      expect(style.color, colors.inkMuted);
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(
        tester.getSize(find.byType(MeridianStatusBar)).height,
        MeridianLayout.statusBarHeight,
      );
      expect(
        tester.getTopRight(find.text('412 processes')).dx,
        greaterThan(tester.getTopRight(find.text('Polling every second')).dx),
      );
    });

    testWidgets('ellipsizes a long leading item instead of overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            child: MeridianStatusBar(
              leading: [Text('Polling every second while the window is open')],
              trailing: [Text('412 processes')],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
