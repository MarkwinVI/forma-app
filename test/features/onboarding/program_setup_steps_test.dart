import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/widgets/polished.dart';
import 'package:forma_app/core/widgets/weight_entry.dart';
import 'package:forma_app/data/models/equipment_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/services/weight_unit_service.dart';
import 'package:forma_app/features/onboarding/onboarding_view.dart';
import 'package:forma_app/features/onboarding/program_setup_steps.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    WeightUnitService.notifier.value = WeightUnit.kg;
  });

  /// The bodyweight step opens with its caret blinking, so nothing on it
  /// ever settles — a fixed pump stands in for pumpAndSettle there.
  Future<void> pumpStep(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 400));

  /// An account with its onboarding answers already on file: the flow is
  /// the program questions alone.
  Future<void> pumpQuestions(
    WidgetTester tester, {
    required Future<void> Function(ProgramSetupResult) onComplete,
    VoidCallback? onFinished,
  }) async {
    // Phone-sized, so the bodyweight keypad sits above the fold.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingView(
          userId: 'user',
          askProfile: false,
          onSave: (profile, program) async {
            expect(profile, isNull);
            await onComplete(program!);
          },
          onFinished: onFinished ?? () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder backButton() => find.byIcon(Icons.arrow_back_ios_new_rounded);

  WeightValueDisplay bodyweightField(WidgetTester tester) =>
      tester.widget<WeightValueDisplay>(find.byType(WeightValueDisplay));

  /// The flow's one button: greyed out and inert while a step still waits
  /// on an answer.
  bool continueEnabled(WidgetTester tester) =>
      tester.widget<PillButton>(find.byType(PillButton)).onTap != null;

  testWidgets('walks through all four steps and reports the answers',
      (tester) async {
    ProgramSetupResult? result;
    var finished = 0;
    await pumpQuestions(
      tester,
      onComplete: (value) async => result = value,
      onFinished: () => finished++,
    );

    // Step 1: schedule — nothing picked, so the CTA holds.
    expect(find.text('Your training schedule'), findsOneWidget);
    expect(find.text('YOUR PROGRAM'), findsOneWidget);
    expect(find.text('Pick one to continue'), findsOneWidget);
    expect(continueEnabled(tester), isFalse);
    await tester.tap(find.text('4'));
    await tester.pump();
    // The note copy varies with the day count.
    expect(find.textContaining('4 days — More training.'), findsOneWidget);
    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.textContaining('3 days — Recommended.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: equipment — "Some equipment" opens the tile sheet; Done writes
    // the ticks back onto the card, and a list without a bar warns about it.
    expect(find.text('Your equipment'), findsOneWidget);
    expect(find.text('Pick one to continue'), findsOneWidget);
    expect(continueEnabled(tester), isFalse);
    // Three bare names: no explaining line under any of them.
    expect(find.text('Full gym'), findsOneWidget);
    expect(find.text('No equipment'), findsOneWidget);
    expect(find.text('Some equipment'), findsOneWidget);
    expect(find.textContaining('Pull-up bar, rings'), findsNothing);
    expect(find.textContaining('Training at home'), findsNothing);
    expect(find.textContaining('bar in the garage'), findsNothing);
    expect(find.textContaining('Tell Forma'), findsNothing);
    await tester.tap(find.text('Some equipment'));
    await tester.pumpAndSettle();
    expect(find.text('What do you have?'), findsOneWidget);
    expect(find.text('Select at least one item'), findsOneWidget);
    await tester.ensureVisible(find.text('Dumbbells'));
    await tester.tap(find.text('Dumbbells'));
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);
    await tester.ensureVisible(find.text('Barbell'));
    await tester.tap(find.text('Barbell'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('What do you have?'), findsNothing);
    expect(find.text('Dumbbells, Barbell'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.textContaining('pull-up bar'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Nothing to dip on in that pick, so the two-chairs tip comes first —
    // still on the equipment step's count, back returns to the pick.
    expect(find.text('No dip bars? Two chairs will do.'), findsOneWidget);
    expect(find.text('Your equipment'), findsNothing);
    await tester.tap(backButton());
    await tester.pumpAndSettle();
    expect(find.text('Your equipment'), findsOneWidget);
    expect(find.text('Dumbbells, Barbell'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await pumpStep(tester);

    // Step 3: bodyweight — the keypad is already up, the placeholder shows,
    // and Continue holds until a number of the user's own is in the field.
    expect(find.text('Your bodyweight'), findsOneWidget);
    // A dimmed 0 kg, and no "minimum" nag about a number nobody typed.
    expect(bodyweightField(tester).text, '0');
    expect(bodyweightField(tester).dim, isTrue);
    expect(bodyweightField(tester).unit, WeightUnit.kg);
    expect(find.textContaining('Minimum'), findsNothing);
    expect(find.text('Tap the number to change it'), findsNothing);
    expect(find.text('8'), findsOneWidget, reason: 'the keypad is open');
    expect(find.text('Enter your bodyweight to continue'), findsOneWidget);
    expect(continueEnabled(tester), isFalse, reason: 'nothing typed yet');
    await tester.tap(find.text('8'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(find.text('82'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 4: starting strength — everything starts at 0, and "+" steps up
    // by a rep, or by five of the weight unit.
    expect(find.text('Where are you starting?'), findsOneWidget);
    expect(find.text('Barbell squat'), findsOneWidget);
    // The hinge is not asked about: it opens on its first loaded rung.
    expect(find.text('Romanian deadlift'), findsNothing);
    expect(find.text('Best single rep — bar weight'), findsNothing);
    expect(find.text('—'), findsNothing);
    expect(find.text('0'), findsNWidgets(3)); // push-ups, pull-ups, dips
    expect(find.text('0 kg'), findsOneWidget); // squat
    await tester.tap(find.byIcon(Icons.add_rounded).at(1));
    await tester.pump();
    expect(find.text('1'), findsOneWidget); // pull-ups: one rep
    await tester.tap(find.byIcon(Icons.add_rounded).at(1));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add_rounded).at(1));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_rounded).at(3));
    await tester.pump();
    expect(find.text('5 kg'), findsOneWidget); // squat: five kilos
    // Back down to 0, where "−" stops.
    await tester.tap(find.byIcon(Icons.remove_rounded).at(3));
    await tester.pump();
    expect(find.text('0 kg'), findsOneWidget);
    expect(find.text('Build my program'), findsOneWidget);
    await tester.tap(find.text('Build my program'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.daysPerWeek, 3);
    expect(result!.split, TrainingProgramType.fullBody);
    expect(
      result!.equipment,
      EquipmentAnswer.some({EquipmentItem.dumbbells, EquipmentItem.barbell}),
    );
    expect(result!.hasWeights, isTrue);
    expect(result!.bodyweightKg, 82);
    expect(result!.startingStrength['pushups'], isNull);
    expect(result!.startingStrength['pullups'], 3);
    // Stepped up and back down is an answer of 0.
    expect(result!.startingStrength['squat'], 0);
    expect(result!.startingStrength.containsKey('rdl'), isFalse);
    expect(result!.startingStrength.containsKey('squat_bw'), isFalse);
    expect(result!.toMap()['has_gym'], isTrue);
    expect(result!.toMap()['equipment'], 'some');
    expect(result!.toMap()['equipment_items'], ['dumbbells', 'barbell']);

    // The ready screen: the map, the trial, and "Not now" out of the
    // wizard. Without a program on file there is no wheel to draw, but the
    // page and its choice still stand.
    expect(find.text('Your training program is ready'), findsOneWidget);
    expect(find.textContaining('free trial'), findsWidgets);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(finished, 1);
  });

  testWidgets('4–6 training days build a push/pull split', (tester) async {
    ProgramSetupResult? result;
    await pumpQuestions(tester, onComplete: (value) async => result = value);

    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No equipment'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsOneWidget, reason: 'no dip bars');
    await tester.tap(find.text('Got it'));
    await pumpStep(tester);
    // Two digits from the keypad's upper rows: the bottom row sits below
    // the test surface's fold.
    await tester.tap(find.text('7'));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    // No weights: the squat question is bodyweight reps.
    expect(find.text('Bodyweight squats'), findsOneWidget);
    expect(find.text('Barbell squat'), findsNothing);
    await tester.tap(find.text('Build my program'));
    await tester.pumpAndSettle();

    expect(result!.split, TrainingProgramType.pushPull);
    expect(result!.equipment, EquipmentAnswer.none);
    expect(result!.hasWeights, isFalse);
    expect(result!.toMap()['has_gym'], isFalse);
    expect(result!.startingStrength.containsKey('squat_bw'), isTrue);
    expect(result!.startingStrength.containsKey('squat'), isFalse);
  });

  testWidgets('picking lbs converts the shown weight and sticks app-wide',
      (tester) async {
    ProgramSetupResult? result;
    await pumpQuestions(tester, onComplete: (value) async => result = value);

    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full gym'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await pumpStep(tester);
    expect(find.text('Got it'), findsNothing, reason: 'a gym has dip bars');

    // The placeholder is 0 in either unit, the choice persists for the
    // whole app, and the keypad stays up across the flip.
    await tester.tap(find.text('lbs'));
    await tester.pump();
    expect(bodyweightField(tester).text, '0');
    expect(bodyweightField(tester).dim, isTrue);
    expect(bodyweightField(tester).unit, WeightUnit.lb);
    expect(WeightUnitService.unit, WeightUnit.lb);
    expect(find.text('8'), findsOneWidget, reason: 'the keypad is still open');

    // Type in pounds, then flip mid-entry: the typed number converts rather
    // than the placeholder, and it stays typed.
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('6'));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('kg'));
    await tester.pump();
    expect(find.text('75'), findsOneWidget, reason: '165 lb is 75 kg');
    await tester.tap(find.text('lbs'));
    await tester.pump();
    expect(find.text('165'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build my program'));
    await tester.pumpAndSettle();

    // Canonical storage stays in kilograms.
    expect(result!.bodyweightKg, closeTo(74.8, 0.2));
  });

  testWidgets(
      'the bodyweight minimum is only mentioned when Continue is pressed on '
      'a number under it', (tester) async {
    await pumpQuestions(tester, onComplete: (_) async {});
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full gym'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await pumpStep(tester);
    expect(find.text('Your bodyweight'), findsOneWidget);

    // Typing a number under the floor: no note, and Continue can be tried.
    // (Keys from the keypad's upper rows: the bottom one is under the fold.)
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(bodyweightField(tester).text, '1');
    expect(find.textContaining('Minimum'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
    expect(continueEnabled(tester), isTrue);

    // Pressing Continue on it: the page stays, and says why.
    await tester.tap(find.text('Continue'));
    await pumpStep(tester);
    expect(find.text('Your bodyweight'), findsOneWidget);
    expect(find.text('Minimum 30 kg'), findsOneWidget);
    expect(bodyweightField(tester).text, '1');

    // The next key takes the note down again, even though 12 is still
    // under the floor — it only comes back on another press of Continue.
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(bodyweightField(tester).text, '12');
    expect(find.textContaining('Minimum'), findsNothing);

    // A real weight goes through.
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(bodyweightField(tester).text, '125');
    expect(find.textContaining('Minimum'), findsNothing);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Where are you starting?'), findsOneWidget);
  });

  testWidgets(
      'a page on its way out keeps what it showed — no flash of another '
      'state mid-transition', (tester) async {
    await pumpQuestions(tester, onComplete: (_) async {});
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No equipment'));
    await tester.pump();

    // Into the chairs tip: the equipment page leaves as the equipment page.
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('No equipment'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('No equipment'), findsNothing);

    // Out of it: the tip leaves as the tip, not as the options behind it.
    await tester.tap(find.text('Got it'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('No equipment'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(Image), findsNothing);

    // Leaving the bodyweight page: its keypad stays up while it fades.
    expect(find.text('Your bodyweight'), findsOneWidget);
    await tester.tap(find.text('7'));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Tap the number to change it'), findsNothing);
  });

  testWidgets('back button steps backwards, and the first step has none',
      (tester) async {
    await pumpQuestions(tester, onComplete: (_) async {});
    expect(backButton().hitTestable(), findsNothing);

    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Your equipment'), findsOneWidget);

    await tester.tap(backButton());
    await tester.pumpAndSettle();
    expect(find.text('Your training schedule'), findsOneWidget);
    expect(backButton().hitTestable(), findsNothing);
  });

  testWidgets('a back gesture steps backwards through the questions',
      (tester) async {
    await pumpQuestions(tester, onComplete: (_) async {});

    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Your equipment'), findsOneWidget);

    // What the iOS edge swipe and the Android back button both call.
    Future<void> systemBack() async {
      await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
      await tester.pumpAndSettle();
    }

    await systemBack();
    expect(find.text('Your training schedule'), findsOneWidget);
  });
}
