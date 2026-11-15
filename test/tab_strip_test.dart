import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

/// Tabs as an app keeps them: moves are applied, and a group's tabs stay
/// together.
class _Strip extends StatefulWidget {
  const _Strip({
    required this.tabs,
    this.groups = const [],
    this.width = 900,
    this.moves,
  });

  final List<(String, int?)> tabs;
  final List<MeridianStripGroup<int>> groups;
  final double width;
  final List<Object>? moves;

  @override
  State<_Strip> createState() => _StripState();
}

class _StripState extends State<_Strip> {
  late List<(String, int?)> tabs = [...widget.tabs];
  var active = 'a';
  final key = GlobalKey<MeridianTabStripState<String, int>>();

  void edit(void Function(List<(String, int?)> tabs) change) =>
      setState(() => change(tabs));

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    child: Align(
      alignment: Alignment.centerLeft,
      child: MeridianTabStrip<String, int>(
        key: key,
        tabs: [
          for (final (id, group) in tabs)
            MeridianStripTab(id: id, label: id, group: group),
        ],
        groups: widget.groups,
        activeTab: active,
        onActivate: (id) => setState(() => active = id),
        onClose: (id) =>
            setState(() => tabs.removeWhere((tab) => tab.$1 == id)),
        onMoveTab: (id, index, group) {
          widget.moves?.add((id, index, group));
          setState(() {
            tabs.removeWhere((tab) => tab.$1 == id);
            tabs.insert(index, (id, group));
          });
        },
        onMoveGroup: (group, index) {
          widget.moves?.add((group, index));
          setState(() {
            final members = tabs.where((tab) => tab.$2 == group).toList();
            tabs.removeWhere((tab) => tab.$2 == group);
            tabs.insertAll(index, members);
          });
        },
        onRenameTab: (id, name) => widget.moves?.add(('renamed', id, name)),
        onToggleGroup: (id) => widget.moves?.add(('toggled', id)),
      ),
    ),
  );
}

const _client = MeridianStripGroup<int>(
  id: 7,
  color: Color(0xFF7C5CD6),
  name: 'Client',
);

void main() {
  late List<Object> moves;
  setUp(() => moves = []);

  _StripState strip(WidgetTester tester) =>
      tester.state<_StripState>(find.byType(_Strip));

  List<(String, int?)> order(WidgetTester tester) => strip(tester).tabs;

  Rect tab(WidgetTester tester, String label) =>
      tester.getRect(find.byKey(ValueKey(('tab-pill', label))));

  Rect chip(WidgetTester tester) =>
      tester.getRect(find.byKey(const ValueKey(('tab-group-chip', 7))));

  Rect rule(WidgetTester tester) =>
      tester.getRect(find.byKey(const ValueKey(('tab-group-rule', 7))));

  Future<TestGesture> press(WidgetTester tester, Offset at) =>
      tester.startGesture(at, kind: PointerDeviceKind.mouse);

  /// Moves [gesture] by [dx] in small steps, a frame each.
  Future<void> slide(
    WidgetTester tester,
    TestGesture gesture,
    double dx,
  ) async {
    const steps = 8;
    for (var step = 0; step < steps; step++) {
      await gesture.moveBy(Offset(dx / steps, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  Widget grouped({List<(String, int?)>? tabs, bool collapsed = false}) => host(
    _Strip(
      moves: moves,
      tabs:
          tabs ??
          const [('a', null), ('b', null), ('c', 7), ('d', 7), ('e', null)],
      groups: [
        MeridianStripGroup(
          id: 7,
          color: _client.color,
          name: 'Client',
          collapsed: collapsed,
        ),
      ],
    ),
  );

  testWidgets('a click activates; a second click on the active tab names it', (
    tester,
  ) async {
    await tester.pumpWidget(grouped());
    await tester.pumpAndSettle();
    await tester.tap(find.text('b'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('b'));
    await tester.pumpAndSettle();
    // The first click activated it; only a click on the active tab names.
    expect(strip(tester).active, 'b');
    expect(find.byType(EditableText), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('b'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('b'));
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Docs');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(moves, [('renamed', 'b', 'Docs')]);
  });

  testWidgets('a press that barely moves is still a click', (tester) async {
    await tester.pumpWidget(grouped());
    await tester.pumpAndSettle();
    final gesture = await press(tester, tab(tester, 'e').center);
    await gesture.moveBy(const Offset(2, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(strip(tester).active, 'e');
    expect(moves, isEmpty);
  });

  testWidgets('the others make room while a tab is dragged past them', (
    tester,
  ) async {
    await tester.pumpWidget(grouped());
    await tester.pumpAndSettle();
    final a = tab(tester, 'a');
    final b = tab(tester, 'b');
    final gesture = await press(tester, a.center);
    await slide(tester, gesture, b.width + MeridianSpace.space2);
    // Before the drop, b has moved into a's place.
    expect(tab(tester, 'b').left, moreOrLessEquals(a.left));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, [('a', 1, null)]);
    expect(order(tester).take(2), [('b', null), ('a', null)]);
  });

  testWidgets('a quick flick drops where the pointer is let go', (
    tester,
  ) async {
    await tester.pumpWidget(grouped());
    await tester.pumpAndSettle();
    // Down, one move and up without a frame in between.
    await tester.drag(find.text('a'), const Offset(900, 0));
    await tester.pumpAndSettle();
    expect(moves, [('a', 4, null)]);
  });

  testWidgets('a tab passing a group chip joins the group, shown by its rule', (
    tester,
  ) async {
    await tester.pumpWidget(grouped());
    await tester.pumpAndSettle();
    final b = tab(tester, 'b');
    final gesture = await press(tester, b.center);
    await slide(tester, gesture, chip(tester).width + MeridianSpace.space2 + 2);
    // The rule already runs under the dragged tab.
    expect(rule(tester).left, lessThanOrEqualTo(tab(tester, 'b').left));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, [('b', 1, 7)]);
    expect(order(tester), [
      ('a', null),
      ('b', 7),
      ('c', 7),
      ('d', 7),
      ('e', null),
    ]);
  });

  testWidgets('at a group end a short nudge out leaves it', (tester) async {
    await tester.pumpWidget(grouped());
    await tester.pumpAndSettle();
    final d = tab(tester, 'd');

    // A small move keeps it in: nothing changes.
    var gesture = await press(tester, d.center);
    await slide(tester, gesture, MeridianLayout.tabGroupEdgeShift / 3);
    expect(rule(tester).right, greaterThanOrEqualTo(tab(tester, 'd').right));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, isEmpty);

    gesture = await press(tester, d.center);
    await slide(tester, gesture, MeridianLayout.tabGroupEdgeShift + 4);
    // The rule ends before the dragged tab.
    expect(rule(tester).right, lessThan(tab(tester, 'd').center.dx));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, [('d', 3, null)]);
    expect(order(tester)[3], ('d', null));
  });

  testWidgets('a dragged chip carries its whole group', (tester) async {
    await tester.pumpWidget(grouped());
    await tester.pumpAndSettle();
    final start = chip(tester);
    final c = tab(tester, 'c');
    final a = tab(tester, 'a');
    final gesture = await press(tester, start.center);
    await slide(tester, gesture, a.left - start.left - 2);
    // The group's tabs travel with the chip.
    expect(
      tab(tester, 'c').left - chip(tester).left,
      moreOrLessEquals(c.left - start.left),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, [(7, 0)]);
    expect(order(tester), [
      ('c', 7),
      ('d', 7),
      ('a', null),
      ('b', null),
      ('e', null),
    ]);
  });

  testWidgets('Escape cancels a drag', (tester) async {
    await tester.pumpWidget(grouped());
    await tester.pumpAndSettle();
    final a = tab(tester, 'a');
    final gesture = await press(tester, a.center);
    await slide(tester, gesture, a.width * 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, isEmpty);
    expect(tab(tester, 'a').left, moreOrLessEquals(a.left));
  });

  testWidgets('a collapsed group folds into a counted chip a drag passes', (
    tester,
  ) async {
    await tester.pumpWidget(grouped(collapsed: true));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.byKey(const ValueKey(('tab-group-rule', 7))), findsNothing);
    final b = tab(tester, 'b');
    final gesture = await press(tester, b.center);
    await slide(tester, gesture, chip(tester).width + MeridianSpace.space2 + 2);
    await gesture.up();
    await tester.pumpAndSettle();
    // It lands after the folded tabs, outside the group.
    expect(moves, [('b', 3, null)]);
  });

  testWidgets('a new tab grows in and a closed one collapses out', (
    tester,
  ) async {
    await tester.pumpWidget(grouped());
    await tester.pumpAndSettle();
    final e = tab(tester, 'e');
    strip(tester).edit((tabs) => tabs.add(('f', null)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    Rect slot(String id) => tester.getRect(
      find
          .ancestor(
            of: find.byKey(ValueKey(('tab-pill', id))),
            matching: find.byType(ClipRect),
          )
          .first,
    );
    expect(slot('f').width, lessThan(e.width));
    await tester.pumpAndSettle();
    expect(tab(tester, 'f').width, moreOrLessEquals(tab(tester, 'e').width));

    strip(tester).edit((tabs) => tabs.removeWhere((tab) => tab.$1 == 'e'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(slot('e').width, lessThan(e.width));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(('tab-pill', 'e'))), findsNothing);
  });

  testWidgets('a group shows its icon before its name, or alone', (
    tester,
  ) async {
    Widget withIcon(String name) => host(
      _Strip(
        tabs: const [('a', 7)],
        groups: [
          MeridianStripGroup(
            id: 7,
            color: _client.color,
            name: name,
            icon: MeridianIcons.star,
          ),
        ],
      ),
    );
    await tester.pumpWidget(withIcon('Client'));
    await tester.pumpAndSettle();
    final icon = find.byKey(const ValueKey('tab-group-icon'));
    expect(
      tester.getRect(icon).right,
      lessThan(tester.getRect(find.text('Client')).left),
    );
    await tester.pumpWidget(withIcon(''));
    await tester.pumpAndSettle();
    expect(icon, findsOneWidget);
    expect(chip(tester).width, MeridianLayout.tabGroupChipHeight);
  });

  testWidgets('assistive technology moves a tab a place at a time', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(grouped());
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.bySemanticsLabel('b'));
    final action = node.getSemanticsData().customSemanticsActionIds!.firstWhere(
      (id) => CustomSemanticsAction.getAction(id)!.label == 'Move right',
    );
    tester.semantics.performAction(
      find.semantics.byLabel('b'),
      SemanticsAction.customAction,
      args: action,
    );
    await tester.pumpAndSettle();
    // Between two of a group's tabs, it joins the group.
    expect(moves, [('b', 2, 7)]);
    semantics.dispose();
  });

  testWidgets('tabs keep their minimum width and scroll when narrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        _Strip(
          width: 390,
          tabs: [for (final id in 'abcdef'.split('')) (id, null)],
        ),
        density: MeridianDensity.touch,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tab(tester, 'a').width, MeridianLayout.tabPillMinWidth);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      tester.getSize(find.byType(MeridianTabStrip<String, int>)).width,
      lessThanOrEqualTo(390),
    );
  });
}
