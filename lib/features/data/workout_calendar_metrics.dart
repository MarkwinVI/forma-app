import '../../data/models/workout_history_model.dart';

/// Calendar-shaped rollups over saved workouts: per-week streaks against the
/// program's weekly session goal, month totals, and per-day activity levels.
class WorkoutCalendarMetrics {
  final List<PastWorkout> workouts;
  final int weeklyGoal;
  final DateTime _now;

  WorkoutCalendarMetrics({
    required this.workouts,
    required int weeklyGoal,
    DateTime? now,
  })  : weeklyGoal = weeklyGoal < 1 ? 1 : weeklyGoal,
        _now = now ?? DateTime.now();

  static DateTime dayOf(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  /// Monday of the week containing [dateTime].
  static DateTime weekStartOf(DateTime dateTime) {
    final day = dayOf(dateTime);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  late final Map<DateTime, int> _sessionsPerWeek = () {
    final map = <DateTime, int>{};
    for (final workout in workouts) {
      final week = weekStartOf(workout.loggedAt);
      map[week] = (map[week] ?? 0) + 1;
    }
    return map;
  }();

  late final Map<DateTime, int> _setsPerDay = () {
    final map = <DateTime, int>{};
    for (final workout in workouts) {
      final day = dayOf(workout.loggedAt);
      map[day] = (map[day] ?? 0) + workout.totalSets;
    }
    return map;
  }();

  int get sessionsThisWeek => _sessionsPerWeek[weekStartOf(_now)] ?? 0;

  /// Consecutive weeks with at least one session, ending with this week if
  /// it already has one, otherwise last week. A single such week already
  /// counts as a 1-week streak.
  int get currentStreakWeeks {
    var week = weekStartOf(_now);
    if ((_sessionsPerWeek[week] ?? 0) < 1) {
      week = week.subtract(const Duration(days: 7));
    }
    var streak = 0;
    while ((_sessionsPerWeek[week] ?? 0) >= 1) {
      streak++;
      week = week.subtract(const Duration(days: 7));
    }
    return streak;
  }

  /// Longest run of consecutive weeks with at least one session.
  int get bestStreakWeeks {
    if (_sessionsPerWeek.isEmpty) return 0;
    final weeks = _sessionsPerWeek.keys.toList()..sort();
    var best = 0;
    var run = 0;
    var cursor = weeks.first;
    final last = weekStartOf(_now);
    while (!cursor.isAfter(last)) {
      if ((_sessionsPerWeek[cursor] ?? 0) >= 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
      cursor = cursor.add(const Duration(days: 7));
    }
    return best;
  }

  int get sessionsYearToDate {
    final yearStart = DateTime(_now.year);
    return workouts
        .where((workout) => !workout.loggedAt.isBefore(yearStart))
        .length;
  }

  List<PastWorkout> workoutsOnDay(DateTime day) {
    final target = dayOf(day);
    return workouts
        .where((workout) => dayOf(workout.loggedAt) == target)
        .toList();
  }

  int sessionsInMonth(DateTime month) => workouts
      .where(
        (workout) =>
            workout.loggedAt.year == month.year &&
            workout.loggedAt.month == month.month,
      )
      .length;

  Duration totalTimeInMonth(DateTime month) {
    var total = Duration.zero;
    for (final workout in workouts) {
      if (workout.loggedAt.year == month.year &&
          workout.loggedAt.month == month.month) {
        final elapsed = workout.loggedAt.difference(workout.startedAt);
        if (!elapsed.isNegative) total += elapsed;
      }
    }
    return total;
  }

  /// Day numbers (1-based) in [month] with at least one saved session.
  Set<int> sessionDaysInMonth(DateTime month) => {
        for (final workout in workouts)
          if (workout.loggedAt.year == month.year &&
              workout.loggedAt.month == month.month)
            workout.loggedAt.day,
      };

  /// Activity level 0–4 for a day, scaled against the busiest logged day.
  int activityLevelForDay(DateTime day) {
    final sets = _setsPerDay[dayOf(day)] ?? 0;
    if (sets <= 0) return 0;
    final maxSets = _setsPerDay.values
        .fold<int>(0, (max, value) => value > max ? value : max);
    if (maxSets <= 0) return 0;
    final ratio = sets / maxSets;
    if (ratio > 0.85) return 4;
    if (ratio > 0.6) return 3;
    if (ratio > 0.35) return 2;
    return 1;
  }
}
