import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/workout_history_model.dart';
import 'past_workout_detail_view.dart';
import 'workout_calendar_metrics.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Training calendar: month grid with logged days, month totals, and the
/// weekly streak breakdown directly underneath.
class CalendarView extends StatefulWidget {
  final List<PastWorkout> workouts;
  final int weeklyGoal;

  /// Called when a workout was deleted from within the calendar so the
  /// owning screen can reload its data.
  final VoidCallback? onDataChanged;

  const CalendarView({
    super.key,
    required this.workouts,
    required this.weeklyGoal,
    this.onDataChanged,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late List<PastWorkout> _workouts;
  late WorkoutCalendarMetrics _metrics;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _workouts = List.of(widget.workouts);
    _rebuildMetrics();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _rebuildMetrics() {
    _metrics = WorkoutCalendarMetrics(
      workouts: _workouts,
      weeklyGoal: widget.weeklyGoal,
    );
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _openDay(int day) async {
    final workouts =
        _metrics.workoutsOnDay(DateTime(_month.year, _month.month, day));
    if (workouts.isEmpty) return;
    final opened = workouts.first;
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PastWorkoutDetailView(workout: opened),
      ),
    );
    if (deleted == true && mounted) {
      setState(() {
        _workouts.removeWhere((workout) => workout.id == opened.id);
        _rebuildMetrics();
      });
      widget.onDataChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = _metrics.currentStreakWeeks;
    final sessionsThisMonth = _metrics.sessionsInMonth(_month);
    final monthTime = _metrics.totalTimeInMonth(_month);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SubScreenHeader(
              title: 'Calendar',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 44),
                children: [
                  _MonthCard(
                    month: _month,
                    metrics: _metrics,
                    onPrev: () => _shiftMonth(-1),
                    onNext: () => _shiftMonth(1),
                    onDayTap: _openDay,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          big: '$sessionsThisMonth',
                          small: 'sessions in ${_monthNames[_month.month - 1]}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          big: _formatTotalTime(monthTime),
                          small: 'total time',
                        ),
                      ),
                    ],
                  ),

                  // Streak — lives directly under the month content.
                  const SectionHeader(title: 'Weekly streak'),
                  _StreakHeroCard(streak: streak),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          big: '$streak',
                          small: 'week streak',
                          accent: true,
                          centered: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          big: '${_metrics.bestStreakWeeks}',
                          small: 'best run (wks)',
                          centered: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          big: '${_metrics.sessionsYearToDate}',
                          small: 'sessions YTD',
                          centered: true,
                        ),
                      ),
                    ],
                  ),
                  const SectionHeader(title: 'Last 13 weeks'),
                  SurfaceCard(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    child: Column(
                      children: [
                        _ActivityHeatmap(metrics: _metrics),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Rest',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 7),
                            for (final opacity in [0.0, 0.3, 0.55, 0.8, 1.0])
                              Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: opacity == 0
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : AppColors.accentPrimary
                                            .withValues(alpha: opacity),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            const Text(
                              'Hard',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final DateTime month;
  final WorkoutCalendarMetrics metrics;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onDayTap;

  const _MonthCard({
    required this.month,
    required this.metrics,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final sessionDays = metrics.sessionDaysInMonth(month);
    final now = DateTime.now();
    final today =
        now.year == month.year && now.month == month.month ? now.day : null;
    final weeks = _monthWeeks(month);

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Pressable(
                onTap: onPrev,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${_monthNames[month.month - 1]} ${month.year}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Pressable(
                onTap: onNext,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final letter in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Text(
                    letter,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final week in weeks)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  for (final day in week)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _DayCell(
                          day: day,
                          hasSession: day != null && sessionDays.contains(day),
                          isToday: day != null && day == today,
                          onTap: day != null && sessionDays.contains(day)
                              ? () => onDayTap(day)
                              : null,
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

  static List<List<int?>> _monthWeeks(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month, 1).weekday - 1;
    final cells = <int?>[
      ...List<int?>.filled(leading, null),
      for (var day = 1; day <= daysInMonth; day++) day,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return [
      for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7),
    ];
  }
}

class _DayCell extends StatelessWidget {
  final int? day;
  final bool hasSession;
  final bool isToday;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.hasSession,
    required this.isToday,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = isToday
        ? AppColors.accentPrimary
        : hasSession
            ? AppColors.accentSoft
            : Colors.white.withValues(alpha: 0.03);
    final textColor = day == null
        ? Colors.transparent
        : isToday
            ? Colors.white
            : hasSession
                ? AppColors.textPrimary
                : AppColors.textMuted;

    return Pressable(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color:
                day == null ? Colors.white.withValues(alpha: 0.03) : background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day == null ? '' : '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.white
                      : hasSession
                          ? AppColors.accentPrimary
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakHeroCard extends StatelessWidget {
  final int streak;

  const _StreakHeroCard({
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final headline = streak > 0
        ? (streak == 1 ? '1 week' : '$streak weeks')
        : 'No streak yet';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentPrimary.withValues(alpha: 0.14),
            AppColors.surface,
          ],
          stops: const [0, 0.6],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            offset: Offset(0, 10),
            blurRadius: 28,
          ),
        ],
      ),
      child: Text(
        headline,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: streak > 0 ? AppColors.accentPrimary : AppColors.textMuted,
          letterSpacing: -0.72,
          height: 1,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String big;
  final String small;
  final bool accent;
  final bool centered;

  const _StatCard({
    required this.big,
    required this.small,
    this.accent = false,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            big,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent ? AppColors.accentPrimary : AppColors.textPrimary,
              letterSpacing: -0.44,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            small,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// 13-week activity grid — one column per week, Monday at the top.
class _ActivityHeatmap extends StatelessWidget {
  final WorkoutCalendarMetrics metrics;

  const _ActivityHeatmap({required this.metrics});

  static const _levelOpacities = [0.0, 0.3, 0.55, 0.8, 1.0];

  @override
  Widget build(BuildContext context) {
    final thisWeek = WorkoutCalendarMetrics.weekStartOf(DateTime.now());
    final weekStarts = [
      for (var i = 12; i >= 0; i--) thisWeek.subtract(Duration(days: 7 * i)),
    ];

    return Row(
      children: [
        for (var w = 0; w < weekStarts.length; w++) ...[
          if (w > 0) const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                for (var d = 0; d < 7; d++) ...[
                  if (d > 0) const SizedBox(height: 4),
                  _cell(weekStarts[w].add(Duration(days: d))),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _cell(DateTime day) {
    final level = metrics.activityLevelForDay(day);
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: level == 0
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.accentPrimary
                  .withValues(alpha: _levelOpacities[level]),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

String _formatTotalTime(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours <= 0) return '${minutes}m';
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}
