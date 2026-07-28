import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/type_led.dart';
import '../home_dashboard_metrics.dart';
import '../train_day_view.dart';

/// The dated ribbon at the top of the Train tab: the month, a way back to
/// today once you leave it, and a scrolling run of days.
///
/// State is carried by the marker's SHAPE rather than its colour — filled for
/// a day that was trained, a hollow ring for one that is planned, nothing at
/// all for a rest day — so the row reads at a glance without a legend. The
/// underline under the day you are looking at says which kind of day it is:
/// solid for today, dashed for a day ahead (nothing about it is settled yet),
/// red for one you missed.
class DayRibbon extends StatefulWidget {
  static const double _cellWidth = 51;

  final List<HomeWeekStripDay> days;

  /// The day being looked at; today when the user has not moved off it.
  final DateTime selectedDate;
  final DateTime today;

  final ValueChanged<HomeWeekStripDay> onDayTap;
  final VoidCallback onBackToToday;

  /// The month opens the full schedule — the one place that still lists the
  /// weeks as a page rather than a ribbon.
  final VoidCallback? onMonthTap;

  const DayRibbon({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.today,
    required this.onDayTap,
    required this.onBackToToday,
    this.onMonthTap,
  });

  @override
  State<DayRibbon> createState() => _DayRibbonState();
}

class _DayRibbonState extends State<DayRibbon> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void didUpdateWidget(DayRibbon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Keeps the day you are looking at on screen — tapping "back to today"
  /// from two weeks out has to actually show today.
  void _revealSelected() {
    if (!_controller.hasClients) return;
    final index = widget.days.indexWhere(
      (day) => _sameDay(day.date, widget.selectedDate),
    );
    if (index < 0) return;

    final viewport = _controller.position.viewportDimension;
    final target = index * DayRibbon._cellWidth -
        (viewport - DayRibbon._cellWidth) / 2;
    _controller.animateTo(
      target.clamp(0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    if (widget.days.isEmpty) return const SizedBox.shrink();

    final away = !_sameDay(widget.selectedDate, widget.today);
    final ahead = widget.selectedDate.isAfter(widget.today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Pressable(
                onTap: widget.onMonthTap,
                child: Text(
                  _monthLabel(widget.selectedDate),
                  style: monoStyle(size: 10.5, letterSpacing: 1.7),
                ),
              ),
              const Spacer(),
              if (away)
                Pressable(
                  onTap: widget.onBackToToday,
                  child: Text(
                    ahead ? '← TODAY' : 'TODAY →',
                    style: monoStyle(
                      size: 10.5,
                      letterSpacing: 1.7,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 68,
          // Bleeds into the page margin so the run of days reads as a ribbon
          // that continues past the screen, not a boxed row.
          child: ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            itemCount: widget.days.length,
            itemBuilder: (context, index) {
              final day = widget.days[index];
              return SizedBox(
                width: DayRibbon._cellWidth,
                child: Pressable(
                  onTap: () => widget.onDayTap(day),
                  child: _RibbonDay(
                    day: day,
                    selected: _sameDay(day.date, widget.selectedDate),
                    isToday: _sameDay(day.date, widget.today),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _monthLabel(DateTime date) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _RibbonDay extends StatelessWidget {
  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final HomeWeekStripDay day;
  final bool selected;
  final bool isToday;

  const _RibbonDay({
    required this.day,
    required this.selected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final numberColor = selected
        ? AppColors.textPrimary
        : isToday
            ? AppColors.accentPrimary
            : day.isRestDay
                ? AppColors.textMuted
                : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        border: selected && !_isDashed
            ? Border(bottom: BorderSide(color: _ruleColor, width: 2))
            : null,
      ),
      foregroundDecoration: selected && _isDashed
          ? _DashedRule(color: _ruleColor)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _letters[day.date.weekday - 1],
            style: monoStyle(size: 10, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          Text(
            '${day.date.day}',
            style: monoStyle(size: 15.5, color: numberColor, letterSpacing: 0),
          ),
          const SizedBox(height: 8),
          _Marker(day: day, isToday: isToday),
        ],
      ),
    );
  }

  /// A day ahead is ruled with a dashed line: what it holds is a projection,
  /// and the underline says so before any copy does.
  bool get _isDashed => !isToday && !day.isMissed && _isAhead;

  bool get _isAhead {
    final now = DateTime.now();
    return TrainDayViewResolver.daysBetween(now, day.date) > 0;
  }

  Color get _ruleColor =>
      day.isMissed ? AppColors.red : AppColors.accentPrimary;
}

/// Filled = trained, ring = planned, nothing = rest.
class _Marker extends StatelessWidget {
  final HomeWeekStripDay day;
  final bool isToday;

  const _Marker({required this.day, required this.isToday});

  @override
  Widget build(BuildContext context) {
    if (day.isRestDay) {
      return const SizedBox(width: 5, height: 5);
    }
    if (day.isCompleted) {
      return _dot(AppColors.accentPrimary);
    }
    if (day.isMissed) {
      return _dot(AppColors.red);
    }
    if (isToday) {
      return _dot(AppColors.accentPrimary);
    }
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

/// A dashed 2px rule under the cell, painted rather than composed of boxes so
/// the dashes stay even at any cell width.
class _DashedRule extends Decoration {
  final Color color;

  const _DashedRule({required this.color});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _DashedRulePainter(color);
  }
}

class _DashedRulePainter extends BoxPainter {
  static const double _dash = 4;
  static const double _gap = 3;

  final Color color;

  _DashedRulePainter(this.color);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final width = configuration.size?.width ?? 0;
    final height = configuration.size?.height ?? 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;

    final y = offset.dy + height - 1;
    var x = offset.dx;
    while (x < offset.dx + width) {
      final end = (x + _dash).clamp(offset.dx, offset.dx + width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += _dash + _gap;
    }
  }
}
