import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/hold_timer_view.dart';
import 'package:forma_app/features/home/live_workout_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A timed set is a hold waiting to happen: until something is logged for
/// it, its value cell is a play pill into the full-screen stopwatch — which
/// starts at once, with no count-in — and logging from there records the
/// seconds and ticks the set. From then on the cell is the ordinary number
/// field, so the seconds can be corrected the way reps are.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZSI6ImFub24iLCJpYXQiOjE1MTYyMzkwMjJ9.c2lnbmVk',
    );
  });

  DailyTrainingRecommendation timedRecommendation() {
    // A hold in the rows tree — timed, so its sets are seconds.
    final exercise =
        ExerciseCatalog.findById('rows_tuck_front_lever_rows_hold')!;
    expect(exercise.isTimed, isTrue);
    return DailyTrainingRecommendation(
      programType: TrainingProgramType.pushPull,
      sessionType: TrainingSessionType.pull,
      sessionLabel: 'Pull Day',
      isRestDay: false,
      items: [
        TrainingRecommendationItem(
          track: TrainingTrack.horizontalPull,
          exercise: exercise,
          status: ExerciseStatus.active,
          sourceCategory: exercise.category,
          sourceSkillCategoryId: exercise.skillCategoryId,
        ),
      ],
    );
  }

  Future<void> pumpWorkout(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: LiveWorkoutView(recommendation: timedRecommendation())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('an unlogged timed set shows a play pill, not a number field',
      (tester) async {
    await pumpWorkout(tester);

    // Every set is a hold waiting: one pill per set, no editable field.
    final pills = find.byIcon(Icons.play_arrow_rounded);
    expect(pills, findsWidgets);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
      'the pill opens the hold timer at once, logging ticks the set and '
      'turns the cell into the number field', (tester) async {
    await pumpWorkout(tester);
    final pillCount = find.byIcon(Icons.play_arrow_rounded).evaluate().length;

    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    // Fixed pumps: the timer redraws every frame, so nothing ever settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // No count-in: the stopwatch is already holding.
    expect(find.byType(HoldTimerView), findsOneWidget);
    expect(find.text('Get ready…'), findsNothing);
    expect(find.text('Holding…'), findsOneWidget);
    expect(find.textContaining('Set 1 of'), findsOneWidget);

    // Nothing to log at zero seconds; three seconds later there is.
    expect(find.text('Log set'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Log set · 3s'), findsOneWidget);

    await tester.tap(find.text('Log set · 3s'));
    // Not pumpAndSettle: the workout clock behind never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(HoldTimerView), findsNothing);

    // The set carries the held seconds in an editable field, ticked — and
    // is no longer a pill. The others still are.
    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, '3');
    expect(
      find.byIcon(Icons.play_arrow_rounded),
      findsNWidgets(pillCount - 1),
    );
  });

  testWidgets('closing the timer mid-hold changes nothing', (tester) async {
    await pumpWorkout(tester);
    final pillCount = find.byIcon(Icons.play_arrow_rounded).evaluate().length;

    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    // Fixed pumps: the timer redraws every frame, so nothing ever settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(HoldTimerView), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(pillCount));
  });

  testWidgets('closing a paused timer logs the seconds', (tester) async {
    await pumpWorkout(tester);
    final pillCount = find.byIcon(Icons.play_arrow_rounded).evaluate().length;

    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    // Fixed pumps: the timer redraws every frame, so nothing ever settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 7));
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(HoldTimerView), findsNothing);
    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, '7');
    expect(
      find.byIcon(Icons.play_arrow_rounded),
      findsNWidgets(pillCount - 1),
    );
  });

  testWidgets('pausing exposes fine adjustment, and it cannot go below zero',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HoldTimerView(
          exerciseName: 'Tuck Front Lever Hold',
          setNumber: 2,
          totalSets: 3,
          goalSeconds: 10,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Paused'), findsOneWidget);

    await tester.tap(find.text('+5s'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('9'), findsOneWidget);
    // Past the goal reads green and says so.
    await tester.tap(find.text('+1s'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Goal reached'), findsOneWidget);
    expect(find.text('Goal hit — keep going or log it'), findsNothing);

    // Take back more than was counted: it stops at zero.
    await tester.tap(find.text('-5s'));
    await tester.tap(find.text('-5s'));
    await tester.tap(find.text('-5s'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Log set'), findsOneWidget);
  });

  testWidgets('a tap anywhere off the controls pauses the hold',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HoldTimerView(
          exerciseName: 'Tuck Front Lever Hold',
          setNumber: 1,
          totalSets: 3,
          goalSeconds: 20,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Holding…'), findsOneWidget);

    // Bare background, well away from any button.
    await tester.tapAt(const Offset(40, 300));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Paused'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Frozen: time passes, the count does not.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('3'), findsOneWidget);

    // Another background tap does not resume; the play button does.
    await tester.tapAt(const Offset(40, 300));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Paused'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Holding…'), findsOneWidget);
  });
}
