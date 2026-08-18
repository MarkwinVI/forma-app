import '../../data/models/workout_history_model.dart';

/// Where an exercise's session volume is heading: the last session against
/// the one before it. [buildingBaseline] means the exercise has not been
/// trained on two separate days yet, so there is nothing to compare.
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

/// One row of the MY PERFORMANCE panel: the exercise's last session volume
/// and how it moved against the session before.
///
/// A session's volume is its sets added up — total reps, total seconds, or
/// total kilograms lifted (reps × load per set) for a weighted movement — so
/// 4, 6, 3 is 13 reps and 5, 3, 2 is 10, and the second reads as 3 down.
class PerformanceRowData {
  final String exerciseId;
  final String exerciseName;
  final bool isTimed;
  final bool isWeighted;

  /// The last session's volume — always the latest, however long ago. 0
  /// when the exercise has never been logged.
  final int bestValue;

  /// The last session against the one before it; null when there is no
  /// session before it — the row files under BUILDING BASELINE.
  final int? delta;

  /// Distinct days the exercise has been trained, capped at the two a
  /// comparison needs — drives the day counter on BUILDING BASELINE rows.
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

  const PerformanceOverview({required this.rows});

  bool get isEmpty => rows.isEmpty;

  /// Whether any exercise has two points to compare. When false the panel
  /// drops the list entirely and explains how trends start.
  bool get hasComparisons => rows.any((row) => row.delta != null);

  List<PerformanceRowData> rowsFor(PerformanceTrend trend) =>
      [for (final row in rows) if (row.trend == trend) row];
}

/// Classifies every exercise currently in the workout list by how its last
/// session's volume moved against the session before it — whether that was
/// two days ago or two weeks. Two sessions on one day read as that day's
/// best. Fewer than two trained days leaves the exercise building its
/// baseline.
PerformanceOverview buildPerformanceOverview({
  required List<ActivePerformanceExercise> activeExercises,
  required List<PastWorkout> workouts,
  required DateTime now,
}) {
  final today = _dateOnly(now);

  // Each active exercise's volume per trained day, oldest day first.
  final byId = {
    for (final exercise in activeExercises) exercise.exerciseId: exercise,
  };
  final volumeByDay = <String, Map<DateTime, int>>{};
  for (final workout in workouts) {
    final day = _dateOnly(workout.loggedAt);
    if (day.isAfter(today)) continue;
    for (final exercise in workout.exercises) {
      final active = byId[exercise.exerciseId];
      if (active == null || exercise.sets.isEmpty) continue;
      final volume = _sessionVolume(active, exercise.sets);
      final days = volumeByDay[exercise.exerciseId] ??= {};
      final already = days[day];
      if (already == null || volume > already) days[day] = volume;
    }
  }

  return PerformanceOverview(
    rows: [
      for (final exercise in activeExercises)
        _rowFor(exercise, volumeByDay[exercise.exerciseId] ?? const {}),
    ],
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

/// One exercise's row: the last trained day's volume, against the day
/// before it. One trained day — or none — is still building its baseline.
PerformanceRowData _rowFor(
  ActivePerformanceExercise exercise,
  Map<DateTime, int> volumeByDay,
) {
  final days = volumeByDay.keys.toList()..sort();
  if (days.length < 2) {
    return _row(
      exercise,
      bestValue: days.isEmpty ? 0 : volumeByDay[days.last]!,
      daysTrained: days.length,
    );
  }
  final latest = volumeByDay[days[days.length - 1]]!;
  final previous = volumeByDay[days[days.length - 2]]!;
  return _row(
    exercise,
    bestValue: latest,
    delta: latest - previous,
    daysTrained: 2,
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

DateTime _dateOnly(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);
