import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
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

/// Embeddable training calendar: the weekly streak, then a month grid with
/// the days that were trained. Rendered inline (for example in the Profile
/// tab) rather than as its own page.
class CalendarPanel extends StatefulWidget {
  final List<PastWorkout> workouts;
  final DateTime? now;

  /// Called when a workout was deleted from within the calendar so the
  /// owning screen can reload its data.
  final VoidCallback? onDataChanged;

  /// When false the "Last 13 weeks" activity heatmap is omitted.
  final bool showActivityHeatmap;

  const CalendarPanel({
    super.key,
    required this.workouts,
    this.now,
    this.onDataChanged,
    this.showActivityHeatmap = true,
  });

  @override
  State<CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<CalendarPanel> {
  late List<PastWorkout> _workouts;
  late WorkoutCalendarMetrics _metrics;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _workouts = List.of(widget.workouts);
    _rebuildMetrics();
    final now = widget.now ?? DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  void didUpdateWidget(covariant CalendarPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep in sync when the owning screen reloads its workout list.
    if (!identical(oldWidget.workouts, widget.workouts)) {
      _workouts = List.of(widget.workouts);
      _rebuildMetrics();
    }
    if (oldWidget.now != widget.now) {
      final now = widget.now ?? DateTime.now();
      _month = DateTime(now.year, now.month);
      _rebuildMetrics();
    }
  }

  void _rebuildMetrics() {
    _metrics = WorkoutCalendarMetrics(
      workouts: _workouts,
      now: widget.now,
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

    // A single session opens straight away; multiple sessions on the same
    // day let the user choose which one to open.
    final opened =
        workouts.length == 1 ? workouts.first : await _pickWorkout(workouts);
    if (opened == null || !mounted) return;

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

  Future<PastWorkout?> _pickWorkout(List<PastWorkout> workouts) {
    return showModalBottomSheet<PastWorkout>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.bgTertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  '${workouts.length} sessions this day',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              for (var i = 0; i < workouts.length; i++)
                _DaySessionRow(
                  workout: workouts[i],
                  showDivider: i > 0,
                  onTap: () => Navigator.of(sheetContext).pop(workouts[i]),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = _metrics.currentStreakWeeks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TypeSectionLabel('Weekly streak', top: 30),
        _StreakStatement(streak: streak),
        const TypeSectionLabel('Calendar'),
        _MonthGrid(
          month: _month,
          metrics: _metrics,
          onPrev: () => _shiftMonth(-1),
          onNext: () => _shiftMonth(1),
          onDayTap: _openDay,
        ),
        if (widget.showActivityHeatmap) ...[
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
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final WorkoutCalendarMetrics metrics;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onDayTap;

  const _MonthGrid({
    required this.month,
    required this.metrics,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final sessionDays = metrics.sessionDaysInMonth(month);
    final now = metrics.now;
    final today =
        now.year == month.year && now.month == month.month ? now.day : null;
    final weeks = _monthWeeks(month);

    // Bare on the page like everything else — the grid is held together by
    // its own alignment, not by a surface behind it.
    return Column(
      children: [
        Row(
          children: [
            Pressable(
              onTap: onPrev,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${_monthNames[month.month - 1]} ${month.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.32,
                ),
              ),
            ),
            Pressable(
              onTap: onNext,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
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
                  style: monoStyle(size: 10, letterSpacing: 1),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final week in weeks)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (final day in week)
                  Expanded(
                    child: _DayCell(
                      day: day,
                      hasSession: day != null && sessionDays.contains(day),
                      isToday: day != null && day == today,
                      onTap: day != null && sessionDays.contains(day)
                          ? () => onDayTap(day)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
      ],
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
    // Bare numbers on a grid: today is the only one the colour picks out, and
    // a trained day is marked by the dot under it rather than a filled tile.
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        height: 38,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day == null ? '' : '$day',
              style: monoStyle(
                size: 13.5,
                weight: isToday ? FontWeight.w700 : FontWeight.w500,
                color:
                    isToday ? AppColors.accentPrimary : AppColors.textSecondary,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    hasSession ? AppColors.accentPrimary : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The streak said as a sentence rather than shown as a hero card: the run of
/// weeks, on its own, with the label above it doing the explaining.
class _StreakStatement extends StatelessWidget {
  final int streak;

  const _StreakStatement({required this.streak});

  @override
  Widget build(BuildContext context) {
    final running = streak > 0;

    return Text(
      running ? (streak == 1 ? '1 week' : '$streak weeks') : 'No streak yet',
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: running ? AppColors.textPrimary : AppColors.textSecondary,
        letterSpacing: -0.78,
        height: 1.05,
      ),
    );
  }
}

/// Row in the "multiple sessions this day" picker sheet.
class _DaySessionRow extends StatelessWidget {
  final PastWorkout workout;
  final bool showDivider;
  final VoidCallback onTap;

  const _DaySessionRow({
    required this.workout,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final summaryParts = <String>[
      _formatClock(workout.loggedAt),
      '${workout.totalSets} sets',
      if (workout.totalReps > 0) '${workout.totalReps} reps',
      if (workout.totalTimedSeconds > 0)
        formatWorkoutSeconds(workout.totalTimedSeconds),
    ];

    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(top: BorderSide(color: AppColors.divider))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            IconTile(
              icon: workoutIconForSessionType(workout.sessionType),
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    summaryParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
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
    final thisWeek = WorkoutCalendarMetrics.weekStartOf(metrics.now);
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

String _formatClock(DateTime dateTime) {
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
  final displayHour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  return '$displayHour:$minute $suffix';
}
