import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/models/progression_event_model.dart';
import '../../../data/models/workout_history_model.dart';
import '../home_dashboard_metrics.dart';

/// One planned exercise in today's session: what it totalled in the session
/// before last, and how the last session moved against that.
class TodayWorkoutRow {
  /// Empty when the row was built without a catalog exercise behind it.
  final String exerciseId;
  final String name;

  /// The session-before-last total: a bare count, or seconds ("18s").
  final String previousLabel;

  /// How the last session moved against it ("+3", "−2", "—").
  final String changeLabel;
  final int changeDir;

  /// The program moved the user onto this exercise and it has not been
  /// trained since — it wears a tag until it has: "Lvl up" for the next
  /// step of its own tree, "New" for the first step of a tree that took
  /// over a slot.
  final TodayRowTag? tag;

  const TodayWorkoutRow({
    this.exerciseId = '',
    required this.name,
    required this.previousLabel,
    required this.changeLabel,
    required this.changeDir,
    this.tag,
  });

  bool get leveledUp => tag != null;
}

/// Why a row in today's list wears a tag.
enum TodayRowTag { levelUp, newTree }

/// Derives the session list's rows from the dashboard metrics, so any screen
/// hosting it renders the same story.
class TodayWorkoutContent {
  TodayWorkoutContent._();

  static List<TodayWorkoutRow> rows(
    HomeDashboardMetrics metrics, {
    Map<String, TodayRowTag> rowTags = const {},
  }) {
    final perfByName = {
      for (final perf in metrics.exercisePerformance) perf.exerciseName: perf,
    };

    return [
      for (final planned in metrics.today.plannedExercises)
        _rowFor(
          planned,
          perfByName[planned.name],
          tag: rowTags[planned.exerciseId],
        ),
    ];
  }

  /// The exercises the program has moved the user onto — activated by
  /// mastering a step, not by a manual jump — that have not been logged
  /// since, each with the tag it wears: the next step of its own tree
  /// levelled up, the first step of a tree that took over a slot is new.
  /// Training the exercise once retires the tag, so a finished session
  /// clears every tag it carried.
  static Map<String, TodayRowTag> rowTags({
    required List<ProgressionEvent> activations,
    required List<PastWorkout> pastWorkouts,
  }) {
    final tags = <String, TodayRowTag>{};
    for (final id in leveledUpExerciseIds(
      activations: activations,
      pastWorkouts: pastWorkouts,
    )) {
      tags[id] = TodayRowTag.levelUp;
    }
    for (final event in activations) {
      if (!tags.containsKey(event.exerciseId)) continue;
      final from = event.relatedExerciseId == null
          ? null
          : ExerciseCatalog.findById(event.relatedExerciseId!);
      final to = ExerciseCatalog.findById(event.exerciseId);
      if (from != null &&
          to != null &&
          from.skillCategoryId.isNotEmpty &&
          from.skillCategoryId != to.skillCategoryId) {
        tags[event.exerciseId] = TodayRowTag.newTree;
      }
    }
    return tags;
  }

  /// Every exercise that wears a tag, whichever kind — see [rowTags].
  static Set<String> leveledUpExerciseIds({
    required List<ProgressionEvent> activations,
    required List<PastWorkout> pastWorkouts,
  }) {
    // Keyed by movement, so training the exercise under any of its ids
    // (the step, or its library twin from the catalogue) retires the tag.
    final lastLoggedAt = <String, DateTime>{};
    for (final workout in pastWorkouts) {
      for (final exercise in workout.exercises) {
        final movement = ExerciseCatalog.movementIdFor(exercise.exerciseId);
        final seen = lastLoggedAt[movement];
        if (seen == null || workout.loggedAt.isAfter(seen)) {
          lastLoggedAt[movement] = workout.loggedAt;
        }
      }
    }

    final ids = <String>{};
    for (final event in activations) {
      if (event.kind != ProgressionEventKind.activated) continue;
      // A manual fast-forward carries the target it jumped from; the
      // program's own step up does not.
      if (event.valueFrom != null) continue;
      final logged =
          lastLoggedAt[ExerciseCatalog.movementIdFor(event.exerciseId)];
      if (logged == null || logged.isBefore(event.createdAt)) {
        ids.add(event.exerciseId);
      }
    }
    return ids;
  }

  static TodayWorkoutRow _rowFor(
    HomePlannedExerciseSummary planned,
    HomeExercisePerformance? perf, {
    TodayRowTag? tag,
  }) {
    final history = perf?.history ?? const <int>[];
    final isTimed = perf?.isTimed ?? false;
    // The change is measured against the session before last, so that is the
    // total worth showing beside it — the last session is the two added up.
    final previous = history.length >= 2 ? history[history.length - 2] : null;
    final delta = perf?.sessionDelta;

    return TodayWorkoutRow(
      exerciseId: planned.exerciseId,
      name: planned.name,
      tag: tag,
      previousLabel: previous == null
          ? '—'
          : isTimed
              ? '${previous}s'
              : '$previous',
      changeLabel: delta == null
          ? '—'
          : delta == 0
              ? '±0'
              : delta > 0
                  ? '+$delta'
                  : '−${delta.abs()}',
      changeDir: delta == null ? 0 : delta.sign,
    );
  }
}

/// The pill beside an exercise the program has just moved the user onto.
/// Reads "LVL UP" — or "NEW", for the first step of a tree that took over
/// a slot — until the exercise has been trained once.
class LevelUpTag extends StatelessWidget {
  final TodayRowTag tag;

  const LevelUpTag({super.key, this.tag = TodayRowTag.levelUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.accentPrimary.withValues(alpha: 0.14),
        border: Border.all(
          color: AppColors.accentPrimary.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tag == TodayRowTag.newTree ? 'NEW' : 'LVL UP',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Color(0xFF7FA0FF),
          height: 1.3,
        ),
      ),
    );
  }
}
