import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/widgets/no_program_state.dart';
import 'package:forma_app/features/home/home_empty_state.dart';

/// The three tabs tell one story before a program exists, and every one of
/// them offers the same way out.
void main() {
  testWidgets('the Train empty state says what will be here, with the CTA',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeEmptyState(onGoToProgram: () => tapped++),
        ),
      ),
    );

    expect(find.text('Your workouts will appear here'), findsOneWidget);
    expect(find.text("TODAY'S SESSION"), findsOneWidget);
    expect(find.text('AFTER SETUP'), findsOneWidget);
    // A week with no state on any day, and four placeholder exercises.
    expect(find.text('Exercise'), findsNWidgets(4));

    await tester.tap(find.text('Create my program'));
    expect(tapped, 1);
  });

  testWidgets('the shared shell centres its content and always offers the CTA',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoProgramState(
            title: 'Build your training program',
            sub: 'Tell us your goals.',
            onCreateProgram: () {},
          ),
        ),
      ),
    );

    expect(find.text('Build your training program'), findsOneWidget);
    expect(find.text('Create my program'), findsOneWidget);
  });
}
