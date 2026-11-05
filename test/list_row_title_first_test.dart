import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

const _branch = 'feature/login-form-validation';
const _onto = 'onto main';
const _longSubtitle =
    'rebases twelve commits that touch the login form and its validators';

Finder _rich(String text) => find.text(text, findRichText: true);

RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(_rich(text));

bool _truncated(WidgetTester tester, String text) =>
    _paragraph(tester, text).didExceedMaxLines;

/// The natural one-line width of [text] as laid out in the row.
double _natural(WidgetTester tester, String text) =>
    _paragraph(tester, text).getMaxIntrinsicWidth(double.infinity);

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  String title = _branch,
  String subtitle = _onto,
  MeridianDensity? density,
  TextDirection textDirection = TextDirection.ltr,
  double textScale = 1,
  String? match,
  Widget? titleTrailing,
  Widget? leading,
}) => tester.pumpWidget(
  host(
    SizedBox(
      width: width,
      child: MeridianListRow(
        title: title,
        subtitle: subtitle,
        match: match,
        titleTrailing: titleTrailing,
        leading: leading,
        onTap: () {},
      ),
    ),
    density: density,
    textDirection: textDirection,
    textScale: textScale,
  ),
);

void main() {
  group('MeridianListRow one-line title priority', () {
    testWidgets('a long title beside a short subtitle is not truncated', (
      tester,
    ) async {
      // Room for both, but less than twice the title: two half-width
      // Flexibles used to clip the title here.
      await _pump(tester, width: 1000);
      final title = _natural(tester, _branch);
      final subtitle = _natural(tester, _onto);
      await _pump(tester, width: title + subtitle + 100);

      expect(_truncated(tester, _branch), isFalse);
      expect(_truncated(tester, _onto), isFalse);
      // The subtitle follows the title after the gap: no empty space while
      // either is shortened.
      final titleRect = tester.getRect(_rich(_branch));
      final subtitleRect = tester.getRect(_rich(_onto));
      expect(
        subtitleRect.left - titleRect.right,
        moreOrLessEquals(MeridianSpace.space4),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the subtitle truncates first and the title stays whole', (
      tester,
    ) async {
      await _pump(tester, width: 1000, subtitle: _longSubtitle);
      final title = _natural(tester, _branch);
      await _pump(tester, width: title + 200, subtitle: _longSubtitle);

      expect(_truncated(tester, _branch), isFalse);
      expect(_truncated(tester, _longSubtitle), isTrue);
      expect(tester.getSize(_rich(_longSubtitle)).width, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a title wider than the row leaves the subtitle an ellipsis', (
      tester,
    ) async {
      await _pump(tester, width: 1000);
      final title = _natural(tester, _branch);
      await _pump(tester, width: title * 0.75);

      expect(_truncated(tester, _branch), isTrue);
      expect(tester.getSize(_rich(_branch)).width, greaterThan(0));
      // The subtitle keeps a sliver for its ellipsis, so the line says
      // there is more.
      expect(tester.getSize(_rich(_onto)).width, greaterThan(0));
      expect(_truncated(tester, _onto), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow rows never overflow', (tester) async {
      for (final density in [
        MeridianDensity.compact,
        MeridianDensity.regular,
        MeridianDensity.touch,
      ]) {
        // The row's own padding is the least it can be.
        final padding = density.isTouch
            ? 2 * MeridianSpace.space6
            : 2 * MeridianSpace.space4;
        for (final line in [0.0, 1.0, 4.0, 8.0, 16.0, 32.0, 64.0, 128.0]) {
          await _pump(
            tester,
            width: padding + line,
            density: density,
            subtitle: _longSubtitle,
          );
          expect(tester.takeException(), isNull, reason: '$density $line');
          if (line == 0) {
            // No room at all: the title takes the line, the subtitle hides.
            expect(tester.getSize(_rich(_longSubtitle)), Size.zero);
          }
        }
        // With a leading icon and a title trailing count as well.
        for (final width in [96.0, 120.0, 160.0, 200.0, 320.0]) {
          await _pump(
            tester,
            width: width,
            density: density,
            subtitle: _longSubtitle,
            leading: const MeridianIcon(MeridianIcons.gitBranch),
            titleTrailing: const MeridianCount(label: '3'),
          );
          expect(tester.takeException(), isNull, reason: '$density $width');
        }
      }
    });

    testWidgets('touch density keeps the title first', (tester) async {
      await _pump(tester, width: 1000, density: MeridianDensity.touch);
      final title = _natural(tester, _branch);
      final subtitle = _natural(tester, _onto);
      await _pump(
        tester,
        width:
            title +
            subtitle +
            2 * MeridianSpace.space6 +
            MeridianSpace.space4 +
            8,
        density: MeridianDensity.touch,
      );
      expect(_truncated(tester, _branch), isFalse);
      expect(_truncated(tester, _onto), isFalse);
      expect(
        tester.getSize(find.byType(MeridianListRow)).height,
        greaterThanOrEqualTo(MeridianDensity.touch.rowExtent),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('right to left puts the title at the start edge', (
      tester,
    ) async {
      await _pump(tester, width: 1000);
      final title = _natural(tester, _branch);
      await _pump(
        tester,
        width: title + 160,
        subtitle: _longSubtitle,
        textDirection: TextDirection.rtl,
      );
      final row = tester.getRect(find.byType(MeridianListRow));
      final titleRect = tester.getRect(_rich(_branch));
      final subtitleRect = tester.getRect(_rich(_longSubtitle));
      expect(_truncated(tester, _branch), isFalse);
      expect(_truncated(tester, _longSubtitle), isTrue);
      expect(titleRect.right, lessThanOrEqualTo(row.right));
      expect(subtitleRect.right, lessThan(titleRect.left));
      expect(
        titleRect.left - subtitleRect.right,
        moreOrLessEquals(MeridianSpace.space4),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('large text keeps the title first', (tester) async {
      await _pump(tester, width: 2000, textScale: 2);
      final title = _natural(tester, _branch);
      await _pump(
        tester,
        width: title + 120,
        subtitle: _longSubtitle,
        textScale: 2,
      );
      expect(_truncated(tester, _branch), isFalse);
      expect(_truncated(tester, _longSubtitle), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a match and a title trailing keep the title first', (
      tester,
    ) async {
      const trailing = MeridianCount(label: '12');
      await _pump(tester, width: 1000, match: 'login', titleTrailing: trailing);
      final title = _natural(tester, _branch);
      final count = tester.getSize(find.byType(MeridianCount)).width;
      await _pump(
        tester,
        width: title + count + 160,
        subtitle: _longSubtitle,
        match: 'login',
        titleTrailing: trailing,
      );
      expect(_truncated(tester, _branch), isFalse);
      expect(_truncated(tester, _longSubtitle), isTrue);
      final countRect = tester.getRect(find.byType(MeridianCount));
      expect(
        countRect.left - tester.getRect(_rich(_branch)).right,
        moreOrLessEquals(MeridianSpace.space2),
      );
      expect(
        tester.getRect(_rich(_longSubtitle)).left - countRect.right,
        moreOrLessEquals(MeridianSpace.space4),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('two-line rows still stack the subtitle', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            child: MeridianListRow(
              title: _branch,
              subtitle: _longSubtitle,
              twoLine: true,
            ),
          ),
        ),
      );
      final title = tester.getRect(_rich(_branch));
      final subtitle = tester.getRect(_rich(_longSubtitle));
      expect(subtitle.top, greaterThanOrEqualTo(title.bottom));
      expect(subtitle.left, moreOrLessEquals(title.left));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a row sized by its content measures both texts', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const IntrinsicWidth(
            child: MeridianListRow(title: _branch, subtitle: _onto),
          ),
        ),
      );
      expect(_truncated(tester, _branch), isFalse);
      expect(_truncated(tester, _onto), isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
