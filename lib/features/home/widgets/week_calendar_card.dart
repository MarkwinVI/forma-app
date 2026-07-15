import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../data/models/training_program_model.dart';
import '../home_dashboard_metrics.dart';
import '../program_day_items.dart';

/// Week strip on the Train tab: one cell per day of the current program
/// cycle, showing which days are training days and which are rest.
class WeekCalendarCard extends StatelessWidget {
  final HomeWeekStripData weekStrip;

  const WeekCalendarCard({super.key, required this.weekStrip});

  @override
  Widget build(BuildContext context) {
    if (weekStrip.days.isEmpty) return const SizedBox.shrink();

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'THIS WEEK',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Text(
                '${weekStrip.completedSessions} of '
                '${weekStrip.totalSessions} done',
                style: GoogleFonts.robotoMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              for (final day in weekStrip.days)
                Expanded(child: _DayCell(day: day)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final HomeWeekStripDay day;

  const _DayCell({required this.day});

  @override
  Widget build(BuildContext context) {
    final isRest = day.sessionType == TrainingSessionType.rest;
    final label = _shortTitle(programDayTitle(day.sessionType));
    final labelColor = day.isCompleted
        ? AppColors.green
        : day.isCurrent
            ? AppColors.textPrimary
            : isRest
                ? AppColors.textMuted
                : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _weekdayLetters[day.date.weekday - 1],
          style: GoogleFonts.robotoMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: day.isCurrent ? AppColors.startOrange : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 7),
        day.isCompleted
            ? const Icon(
                Icons.check_rounded,
                size: 14,
                color: AppColors.green,
              )
            : SizedBox(
                height: 14,
                child: Center(
                  child: Container(
                    width: isRest ? 4 : 7,
                    height: isRest ? 4 : 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRest
                          ? AppColors.surface3
                          : day.isCurrent
                              ? AppColors.startOrange
                              : AppColors.surface3,
                      border: !isRest && !day.isCurrent
                          ? Border.all(
                              color: AppColors.textMuted,
                              width: 1,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: day.isCurrent || day.isCompleted
                ? FontWeight.w700
                : FontWeight.w600,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  String _shortTitle(String title) =>
      title == 'Full Body' ? 'Full' : title;
}
