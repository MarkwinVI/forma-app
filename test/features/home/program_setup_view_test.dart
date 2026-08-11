import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/services/weight_unit_service.dart';
import 'package:forma_app/features/home/getting_started_checklist.dart';
import 'package:forma_app/features/home/program_setup_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    WeightUnitService.notifier.value = WeightUnit.kg;
  });

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

    // Step 1: schedule — nothing picked, so the CTA holds.
    expect(find.text('Your training schedule'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('Pick one to continue'), findsOneWidget);
    await tester.tap(find.text('4'));
    await tester.pump();
    // The note copy varies with the day count.
    expect(find.textContaining('4 days — More training.'), findsOneWidget);
    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.textContaining('3 days — Recommended.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: equipment — three answers; barbell still warns about the bar.
    expect(find.text('Your equipment'), findsOneWidget);
    expect(find.text('Pick one to continue'), findsOneWidget);
    await tester.tap(find.text('Barbell and dumbbells'));
    await tester.pump();
    expect(find.textContaining('pull-up bar'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3: bodyweight — tap the number, type on the keypad.
    expect(find.text('Your bodyweight'), findsOneWidget);
    expect(find.text('75'), findsOneWidget);
    await tester.tap(find.text('75'));
    await tester.pump();
    await tester.tap(find.text('8'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(find.text('82'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 4: starting strength — unset by default, "+" adds a number.
    expect(find.text('Where are you starting?'), findsOneWidget);
    expect(find.text('Barbell squat'), findsOneWidget);
    expect(find.text('Bar weight × 5 reps'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_rounded).at(1));
    await tester.pump();
    expect(find.text('3'), findsOneWidget); // pull-ups default
    expect(find.text('Build my program'), findsOneWidget);
    await tester.tap(find.text('Build my program'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.daysPerWeek, 3);
    expect(result!.split, TrainingProgramType.fullBody);
    expect(result!.equipment, SetupEquipment.freeWeights);
    expect(result!.hasWeights, isTrue);
    expect(result!.bodyweightKg, 82);
    expect(result!.startingStrength['pushups'], isNull);
    expect(result!.startingStrength['pullups'], 3);
    expect(result!.startingStrength.containsKey('squat'), isTrue);
    expect(result!.startingStrength.containsKey('squat_bw'), isFalse);
    expect(result!.toMap()['has_gym'], isTrue);
    expect(result!.toMap()['equipment'], 'barbell');

    // Summary screen reflects the answers, then returns to the caller.
    expect(find.text('Your program is ready'), findsOneWidget);
    expect(find.text('Your week — Full Body'), findsOneWidget);
    expect(find.text('UP FIRST'), findsOneWidget);
    await tester.tap(find.text('Let’s go'));
    await tester.pumpAndSettle();
    expect(find.text('Open wizard'), findsOneWidget);
  });

  testWidgets('4–6 training days build a push/pull split', (tester) async {
    ProgramSetupResult? result;
    await pumpWizard(tester, onComplete: (value) async => result = value);

    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No equipment'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    // No weights: the squat question is bodyweight reps.
    expect(find.text('Bodyweight squats'), findsOneWidget);
    expect(find.text('Barbell squat'), findsNothing);
    await tester.tap(find.text('Build my program'));
    await tester.pumpAndSettle();

    expect(result!.split, TrainingProgramType.pushPull);
    expect(result!.equipment, SetupEquipment.none);
    expect(result!.hasWeights, isFalse);
    expect(result!.toMap()['has_gym'], isFalse);
    expect(result!.startingStrength.containsKey('squat_bw'), isTrue);
    expect(result!.startingStrength.containsKey('squat'), isFalse);
  });

  testWidgets('picking lbs converts the shown weight and sticks app-wide',
      (tester) async {
    ProgramSetupResult? result;
    await pumpWizard(tester, onComplete: (value) async => result = value);

    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full gym'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 75 kg becomes 165 lbs, and the choice persists for the whole app.
    await tester.tap(find.text('lbs'));
    await tester.pump();
    expect(find.text('165'), findsOneWidget);
    expect(WeightUnitService.unit, WeightUnit.lb);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build my program'));
    await tester.pumpAndSettle();

    // Canonical storage stays in kilograms.
    expect(result!.bodyweightKg, closeTo(74.8, 0.2));
  });

  testWidgets('back button steps backwards and then leaves the wizard',
      (tester) async {
    await pumpWizard(tester, onComplete: (_) async {});

    await tester.tap(find.text('3'));
    await tester.pump();
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

    await tester.tap(find.text('3'));
    await tester.pump();
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
