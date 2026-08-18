import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/workout_history_model.dart';
import 'package:forma_app/features/progress/performance_overview.dart';

const _now = '2026-08-12';

DateTime _date(String iso) => DateTime.parse(iso);

ActivePerformanceExercise _active(
  String id, {
  bool isTimed = false,
  bool isWeighted = false,
}) =>
    ActivePerformanceExercise(
      exerciseId: id,
      exerciseName: id,
      isTimed: isTimed,
      isWeighted: isWeighted,
    );

PastWorkout _workout(
  String loggedAt,
  Map<String, List<int>> setsByExercise, {
  bool timed = false,
  Map<String, List<double>> weightsByExercise = const {},
}) {
  return PastWorkout(
    id: loggedAt,
    title: 'Full Body',
    sessionType: 'full_body',
    startedAt: _date(loggedAt),
    loggedAt: _date(loggedAt),
    exercises: [
      for (final entry in setsByExercise.entries)
        PastWorkoutExercise(
          exerciseId: entry.key,
          exerciseName: entry.key,
          setCount: entry.value.length,
          totalReps: timed ? 0 : entry.value.fold(0, (a, b) => a + b),
          totalTimedSeconds:
              timed ? entry.value.fold(0, (a, b) => a + b) : 0,
          sets: [
            for (var i = 0; i < entry.value.length; i++)
              PastWorkoutSet(
                number: i + 1,
                value: entry.value[i],
                isTimed: timed,
                weightKg: weightsByExercise[entry.key]?[i] ?? 0,
              ),
          ],
        ),
    ],
  );
}

void main() {
  group('last session against the one before', () {
    test('classifies improving, no change, and declining', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('up'), _active('flat'), _active('down')],
        workouts: [
          _workout('2026-07-20', {
            'up': [17, 15],
            'flat': [12, 10],
            'down': [11, 9],
          }),
          _workout('2026-08-10', {
            'up': [21, 18],
            // The same 22 in a different shape — flat is about the total.
            'flat': [8, 8, 6],
            'down': [9],
          }),
        ],
        now: _date(_now),
      );

      expect(overview.hasComparisons, isTrue);

      // A session is its sets added up: 17 + 15 = 32, then 21 + 18 = 39.
      final up = overview.rowsFor(PerformanceTrend.improving).single;
      expect(up.exerciseId, 'up');
      expect(up.bestValue, 39);
      expect(up.delta, 7);

      final flat = overview.rowsFor(PerformanceTrend.noChange).single;
      expect(flat.bestValue, 22);
      expect(flat.delta, 0);

      // 11 + 9 = 20, then 9: down by 11.
      final down = overview.rowsFor(PerformanceTrend.needsAttention).single;
      expect(down.bestValue, 9);
      expect(down.delta, -11);
    });

    test('a session is judged on its total, not its best set', () {
      // Day A: 4, 6, 3 = 13. Day B: 5, 3, 2 = 10 — three reps down.
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          _workout('2026-07-20', {
            'a': [4, 6, 3],
          }),
          _workout('2026-08-10', {
            'a': [5, 3, 2],
          }),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.bestValue, 10);
      expect(row.delta, -3);
      expect(row.trend, PerformanceTrend.needsAttention);
    });

    test('the value is the last session, and the delta is against the one '
        'before it — never a better session further back', () {
      // 10, then a strong 15, then 12: the row reads 12, down 3 on the 15
      // — not up 2 on the 10, and not the 15.
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          _workout('2026-07-28', {
            'a': [10],
          }),
          _workout('2026-08-01', {
            'a': [15],
          }),
          _workout('2026-08-09', {
            'a': [12],
          }),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.bestValue, 12);
      expect(row.delta, -3);
    });

    test('a bigger last session than the one before is a positive delta', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          _workout('2026-08-05', {
            'a': [8, 8, 7],
          }),
          _workout('2026-08-11', {
            'a': [9, 8, 8],
          }),
        ],
        now: _date(_now),
      );

      expect(overview.rows.single.delta, 2);
      expect(overview.rows.single.trend, PerformanceTrend.improving);
    });

    test('the gap between the two sessions does not matter', () {
      // Two days apart or two months apart, it is the same comparison.
      for (final earlier in ['2026-08-09', '2026-06-01']) {
        final overview = buildPerformanceOverview(
          activeExercises: [_active('a')],
          workouts: [
            _workout(earlier, {
              'a': [10],
            }),
            _workout('2026-08-11', {
              'a': [12],
            }),
          ],
          now: _date(_now),
        );
        expect(overview.rows.single.delta, 2, reason: earlier);
      }
    });

    test('a weighted movement is judged on kilograms lifted', () {
      // 3 × 10 kg × 8 = 240 kg, then 3 × 12 kg × 8 = 288 kg: up 48.
      final overview = buildPerformanceOverview(
        activeExercises: [_active('row', isWeighted: true)],
        workouts: [
          _workout(
            '2026-07-20',
            {'row': [8, 8, 8]},
            weightsByExercise: {'row': [10, 10, 10]},
          ),
          _workout(
            '2026-08-10',
            {'row': [8, 8, 8]},
            weightsByExercise: {'row': [12, 12, 12]},
          ),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.bestValue, 288);
      expect(row.delta, 48);
    });

    test('a hold is judged on total seconds', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('hold', isTimed: true)],
        workouts: [
          _workout('2026-07-20', {'hold': [20, 20, 15]}, timed: true),
          _workout('2026-08-10', {'hold': [25, 20, 20]}, timed: true),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.bestValue, 65);
      expect(row.delta, 10);
    });

    test('two sessions on one day are that day\'s best, and one day', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          _workout('2026-08-10T09:00', {
            'a': [10],
          }),
          _workout('2026-08-10T18:00', {
            'a': [12],
          }),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.trend, PerformanceTrend.buildingBaseline);
      expect(row.bestValue, 12);
      expect(row.daysTrained, 1);
    });

    test('a session dated after today is not counted', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          _workout('2026-08-01', {
            'a': [10],
          }),
          _workout('2026-08-20', {
            'a': [30],
          }),
        ],
        now: _date(_now),
      );

      expect(overview.rows.single.trend, PerformanceTrend.buildingBaseline);
      expect(overview.rows.single.bestValue, 10);
    });
  });

  group('building a baseline', () {
    test('one trained day is still building its baseline', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          _workout('2026-08-09', {
            'a': [15],
          }),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.trend, PerformanceTrend.buildingBaseline);
      expect(row.delta, isNull);
      expect(row.bestValue, 15);
      expect(row.daysTrained, 1);
      expect(overview.hasComparisons, isFalse);
    });

    test('a never-trained active exercise builds its baseline from zero days',
        () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: const [],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.trend, PerformanceTrend.buildingBaseline);
      expect(row.bestValue, 0);
      expect(row.daysTrained, 0);
    });

    test('removed exercises simply are not passed in', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('kept')],
        workouts: [
          _workout('2026-08-01', {
            'kept': [10],
            'gone': [10],
          }),
          _workout('2026-08-09', {
            'kept': [12],
            'gone': [12],
          }),
        ],
        now: _date(_now),
      );

      expect(overview.rows.map((row) => row.exerciseId), ['kept']);
    });
  });
}
