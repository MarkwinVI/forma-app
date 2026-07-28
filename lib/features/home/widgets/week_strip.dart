import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/type_led.dart';
import '../../../data/models/training_program_model.dart';
import '../home_dashboard_metrics.dart';

/// Slim week strip at the top of the Train tab — letters only, no tiles. The
/// state is carried by the colour of the letter and the rule under today:
/// green done, red skipped, accent today, secondary planned, muted rest.
class WeekStrip extends StatelessWidget {
  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final HomeWeekStripData weekStrip;
  final ValueChanged<HomeWeekStripDay>? onDayTap;

  const WeekStrip({
    super.key,
    required this.weekStrip,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final days = weekStrip.days;
    if (days.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Pressable(
              onTap: onDayTap == null ? null : () => onDayTap!(day),
              child: _DayLetter(day: day),
            ),
          ),
      ],
    );
  }
}

class _DayLetter extends StatelessWidget {
  final HomeWeekStripDay day;

  const _DayLetter({required this.day});

  @override
  Widget build(BuildContext context) {
    final isRest = day.sessionType == TrainingSessionType.rest;

    final Color color;
    if (day.isMissed) {
      color = AppColors.red;
    } else if (day.isCompleted) {
      color = AppColors.green;
    } else if (day.isCurrent) {
      color = isRest ? AppColors.textSecondary : AppColors.accentPrimary;
    } else if (isRest) {
      color = AppColors.textMuted;
    } else {
      color = AppColors.textSecondary;
    }

    // Only the day you are on is underlined; a day you tapped to look at is
    // ruled more quietly so the two never compete.
    final Color rule;
    if (day.isCurrent) {
      rule = isRest ? AppColors.surface3 : AppColors.accentPrimary;
    } else if (day.isSelected) {
      rule = AppColors.surface3;
    } else {
      rule = Colors.transparent;
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: rule, width: 2)),
      ),
      child: Text(
        WeekStrip._weekdayLetters[day.date.weekday - 1],
        textAlign: TextAlign.center,
        style: monoStyle(size: 13, color: color, letterSpacing: 0.8),
      ),
    );
  }
}
