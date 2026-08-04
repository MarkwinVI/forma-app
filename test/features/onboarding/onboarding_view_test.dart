import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/onboarding/onboarding_view.dart';

void main() {
  Future<void> pumpFlow(WidgetTester tester) async {
    // Phone-sized viewport so the fixed radar layout gets realistic space.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: OnboardingView(onFinished: () {})),
    );
  }

  // The narrative beats loop forever, so `pumpAndSettle` would time out on
  // them — step the clock by hand instead.
  Future<void> next(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
  }

  testWidgets('walks through all seven steps and reflects the answers',
      (tester) async {
    await pumpFlow(tester);

    // Step 0: welcome — the hook, with no badge above it.
    expect(find.text('From your first'), findsOneWidget);
    expect(find.text('pull-up'), findsOneWidget);
    expect(find.text('WELCOME TO FORMA'), findsNothing);
    await next(tester, 'Get started');

    // Step 1: the skill-tree beat, drawn by the app's own tree map.
    expect(find.text('A roadmap for every calisthenic skill.'), findsOneWidget);
    expect(find.text('PULL-UP SKILL TREE'), findsOneWidget);
    final treeMap = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_TreeMapPainter',
    );
    expect(treeMap, findsOneWidget);
    await next(tester, 'Continue');

    // Step 2: the workout beat starts at 3 × 5.
    expect(
      find.text('Your exercises adapt to your skill level.'),
      findsOneWidget,
    );
    expect(find.text('3 × '), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    await next(tester, 'Continue');

    // Step 3: the data beat.
    expect(
      find.text('Your workouts adapt so you never start over.'),
      findsOneWidget,
    );
    await next(tester, 'Continue');

    // Step 4: radar starts balanced; dragging up selects The Technician.
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

    // Step 5: about you.
    expect(find.text('Your profile'), findsOneWidget);
    expect(find.text('28'), findsOneWidget); // default age
    await tester.tap(find.text('1–2×'));
    await tester.pump();
    await tester.tap(find.text('Male'));
    await tester.pump();
    await next(tester, 'Continue');

    // Step 6: ready.
    expect(find.text('Welcome to Forma'), findsOneWidget);
    expect(find.text('Enter Forma'), findsOneWidget);
  });

  testWidgets('there is no way to skip the flow', (tester) async {
    await pumpFlow(tester);

    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('back button steps backwards', (tester) async {
    await pumpFlow(tester);

    await next(tester, 'Get started');
    expect(find.text('A roadmap for every calisthenic skill.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('From your first'), findsOneWidget);
  });
}
