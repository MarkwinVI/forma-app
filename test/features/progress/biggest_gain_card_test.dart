import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/workout_history_model.dart';
import 'package:forma_app/features/progress/widgets/biggest_gain_card.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  PastWorkout workout(
    String id,
    DateTime loggedAt,
    Map<String, (int, bool)> totals,
  ) {
    return PastWorkout(
      id: id,
      title: 'Session',
      sessionType: 'full_body',
      startedAt: loggedAt.subtract(const Duration(minutes: 45)),
      loggedAt: loggedAt,
      exercises: [
        for (final entry in totals.entries)
          PastWorkoutExercise(
            exerciseId: entry.key,
            exerciseName: entry.key,
            setCount: 1,
            totalReps: entry.value.$2 ? 0 : entry.value.$1,
            totalTimedSeconds: entry.value.$2 ? entry.value.$1 : 0,
            sets: [
              PastWorkoutSet(
                number: 1,
                value: entry.value.$1,
                isTimed: entry.value.$2,
              ),
            ],
          ),
      ],
    );
  }

  List<PastWorkout> sampleWorkouts() {
    final day = DateTime(2026, 7, 1);
    return [
      // Oldest → newest: handstand hold 14s → 20s (+43%), pull-ups flat,
      // l-sit 13 → 17 reps (+31%).
      workout('w1', day, {
        'handstand': (14, true),
        'pullups': (6, false),
        'lsit': (13, false),
      }),
      workout('w2', day.add(const Duration(days: 2)), {
        'handstand': (16, true),
        'pullups': (6, false),
        'lsit': (15, false),
      }),
      workout('w3', day.add(const Duration(days: 4)), {
        'handstand': (20, true),
        'pullups': (6, false),
        'lsit': (17, false),
      }),
    ];
  }

  test('ranks gains by relative improvement and flags personal bests', () {
    final data = BiggestGainData.compute(sampleWorkouts());

    expect(data, isNotNull);
    expect(data!.top.exerciseId, 'handstand');
    expect(data.top.first, 14);
    expect(data.top.last, 20);
    expect(data.top.deltaLabel, '+6s');
    expect(data.top.isPersonalBest, isTrue);
    expect(data.runnerUp?.exerciseId, 'lsit');
    expect(data.runnerUp?.deltaLabel, '+4');
  });

  test('returns null when nothing improved', () {
    final day = DateTime(2026, 7, 1);
    final data = BiggestGainData.compute([
      workout('w1', day, {'pullups': (8, false)}),
      workout('w2', day.add(const Duration(days: 2)), {'pullups': (7, false)}),
    ]);

    expect(data, isNull);
  });

  Widget host(GlobalKey key, BiggestGainData data) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF111114),
        body: Center(
          child: SizedBox(
            width: 370,
            child: RepaintBoundary(
              key: key,
              child: BiggestGainCard(data: data, skills: const []),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders the top gain with chips and runner-up',
      (tester) async {
    final data = BiggestGainData.compute(sampleWorkouts())!;

    await tester.pumpWidget(host(GlobalKey(), data));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('BIGGEST GAIN'), findsOneWidget);
    expect(find.text('+6s'), findsOneWidget);
    expect(find.text('Personal best'), findsOneWidget);
    expect(find.text('+4'), findsOneWidget);
  });

  testWidgets('captures a preview image', (tester) async {
    final data = BiggestGainData.compute(sampleWorkouts())!;
    final key = GlobalKey();

    await tester.pumpWidget(host(key, data));
    await tester.pump();

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('build/biggest_gain_card_preview.png');
      out.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
