import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/type_led.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/models/progression_event_model.dart';

/// One rendered change line: the exercise, what the program did to it, and
/// the value that changed.
class _InsightItem {
  final Color color;
  final String name;
  final String detail;
  final String value;

  const _InsightItem({
    required this.color,
    required this.name,
    required this.detail,
    required this.value,
  });
}

/// "What the program changed" on the Train tab — the target raises, masteries
/// and swaps the last workout earned, listed under a mono label. Driven by the
/// unseen progression events from recent workouts. Personal bests live on
/// Progress.
class TrainInsight extends StatelessWidget {
  final List<ProgressionEvent> events;

  const TrainInsight({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final event in events)
        if (_itemFor(event) case final item?) item,
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TypeSectionLabel('What the program changed'),
        for (var i = 0; i < items.length; i++)
          Container(
            padding: const EdgeInsets.only(top: 16, bottom: 17),
            decoration: BoxDecoration(
              border: i == items.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AppColors.divider),
                    ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.35,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        items[i].detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  items[i].value,
                  style: monoStyle(
                    size: 14,
                    letterSpacing: 0.2,
                    color: items[i].color,
                  ),
                ),
              ],
            ),
          ),
      ],
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
          color: AppColors.green,
          name: exercise.name,
          detail: 'target raised',
          value: event.valueFrom == null
              ? '→ ${event.valueTo}$unit'
              : '${event.valueFrom}$unit → ${event.valueTo}$unit',
        );
      case ProgressionEventKind.mastered:
        return _InsightItem(
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
          color: AppColors.accentPrimary,
          name: exercise.name,
          detail: 'path forks here',
          value: 'choose',
        );
    }
  }
}
