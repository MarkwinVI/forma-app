import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/training_schedule_service.dart';
import '../data/past_workout_detail_view.dart';
import 'home_dashboard_metrics.dart';

/// What a single day in the list is: drives the status line, its colour and
/// the trailing action. Rest days are inert; today gets the start action;
/// anything with detail behind it expands in place.
enum _DayKind { done, missed, today, planned, rest, plannedRest }

/// Day list — the 15-day window around today as one flat, scannable list
/// instead of a stack of cards. Tapping a session opens its exercises in
/// place; today can be started straight from the row.
class TrainingCalendarView extends StatefulWidget {
  final List<HomeWeekStripDay> days;
  final Map<DateTime, DailyTrainingRecommendation> recommendations;
  final Map<DateTime, HomeTodaySummary> summaries;
  final Map<DateTime, PastWorkout> completedWorkouts;
  final DateTime now;

  const TrainingCalendarView({
    super.key,
    required this.days,
    required this.recommendations,
    required this.summaries,
    required this.completedWorkouts,
    required this.now,
  });

  @override
  State<TrainingCalendarView> createState() => _TrainingCalendarViewState();
}

class _TrainingCalendarViewState extends State<TrainingCalendarView> {
  DateTime? _expandedDate;

  @override
  Widget build(BuildContext context) {
    final today = TrainingScheduleService.dateOnly(widget.now);
    final past = <HomeWeekStripDay>[];
    final current = <HomeWeekStripDay>[];
    final future = <HomeWeekStripDay>[];

    for (final day in widget.days) {
      final key = TrainingScheduleService.dateOnly(day.date);
      if (key.isBefore(today)) {
        past.add(day);
      } else if (key.isAtSameMomentAs(today)) {
        current.add(day);
      } else {
        future.add(day);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CalendarHeader(
              title: 'Schedule',
              range: _rangeLabel(widget.days),
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      0,
                      22,
                      32 + MediaQuery.of(context).padding.bottom,
                    ),
                    children: [
                      ..._group('Last ${past.length} days', past, today),
                      ..._group('Today', current, today),
                      ..._group('Next ${future.length} days', future, today),
                    ],
                  ),
                  // Softens the list against the bottom edge on scroll.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 48,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.bg.withValues(alpha: 0),
                              AppColors.bg,
                            ],
                          ),
                        ),
                      ),
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

  List<Widget> _group(
    String label,
    List<HomeWeekStripDay> days,
    DateTime today,
  ) {
    if (days.isEmpty) return const [];

    return [
      TypeSectionLabel(label, top: 26),
      for (var i = 0; i < days.length; i++) _row(days[i], today, i == 0),
    ];
  }

  Widget _row(HomeWeekStripDay day, DateTime today, bool first) {
    final key = TrainingScheduleService.dateOnly(day.date);
    final kind = _kindFor(day, key, today);
    final recommendation = widget.recommendations[key];
    final summary = widget.summaries[key];
    final workout = widget.completedWorkouts[key];
    final lines = _detailLines(kind, summary);
    final expanded =
        _expandedDate != null && key.isAtSameMomentAs(_expandedDate!);
    // Only sessions still ahead open in place. A finished day hands off to its
    // history entry, and a skipped day is inert — there is nothing behind it.
    final canExpand = kind == _DayKind.planned && lines.isNotEmpty;
    final canOpenHistory = kind == _DayKind.done && workout != null;

    return _DayRow(
      day: day,
      kind: kind,
      first: first,
      title: _titleFor(kind, day, summary),
      meta: _metaFor(kind, summary),
      lines: lines,
      expanded: expanded,
      showChevron: canExpand || canOpenHistory,
      onTap: canExpand
          ? () => setState(() => _expandedDate = expanded ? null : key)
          : canOpenHistory
              ? () => _openWorkoutHistory(workout)
              : null,
      onStart: recommendation == null || kind == _DayKind.done
          ? null
          : () => Navigator.of(context).pop(recommendation),
    );
  }

  Future<void> _openWorkoutHistory(PastWorkout workout) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => PastWorkoutDetailView(workout: workout)),
    );
    // This page renders a snapshot taken on the Train tab; once a session is
    // deleted the whole window is stale, so hand back to the tab to rebuild.
    if (deleted == true && mounted) Navigator.of(context).pop();
  }

  _DayKind _kindFor(HomeWeekStripDay day, DateTime key, DateTime today) {
    // Rest wins over every other state: a recovery day carries no session, so
    // it never picks up session stats even if something was logged that day.
    if (day.isRestDay) {
      return key.isAfter(today) ? _DayKind.plannedRest : _DayKind.rest;
    }
    if (day.isCompleted) return _DayKind.done;
    if (day.isMissed) return _DayKind.missed;
    if (key.isAtSameMomentAs(today)) return _DayKind.today;
    return key.isAfter(today) ? _DayKind.planned : _DayKind.missed;
  }

  String _titleFor(
    _DayKind kind,
    HomeWeekStripDay day,
    HomeTodaySummary? summary,
  ) {
    if (kind == _DayKind.rest || kind == _DayKind.plannedRest) {
      return 'Rest day';
    }
    return summary?.sessionTitle ?? day.sessionType.label;
  }

  String? _metaFor(_DayKind kind, HomeTodaySummary? summary) {
    switch (kind) {
      case _DayKind.done:
        final completed = summary?.completed;
        if (completed == null) return 'Completed';
        return '${completed.durationMinutes} min · ${completed.setCount} sets';
      case _DayKind.missed:
        return 'Workout skipped';
      case _DayKind.today:
      case _DayKind.planned:
        final count = summary?.exerciseCount ?? 0;
        if (count == 0) return 'Planned workout';
        return '$count ${_plural(count)}';
      case _DayKind.rest:
      case _DayKind.plannedRest:
        return null;
    }
  }

  /// The prescribed exercises behind an upcoming session.
  List<_DetailLine> _detailLines(_DayKind kind, HomeTodaySummary? summary) {
    if (kind != _DayKind.planned) return const [];
    return [
      for (final planned
          in summary?.plannedExercises ?? const <HomePlannedExerciseSummary>[])
        _DetailLine(planned.name, planned.targetLabel),
    ];
  }

  String _plural(int count) => count == 1 ? 'exercise' : 'exercises';

  String _rangeLabel(List<HomeWeekStripDay> days) {
    if (days.isEmpty) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final first = days.first.date;
    final last = days.last.date;
    final start = '${months[first.month - 1]} ${first.day}';
    final end = first.month == last.month
        ? '${last.day}'
        : '${months[last.month - 1]} ${last.day}';
    return '$start – $end';
  }
}

class _DetailLine {
  final String name;
  final String value;

  const _DetailLine(this.name, this.value);
}

class _CalendarHeader extends StatelessWidget {
  final String title;
  final String range;
  final VoidCallback onBack;

  const _CalendarHeader({
    required this.title,
    required this.range,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 8, 22, 4),
      child: Row(
        children: [
          Pressable(
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.38,
              ),
            ),
          ),
          if (range.isNotEmpty)
            Text(
              range.toUpperCase(),
              maxLines: 1,
              style: monoStyle(size: 11, letterSpacing: 1.3),
            ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final HomeWeekStripDay day;
  final _DayKind kind;
  final bool first;
  final String title;
  final String? meta;
  final List<_DetailLine> lines;
  final bool expanded;
  final bool showChevron;
  final VoidCallback? onTap;
  final VoidCallback? onStart;

  const _DayRow({
    required this.day,
    required this.kind,
    required this.first,
    required this.title,
    required this.meta,
    required this.lines,
    required this.expanded,
    required this.showChevron,
    required this.onTap,
    required this.onStart,
  });

  bool get _isRest => kind == _DayKind.rest || kind == _DayKind.plannedRest;
  bool get _isToday => kind == _DayKind.today;

  /// The status line's colour is the only status marker: red for a session
  /// that was skipped, green for one that was done, quiet for anything still
  /// ahead.
  Color get _metaColor {
    switch (kind) {
      case _DayKind.missed:
        return AppColors.red;
      case _DayKind.done:
        return AppColors.green;
      case _DayKind.today:
      case _DayKind.planned:
      case _DayKind.rest:
      case _DayKind.plannedRest:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color dateColor = _isToday
        ? AppColors.accentPrimary
        : _isRest
            ? AppColors.textSecondary
            : AppColors.textPrimary;

    // No fill behind an opened row: the list is inset from the screen edges,
    // so a tint would read as a band that stops short of them. The exercises
    // appearing and the chevron turning already say the row is open.
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: first
              ? BorderSide.none
              : const BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _weekday(day.date),
                          style: monoStyle(
                            size: 10,
                            letterSpacing: 1,
                            color: _isToday
                                ? AppColors.accentPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${day.date.day}',
                          style: monoStyle(
                            size: 17,
                            letterSpacing: 0,
                            color: dateColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _isRest ? 18 : 20,
                            height: 1.15,
                            letterSpacing: -0.4,
                            fontWeight:
                                _isRest ? FontWeight.w600 : FontWeight.w800,
                            color: _isRest
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (meta != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            meta!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.2,
                              color: _metaColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _trailing(),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _DayDetail(lines: lines, onStart: onStart),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _trailing() {
    if (_isToday) {
      if (onStart == null) return const SizedBox.shrink();
      // Today is the one row that acts rather than opens, so it keeps a
      // written action instead of a chevron.
      return Pressable(
        onTap: onStart,
        child: const Text(
          'Start',
          style: TextStyle(
            fontSize: 16,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: AppColors.accentPrimary,
          ),
        ),
      );
    }
    if (!showChevron) return const SizedBox.shrink();
    return AnimatedRotation(
      turns: expanded ? 0.25 : 0,
      duration: const Duration(milliseconds: 180),
      child: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.textMuted,
      ),
    );
  }

  String _weekday(DateTime date) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[date.weekday - 1];
  }
}

/// Exercises behind an opened row, indented under the title column.
class _DayDetail extends StatelessWidget {
  final List<_DetailLine> lines;
  final VoidCallback? onStart;

  const _DayDetail({required this.lines, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 0, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in lines)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.cardHighlight),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      line.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.25,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    line.value,
                    maxLines: 1,
                    style: monoStyle(
                      size: 13,
                      weight: FontWeight.w500,
                      letterSpacing: 0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          if (onStart != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Pressable(
                onTap: onStart,
                child: const Text(
                  'Start this session',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
