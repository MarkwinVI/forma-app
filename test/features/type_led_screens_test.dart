import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/models/workout_history_model.dart';
import 'package:forma_app/features/data/calendar_view.dart';
import 'package:forma_app/features/data/past_workout_detail_view.dart';
import 'package:forma_app/features/home/home_dashboard_metrics.dart';
import 'package:forma_app/features/home/widgets/week_strip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Layout guards for the type-led screens: a phone-sized frame catches the
/// overflow a hairline row can hit once its numbers grow, which is the way
/// these screens break.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZSI6ImFub24iLCJpYXQiOjE1MTYyMzkwMjJ9.c2lnbmVk',
    );
  });

  testWidgets('the profile calendar panel lays out with a full month',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: CalendarPanel(
              workouts: [
                for (var day = 1; day <= 12; day++)
                  _workout('w$day', DateTime(2026, 7, day * 2)),
              ],
              now: DateTime(2026, 7, 29),
              showActivityHeatmap: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('July 2026'), findsOneWidget);
    expect(find.text('WEEKLY STREAK'), findsOneWidget);
    // A session every other day is a session every week.
    expect(find.text('4 weeks'), findsOneWidget);
    // The label names the number; nothing explains it underneath.
    expect(find.textContaining('Train once'), findsNothing);
    // Stat captions read above their numbers.
    // Twelve 42-minute sessions.
    final caption = tester.getTopLeft(find.text('TOTAL TIME'));
    final value = tester.getTopLeft(find.text('8h 24m'));
    expect(caption.dy, lessThan(value.dy));
  });

  testWidgets('the workout record lists every set of every exercise',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: PastWorkoutDetailView(workout: _workout('w1', DateTime(2026, 7, 28))),
      ),
    );

    expect(find.text('Upper'), findsOneWidget);
    // Once as the stat caption, once as the section label.
    expect(find.text('EXERCISES'), findsNWidgets(2));
    expect(find.text('SET 1'), findsNWidgets(2));
    expect(find.text('6 reps'), findsNWidgets(3));
    // The category subtitle and the rep total are deliberately absent.
    expect(find.text('Vertical push'), findsNothing);
    expect(find.text('REPS'), findsNothing);
  });

  testWidgets('the week strip renders one letter per day', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: WeekStrip(
              weekStrip: HomeWeekStripData(
                days: [
                  for (var i = 0; i < 7; i++)
                    HomeWeekStripDay(
                      date: DateTime(2026, 7, 27).add(Duration(days: i)),
                      sessionType: i.isEven
                          ? TrainingSessionType.upper
                          : TrainingSessionType.rest,
                      isCurrent: i == 1,
                      isCompleted: i == 0,
                    ),
                ],
                completedSessions: 1,
                totalSessions: 4,
                supportingText: '',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('M'), findsOneWidget);
    expect(find.text('T'), findsNWidgets(2));
    expect(find.text('S'), findsNWidgets(2));
  });
}

PastWorkout _workout(String id, DateTime day) {
  final startedAt = DateTime(day.year, day.month, day.day, 17);
  return PastWorkout(
    id: id,
    title: 'Upper',
    sessionType: TrainingSessionType.upper.dbValue,
    startedAt: startedAt,
    loggedAt: startedAt.add(const Duration(minutes: 42)),
    exercises: const [
      PastWorkoutExercise(
        exerciseId: 'bench_dips',
        exerciseName: 'Bench Dips',
        setCount: 2,
        totalReps: 12,
        totalTimedSeconds: 0,
        sets: [
          PastWorkoutSet(number: 1, value: 6, isTimed: false),
          PastWorkoutSet(number: 2, value: 6, isTimed: false),
        ],
      ),
      PastWorkoutExercise(
        exerciseId: 'wall_push_up',
        exerciseName: 'Wall Pushups',
        setCount: 1,
        totalReps: 6,
        totalTimedSeconds: 0,
        sets: [PastWorkoutSet(number: 1, value: 6, isTimed: false)],
      ),
    ],
  );
}
