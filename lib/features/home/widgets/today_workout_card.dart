import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/type_led.dart';
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

  /// The program moved the user onto this exercise by mastering the one
  /// before it, and it has not been trained since — it wears the "Lvl up"
  /// tag until it has.
  final bool leveledUp;

  const TodayWorkoutRow({
    this.exerciseId = '',
    required this.name,
    required this.previousLabel,
    required this.changeLabel,
    required this.changeDir,
    this.leveledUp = false,
  });
}

/// Derives the session list's rows from the dashboard metrics, so any screen
/// hosting it renders the same story.
class TodayWorkoutContent {
  TodayWorkoutContent._();

  static List<TodayWorkoutRow> rows(
    HomeDashboardMetrics metrics, {
    Set<String> leveledUpExerciseIds = const {},
  }) {
    final perfByName = {
      for (final perf in metrics.exercisePerformance) perf.exerciseName: perf,
    };

    return [
      for (final planned in metrics.today.plannedExercises)
        _rowFor(
          planned,
          perfByName[planned.name],
          leveledUp: leveledUpExerciseIds.contains(planned.exerciseId),
        ),
    ];
  }

  /// The exercises the program has levelled the user up onto — activated
  /// by mastering the step before, not by a manual jump — that have not
  /// been logged since. Training the exercise once retires the tag, so a
  /// finished session clears every tag it carried.
  static Set<String> leveledUpExerciseIds({
    required List<ProgressionEvent> activations,
    required List<PastWorkout> pastWorkouts,
  }) {
    final lastLoggedAt = <String, DateTime>{};
    for (final workout in pastWorkouts) {
      for (final exercise in workout.exercises) {
        final seen = lastLoggedAt[exercise.exerciseId];
        if (seen == null || workout.loggedAt.isAfter(seen)) {
          lastLoggedAt[exercise.exerciseId] = workout.loggedAt;
        }
      }
    }

    final ids = <String>{};
    for (final event in activations) {
      if (event.kind != ProgressionEventKind.activated) continue;
      // A manual fast-forward carries the target it jumped from; the
      // program's own step up does not.
      if (event.valueFrom != null) continue;
      final logged = lastLoggedAt[event.exerciseId];
      if (logged == null || logged.isBefore(event.createdAt)) {
        ids.add(event.exerciseId);
      }
    }
    return ids;
  }

  static TodayWorkoutRow _rowFor(
    HomePlannedExerciseSummary planned,
    HomeExercisePerformance? perf, {
    bool leveledUp = false,
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
      leveledUp: leveledUp,
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

/// Today's session on the Train tab, written as a list rather than boxed in a
/// card: the day names itself, then every exercise with what it last totalled
/// and how it moved. The actions live in [TodayWorkoutActions], pinned by the
/// tab so a long session never pushes Start below the fold.
class TodayWorkoutCard extends StatelessWidget {
  static const double _previousColWidth = 46;
  static const double _changeColWidth = 42;
  static const double _colGap = 10;

  final HomeTodaySummary summary;
  final List<TodayWorkoutRow> rows;

  /// A one-line note about the day, if there is one to give. Sits between
  /// the title and the table so it never becomes a second list.
  final Widget? note;

  /// Tapping a row opens the exercise behind it.
  final ValueChanged<TodayWorkoutRow>? onRowTap;

  const TodayWorkoutCard({
    super.key,
    required this.summary,
    required this.rows,
    this.note,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TypeTitle(summary.sessionTitle),
        if (note != null) note!,
        if (rows.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(top: 26),
            padding: const EdgeInsets.only(bottom: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(child: Text('EXERCISES', style: _headStyle)),
                const SizedBox(width: _colGap),
                SizedBox(
                  width: _previousColWidth,
                  child: Text(
                    'PREV',
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.right,
                    style: _headStyle,
                  ),
                ),
                const SizedBox(width: _colGap),
                SizedBox(
                  width: _changeColWidth,
                  child: Text(
                    'LAST',
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.right,
                    style: _headStyle,
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < rows.length; index++)
            _ExerciseRow(
              row: rows[index],
              last: index == rows.length - 1,
              onTap: onRowTap == null || rows[index].exerciseId.isEmpty
                  ? null
                  : () => onRowTap!(rows[index]),
            ),
        ],
      ],
    );
  }

  static final _headStyle = monoStyle(size: 11, letterSpacing: 1.76);
}

/// The way into today's session. Pinned above the tab bar rather than sitting
/// under the list — an eight-exercise session would otherwise scroll Start off
/// the screen.
class TodayWorkoutActions extends StatelessWidget {
  final HomeTodaySummary summary;
  final VoidCallback onStart;
  final VoidCallback? onTrainSomethingElse;

  const TodayWorkoutActions({
    super.key,
    required this.summary,
    required this.onStart,
    this.onTrainSomethingElse,
  });

  @override
  Widget build(BuildContext context) {
    final completed = summary.completed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (completed != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, size: 18, color: AppColors.green),
                SizedBox(width: 7),
                Text(
                  'Workout complete',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          )
        else
          PillButton(
            label: summary.isRestDay ? 'View plan' : 'Start',
            radius: 14,
            onTap: onStart,
          ),
        if (onTrainSomethingElse != null)
          Pressable(
            onTap: onTrainSomethingElse,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 14, bottom: 2),
              alignment: Alignment.center,
              child: Text(
                summary.isRestDay
                    ? 'Feeling fresh? Train something else'
                    : 'Train something else',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentPrimary,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final TodayWorkoutRow row;
  final bool last;
  final VoidCallback? onTap;

  const _ExerciseRow({required this.row, required this.last, this.onTap});

  @override
  Widget build(BuildContext context) {
    final changeColor = row.changeDir > 0
        ? AppColors.green
        : row.changeDir < 0
            ? AppColors.red
            : AppColors.textMuted;

    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                if (row.leveledUp) ...[
                  const SizedBox(width: 8),
                  const LevelUpTag(),
                ],
              ],
            ),
          ),
          const SizedBox(width: TodayWorkoutCard._colGap),
          SizedBox(
            width: TodayWorkoutCard._previousColWidth,
            child: Text(
              row.previousLabel,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: _valueStyle(AppColors.textMuted),
            ),
          ),
          const SizedBox(width: TodayWorkoutCard._colGap),
          SizedBox(
            width: TodayWorkoutCard._changeColWidth,
            // The signed number carries the direction on its own — an arrow
            // beside it is the same fact twice.
            child: Text(
              row.changeLabel,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: _valueStyle(changeColor),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Pressable(onTap: onTap, child: content);
  }

  static TextStyle _valueStyle(Color color) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.2,
      );
}

/// The pill beside an exercise the program has just levelled the user up
/// onto. Reads "LVL UP" until the exercise has been trained once.
class LevelUpTag extends StatelessWidget {
  const LevelUpTag({super.key});

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
      child: const Text(
        'LVL UP',
        style: TextStyle(
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
