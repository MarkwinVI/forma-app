import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/settings/settings_view.dart';

/// Signing out asks first. Cancel resolves false, Sign out resolves true, and
/// the scrim resolves null — only the explicit yes ends the session.
void main() {
  Future<Future<bool?>> open(WidgetTester tester) async {
    late Future<bool?> result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => result = showSignOutConfirmSheet(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return result;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('shows the question and both ways out', (tester) async {
    await open(tester);
    expect(find.text('Sign out of Forma?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('Cancel resolves false', (tester) async {
    final result = await open(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(await result, isFalse);
  });

  testWidgets('Sign out resolves true', (tester) async {
    final result = await open(tester);
    await tester.tap(find.text('Sign out'));
    await settle(tester);
    expect(await result, isTrue);
  });
}
