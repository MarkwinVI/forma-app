import '../../data/models/workout_history_model.dart';

/// Where an exercise's session volume is heading: last 14 days vs the 14
/// before. [buildingBaseline] means the exercise hasn't been trained on two
/// separate days inside the 28-day span yet, so there is nothing to compare.
enum PerformanceTrend { improving, noChange, needsAttention, buildingBaseline }

/// One exercise currently in the workout list, as the MY PERFORMANCE panel
/// needs it — identity plus how its sets are counted: reps, seconds, or
/// kilograms lifted (reps × load, summed over the sets).
class ActivePerformanceExercise {
  final String exerciseId;
  final String exerciseName;
  final bool isTimed;
  final bool isWeighted;

  const ActivePerformanceExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.isTimed,
    this.isWeighted = false,
  });
}

/// One row of the MY PERFORMANCE panel: the exercise's best session volume
/// in the current comparison window and how it moved against the previous.
///
/// A session's volume is its sets added up — total reps, total seconds, or
/// total kilograms lifted (reps × load per set) for a weighted movement — so
/// 4, 6, 3 is 13 reps and 5, 3, 2 is 10, and the second reads as 3 down.
class PerformanceRowData {
  final String exerciseId;
  final String exerciseName;
  final bool isTimed;
  final bool isWeighted;

  /// The session volume shown on the row — the current window's best, or
  /// the most recent for an exercise still building its baseline. 0 when
  /// the exercise has never been logged.
  final int bestValue;

  /// Volume movement against the comparison; null when the exercise has no
  /// baseline yet — the row files under BUILDING BASELINE.
  final int? delta;

  /// Distinct days the exercise was trained inside the 28-day span, capped
  /// at the two a baseline needs — drives the day counter on
  /// BUILDING BASELINE rows.
  final int daysTrained;

  const PerformanceRowData({
    required this.exerciseId,
    required this.exerciseName,
    required this.isTimed,
    this.isWeighted = false,
    required this.bestValue,
    this.delta,
    this.daysTrained = 0,
  });

  PerformanceTrend get trend {
    final delta = this.delta;
    if (delta == null) return PerformanceTrend.buildingBaseline;
    if (delta > 0) return PerformanceTrend.improving;
    if (delta < 0) return PerformanceTrend.needsAttention;
    return PerformanceTrend.noChange;
  }
}

/// Everything the MY PERFORMANCE panel renders, already classified.
class PerformanceOverview {
  /// All active exercises, in workout-list order.
  final List<PerformanceRowData> rows;

  /// True when history is shorter than a full comparison window, so rows
  /// compare the latest training day against the days before it instead of
  /// 14-day windows.
  final bool comparesRecentSessions;

  const PerformanceOverview({
    required this.rows,
    required this.comparesRecentSessions,
  });

  bool get isEmpty => rows.isEmpty;

  /// Whether any exercise has two points to compare. When false the panel
  /// drops the list entirely and explains how trends start.
  bool get hasComparisons => rows.any((row) => row.delta != null);

  List<PerformanceRowData> rowsFor(PerformanceTrend trend) =>
      [for (final row in rows) if (row.trend == trend) row];
}

/// Classifies every exercise currently in the workout list by how its
/// session volume moved: last 14 days vs the previous 14 days, each window
/// read at its best session. An exercise trained on two separate days inside
/// that 28-day span but not in both windows still gets a trend — its latest
/// trained day against the days before it. Fewer than two trained days in
/// the span leaves it building its baseline.
PerformanceOverview buildPerformanceOverview({
  required List<ActivePerformanceExercise> activeExercises,
  required List<PastWorkout> workouts,
  required DateTime now,
}) {
  final today = _dateOnly(now);
  final currentWindowStart = today.subtract(const Duration(days: 13));
  final previousWindowStart =
      currentWindowStart.subtract(const Duration(days: 14));

  // Every logged appearance of each active exercise, oldest first, each
  // read as one number: the session's volume in the exercise's own unit.
  final byId = {
    for (final exercise in activeExercises) exercise.exerciseId: exercise,
  };
  final ids = byId.keys.toSet();
  final sessionsByExercise = <String, List<_LoggedSession>>{};
  final sorted = [...workouts]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  var hasHistoryBeforeWindow = false;
  for (final workout in sorted) {
    final loggedAt = _dateOnly(workout.loggedAt);
    if (loggedAt.isAfter(today)) continue;
    if (loggedAt.isBefore(currentWindowStart)) hasHistoryBeforeWindow = true;
    for (final exercise in workout.exercises) {
      if (!ids.contains(exercise.exerciseId) || exercise.sets.isEmpty) {
        continue;
      }
      final volume = _sessionVolume(byId[exercise.exerciseId]!, exercise.sets);
      (sessionsByExercise[exercise.exerciseId] ??= [])
          .add(_LoggedSession(loggedAt, volume));
    }
  }

  final rows = <PerformanceRowData>[
    for (final exercise in activeExercises)
      _rowFor(
        exercise,
        sessionsByExercise[exercise.exerciseId] ?? const [],
        currentWindowStart: currentWindowStart,
        previousWindowStart: previousWindowStart,
      ),
  ];

  return PerformanceOverview(
    rows: rows,
    comparesRecentSessions: !hasHistoryBeforeWindow,
  );
}

/// A session's volume in the exercise's own unit: seconds held for a timed
/// movement, kilograms lifted (reps × load, summed) for a weighted one,
/// reps for everything else. Whole numbers — a kilogram total is rounded.
int _sessionVolume(
  ActivePerformanceExercise exercise,
  List<PastWorkoutSet> sets,
) {
  if (exercise.isWeighted && !exercise.isTimed) {
    return sets
        .fold<double>(0, (sum, set) => sum + set.value * set.weightKg)
        .round();
  }
  return sets.fold<int>(0, (sum, set) => sum + set.value);
}

/// One exercise's row. The standard comparison is the best session volume in
/// the last 14 days vs the 14 before; when only one window holds sessions
/// but the exercise still has two separate trained days in the span, the
/// latest day compares against the best of the earlier ones. Fewer than two
/// trained days files it under BUILDING BASELINE with its day count.
PerformanceRowData _rowFor(
  ActivePerformanceExercise exercise,
  List<_LoggedSession> sessions, {
  required DateTime currentWindowStart,
  required DateTime previousWindowStart,
}) {
  var currentBest = 0, previousBest = 0;
  var inCurrent = false, inPrevious = false;
  final inSpan = <_LoggedSession>[];
  final days = <DateTime>{};
  for (final session in sessions) {
    if (!session.date.isBefore(currentWindowStart)) {
      inCurrent = true;
      if (session.best > currentBest) currentBest = session.best;
    } else if (!session.date.isBefore(previousWindowStart)) {
      inPrevious = true;
      if (session.best > previousBest) previousBest = session.best;
    } else {
      continue;
    }
    inSpan.add(session);
    days.add(session.date);
  }

  if (inCurrent && inPrevious) {
    return _row(
      exercise,
      bestValue: currentBest,
      delta: currentBest - previousBest,
      daysTrained: 2,
    );
  }

  if (days.length >= 2) {
    // Both trained days sit in one window — the latest day still compares
    // against the best of the days before it.
    final latestDay =
        days.reduce((a, b) => a.isAfter(b) ? a : b);
    var latestBest = 0, earlierBest = 0;
    for (final session in inSpan) {
      if (session.date == latestDay) {
        if (session.best > latestBest) latestBest = session.best;
      } else if (session.best > earlierBest) {
        earlierBest = session.best;
      }
    }
    return _row(
      exercise,
      bestValue: latestBest,
      delta: latestBest - earlierBest,
      daysTrained: 2,
    );
  }

  // Still building a baseline — show the most recent best it ever logged.
  return _row(
    exercise,
    bestValue: sessions.isEmpty ? 0 : sessions.last.best,
    daysTrained: days.length,
  );
}

PerformanceRowData _row(
  ActivePerformanceExercise exercise, {
  required int bestValue,
  int? delta,
  required int daysTrained,
}) {
  return PerformanceRowData(
    exerciseId: exercise.exerciseId,
    exerciseName: exercise.exerciseName,
    isTimed: exercise.isTimed,
    isWeighted: exercise.isWeighted,
    bestValue: bestValue,
    delta: delta,
    daysTrained: daysTrained,
  );
}

class _LoggedSession {
  final DateTime date;
  final int best;

  const _LoggedSession(this.date, this.best);
}

DateTime _dateOnly(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);
