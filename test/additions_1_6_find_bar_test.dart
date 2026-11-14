import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

/// A find bar over five lines, searching like an owner would.
class _Finder extends StatefulWidget {
  const _Finder({this.enabled = true, this.onClose, this.trailing = const []});

  final bool enabled;
  final VoidCallback? onClose;
  final List<Widget> trailing;

  @override
  State<_Finder> createState() => _FinderState();
}

class _FinderState extends State<_Finder> {
  static const lines = ['alpha', 'Beta', 'beta', 'gamma', 'BETA'];
  final controller = TextEditingController();
  var caseSensitive = false;
  var matches = <int>[];
  int? current;
  var closed = 0;

  void search(String query) => setState(() {
    matches = [
      for (final (i, line) in lines.indexed)
        if (query.isNotEmpty &&
            (caseSensitive
                ? line.contains(query)
                : line.toLowerCase().contains(query.toLowerCase())))
          i,
    ];
    current = matches.isEmpty ? null : 0;
  });

  void step(int delta) {
    if (matches.isEmpty) {
      search(controller.text);
      return;
    }
    setState(() => current = ((current ?? -1) + delta) % matches.length);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MeridianFindBar(
    controller: controller,
    enabled: widget.enabled,
    autofocus: true,
    matchCount: matches.length,
    currentMatch: current,
    caseSensitive: caseSensitive,
    onCaseSensitiveChanged: (value) {
      caseSensitive = value;
      search(controller.text);
    },
    onChanged: search,
    onNext: () => step(1),
    onPrevious: () => step(-1),
    onClose: widget.onClose,
    trailing: widget.trailing,
  );
}

_FinderState _state(WidgetTester tester) =>
    tester.state<_FinderState>(find.byType(_Finder));

void main() {
  testWidgets('typing shows a localized position, not n/m', (tester) async {
    await tester.pumpWidget(host(const _Finder()));
    await tester.pump();
    expect(find.text('No matches'), findsNothing);
    await tester.enterText(find.byType(EditableText), 'beta');
    await tester.pumpAndSettle();
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.textContaining('/'), findsNothing);
    await tester.enterText(find.byType(EditableText), 'zeta');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('German shows "von"', (tester) async {
    await tester.pumpWidget(
      host(
        const MeridianLocalizationsScope(
          localizations: MeridianLocalizationsDe(),
          child: _Finder(),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'beta');
    await tester.pumpAndSettle();
    expect(find.text('1 von 3'), findsOneWidget);
    expect(
      MeridianLocalizations.forLocale(const Locale('de', 'AT')),
      isA<MeridianLocalizationsDe>(),
    );
    expect(
      MeridianLocalizations.forLocale(const Locale('fr')),
      isA<MeridianLocalizationsEn>(),
    );
  });

  testWidgets('Enter and Shift+Enter step; the buttons follow', (tester) async {
    await tester.pumpWidget(host(const _Finder()));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'beta');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_state(tester).current, 1);
    expect(find.text('2 of 3'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(_state(tester).current, 0);
    await tester.tap(find.byKey(const ValueKey('meridian-find-previous')));
    await tester.pumpAndSettle();
    expect(_state(tester).current, 2);
    await tester.tap(find.byKey(const ValueKey('meridian-find-next')));
    await tester.pumpAndSettle();
    expect(_state(tester).current, 0);
  });

  testWidgets('the case toggle searches again', (tester) async {
    await tester.pumpWidget(host(const _Finder()));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'beta');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('meridian-find-case')));
    await tester.pumpAndSettle();
    expect(_state(tester).caseSensitive, isTrue);
    expect(find.text('1 of 1'), findsOneWidget);
    expect(
      tester
          .widget<MeridianIconButton>(
            find.byKey(const ValueKey('meridian-find-case')),
          )
          .active,
      isTrue,
    );
  });

  testWidgets('Escape clears, then closes', (tester) async {
    var closed = 0;
    await tester.pumpWidget(host(_Finder(onClose: () => closed++)));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'beta');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_state(tester).controller.text, isEmpty);
    expect(_state(tester).matches, isEmpty);
    expect(closed, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(closed, 1);
    await tester.tap(find.byKey(const ValueKey('meridian-find-close')));
    expect(closed, 2);
  });

  testWidgets('without matches the step buttons are disabled; disabled bar '
      'ignores input', (tester) async {
    await tester.pumpWidget(host(const _Finder()));
    await tester.pump();
    final next = tester.widget<MeridianIconButton>(
      find.byKey(const ValueKey('meridian-find-next')),
    );
    expect(next.onPressed, isNull);
    await tester.pumpWidget(host(const _Finder(enabled: false)));
    await tester.pump();
    expect(
      tester
          .widget<MeridianIconButton>(
            find.byKey(const ValueKey('meridian-find-case')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<MeridianEditableText>(find.byType(MeridianEditableText))
          .enabled,
      isFalse,
    );
  });

  testWidgets('a narrow toolbar shrinks the field instead of overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 300,
          child: _Finder(
            onClose: () {},
            trailing: [
              MeridianIconButton(
                label: 'Search scopes',
                icon: MeridianIcons.listFilter,
                size: MeridianControlSize.small,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final field = tester.getSize(find.byType(MeridianTextField));
    expect(field.width, lessThan(MeridianLayout.findFieldWidth));
    expect(field.width, greaterThanOrEqualTo(MeridianLayout.findFieldMinWidth));
  });

  testWidgets('a phone width stacks the buttons under the field', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(width: 280, child: _Finder(onClose: () {})),
        density: MeridianDensity.touch,
        textScale: 1.6,
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'beta');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MeridianTextField)).width, 280);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('meridian-find-next'))).dy,
      greaterThan(tester.getTopLeft(find.byType(MeridianTextField)).dy),
    );
  });

  testWidgets('touch density keeps 48px targets', (tester) async {
    await tester.pumpWidget(
      host(_Finder(onClose: () {}), density: MeridianDensity.touch),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final close = tester.getSize(
      find.byKey(const ValueKey('meridian-find-close')),
    );
    expect(close.height, greaterThanOrEqualTo(MeridianSize.targetTouch));
  });

  testWidgets('reduced motion hides it at once', (tester) async {
    await tester.pumpWidget(
      host(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MeridianFindBar(visible: false),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MeridianFindBar)).height, 0);
  });
}
