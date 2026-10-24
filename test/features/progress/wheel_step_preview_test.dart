import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel_panels.dart';

/// The preview sheet a tapped step opens draws how far along the step is.
/// The bar's fill once sized itself to nothing, so a step three-quarters of
/// the way to its target showed "18 / 24" over an empty bar.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required WheelNodeState state,
    WheelStepStats? stats,
    VoidCallback? onOpen,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: WheelStepPreview(
              node: WheelNode(
                exerciseId: 'pullups_pull_up',
                name: 'Pull Up',
                state: state,
              ),
              stats: stats,
              position: const WheelStepPosition(
                section: 'FOUNDATION',
                number: 3,
                count: 4,
              ),
              onOpenExercise: onOpen ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The bar's track is the clipped strip; the fill is the sized box inside
  /// it, and the Container is what actually paints.
  Size trackSize(WidgetTester tester) => tester.getSize(find.byType(ClipRRect));
  Size fillSize(WidgetTester tester) => tester.getSize(
        find.descendant(
          of: find.byType(AnimatedFractionallySizedBox),
          matching: find.byType(Container),
        ),
      );

  testWidgets('a step most of the way to its target shows most of a bar',
      (tester) async {
    await pump(
      tester,
      state: WheelNodeState.active,
      stats: const WheelStepStats(bestVolume: 18, targetVolume: 24),
    );

    final track = trackSize(tester);
    final fill = fillSize(tester);
    expect(fill.height, track.height);
    expect(fill.width, closeTo(track.width * 0.75, 0.5));
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('FOUNDATION · STEP 3 OF 4'), findsOneWidget);
    expect(find.text('BEST WORKOUT'), findsOneWidget);
    expect(
      find.textContaining('18 / 24 reps', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('24 reps in a single workout masters this step.'),
      findsOneWidget,
    );
  });

  testWidgets('a mastered step shows a full bar, whatever it logged',
      (tester) async {
    // Mastered by jumping past it: never reached its own target.
    await pump(
      tester,
      state: WheelNodeState.mastered,
      stats: const WheelStepStats(bestVolume: 10, targetVolume: 24),
    );

    final track = trackSize(tester);
    final fill = fillSize(tester);
    expect(fill.height, track.height);
    expect(fill.width, closeTo(track.width, 0.5));
    expect(find.text('Mastered'), findsOneWidget);
    expect(find.textContaining('masters this step'), findsNothing);
  });

  testWidgets('a hold counts seconds, and an untrained step an empty bar',
      (tester) async {
    await pump(
      tester,
      state: WheelNodeState.available,
      stats: const WheelStepStats(
        bestVolume: 0,
        targetVolume: 60,
        isTimed: true,
      ),
    );

    expect(fillSize(tester).width, 0);
    expect(find.text('Unlocked · not training'), findsOneWidget);
    expect(
      find.textContaining('0 / 60 sec', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('60 sec in a single workout masters this step.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'without numbers the status stands alone; the thumbnail and Full '
      'details both open the exercise', (tester) async {
    var opened = 0;
    await pump(
      tester,
      state: WheelNodeState.locked,
      onOpen: () => opened++,
    );

    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('BEST WORKOUT'), findsNothing);
    expect(find.textContaining('masters this step'), findsNothing);
    expect(find.text('Full details'), findsOneWidget);

    await tester.tap(find.text('Full details'));
    expect(opened, 1);
    await tester.tap(find.bySemanticsLabel('Open Pull Up'));
    expect(opened, 2);
  });

  test('a step knows its place in its branch', () {
    final family = WheelFamily(
      categoryId: 'squat',
      title: 'Squat',
      trunk: [
        for (var i = 0; i < 2; i++)
          WheelNode(
            exerciseId: 't$i',
            name: 'Trunk $i',
            state: WheelNodeState.mastered,
          ),
      ],
      branches: [
        WheelBranch(id: 'pistol', label: 'Pistol', steps: [
          for (var i = 0; i < 3; i++)
            WheelNode(
              exerciseId: 'p$i',
              name: 'Pistol $i',
              state: WheelNodeState.locked,
            ),
        ]),
      ],
    );

    expect(WheelStepPosition.of(family, 1).label, 'FOUNDATION · STEP 2 OF 2');
    expect(WheelStepPosition.of(family, 2).label, 'PISTOL · STEP 1 OF 3');
    expect(WheelStepPosition.of(family, 4).label, 'PISTOL · STEP 3 OF 3');
  });
}
