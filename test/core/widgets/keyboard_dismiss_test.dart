import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/widgets/keyboard_dismiss.dart';

void main() {
  const field = Key('field');
  const below = Key('below');

  Future<void> pumpKeyboardUp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KeyboardDismissOnSwipeDown(child: child!),
        home: const Scaffold(
          body: Column(
            children: [
              TextField(key: field, autofocus: true),
              Expanded(child: SizedBox.expand(key: below)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    // The keyboard is up: the field has focus and the view says so.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
  }

  bool fieldFocused(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

  testWidgets('a pull down outside the field puts the keyboard away',
      (tester) async {
    await pumpKeyboardUp(tester);
    expect(fieldFocused(tester), isTrue);

    await tester.drag(find.byKey(below), const Offset(0, 80));
    await tester.pump();

    expect(fieldFocused(tester), isFalse);
  });

  testWidgets('a drag that starts in the field, or goes up, is left alone',
      (tester) async {
    await pumpKeyboardUp(tester);

    await tester.drag(find.byKey(field), const Offset(0, 80));
    await tester.pump();
    expect(fieldFocused(tester), isTrue, reason: 'the field\'s own drag');

    await tester.drag(find.byKey(below), const Offset(0, -80));
    await tester.pump();
    expect(fieldFocused(tester), isTrue, reason: 'only a pull down counts');
  });
}
