import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/home/weekly_quota.dart';

void main() {
  // Monday 9 November 2026 starts the week; Thursday the 12th is "now".
  final monday = DateTime(2026, 11, 9);
  final thursday = DateTime(2026, 11, 12, 9);

  WeeklyQuota quota(
    List<DateTime> dates, {
    int target = 3,
    DateTime? now,
  }) =>
      WeeklyQuota.resolve(
        sessionDates: dates,
        target: target,
        now: now ?? thursday,
      );

  group('the week', () {
    test('runs Monday to Sunday', () {
      expect(WeeklyQuota.weekStartOf(thursday), monday);
      expect(WeeklyQuota.weekStartOf(DateTime(2026, 11, 15, 23)), monday);
      expect(WeeklyQuota.weekStartOf(monday), monday);
      expect(WeeklyQuota.weekStartOf(DateTime(2026, 11, 16)),
          DateTime(2026, 11, 16));
    });

    test('counts the days left with today included', () {
      expect(quota([], now: monday).daysLeft, 7);
      expect(quota([]).daysLeft, 4);
      expect(quota([], now: DateTime(2026, 11, 15)).daysLeft, 1);
    });

    test('holds across a clock change', () {
      // Clocks go back on Sunday 25 October 2026 in Europe; whatever the
      // zone, the Monday before is still that week's start.
      expect(
        WeeklyQuota.weekStartOf(DateTime(2026, 10, 25, 12)),
        DateTime(2026, 10, 19),
      );
    });
  });

  group('the count', () {
    test('is nothing with no sessions', () {
      final week = quota([]);
      expect(week.done, 0);
      expect(week.remaining, 3);
      expect(week.isComplete, isFalse);
    });

    test('takes this week’s sessions and leaves last week’s out', () {
      final week = quota([
        DateTime(2026, 11, 6, 18), // last week
        DateTime(2026, 11, 9, 18),
        DateTime(2026, 11, 11, 7),
      ]);
      expect(week.done, 2);
      expect(week.remaining, 1);
    });

    test('a week that ended short leaves nothing behind', () {
      // One of three last week: this week still starts from zero.
      expect(quota([DateTime(2026, 11, 3)]).done, 0);
    });

    test('is complete at the target, and never reads past it', () {
      final week = quota([
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 10),
        DateTime(2026, 11, 11),
        DateTime(2026, 11, 12, 8),
      ]);
      expect(week.done, 3);
      expect(week.isComplete, isTrue);
      expect(week.remaining, 0);
    });

    test('a session past last week’s target opens this week', () {
      // Four last week on a three-a-week program: the fourth was this
      // week's first, started early.
      final week = quota([
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 5),
        DateTime(2026, 11, 7),
      ]);
      expect(week.done, 1);
    });

    test('carried sessions run out over weeks with nothing logged', () {
      // Four in the week of 26 October, nothing the week after: the one
      // carried was that empty week's, not this one's.
      final week = quota([
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 27),
        DateTime(2026, 10, 29),
        DateTime(2026, 10, 31),
      ]);
      expect(week.done, 0);
    });

    test('a target below one is read as one', () {
      final week = quota([DateTime(2026, 11, 10)], target: 0);
      expect(week.target, 1);
      expect(week.isComplete, isTrue);
    });
  });
}
