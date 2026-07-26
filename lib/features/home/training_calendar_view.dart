import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/training_schedule_service.dart';
import 'home_dashboard_metrics.dart';

const _skippedRed = Color(0xFFFF5C45);
const _skippedRedSoft = Color(0x24FF5C45);

class TrainingCalendarView extends StatefulWidget {
  final List<HomeWeekStripDay> days;
  final Map<DateTime, DailyTrainingRecommendation> recommendations;
  final DateTime now;

  const TrainingCalendarView({
    super.key,
    required this.days,
    required this.recommendations,
    required this.now,
  });

  @override
  State<TrainingCalendarView> createState() => _TrainingCalendarViewState();
}

class _TrainingCalendarViewState extends State<TrainingCalendarView> {
  DateTime? _expandedDate;
  bool _showPreviousDays = false;

  @override
  Widget build(BuildContext context) {
    final today = TrainingScheduleService.dateOnly(widget.now);
    final previousDays = widget.days
        .where(
            (day) => TrainingScheduleService.dateOnly(day.date).isBefore(today))
        .toList();
    final visibleDays = _showPreviousDays
        ? widget.days
        : widget.days
            .where((day) =>
                !TrainingScheduleService.dateOnly(day.date).isBefore(today))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CalendarHeader(onBack: () => Navigator.of(context).pop()),
            if (previousDays.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Align(
                  alignment: Alignment.center,
                  child: _TertiaryScheduleButton(
                    label: _showPreviousDays
                        ? 'Hide last 7 days'
                        : 'Show last 7 days',
                    onTap: () {
                      setState(() {
                        _showPreviousDays = !_showPreviousDays;
                      });
                    },
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                itemCount: visibleDays.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final day = visibleDays[index];
                  final key = TrainingScheduleService.dateOnly(day.date);
                  final recommendation = widget.recommendations[key];
                  final canExpand = key.isAfter(today) &&
                      !day.isRestDay &&
                      !day.isCompleted &&
                      !day.isMissed &&
                      recommendation != null;
                  final expanded = _expandedDate != null &&
                      key.isAtSameMomentAs(_expandedDate!);

                  return _CalendarDayTile(
                    day: day,
                    recommendation: recommendation,
                    expanded: expanded,
                    canExpand: canExpand,
                    onTap: canExpand
                        ? () {
                            setState(() {
                              _expandedDate = expanded ? null : key;
                            });
                          }
                        : null,
                    onStart: recommendation == null
                        ? null
                        : () => Navigator.of(context).pop(recommendation),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TertiaryScheduleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TertiaryScheduleButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.accentPrimary,
          ),
        ),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _CalendarHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SizedBox(
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Pressable(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const Text(
              'Schedule',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.44,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  final HomeWeekStripDay day;
  final DailyTrainingRecommendation? recommendation;
  final bool expanded;
  final bool canExpand;
  final VoidCallback? onTap;
  final VoidCallback? onStart;

  const _CalendarDayTile({
    required this.day,
    required this.recommendation,
    required this.expanded,
    required this.canExpand,
    required this.onTap,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(day);
    final title = day.isRestDay ? 'Rest day' : day.sessionType.label;
    final subtitle = _subtitleFor(day, recommendation);

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tone.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _DateBadge(day: day, color: tone.foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: tone.title,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canExpand)
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Icon(tone.icon, size: 20, color: tone.foreground),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _ExpandedWorkout(
                recommendation: recommendation,
                onStart: onStart,
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(
    HomeWeekStripDay day,
    DailyTrainingRecommendation? recommendation,
  ) {
    if (day.isMissed) return 'Skipped';
    if (day.isCompleted) return 'Completed';
    if (day.isCurrent && !day.isRestDay) return 'Today';
    if (day.isRestDay) return 'Recovery';
    final count = recommendation?.items.length ?? 0;
    if (count == 0) return 'Planned workout';
    return '$count exercises planned';
  }

  _CalendarTone _toneFor(HomeWeekStripDay day) {
    if (day.isMissed) {
      return const _CalendarTone(
        background: _skippedRedSoft,
        border: _skippedRed,
        foreground: _skippedRed,
        title: AppColors.textPrimary,
        icon: Icons.remove_circle_outline_rounded,
      );
    }
    if (day.isCompleted) {
      return const _CalendarTone(
        background: AppColors.greenSoft,
        border: Color(0x663FD07E),
        foreground: AppColors.green,
        title: AppColors.textPrimary,
        icon: Icons.check_circle_rounded,
      );
    }
    if (day.isCurrent) {
      return const _CalendarTone(
        background: AppColors.accentSoft,
        border: AppColors.accentPrimary,
        foreground: AppColors.accentPrimary,
        title: AppColors.textPrimary,
        icon: Icons.today_rounded,
      );
    }
    if (day.isRestDay) {
      return const _CalendarTone(
        background: Colors.transparent,
        border: AppColors.divider,
        foreground: AppColors.textMuted,
        title: AppColors.textSecondary,
        icon: Icons.nights_stay_rounded,
      );
    }
    return const _CalendarTone(
      background: AppColors.surface,
      border: Colors.transparent,
      foreground: AppColors.textSecondary,
      title: AppColors.textPrimary,
      icon: Icons.fitness_center_rounded,
    );
  }
}

class _ExpandedWorkout extends StatelessWidget {
  final DailyTrainingRecommendation? recommendation;
  final VoidCallback? onStart;

  const _ExpandedWorkout({
    required this.recommendation,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final items = recommendation?.items ?? const <TrainingRecommendationItem>[];

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 1, color: AppColors.divider),
          for (var i = 0; i < items.length; i++) ...[
            _ExerciseScheduleRow(item: items[i]),
            if (i < items.length - 1)
              Container(height: 1, color: AppColors.divider),
          ],
          const SizedBox(height: 14),
          _NeutralStartButton(onTap: onStart),
        ],
      ),
    );
  }
}

class _ExerciseScheduleRow extends StatelessWidget {
  final TrainingRecommendationItem item;

  const _ExerciseScheduleRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.exercise.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.track.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeutralStartButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _NeutralStartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return Pressable(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: disabled ? AppColors.surface : AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow_rounded,
              size: 18,
              color: disabled ? AppColors.textMuted : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              'Start workout',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: disabled ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final HomeWeekStripDay day;
  final Color color;

  const _DateBadge({
    required this.day,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _weekday(day.date),
            style: TextStyle(
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${day.date.day}',
            style: const TextStyle(
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _weekday(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1].toUpperCase();
  }
}

class _CalendarTone {
  final Color background;
  final Color border;
  final Color foreground;
  final Color title;
  final IconData icon;

  const _CalendarTone({
    required this.background,
    required this.border,
    required this.foreground,
    required this.title,
    required this.icon,
  });
}
