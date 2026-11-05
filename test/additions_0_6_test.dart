import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

/// A button that opens [entries] in a Meridian menu.
Widget _menuButton(List<MeridianMenuEntry> entries) => MeridianMenuAnchor(
  entries: entries,
  builder: (context, open) => MeridianButton(label: 'Actions', onPressed: open),
);

void main() {
  group('user themes', () {
    test('replacement colours and type scale win over the brand', () {
      final base = MeridianColors.resolve(
        Brightness.light,
        MeridianBrands.crossproton.light,
      );
      final colors = base.copyWith(ground: const Color(0xFF102030));
      final scale = MeridianTypeScale.desktop.copyWith(
        heading: MeridianTypeScale.desktop.heading.copyWith(
          fontSize: 19,
          fontFamily: 'Georgia',
        ),
      );
      final theme = buildMeridianTheme(
        brand: MeridianBrands.crossproton,
        brightness: Brightness.light,
        colors: colors,
        typeScale: scale,
      ).extension<MeridianTheme>()!;
      expect(theme.colors.ground, const Color(0xFF102030));
      expect(theme.colors.pane, base.pane);
      expect(theme.text.heading.fontSize, 19);
      // A family named on the scale is kept; the others take the brand's.
      expect(theme.text.heading.fontFamily, 'Georgia');
      expect(theme.text.body.fontFamily, 'Inter');
      expect(theme.text.body.color, theme.colors.ink);
    });

    test('copyWith keeps the replacements', () {
      final theme = MeridianTheme.resolve(
        brand: MeridianBrands.crossproton,
        brightness: Brightness.dark,
        typeScale: MeridianTypeScale.touch,
      );
      final next = theme.copyWith(density: MeridianDensity.compact);
      expect(next.typeScale, MeridianTypeScale.touch);
      expect(next.text.body.fontSize, MeridianTypeScale.touch.body.fontSize);
    });
  });

  group('menu additions', () {
    testWidgets('a submenu opens on hover and runs its item', (tester) async {
      useDesktopHighlights();
      var moved = '';
      await tester.pumpWidget(
        host(
          _menuButton([
            MeridianMenuItem(label: 'Archive', onSelected: () {}),
            MeridianMenuItem(
              label: 'Move to',
              children: [
                MeridianMenuItem(label: 'Work', onSelected: () => moved = 'w'),
                MeridianMenuItem(label: 'Home', onSelected: () => moved = 'h'),
              ],
            ),
          ]),
        ),
      );
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      expect(find.text('Work'), findsNothing);
      await hoverAt(tester, tester.getCenter(find.text('Move to')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.text('Work'), findsOneWidget);
      // The submenu opens beside its row.
      expect(
        tester.getTopLeft(find.text('Work')).dx,
        greaterThan(tester.getTopRight(find.text('Move to')).dx),
      );
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(moved, 'h');
      expect(find.byType(MeridianMenuSurface), findsNothing);
    });

    testWidgets('→ opens a submenu, ← closes it, Enter runs an item', (
      tester,
    ) async {
      var chosen = '';
      await tester.pumpWidget(
        host(
          MeridianMenuSurface(
            entries: [
              MeridianMenuItem(
                label: 'Label as',
                children: [
                  MeridianMenuItem(
                    label: 'Travel',
                    onSelected: () => chosen = 'travel',
                  ),
                  MeridianMenuItem(
                    label: 'Receipts',
                    onSelected: () => chosen = 'receipts',
                  ),
                ],
              ),
            ],
            onSelected: (item) => item.onSelected?.call(),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Travel'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('Travel'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Travel'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, 'receipts');
    });

    testWidgets('type-ahead jumps to an item and skips custom content', (
      tester,
    ) async {
      MeridianMenuItem? chosen;
      await tester.pumpWidget(
        host(
          MeridianMenuSurface(
            entries: [
              const MeridianMenuCustom(Text('anna@example.com')),
              MeridianMenuItem(label: 'Copy address', onSelected: () {}),
              MeridianMenuItem(label: 'New message', onSelected: () {}),
              MeridianMenuItem(label: 'Block sender', onSelected: () {}),
            ],
            onSelected: (item) => chosen = item,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('anna@example.com'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(chosen?.label, 'New message');
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(chosen?.label, 'Copy address');
    });

    testWidgets('leading widgets and label styles render', (tester) async {
      await tester.pumpWidget(
        host(
          MeridianMenuSurface(
            entries: [
              MeridianMenuItem(
                label: 'Travel',
                leading: const SizedBox(key: Key('dot'), width: 8, height: 8),
                onSelected: () {},
              ),
              MeridianMenuItem(
                label: 'Georgia',
                labelStyle: const TextStyle(fontFamily: 'Georgia'),
                onSelected: () {},
              ),
            ],
            onSelected: (_) {},
          ),
        ),
      );
      expect(find.byKey(const Key('dot')), findsOneWidget);
      expect(textColor(tester, 'Georgia'), colorsOf(tester).ink);
      expect(
        tester.widget<Text>(find.text('Georgia')).style?.fontFamily,
        'Georgia',
      );
    });
  });

  testWidgets('manual activation moves focus and selects on Enter', (
    tester,
  ) async {
    var value = 'All';
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => host(
          MeridianSegmented<String>(
            label: 'Show',
            value: value,
            manualActivation: true,
            segments: const [
              MeridianSegment(value: 'All', label: 'All'),
              MeridianSegment(value: 'Unread', label: 'Unread'),
            ],
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 'All');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(value, 'Unread');
  });

  testWidgets('nav rows show drop feedback', (tester) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianNavRow(
                label: 'Work',
                icon: MeridianIcons.folder,
                drop: MeridianDropFeedback.accept,
              ),
              MeridianNavRow(
                label: 'Sent',
                icon: MeridianIcons.send,
                drop: MeridianDropFeedback.reject,
              ),
            ],
          ),
        ),
      ),
    );
    final colors = colorsOf(tester);
    expect(fillAround(tester, find.text('Work')), colors.accentSoft);
    expect(textColor(tester, 'Work'), colors.accentInk);
    expect(textColor(tester, 'Sent'), colors.inkFaint);
  });

  group('MeridianPagination', () {
    testWidgets('page buttons hug their numbers in a narrow pane', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 330,
            child: MeridianPagination(
              page: 1,
              pageCount: 2,
              previousLabel: 'Previous',
              nextLabel: 'Next',
              jumpLabel: 'Page',
              pageCountLabel: (count) => 'of $count',
              onPageSelected: (_) {},
            ),
          ),
        ),
      );
      final one = tester.getRect(find.text('1').first);
      final two = tester.getRect(find.text('2'));
      expect(one.center.dy, two.center.dy);
      final button = tester.getSize(
        find
            .ancestor(
              of: find.text('2'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(button.width, lessThan(48));
      expect(tester.getCenter(find.text('Page')).dy, closeTo(two.center.dy, 2));
    });

    test('collapses long ranges around the current page', () {
      expect(MeridianPagination.visiblePages(1, 5), [1, 2, 3, 4, 5]);
      expect(MeridianPagination.visiblePages(2, 20), [1, 2, 3, 4, 5, null, 20]);
      expect(MeridianPagination.visiblePages(10, 20), [
        1,
        null,
        9,
        10,
        11,
        null,
        20,
      ]);
      expect(MeridianPagination.visiblePages(19, 20), [
        1,
        null,
        16,
        17,
        18,
        19,
        20,
      ]);
    });

    Widget pagination({
      required ValueChanged<int> onPage,
      int page = 3,
      bool enabled = true,
      int count = 12,
    }) => host(
      SizedBox(
        width: 700,
        child: MeridianPagination(
          page: page,
          pageCount: count,
          enabled: enabled,
          previousLabel: 'Previous page',
          nextLabel: 'Next page',
          pageLabel: (p) => 'Page $p',
          jumpLabel: 'Page',
          pageCountLabel: (n) => 'of $n',
          onPageSelected: onPage,
        ),
      ),
    );

    testWidgets('pages, arrows and the jump field select pages', (
      tester,
    ) async {
      final pages = <int>[];
      await tester.pumpWidget(pagination(onPage: pages.add));
      await tester.tap(find.text('4'));
      await tester.tap(find.byTooltip('Previous page'));
      await tester.tap(find.byTooltip('Next page'));
      await tester.enterText(find.byType(EditableText), '99');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();
      expect(pages, [4, 2, 4, 12]);
      expect(find.text('of 12'), findsOneWidget);
    });

    testWidgets('nothing runs while loading, nothing shows for one page', (
      tester,
    ) async {
      final pages = <int>[];
      await tester.pumpWidget(pagination(onPage: pages.add, enabled: false));
      await tester.tap(find.text('4'));
      await tester.tap(find.byTooltip('Next page'));
      expect(pages, isEmpty);
      await tester.pumpWidget(pagination(onPage: pages.add, page: 1, count: 1));
      expect(find.byType(MeridianIconButton), findsNothing);
    });
  });

  testWidgets('a narrow selection bar moves commands into its menu', (
    tester,
  ) async {
    var archived = 0;
    var deleted = 0;
    Widget bar(double width) => host(
      SizedBox(
        width: width,
        child: MeridianSelectionBar(
          label: '3 selected',
          clearLabel: 'Clear',
          overflowLabel: 'More actions',
          onClear: () {},
          actions: [
            MeridianSelectionAction(
              child: MeridianIconButton(
                label: 'Archive',
                icon: MeridianIcons.archive,
                size: MeridianControlSize.small,
                onPressed: () => archived++,
              ),
            ),
            for (final name in ['Spam', 'Snooze'])
              MeridianSelectionAction(
                child: MeridianIconButton(
                  label: name,
                  icon: MeridianIcons.clock,
                  size: MeridianControlSize.small,
                  onPressed: () {},
                ),
                overflow: MeridianMenuItem(label: name, onSelected: () {}),
              ),
            MeridianSelectionAction(
              child: MeridianIconButton(
                label: 'Delete',
                icon: MeridianIcons.trash2,
                size: MeridianControlSize.small,
                onPressed: () => deleted++,
              ),
              overflow: MeridianMenuItem(
                label: 'Delete',
                icon: MeridianIcons.trash2,
                onSelected: () => deleted++,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(bar(600));
    expect(find.byTooltip('More actions'), findsNothing);
    await tester.tap(find.byTooltip('Delete'));
    expect(deleted, 1);
    await tester.pumpWidget(bar(260));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Archive'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsNothing);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, 2);
    expect(archived, 0);
  });

  group('MeridianDropZone', () {
    testWidgets('browses from a click and from the keyboard', (tester) async {
      var browsed = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: MeridianDropZone(
              label: 'Drop files to attach',
              message: 'Up to 25 MB',
              onBrowse: () => browsed++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Drop files to attach'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(browsed, 2);
      expect(
        tester.getSize(find.byType(MeridianDropZone)).height,
        greaterThanOrEqualTo(MeridianLayout.dropZoneMinHeight),
      );
    });

    testWidgets('shows active and invalid states', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianDropZone(
                label: 'Accept',
                state: MeridianDropZoneState.active,
              ),
              MeridianDropZone(
                label: 'Reject',
                state: MeridianDropZoneState.invalid,
              ),
            ],
          ),
        ),
      );
      // The active edge marches forever (MM-77): pump, never settle.
      await tester.pump(const Duration(milliseconds: 300));
      final colors = colorsOf(tester);
      expect(textColor(tester, 'Accept'), colors.accentInk);
      expect(fillAround(tester, find.text('Accept')), colors.accentSoft);
      expect(textColor(tester, 'Reject'), colors.danger);
    });
  });

  testWidgets('a busy overlay takes no input and says what is happening', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 300,
          height: 200,
          child: Stack(
            children: [
              Positioned.fill(
                child: MeridianButton(label: 'Go', onPressed: () => taps++),
              ),
              const Positioned.fill(
                child: MeridianBusyOverlay(message: 'Verifying…'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(MeridianBusyOverlay), warnIfMissed: false);
    expect(taps, 0);
    expect(find.text('Verifying…'), findsOneWidget);
    expect(find.byType(MeridianSpinner), findsOneWidget);
  });

  testWidgets('a busy overlay keeps its action usable and the rest covered', (
    tester,
  ) async {
    var taps = 0;
    var cancels = 0;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 400,
          height: 200,
          child: Stack(
            children: [
              Positioned.fill(
                child: MeridianButton(label: 'Go', onPressed: () => taps++),
              ),
              Positioned.fill(
                child: MeridianBusyOverlay(
                  message: 'Merging…',
                  action: MeridianButton(
                    label: 'Cancel',
                    variant: MeridianButtonVariant.quiet,
                    onPressed: () => cancels++,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Past `motion-spinner-delay` and the fade; the spinner never settles.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tapAt(const Offset(4, 4));
    await tester.tap(find.text('Merging…'));
    expect(taps, 0);
    await tester.tap(find.text('Cancel'));
    expect(cancels, 1);
    expect(taps, 0);
  });

  group('MeridianCalendar', () {
    final first = DateTime(2026, 1, 1);
    final last = DateTime(2026, 12, 31);

    testWidgets('a tap chooses a day; days out of range cannot', (
      tester,
    ) async {
      DateTime? chosen;
      await tester.pumpWidget(
        host(
          MeridianCalendar(
            value: DateTime(2026, 3, 10),
            firstDate: DateTime(2026, 3, 5),
            lastDate: last,
            onChanged: (day) => chosen = day,
          ),
        ),
      );
      expect(find.text('March 2026'), findsOneWidget);
      await tester.tap(find.text('3'));
      expect(chosen, isNull);
      await tester.tap(find.text('12'));
      expect(chosen, DateTime(2026, 3, 12));
    });

    testWidgets('arrows, Page Down and Enter pick with the keyboard', (
      tester,
    ) async {
      DateTime? chosen;
      await tester.pumpWidget(
        host(
          MeridianCalendar(
            value: DateTime(2026, 3, 10),
            firstDate: first,
            lastDate: last,
            autofocus: true,
            onChanged: (day) => chosen = day,
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(find.text('April 2026'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(chosen, DateTime(2026, 4, 18));
    });

    testWidgets('the date picker returns the day, or null on cancel', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final picked = showMeridianDatePicker(
        context: context,
        initialDate: DateTime(2026, 5, 20),
        firstDate: first,
        lastDate: last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('22'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await picked, DateTime(2026, 5, 22));

      final cancelled = showMeridianDatePicker(
        context: context,
        initialDate: DateTime(2026, 5, 20),
        firstDate: first,
        lastDate: last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await cancelled, isNull);
    });
  });

  group('popovers', () {
    testWidgets('an anchor opens content below it; Escape closes it', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          MeridianPopoverAnchor(
            width: 240,
            builder: (context, open) =>
                MeridianButton(label: 'Filter', onPressed: open),
            popoverBuilder: (context) => const Padding(
              padding: EdgeInsets.all(MeridianSpace.space4),
              child: Text('Popover content'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      expect(find.byType(MeridianPopoverSurface), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(MeridianPopoverSurface)).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.text('Filter')).dy),
      );
      expect(tester.getSize(find.byType(MeridianPopoverSurface)).width, 240);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Popover content'), findsNothing);
    });

    testWidgets('showMeridianPopover returns what the content pops', (
      tester,
    ) async {
      late BuildContext origin;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              origin = context;
              return const SizedBox(width: 100, height: 40);
            },
          ),
        ),
      );
      final result = showMeridianPopover<String>(
        origin,
        anchor: const Rect.fromLTWH(100, 100, 100, 40),
        builder: (context) => MeridianButton(
          label: 'Pick',
          onPressed: () => Navigator.of(context).pop('picked'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(await result, 'picked');
    });
  });

  group('field and row additions', () {
    testWidgets('the plain text field has no edge of its own', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 240,
            child: MeridianTextField(
              label: 'To',
              showLabel: false,
              variant: MeridianTextFieldVariant.plain,
            ),
          ),
        ),
      );
      final colors = colorsOf(tester);
      final edges = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(MeridianTextField),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .where(
            (decoration) =>
                decoration.border is Border &&
                (decoration.border! as Border).top.color == colors.controlEdge,
          );
      expect(edges, isEmpty);
      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('clearLabel clears the text; onTap reports taps', (
      tester,
    ) async {
      var taps = 0;
      final controller = TextEditingController(text: 'invoice');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 240,
            child: MeridianTextField(
              label: 'Search',
              controller: controller,
              variant: MeridianTextFieldVariant.search,
              clearLabel: 'Clear search',
              onTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(taps, 1);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(find.byTooltip('Clear search'), findsNothing);
    });

    testWidgets('suggestion rows show a leading picture', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 280,
            child: MeridianSuggestionRow(
              label: 'Ada Lovelace',
              hint: 'ada@example.com',
              leading: const MeridianAvatar(name: 'Ada Lovelace'),
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.byType(MeridianAvatar), findsOneWidget);
      expect(find.text('ada@example.com'), findsOneWidget);
    });

    testWidgets('xLarge avatars take a monogram and fall back from images', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          MeridianAvatar(
            name: 'Ada Lovelace',
            monogram: 'AL',
            size: MeridianAvatarSize.xLarge,
            image: MemoryImage(Uint8List.fromList(const [0, 1, 2, 3])),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        tester.getSize(find.byType(MeridianAvatar)),
        const Size.square(MeridianLayout.avatarXLarge),
      );
      expect(find.text('AL'), findsOneWidget);
    });
  });

  group('theme additions', () {
    test('shadows can be replaced and tinted', () {
      final tinted = MeridianShadows.light.tinted(
        pane: const Color(0xFF123456),
      );
      final theme = buildMeridianTheme(
        brand: MeridianBrands.crossproton,
        brightness: Brightness.light,
        shadows: tinted,
      ).extension<MeridianTheme>()!;
      expect(theme.shadows, tinted);
      for (final (index, layer) in theme.shadows.shadowPane.indexed) {
        expect(layer.color.withValues(alpha: 1), const Color(0xFF123456));
        expect(layer.color.a, MeridianShadows.light.shadowPane[index].color.a);
      }
      expect(theme.shadows.shadowFloat, MeridianShadows.light.shadowFloat);
    });

    test('corner radii animate between themes', () {
      final a = MeridianTheme.resolve(
        brand: MeridianBrands.crossproton,
        brightness: Brightness.light,
      );
      final b = a.copyWith(
        brand: MeridianBrands.crossproton.copyWith(
          radius: const MeridianRadiusScale(
            xs: 4,
            sm: 8,
            md: 16,
            lg: 24,
            xl: 32,
          ),
        ),
      );
      final middle = a.lerp(b, .5);
      expect(middle.radius.md, (a.radius.md + 16) / 2);
      expect(middle.radius.xl, (a.radius.xl + 32) / 2);
    });

    testWidgets('match styles underline in the given colour', (tester) async {
      await tester.pumpWidget(host(const SizedBox()));
      final text = MeridianTheme.of(tester.element(find.byType(SizedBox))).text;
      final match = text.match(text.body, const Color(0xFF6D4AFF));
      expect(match.color, const Color(0xFF6D4AFF));
      expect(match.decoration, TextDecoration.underline);
      expect(match.fontWeight, text.bodyStrong.fontWeight);
    });
  });

  testWidgets('a resize handle follows the pointer from where it went down', (
    tester,
  ) async {
    var dragged = 0.0;
    await tester.pumpWidget(
      host(
        SizedBox(
          height: 200,
          child: MeridianResizeHandle(
            semanticLabel: 'Resize',
            onDrag: (delta) => dragged += delta,
          ),
        ),
      ),
    );
    await tester.drag(find.byType(MeridianResizeHandle), const Offset(30, 0));
    await tester.pump(kDoubleTapTimeout);
    expect(dragged, 30);
  });

  testWidgets('the date picker shows in the requested locale', (tester) async {
    late BuildContext origin;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            origin = context;
            return const SizedBox();
          },
        ),
      ),
    );
    unawaited(
      showMeridianDatePicker(
        context: origin,
        initialDate: DateTime(2026, 3, 18),
        firstDate: DateTime(2026),
        lastDate: DateTime(2026, 12, 31),
        locale: const Locale('en', 'GB'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Localizations.localeOf(tester.element(find.byType(MeridianCalendar))),
      const Locale('en', 'GB'),
    );
  });
}
