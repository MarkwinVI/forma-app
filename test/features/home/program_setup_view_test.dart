import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/getting_started_checklist.dart';
import 'package:forma_app/features/home/program_setup_view.dart';

void main() {
  Future<void> pumpWizard(
    WidgetTester tester, {
    required Future<void> Function(ProgramSetupResult) onComplete,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProgramSetupView(onComplete: onComplete),
                    ),
                  );
                },
                child: const Text('Open wizard'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open wizard'));
    await tester.pumpAndSettle();
  }

  testWidgets('walks through all four steps and reports the answers',
      (tester) async {
    ProgramSetupResult? result;
    await pumpWizard(
      tester,
      onComplete: (value) async => result = value,
    );

    // Step 1: schedule.
    expect(find.text('Your training schedule'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: split — 3 days recommends full body.
    expect(find.text('Pick your split'), findsOneWidget);
    final recommendedRow = find.ancestor(
      of: find.text('Recommended'),
      matching: find.byType(Container),
    );
    expect(recommendedRow, findsWidgets);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Full body'),
          matching: find.byType(Row),
        ),
        matching: find.text('Recommended'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Upper / Lower'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3: equipment — no gym shows the pull-up bar note.
    expect(find.text('Where will you train?'), findsOneWidget);
    await tester.tap(find.text('No gym'));
    await tester.pump();
    expect(find.textContaining('pull-up bar'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 4: starting strength — mark push-ups as unknown.
    expect(find.text('Where are you starting?'), findsOneWidget);
    await tester.tap(find.text('I don’t know').first);
    await tester.pump();
    expect(find.text('Forma will test this in session one'), findsOneWidget);
    expect(find.text('Build my program'), findsOneWidget);
    await tester.tap(find.text('Build my program'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.daysPerWeek, 3);
    expect(result!.split, TrainingProgramType.upperLower);
    expect(result!.hasGym, isFalse);
    expect(result!.bodyweightKg, 75);
    expect(result!.startingStrength.containsKey('bodyweight'), isFalse);
    expect(result!.startingStrength['pushups'], isNull);
    expect(result!.startingStrength['pullups'], 3);

    // Summary screen reflects the answers, then returns to the caller.
    expect(find.text('Your program is ready'), findsOneWidget);
    expect(find.text('Your week — Upper / Lower'), findsOneWidget);
    expect(find.text('Upper A'), findsOneWidget);
    expect(find.text('Lower A'), findsOneWidget);
    expect(find.text('UP FIRST'), findsOneWidget);
    await tester.tap(find.text('Let’s go'));
    await tester.pumpAndSettle();
    expect(find.text('Open wizard'), findsOneWidget);
  });

  testWidgets('back button steps backwards and then leaves the wizard',
      (tester) async {
    await pumpWizard(tester, onComplete: (_) async {});

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('1 / 4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Open wizard'), findsOneWidget);
  });

  testWidgets('a back gesture steps backwards rather than leaving the wizard',
      (tester) async {
    await pumpWizard(tester, onComplete: (_) async {});

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);

    // What the iOS edge swipe and the Android back button both call.
    Future<void> systemBack() async {
      await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
      await tester.pumpAndSettle();
    }

    await systemBack();
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('Open wizard'), findsNothing);

    // Only once there is no step behind does it leave.
    await systemBack();
    expect(find.text('Open wizard'), findsOneWidget);
  });

  testWidgets('getting started checklist reflects program completion',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GettingStartedChecklist(programDone: false),
        ),
      ),
    );
    expect(find.text('0 / 2'), findsOneWidget);
    expect(find.text('Set up your training program'), findsOneWidget);
    expect(find.text('Complete your first workout'), findsOneWidget);
    expect(find.text('Reach your first skill level-up'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GettingStartedChecklist(programDone: true),
        ),
      ),
    );
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
