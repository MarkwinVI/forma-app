import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/progression_event_model.dart';
import 'package:forma_app/data/models/workout_history_model.dart';
import 'package:forma_app/features/home/home_dashboard_metrics.dart';
import 'package:forma_app/features/home/widgets/today_workout_card.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  HomeTodaySummary summary({HomeCompletedWorkoutSummary? completed}) {
    return HomeTodaySummary(
      sessionTitle: 'Pull Day',
      ctaLabel: 'Start Pull Day',
      isRestDay: false,
      exerciseCount: 5,
      estimatedDurationMinutes: 48,
      focusTags: const [],
      plannedExercises: const [],
      mixSegments: const [],
      supportingText: '',
      completed: completed,
    );
  }

  const rows = [
    TodayWorkoutRow(
      exerciseId: 'handstand_wall_handstand',
      name: 'Wall Handstand',
      previousLabel: '18s',
      changeLabel: '+2',
      changeDir: 1,
      leveledUp: true,
    ),
    TodayWorkoutRow(
      exerciseId: 'pullups_pull_up',
      name: 'Pull-ups',
      previousLabel: '24',
      changeLabel: '±0',
      changeDir: 0,
    ),
    TodayWorkoutRow(
      name: 'Romanian Deadlift',
      previousLabel: '—',
      changeLabel: '−1',
      changeDir: -1,
    ),
  ];

  Widget host(Widget child) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF111114),
        body: Center(
          child: SizedBox(width: 370, child: child),
        ),
      ),
    );
  }

  testWidgets('shows plan rows with the prev and last columns', (tester) async {
    var started = false;
    var trainElse = false;
    TodayWorkoutRow? tapped;
    await tester.pumpWidget(
      host(
        Column(
          children: [
            TodayWorkoutCard(
              summary: summary(),
              rows: rows,
              onRowTap: (row) => tapped = row,
            ),
            TodayWorkoutActions(
              summary: summary(),
              onStart: () => started = true,
              onTrainSomethingElse: () => trainElse = true,
            ),
          ],
        ),
      ),
    );

    // The day names itself, then every exercise with what it last totalled.
    expect(find.text('Pull Day'), findsOneWidget);
    expect(find.text('EXERCISES'), findsOneWidget);
    expect(find.text('PREV'), findsOneWidget);
    expect(find.text('LAST'), findsOneWidget);
    expect(find.text('PREVIOUS'), findsNothing);
    expect(find.text('Wall Handstand'), findsOneWidget);
    expect(find.text('18s'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('±0'), findsOneWidget);
    // The per-row target line is gone; the day names itself and nothing else.
    expect(find.textContaining('3 × 30s'), findsNothing);
    // Only the levelled-up exercise wears the tag.
    expect(find.byType(LevelUpTag), findsOneWidget);
    expect(find.text('LVL UP'), findsOneWidget);
    expect(
      find
          .ancestor(of: find.text('Wall Handstand'), matching: find.byType(Row))
          .evaluate()
          .any((row) => find
              .descendant(
                  of: find.byWidget(row.widget),
                  matching: find.byType(LevelUpTag))
              .evaluate()
              .isNotEmpty),
      isTrue,
    );

    // A row is the way into its exercise.
    await tester.tap(find.text('Pull-ups'));
    expect(tapped?.exerciseId, 'pullups_pull_up');

    await tester.tap(find.text('Train something else'));
    expect(trainElse, isTrue);

    await tester.tap(find.text('Start'));
    expect(started, isTrue);
  });

  testWidgets('the value columns never spill, however long the number',
      (tester) async {
    const wide = [
      TodayWorkoutRow(
        exerciseId: 'plank',
        name: 'Plank',
        previousLabel: '10000s',
        changeLabel: '−1000',
        changeDir: -1,
      ),
      TodayWorkoutRow(
        exerciseId: 'squat',
        name: 'Squat (Barbell)',
        previousLabel: '15',
        changeLabel: '+1000',
        changeDir: 1,
      ),
    ];
    await tester
        .pumpWidget(host(TodayWorkoutCard(summary: summary(), rows: wide)));

    // No render overflow was reported (the test binding rethrows them), and
    // every value's painted box sits inside its column, flush right.
    expect(tester.takeException(), isNull);
    for (final (label, width) in [
      ('10000s', 46.0),
      ('−1000', 42.0),
      ('15', 46.0),
      ('+1000', 42.0),
    ]) {
      final text = find.text(label);
      expect(text, findsOneWidget);
      final textBox = tester.getRect(text);
      final cell = find.ancestor(of: text, matching: find.byType(FittedBox));
      final cellBox = tester.getRect(cell);
      expect(cellBox.width, width);
      expect(textBox.width, lessThanOrEqualTo(width + 0.01), reason: label);
      expect(textBox.right, closeTo(cellBox.right, 0.01), reason: label);
    }
  });

  testWidgets('shows completed state instead of Start', (tester) async {
    await tester.pumpWidget(
      host(
        TodayWorkoutActions(
          summary: summary(
            completed: const HomeCompletedWorkoutSummary(
              title: 'Pull Day',
              durationMinutes: 45,
              setCount: 12,
              exerciseCount: 5,
              nextSessionLabel: 'Push Day',
            ),
          ),
          onStart: () {},
        ),
      ),
    );

    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
  });

  testWidgets('captures a preview image of the today card', (tester) async {
    final key = GlobalKey();

    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: RepaintBoundary(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TodayWorkoutCard(
                  summary: summary(),
                  rows: rows,
                ),
                TodayWorkoutActions(
                  summary: summary(),
                  onStart: () {},
                  onTrainSomethingElse: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('build/today_workout_card_preview.png');
      out.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });

  group('leveledUpExerciseIds', () {
    ProgressionEvent activation(
      String exerciseId, {
      required DateTime at,
      int? valueFrom,
    }) {
      return ProgressionEvent(
        id: '$exerciseId-$at',
        exerciseId: exerciseId,
        kind: ProgressionEventKind.activated,
        createdAt: at,
        relatedExerciseId: 'previous',
        valueFrom: valueFrom,
      );
    }

    PastWorkout workout(List<String> exerciseIds, {required DateTime at}) {
      return PastWorkout(
        id: 'w-$at',
        title: 'Pull',
        sessionType: 'pull',
        startedAt: at,
        loggedAt: at,
        exercises: [
          for (final id in exerciseIds)
            PastWorkoutExercise(
              exerciseId: id,
              exerciseName: id,
              setCount: 3,
              totalReps: 18,
              totalTimedSeconds: 0,
              sets: const [],
            ),
        ],
      );
    }

    final day1 = DateTime(2026, 8, 10);
    final day2 = DateTime(2026, 8, 12);
    final day3 = DateTime(2026, 8, 14);

    test('an exercise the program stepped up onto is tagged until trained', () {
      final ids = TodayWorkoutContent.leveledUpExerciseIds(
        activations: [activation('pull_b', at: day2)],
        pastWorkouts: [
          workout(['pull_a'], at: day1)
        ],
      );
      expect(ids, {'pull_b'});
    });

    test('training the exercise once, after the step up, retires the tag', () {
      final ids = TodayWorkoutContent.leveledUpExerciseIds(
        activations: [activation('pull_b', at: day2)],
        pastWorkouts: [
          workout(['pull_a'], at: day1),
          workout(['pull_b'], at: day3),
        ],
      );
      expect(ids, isEmpty);
    });

    test('a log from before the step up does not count', () {
      final ids = TodayWorkoutContent.leveledUpExerciseIds(
        activations: [activation('pull_b', at: day2)],
        pastWorkouts: [
          workout(['pull_b'], at: day1)
        ],
      );
      expect(ids, {'pull_b'});
    });

    test('a manual fast-forward is not a level up', () {
      final ids = TodayWorkoutContent.leveledUpExerciseIds(
        activations: [activation('pull_b', at: day2, valueFrom: 6)],
        pastWorkouts: const [],
      );
      expect(ids, isEmpty);
    });
  });
}
