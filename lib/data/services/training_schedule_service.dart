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

  TrainingScheduleWindow buildWindow({
    required TrainingProgramType programType,
    required int frequencyPerWeek,
    required int currentStepIndex,
    required TrainingSessionType currentSessionType,
    DateTime? lastPlannedWorkoutAt,
    TrainingSessionType? lastCompletedSessionType,
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

    final storedIndex = _resolveIndex(
      cycle: cycle,
      stepIndex: currentStepIndex,
      sessionType: currentSessionType,
    );

    final lastWorkoutDay =
        lastPlannedWorkoutAt == null ? null : dateOnly(lastPlannedWorkoutAt);
    final completedToday =
        lastWorkoutDay != null && lastWorkoutDay.isAtSameMomentAs(today);
    final baseDate = lastWorkoutDay == null
        ? today
        : completedToday
            ? today
            : lastWorkoutDay.add(const Duration(days: 1));
    final stateStillPointsAtCompletedStep = lastCompletedSessionType == null ||
        lastCompletedSessionType == currentSessionType;
    final baseIndex = lastWorkoutDay != null &&
            !completedToday &&
            stateStillPointsAtCompletedStep
        ? (storedIndex + 1) % cycle.length
        : storedIndex;

    final simulationStart = _earliest(displayStart, baseDate);
    final simulationEnd = _latest(
      displayEnd,
      selected.isAfter(today) ? selected : today,
    );

    final byDate = <DateTime, PlannedScheduleDay>{};
    var index = _indexOnDateBeforeBase(
      cycle: cycle,
      baseIndex: baseIndex,
      baseDate: baseDate,
      targetDate: simulationStart,
    );

    for (var cursor = simulationStart;
        !cursor.isAfter(simulationEnd);
        cursor = cursor.add(const Duration(days: 1))) {
      var status = PlannedScheduleStatus.planned;
      if (lastWorkoutDay != null && cursor.isAtSameMomentAs(lastWorkoutDay)) {
        status = PlannedScheduleStatus.completed;
      } else if (cursor.isBefore(today) &&
          !cursor.isBefore(baseDate) &&
          cycle[index] != TrainingSessionType.rest) {
        status = PlannedScheduleStatus.missed;
      }

      byDate[cursor] = PlannedScheduleDay(
        date: cursor,
        sessionType: cycle[index],
        stepIndex: index,
        isToday: cursor.isAtSameMomentAs(today),
        isSelected: cursor.isAtSameMomentAs(selected),
        status: status,
      );

      if (cursor.isBefore(baseDate)) {
        index = (index + 1) % cycle.length;
      } else if (status == PlannedScheduleStatus.missed) {
        // The missed workout remains the next workout. The whole future
        // schedule shifts by one date, including any rest days after it.
      } else if (!cursor.isAtSameMomentAs(today) || !completedToday) {
        index = (index + 1) % cycle.length;
      }
    }

    final days = [
      for (var cursor = displayStart;
          !cursor.isAfter(displayEnd);
          cursor = cursor.add(const Duration(days: 1)))
        byDate[cursor]!,
    ];
    final selectedDay = byDate[selected] ?? byDate[today]!;
    final todayDay = byDate[today]!;
    final completedSessions = days
        .where((day) =>
            day.isCompleted && day.sessionType != TrainingSessionType.rest)
        .length;

    return TrainingScheduleWindow(
      days: days,
      today: todayDay,
      selectedDay: selectedDay,
      completedSessions: completedSessions,
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
