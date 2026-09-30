import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/onboarding_profile_model.dart';
import 'package:forma_app/data/services/weight_unit_service.dart';
import 'package:forma_app/features/onboarding/onboarding_view.dart';
import 'package:forma_app/features/onboarding/program_setup_steps.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    WeightUnitService.notifier.value = WeightUnit.kg;
  });

  Future<void> pumpFlow(
    WidgetTester tester, {
    bool askProgram = true,
    Future<void> Function(OnboardingProfileModel?, ProgramSetupResult?)? onSave,
    VoidCallback? onFinished,
  }) async {
    // Phone-sized viewport so the fixed radar layout gets realistic space.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingView(
          userId: 'user',
          askProgram: askProgram,
          onSave: onSave ?? (_, __) async {},
          onFinished: onFinished ?? () {},
        ),
      ),
    );
  }

  // The narrative beats loop forever, so `pumpAndSettle` would time out on
  // them — step the clock by hand instead.
  Future<void> next(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
  }

  testWidgets(
      'one flow from the beats to a built program, saving both at the end',
      (tester) async {
    OnboardingProfileModel? savedProfile;
    ProgramSetupResult? savedProgram;
    await pumpFlow(
      tester,
      onSave: (profile, program) async {
        savedProfile = profile;
        savedProgram = program;
      },
    );

    // Step 0: the skill-tree beat — the welcome hook now lives on the
    // sign-in screen.
    expect(find.text('From your first'), findsNothing);
    expect(find.text('Get started'), findsNothing);
    // The skill-tree beat, drawn by the app's own tree map.
    expect(find.text('A roadmap for every calisthenic skill.'), findsOneWidget);
    expect(find.text('PULL-UP SKILL TREE'), findsOneWidget);
    final treeMap = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_TreeMapPainter',
    );
    expect(treeMap, findsOneWidget);
    await next(tester, 'Continue');

    // Step 1: the workout beat starts at 3 × 5.
    expect(
      find.text('Your exercises adapt to your skill level.'),
      findsOneWidget,
    );
    expect(find.text('3 × '), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    await next(tester, 'Continue');

    // Step 2: the data beat.
    expect(
      find.text('Your workouts adapt so you never start over.'),
      findsOneWidget,
    );
    await next(tester, 'Continue');

    // Step 3: radar starts balanced; dragging up selects The Technician.
    expect(find.text('What is your aim?'), findsOneWidget);
    expect(find.text('The Generalist'), findsOneWidget);
    final radar = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_RadarPainter',
    );
    expect(radar, findsOneWidget);
    final logicalWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(
      tester.getCenter(radar).dx,
      moreOrLessEquals(logicalWidth / 2, epsilon: 1),
      reason: 'radar should be horizontally centered',
    );
    await tester.tapAt(tester.getCenter(radar) + const Offset(0, -80));
    await tester.pump();
    expect(find.text('The Technician'), findsOneWidget);
    await next(tester, 'Continue');

    // Step 4: about you.
    expect(find.text('Your profile'), findsOneWidget);
    expect(find.text('28'), findsOneWidget); // default age
    await tester.tap(find.text('1–2×'));
    await tester.pump();
    await tester.tap(find.text('Male'));
    await tester.pump();

    // No welcome screen and no second flow: the program questions come
    // next under the same header, and back crosses between the two.
    await next(tester, 'Continue');
    expect(find.text('YOUR PROGRAM'), findsOneWidget);
    expect(find.text('Your training schedule'), findsOneWidget);
    expect(find.text('Enter Forma'), findsNothing);
    expect(savedProfile, isNull, reason: 'nothing is written mid-flow');

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Your profile'), findsOneWidget);
    await next(tester, 'Continue');

    // Step 5: schedule. Step 6: equipment — a gym has dip bars, so no tip.
    await tester.tap(find.text('3'));
    await tester.pump();
    await next(tester, 'Continue');
    await tester.tap(find.text('Full gym'));
    await tester.pump();
    await next(tester, 'Continue');

    // Step 7: bodyweight, keypad already up.
    expect(find.text('Your bodyweight'), findsOneWidget);
    await tester.tap(find.text('8'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await next(tester, 'Continue');

    // Step 8: starting strength, and the one save for the whole flow.
    expect(find.text('Where are you starting?'), findsOneWidget);
    await next(tester, 'Build my program');

    expect(savedProfile!.userId, 'user');
    expect(savedProfile!.archetype, 'technician');
    expect(savedProfile!.gender, 'm');
    expect(savedProfile!.trainingFrequency, '1-2');
    expect(savedProgram!.daysPerWeek, 3);
    expect(savedProgram!.bodyweightKg, 80);
    // The flow ends on the map the answers drew.
    expect(find.text('Program ready'), findsOneWidget);
  });

  testWidgets(
      'an account that already has a program answers onboarding alone, '
      'and its program is left as it is', (tester) async {
    OnboardingProfileModel? savedProfile;
    ProgramSetupResult? savedProgram;
    var finished = 0;
    await pumpFlow(
      tester,
      askProgram: false,
      onSave: (profile, program) async {
        savedProfile = profile;
        savedProgram = program;
      },
      onFinished: () => finished++,
    );
    for (var i = 0; i < 4; i++) {
      await next(tester, 'Continue');
    }
    expect(find.text('Your profile'), findsOneWidget);
    await next(tester, 'Continue');

    expect(savedProfile, isNotNull);
    expect(savedProgram, isNull);
    expect(finished, 1, reason: 'no ready screen without a new program');
  });

  testWidgets('the age slider is a real slider that announces its value',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFlow(tester);
    for (var i = 0; i < 4; i++) {
      await next(tester, 'Continue');
    }
    expect(find.text('Your profile'), findsOneWidget);
    expect(find.text('A LITTLE BIT ABOUT YOU'), findsOneWidget);
    expect(find.text('Rather not say'), findsOneWidget);

    final slider = tester.getSemantics(find.byType(Slider));
    expect(slider.flagsCollection.isSlider, isTrue);
    expect(slider.value, '28 years');
    handle.dispose();
  });

  testWidgets('back button steps backwards', (tester) async {
    await pumpFlow(tester);

    await next(tester, 'Continue');
    expect(
      find.text('Your exercises adapt to your skill level.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('A roadmap for every calisthenic skill.'), findsOneWidget);
  });
}
