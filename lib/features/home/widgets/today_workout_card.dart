import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../home_dashboard_metrics.dart';

/// One planned exercise in today's session, with the result of the last
/// session it was trained and the change vs the session before that.
class TodayWorkoutRow {
  final String name;
  final String setsLabel;
  final bool stalled;
  final String lastLabel;
  final String changeLabel;
  final int changeDir;

  const TodayWorkoutRow({
    required this.name,
    required this.setsLabel,
    required this.stalled,
    required this.lastLabel,
    required this.changeLabel,
    required this.changeDir,
  });
}

/// Derives the Today card's rows, subtitle, and tip from the dashboard
/// metrics, so any screen hosting the card renders the same story.
class TodayWorkoutContent {
  TodayWorkoutContent._();

  static List<TodayWorkoutRow> rows(HomeDashboardMetrics metrics) {
    final perfByName = {
      for (final perf in metrics.exercisePerformance) perf.exerciseName: perf,
    };
    final stalledNames = {
      for (final path in metrics.activeSkillPaths)
        if (path.momentum == HomeSkillMomentum.stalled)
          path.currentExerciseName,
    };

    return [
      for (final planned in metrics.today.plannedExercises)
        _rowFor(
          planned,
          perfByName[planned.name],
          stalledNames.contains(planned.name),
        ),
    ];
  }

  static TodayWorkoutRow _rowFor(
    HomePlannedExerciseSummary planned,
    HomeExercisePerformance? perf,
    bool stalled,
  ) {
    final history = perf?.history ?? const <int>[];
    final unit = (perf?.isTimed ?? false) ? 's' : '';
    final delta = perf?.sessionDelta;

    return TodayWorkoutRow(
      name: planned.name,
      setsLabel: planned.targetLabel,
      stalled: stalled,
      lastLabel: history.isEmpty ? '—' : '${history.last}$unit',
      changeLabel: delta == null
          ? '—'
          : delta == 0
              ? '±0'
              : delta > 0
                  ? '+$delta$unit'
                  : '−${delta.abs()}$unit',
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

  /// (highlight, body) for the tip card, from the most pressing momentum
  /// signal across the active skill paths.
  static (String, String) tip(HomeDashboardMetrics metrics) {
    if (metrics.today.isRestDay) {
      return (
        'Rest is part of the program.',
        'Recovery today means better numbers in your next session.',
      );
    }

    final perfByName = {
      for (final perf in metrics.exercisePerformance) perf.exerciseName: perf,
    };
    for (final path in metrics.activeSkillPaths) {
      if (path.momentum != HomeSkillMomentum.stalled) continue;
      final perf = perfByName[path.currentExerciseName];
      final at = perf != null && perf.history.isNotEmpty
          ? ' at ${perf.history.last}${perf.isTimed ? 's' : ' reps'}'
          : '';
      return (
        'Your ${path.currentExerciseName} has stalled$at.',
        'Focus on clean, full-range reps today — quality sets are what '
            'break the plateau.',
      );
    }
    for (final path in metrics.activeSkillPaths) {
      if (path.momentum != HomeSkillMomentum.improving) continue;
      return (
        'Your ${path.currentExerciseName} is trending up.',
        "Keep the momentum — hitting today's targets brings the next "
            'node closer.',
      );
    }
    return (
      'Consistency beats intensity.',
      "Show up for today's session and every tree on this page keeps "
          'growing.',
    );
  }
}

/// "Today's workout" card on the Train tab — the planned exercises as a
/// performance list: EXERCISE / LAST / CHANGE columns and a Start CTA.
class TodayWorkoutCard extends StatelessWidget {
  static const double _lastColWidth = 58;
  static const double _changeColWidth = 52;

  final HomeTodaySummary summary;
  final String subtitle;
  final List<TodayWorkoutRow> rows;
  final VoidCallback onStart;

  const TodayWorkoutCard({
    super.key,
    required this.summary,
    required this.subtitle,
    required this.rows,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final completed = summary.completed;

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'UP NEXT · TODAY',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.startOrange,
                  ),
                ),
              ),
              if (!summary.isRestDay)
                Text(
                  '${summary.estimatedDurationMinutes} min',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary.sessionTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.48,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(child: _columnLabel('EXERCISE')),
                  SizedBox(
                    width: _lastColWidth,
                    child: _columnLabel('LAST', alignRight: true),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: _changeColWidth,
                    child: _columnLabel('CHANGE', alignRight: true),
                  ),
                ],
              ),
            ),
            for (var index = 0; index < rows.length; index++)
              _ExerciseRow(
                row: rows[index],
                showDivider: index < rows.length - 1,
              ),
          ],
          const SizedBox(height: 14),
          if (completed != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.green,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Workout complete',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            )
          else
            Pressable(
              onTap: onStart,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.startOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  summary.isRestDay ? 'View plan' : 'Start',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _columnLabel(String label, {bool alignRight = false}) {
    return Text(
      label,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: GoogleFonts.robotoMono(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final TodayWorkoutRow row;
  final bool showDivider;

  const _ExerciseRow({required this.row, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final changeColor = row.changeDir > 0
        ? AppColors.green
        : row.changeDir < 0
            ? AppColors.amber
            : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? const BorderSide(color: AppColors.divider)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: row.setsLabel,
                    style: GoogleFonts.robotoMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                    children: [
                      if (row.stalled)
                        TextSpan(
                          text: ' · stalled',
                          style: GoogleFonts.robotoMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.amber,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: TodayWorkoutCard._lastColWidth,
            child: Text(
              row.lastLabel,
              textAlign: TextAlign.right,
              style: GoogleFonts.robotoMono(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: TodayWorkoutCard._changeColWidth,
            child: Text(
              row.changeLabel,
              textAlign: TextAlign.right,
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: changeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coaching tip card shown under the Today card: soft accent icon plus one
/// bold insight sentence and a plain follow-up.
class TipCard extends StatelessWidget {
  final String highlight;
  final String body;

  const TipCard({super.key, required this.highlight, required this.body});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.startOrange.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.bolt_rounded,
              size: 18,
              color: AppColors.startOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: highlight,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.55,
                ),
                children: [
                  TextSpan(
                    text: ' $body',
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
