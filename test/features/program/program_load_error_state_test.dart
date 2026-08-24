import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/program/program_view.dart';

/// A failed program fetch must read as a failure — never as "you have no
/// program", which invites building over one that may be fine.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
  });

  testWidgets('names the problem, offers retry, and never offers setup',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgramLoadErrorState(onRetry: () async => retries++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load your program"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Create my program'), findsNothing);
    expect(find.text('Build your training program'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(retries, 1);
  });
}
