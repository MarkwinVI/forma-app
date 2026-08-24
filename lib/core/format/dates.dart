import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date and time wording that follows the device — its language for month
/// and weekday names, its 12/24-hour setting for clock times — instead of
/// the English, 12-hour strings the screens used to spell out by hand.
///
/// Every helper takes a [BuildContext] so the locale comes from the widget
/// tree ([Localizations.localeOf]) and the clock preference from
/// [MediaQuery.alwaysUse24HourFormatOf].
class FormaDates {
  FormaDates._();

  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).toString();

  /// "14:05" or "2:05 PM", per the device's 24-hour setting.
  static String time(BuildContext context, DateTime at) {
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final f = use24 ? DateFormat.Hm(_locale(context)) : DateFormat.jm(_locale(context));
    return f.format(at);
  }

  /// "Aug" — abbreviated month.
  static String monthShort(BuildContext context, DateTime at) =>
      DateFormat.MMM(_locale(context)).format(at);

  /// "August" — full month.
  static String monthLong(BuildContext context, DateTime at) =>
      DateFormat.MMMM(_locale(context)).format(at);

  /// "August 2026" — month and year, for calendar headers.
  static String monthYear(BuildContext context, DateTime at) =>
      DateFormat.yMMMM(_locale(context)).format(at);

  /// "Aug 19" — abbreviated month and day.
  static String monthDay(BuildContext context, DateTime at) =>
      DateFormat.MMMd(_locale(context)).format(at);

  /// "Wed, Aug 19" — abbreviated weekday, month and day.
  static String weekdayMonthDay(BuildContext context, DateTime at) =>
      DateFormat.MMMEd(_locale(context)).format(at);

  /// "Wednesday" — full weekday.
  static String weekdayLong(BuildContext context, DateTime at) =>
      DateFormat.EEEE(_locale(context)).format(at);

  /// "Wednesday" for a Monday-first index 0..6 — program days that are a
  /// weekday slot rather than a date.
  static String weekdayLongByIndex(BuildContext context, int mondayFirstIndex) =>
      // 2024-01-01 is a Monday.
      weekdayLong(context, DateTime(2024, 1, 1 + mondayFirstIndex));

  /// "Wednesday, August 19" — full weekday, month and day, for a sentence.
  static String weekdayMonthDayLong(BuildContext context, DateTime at) =>
      DateFormat.MMMMEEEEd(_locale(context)).format(at);

  /// "Wed" — abbreviated weekday.
  static String weekdayShort(BuildContext context, DateTime at) =>
      DateFormat.E(_locale(context)).format(at);

  /// One-letter weekday, Monday-first index 0..6 ("M", "T", …), in the
  /// device's language.
  static String weekdayLetter(BuildContext context, int mondayFirstIndex) {
    // 2024-01-01 is a Monday.
    final day = DateTime(2024, 1, 1 + mondayFirstIndex);
    final narrow = DateFormat.E(_locale(context)).format(day);
    return narrow.isEmpty ? '' : narrow.characters.first.toUpperCase();
  }

  /// "Aug 19, 2026" — medium date.
  static String mediumDate(BuildContext context, DateTime at) =>
      DateFormat.yMMMd(_locale(context)).format(at);
}
