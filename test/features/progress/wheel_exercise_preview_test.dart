import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/home_dashboard_metrics.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel_panels.dart';

/// The preview under a selected node draws how far along it is. The bar's
/// fill once sized itself to nothing, so a node three-quarters of the way to
/// its target showed "18 of 24" over an empty bar.
void main() {
  JourneySkillProgressData journey(double percent) {
    return JourneySkillProgressData(
      track: TrainingTrack.verticalPull,
      skillCategoryId: 'pullups',
      branchId: 'foundation',
      motionLabel: 'Pullups',
      skillTitle: 'Pull-up',
      currentExerciseName: 'Pull Up',
      nextExerciseName: 'Weighted Pull Up',
      targetVolume: 24,
      lastSessionVolume: 18,
      targetLabel: '24 reps',
      lastLabel: '18 reps',
      lastSessionDeltaLabel: '+3',
      lastSessionTrend: JourneySkillTrend.up,
      progressPercent: percent,
      stages: const [],
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    required WheelNodeState state,
    JourneySkillProgressData? data,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: WheelExercisePreview(
              node: WheelNode(
                exerciseId: 'pullups_pull_up',
                name: 'Pull Up',
                state: state,
              ),
              journey: data,
              onOpen: () {},
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

  testWidgets('a node most of the way to its target shows most of a bar',
      (tester) async {
    await pump(tester, state: WheelNodeState.active, data: journey(0.75));

    final track = trackSize(tester);
    final fill = fillSize(tester);
    expect(fill.height, track.height);
    expect(fill.width, closeTo(track.width * 0.75, 0.5));
    expect(
      find.text('Training · 18 of 24 reps (total reps)'),
      findsOneWidget,
    );
  });

  testWidgets('a mastered node shows a full bar', (tester) async {
    await pump(tester, state: WheelNodeState.mastered);

    final track = trackSize(tester);
    final fill = fillSize(tester);
    expect(fill.height, track.height);
    expect(fill.width, closeTo(track.width, 0.5));
  });
}
