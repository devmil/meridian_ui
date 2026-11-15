import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  group('brand neutrals', () {
    test('a brand with neutrals replaces the core surfaces and ink', () {
      for (final brightness in Brightness.values) {
        final core = MeridianColors.resolve(
          brightness,
          MeridianBrands.gitlama.light,
        );
        final nibluma = MeridianTheme.resolve(
          brand: MeridianBrands.nibluma,
          brightness: brightness,
        ).colors;
        final neutrals = MeridianBrands.nibluma.neutralsFor(brightness)!;
        expect(nibluma.ground, neutrals.ground);
        expect(nibluma.canvas, neutrals.canvas);
        expect(nibluma.ink, neutrals.ink);
        // Status colours stay shared.
        expect(nibluma.success, core.success);
        expect(nibluma.danger, core.danger);
      }
    });

    test('a brand without neutrals keeps the core', () {
      final theme = MeridianTheme.resolve(
        brand: MeridianBrands.gitlama,
        brightness: Brightness.light,
      );
      expect(MeridianBrands.gitlama.lightNeutrals, isNull);
      expect(
        theme.colors.ground,
        MeridianColors.resolve(
          Brightness.light,
          MeridianBrands.gitlama.light,
        ).ground,
      );
    });

    test('copyWith(brand:) resolves the new brand with its neutrals', () {
      final theme = MeridianTheme.resolve(
        brand: MeridianBrands.gitlama,
        brightness: Brightness.dark,
      ).copyWith(brand: MeridianBrands.nibluma);
      expect(theme.colors.pane, MeridianBrands.nibluma.darkNeutrals!.pane);
    });
  });

  group('display face', () {
    test('displayForTitle: false keeps titles in the sans', () {
      final theme = MeridianTheme.resolve(
        brand: MeridianBrands.nibluma,
        brightness: Brightness.light,
      );
      expect(theme.text.display.fontFamily, 'Literata');
      expect(theme.text.display.fontWeight, FontWeight.w500);
      // Nibluma's sans is the platform face, named for the platform.
      expect(theme.text.title.fontFamily, MeridianTextStyles.platformSans);
      expect(theme.text.title.fontFamily, isNot('Literata'));
      expect(theme.text.title.fontWeight, FontWeight.w600);
    });

    test('titles follow display by default', () {
      final brand = MeridianBrands.gitlama.copyWith(
        fonts: const MeridianFonts(display: 'Georgia'),
      );
      final theme = MeridianTheme.resolve(
        brand: brand,
        brightness: Brightness.light,
      );
      expect(theme.text.title.fontFamily, 'Georgia');
      expect(theme.text.title.fontWeight, FontWeight.w600);
    });
  });

  group('canvas, paper and tool dock', () {
    testWidgets('the canvas paints canvas and paper keeps its colour', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 300,
            height: 400,
            child: MeridianCanvas(
              child: Center(
                child: SizedBox(
                  width: 120,
                  child: MeridianPaper(
                    color: Color(0xFFFFFFFF),
                    aspectRatio: 210 / 297,
                    selected: true,
                    semanticLabel: 'Page 1 of 3',
                  ),
                ),
              ),
            ),
          ),
          brand: MeridianBrands.nibluma,
          brightness: Brightness.dark,
        ),
      );
      final colors = colorsOf(tester);
      final canvas = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(MeridianCanvas),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(canvas.color, colors.canvas);
      final paper = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MeridianPaper),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = paper.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFFFFFFF));
      expect(decoration.boxShadow!.first.color, colors.accent);
      expect(
        tester.getSize(find.byType(MeridianPaper)).height,
        closeTo(169.7, 0.1),
      );
      expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the dock hugs its tools in both axes', (tester) async {
      for (final axis in Axis.values) {
        var tapped = 0;
        await tester.pumpWidget(
          host(
            MeridianToolDock(
              axis: axis,
              semanticLabel: 'Tools',
              children: [
                MeridianIconButton(
                  label: 'Pen',
                  icon: MeridianIcons.pencil,
                  active: true,
                  onPressed: () => tapped++,
                ),
                const MeridianToolDockDivider(),
                MeridianIconButton(
                  label: 'Undo',
                  icon: MeridianIcons.undo2,
                  onPressed: () {},
                ),
              ],
            ),
            brand: MeridianBrands.nibluma,
            density: MeridianDensity.touch,
          ),
        );
        final size = tester.getSize(find.byType(MeridianToolDock));
        final long = axis == Axis.horizontal ? size.width : size.height;
        final short = axis == Axis.horizontal ? size.height : size.width;
        expect(long, lessThan(200));
        expect(short, greaterThanOrEqualTo(MeridianSize.targetTouch));
        await tester.tap(find.byType(MeridianIconButton).first);
        expect(tapped, 1);
        expect(tester.takeException(), isNull);
      }
    });
  });

  testWidgets('a narrow touch selection bar budgets 48px per command', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 300,
          child: MeridianSelectionBar(
            label: '3 selected',
            clearLabel: 'Clear',
            overflowLabel: 'More actions',
            onClear: () {},
            actions: [
              for (final name in ['Archive', 'Spam', 'Snooze', 'Delete'])
                MeridianSelectionAction(
                  child: MeridianIconButton(
                    label: name,
                    icon: MeridianIcons.clock,
                    size: MeridianControlSize.small,
                    onPressed: () {},
                  ),
                  overflow: MeridianMenuItem(label: name, onSelected: () {}),
                ),
            ],
          ),
        ),
        density: MeridianDensity.touch,
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(findTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);
  });

  for (final (platform, family) in [
    (TargetPlatform.android, 'Roboto'),
    (TargetPlatform.iOS, 'CupertinoSystemText'),
  ]) {
    testWidgets(
      'dialog text on a platform-face brand uses $family, '
      'not monospace',
      variant: TargetPlatformVariant.only(platform),
      (tester) async {
        await tester.pumpWidget(
          MeridianApp(
            theme: MeridianTheme.resolve(
              brand: MeridianBrands.nibluma,
              brightness: Brightness.light,
            ),
            home: Builder(
              builder: (context) => Center(
                child: MeridianButton(
                  label: 'Open',
                  onPressed: () => showMeridianDialog<void>(
                    context: context,
                    builder: (_) => const MeridianDialog(
                      title: 'Create notebook',
                      content: Text('Cover colour'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(MeridianBrands.nibluma.fonts.sans, isNull);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        for (final text in ['Create notebook', 'Cover colour']) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(text),
          );
          expect(paragraph.text.style?.fontFamily, family, reason: text);
        }
      },
    );
  }
}
