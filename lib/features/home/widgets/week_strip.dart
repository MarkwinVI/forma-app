import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../data/models/training_program_model.dart';
import '../home_dashboard_metrics.dart';

const _skippedRed = Color(0xFFFF5C45);
const _skippedRedSoft = Color(0x24FF5C45);

/// Slim week strip at the top of the Train tab — one rounded pill per day of
/// the current program cycle. Completed days show a check; today is outlined;
/// upcoming training and rest days are toned down. No date or session count.
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
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: Pressable(
              onTap: onDayTap == null ? null : () => onDayTap!(days[i]),
              child: _DayPill(day: days[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  final HomeWeekStripDay day;

  const _DayPill({required this.day});

  @override
  Widget build(BuildContext context) {
    final isRest = day.sessionType == TrainingSessionType.rest;
    final isCompleted = day.isCompleted;
    final isToday = day.isCurrent;
    final isSelected = day.isSelected;
    final isMissed = day.isMissed;

    // Background: soft green for done, tinted accent / neutral for today,
    // faint surface for upcoming training, transparent for rest.
    final Color background;
    if (isMissed) {
      background = _skippedRedSoft;
    } else if (isCompleted) {
      background = AppColors.greenSoft;
    } else if (isSelected) {
      background = isRest ? AppColors.surface2 : AppColors.accentSoft;
    } else if (isToday) {
      background = isRest ? AppColors.surface2 : AppColors.accentSoft;
    } else if (!isRest) {
      background = AppColors.surface;
    } else {
      background = Colors.transparent;
    }

    // A skipped day is outlined in dashes, the same "nothing logged here"
    // language the schedule uses. Painted rather than bordered, so the pill
    // keeps its size either way.
    final Color? dashedBorder = isMissed
        ? _skippedRed.withValues(alpha: isSelected ? 0.9 : 0.7)
        : null;

    final Border border;
    if (isMissed) {
      border = Border.all(color: Colors.transparent);
    } else if (isSelected) {
      border = Border.all(
        color: AppColors.accentPrimary.withValues(alpha: 0.75),
      );
    } else if (isToday) {
      border = Border.all(
        color: isRest
            ? Colors.white.withValues(alpha: 0.22)
            : AppColors.accentPrimary.withValues(alpha: 0.55),
      );
    } else {
      border = Border.all(color: Colors.transparent);
    }

    final Color letterColor = isMissed
        ? _skippedRed
        : isCompleted
            ? AppColors.green
            : isToday && !isRest
                ? AppColors.accentPrimary
                : !isRest
                    ? AppColors.textSecondary
                    : AppColors.textMuted;

    final pill = Container(
      height: 32,
      decoration: BoxDecoration(
        color: background,
        border: border,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      // The day letter always stays readable — a finished day says so with
      // its green fill and green letter, not by dropping out of the week.
      child: Text(
        WeekStrip._weekdayLetters[day.date.weekday - 1],
        style: GoogleFonts.robotoMono(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: letterColor,
        ),
      ),
    );

    if (dashedBorder == null) return pill;
    return DashedRoundedBorder(color: dashedBorder, child: pill);
  }
}
