import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  group('MeridianMenuPresenter', () {
    testWidgets('routes selects and anchors to the presenter', (tester) async {
      List<MeridianMenuEntry>? presented;
      Rect? presentedAnchor;
      var value = 'Newest first';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            MeridianMenuPresenter(
              present: (context, {required anchor, required entries}) async {
                presented = entries;
                presentedAnchor = anchor;
                // Like a native menu: the choice runs after it closed.
                (entries.last as MeridianMenuItem).onSelected!();
              },
              child: MeridianSelect<String>(
                label: 'Sort by',
                value: value,
                values: const ['Newest first', 'Sender'],
                valueLabel: (v) => v,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Newest first'));
      await tester.pumpAndSettle();
      expect(find.byType(MeridianMenuSurface), findsNothing);
      expect(presented, hasLength(2));
      expect((presented!.first as MeridianMenuItem).checked, isTrue);
      expect(value, 'Sender');
      // The anchor is the trigger, so a native menu opens under it.
      expect(presentedAnchor!.height, MeridianSize.control);
      expect(
        tester
            .getRect(find.byType(MeridianSelect<String>))
            .contains(presentedAnchor!.center),
        isTrue,
      );
    });

    testWidgets('without a presenter the Flutter surface opens', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          MeridianMenuAnchor(
            entries: [MeridianMenuItem(label: 'Rename', onSelected: () {})],
            builder: (context, open) =>
                MeridianButton(label: 'Actions', onPressed: open),
          ),
        ),
      );
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      expect(find.byType(MeridianMenuSurface), findsOneWidget);
    });

    testWidgets('a menu with custom content stays a Meridian menu', (
      tester,
    ) async {
      var presented = 0;
      await tester.pumpWidget(
        host(
          MeridianMenuPresenter(
            present: (context, {required anchor, required entries}) async =>
                presented++,
            child: MeridianMenuAnchor(
              entries: const [
                MeridianMenuItem(
                  label: 'More',
                  children: [MeridianMenuCustom(Text('Storage'))],
                ),
              ],
              builder: (context, open) =>
                  MeridianButton(label: 'Account', onPressed: open),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(presented, 0);
      expect(find.byType(MeridianMenuSurface), findsOneWidget);
    });
  });

  group('dialogs', () {
    testWidgets('a dialog opened from a dialog keeps the first scrim', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => MeridianButton(
              label: 'Open',
              onPressed: () => showMeridianDialog<void>(
                context: context,
                builder: (context) => MeridianDialog(
                  title: 'First',
                  actions: [
                    MeridianButton(
                      label: 'Nested',
                      onPressed: () => showMeridianDialog<void>(
                        context: context,
                        builder: (_) => const MeridianDialog(title: 'Second'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nested'));
      await tester.pumpAndSettle();
      final barriers = tester
          .widgetList<ModalBarrier>(find.byType(ModalBarrier))
          .map((barrier) => barrier.color)
          .whereType<Color>()
          .where((color) => color.a > 0)
          .toList();
      expect(barriers, [colorsOf(tester).scrim]);
    });

    for (final destructive in [true, false]) {
      testWidgets('confirm starts on ${destructive ? 'Cancel' : 'the verb'}', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            Builder(
              builder: (context) => MeridianButton(
                label: 'Open',
                onPressed: () => showMeridianConfirm(
                  context,
                  title: 'Delete Linear algebra',
                  confirmLabel: 'Delete',
                  destructive: destructive,
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final focused = FocusManager.instance.primaryFocus!.context!;
        final expected = find.byWidgetPredicate(
          (widget) =>
              widget is MeridianButton &&
              widget.label == (destructive ? 'Cancel' : 'Delete'),
        );
        expect(
          find.ancestor(
            of: find.byElementPredicate((element) => element == focused),
            matching: expected,
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('an inline dialog specimen leaves focus alone', (tester) async {
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianButton(label: 'First', onPressed: () {}),
              const SizedBox(
                height: 200,
                child: MeridianDialog(title: 'Specimen'),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isA<FocusScopeNode>());
    });

    testWidgets('MeridianDialogSurface paints the raised float surface', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          const MeridianDialogSurface(
            maxWidth: 600,
            semanticLabel: 'Command palette',
            child: SizedBox(width: 900, height: 2000, child: Text('Body')),
          ),
        ),
      );
      final box = tester.getSize(
        find
            .ancestor(
              of: find.text('Body'),
              matching: find.byType(DecoratedBox),
            )
            .last,
      );
      expect(box.width, 600);
      expect(box.height, 800 * MeridianLayout.dialogMaxHeightFraction);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text('Body'),
                          matching: find.byType(DecoratedBox),
                        )
                        .last,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, colorsOf(tester).raised);
      expect(find.bySemanticsLabel('Command palette'), findsOneWidget);
      handle.dispose();
    });
  });

  group('MeridianTextField additions', () {
    testWidgets('fieldKey reaches the editable field', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 300,
            child: MeridianTextField(
              label: 'Branch',
              fieldKey: ValueKey('branch-name'),
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const ValueKey('branch-name')), 'main');
      expect(
        tester.widget<TextField>(find.byType(TextField)).key,
        const ValueKey('branch-name'),
      );
      expect(find.text('main'), findsOneWidget);
    });

    testWidgets('text fields take the presenter text menu', (tester) async {
      Widget nativeMenu(BuildContext context, EditableTextState editable) =>
          const SizedBox.shrink();
      await tester.pumpWidget(
        host(
          MeridianMenuPresenter(
            present: (context, {required anchor, required entries}) async {},
            textContextMenuBuilder: nativeMenu,
            child: const SizedBox(
              width: 300,
              child: MeridianTextField(label: 'Branch'),
            ),
          ),
        ),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).contextMenuBuilder,
        same(nativeMenu),
      );
      await tester.pumpWidget(
        host(
          const SizedBox(width: 300, child: MeridianTextField(label: 'Branch')),
        ),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).contextMenuBuilder,
        isNotNull,
      );
    });

    testWidgets('selectable properties take the presenter text menu', (
      tester,
    ) async {
      Widget nativeMenu(BuildContext context, EditableTextState editable) =>
          const SizedBox.shrink();
      await tester.pumpWidget(
        host(
          MeridianMenuPresenter(
            present: (context, {required anchor, required entries}) async {},
            textContextMenuBuilder: nativeMenu,
            child: const SizedBox(
              width: 400,
              child: MeridianPropertyList(
                properties: [
                  MeridianProperty(label: 'Committer', value: 'Ada Lovelace'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<SelectableText>(find.byType(SelectableText))
            .contextMenuBuilder,
        same(nativeMenu),
      );
    });

    testWidgets('a hidden label is still the accessible name', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 300,
            child: MeridianTextField(
              label: 'Search commands',
              showLabel: false,
            ),
          ),
        ),
      );
      expect(find.text('Search commands'), findsNothing);
      expect(find.bySemanticsLabel('Search commands'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('height overrides the single-line control height', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 300,
            child: MeridianTextField(placeholder: 'Subject', height: 32),
          ),
        ),
      );
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.byType(TextField),
                    matching: find.byType(AnimatedContainer),
                  )
                  .first,
            )
            .height,
        32,
      );
    });

    testWidgets('expands fills a bounded height', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 300,
            height: 240,
            child: MeridianTextField(label: 'Result', expands: true),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.expands, isTrue);
      expect(field.maxLines, isNull);
      expect(tester.getSize(find.byType(TextField)).height, greaterThan(150));
    });

    testWidgets('scrollController drives a multi-line field', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final controller = TextEditingController(
        text: [for (var line = 0; line < 80; line++) 'line $line'].join('\n'),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            height: 240,
            child: MeridianTextField(
              label: 'Result',
              controller: controller,
              scrollController: scroll,
              expands: true,
            ),
          ),
        ),
      );
      expect(scroll.hasClients, isTrue);
      expect(scroll.position.maxScrollExtent, greaterThan(240));
      final before = tester.getTopLeft(find.byType(EditableText));
      scroll.jumpTo(120);
      await tester.pump();
      expect(scroll.offset, 120);
      // The field stays put; only its text moves.
      expect(tester.getTopLeft(find.byType(EditableText)), before);
      expect(tester.takeException(), isNull);
    });
  });

  group('MeridianListRow additions', () {
    testWidgets('match underlines the query in accent', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 300,
            child: MeridianListRow(title: 'Fetch all remotes', match: 'all'),
          ),
        ),
      );
      final rich = tester.widget<RichText>(
        find.descendant(
          of: find.byType(MeridianListRow),
          matching: find.byType(RichText),
        ),
      );
      final spans = <TextSpan>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });
      final matched = spans.singleWhere((span) => span.text == 'all');
      expect(matched.style?.color, colorsOf(tester).accent);
      expect(matched.style?.decoration, TextDecoration.underline);
      expect(spans.map((span) => span.text).join(), 'Fetch all remotes');
    });

    testWidgets(
      'titleTrailing sits after the title and semanticValue is read',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          host(
            SizedBox(
              width: 300,
              child: MeridianListRow(
                title: 'main',
                meta: '2d',
                semanticValue: 'Current',
                titleTrailing: const MeridianCount(label: '3'),
                onTap: () {},
              ),
            ),
          ),
        );
        final title = tester.getTopRight(find.text('main'));
        final count = tester.getTopLeft(find.byType(MeridianCount));
        expect(count.dx, greaterThan(title.dx));
        expect(count.dx, lessThan(tester.getTopLeft(find.text('2d')).dx));
        expect(
          tester.getSemantics(find.byType(MeridianListRow)),
          matchesSemantics(
            label: 'main, 2d',
            value: 'Current',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasSelectedState: true,
            hasTapAction: true,
          ),
        );
        handle.dispose();
      },
    );
  });

  testWidgets('MeridianDisclosure header grows to fit and keeps the title', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 300,
          child: MeridianDisclosure(
            title: 'Fix the parser',
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fix the parser'),
                SizedBox(height: 40),
                Text('Ada Lovelace'),
              ],
            ),
            child: Text('Body'),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(
      tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Ada Lovelace'),
                  matching: find.byType(AnimatedContainer),
                )
                .first,
          )
          .height,
      greaterThan(MeridianSize.row + 40),
    );
    await tester.tap(find.text('Ada Lovelace'));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('a control that cannot take focus settles and skips Tab', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MeridianIconButton(
              label: 'Previous match',
              icon: MeridianIcons.chevronUp,
              canRequestFocus: false,
              onPressed: () => taps++,
            ),
            MeridianButton(label: 'Next', onPressed: () {}),
          ],
        ),
      ),
    );
    // Settles: the node's focusability no longer flips on every build.
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      find.ancestor(
        of: find.byElementPredicate((element) => element == focused),
        matching: find.byType(MeridianButton),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byType(MeridianIconButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('a hugging segmented control shrinks instead of overflowing', (
    tester,
  ) async {
    Widget segmented(double width) => host(
      SizedBox(
        width: width,
        child: Align(
          alignment: Alignment.centerLeft,
          child: MeridianSegmented<String>(
            label: 'Density',
            value: 'regular',
            segments: const [
              MeridianSegment(value: 'compact', label: 'Kompakt'),
              MeridianSegment(value: 'regular', label: 'Normal'),
              MeridianSegment(value: 'comfortable', label: 'Komfortabel'),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpWidget(segmented(600));
    final natural = tester
        .getSize(find.byType(MeridianSegmented<String>))
        .width;
    expect(
      natural,
      lessThan(600),
      reason: 'hugs its labels when there is room',
    );
    await tester.pumpWidget(segmented(natural * 0.6));
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(MeridianSegmented<String>)).width,
      lessThanOrEqualTo(natural * 0.6),
    );
  });

  group('suggestions', () {
    testWidgets('the highlighted row is solid accent and rows keep no focus', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: MeridianSuggestionSurface(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MeridianSuggestionHeader('Local branches'),
                  MeridianSuggestionRow(
                    label: 'main',
                    hint: 'origin/main',
                    icon: MeridianIcons.gitBranch,
                    highlighted: true,
                    onTap: () => picked = 'main',
                  ),
                  MeridianSuggestionRow(
                    label: 'develop',
                    onTap: () => picked = 'develop',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final colors = colorsOf(tester);
      expect(fillAround(tester, find.text('main')), colors.accent);
      expect(textColor(tester, 'main'), colors.onAccent);
      expect(textColor(tester, 'develop'), colors.ink);
      expect(find.text('LOCAL BRANCHES'), findsOneWidget);
      await tester.tap(find.text('develop'));
      expect(picked, 'develop');
      expect(FocusManager.instance.primaryFocus, isA<FocusScopeNode>());
    });

    testWidgets('a hovered suggestion paints pane-hover', (tester) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: MeridianSuggestionSurface(
              child: MeridianSuggestionRow(label: 'develop', onTap: () {}),
            ),
          ),
        ),
      );
      await hoverAt(tester, tester.getCenter(find.text('develop')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        fillAround(tester, find.text('develop')),
        colorsOf(tester).paneHover,
      );
    });

    testWidgets('the surface caps its height', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: MeridianSuggestionSurface(
              maxHeight: 120,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < 20; i++)
                    MeridianSuggestionRow(label: 'branch-$i', onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(MeridianSuggestionSurface)).height,
        120,
      );
    });
  });

  test('every added Development icon has its asset', () {
    for (final name in [
      MeridianIcons.gitFork,
      MeridianIcons.gitPullRequest,
      MeridianIcons.gitCompareArrows,
      MeridianIcons.fileDiff,
      MeridianIcons.folderGit2,
      MeridianIcons.squareTerminal,
    ]) {
      expect(File('assets/icons/$name.svg').existsSync(), isTrue, reason: name);
    }
  });

  testWidgets('menu presenter survives a keyboard-opened split button', (
    tester,
  ) async {
    var presented = 0;
    await tester.pumpWidget(
      host(
        MeridianMenuPresenter(
          present: (context, {required anchor, required entries}) async =>
              presented++,
          child: MeridianToolbarButton(
            label: 'Push',
            icon: MeridianIcons.upload,
            onPressed: () {},
            menu: [MeridianMenuItem(label: 'Force push', onSelected: () {})],
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel(RegExp('Show menu')));
    await tester.pumpAndSettle();
    expect(presented, 1);
    expect(find.byType(MeridianMenuSurface), findsNothing);
  });
}
