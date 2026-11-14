import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  group('controls on a hovered row stay visible', () {
    testWidgets('a hover action darkens the hovered row instead of '
        'matching it', (tester) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(
          MeridianIsland(
            child: SizedBox(
              width: 320,
              child: MeridianListRow(
                title: 'Quarterly report',
                onTap: () {},
                hoverActions: [
                  MeridianIconButton(
                    label: 'Archive',
                    icon: MeridianIcons.archive,
                    size: MeridianControlSize.small,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final colors = colorsOf(tester);
      final mouse = await hoverAt(
        tester,
        tester.getCenter(find.text('Quarterly report')),
      );
      await tester.pumpAndSettle();
      final action = find.byType(MeridianIconButton);
      expect(action, findsOneWidget);
      await mouse.moveTo(tester.getCenter(action));
      await tester.pumpAndSettle();
      final chip =
          tester
                  .widget<AnimatedContainer>(
                    find.descendant(
                      of: action,
                      matching: find.byType(AnimatedContainer),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(chip.color, isNot(colors.paneHover));
      expect(chip.color, meridianPressed(colors.paneHover, colors.ink));
    });

    testWidgets('on a solid accent selection it brightens', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => MeridianSurfaceScope(
              fill: context.meridian.colors.accent,
              child: Builder(
                builder: (context) => Text(
                  '${MeridianSurfaceScope.hoverFillOf(context).toARGB32()}',
                ),
              ),
            ),
          ),
        ),
      );
      final colors = colorsOf(tester);
      final expected = Color.alphaBlend(
        colors.onAccent.withValues(alpha: MeridianOpacity.primaryHoverOverlay),
        colors.accent,
      );
      expect(find.text('${expected.toARGB32()}'), findsOneWidget);
    });

    testWidgets('on a solid accent selection its icon uses on-accent inks', (
      tester,
    ) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => MeridianSurfaceScope(
              fill: context.meridian.colors.accent,
              child: Row(
                children: [
                  MeridianIconButton(
                    key: const ValueKey('enabled'),
                    label: 'Stage',
                    icon: MeridianIcons.archive,
                    color: context.meridian.colors.danger,
                    onPressed: () {},
                  ),
                  const MeridianIconButton(
                    key: ValueKey('disabled'),
                    label: 'Discard',
                    icon: MeridianIcons.archive,
                    onPressed: null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final colors = colorsOf(tester);
      Color? inkOf(String key) => tester
          .widget<MeridianIcon>(
            find.descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(MeridianIcon),
            ),
          )
          .color;
      expect(inkOf('enabled'), colors.onAccentMuted);
      expect(
        inkOf('disabled'),
        colors.onAccentMuted.withValues(alpha: MeridianOpacity.disabledContent),
      );
      await hoverAt(
        tester,
        tester.getCenter(find.byKey(const ValueKey('enabled'))),
      );
      await tester.pumpAndSettle();
      expect(inkOf('enabled'), colors.onAccent);
    });
  });

  testWidgets('NavRow shows a leading picture instead of its icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 240,
          child: MeridianNavRow(
            label: 'Safari',
            icon: MeridianIcons.circleDot,
            leading: SizedBox.square(key: ValueKey('app-icon'), dimension: 14),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('app-icon')), findsOneWidget);
    expect(find.byType(MeridianIcon), findsNothing);
    expect(
      tester.getTopLeft(find.text('Safari')).dx,
      greaterThan(
        tester.getTopRight(find.byKey(const ValueKey('app-icon'))).dx,
      ),
    );
  });

  group('MeridianTabs', () {
    const tabs = [
      MeridianTab(label: 'Inbox'),
      MeridianTab(label: 'Drafts', count: 3, dirty: true),
      MeridianTab(label: 'Archive', enabled: false),
      MeridianTab(label: 'Sent'),
    ];

    Widget strip({
      required int index,
      required ValueChanged<int> onChanged,
      ValueChanged<int>? onClose,
      MeridianTabsStyle style = MeridianTabsStyle.underline,
      List<MeridianTab> items = tabs,
      double width = 600,
    }) => host(
      SizedBox(
        width: width,
        child: MeridianTabs(
          tabs: items,
          index: index,
          onChanged: onChanged,
          onClose: onClose,
          style: style,
        ),
      ),
    );

    testWidgets('arrow keys move selection and focus, skipping disabled '
        'tabs', (tester) async {
      var index = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) =>
              strip(index: index, onChanged: (i) => setState(() => index = i)),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(index, 1);
      Finder tab(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(MeridianInteraction),
      );
      expect(ringVisible(tester, tab('Drafts')), isTrue);
      expect(ringVisible(tester, tab('Inbox')), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(index, 3, reason: 'Archive is disabled');
      expect(ringVisible(tester, tab('Sent')), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(index, 0);
    });

    testWidgets('a disabled tab ignores taps', (tester) async {
      var index = 0;
      await tester.pumpWidget(strip(index: index, onChanged: (i) => index = i));
      await tester.tap(find.text('Archive'));
      expect(index, 0);
      await tester.tap(find.text('Sent'));
      expect(index, 3);
    });

    testWidgets('count and dirty state are folded into the label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(strip(index: 0, onChanged: (_) {}));
      expect(
        find.bySemanticsLabel('Drafts, 3, unsaved changes'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Inbox')),
        isSemantics(isSelected: true, isButton: true),
      );
      semantics.dispose();
    });

    testWidgets('hidden pill close buttons take no taps but stay in '
        'semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      final closed = <int>[];
      var index = 0;
      await tester.pumpWidget(
        strip(
          index: index,
          style: MeridianTabsStyle.pill,
          onChanged: (i) => index = i,
          onClose: closed.add,
        ),
      );
      final closes = findTooltip('Close Sent');
      expect(closes, findsOneWidget);
      // Sent is not active or hovered: its close button is invisible.
      await tester.tap(closes, warnIfMissed: false);
      expect(closed, isEmpty);
      expect(index, 3, reason: 'the tap selects the tab underneath');
      expect(find.bySemanticsLabel('Close Sent'), findsOneWidget);
      // The active tab's close button works.
      await tester.tap(findTooltip('Close Inbox'));
      expect(closed, [0]);
      semantics.dispose();
    });

    testWidgets('the underline stays under its tab after scrolling', (
      tester,
    ) async {
      final many = [
        for (var i = 0; i < 12; i++) MeridianTab(label: 'Notebook $i'),
      ];
      var index = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => strip(
            index: index,
            items: many,
            width: 300,
            onChanged: (i) => setState(() => index = i),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();
      final target = find.text('Notebook 4');
      await tester.tap(target);
      await tester.pumpAndSettle();
      // The rule is the glide's indicator (MM-26).
      final rule = tester.getRect(
        find
            .descendant(
              of: find.byType(MeridianGlide),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final tab = tester.getRect(
        find.ancestor(of: target, matching: find.byType(KeyedSubtree)).first,
      );
      expect(rule.left, moreOrLessEquals(tab.left + MeridianSpace.space4));
      expect(rule.right, moreOrLessEquals(tab.right - MeridianSpace.space4));
    });
  });

  group('MeridianListRow', () {
    testWidgets('onTap runs at once; a second tap is a double tap', (
      tester,
    ) async {
      var taps = 0;
      var doubles = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            child: MeridianListRow(
              title: 'Quarterly report',
              onTap: () => taps++,
              onDoubleTap: () => doubles++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Quarterly report'));
      expect(taps, 1, reason: 'no 300ms wait for a possible double tap');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Quarterly report'));
      expect(doubles, 1);
      expect(taps, 1);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Quarterly report'));
      expect(taps, 2);
      expect(doubles, 1);
    });

    testWidgets('hover shows actions in place of meta, keeps trailing', (
      tester,
    ) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            child: MeridianListRow(
              title: 'Quarterly report',
              meta: '12 May',
              trailing: const Text('PDF'),
              onTap: () {},
              hoverActions: [
                MeridianIconButton(
                  label: 'Archive',
                  icon: MeridianIcons.archive,
                  size: MeridianControlSize.small,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('12 May'), findsOneWidget);
      expect(findTooltip('Archive'), findsNothing);
      await hoverAt(tester, tester.getCenter(find.text('Quarterly report')));
      await tester.pump();
      expect(findTooltip('Archive'), findsOneWidget);
      expect(find.text('12 May'), findsNothing);
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('actions stay while keyboard focus is inside them', (
      tester,
    ) async {
      var archived = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            child: MeridianListRow(
              title: 'Quarterly report',
              onTap: () {},
              hoverActions: [
                MeridianIconButton(
                  label: 'Archive',
                  icon: MeridianIcons.archive,
                  size: MeridianControlSize.small,
                  onPressed: () => archived++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(findTooltip('Archive'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(findTooltip('Archive'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(archived, 1);
      final action = find.ancestor(
        of: findTooltip('Archive'),
        matching: find.byType(MeridianIconButton),
      );
      expect(ringVisible(tester, action), isTrue);
    });

    testWidgets('a disabled row fades all content to ink-faint', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            child: MeridianListRow(
              title: 'Quarterly report',
              subtitle: 'Finance',
              meta: '12 May',
              enabled: false,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      final faint = colorsOf(tester).inkFaint;
      expect(textColor(tester, 'Quarterly report'), faint);
      expect(textColor(tester, 'Finance'), faint);
      expect(textColor(tester, '12 May'), faint);
      await tester.tap(find.text('Quarterly report'));
      expect(taps, 0);
    });

    testWidgets('becoming two-line never overflows mid-animation', (
      tester,
    ) async {
      Widget row(MeridianDensity density) => host(
        SizedBox(
          width: 400,
          child: MeridianListRow(
            title: 'Anna Berg',
            subtitle: 'Quarterly report draft',
            twoLine: density.isTouch,
            onTap: () {},
          ),
        ),
        density: density,
      );
      await tester.pumpWidget(row(MeridianDensity.regular));
      await tester.pumpWidget(row(MeridianDensity.touch));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('MeridianList insets rows by space-3', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            height: 200,
            child: MeridianList(
              children: [MeridianListRow(title: 'First', onTap: () {})],
            ),
          ),
        ),
      );
      final list = tester.getRect(find.byType(MeridianList));
      final row = tester.getRect(find.byType(MeridianListRow));
      expect(row.left - list.left, MeridianSpace.space3);
      expect(row.top - list.top, MeridianSpace.space3);
      expect(list.right - row.right, MeridianSpace.space3);
    });
  });

  group('MeridianNavSection', () {
    testWidgets('a collapsible header folds from a tap and from Enter', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 240,
            child: MeridianNavSection(
              title: 'Labels',
              collapsible: true,
              children: [MeridianNavRow(label: 'Work', onTap: () {})],
            ),
          ),
        ),
      );
      expect(find.text('Work'), findsOneWidget);
      await tester.tap(find.text('LABELS'));
      // The rows fade and collapse (motion-exit + motion-layout, MM-24).
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.text('Work'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('the header is 48px at touch density', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 240,
            child: MeridianNavSection(
              title: 'Labels',
              collapsible: true,
              children: [],
            ),
          ),
          brand: MeridianBrands.nibluma,
        ),
      );
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byType(MeridianNavSection),
                matching: find.byType(MeridianInteraction),
              ),
            )
            .height,
        48,
      );
    });

    testWidgets('the action is revealed when it takes focus', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 240,
            child: MeridianNavSection(
              title: 'Folders',
              action: MeridianIconButton(
                label: 'New folder',
                icon: MeridianIcons.plus,
                size: MeridianControlSize.small,
                onPressed: () {},
              ),
              children: const [],
            ),
          ),
        ),
      );
      double opacity() => tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byType(MeridianIconButton),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      expect(opacity(), 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(opacity(), 1);
    });
  });

  group('MeridianNavRow', () {
    testWidgets('the chevron is its own focusable target', (tester) async {
      var toggles = 0;
      var taps = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 240,
            child: MeridianNavRow(
              label: 'Projects',
              expandable: true,
              onToggleExpanded: () => toggles++,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      final chevron = findTooltip('Expand');
      expect(chevron, findsOneWidget);
      expect(
        tester.getSize(chevron).width,
        greaterThanOrEqualTo(MeridianLayout.navChevronTarget),
      );
      await tester.tap(chevron);
      expect(toggles, 1);
      expect(taps, 0);
      // Row first, then the chevron.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringVisible(tester, chevron), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(toggles, 2);
      expect(taps, 0);
      // Arrow right on the collapsed row expands it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(toggles, 3);
    });

    testWidgets('the chevron is 48px at touch density', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: MeridianNavRow(
              label: 'Projects',
              expandable: true,
              onToggleExpanded: () {},
            ),
          ),
          brand: MeridianBrands.nibluma,
        ),
      );
      final chevron = find.descendant(
        of: findTooltip('Expand'),
        matching: find.byType(MeridianInteraction),
      );
      expect(tester.getSize(chevron), const Size(48, 48));
    });

    testWidgets('disabled rows ignore taps and fade', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 240,
            child: MeridianNavRow(
              label: 'Trash',
              enabled: false,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Trash'));
      expect(taps, 0);
      expect(textColor(tester, 'Trash'), colorsOf(tester).inkFaint);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Trash')),
        isSemantics(isEnabled: false),
      );
      semantics.dispose();
    });
  });

  group('MeridianBreadcrumbs', () {
    // The test font sets every glyph at its font size; keep labels short so
    // the full trail fits 700 px.
    List<MeridianBreadcrumb> trail({
      List<String>? log,
      List<Offset>? menus,
    }) => [
      MeridianBreadcrumb(
        label: 'Bump 1.1.1',
        leading: const MeridianIcon(MeridianIcons.gitCommitHorizontal),
        onActivate: () => log?.add('commit'),
        onContextMenu: menus?.add,
      ),
      for (final folder in ['lib', 'app', 'src', 'ui'])
        MeridianBreadcrumb(label: folder, onActivate: () => log?.add(folder)),
      MeridianBreadcrumb(
        label: 'a.lock',
        mono: true,
        emphasis: true,
        onContextMenu: menus?.add,
      ),
    ];

    Widget bar(
      List<MeridianBreadcrumb> crumbs, {
      double width = 700,
      void Function(List<MeridianBreadcrumb>, Offset)? onOverflow,
      MeridianDensity? density,
      MeridianBrand brand = MeridianBrands.gitlama,
      TextDirection textDirection = TextDirection.ltr,
      double textScale = 1,
    }) => host(
      SizedBox(
        width: width,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: MeridianBreadcrumbs(
            crumbs: crumbs,
            onOverflow: onOverflow,
            semanticLabel: 'Location',
          ),
        ),
      ),
      density: density,
      brand: brand,
      textDirection: textDirection,
      textScale: textScale,
    );

    testWidgets('a tap activates a crumb; plain crumbs take none', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(bar(trail(log: log)));
      await tester.tap(find.text('app'));
      await tester.tap(find.text('Bump 1.1.1'));
      await tester.tap(find.text('a.lock'));
      expect(log, ['app', 'commit']);
      // Five chevrons between six crumbs, in ink-faint.
      final chevrons = tester.widgetList<MeridianIcon>(
        find.byWidgetPredicate(
          (w) => w is MeridianIcon && w.name == MeridianIcons.chevronRight,
        ),
      );
      expect(chevrons, hasLength(5));
      expect(chevrons.map((icon) => icon.color).toSet(), {
        colorsOf(tester).inkFaint,
      });
    });

    testWidgets('Enter and Space activate the focused crumb', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(bar(trail(log: log)));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(log, ['commit', 'lib']);
    });

    testWidgets('secondary click, the menu key and Shift+F10 open the '
        'context menu', (tester) async {
      final menus = <Offset>[];
      await tester.pumpWidget(bar(trail(menus: menus)));
      final file = tester.getCenter(find.text('a.lock'));
      await tester.tapAt(file, buttons: kSecondaryButton);
      expect(menus, [file]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      expect(menus, hasLength(2));
      final box = tester.getRect(
        find.ancestor(
          of: find.text('Bump 1.1.1'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(menus.last, box.bottomLeft);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(menus, hasLength(3));
    });

    testWidgets('at 300 px the middle folds into … and the ends stay', (
      tester,
    ) async {
      final hidden = <List<String>>[];
      final log = <String>[];
      await tester.pumpWidget(
        bar(
          trail(log: log),
          width: 300,
          onOverflow: (crumbs, _) =>
              hidden.add([for (final crumb in crumbs) crumb.label]),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final row = tester.getRect(find.byType(MeridianBreadcrumbs));
      expect(row.width, lessThanOrEqualTo(300));
      bool shown(String label) =>
          find.text(label).hitTestable().evaluate().isNotEmpty;
      expect(shown('Bump 1.1.1'), isTrue);
      expect(shown('a.lock'), isTrue);
      expect(shown('…'), isTrue);
      expect(shown('lib'), isFalse);
      await tester.tap(find.text('…'));
      expect(hidden, hasLength(1));
      expect(hidden.single.first, 'lib');
      expect(log, isEmpty);
      // The folded crumbs leave focus traversal; the … crumb joins it.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(hidden, hasLength(2));
    });

    testWidgets('the first crumb ellipsizes before the last', (tester) async {
      final crumbs = [
        const MeridianBreadcrumb(
          label: 'A long commit subject that does not fit at all',
        ),
        MeridianBreadcrumb(label: 'lib', onActivate: () {}),
        const MeridianBreadcrumb(label: 'pubspec.lock', emphasis: true),
      ];
      await tester.pumpWidget(bar(crumbs, width: 300));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final last = tester.renderObject<RenderParagraph>(
        find.text('pubspec.lock'),
      );
      final first = tester.renderObject<RenderParagraph>(
        find.text('A long commit subject that does not fit at all'),
      );
      expect(last.didExceedMaxLines, isFalse);
      expect(first.didExceedMaxLines, isTrue);
      expect(
        tester.getSize(find.byType(MeridianBreadcrumbs)).width,
        lessThanOrEqualTo(300),
      );
    });

    testWidgets('semantics: buttons for interactive crumbs, a header for '
        'the trail', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(bar(trail(log: [], menus: [])));
      expect(
        tester.getSemantics(find.bySemanticsLabel('lib')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('a.lock')),
        isSemantics(isButton: false, hasLongPressAction: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Location')),
        isSemantics(isHeader: true),
      );
      semantics.dispose();
    });

    testWidgets('mono, emphasis and hover follow the type and ink tokens', (
      tester,
    ) async {
      useDesktopHighlights();
      await tester.pumpWidget(bar(trail(log: [])));
      final meridian = MeridianTheme.of(
        tester.element(find.byType(MeridianGround)),
      );
      final file = tester.widget<Text>(find.text('a.lock')).style!;
      expect(file.fontFamily, meridian.text.codeSm.fontFamily);
      expect(file.color, meridian.colors.ink);
      expect(textColor(tester, 'lib'), meridian.colors.inkMuted);
      await hoverAt(tester, tester.getCenter(find.text('lib')));
      await tester.pumpAndSettle();
      expect(textColor(tester, 'lib'), meridian.colors.ink);
      final fill =
          tester
                  .widget<AnimatedContainer>(
                    find.ancestor(
                      of: find.text('lib'),
                      matching: find.byType(AnimatedContainer),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(fill.color?.a, greaterThan(0));
    });

    testWidgets('lays out at every density, in every brand and in RTL', (
      tester,
    ) async {
      for (final density in MeridianDensity.values) {
        for (final brand in MeridianBrands.all) {
          for (final width in [700.0, 300.0, 120.0]) {
            await tester.pumpWidget(
              bar(
                trail(log: []),
                width: width,
                density: density,
                brand: brand,
                textDirection: width == 300
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              ),
            );
            await tester.pump();
            expect(
              tester.takeException(),
              isNull,
              reason: '$density ${brand.name} $width',
            );
          }
        }
      }
    });

    testWidgets('a wide leading never overflows the crumb, even with large '
        'text', (tester) async {
      final crumbs = [
        MeridianBreadcrumb(
          label: 'A subject that ellipsizes',
          leading: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianIcon(MeridianIcons.gitCommitHorizontal),
              SizedBox(width: MeridianSpace.space2),
              Text('434cdea0'),
            ],
          ),
          onActivate: () {},
        ),
        MeridianBreadcrumb(label: 'lib', onActivate: () {}),
        const MeridianBreadcrumb(label: 'main.dart', emphasis: true),
      ];
      for (final width in [600.0, 200.0, 60.0]) {
        for (final scale in [1.0, 2.0]) {
          await tester.pumpWidget(bar(crumbs, width: width, textScale: scale));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: '$width $scale');
          expect(
            tester.getSize(find.byType(MeridianBreadcrumbs)).width,
            lessThanOrEqualTo(width),
          );
        }
      }
    });
  });
}
