import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/widgets/polished.dart';
import 'package:forma_app/data/models/exercise_log_model.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/features/exercises/exercise_detail_view.dart';
import 'package:forma_app/features/exercises/exercise_summary_metrics.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('exercise summary metrics', () {
    test('reps exercises use total reps and best set', () {
      final metrics = summaryMetricsFor(_exercise());
      const sets = [
        ExerciseSet(reps: 8),
        ExerciseSet(reps: 11),
        ExerciseSet(reps: 6),
      ];

      expect(metrics, const [
        ExerciseSummaryMetric.totalReps,
        ExerciseSummaryMetric.bestSet,
      ]);
      expect(
        summaryMetricValue(ExerciseSummaryMetric.totalReps, sets),
        25,
      );
      expect(
        summaryMetricValue(ExerciseSummaryMetric.bestSet, sets),
        11,
      );
    });

    test('weighted exercises use weight, volume, and rep metrics', () {
      final metrics = summaryMetricsFor(_exercise(isWeighted: true));
      const sets = [
        ExerciseSet(reps: 8, weightKg: 60),
        ExerciseSet(reps: 6, weightKg: 70),
      ];

      expect(metrics, const [
        ExerciseSummaryMetric.heaviestWeight,
        ExerciseSummaryMetric.totalVolume,
        ExerciseSummaryMetric.totalReps,
      ]);
      expect(
        summaryMetricValue(ExerciseSummaryMetric.heaviestWeight, sets),
        70,
      );
      expect(
        summaryMetricValue(ExerciseSummaryMetric.totalVolume, sets),
        900,
      );
      expect(
        summaryMetricValue(ExerciseSummaryMetric.totalReps, sets),
        14,
      );
    });

    test('timed exercises use best and total time', () {
      final metrics = summaryMetricsFor(
        _exercise(isTimed: true, isWeighted: true),
      );
      const sets = [
        ExerciseSet(durationSeconds: 30, weightKg: 10),
        ExerciseSet(durationSeconds: 45, weightKg: 10),
      ];

      expect(metrics, const [
        ExerciseSummaryMetric.bestTime,
        ExerciseSummaryMetric.totalTime,
      ]);
      expect(
        summaryMetricValue(ExerciseSummaryMetric.bestTime, sets),
        45,
      );
      expect(
        summaryMetricValue(ExerciseSummaryMetric.totalTime, sets),
        75,
      );
    });
  });

  testWidgets('one logged session renders a graph and the new rep labels',
      (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      _host(
        exercise: _exercise(),
        logs: [
          ExerciseLog(
            id: 'log-1',
            exerciseId: 'test',
            loggedAt: now,
            sets: const [ExerciseSet(reps: 5), ExerciseSet(reps: 7)],
            totalReps: 12,
            totalVolumeKg: 0,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TOTAL REPS · LAST 3 MONTHS'), findsOneWidget);
    expect(find.text('Total reps'), findsAtLeastNWidgets(1));
    expect(find.text('Best set'), findsAtLeastNWidgets(1));
    expect(find.text('HISTORY'), findsOneWidget);
    expect(find.text('5 · 7 reps'), findsOneWidget);
    expect(find.text('PERSONAL RECORDS'), findsNothing);
    expect(find.textContaining('Log one more session'), findsNothing);
    expect(_chartValue(tester), 'S1 12');

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedTabs),
        matching: find.text('Best set'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BEST SET · LAST 3 MONTHS'), findsOneWidget);
    expect(_chartValue(tester), 'S1 7');
  });

  testWidgets('the live session point follows completed-set changes',
      (tester) async {
    final liveSets = ValueNotifier<List<ExerciseSet>>(const []);
    addTearDown(liveSets.dispose);

    await tester.pumpWidget(
      _host(
        exercise: _exercise(),
        logs: const [],
        liveSets: liveSets,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No completed sets yet'), findsOneWidget);

    liveSets.value = const [ExerciseSet(reps: 8)];
    await tester.pumpAndSettle();
    expect(find.textContaining('No completed sets yet'), findsNothing);
    expect(_chartValue(tester), 'Live 8');

    liveSets.value = const [ExerciseSet(reps: 10)];
    await tester.pumpAndSettle();
    expect(_chartValue(tester), 'Live 10');

    liveSets.value = const [];
    await tester.pumpAndSettle();
    expect(find.textContaining('No completed sets yet'), findsOneWidget);
  });

  testWidgets('weighted exercises expose all three requested graph buttons',
      (tester) async {
    await tester.pumpWidget(
      _host(
        exercise: _exercise(isWeighted: true),
        logs: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heaviest weight'), findsAtLeastNWidgets(1));
    expect(find.text('Total volume'), findsAtLeastNWidgets(1));
    expect(find.text('Total reps'), findsAtLeastNWidgets(1));
  });
}

String? _chartValue(WidgetTester tester) {
  final chart = tester.widget<Semantics>(
    find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == 'Exercise sessions chart',
    ),
  );
  return chart.properties.value;
}

Widget _host({
  required Exercise exercise,
  required List<ExerciseLog> logs,
  ValueListenable<List<ExerciseSet>>? liveSets,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ExerciseTrendsTab(
        logsFuture: Future.value(logs),
        exercise: exercise,
        liveSetsListenable: liveSets,
        liveSessionStartedAt: DateTime.now(),
      ),
    ),
  );
}

Exercise _exercise({bool isTimed = false, bool isWeighted = false}) {
  return Exercise(
    id: 'test',
    category: ExerciseCategory.other,
    name: 'Test exercise',
    description: 'Test exercise',
    difficulty: 1,
    treeOrder: 1,
    isTimed: isTimed,
    isWeighted: isWeighted,
  );
}
