import '../../data/services/training_schedule_service.dart';

/// Which day of the plan the Train tab is looking at.
///
/// The tab shows one day at a time and the day decides what it can honestly
/// say. Only [today] is a session you can just start; every other day is
/// either finished, gone, or not yet decided, and says so in its own words.
enum TrainDayView {
  /// The day you are on: the session, its history, and Start.
  today,

  /// A past day with a workout on it.
  logged,

  /// A past training day with nothing logged. Its session slid forward.
  missed,

  /// A training day inside the built horizon: real exercises, though the
  /// sessions before it can still move their targets.
  soon,

  /// A training day past the horizon. Only the shape of the day exists.
  distant,

  /// A rest day ahead of today.
  rest,
}

/// One line of copy above the session, in the tab's mono voice.
class TrainDayNote {
  final String tag;
  final String body;

  const TrainDayNote({required this.tag, required this.body});
}

/// Everything the Train tab needs to render a day that is not today: the
/// state, the eyebrow that names the day and its distance, and the note that
/// says what is true about it.
class TrainDayPresentation {
  final TrainDayView view;

  /// Mono line above the title — "IN 2 DAYS · FRI 31 JUL", or
  /// "TODAY · WED 29 JUL". Every day names itself, so moving across the week
  /// never leaves you guessing which one you are reading.
  final String? eyebrow;

  /// The band under the title, or null when the day speaks for itself.
  final TrainDayNote? note;

  const TrainDayPresentation({
    required this.view,
    this.eyebrow,
    this.note,
  });

  bool get isToday => view == TrainDayView.today;
}

/// Reads a selected day against today.
class TrainDayViewResolver {
  TrainDayViewResolver._();

  /// How far ahead the program's exercises are actually decided. Past this,
  /// a day only holds its shape: which patterns it trains and how many slots
  /// each gets, because the exercises come from how the sessions before it
  /// went.
  static const int builtHorizonDays = 7;

  static const _monthsShort = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  static const _weekdaysShort = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  static const _weekdaysLong = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// "FRI 31 JUL".
  static String dateLabel(DateTime date) {
    final local = date.toLocal();
    return '${_weekdaysShort[local.weekday - 1]} '
        '${local.day} ${_monthsShort[local.month - 1]}';
  }

  /// "Thursday 30 July" — the long form, for a sentence rather than a label.
  static String longDateLabel(DateTime date) {
    final local = date.toLocal();
    const months = [
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
    return '${_weekdaysLong[local.weekday - 1]} '
        '${local.day} ${months[local.month - 1]}';
  }

  static String weekdayName(DateTime date) =>
      _weekdaysLong[date.toLocal().weekday - 1];

  static int daysBetween(DateTime from, DateTime to) {
    return TrainingScheduleService.dateOnly(to)
        .difference(TrainingScheduleService.dateOnly(from))
        .inDays;
  }

  static TrainDayPresentation resolve({
    required DateTime date,
    required DateTime today,
    required bool isCompleted,
    required bool isMissed,
    required bool isRestDay,

    /// Where a missed session ended up, when the plan could say.
    DateTime? rescheduledTo,
    int builtHorizon = builtHorizonDays,
  }) {
    final distance = daysBetween(today, date);

    if (distance == 0) {
      return TrainDayPresentation(
        view: TrainDayView.today,
        eyebrow: 'TODAY · ${dateLabel(date)}',
      );
    }

    if (distance < 0) {
      if (isCompleted) {
        return TrainDayPresentation(
          view: TrainDayView.logged,
          eyebrow: 'LOGGED · ${dateLabel(date)}',
        );
      }
      if (isRestDay) {
        return TrainDayPresentation(
          view: TrainDayView.rest,
          eyebrow: 'REST · ${dateLabel(date)}',
        );
      }
      return TrainDayPresentation(
        view: TrainDayView.missed,
        eyebrow: 'MISSED · ${dateLabel(date)}',
        note: rescheduledTo == null
            ? const TrainDayNote(
                tag: 'STILL DUE',
                body: 'Nothing was logged here. The session stays next in '
                    'line rather than being dropped.',
              )
            : TrainDayNote(
                tag: 'RESCHEDULED',
                body: 'Forma moved this session to '
                    '${longDateLabel(rescheduledTo)}, the next open day. '
                    'The sessions after it slide along with it.',
              ),
      );
    }

    final eyebrow = '${_distanceLabel(distance)} · ${dateLabel(date)}';

    if (isRestDay) {
      return TrainDayPresentation(
        view: TrainDayView.rest,
        eyebrow: eyebrow,
      );
    }

    if (distance > builtHorizon) {
      return TrainDayPresentation(
        view: TrainDayView.distant,
        eyebrow: eyebrow,
        note: const TrainDayNote(
          tag: 'NOT BUILT YET',
          body: 'Beyond next week Forma only holds the shape of the week. '
              'The exercises get chosen from how the sessions before it '
              'went.',
        ),
      );
    }

    // No band: the dashed underline in the ribbon and the distance in the
    // eyebrow already say this day is ahead. Saying it a third time in a
    // sentence made every future day read as a disclaimer.
    return TrainDayPresentation(
      view: TrainDayView.soon,
      eyebrow: eyebrow,
    );
  }

  static String _distanceLabel(int days) {
    if (days == 1) return 'TOMORROW';
    return 'IN $days DAYS';
  }

  /// Whether a missed day's flag should be shown, marked, or ignored.
  static bool isPast(DateTime date, DateTime today) =>
      daysBetween(today, date) < 0;
}
