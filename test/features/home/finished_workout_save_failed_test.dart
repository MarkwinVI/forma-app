import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/completed_workout_model.dart';
import 'package:forma_app/features/home/finished_workout_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A workout that could not be saved is not a finished workout. The screen
/// says what happened and how to recover — retry, or go back to the live
/// workout, which is still underneath with every set in place — and keeps
/// the celebration (check, confetti, "Workout complete") for a save that
/// landed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // No signed-in user: the save fails before it reaches the network.
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZSI6ImFub24iLCJpYXQiOjE1MTYyMzkwMjJ9.c2lnbmVk',
    );
  });

  CompletedWorkout workout() {
    final exercise = ExerciseCatalog.findById('pullups_scapular_pull')!;
    final now = DateTime(2026, 8, 19, 18, 30);
    return CompletedWorkout(
      sessionLabel: 'Pull Day',
      sessionType: TrainingSessionType.pull,
      startedAt: now.subtract(const Duration(minutes: 40)),
      finishedAt: now,
      exercises: [
        CompletedWorkoutExercise(
          item: TrainingRecommendationItem(
            track: TrainingTrack.verticalPull,
            exercise: exercise,
            status: ExerciseStatus.active,
            sourceCategory: exercise.category,
            sourceSkillCategoryId: exercise.skillCategoryId,
          ),
          sets: const [
            CompletedWorkoutSet(number: 1, value: 8, isTimed: false),
            CompletedWorkoutSet(number: 2, value: 8, isTimed: false),
          ],
        ),
      ],
    );
  }

  /// The finish screen is pushed over the live workout; here a stand-in
  /// page plays the workout, so "back" has somewhere to land.
  Future<void> pumpOverHost(WidgetTester tester,
      {bool reduceMotion = false}) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FinishedWorkoutView(workout: workout()),
                  ),
                ),
                child: const Text('live workout'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('live workout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('a failed save is an error state, not a celebration',
      (tester) async {
    await pumpOverHost(tester);

    expect(find.text("Couldn't save your workout"), findsOneWidget);
    expect(
      find.textContaining('Your sets are still here'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Back to workout'), findsOneWidget);

    expect(find.text('Workout complete'), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    // No confetti layer while there is nothing to celebrate.
    expect(
        find.byType(CustomPaint).evaluate().where((element) {
          final painter = (element.widget as CustomPaint).painter;
          return painter.runtimeType.toString().contains('Confetti');
        }),
        isEmpty);
  });

  testWidgets('Back to workout returns to the screen underneath',
      (tester) async {
    await pumpOverHost(tester);
    await tester.tap(find.text('Back to workout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(FinishedWorkoutView), findsNothing);
    expect(find.text('live workout'), findsOneWidget);
  });

  testWidgets('the signed-out reason reads as a sentence, not an exception',
      (tester) async {
    await pumpOverHost(tester);
    expect(find.textContaining('You are signed out.'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
  });
}
