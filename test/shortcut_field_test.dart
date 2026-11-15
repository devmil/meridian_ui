import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

class Owner extends ChangeNotifier {
  bool recording = false,
      preparing = false,
      enabled = true,
      finishOnStroke = true;
  int requests = 0, cancellations = 0, clears = 0;
  List<String> keys = ['Ctrl', 'H'];
  final strokes = <MeridianShortcutStroke>[];
  void request() {
    requests++;
    recording = true;
    notifyListeners();
  }

  void cancel() {
    cancellations++;
    recording = false;
    notifyListeners();
  }

  void clear() {
    clears++;
    keys = [];
    recording = false;
    notifyListeners();
  }

  void accept(MeridianShortcutStroke value) {
    strokes.add(value);
    if (finishOnStroke) recording = false;
    notifyListeners();
  }

  Widget field({bool autofocus = false, Widget? conflict}) => ListenableBuilder(
    listenable: this,
    builder: (context, _) => MeridianShortcutField(
      label: 'Bereich aufnehmen',
      emptyLabel: 'Kein Tastenkürzel',
      recordingLabel: 'Drücke ein Tastenkürzel',
      preparingLabel: 'Aufnahme wird vorbereitet',
      clearLabel: 'Tastenkürzel löschen',
      keys: keys,
      enabled: enabled,
      preparing: preparing,
      recording: recording,
      onRecordRequested: request,
      onCancelRecording: cancel,
      onRecorded: accept,
      onClear: clear,
      autofocus: autofocus,
      conflict: conflict,
    ),
  );
}

Finder trigger() => find
    .descendant(
      of: find.byType(MeridianShortcutField),
      matching: find.byType(MeridianInteraction),
    )
    .first;
Future<void> arm(WidgetTester tester) async {
  await tester.tap(trigger());
  await tester.pumpAndSettle();
}

void main() {
  late Owner owner;
  setUp(() {
    owner = Owner();
  });
  tearDown(() => owner.dispose());
  testWidgets(
    'records physical identity and all modifiers without retaining characters',
    (tester) async {
      await tester.pumpWidget(host(SizedBox(width: 260, child: owner.field())));
      await arm(tester);
      for (final key in [
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.altLeft,
        LogicalKeyboardKey.metaLeft,
      ]) {
        await tester.sendKeyDownEvent(key);
      }
      expect(owner.strokes, isEmpty);
      await tester.sendKeyEvent(
        LogicalKeyboardKey.keyY,
        physicalKey: PhysicalKeyboardKey.keyZ,
      );
      await tester.pumpAndSettle();
      final stroke = owner.strokes.single;
      expect(stroke.physicalKey, PhysicalKeyboardKey.keyZ);
      expect(stroke.logicalKey, LogicalKeyboardKey.keyY);
      expect([
        stroke.control,
        stroke.shift,
        stroke.alt,
        stroke.meta,
      ], everyElement(true));
      for (final key in [
        LogicalKeyboardKey.metaLeft,
        LogicalKeyboardKey.altLeft,
        LogicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.controlLeft,
      ]) {
        await tester.sendKeyUpEvent(key);
      }
      expect(owner.requests, 1);
      expect(owner.cancellations, 0);
      expect(
        find.text('H'),
        findsOneWidget,
      ); // Controlled value remains authoritative.
    },
  );
  testWidgets('Enter arms, then Enter and Space are recordable strokes', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(SizedBox(width: 260, child: owner.field(autofocus: true))),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(owner.requests, 1);
    expect(owner.strokes, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(owner.strokes.single.physicalKey, PhysicalKeyboardKey.enter);
    await arm(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(owner.strokes.last.physicalKey, PhysicalKeyboardKey.space);
    expect(owner.cancellations, 0);
  });
  testWidgets('modifiers, repeats, synthesized events and key-up do not emit', (
    tester,
  ) async {
    owner.finishOnStroke = false;
    await tester.pumpWidget(host(SizedBox(width: 260, child: owner.field())));
    await arm(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(owner.strokes, isEmpty);
    final focus = FocusManager.instance.primaryFocus!;
    for (final pair in const [
      (PhysicalKeyboardKey.altRight, LogicalKeyboardKey.altGraph),
      (PhysicalKeyboardKey.fn, LogicalKeyboardKey.fn),
    ]) {
      focus.onKeyEvent!(
        focus,
        KeyDownEvent(
          physicalKey: pair.$1,
          logicalKey: pair.$2,
          timeStamp: Duration.zero,
        ),
      );
    }
    expect(owner.strokes, isEmpty);
    focus.onKeyEvent!(
      focus,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        timeStamp: Duration.zero,
        synthesized: true,
      ),
    );
    expect(owner.strokes, isEmpty);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    expect(owner.strokes, hasLength(1));
  });
  testWidgets('Escape cancels once and preserves the supplied chord', (
    tester,
  ) async {
    await tester.pumpWidget(host(SizedBox(width: 260, child: owner.field())));
    await arm(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(owner.recording, false);
    expect(owner.cancellations, 1);
    expect(owner.strokes, isEmpty);
    expect(owner.keys, ['Ctrl', 'H']);
  });
  for (final shift in [false, true]) {
    testWidgets('Tab cancels and leaves normal traversal, shift=$shift', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MeridianButton(label: 'Before', onPressed: () {}),
                owner.field(),
                MeridianButton(label: 'After', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await arm(tester);
      final capturing = FocusManager.instance.primaryFocus;
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(owner.cancellations, 1);
      expect(owner.strokes, isEmpty);
      expect(FocusManager.instance.primaryFocus, isNot(same(capturing)));
      expect(owner.recording, false);
      expect(tester.takeException(), null);
    });
  }
  testWidgets('moving focus cancels; disabling cancels only once', (
    tester,
  ) async {
    final other = FocusNode();
    try {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                owner.field(),
                MeridianButton(
                  label: 'Other',
                  onPressed: () {},
                  focusNode: other,
                ),
              ],
            ),
          ),
        ),
      );
      await arm(tester);
      other.requestFocus();
      await tester.pumpAndSettle();
      expect(owner.cancellations, 1);
      await arm(tester);
      owner.enabled = false;
      owner.notifyListeners();
      await tester.pumpAndSettle();
      expect(owner.cancellations, 2);
      expect(owner.recording, false);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      expect(owner.strokes, isEmpty);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      other.dispose();
    }
  });
  testWidgets('preparing and disabled fields never start or clear', (
    tester,
  ) async {
    for (final preparing in [false, true]) {
      owner.enabled = preparing;
      owner.preparing = preparing;
      await tester.pumpWidget(host(SizedBox(width: 260, child: owner.field())));
      await tester.pumpAndSettle();
      await tester.tap(trigger());
      await tester.tap(find.byType(MeridianIconButton));
      expect(owner.requests, 0);
      expect(owner.clears, 0);
      expect(owner.strokes, isEmpty);
    }
  });
  testWidgets('clear is a separate named semantic and keyboard action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(host(SizedBox(width: 260, child: owner.field())));
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Tastenkürzel löschen'))
            .label,
        'Tastenkürzel löschen',
      );
      // Traverse from the recorder to its separately reachable clear action.
      await tester.tap(trigger());
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(owner.clears, 1);
      expect(owner.keys, isEmpty);
      expect(find.text('Kein Tastenkürzel'), findsOneWidget);
      expect(find.byType(MeridianIconButton), findsNothing);
    } finally {
      semantics.dispose();
    }
  });
  for (final density in [MeridianDensity.regular, MeridianDensity.touch]) {
    testWidgets('narrow 200% chord, empty, preparing and conflict $density', (
      tester,
    ) async {
      owner.keys = ['Ctrl', 'Shift', 'Alt', 'Meta', 'Print Screen'];
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            child: SizedBox(
              width: 170,
              child: owner.field(
                conflict: const Text(
                  'Dieses Tastenkürzel wird bereits für den Verlauf verwendet.',
                ),
              ),
            ),
          ),
          density: density,
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
      expect(find.text('Print Screen'), findsOneWidget);
      expect(
        find.text(
          'Dieses Tastenkürzel wird bereits für den Verlauf verwendet.',
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(trigger()).height,
        greaterThanOrEqualTo(density.controlExtent),
      );
      owner.keys = [];
      owner.notifyListeners();
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
      owner.preparing = true;
      owner.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Aufnahme wird vorbereitet'), findsOneWidget);
      expect(tester.takeException(), null);
    });
  }
}
