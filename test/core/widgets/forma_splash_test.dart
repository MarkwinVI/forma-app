import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/widgets/forma_splash.dart';

void main() {
  testWidgets('plays once before completing', (tester) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: FormaSplash(onDone: () => completed = true),
      ),
    );

    expect(find.text('FORMA'), findsOneWidget);
    expect(completed, isFalse);

    await tester.pump(const Duration(milliseconds: 5499));
    expect(completed, isFalse);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    expect(completed, isTrue);
  });
}
