import '../../data/models/exercise_log_model.dart';
import '../../data/models/exercise_model.dart';

enum ExerciseSummaryMetric {
  totalReps,
  bestSet,
  heaviestWeight,
  totalVolume,
  bestTime,
  totalTime,
}

extension ExerciseSummaryMetricX on ExerciseSummaryMetric {
  String get label => switch (this) {
        ExerciseSummaryMetric.totalReps => 'Total reps',
        ExerciseSummaryMetric.bestSet => 'Best set',
        ExerciseSummaryMetric.heaviestWeight => 'Top weight',
        ExerciseSummaryMetric.totalVolume => 'Total volume',
        ExerciseSummaryMetric.bestTime => 'Best time',
        ExerciseSummaryMetric.totalTime => 'Total time',
      };

  String get definition => switch (this) {
        ExerciseSummaryMetric.totalReps =>
          'Total reps completed in each exercise session',
        ExerciseSummaryMetric.bestSet =>
          'Highest rep count in one completed set',
        ExerciseSummaryMetric.heaviestWeight =>
          'Highest weight used in one completed set',
        ExerciseSummaryMetric.totalVolume =>
          'Reps × weight across all completed sets',
        ExerciseSummaryMetric.bestTime =>
          'Longest completed hold in each exercise session',
        ExerciseSummaryMetric.totalTime =>
          'Total hold time across all completed sets',
      };
}

List<ExerciseSummaryMetric> summaryMetricsFor(Exercise exercise) {
  if (exercise.isTimed) {
    return const [
      ExerciseSummaryMetric.bestTime,
      ExerciseSummaryMetric.totalTime,
    ];
  }
  if (exercise.isWeighted) {
    // Volume first: it is what a session's work adds up to, and what the
    // performance panel reads.
    return const [
      ExerciseSummaryMetric.totalVolume,
      ExerciseSummaryMetric.heaviestWeight,
      ExerciseSummaryMetric.totalReps,
    ];
  }
  return const [
    ExerciseSummaryMetric.totalReps,
    ExerciseSummaryMetric.bestSet,
  ];
}

double summaryMetricValue(
  ExerciseSummaryMetric metric,
  List<ExerciseSet> sets,
) {
  switch (metric) {
    case ExerciseSummaryMetric.totalReps:
      return sets.fold<double>(0, (sum, set) => sum + set.reps);
    case ExerciseSummaryMetric.bestSet:
      return sets.fold<double>(
        0,
        (best, set) => set.reps > best ? set.reps.toDouble() : best,
      );
    case ExerciseSummaryMetric.heaviestWeight:
      return sets.fold<double>(
        0,
        (best, set) => set.weightKg > best ? set.weightKg : best,
      );
    case ExerciseSummaryMetric.totalVolume:
      return sets.fold<double>(
        0,
        (sum, set) => sum + set.reps * set.weightKg,
      );
    case ExerciseSummaryMetric.bestTime:
      return sets.fold<double>(
        0,
        (best, set) =>
            set.durationSeconds > best ? set.durationSeconds.toDouble() : best,
      );
    case ExerciseSummaryMetric.totalTime:
      return sets.fold<double>(
        0,
        (sum, set) => sum + set.durationSeconds,
      );
  }
}
