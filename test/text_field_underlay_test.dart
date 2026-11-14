import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

const _underlayKey = Key('underlay');
const _fieldKey = Key('field');

Future<void> _pump(WidgetTester tester, {Widget? underlay}) =>
    tester.pumpWidget(
      host(
        SizedBox(
          width: 320,
          height: 200,
          child: MeridianTextField(
            fieldKey: _fieldKey,
            controller: TextEditingController(text: 'one\ntwo\nthree'),
            expands: true,
            underlay: underlay,
          ),
        ),
      ),
    );

void main() {
  testWidgets('the underlay fills the text area under the editable text', (
    tester,
  ) async {
    await _pump(
      tester,
      underlay: const ColoredBox(key: _underlayKey, color: Color(0xFFFF0000)),
    );
    final underlay = tester.getRect(find.byKey(_underlayKey));
    final field = tester.getRect(find.byKey(_fieldKey));
    expect(underlay, field);
    // Painted first, so the text, its selection and the caret are on top.
    final stack = find
        .ancestor(of: find.byKey(_fieldKey), matching: find.byType(Stack))
        .first;
    final children = tester
        .renderObject<RenderStack>(stack)
        .getChildrenAsList();
    final editable = tester.renderObject(find.byKey(_fieldKey));
    final underlayBox = tester.renderObject(find.byKey(_underlayKey));
    int indexOf(RenderObject target) => children.indexWhere((child) {
      var found = false;
      void visit(RenderObject node) {
        if (identical(node, target)) found = true;
        if (!found) node.visitChildren(visit);
      }

      visit(child);
      return found;
    });
    expect(indexOf(underlayBox), lessThan(indexOf(editable)));
  });

  testWidgets('the underlay takes no taps and is not announced', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var tapped = false;
    await _pump(
      tester,
      underlay: GestureDetector(
        onTap: () => tapped = true,
        child: Semantics(
          label: 'underlay mark',
          child: const ColoredBox(key: _underlayKey, color: Color(0xFFFF0000)),
        ),
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.pump();
    expect(tapped, isFalse);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    expect(find.bySemanticsLabel('underlay mark'), findsNothing);
    handle.dispose();
  });

  testWidgets('without an underlay the field is unchanged', (tester) async {
    await _pump(tester);
    expect(find.byKey(_underlayKey), findsNothing);
    expect(find.byKey(_fieldKey), findsOneWidget);
  });
}
