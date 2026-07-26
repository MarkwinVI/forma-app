import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/training_schedule_service.dart';
import '../data/past_workout_detail_view.dart';
import 'home_dashboard_metrics.dart';

const _skippedRed = Color(0xFFFF5C45);
const _skippedRedSoft = Color(0x24FF5C45);

/// What a single day in the list is: drives the marker, meta line and the
/// trailing action. Rest days are inert; today gets the start CTA; anything
/// with detail behind it expands in place.
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
                    padding: EdgeInsets.only(
                      bottom: 32 + MediaQuery.of(context).padding.bottom,
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
      _ListGroupLabel(label: label),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 18, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
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
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.44,
              ),
            ),
          ),
          if (range.isNotEmpty)
            Text(
              range.toUpperCase(),
              maxLines: 1,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.84,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _ListGroupLabel extends StatelessWidget {
  final String label;

  const _ListGroupLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 7),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.robotoMono(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textMuted,
        ),
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

  @override
  Widget build(BuildContext context) {
    final Color background;
    if (_isToday) {
      background = AppColors.accentPrimary.withValues(alpha: 0.05);
    } else if (expanded) {
      background = Colors.white.withValues(alpha: 0.03);
    } else {
      background = Colors.transparent;
    }

    final Color dateColor = _isToday
        ? AppColors.accentPrimary
        : _isRest
            ? AppColors.textMuted
            : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: background,
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Column(
                      children: [
                        Text(
                          _weekday(day.date),
                          style: GoogleFonts.robotoMono(
                            fontSize: 10.5,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: _isToday
                                ? AppColors.accentPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.date.day}',
                          style: GoogleFonts.robotoMono(
                            fontSize: 17,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: dateColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _DayMarker(kind: kind),
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
                            height: 1.2,
                            fontWeight:
                                _isRest ? FontWeight.w600 : FontWeight.w700,
                            color: _isRest
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (meta != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            meta!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                              color: kind == _DayKind.missed
                                  ? _skippedRed
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
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
      return Pressable(
        onTap: onStart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accentPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Start',
            style: TextStyle(
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
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
        size: 22,
        color: AppColors.textMuted,
      ),
    );
  }

  String _weekday(DateTime date) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[date.weekday - 1];
  }
}

/// 30×30 status chip in front of the session title. Dashed outlines mean
/// "nothing logged" — planned ahead, or missed behind.
class _DayMarker extends StatelessWidget {
  final _DayKind kind;

  const _DayMarker({required this.kind});

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case _DayKind.done:
        return _box(
          background: AppColors.greenSoft,
          child:
              const Icon(Icons.check_rounded, size: 17, color: AppColors.green),
        );
      case _DayKind.missed:
        return _box(
          background: _skippedRedSoft,
          dashedBorder: _skippedRed.withValues(alpha: 0.6),
          child: Text(
            '!',
            style: GoogleFonts.robotoMono(
              fontSize: 12.5,
              height: 1,
              fontWeight: FontWeight.w800,
              color: _skippedRed,
            ),
          ),
        );
      case _DayKind.today:
        return _box(
          background: AppColors.accentSoft,
          solidBorder: AppColors.accentPrimary.withValues(alpha: 0.55),
          child: const Icon(
            Icons.fitness_center_rounded,
            size: 16,
            color: AppColors.accentPrimary,
          ),
        );
      case _DayKind.planned:
        return _box(
          dashedBorder: Colors.white.withValues(alpha: 0.2),
          child: const Icon(
            Icons.fitness_center_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        );
      case _DayKind.rest:
      case _DayKind.plannedRest:
        return _box(
          child: const Icon(
            Icons.nightlight_round,
            size: 16,
            color: AppColors.textMuted,
          ),
        );
    }
  }

  Widget _box({
    required Widget child,
    Color background = Colors.transparent,
    Color? solidBorder,
    Color? dashedBorder,
  }) {
    final box = Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
        border: solidBorder == null ? null : Border.all(color: solidBorder),
      ),
      child: child,
    );

    if (dashedBorder == null) return box;
    return DashedRoundedBorder(color: dashedBorder, child: box);
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
      padding: const EdgeInsets.fromLTRB(78, 0, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lines.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: i == 0
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lines[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    lines[i].value,
                    maxLines: 1,
                    style: GoogleFonts.robotoMono(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          if (onStart != null)
            Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Pressable(
                onTap: onStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
