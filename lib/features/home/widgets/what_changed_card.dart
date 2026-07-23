import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/models/progression_event_model.dart';

/// One rendered change line in the insight block: a leading glyph, a short
/// description with the exercise name emphasized, and a value on the right.
class _InsightItem {
  final String glyph;
  final Color color;
  final String name;
  final String detail;
  final String value;

  const _InsightItem({
    required this.glyph,
    required this.color,
    required this.name,
    required this.detail,
    required this.value,
  });
}

/// Editorial "Insight" block on the Train tab — an unbordered section under the
/// Today card, separated by a hairline, that combines both design variants: a
/// coaching lead line with a volume-trend sparkline on top, and a compact
/// glyph / text / value change list underneath. Driven by the unseen
/// progression events from recent workouts (target raises, masteries, exercise
/// swaps). Personal bests live on Progress.
class TrainInsight extends StatelessWidget {
  final List<ProgressionEvent> events;

  /// Chronological total-volume per recent session (oldest → newest) used to
  /// draw the sparkline. Fewer than two points hides the bars.
  final List<int> volumeTrend;

  const TrainInsight({
    super.key,
    required this.events,
    this.volumeTrend = const [],
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final event in events)
        if (_itemFor(event) case final item?) item,
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    final count = items.length;
    const kicker = 'INSIGHT';
    final lead = count == 1
        ? 'The program adjusted one thing to keep you moving.'
        : 'The program adjusted $count things to keep you moving.';

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 28, 8, 0),
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: AppColors.accentPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  lead,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              if (volumeTrend.length >= 2) ...[
                const SizedBox(width: 18),
                _TrendBars(values: volumeTrend),
              ],
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < items.length; i++)
            Container(
              decoration: i < items.length - 1
                  ? const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(
                      items[i].glyph,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: items[i].color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: items[i].name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: ' ${items[i].detail}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    items[i].value,
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: items[i].color,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Maps a progression event to a compact insight row, or null when it has no
  /// catalog exercise (or is a personal best, which lives on Progress).
  _InsightItem? _itemFor(ProgressionEvent event) {
    final exercise = ExerciseCatalog.findById(event.exerciseId);
    if (exercise == null) return null;
    final unit = exercise.isTimed ? 's' : '';
    final sets = event.targetSets ?? 3;

    switch (event.kind) {
      case ProgressionEventKind.targetIncrease:
        return _InsightItem(
          glyph: '↑',
          color: AppColors.green,
          name: exercise.name,
          detail: 'target raised',
          value: event.valueFrom == null
              ? '→ ${event.valueTo}$unit'
              : '${event.valueFrom}$unit → ${event.valueTo}$unit',
        );
      case ProgressionEventKind.mastered:
        return _InsightItem(
          glyph: '★',
          color: AppColors.green,
          name: exercise.name,
          detail: 'mastered',
          value: '$sets × ${event.valueTo}$unit',
        );
      case ProgressionEventKind.activated:
        final related = event.relatedExerciseId == null
            ? null
            : ExerciseCatalog.findById(event.relatedExerciseId!);
        return _InsightItem(
          glyph: '⇄',
          color: AppColors.accentPrimary,
          name: exercise.name,
          detail:
              related == null ? 'is your next move' : 'replaces ${related.name}',
          value: related == null ? 'new' : 'unlocked',
        );
      case ProgressionEventKind.personalBest:
        return null; // Shown as an achievement on the Progress tab.
      case ProgressionEventKind.branchChoice:
        return _InsightItem(
          glyph: '⇄',
          color: AppColors.accentPrimary,
          name: exercise.name,
          detail: 'path forks here',
          value: 'choose',
        );
    }
  }
}

/// Small volume-trend sparkline — the most recent bar is accented.
class _TrendBars extends StatelessWidget {
  static const double _height = 46;

  final List<int> values;

  const _TrendBars({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce(math.max);
    if (maxValue <= 0) return const SizedBox.shrink();

    return SizedBox(
      height: _height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Container(
              width: 8,
              height: _height * (0.16 + 0.84 * (values[i] / maxValue)),
              decoration: BoxDecoration(
                color: i == values.length - 1
                    ? AppColors.accentPrimary
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
