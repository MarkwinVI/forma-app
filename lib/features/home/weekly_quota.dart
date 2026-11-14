import '../../data/services/training_schedule_service.dart';

/// Where the week stands against the number of sessions the program asks
/// for.
///
/// The program does not put sessions on days. It asks for a count — three
/// a week, say — and the week is Monday to Sunday. Any day is a day to
/// train; the only thing that can fall short is the week, and a session
/// that was not reached simply stays next in line.
class WeeklyQuota {
  /// Sessions the program asks for in a week; at least one.
  final int target;

  /// Sessions counted toward this week, never more than [target].
  final int done;

  /// The Monday this week starts on, at local midnight.
  final DateTime weekStart;

  /// Days left in the week, today included: 7 on Monday, 1 on Sunday.
  final int daysLeft;

  const WeeklyQuota({
    required this.target,
    required this.done,
    required this.weekStart,
    required this.daysLeft,
  });

  int get remaining => target - done;
  bool get isComplete => done >= target;

  /// The Monday of the week [date] falls in.
  static DateTime weekStartOf(DateTime date) => TrainingScheduleService.addDays(
        TrainingScheduleService.dateOnly(date),
        -(date.weekday - 1),
      );

  /// Counts the week [now] falls in.
  ///
  /// [sessionDates] are the days program sessions were logged on, in any
  /// order. A session trained after a week's count was already met is
  /// next week's, started early: it carries forward rather than being
  /// lost, so the week after opens with it already counted.
  static WeeklyQuota resolve({
    required Iterable<DateTime> sessionDates,
    required int target,
    required DateTime now,
  }) {
    final goal = target < 1 ? 1 : target;
    final thisWeek = weekStartOf(now);

    final perWeek = <DateTime, int>{};
    for (final date in sessionDates) {
      final week = weekStartOf(date);
      // A workout dated past this week (a clock set back) counts nowhere.
      if (TrainingScheduleService.daysBetween(week, thisWeek) < 0) continue;
      perWeek[week] = (perWeek[week] ?? 0) + 1;
    }

    final weeks = perWeek.keys.toList()..sort();
    var carry = 0;
    DateTime? previous;
    var counted = 0;
    for (final week in [
      ...weeks,
      if (!perWeek.containsKey(thisWeek)) thisWeek
    ]) {
      if (previous != null) {
        // Weeks with nothing logged in between each use up a week's worth
        // of whatever was carried.
        final skipped =
            TrainingScheduleService.daysBetween(previous, week) ~/ 7 - 1;
        carry -= goal * skipped;
        if (carry < 0) carry = 0;
      }
      final total = (perWeek[week] ?? 0) + carry;
      if (TrainingScheduleService.daysBetween(week, thisWeek) == 0) {
        counted = total;
      } else {
        carry = total > goal ? total - goal : 0;
      }
      previous = week;
    }

    return WeeklyQuota(
      target: goal,
      done: counted > goal ? goal : counted,
      weekStart: thisWeek,
      daysLeft: 8 - now.weekday,
    );
  }
}
