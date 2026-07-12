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

  Future<void> next(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('walks through all six steps and reflects the answers',
      (tester) async {
    await pumpFlow(tester);

    // Step 0: welcome.
    expect(find.text('Train your body.\nMaster real skills.'), findsOneWidget);
    await next(tester, 'Get started');

    // Step 1: how it works.
    expect(find.text('You always know what to train.'), findsOneWidget);
    expect(find.text('Muscle-up'), findsOneWidget);
    await next(tester, 'Continue');

    // Step 2: what's inside.
    expect(find.text("What's inside."), findsOneWidget);
    expect(find.text('Skill trees'), findsOneWidget);
    await next(tester, 'Continue');

    // Step 3: radar starts balanced; dragging up selects The Technician.
    expect(find.text('What brings you to Forma?'), findsOneWidget);
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
    expect(find.text('About you.'), findsOneWidget);
    expect(find.text('28'), findsOneWidget); // default age
    await tester.tap(find.text('1–2×'));
    await tester.pump();
    await tester.tap(find.text('Male'));
    await tester.pump();
    await next(tester, 'Continue');

    // Step 5: summary shows the collected answers.
    expect(find.text('Your Forma profile.'), findsOneWidget);
    expect(find.text('The Technician'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('1-2 / week'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    // Hidden via Visibility(maintainSize) — still in the tree, not tappable.
    expect(find.text('Skip').hitTestable(), findsNothing);
  });

  testWidgets('skip jumps to the summary', (tester) async {
    await pumpFlow(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Your Forma profile.'), findsOneWidget);
    expect(find.text('The Generalist'), findsOneWidget);
  });

  testWidgets('back button steps backwards', (tester) async {
    await pumpFlow(tester);

    await next(tester, 'Get started');
    expect(find.text('You always know what to train.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Train your body.\nMaster real skills.'), findsOneWidget);
  });
}
