import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/type_led.dart';
import '../home_dashboard_metrics.dart';
import '../program_week_strip.dart';
import '../train_day_view.dart';

/// The week ribbon at the top of the Train tab: a way back to today once you
/// leave it, and a scrolling run of days.
///
/// Each day speaks the Program tab's marker language: its weekday letter over
/// its workout type's circled initial — a faint dot for a rest day — so the
/// two tabs read as one schedule. Colour carries what happened to the day:
/// green for work that was done, red for work that was not. The underline
/// under the day you are looking at says which kind of day it is: solid for
/// today, dashed for a day ahead (nothing about it is settled yet), red for
/// one you missed.
class DayRibbon extends StatefulWidget {
  /// A page of the ribbon is a week: seven days, filling the row.
  static const int daysPerPage = 7;

  final List<HomeWeekStripDay> days;

  /// The day being looked at; today when the user has not moved off it.
  final DateTime selectedDate;
  final DateTime today;

  final ValueChanged<HomeWeekStripDay> onDayTap;

  const DayRibbon({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.today,
    required this.onDayTap,
  });

  @override
  State<DayRibbon> createState() => _DayRibbonState();
}

class _DayRibbonState extends State<DayRibbon> {
  final _controller = PageController();

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

  /// Brings the week holding the selected day into view — coming back to
  /// today from next week has to actually show today.
  void _revealSelected() {
    if (!_controller.hasClients) return;
    final index = widget.days.indexWhere(
      (day) => _sameDay(day.date, widget.selectedDate),
    );
    if (index < 0) return;

    final page = index ~/ DayRibbon.daysPerPage;
    if ((_controller.page ?? 0).round() == page) return;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<List<HomeWeekStripDay>> get _weeks {
    final weeks = <List<HomeWeekStripDay>>[];
    for (var start = 0;
        start < widget.days.length;
        start += DayRibbon.daysPerPage) {
      weeks.add(
        widget.days.sublist(
          start,
          (start + DayRibbon.daysPerPage).clamp(0, widget.days.length),
        ),
      );
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.days.isEmpty) return const SizedBox.shrink();

    final weeks = _weeks;

    // No way back drawn here: today is lit in the row itself, and a tap on
    // it is the way back.
    return SizedBox(
      height: 58,
      // A week at a time: the row holds seven days and the next swipe
      // brings the seven behind them, so the days never half-scroll into
      // a reading that spans two weeks.
      child: PageView.builder(
        controller: _controller,
        itemCount: weeks.length,
        itemBuilder: (context, index) {
          final week = weeks[index];
          return Row(
            children: [
              for (var slot = 0; slot < DayRibbon.daysPerPage; slot++)
                Expanded(
                  child: slot < week.length
                      ? Pressable(
                          onTap: () => widget.onDayTap(week[slot]),
                          child: _RibbonDay(
                            day: week[slot],
                            selected: _sameDay(
                              week[slot].date,
                              widget.selectedDate,
                            ),
                            isToday: _sameDay(
                              week[slot].date,
                              widget.today,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          );
        },
      ),
    );
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
    return Container(
      padding: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        border: selected && !_isDashed
            ? Border(bottom: BorderSide(color: _ruleColor, width: 2))
            : null,
      ),
      foregroundDecoration:
          selected && _isDashed ? _DashedRule(color: _ruleColor) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _letters[day.date.weekday - 1],
            style: monoStyle(
              size: 10,
              letterSpacing: 1,
              // The letter is what says "you are here" — the marker below
              // stays free to carry the day's type and outcome.
              color: isToday ? AppColors.accentPrimary : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          day.isRestDay
              ? const ProgramRestDot(size: 22)
              : ProgramTypeNode(
                  sessionType: day.sessionType,
                  size: 22,
                  color: day.isCompleted
                      ? AppColors.green
                      : day.isMissed
                          ? AppColors.red
                          : null,
                ),
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
