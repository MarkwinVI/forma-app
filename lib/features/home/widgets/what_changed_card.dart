import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/models/progression_event_model.dart';

/// "What changed" feed on the Train tab: unseen progression events from
/// recent workouts — target raises, masteries, and exercise swaps — with a
/// single dismiss that marks them seen. Personal bests live on Progress.
class WhatChangedCard extends StatelessWidget {
  final List<ProgressionEvent> events;
  final VoidCallback onDismiss;

  const WhatChangedCard({
    super.key,
    required this.events,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final event in events)
        if (_lineFor(event) case final line?) (event: event, line: line),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 15,
                color: AppColors.accentPrimary,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'What changed',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Pressable(
                onTap: onDismiss,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: i > 0
                  ? const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.divider),
                      ),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _iconFor(rows[i].event.kind),
                    size: 16,
                    color: _colorFor(rows[i].event.kind),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rows[i].line,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(ProgressionEventKind kind) {
    switch (kind) {
      case ProgressionEventKind.targetIncrease:
        return Icons.trending_up_rounded;
      case ProgressionEventKind.mastered:
        return Icons.verified_rounded;
      case ProgressionEventKind.activated:
        return Icons.lock_open_rounded;
      case ProgressionEventKind.personalBest:
        return Icons.emoji_events_rounded;
      case ProgressionEventKind.branchChoice:
        return Icons.alt_route_rounded;
    }
  }

  Color _colorFor(ProgressionEventKind kind) {
    switch (kind) {
      case ProgressionEventKind.targetIncrease:
        return AppColors.amber;
      case ProgressionEventKind.mastered:
        return AppColors.green;
      case ProgressionEventKind.activated:
        return AppColors.accentPrimary;
      case ProgressionEventKind.personalBest:
        return AppColors.amber;
      case ProgressionEventKind.branchChoice:
        return AppColors.accentPrimary;
    }
  }

  String? _lineFor(ProgressionEvent event) {
    final exercise = ExerciseCatalog.findById(event.exerciseId);
    if (exercise == null) return null;
    final suffix = exercise.isTimed ? 's' : '';
    final sets = event.targetSets ?? 3;

    switch (event.kind) {
      case ProgressionEventKind.targetIncrease:
        return 'We raised your target for ${exercise.name} to '
            '$sets × ${event.valueTo}$suffix'
            '${event.valueFrom == null ? '' : ' (was ${event.valueFrom}$suffix)'}.';
      case ProgressionEventKind.mastered:
        return 'You mastered ${exercise.name} at '
            '$sets × ${event.valueTo}$suffix.';
      case ProgressionEventKind.activated:
        final related = event.relatedExerciseId == null
            ? null
            : ExerciseCatalog.findById(event.relatedExerciseId!);
        return related == null
            ? '${exercise.name} is your next move — starting at '
                '$sets × ${event.valueTo}$suffix.'
            : '${exercise.name} replaces ${related.name} — you mastered it.';
      case ProgressionEventKind.personalBest:
        return null; // Shown as an achievement on the Progress tab.
      case ProgressionEventKind.branchChoice:
        return 'You mastered ${exercise.name} — its path forks here. '
            'Pick your next branch in your program.';
    }
  }
}
