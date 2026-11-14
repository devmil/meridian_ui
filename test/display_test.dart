import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  testWidgets('Kbd wraps long enlarged caps within bounded width', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 120,
          child: MeridianKbd(keys: ['Ctrl', 'Print Screen']),
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), null);
    expect(find.text('Ctrl'), findsOneWidget);
    expect(find.text('Print Screen'), findsOneWidget);
    expect(
      tester.getSize(find.byType(MeridianKbd)).width,
      lessThanOrEqualTo(120),
    );
    expect(
      tester.getTopLeft(find.text('Print Screen')).dy,
      greaterThan(tester.getTopLeft(find.text('Ctrl')).dy),
    );
  });

  group('MeridianMiddleEllipsis', () {
    RenderMeridianMiddleEllipsis render(WidgetTester tester) =>
        tester.renderObject<RenderMeridianMiddleEllipsis>(
          find.byType(MeridianMiddleEllipsis),
        );

    testWidgets('shows a fitting text whole and takes only its width', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 220,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Flexible(child: MeridianMiddleEllipsis('main'))],
            ),
          ),
        ),
      );
      expect(render(tester).shownText, 'main');
      expect(
        tester.getSize(find.byType(MeridianMiddleEllipsis)).width,
        lessThan(220),
      );
    });

    testWidgets('keeps both ends of a long text within its width', (
      tester,
    ) async {
      const name = 'feature/very-long-branch-name-for-a-dialog-🙂';
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: MeridianMiddleEllipsis(name),
            ),
          ),
        ),
      );
      final shown = render(tester).shownText;
      expect(shown, startsWith('feat'));
      expect(shown, contains('…'));
      expect(shown, endsWith('🙂'));
      final width = tester.getSize(find.byType(MeridianMiddleEllipsis)).width;
      expect(width, lessThanOrEqualTo(120));
      // Hyphens offer line breaks. The width must follow the shown text
      // instead of the available width of a wrapped paragraph.
      expect(width, greaterThan(90));
      expect(
        tester.getSemantics(find.byType(MeridianMiddleEllipsis)).label,
        name,
      );
    });

    testWidgets('a colour change keeps the shortened text', (tester) async {
      const name = 'origin/feature/a-remote-branch-with-a-long-name';
      Widget chip(Color color) => host(
        SizedBox(
          width: 100,
          child: Align(
            alignment: Alignment.centerLeft,
            child: MeridianMiddleEllipsis(name, style: TextStyle(color: color)),
          ),
        ),
      );
      await tester.pumpWidget(chip(const Color(0xFF000000)));
      final before = render(tester).shownText;
      final size = tester.getSize(find.byType(MeridianMiddleEllipsis));
      await tester.pumpWidget(chip(const Color(0xFF336699)));
      expect(render(tester).shownText, before);
      expect(tester.getSize(find.byType(MeridianMiddleEllipsis)), size);
      expect(render(tester).style.color, const Color(0xFF336699));
    });

    testWidgets('follows a width change and large text', (tester) async {
      const name = 'release/2026-09-candidate-with-a-long-suffix';
      Widget sized(double width, {double scale = 1}) => host(
        SizedBox(
          width: width,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: MeridianMiddleEllipsis(name),
          ),
        ),
        textScale: scale,
      );
      await tester.pumpWidget(sized(100));
      final narrow = render(tester).shownText;
      await tester.pumpWidget(sized(600));
      expect(render(tester).shownText, name);
      await tester.pumpWidget(sized(100, scale: 2));
      final large = render(tester).shownText;
      expect(large.length, lessThan(narrow.length));
      expect(
        tester.getSize(find.byType(MeridianMiddleEllipsis)).width,
        lessThanOrEqualTo(100),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('MeridianKbd', () {
    testWidgets('uses the density caption, not the desktop one', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const MeridianKbd(keys: ['⌘', 'K']),
          brand: MeridianBrands.nibluma,
        ),
      );
      final meridian = MeridianTheme.of(tester.element(find.text('K')));
      expect(meridian.density, MeridianDensity.touch);
      expect(
        tester.widget<Text>(find.text('K')).style?.fontSize,
        meridian.text.caption.fontSize,
      );
      expect(
        meridian.text.caption.fontSize,
        isNot(MeridianTypeScale.desktop.caption.fontSize),
      );
    });

    testWidgets('grows with large text', (tester) async {
      await tester.pumpWidget(
        host(const MeridianKbd(keys: ['Enter']), textScale: 2),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(Container).first).height,
        greaterThan(MeridianLayout.kbdHeight),
      );
    });
  });

  group('MeridianStatusDot', () {
    testWidgets('ellipsizes its label in a narrow space', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 80,
            child: Row(
              children: [
                Flexible(
                  child: MeridianStatusDot(
                    tone: MeridianStatusTone.success,
                    label: 'Live, polling every second',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MeridianStatusDot)).width,
        lessThanOrEqualTo(80),
      );
    });
  });

  group('text scale 130%', () {
    testWidgets('Count grows instead of clipping', (tester) async {
      await tester.pumpWidget(
        host(const MeridianCount(label: '128'), textScale: 1.3),
      );
      expect(tester.takeException(), isNull);
      final pill = tester.getSize(find.byType(MeridianCount));
      final text = tester.getSize(find.text('128'));
      expect(pill.height, greaterThanOrEqualTo(text.height));
      expect(pill.height, greaterThan(MeridianLayout.countHeight));
    });

    testWidgets('Avatar keeps its size and fits its initials', (tester) async {
      for (final size in MeridianAvatarSize.values) {
        await tester.pumpWidget(
          host(
            MeridianAvatar(name: 'Michael Lamers', size: size),
            textScale: 1.3,
          ),
        );
        expect(tester.takeException(), isNull);
        final circle = tester.getRect(find.byType(MeridianAvatar));
        final initials = tester.getRect(find.text('ML'));
        expect(circle.width, circle.height);
        expect(circle.contains(initials.topLeft), isTrue);
        expect(
          circle.contains(initials.bottomRight - const Offset(1, 1)),
          isTrue,
        );
      }
    });
  });

  group('MeridianAvatar', () {
    test('initials and colour are stable', () {
      expect(MeridianAvatar.initials('Michael Lamers'), 'ML');
      expect(MeridianAvatar.initials('anna@example.org'), 'AE');
      expect(MeridianAvatar.initials(''), '?');
      expect(
        MeridianAvatar.colorIndex('Michael Lamers'),
        MeridianAvatar.colorIndex('michael lamers'),
      );
    });

    testWidgets('a loaded picture covers the fill and initials', (
      tester,
    ) async {
      // A 1x1 fully transparent PNG, like a logo without a background.
      final transparent = MemoryImage(
        Uint8List.fromList(const [
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0B,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x60,
          0x00,
          0x02,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x7A,
          0x5E,
          0xAB,
          0x3F,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]),
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          host(MeridianAvatar(name: 'Anna Berg', image: transparent)),
        );
        await precacheImage(
          transparent,
          tester.element(find.byType(MeridianAvatar)),
        );
      });
      await tester.pumpAndSettle();
      final backing = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(MeridianAvatar),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(backing.color, colorsOf(tester).pane);
      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(ColoredBox),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, 1);
    });

    testWidgets('is hidden from assistive technology', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(const MeridianAvatar(name: 'Anna Berg')));
      expect(find.bySemanticsLabel('AB'), findsNothing);
      semantics.dispose();
    });
  });

  group('MeridianStatusDot', () {
    testWidgets('announces its label and draws the halo from tokens', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const MeridianStatusDot(
            tone: MeridianStatusTone.success,
            label: 'Running',
            halo: true,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Running'), findsOneWidget);
      final colors = colorsOf(tester);
      final dot = tester.widget<Container>(
        find.descendant(
          of: find.byType(MeridianStatusDot),
          matching: find.byType(Container),
        ),
      );
      final shadow = (dot.decoration! as BoxDecoration).boxShadow!.single;
      expect(shadow.spreadRadius, MeridianLayout.statusHaloSpread);
      expect(
        shadow.color,
        colors.success.withValues(alpha: MeridianOpacity.statusHalo),
      );
      semantics.dispose();
    });
  });

  group('MeridianChip', () {
    testWidgets('the remove button is announced and is 48px at touch', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var removed = 0;
      var pressed = 0;
      await tester.pumpWidget(
        host(
          MeridianChip(
            label: 'Anna',
            removeLabel: 'Remove Anna',
            onPressed: () => pressed++,
            onRemove: () => removed++,
          ),
          brand: MeridianBrands.nibluma,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Remove Anna')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      final remove = find.descendant(
        of: findTooltip('Remove Anna'),
        matching: find.byType(MeridianInteraction),
      );
      final target = tester.getRect(remove);
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));
      // The corner of the grown target, outside the 32px pill.
      await tester.tapAt(target.bottomRight - const Offset(2, 2));
      expect(removed, 1);
      expect(pressed, 0);
      await tester.tap(find.text('Anna'));
      expect(pressed, 1);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('tinted tones hover; a selected filter does not', (
      tester,
    ) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianChip(
                label: 'Failing',
                tone: MeridianChipTone.danger,
                onPressed: () {},
              ),
              MeridianChip(label: 'Unread', selected: true, onPressed: () {}),
            ],
          ),
        ),
      );
      final colors = colorsOf(tester);
      final mouse = await hoverAt(
        tester,
        tester.getCenter(find.text('Failing')),
      );
      await tester.pumpAndSettle();
      expect(
        fillAround(tester, find.text('Failing')),
        meridianPressed(colors.dangerBg, colors.ink),
      );
      await mouse.moveTo(tester.getCenter(find.text('Unread')));
      await tester.pumpAndSettle();
      expect(fillAround(tester, find.text('Unread')), colors.accentSoft);
    });

    for (final density in [MeridianDensity.compact, MeridianDensity.touch]) {
      for (final removable in [false, true]) {
        testWidgets(
          'enlarged chip fits its line and retains actions ($density, $removable)',
          (tester) async {
            var taps = 0, removals = 0;
            await tester.pumpWidget(
              host(
                MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: SizedBox(
                    width: 160,
                    child: MeridianChip(
                      label: 'Danach bearbeiten',
                      maxWidth: 160,
                      selected: true,
                      onPressed: () => taps++,
                      onRemove: removable ? () => removals++ : null,
                      removeLabel: removable ? 'Entfernen' : null,
                    ),
                  ),
                ),
                density: density,
              ),
            );
            final chip = tester.getRect(find.byType(MeridianChip));
            final text = tester.getRect(find.text('Danach bearbeiten'));
            expect(text.top, greaterThanOrEqualTo(chip.top));
            expect(text.bottom, lessThanOrEqualTo(chip.bottom));
            expect(chip.width, lessThanOrEqualTo(160));
            await tester.tap(find.text('Danach bearbeiten'));
            expect(taps, 1);
            if (removable) {
              await tester.tap(findTooltip('Entfernen'));
              expect(removals, 1);
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
    testWidgets('a disabled chip ignores taps and fades', (tester) async {
      var pressed = 0;
      var removed = 0;
      await tester.pumpWidget(
        host(
          MeridianChip(
            label: 'Anna',
            enabled: false,
            onPressed: () => pressed++,
            onRemove: () => removed++,
          ),
        ),
      );
      await tester.tap(find.text('Anna'));
      await tester.tap(findTooltip('Remove Anna'));
      expect(pressed + removed, 0);
      expect(textColor(tester, 'Anna'), colorsOf(tester).inkFaint);
    });
  });
}
