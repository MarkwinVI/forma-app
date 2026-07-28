import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/type_led.dart';
import '../home_dashboard_metrics.dart';

/// One planned exercise in today's session: what it totalled in the session
/// before last, and how the last session moved against that.
class TodayWorkoutRow {
  final String name;

  /// The session-before-last total, written with its unit ("15 reps", "18s").
  final String previousLabel;

  /// How the last session moved against it ("+3", "−2", "—").
  final String changeLabel;
  final int changeDir;

  const TodayWorkoutRow({
    required this.name,
    required this.previousLabel,
    required this.changeLabel,
    required this.changeDir,
  });
}

/// Derives the session list's rows, subtitle, and tip from the dashboard
/// metrics, so any screen hosting it renders the same story.
class TodayWorkoutContent {
  TodayWorkoutContent._();

  static List<TodayWorkoutRow> rows(HomeDashboardMetrics metrics) {
    final perfByName = {
      for (final perf in metrics.exercisePerformance) perf.exerciseName: perf,
    };

    return [
      for (final planned in metrics.today.plannedExercises)
        _rowFor(planned, perfByName[planned.name]),
    ];
  }

  static TodayWorkoutRow _rowFor(
    HomePlannedExerciseSummary planned,
    HomeExercisePerformance? perf,
  ) {
    final history = perf?.history ?? const <int>[];
    final isTimed = perf?.isTimed ?? false;
    // The change is measured against the session before last, so that is the
    // total worth showing beside it — the last session is the two added up.
    final previous =
        history.length >= 2 ? history[history.length - 2] : null;
    final delta = perf?.sessionDelta;

    return TodayWorkoutRow(
      name: planned.name,
      previousLabel: previous == null
          ? '—'
          : isTimed
              ? '${previous}s'
              : '$previous reps',
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

  static String subtitle(HomeDashboardMetrics metrics) {
    final summary = metrics.today;
    if (summary.isRestDay) {
      return 'Rest day — recovery keeps the split moving';
    }

    final count = '${summary.exerciseCount} exercise'
        '${summary.exerciseCount == 1 ? '' : 's'}';
    for (final path in metrics.activeSkillPaths) {
      if (path.momentum == HomeSkillMomentum.stalled) {
        return '$count · targets your stalled ${path.skillTitle} node';
      }
    }
    return '$count · built from your current program';
  }
}

/// Today's session on the Train tab, written as a list rather than boxed in a
/// card: the day names itself, then every exercise with what it last totalled
/// and how it moved, then the way in.
class TodayWorkoutCard extends StatelessWidget {
  static const double _previousColWidth = 84;
  static const double _changeColWidth = 58;

  final HomeTodaySummary summary;
  final String subtitle;
  final List<TodayWorkoutRow> rows;
  final VoidCallback onStart;
  final VoidCallback? onTrainSomethingElse;

  const TodayWorkoutCard({
    super.key,
    required this.summary,
    required this.subtitle,
    required this.rows,
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
        TypeTitle(summary.sessionTitle, sub: subtitle),
        if (rows.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 30, 0, 6),
            child: Row(
              children: [
                Expanded(child: Text('THE SESSION', style: _headStyle)),
                SizedBox(
                  width: _previousColWidth,
                  child: Text('PREVIOUS', style: _headStyle),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: _changeColWidth,
                  child: Text(
                    'LAST',
                    textAlign: TextAlign.right,
                    style: _headStyle,
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < rows.length; index++)
            _ExerciseRow(row: rows[index], last: index == rows.length - 1),
        ],
        const SizedBox(height: 34),
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
              padding: const EdgeInsets.only(top: 18, bottom: 4),
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

  static final _headStyle = monoStyle(size: 11, letterSpacing: 1.5);
}

class _ExerciseRow extends StatelessWidget {
  final TodayWorkoutRow row;
  final bool last;

  const _ExerciseRow({required this.row, required this.last});

  @override
  Widget build(BuildContext context) {
    final changeColor = row.changeDir > 0
        ? AppColors.green
        : row.changeDir < 0
            ? AppColors.red
            : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.only(top: 17, bottom: 18),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.42,
                height: 1.15,
              ),
            ),
          ),
          SizedBox(
            width: TodayWorkoutCard._previousColWidth,
            child: Text(
              row.previousLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(
                size: 14,
                weight: FontWeight.w500,
                letterSpacing: 0,
                color: row.previousLabel == '—'
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: TodayWorkoutCard._changeColWidth,
            // The signed number carries the direction on its own — an arrow
            // beside it is the same fact twice.
            child: Text(
              row.changeLabel,
              textAlign: TextAlign.right,
              style: monoStyle(size: 14, letterSpacing: 0, color: changeColor),
            ),
          ),
        ],
      ),
    );
  }
}
