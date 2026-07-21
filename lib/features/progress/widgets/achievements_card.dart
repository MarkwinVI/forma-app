import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/models/progression_event_model.dart';

/// Recent personal bests on the Progress tab, newest first.
class AchievementsCard extends StatelessWidget {
  final List<ProgressionEvent> personalBests;

  const AchievementsCard({
    super.key,
    required this.personalBests,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final event in personalBests)
        if (ExerciseCatalog.findById(event.exerciseId) case final exercise?)
          (event: event, exercise: exercise),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: i > 0
                  ? const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.divider),
                      ),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.amberSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 17,
                      color: AppColors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${rows[i].exercise.name} · '
                          '${rows[i].event.valueTo}'
                          '${rows[i].exercise.isTimed ? 's hold' : ' reps'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Personal best'
                          '${rows[i].event.valueFrom == null ? '' : ' — was ${rows[i].event.valueFrom}${rows[i].exercise.isTimed ? 's' : ''}'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _relativeDate(rows[i].event.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _relativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final days = today.difference(day).inDays;

    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '${days}d ago';
    if (days < 30) return '${days ~/ 7}w ago';
    return '${days ~/ 30}mo ago';
  }
}
