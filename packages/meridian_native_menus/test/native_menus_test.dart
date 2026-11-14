import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_native_menus/meridian_native_menus.dart';
import 'package:meridian_ui/meridian_ui.dart';

/// meridian_ui's icons are not assets of this package's tests.
const _icons = MeridianIconSet(extra: {});

Widget _host(Widget child) => MeridianApp(
  theme: MeridianTheme.resolve(
    brand: MeridianBrands.gitlama,
    brightness: Brightness.light,
    icons: _icons,
  ),
  builder: (context, app) =>
      MeridianNativeMenus.scope(child: app ?? const SizedBox.shrink()),
  home: MeridianGround(child: Center(child: child)),
);

void main() {
  tearDown(() {
    MeridianNativeMenus.debugShowOverride = null;
    MeridianNativeMenus.debugSupportedOverride = null;
    debugDefaultTargetPlatformOverride = null;
  });

  group('model', () {
    test('keeps labels, states, danger, submenus, headers and separators', () {
      var picked = 0;
      final nodes = nativeMenuFromMeridian([
        const MeridianMenuDivider(),
        const MeridianMenuHeader('Branch main'),
        MeridianMenuItem(
          label: 'Check out',
          icon: MeridianIcons.gitBranch,
          shortcut: const ['⌘', '⇧', 'O'],
          onSelected: () => picked++,
        ),
        const MeridianMenuItem(label: 'Merge into current'),
        MeridianMenuItem(
          label: 'Sort by',
          children: [
            MeridianMenuItem(label: 'Name', checked: true, onSelected: () {}),
            MeridianMenuItem(label: 'Date', checked: false, onSelected: () {}),
          ],
        ),
        const MeridianMenuCustom(SizedBox()),
        const MeridianMenuDivider(),
        const MeridianMenuDivider(),
        MeridianMenuItem(
          label: 'Delete branch',
          danger: true,
          onSelected: () {},
        ),
        const MeridianMenuDivider(),
      ]);
      expect(nodes.first, isA<NativeMenuAction>());
      final header = nodes.first as NativeMenuAction;
      expect(header.header, isTrue);
      expect(header.enabled, isFalse);
      final checkout = nodes[1] as NativeMenuAction;
      expect(checkout.title, 'Check out');
      expect(checkout.icon, MeridianIcons.gitBranch);
      expect(
        checkout.shortcut,
        const NativeMenuShortcut(key: 'O', shift: true, meta: true),
      );
      checkout.onSelected!();
      expect(picked, 1);
      expect((nodes[2] as NativeMenuAction).enabled, isFalse);
      final submenu = nodes[3] as NativeMenuSubmenu;
      expect(submenu.children.map((n) => (n as NativeMenuAction).checked), [
        true,
        false,
      ]);
      // Custom blocks are left out; separators collapse and never trail.
      expect(nodes[4], isA<NativeMenuSeparator>());
      expect((nodes[5] as NativeMenuAction).danger, isTrue);
      expect(nodes, hasLength(6));
      final ids = <int>{};
      void collect(List<NativeMenuNode> nodes) {
        for (final node in nodes) {
          if (node is NativeMenuAction) expect(ids.add(node.id), isTrue);
          if (node is NativeMenuSubmenu) collect(node.children);
        }
      }

      collect(nodes);
      final name = submenu.children.first as NativeMenuAction;
      expect(findNativeMenuAction(nodes, name.id)?.title, 'Name');
      expect(findNativeMenuAction(nodes, 999), isNull);
    });

    test('parses keycaps into shortcuts', () {
      expect(
        NativeMenuShortcut.fromKeycaps(const ['Ctrl', 'Shift', 'f'])?.hostLabel,
        'Ctrl+Shift+F',
      );
      expect(
        NativeMenuShortcut.fromKeycaps(const ['⌥', '⌘', '↵'])?.hostLabel,
        'Alt+Win+Enter',
      );
      expect(NativeMenuShortcut.fromKeycaps(const ['F5'])?.key, 'F5');
      expect(NativeMenuShortcut.fromKeycaps(const ['⌘', 'K', 'S']), isNull);
      expect(NativeMenuShortcut.fromKeycaps(const ['⌘']), isNull);
      expect(NativeMenuShortcut.fromKeycaps(null), isNull);
      final activator = NativeMenuShortcut.fromKeycaps(const [
        'Ctrl',
        'R',
      ])!.activator!;
      expect(activator.trigger, LogicalKeyboardKey.keyR);
      expect(activator.control, isTrue);
      expect(
        NativeMenuShortcut.fromKeycaps(const ['F12'])!.activator!.trigger,
        LogicalKeyboardKey.f12,
      );
    });

    test('encodes the host protocol', () {
      final nodes = nativeMenuFromMeridian([
        const MeridianMenuHeader('Commit'),
        MeridianMenuItem(
          label: 'Copy & paste',
          icon: MeridianIcons.copy,
          shortcut: const ['Ctrl', 'C'],
          checked: true,
          onSelected: () {},
        ),
        const MeridianMenuDivider(),
        MeridianMenuItem(
          label: 'More',
          children: [
            MeridianMenuItem(label: 'Drop', danger: true, onSelected: () {}),
          ],
        ),
      ]);
      final encoded = encodeHostMenu(
        nodes,
        icons: {
          MeridianIcons.copy: {'width': 1, 'height': 1},
        },
      );
      expect(encoded[0], {
        'id': 1,
        'title': 'Commit',
        'header': true,
        'enabled': false,
        'checked': false,
      });
      expect(encoded[1], {
        'id': 2,
        'title': 'Copy & paste',
        'icon': {'width': 1, 'height': 1},
        'shortcut': 'Ctrl+C',
        'enabled': true,
        'checked': true,
      });
      expect(encoded[2], {'separator': true});
      expect(encoded[3]['items'], [
        {
          'id': 3,
          'title': 'Drop',
          'danger': true,
          'enabled': true,
          'checked': false,
        },
      ]);
      expect(nativeMenuIcons(nodes), {MeridianIcons.copy});
    });
  });

  group('presenter', () {
    testWidgets('a menu anchor shows natively and runs the choice after the '
        'menu closed', (tester) async {
      MeridianNativeMenus.debugSupportedOverride = true;
      Offset? shownAt;
      var picked = 0;
      MeridianNativeMenus.debugShowOverride = (context, nodes, position) async {
        shownAt = position;
        expect(picked, 0);
        return (nodes.last as NativeMenuAction).id;
      };
      await tester.pumpWidget(
        _host(
          MeridianMenuAnchor(
            entries: [
              MeridianMenuItem(label: 'Rename', onSelected: () {}),
              MeridianMenuItem(label: 'Delete', onSelected: () => picked++),
            ],
            builder: (context, open) => MeridianButton(
              key: const ValueKey('trigger'),
              label: 'Actions',
              onPressed: open,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('trigger')));
      await tester.pumpAndSettle();
      expect(picked, 1);
      expect(
        shownAt,
        tester.getBottomLeft(find.byKey(const ValueKey('trigger'))),
      );
      // No Flutter menu was drawn.
      expect(find.byType(MeridianMenuSurface), findsNothing);
    });

    testWidgets('dismissing runs nothing; disabled and header ids are '
        'ignored', (tester) async {
      MeridianNativeMenus.debugSupportedOverride = true;
      var answer = 0;
      MeridianNativeMenus.debugShowOverride =
          (context, nodes, position) async => answer == 0 ? null : answer;
      var picked = 0;
      late BuildContext context;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final entries = [
        const MeridianMenuHeader('Header'),
        const MeridianMenuItem(label: 'Disabled'),
        MeridianMenuItem(label: 'Run', onSelected: () => picked++),
      ];
      expect(
        await MeridianNativeMenus.show(context, entries, Offset.zero),
        isFalse,
      );
      answer = 1;
      expect(
        await MeridianNativeMenus.show(context, entries, Offset.zero),
        isFalse,
      );
      answer = 2;
      expect(
        await MeridianNativeMenus.show(context, entries, Offset.zero),
        isFalse,
      );
      answer = 3;
      expect(
        await MeridianNativeMenus.show(context, entries, Offset.zero),
        isTrue,
      );
      expect(picked, 1);
    });

    testWidgets('macOS and Windows send the menu to the host plugin', (
      tester,
    ) async {
      for (final platform in const [
        TargetPlatform.macOS,
        TargetPlatform.windows,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        MethodCall? sent;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          MeridianNativeMenus.channel,
          (call) async {
            sent = call;
            return 1;
          },
        );
        var picked = 0;
        late BuildContext context;
        await tester.pumpWidget(
          _host(
            Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        );
        final chosen = await tester.runAsync(
          () => MeridianNativeMenus.show(context, [
            MeridianMenuItem(label: 'Open', onSelected: () => picked++),
          ], const Offset(10, 20)),
        );
        expect(chosen, isTrue);
        expect(picked, 1);
        expect(sent?.method, 'show');
        final args = sent!.arguments as Map<Object?, Object?>;
        expect(args['x'], 10);
        expect(args['y'], 20);
        expect((args['items']! as List<Object?>).single, {
          'id': 1,
          'title': 'Open',
          'enabled': true,
          'checked': false,
        });
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          MeridianNativeMenus.channel,
          (call) async => throw PlatformException(code: 'native_menu_failed'),
        );
        String? code;
        await tester.runAsync(() async {
          try {
            await MeridianNativeMenus.show(context, [
              MeridianMenuItem(label: 'Open', onSelected: () {}),
            ], Offset.zero);
          } on MeridianNativeMenuException catch (error) {
            code = error.code;
          }
        });
        expect(code, 'native_menu_host_failed');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          MeridianNativeMenus.channel,
          null,
        );
      }
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('unsupported platforms keep Meridian menus', (tester) async {
      MeridianNativeMenus.debugSupportedOverride = false;
      await tester.pumpWidget(_host(const SizedBox(key: ValueKey('child'))));
      expect(
        MeridianMenuPresenter.maybeOf(
          tester.element(find.byKey(const ValueKey('child'))),
        ),
        isNull,
      );
      final context = tester.element(find.byKey(const ValueKey('child')));
      await expectLater(
        MeridianNativeMenus.show(context, [
          MeridianMenuItem(label: 'Open', onSelected: () {}),
        ], Offset.zero),
        throwsA(isA<MeridianNativeMenuException>()),
      );
    });
  });

  group('context menu region', () {
    testWidgets('a secondary click shows the menu at the pointer', (
      tester,
    ) async {
      MeridianNativeMenus.debugSupportedOverride = true;
      Offset? shownAt;
      var picked = 0;
      MeridianNativeMenus.debugShowOverride = (context, nodes, position) async {
        shownAt = position;
        return 1;
      };
      await tester.pumpWidget(
        _host(
          MeridianNativeContextMenuRegion(
            entries: (position) => [
              MeridianMenuItem(label: 'Copy', onSelected: () => picked++),
            ],
            child: const SizedBox(width: 100, height: 40),
          ),
        ),
      );
      final center = tester.getCenter(
        find.byType(MeridianNativeContextMenuRegion),
      );
      await tester.tapAt(center, buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      expect(shownAt, center);
      expect(picked, 1);
    });

    testWidgets('Shift+F10 and the menu key open it; dismissal restores '
        'focus', (tester) async {
      MeridianNativeMenus.debugSupportedOverride = true;
      var shown = 0;
      MeridianNativeMenus.debugShowOverride = (context, nodes, position) async {
        shown++;
        // The menu takes focus away while it is open.
        FocusManager.instance.primaryFocus?.unfocus();
        return null;
      };
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _host(
          MeridianNativeContextMenuRegion(
            entries: (position) => [
              MeridianMenuItem(label: 'Copy', onSelected: () {}),
            ],
            child: Focus(
              focusNode: focus,
              autofocus: true,
              child: const SizedBox(width: 100, height: 40),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(shown, 1);
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pumpAndSettle();
      expect(shown, 2);
    });

    testWidgets('disabled regions ignore requests', (tester) async {
      MeridianNativeMenus.debugSupportedOverride = true;
      var shown = 0;
      MeridianNativeMenus.debugShowOverride = (context, nodes, position) async {
        shown++;
        return null;
      };
      await tester.pumpWidget(
        _host(
          MeridianNativeContextMenuRegion(
            enabled: false,
            entries: (position) => [
              MeridianMenuItem(label: 'Copy', onSelected: () {}),
            ],
            child: const SizedBox(width: 100, height: 40),
          ),
        ),
      );
      await tester.tapAt(
        tester.getCenter(find.byType(MeridianNativeContextMenuRegion)),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      expect(shown, 0);
    });
  });

  testWidgets('a text field uses the native text menu', (tester) async {
    MeridianNativeMenus.debugSupportedOverride = true;
    List<String>? titles;
    MeridianNativeMenus.debugShowOverride = (context, nodes, position) async {
      titles = [for (final node in nodes) (node as NativeMenuAction).title];
      return null;
    };
    final controller = TextEditingController(text: 'hello');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        SizedBox(width: 240, child: MeridianTextField(controller: controller)),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    final state = tester.state<EditableTextState>(find.byType(EditableText));
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();
    state.showToolbar();
    await tester.pumpAndSettle();
    expect(titles, isNotNull);
    expect(titles, contains('Copy'));
  });
}
