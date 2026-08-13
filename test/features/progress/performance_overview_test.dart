import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/workout_history_model.dart';
import 'package:forma_app/features/progress/performance_overview.dart';

const _now = '2026-08-12';

DateTime _date(String iso) => DateTime.parse(iso);

ActivePerformanceExercise _active(String id, {bool isTimed = false}) =>
    ActivePerformanceExercise(
      exerciseId: id,
      exerciseName: id,
      isTimed: isTimed,
    );

PastWorkout _workout(
  String loggedAt,
  Map<String, List<int>> setsByExercise, {
  bool timed = false,
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
              ),
          ],
        ),
    ],
  );
}

void main() {
  group('14-day window comparison', () {
    // An old workout keeps every case out of the short-history fallback.
    final anchor = _workout('2026-06-01', {
      'anchor': [1],
    });

    test('classifies improving, no change, and needs attention', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('up'), _active('flat'), _active('down')],
        workouts: [
          anchor,
          // Previous window: Jul 16 – Jul 29.
          _workout('2026-07-20', {
            'up': [17, 15],
            'flat': [12],
            'down': [11, 9],
          }),
          // Current window: Jul 30 – Aug 12.
          _workout('2026-08-10', {
            'up': [21, 18],
            'flat': [12, 10],
            'down': [9],
          }),
        ],
        now: _date(_now),
      );

      expect(overview.comparesRecentSessions, isFalse);
      expect(overview.hasComparisons, isTrue);

      final up = overview.rowsFor(PerformanceTrend.improving).single;
      expect(up.exerciseId, 'up');
      expect(up.bestValue, 21);
      expect(up.delta, 4);

      final flat = overview.rowsFor(PerformanceTrend.noChange).single;
      expect(flat.bestValue, 12);
      expect(flat.delta, 0);

      final down = overview.rowsFor(PerformanceTrend.needsAttention).single;
      expect(down.bestValue, 9);
      expect(down.delta, -2);
    });

    test('best set within a window spans several sessions', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          anchor,
          _workout('2026-07-17', {
            'a': [10],
          }),
          _workout('2026-07-28', {
            'a': [14],
          }),
          _workout('2026-08-01', {
            'a': [12],
          }),
          _workout('2026-08-09', {
            'a': [15],
          }),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.bestValue, 15);
      expect(row.delta, 1);
    });

    test('one trained day in the span is still building its baseline', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          anchor,
          _workout('2026-08-05', {
            'a': [8],
          }),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.trend, PerformanceTrend.buildingBaseline);
      expect(row.bestValue, 8);
      expect(row.delta, isNull);
      expect(row.daysTrained, 1);
    });

    test('two trained days in the current window alone make a trend', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          anchor,
          _workout('2026-08-02', {
            'a': [8],
          }),
          _workout('2026-08-09', {
            'a': [11],
          }),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.trend, PerformanceTrend.improving);
      expect(row.bestValue, 11);
      expect(row.delta, 3);
    });

    test('two sessions on the same day do not make a baseline', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          anchor,
          _workout('2026-08-05T08:00:00', {
            'a': [8],
          }),
          _workout('2026-08-05T18:00:00', {
            'a': [10],
          }),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.trend, PerformanceTrend.buildingBaseline);
      expect(row.daysTrained, 1);
    });

    test('a trained day older than the 28-day span does not count toward '
        'the baseline', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          anchor,
          _workout('2026-07-05', {
            'a': [6],
          }),
          _workout('2026-07-20', {
            'a': [10],
          }),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.trend, PerformanceTrend.buildingBaseline);
      expect(row.bestValue, 10);
      expect(row.delta, isNull);
      expect(row.daysTrained, 1);
    });

    test('never-trained active exercise builds its baseline from zero days',
        () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [anchor],
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
          anchor,
          _workout('2026-07-20', {
            'kept': [10],
            'removed': [10],
          }),
          _workout('2026-08-10', {
            'kept': [12],
            'removed': [12],
          }),
        ],
        now: _date(_now),
      );

      expect(overview.rows.map((row) => row.exerciseId), ['kept']);
    });

    test('timed exercises compare hold seconds', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('plank', isTimed: true)],
        workouts: [
          anchor,
          _workout('2026-07-20', {
            'plank': [16],
          }, timed: true),
          _workout('2026-08-10', {
            'plank': [12],
          }, timed: true),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.isTimed, isTrue);
      expect(row.bestValue, 12);
      expect(row.delta, -4);
    });
  });

  group('short history (< 14 days of workouts)', () {
    test('compares the latest session against all earlier ones', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          _workout('2026-08-03', {
            'a': [10],
          }),
          _workout('2026-08-06', {
            'a': [14],
          }),
          _workout('2026-08-11', {
            'a': [13],
          }),
        ],
        now: _date(_now),
      );

      expect(overview.comparesRecentSessions, isTrue);
      final row = overview.rows.single;
      expect(row.trend, PerformanceTrend.needsAttention);
      expect(row.bestValue, 13);
      expect(row.delta, -1);
    });

    test('a single logged session is still building — nothing to compare yet',
        () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a')],
        workouts: [
          _workout('2026-08-10', {
            'a': [10],
          }),
        ],
        now: _date(_now),
      );

      final row = overview.rows.single;
      expect(row.trend, PerformanceTrend.buildingBaseline);
      expect(row.bestValue, 10);
      expect(row.daysTrained, 1);
      expect(overview.hasComparisons, isFalse);
    });

    test('a completely new user is all building baseline, no comparisons', () {
      final overview = buildPerformanceOverview(
        activeExercises: [_active('a'), _active('b')],
        workouts: const [],
        now: _date(_now),
      );

      expect(overview.comparesRecentSessions, isTrue);
      expect(overview.hasComparisons, isFalse);
      expect(
        overview.rows.map((row) => row.trend),
        everyElement(PerformanceTrend.buildingBaseline),
      );
    });
  });
}
