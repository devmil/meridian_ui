import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

Future<BuildContext> _pumpHost(
  WidgetTester tester, {
  MeridianDensity? density,
}) async {
  late BuildContext captured;
  await tester.pumpWidget(
    host(
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
      density: density,
    ),
  );
  return captured;
}

/// A form dialog: one field and Cancel / Rename.
class _Form extends StatefulWidget {
  const _Form({
    required this.onSubmit,
    this.enabled = true,
    this.fieldSubmits = true,
    this.multiline = false,
    this.ownSubmit,
  });

  final VoidCallback onSubmit;
  final bool enabled;
  final bool fieldSubmits;
  final bool multiline;
  final ValueChanged<String>? ownSubmit;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _controller = TextEditingController(text: 'main');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MeridianDialog(
    title: 'Rename branch',
    width: MeridianLayout.dialogFormWidth,
    onSubmit: widget.enabled ? widget.onSubmit : null,
    submitDisabled: !widget.enabled,
    content: MeridianTextField(
      label: 'Name',
      controller: _controller,
      autofocus: true,
      submitsDialog: widget.fieldSubmits,
      maxLines: widget.multiline ? 4 : 1,
      onSubmitted: widget.ownSubmit,
    ),
    actions: [
      MeridianButton(
        label: 'Cancel',
        variant: MeridianButtonVariant.quiet,
        onPressed: () => Navigator.pop(context),
      ),
      MeridianButton(
        label: 'Rename',
        variant: MeridianButtonVariant.primary,
        disabledReason: widget.enabled ? null : 'Enter a new name',
        onPressed: widget.enabled ? widget.onSubmit : null,
      ),
    ],
  );
}

void main() {
  group('named dialog widths', () {
    test('keep the confirm width and add form and workflow widths', () {
      expect(MeridianLayout.dialogConfirmWidth, MeridianLayout.dialogWidth);
      expect(MeridianLayout.dialogConfirmWidth, 460);
      expect(MeridianLayout.dialogFormWidth, 560);
      expect(MeridianLayout.dialogWorkflowWidth, 760);
    });
  });

  group('showMeridianConfirm', () {
    testWidgets('carries the verb, shows content and takes a width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final context = await _pumpHost(tester);
      final result = showMeridianConfirm(
        context,
        title: 'Delete branch feature/login',
        description: 'The branch is not merged.',
        content: const Text('3 commits are only on this branch.'),
        confirmLabel: 'Delete branch',
        destructive: true,
        width: MeridianLayout.dialogFormWidth,
      );
      await tester.pumpAndSettle();
      expect(find.text('The branch is not merged.'), findsOneWidget);
      expect(find.text('3 commits are only on this branch.'), findsOneWidget);
      final card = tester.getSize(
        find
            .descendant(
              of: find.byType(MeridianDialogSurface),
              matching: find.byType(ClipRRect),
            )
            .first,
      );
      expect(card.width, 560);
      final verb = tester.widget<MeridianButton>(
        find.widgetWithText(MeridianButton, 'Delete branch'),
      );
      expect(verb.variant, MeridianButtonVariant.danger);
      // Destructive: Cancel has focus, so Enter cancels.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });

    testWidgets('barrierDismissible: false keeps it open on a scrim click', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      final result = showMeridianConfirm(
        context,
        title: 'Discard 3 files',
        confirmLabel: 'Discard',
        barrierDismissible: false,
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.text('Discard 3 files'), findsOneWidget);
      // Not destructive: the verb has focus and Enter confirms.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });

    testWidgets('the existing signature still works and the scrim cancels', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      final result = showMeridianConfirm(
        context,
        title: 'Delete Linear algebra',
        confirmLabel: 'Delete notebook',
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });

    testWidgets('a narrow touch screen stacks the verb on top', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final context = await _pumpHost(tester, density: MeridianDensity.touch);
      final result = showMeridianConfirm(
        context,
        title: 'Delete branch',
        content: const Text('feature/a-very-long-branch-name-that-wraps'),
        confirmLabel: 'Delete branch',
        destructive: true,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final verb = tester.getTopLeft(
        find.widgetWithText(MeridianButton, 'Delete branch'),
      );
      final cancel = tester.getTopLeft(
        find.widgetWithText(MeridianButton, 'Cancel'),
      );
      expect(verb.dy, lessThan(cancel.dy));
      await tester.tap(find.text('Delete branch').last);
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });
  });

  group('onClose', () {
    testWidgets('puts a close button at the end of the title row', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      unawaited(
        showMeridianDialog<void>(
          context: context,
          builder: (context) => MeridianDialog(
            title: 'Hosts',
            onClose: () => Navigator.pop(context),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final close = find.bySemanticsLabel('Close');
      expect(close, findsOneWidget);
      expect(
        tester.getCenter(close).dx,
        greaterThan(tester.getCenter(find.text('Hosts')).dx),
      );
      expect(
        (tester.getCenter(close).dy - tester.getCenter(find.text('Hosts')).dy)
            .abs(),
        lessThan(MeridianSpace.space4),
      );
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.text('Hosts'), findsNothing);
    });

    testWidgets('is absent by default', (tester) async {
      await tester.pumpWidget(host(const MeridianDialog(title: 'Hosts')));
      expect(find.byType(MeridianIconButton), findsNothing);
    });
  });

  group('Enter in a dialog text field', () {
    testWidgets('submits the dialog by default', (tester) async {
      final context = await _pumpHost(tester);
      var submitted = 0;
      showMeridianDialog<void>(
        context: context,
        builder: (_) => _Form(onSubmit: () => submitted++),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'release');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(submitted, 1);
      // Focus stays in the field.
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<MeridianTextField>(),
        isNotNull,
      );
    });

    testWidgets('a disabled primary action shakes instead', (tester) async {
      final context = await _pumpHost(tester);
      var submitted = 0;
      showMeridianDialog<void>(
        context: context,
        builder: (_) => _Form(enabled: false, onSubmit: () => submitted++),
      );
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(submitted, 0);
      final surface = tester.widget<MeridianDialogSurface>(
        find.byType(MeridianDialogSurface),
      );
      expect(surface.rejectCount, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('a field can opt out', (tester) async {
      final context = await _pumpHost(tester);
      var submitted = 0;
      showMeridianDialog<void>(
        context: context,
        builder: (_) => _Form(fieldSubmits: false, onSubmit: () => submitted++),
      );
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(submitted, 0);
    });

    testWidgets('a field with its own onSubmitted keeps it', (tester) async {
      final context = await _pumpHost(tester);
      var submitted = 0;
      String? own;
      showMeridianDialog<void>(
        context: context,
        builder: (_) =>
            _Form(onSubmit: () => submitted++, ownSubmit: (v) => own = v),
      );
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(submitted, 0);
      expect(own, 'main');
    });

    testWidgets('a multi-line field keeps Enter for new lines', (tester) async {
      final context = await _pumpHost(tester);
      var submitted = 0;
      showMeridianDialog<void>(
        context: context,
        builder: (_) => _Form(multiline: true, onSubmit: () => submitted++),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(submitted, 0);
    });

    testWidgets('a field outside a dialog is unaffected', (tester) async {
      await tester.pumpWidget(
        host(const MeridianTextField(label: 'Name', autofocus: true)),
      );
      await tester.pump();
      expect(
        MeridianDialogSubmitScope.maybeOf(
          tester.element(find.byType(TextField)),
        ),
        isNull,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a custom dialog surface can install the scope', (
      tester,
    ) async {
      var submitted = 0;
      await tester.pumpWidget(
        host(
          MeridianDialogSurface(
            child: MeridianDialogSubmitScope(
              onSubmit: () => submitted++,
              child: const Padding(
                padding: EdgeInsets.all(MeridianSpace.space5),
                child: MeridianTextField(label: 'Command', autofocus: true),
              ),
            ),
          ),
          density: MeridianDensity.touch,
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(TextField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(submitted, 1);
    });
  });
}
