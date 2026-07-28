import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/home/train_day_view.dart';

void main() {
  final today = DateTime(2026, 7, 29);

  TrainDayPresentation resolve(
    DateTime date, {
    bool isCompleted = false,
    bool isMissed = false,
    bool isRestDay = false,
    DateTime? rescheduledTo,
  }) {
    return TrainDayViewResolver.resolve(
      date: date,
      today: today,
      isCompleted: isCompleted,
      isMissed: isMissed,
      isRestDay: isRestDay,
      rescheduledTo: rescheduledTo,
    );
  }

  group('which day the tab is looking at', () {
    test('today needs no explaining', () {
      final presentation = resolve(today);

      expect(presentation.view, TrainDayView.today);
      expect(presentation.eyebrow, isNull);
      expect(presentation.note, isNull);
    });

    test('a day inside the horizon is real but provisional', () {
      final presentation = resolve(DateTime(2026, 7, 31));

      expect(presentation.view, TrainDayView.soon);
      expect(presentation.eyebrow, 'IN 2 DAYS · FRI 31 JUL');
      expect(presentation.note!.tag, 'PROVISIONAL');
      expect(presentation.note!.body, contains('can still move'));
    });

    test('tomorrow says tomorrow', () {
      expect(resolve(DateTime(2026, 7, 30)).eyebrow, 'TOMORROW · THU 30 JUL');
    });

    test('the last day inside the horizon still carries its exercises', () {
      expect(resolve(DateTime(2026, 8, 5)).view, TrainDayView.soon);
    });

    test('a day past the horizon only holds its shape', () {
      final presentation = resolve(DateTime(2026, 8, 10));

      expect(presentation.view, TrainDayView.distant);
      expect(presentation.eyebrow, 'IN 12 DAYS · MON 10 AUG');
      expect(presentation.note!.tag, 'NOT BUILT YET');
    });

    test('a rest day ahead is a rest day, however far off', () {
      expect(
        resolve(DateTime(2026, 8, 10), isRestDay: true).view,
        TrainDayView.rest,
      );
      expect(
        resolve(DateTime(2026, 7, 30), isRestDay: true).view,
        TrainDayView.rest,
      );
    });

    test('a past day with a workout on it reads as logged', () {
      final presentation = resolve(DateTime(2026, 7, 27), isCompleted: true);

      expect(presentation.view, TrainDayView.logged);
      expect(presentation.eyebrow, 'LOGGED · MON 27 JUL');
      expect(presentation.note, isNull);
    });
  });

  group('a missed day says where its session went', () {
    test('naming the day it moved to', () {
      final presentation = resolve(
        DateTime(2026, 7, 27),
        isMissed: true,
        rescheduledTo: DateTime(2026, 7, 30),
      );

      expect(presentation.view, TrainDayView.missed);
      expect(presentation.eyebrow, 'MISSED · MON 27 JUL');
      expect(presentation.note!.tag, 'RESCHEDULED');
      expect(presentation.note!.body, contains('Thursday 30 July'));
      // The plan slides rather than dropping the session, and says so.
      expect(presentation.note!.body, contains('slide'));
    });

    test('and claiming nothing when the plan cannot say', () {
      final presentation = resolve(DateTime(2026, 7, 27), isMissed: true);

      expect(presentation.note!.tag, 'STILL DUE');
      expect(presentation.note!.body, isNot(contains('moved this session')));
    });
  });
}
