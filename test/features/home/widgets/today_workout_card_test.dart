import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
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
      name: 'Wall Handstand',
      previousLabel: '18s',
      changeLabel: '+2',
      changeDir: 1,
    ),
    TodayWorkoutRow(
      name: 'Pull-ups',
      previousLabel: '24 reps',
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

  testWidgets('shows plan rows with the last and change columns',
      (tester) async {
    var started = false;
    var trainElse = false;
    await tester.pumpWidget(
      host(
        Column(
          children: [
            TodayWorkoutCard(
              summary: summary(),
              subtitle: '5 exercises · targets your stalled Pull-up node',
              rows: rows,
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
    expect(find.text('THE SESSION'), findsOneWidget);
    expect(find.text('PREVIOUS'), findsOneWidget);
    expect(find.text('LAST'), findsOneWidget);
    expect(find.text('CHANGE'), findsNothing);
    expect(find.text('Wall Handstand'), findsOneWidget);
    expect(find.text('18s'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('±0'), findsOneWidget);
    // The per-row target line is gone; the subtitle carries the stall note.
    expect(find.textContaining('3 × 30s'), findsNothing);

    await tester.tap(find.text('Train something else'));
    expect(trainElse, isTrue);

    await tester.tap(find.text('Start'));
    expect(started, isTrue);
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
                  subtitle: '5 exercises · targets your stalled Pull-up node',
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
}
