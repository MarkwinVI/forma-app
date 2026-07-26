import '../models/training_program_model.dart';

enum PlannedScheduleStatus { planned, completed, missed }

class PlannedScheduleDay {
  final DateTime date;
  final TrainingSessionType sessionType;
  final int stepIndex;
  final bool isToday;
  final bool isSelected;
  final PlannedScheduleStatus status;

  const PlannedScheduleDay({
    required this.date,
    required this.sessionType,
    required this.stepIndex,
    this.isToday = false,
    this.isSelected = false,
    this.status = PlannedScheduleStatus.planned,
  });

  bool get isRestDay => sessionType == TrainingSessionType.rest;
  bool get isCompleted => status == PlannedScheduleStatus.completed;
  bool get isMissed => status == PlannedScheduleStatus.missed;

  PlannedScheduleDay copyWith({
    bool? isToday,
    bool? isSelected,
    PlannedScheduleStatus? status,
  }) {
    return PlannedScheduleDay(
      date: date,
      sessionType: sessionType,
      stepIndex: stepIndex,
      isToday: isToday ?? this.isToday,
      isSelected: isSelected ?? this.isSelected,
      status: status ?? this.status,
    );
  }
}

class TrainingScheduleWindow {
  final List<PlannedScheduleDay> days;
  final PlannedScheduleDay today;
  final PlannedScheduleDay selectedDay;
  final int completedSessions;
  final int totalSessions;

  const TrainingScheduleWindow({
    required this.days,
    required this.today,
    required this.selectedDay,
    required this.completedSessions,
    required this.totalSessions,
  });
}

class TrainingScheduleService {
  static const minFrequencyPerWeek = 2;
  static const maxFrequencyPerWeek = 6;

  static const Map<int, List<int>> weekTemplates = {
    2: [1, 0, 0, 1, 0, 0, 0],
    3: [1, 0, 1, 0, 1, 0, 0],
    4: [1, 1, 0, 1, 1, 0, 0],
    5: [1, 1, 1, 0, 1, 1, 0],
    6: [1, 1, 1, 1, 1, 1, 0],
  };

  List<TrainingSessionType> cycleFor({
    required TrainingProgramType programType,
    required int frequencyPerWeek,
  }) {
    final sequence = trainingSequenceFor(programType);
    final template = weekTemplates[_clampFrequency(frequencyPerWeek)]!;
    var next = 0;
    return [
      for (final trains in template)
        trains == 1
            ? sequence[(next++) % sequence.length]
            : TrainingSessionType.rest,
    ];
  }

  List<TrainingSessionType> trainingSequenceFor(
    TrainingProgramType programType,
  ) {
    switch (programType) {
      case TrainingProgramType.fullBody:
        return const [TrainingSessionType.fullBody];
      case TrainingProgramType.pushPull:
        return const [TrainingSessionType.push, TrainingSessionType.pull];
      case TrainingProgramType.upperLower:
        return const [TrainingSessionType.upper, TrainingSessionType.lower];
    }
  }

  /// How many training days the program's week template ever stacks back to
  /// back — the recovery ceiling. Two sessions a week never touch (1); six a
  /// week run six deep. Training off-plan may not push a run past this.
  int maxConsecutiveTrainingDays(int frequencyPerWeek) {
    final template = weekTemplates[_clampFrequency(frequencyPerWeek)]!;
    var best = 0;
    // Walked twice so a run wrapping the end of the week is measured whole.
    var run = 0;
    for (var i = 0; i < template.length * 2; i++) {
      if (template[i % template.length] == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }
    return best == 0 ? 1 : (best > template.length ? template.length : best);
  }

  /// Projects the plan onto dates.
  ///
  /// Two independent things are derived here, and keeping them apart is what
  /// makes out-of-order training safe:
  ///
  /// * **Which days are training days** comes from the week template, pinned
  ///   to the last session actually completed ([lastPlannedWorkoutAt]) at the
  ///   template slot matching how many days in a row have been trained. So
  ///   training off-plan re-flows the following days from that session, and
  ///   the recovery spacing the template guarantees is never exceeded.
  /// * **Which session lands on a training day** comes from the program's
  ///   A/B order, continuing from [lastCompletedSessionType]. Alternation is
  ///   therefore preserved no matter which session the user picks: pulling a
  ///   later session forward swaps it with the one that was due, and pulling
  ///   one much further forward re-flows the rest rather than doubling up.
  ///
  /// A missed training day keeps its session pending and slides the plan a
  /// day, so nothing is silently dropped from the sequence.
  ///
  /// [completedSessions] maps a local date to the session logged that day, so
  /// finished days render what was actually trained instead of a projection.
  TrainingScheduleWindow buildWindow({
    required TrainingProgramType programType,
    required int frequencyPerWeek,
    required int currentStepIndex,
    required TrainingSessionType currentSessionType,
    DateTime? lastPlannedWorkoutAt,
    TrainingSessionType? lastCompletedSessionType,
    Map<DateTime, TrainingSessionType>? completedSessions,
    DateTime? selectedDate,
    int? daysBeforeToday,
    int? daysAfterToday,
    DateTime? now,
  }) {
    final today = dateOnly((now ?? DateTime.now()).toLocal());
    final selected = dateOnly((selectedDate ?? today).toLocal());
    final defaultStart = today.subtract(Duration(days: today.weekday - 1));
    final defaultEnd = defaultStart.add(const Duration(days: 6));
    final displayStart = daysBeforeToday == null
        ? defaultStart
        : today.subtract(Duration(days: daysBeforeToday));
    final displayEnd = daysAfterToday == null
        ? defaultEnd
        : today.add(Duration(days: daysAfterToday));
    final cycle = cycleFor(
      programType: programType,
      frequencyPerWeek: frequencyPerWeek,
    );
    final totalSessions =
        cycle.where((session) => session != TrainingSessionType.rest).length;

    if (cycle.isEmpty) {
      final emptyDay = PlannedScheduleDay(
        date: today,
        sessionType: currentSessionType,
        stepIndex: 0,
        isToday: true,
        isSelected: selected.isAtSameMomentAs(today),
      );
      return TrainingScheduleWindow(
        days: [emptyDay],
        today: emptyDay,
        selectedDay: emptyDay,
        completedSessions: 0,
        totalSessions: 0,
      );
    }

    final sequence = trainingSequenceFor(programType);
    final logged = <DateTime, TrainingSessionType>{
      if (completedSessions != null)
        for (final entry in completedSessions.entries)
          dateOnly(entry.key): entry.value,
    };

    // The last session actually completed — the pin for both the training-day
    // pattern and the A/B order.
    final anchorDate =
        lastPlannedWorkoutAt == null ? null : dateOnly(lastPlannedWorkoutAt);
    final anchorType = lastCompletedSessionType ??
        (anchorDate == null ? null : logged[anchorDate]) ??
        currentSessionType;

    // Pin the template so the days already trained back to back line up with a
    // run of the same length in the week shape. When the run has reached (or
    // passed) the template's ceiling this lands on the last slot of a run, so
    // the next day is a rest day — training on a rest day pushes recovery out
    // rather than stacking another hard day on top.
    final int originSlot;
    final DateTime origin;
    if (anchorDate == null) {
      origin = today;
      originSlot = _snapToTrainingSlot(
        cycle,
        _resolveIndex(
          cycle: cycle,
          stepIndex: currentStepIndex,
          sessionType: currentSessionType,
        ),
      );
    } else {
      origin = anchorDate;
      originSlot =
          _slotForRun(cycle, _runEndingAt(logged.keys.toSet(), anchorDate));
    }

    // Where the A/B order resumes. Whatever was completed last decides what
    // comes next, so a session pulled forward out of order never produces two
    // of the same kind back to back.
    var pending = anchorDate == null
        ? _sequencePosition(sequence, currentSessionType)
        : (_sequencePosition(sequence, anchorType) + 1) % sequence.length;

    final simulationStart = _earliest(displayStart, origin);
    final simulationEnd = _latest(
      displayEnd,
      selected.isAfter(today) ? selected : today,
    );

    final byDate = <DateTime, PlannedScheduleDay>{};
    var index = _indexOnDateBeforeBase(
      cycle: cycle,
      baseIndex: originSlot,
      baseDate: origin,
      targetDate: simulationStart,
    );

    for (var cursor = simulationStart;
        !cursor.isAfter(simulationEnd);
        cursor = cursor.add(const Duration(days: 1))) {
      final loggedType = logged[cursor];
      final isPatternTraining = cycle[index] != TrainingSessionType.rest;

      TrainingSessionType sessionType;
      var status = PlannedScheduleStatus.planned;
      var advanceIndex = true;

      if (loggedType != null) {
        // Real history outranks the projection.
        sessionType = loggedType;
        status = PlannedScheduleStatus.completed;
        if (!cursor.isBefore(origin)) {
          pending =
              (_sequencePosition(sequence, loggedType) + 1) % sequence.length;
        }
      } else if (cursor.isBefore(origin)) {
        sessionType = cycle[index];
      } else if (cursor.isAtSameMomentAs(origin) && anchorDate != null) {
        sessionType = anchorType;
        // The pointer says a session landed here. When history is available
        // and has no workout on this date it was deleted after the fact — the
        // plan still runs from here (deleting the past doesn't reopen a slot),
        // but the day is not claimed as done.
        status = completedSessions == null
            ? PlannedScheduleStatus.completed
            : PlannedScheduleStatus.planned;
      } else if (!isPatternTraining) {
        sessionType = TrainingSessionType.rest;
      } else {
        sessionType = sequence[pending];
        if (cursor.isBefore(today)) {
          // Nothing was logged: the session stays next in line and the rest of
          // the plan slides a day rather than dropping it.
          status = PlannedScheduleStatus.missed;
          advanceIndex = false;
        } else {
          // Today and beyond are projected as if they get done.
          pending = (pending + 1) % sequence.length;
        }
      }

      byDate[cursor] = PlannedScheduleDay(
        date: cursor,
        sessionType: sessionType,
        stepIndex: index,
        isToday: cursor.isAtSameMomentAs(today),
        isSelected: cursor.isAtSameMomentAs(selected),
        status: status,
      );

      if (advanceIndex) index = (index + 1) % cycle.length;
    }

    final days = [
      for (var cursor = displayStart;
          !cursor.isAfter(displayEnd);
          cursor = cursor.add(const Duration(days: 1)))
        byDate[cursor]!,
    ];
    final selectedDay = byDate[selected] ?? byDate[today]!;
    final todayDay = byDate[today]!;
    final completedCount = days
        .where((day) =>
            day.isCompleted && day.sessionType != TrainingSessionType.rest)
        .length;

    return TrainingScheduleWindow(
      days: days,
      today: todayDay,
      selectedDay: selectedDay,
      completedSessions: completedCount,
      totalSessions: totalSessions,
    );
  }

  static DateTime dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  static int _clampFrequency(int frequencyPerWeek) =>
      frequencyPerWeek.clamp(minFrequencyPerWeek, maxFrequencyPerWeek);

  static DateTime _earliest(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  static DateTime _latest(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  static int _resolveIndex({
    required List<TrainingSessionType> cycle,
    required int stepIndex,
    required TrainingSessionType sessionType,
  }) {
    if (stepIndex >= 0 &&
        stepIndex < cycle.length &&
        cycle[stepIndex] == sessionType) {
      return stepIndex;
    }

    final matchedIndex = cycle.indexOf(sessionType);
    return matchedIndex >= 0 ? matchedIndex : 0;
  }

  /// Position of [sessionType] in the program's A/B order; 0 when it is not
  /// part of this program (a stale pointer after a program change).
  static int _sequencePosition(
    List<TrainingSessionType> sequence,
    TrainingSessionType sessionType,
  ) {
    final index = sequence.indexOf(sessionType);
    return index < 0 ? 0 : index;
  }

  /// Days trained back to back ending on [date], counting [date] itself.
  static int _runEndingAt(Set<DateTime> completedDates, DateTime date) {
    var run = 0;
    var cursor = date;
    while (completedDates.contains(cursor)) {
      run++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return run == 0 ? 1 : run;
  }

  /// The training slot that ends a run of exactly [run] training days. Falls
  /// back to the end of the template's longest run, which forces a rest day
  /// next — the guard for training past the program's recovery ceiling.
  static int _slotForRun(List<TrainingSessionType> cycle, int run) {
    var fallback = 0;
    var longest = 0;

    for (var i = 0; i < cycle.length; i++) {
      if (cycle[i] == TrainingSessionType.rest) continue;
      var length = 1;
      for (var back = 1; back < cycle.length; back++) {
        if (cycle[(i - back) % cycle.length] == TrainingSessionType.rest) break;
        length++;
      }
      if (length == run) return i;
      if (length > longest) {
        longest = length;
        fallback = i;
      }
    }
    return fallback;
  }

  static int _snapToTrainingSlot(List<TrainingSessionType> cycle, int index) {
    if (cycle[index] != TrainingSessionType.rest) return index;
    for (var offset = 1; offset < cycle.length; offset++) {
      final candidate = (index + offset) % cycle.length;
      if (cycle[candidate] != TrainingSessionType.rest) return candidate;
    }
    return index;
  }

  static int _indexOnDateBeforeBase({
    required List<TrainingSessionType> cycle,
    required int baseIndex,
    required DateTime baseDate,
    required DateTime targetDate,
  }) {
    final daysBefore = baseDate.difference(targetDate).inDays;
    if (daysBefore <= 0) return baseIndex;
    return (baseIndex - daysBefore) % cycle.length;
  }
}
