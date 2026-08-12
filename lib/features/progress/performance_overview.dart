import '../../data/models/workout_history_model.dart';

/// Where an exercise's best set is heading: last 14 days vs the 14 before.
enum PerformanceTrend { improving, noChange, needsAttention, fresh }

/// One exercise currently in the workout list, as the MY PERFORMANCE panel
/// needs it — identity plus how its sets are counted.
class ActivePerformanceExercise {
  final String exerciseId;
  final String exerciseName;
  final bool isTimed;

  const ActivePerformanceExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.isTimed,
  });
}

/// One row of the MY PERFORMANCE panel: the exercise's best set in the
/// current comparison window and how it moved against the previous one.
class PerformanceRowData {
  final String exerciseId;
  final String exerciseName;
  final bool isTimed;

  /// Best single-set value (reps or seconds) shown on the row — the current
  /// window's best, or the most recent logged best for a [fresh] exercise.
  /// 0 when the exercise has never been logged.
  final int bestValue;

  /// Best-set movement against the previous window; null when there is
  /// nothing to compare against — the row files under NEW.
  final int? delta;

  const PerformanceRowData({
    required this.exerciseId,
    required this.exerciseName,
    required this.isTimed,
    required this.bestValue,
    this.delta,
  });

  PerformanceTrend get trend {
    final delta = this.delta;
    if (delta == null) return PerformanceTrend.fresh;
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
  /// compare the latest session against the sessions before it instead of
  /// 14-day windows.
  final bool comparesRecentSessions;

  const PerformanceOverview({
    required this.rows,
    required this.comparesRecentSessions,
  });

  bool get isEmpty => rows.isEmpty;

  /// Whether any exercise has two points to compare. When false the panel
  /// shows everything under NEW with the "train a bit first" note.
  bool get hasComparisons => rows.any((row) => row.delta != null);

  List<PerformanceRowData> rowsFor(PerformanceTrend trend) =>
      [for (final row in rows) if (row.trend == trend) row];
}

/// Classifies every exercise currently in the workout list by how its best
/// set moved: last 14 days vs the previous 14 days. Users whose whole history
/// fits inside one window get their latest session compared against all the
/// sessions before it instead.
PerformanceOverview buildPerformanceOverview({
  required List<ActivePerformanceExercise> activeExercises,
  required List<PastWorkout> workouts,
  required DateTime now,
}) {
  final today = _dateOnly(now);
  final currentWindowStart = today.subtract(const Duration(days: 13));

  // Every logged appearance of each active exercise, oldest first.
  final ids = {for (final exercise in activeExercises) exercise.exerciseId};
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
      final bestSet = exercise.sets
          .fold<int>(0, (best, set) => set.value > best ? set.value : best);
      (sessionsByExercise[exercise.exerciseId] ??= [])
          .add(_LoggedSession(loggedAt, bestSet));
    }
  }

  // History shorter than a full window can't fill the previous window for
  // anything — fall back to latest-session-vs-earlier within what exists.
  final comparesRecentSessions = !hasHistoryBeforeWindow;

  final rows = <PerformanceRowData>[
    for (final exercise in activeExercises)
      comparesRecentSessions
          ? _recentSessionsRow(
              exercise,
              sessionsByExercise[exercise.exerciseId] ?? const [],
            )
          : _windowedRow(
              exercise,
              sessionsByExercise[exercise.exerciseId] ?? const [],
              currentWindowStart: currentWindowStart,
            ),
  ];

  return PerformanceOverview(
    rows: rows,
    comparesRecentSessions: comparesRecentSessions,
  );
}

/// The standard comparison: best set in the last 14 days vs the 14 before.
/// No sessions in either window files the exercise under NEW.
PerformanceRowData _windowedRow(
  ActivePerformanceExercise exercise,
  List<_LoggedSession> sessions, {
  required DateTime currentWindowStart,
}) {
  final previousWindowStart =
      currentWindowStart.subtract(const Duration(days: 14));

  var currentBest = 0, previousBest = 0;
  var inCurrent = false, inPrevious = false;
  for (final session in sessions) {
    if (!session.date.isBefore(currentWindowStart)) {
      inCurrent = true;
      if (session.best > currentBest) currentBest = session.best;
    } else if (!session.date.isBefore(previousWindowStart)) {
      inPrevious = true;
      if (session.best > previousBest) previousBest = session.best;
    }
  }

  if (!inCurrent || !inPrevious) {
    // Untrained these 14 days, or nothing in the window before them —
    // show the most recent best it ever logged, with no delta.
    return _row(
      exercise,
      bestValue: inCurrent
          ? currentBest
          : (sessions.isEmpty ? 0 : sessions.last.best),
    );
  }
  return _row(
    exercise,
    bestValue: currentBest,
    delta: currentBest - previousBest,
  );
}

/// The short-history fallback: the latest session's best set against the
/// best across every session before it.
PerformanceRowData _recentSessionsRow(
  ActivePerformanceExercise exercise,
  List<_LoggedSession> sessions,
) {
  if (sessions.length < 2) {
    return _row(
      exercise,
      bestValue: sessions.isEmpty ? 0 : sessions.last.best,
    );
  }
  final latest = sessions.last.best;
  final earlierBest = sessions
      .take(sessions.length - 1)
      .fold<int>(0, (best, session) => session.best > best ? session.best : best);
  return _row(exercise, bestValue: latest, delta: latest - earlierBest);
}

PerformanceRowData _row(
  ActivePerformanceExercise exercise, {
  required int bestValue,
  int? delta,
}) {
  return PerformanceRowData(
    exerciseId: exercise.exerciseId,
    exerciseName: exercise.exerciseName,
    isTimed: exercise.isTimed,
    bestValue: bestValue,
    delta: delta,
  );
}

class _LoggedSession {
  final DateTime date;
  final int best;

  const _LoggedSession(this.date, this.best);
}

DateTime _dateOnly(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);
