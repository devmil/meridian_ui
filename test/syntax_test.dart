import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  final light = MeridianColors.resolve(
    Brightness.light,
    MeridianBrands.gitlama.light,
  );
  MeridianSyntaxPalette palette({Iterable<Color>? backgrounds}) =>
      MeridianSyntaxPalette(
        colors: MeridianSyntaxColors.light,
        ink: light.ink,
        backgrounds: backgrounds ?? [light.pane],
      );

  List<(String, Color?)> pieces(TextSpan span) => [
    if (span.text != null) (span.text!, span.style?.color),
    for (final child in span.children ?? const <InlineSpan>[])
      if (child is TextSpan) (child.text!, child.style?.color),
  ];

  group('MeridianSyntaxPalette', () {
    test('colours runs and keeps the exact text', () {
      const text = 'final greeting = "Hello"; // hi';
      final span = palette().span(text, const [
        MeridianSyntaxRun(0, 5, MeridianSyntaxKind.keyword),
        MeridianSyntaxRun(15, 16, MeridianSyntaxKind.operator),
        MeridianSyntaxRun(17, 24, MeridianSyntaxKind.string),
        MeridianSyntaxRun(26, 31, MeridianSyntaxKind.comment),
      ]);
      expect(span.toPlainText(), text);
      expect(pieces(span), [
        ('final', MeridianSyntaxColors.light.keyword),
        (' greeting ', null),
        ('=', MeridianSyntaxColors.light.operator),
        (' ', null),
        ('"Hello"', MeridianSyntaxColors.light.string),
        ('; ', null),
        ('// hi', MeridianSyntaxColors.light.comment),
      ]);
      // Only colours change: no weight, style or size.
      for (final child in span.children!) {
        final style = (child as TextSpan).style;
        expect(style?.fontWeight, isNull);
        expect(style?.fontStyle, isNull);
        expect(style?.fontSize, isNull);
      }
    });

    test('rejects every run of a malformed list atomically', () {
      const text = 'let a = 1;';
      for (final runs in [
        const [
          MeridianSyntaxRun(0, 3, MeridianSyntaxKind.keyword),
          MeridianSyntaxRun(2, 4, MeridianSyntaxKind.type),
        ],
        const [MeridianSyntaxRun(4, 4, MeridianSyntaxKind.variable)],
        const [MeridianSyntaxRun(8, 11, MeridianSyntaxKind.number)],
        const [
          MeridianSyntaxRun(5, 6, MeridianSyntaxKind.number),
          MeridianSyntaxRun(0, 3, MeridianSyntaxKind.keyword),
        ],
        const [MeridianSyntaxRun(-1, 3, MeridianSyntaxKind.keyword)],
      ]) {
        final span = palette().span(text, runs);
        expect(span.toPlainText(), text);
        expect(span.children, isNull, reason: '$runs');
      }
    });

    test('never splits a surrogate pair and handles non-ASCII prefixes', () {
      const text = 'é🙂 = "x"';
      // 🙂 is two UTF-16 units at 1..3.
      expect(
        meridianSyntaxRunsValid(text, const [
          MeridianSyntaxRun(2, 3, MeridianSyntaxKind.string),
        ]),
        isFalse,
      );
      final span = palette().span(text, const [
        MeridianSyntaxRun(1, 3, MeridianSyntaxKind.variable),
        MeridianSyntaxRun(6, 9, MeridianSyntaxKind.string),
      ]);
      expect(span.toPlainText(), text);
      expect(pieces(span)[1], ('🙂', MeridianSyntaxColors.light.variable));
      expect(pieces(span).last, ('"x"', MeridianSyntaxColors.light.string));
    });

    test('keeps ink where a category is not readable on an overlay', () {
      final readable = palette(backgrounds: [light.pane, light.successBg]);
      for (final kind in MeridianSyntaxKind.values) {
        expect(readable.colorOf(kind), MeridianSyntaxColors.light.of(kind));
      }
      // A strong mark behind changed words: categories that fall below
      // 4.5:1 on it keep ink instead.
      const strong = Color(0xFF7FB98C);
      final marked = palette(backgrounds: [light.pane, strong]);
      for (final kind in MeridianSyntaxKind.values) {
        final color = MeridianSyntaxColors.light.of(kind);
        expect(
          marked.colorOf(kind),
          meridianContrastRatio(color, strong) >= 4.5 ? color : light.ink,
        );
      }
      expect(
        MeridianSyntaxKind.values.map(marked.colorOf),
        contains(light.ink),
      );
    });

    test('every category passes 4.5:1 on code surfaces in each brand', () {
      for (final brand in MeridianBrands.all) {
        for (final brightness in Brightness.values) {
          final colors = MeridianColors.resolve(
            brightness,
            brightness == Brightness.dark ? brand.dark : brand.light,
            brand.neutralsFor(brightness),
          );
          final syntax = MeridianSyntaxColors.resolve(brightness);
          for (final kind in MeridianSyntaxKind.values) {
            for (final background in [
              colors.pane,
              colors.paneAlt,
              colors.raised,
              colors.paneHover,
              colors.successBg,
              colors.dangerBg,
            ]) {
              expect(
                meridianContrastRatio(syntax.of(kind), background),
                greaterThanOrEqualTo(4.5),
                reason: '${brand.id} $brightness $kind',
              );
            }
          }
        }
      }
    });
  });

  testWidgets('the theme carries syntax colours for its brightness', (
    tester,
  ) async {
    late MeridianTheme theme;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            theme = MeridianTheme.of(context);
            return const SizedBox();
          },
        ),
        brightness: Brightness.dark,
      ),
    );
    expect(theme.syntax, MeridianSyntaxColors.dark);
    expect(
      MeridianSyntaxColors.lerp(
        MeridianSyntaxColors.light,
        MeridianSyntaxColors.dark,
        1,
      ),
      MeridianSyntaxColors.dark,
    );
  });

  testWidgets('code lines colour runs without changing line metrics', (
    tester,
  ) async {
    const lines = ['void main() {', '  print("hi");', '}'];
    Future<Size> pump(Map<int, List<MeridianSyntaxRun>> syntax) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            height: 200,
            child: MeridianCodeLines(lines: lines, syntax: syntax),
          ),
        ),
      );
      return tester.getSize(find.text('void main() {', findRichText: true));
    }

    final plain = await pump(const {});
    final coloured = await pump(const {
      0: [
        MeridianSyntaxRun(0, 4, MeridianSyntaxKind.type),
        MeridianSyntaxRun(5, 9, MeridianSyntaxKind.function),
      ],
      1: [MeridianSyntaxRun(8, 12, MeridianSyntaxKind.string)],
    });
    expect(coloured, plain);
    final rich = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == lines[1],
      ),
    );
    TextSpan? string;
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == '"hi"') string = span;
      return string == null;
    });
    expect(string?.style?.color, MeridianSyntaxColors.light.string);
    expect(tester.takeException(), isNull);
  });
}
