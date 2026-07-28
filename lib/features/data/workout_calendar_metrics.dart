import '../../data/models/workout_history_model.dart';

/// Calendar-shaped rollups over saved workouts: per-week streaks, the days a
/// month was trained, and per-day activity levels.
class WorkoutCalendarMetrics {
  final List<PastWorkout> workouts;
  final DateTime _now;

  WorkoutCalendarMetrics({
    required this.workouts,
    DateTime? now,
  }) : _now = now ?? DateTime.now();

  DateTime get now => _now;

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

  /// Consecutive weeks in which at least one session was logged. One workout
  /// carries a week — the streak is about showing up every week, not about
  /// hitting the program's session count.
  ///
  /// A week you have already trained extends the streak straight away; a week
  /// you have not trained yet cannot break it until it is over.
  int get currentStreakWeeks {
    var week = weekStartOf(_now);
    if (_trained(week)) return _runEndingAt(week);
    return _runEndingAt(week.subtract(const Duration(days: 7)));
  }

  /// Longest run of consecutive trained weeks.
  int get bestStreakWeeks {
    if (_sessionsPerWeek.isEmpty) return 0;
    final weeks = _sessionsPerWeek.keys.toList()..sort();
    var best = 0;
    var run = 0;
    var cursor = weeks.first;
    final last = weekStartOf(_now);
    while (!cursor.isAfter(last)) {
      run = _trained(cursor) ? run + 1 : 0;
      if (run > best) best = run;
      cursor = cursor.add(const Duration(days: 7));
    }
    return best;
  }

  bool _trained(DateTime weekStart) => (_sessionsPerWeek[weekStart] ?? 0) > 0;

  /// How many trained weeks run back from [weekStart], inclusive.
  int _runEndingAt(DateTime weekStart) {
    var week = weekStart;
    var streak = 0;
    while (_trained(week)) {
      streak++;
      week = week.subtract(const Duration(days: 7));
    }
    return streak;
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
