import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/training_program_model.dart';
import 'program_day_items.dart';

/// One training day of the week as the program currently stands.
class ProgramWeekDay {
  /// Monday-first weekday index.
  final int weekday;
  final List<ProgramDayItem> items;

  const ProgramWeekDay({required this.weekday, required this.items});
}

/// How often a primary category should be trained in a week. Two days is the
/// floor — below that the pattern holds rather than improves — and much past
/// three the extra work costs recovery instead of progress.
const int kBalanceTarget = 3;
const int kBalanceMinDays = 2;
const int kBalanceMaxDays = 5;

/// One line of the weekly balance: the movement patterns it covers, and
/// whether it is one of the primary categories the program is judged on.
class BalanceGroup {
  final String label;
  final Set<ExerciseCategory> categories;

  /// Core and skill work support the primary categories rather than being
  /// judged alongside them — the write-up calls them optional.
  final bool primary;

  const BalanceGroup({
    required this.label,
    required this.categories,
    this.primary = true,
  });
}

/// The five primary categories, then the two optional ones.
const List<BalanceGroup> kBalanceGroups = [
  BalanceGroup(
    label: 'Horizontal push',
    categories: {ExerciseCategory.horizontalPush},
  ),
  BalanceGroup(
    label: 'Vertical push',
    categories: {ExerciseCategory.verticalPush},
  ),
  BalanceGroup(
    label: 'Horizontal pull',
    categories: {ExerciseCategory.horizontalPull},
  ),
  BalanceGroup(
    label: 'Vertical pull',
    categories: {ExerciseCategory.verticalPull},
  ),
  BalanceGroup(
    label: 'Legs',
    categories: {ExerciseCategory.squat, ExerciseCategory.hinge},
  ),
  BalanceGroup(
    label: 'Core',
    categories: {ExerciseCategory.core},
    primary: false,
  ),
  BalanceGroup(
    label: 'Skill work',
    categories: {ExerciseCategory.skill},
    primary: false,
  ),
];

enum BalanceVerdict { missing, underloaded, optimal, overloaded, optional }

extension BalanceVerdictX on BalanceVerdict {
  String get label {
    switch (this) {
      case BalanceVerdict.missing:
        return 'Missing';
      case BalanceVerdict.underloaded:
        return 'Underloaded';
      case BalanceVerdict.optimal:
        return 'Optimal';
      case BalanceVerdict.overloaded:
        return 'Overloaded';
      case BalanceVerdict.optional:
        return 'Optional';
    }
  }

  Color get color {
    switch (this) {
      case BalanceVerdict.optimal:
        return AppColors.green;
      case BalanceVerdict.optional:
        return AppColors.textMuted;
      case BalanceVerdict.missing:
      case BalanceVerdict.underloaded:
      case BalanceVerdict.overloaded:
        return AppColors.amber;
    }
  }
}

/// One group measured against the week: which exercises train it, on which
/// days, and how that reads against its target.
class BalanceCategory {
  final BalanceGroup group;

  /// Exercise name → the weekdays it runs on.
  final Map<String, List<int>> exerciseDays;

  const BalanceCategory({required this.group, required this.exerciseDays});

  String get label => group.label;
  int get target => kBalanceTarget;
  bool covers(ProgramDayItem item) => group.categories.contains(item.category);

  /// How many training days a week this category comes up on. Two exercises
  /// of the same category in one session are one go at that pattern, not two.
  int get times => {
        for (final days in exerciseDays.values) ...days,
      }.length;

  /// Exercise blocks a week — every exercise counted on every day it runs.
  /// Used for the evenness checks between sides.
  int get blocks =>
      exerciseDays.values.fold(0, (sum, days) => sum + days.length);

  BalanceVerdict get verdict {
    if (!group.primary) return BalanceVerdict.optional;
    if (exerciseDays.isEmpty) return BalanceVerdict.missing;
    if (times < kBalanceMinDays) return BalanceVerdict.underloaded;
    if (times > kBalanceMaxDays) return BalanceVerdict.overloaded;
    return BalanceVerdict.optimal;
  }
}

/// A pairing that has drifted apart — pushing against pulling, or the
/// horizontal against the vertical half of both.
class BalanceEvenness {
  final String label;
  final String detail;

  const BalanceEvenness({required this.label, required this.detail});
}

int _blocksIn(List<ProgramWeekDay> week, Set<ExerciseCategory> categories) {
  var blocks = 0;
  for (final day in week) {
    for (final item in day.items) {
      if (categories.contains(item.category)) blocks++;
    }
  }
  return blocks;
}

/// Push and pull should stay within a block of each other, and the two
/// directions within two.
List<BalanceEvenness> balanceEvenness(List<ProgramWeekDay> week) {
  final push = _blocksIn(week, {
    ExerciseCategory.horizontalPush,
    ExerciseCategory.verticalPush,
  });
  final pull = _blocksIn(week, {
    ExerciseCategory.horizontalPull,
    ExerciseCategory.verticalPull,
  });
  final horizontal = _blocksIn(week, {
    ExerciseCategory.horizontalPush,
    ExerciseCategory.horizontalPull,
  });
  final vertical = _blocksIn(week, {
    ExerciseCategory.verticalPush,
    ExerciseCategory.verticalPull,
  });

  return [
    if ((push - pull).abs() > 1)
      BalanceEvenness(
        label: push > pull ? 'More push than pull' : 'More pull than push',
        detail: '$push push blocks against $pull pull — they should stay '
            'within one of each other so neither side falls behind.',
      ),
    if ((horizontal - vertical).abs() > 2)
      BalanceEvenness(
        label: horizontal > vertical
            ? 'More horizontal than vertical'
            : 'More vertical than horizontal',
        detail: '$horizontal horizontal blocks against $vertical vertical — '
            'more than two apart leaves one plane under-practised.',
      ),
  ];
}

/// Reads the week into one entry per group.
List<BalanceCategory> balanceFromWeek(List<ProgramWeekDay> week) {
  return [
    for (final group in kBalanceGroups)
      BalanceCategory(
        group: group,
        exerciseDays: () {
          final days = <String, List<int>>{};
          for (final day in week) {
            for (final item in day.items) {
              if (!group.categories.contains(item.category)) continue;
              (days[item.name] ??= []).add(day.weekday);
            }
          }
          return days;
        }(),
      ),
  ];
}

/// "Vertical pull underloaded, more push than pull" — or all clear.
String balanceHeadline(
  List<BalanceCategory> categories, [
  List<BalanceEvenness> evenness = const [],
]) {
  final off = [
    for (final entry in categories)
      if (entry.group.primary && entry.verdict != BalanceVerdict.optimal)
        '${entry.label} ${entry.verdict.label.toLowerCase()}',
    for (final warning in evenness) warning.label.toLowerCase(),
  ];
  if (off.isEmpty) return 'Every category optimal';
  return off.join(', ');
}

/// Full-page read of how often each movement category comes up in the week.
class ProgramBalanceView extends StatelessWidget {
  final List<ProgramWeekDay> week;

  const ProgramBalanceView({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final categories = balanceFromWeek(week);
    final evenness = balanceEvenness(week);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageHeader(title: 'Weekly balance'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 40),
                children: [
                  for (final entry in categories)
                    _CategoryRow(
                      entry: entry,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _CategoryDetailView(
                            entry: entry,
                            week: week,
                          ),
                        ),
                      ),
                    ),
                  if (evenness.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 2),
                      child: Text(
                        'EVENNESS',
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1.65,
                        ),
                      ),
                    ),
                    for (final warning in evenness) _EvennessRow(warning),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Why one category reads the way it does: the week day by day, then what is
/// short (or over) and the concrete ways to change it.
class _CategoryDetailView extends StatelessWidget {
  final BalanceCategory entry;
  final List<ProgramWeekDay> week;

  const _CategoryDetailView({required this.entry, required this.week});

  @override
  Widget build(BuildContext context) {
    final verdict = entry.verdict;
    final times = entry.times;
    final over = verdict == BalanceVerdict.overloaded;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              title: entry.label,
              sub: verdict == BalanceVerdict.optional
                  ? 'Optional · $times ${times == 1 ? 'day' : 'days'} a week'
                  : over
                      ? '$times days a week · target ${entry.target}'
                      : '$times of ${entry.target} days a week',
              subColor: verdict.color,
              subWeight: FontWeight.w600,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
                children: [
                  for (final day in week)
                    _DayRow(
                      weekday: day.weekday,
                      names: [
                        for (final item in day.items)
                          if (entry.covers(item)) item.name,
                      ],
                    ),
                  if (verdict == BalanceVerdict.optional)
                    Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Text(
                        '${entry.label} backs up the primary categories '
                        'rather than being judged alongside them — train it '
                        'as much or as little as suits you.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    )
                  else if (verdict == BalanceVerdict.optimal)
                    Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Text(
                        '${entry.label} is where it should be: $times days a '
                        'week against a target of ${entry.target}.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        _headline,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _explanation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 26, bottom: 2),
                      child: Text(
                        over ? 'WHAT WOULD EVEN IT OUT' : 'WHAT WOULD FIX IT',
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1.65,
                        ),
                      ),
                    ),
                    for (final fix in _fixes) _FixRow(fix),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The single exercise carrying this category, when there is only one.
  MapEntry<String, List<int>>? get _onlyExercise =>
      entry.exerciseDays.length == 1 ? entry.exerciseDays.entries.first : null;

  /// Training days this category never appears on.
  List<int> get _missingDays => [
        for (final day in week)
          if (!day.items.any(entry.covers))
            day.weekday,
      ];

  String get _headline {
    final times = entry.times;
    switch (entry.verdict) {
      case BalanceVerdict.missing:
        return 'Nothing in your week trains this';
      case BalanceVerdict.overloaded:
        return '$times days a week, ${times - entry.target} over';
      case BalanceVerdict.underloaded:
        final only = _onlyExercise;
        if (only != null) {
          return 'One exercise, ${only.value.length}× a week';
        }
        return '${entry.target - times} short of ${entry.target} days a week';
      case BalanceVerdict.optimal:
      case BalanceVerdict.optional:
        return '';
    }
  }

  String get _explanation {
    final times = entry.times;
    final wants = '${entry.label} wants about ${entry.target} training days '
        'a week.';

    if (entry.verdict == BalanceVerdict.overloaded) {
      return '$wants You are at $times. Past the target the extra work mostly '
          'costs you recovery rather than progress — and it crowds out '
          'whatever else the session needs.';
    }

    final only = _onlyExercise;
    final because = only == null
        ? ''
        : ', because ${only.key} only runs on '
            '${_dayList(only.value)}';
    return '$wants You are at $times$because. Under $kBalanceMinDays days a '
        'week the pattern barely improves; at ${entry.target} it progresses '
        'steadily.';
  }

  List<String> get _fixes {
    final times = entry.times;

    if (entry.verdict == BalanceVerdict.overloaded) {
      final last = entry.exerciseDays.entries.last;
      return [
        'Take ${last.key} out of some sessions — it currently runs on '
            '${_dayList(last.value)}',
        'Or drop the pattern from a day entirely, so it comes up on '
            '$kBalanceMaxDays days at most',
        'Or leave it, as long as the sessions still feel manageable',
      ];
    }

    final only = _onlyExercise;
    final missing = _missingDays;
    return [
      if (only != null && missing.isNotEmpty)
        'Run ${only.key} on ${_dayList(missing)} too — that alone gets you '
            'to ${times + missing.length} days',
      'Add ${entry.exerciseDays.isEmpty ? 'a' : 'another'} '
          '${entry.label.toLowerCase()} exercise to your sessions',
      'Or leave it — as long as the opposite side stays even with it',
    ];
  }

  String _dayList(List<int> weekdays) {
    final names = [for (final day in weekdays) kWeekdayNames[day]];
    if (names.length < 2) return names.join();
    return '${names.take(names.length - 1).join(', ')} and ${names.last}';
  }
}

/// Back chevron over a display title, shared by both balance pages.
class _PageHeader extends StatelessWidget {
  final String title;

  /// Optional — the balance list needs no line under its title.
  final String? sub;
  final Color subColor;
  final FontWeight subWeight;

  const _PageHeader({
    required this.title,
    this.sub,
    this.subColor = AppColors.textSecondary,
    this.subWeight = FontWeight.w400,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.only(right: 12, bottom: 4),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.9,
              height: 1.05,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(
              sub!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: subWeight,
                color: subColor,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final BalanceCategory entry;
  final VoidCallback onTap;

  const _CategoryRow({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final verdict = entry.verdict;

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 15, bottom: 17),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.25,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              verdict.label.toUpperCase(),
              style: GoogleFonts.robotoMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: verdict.color,
                letterSpacing: 1.05,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _EvennessRow extends StatelessWidget {
  final BalanceEvenness warning;

  const _EvennessRow(this.warning);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 17),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            warning.label,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.amber,
              letterSpacing: -0.25,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            warning.detail,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final int weekday;
  final List<String> names;

  const _DayRow({required this.weekday, required this.names});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                kWeekdayNames[weekday].substring(0, 3).toUpperCase(),
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (names.isEmpty)
                  const Text(
                    '—',
                    style: TextStyle(fontSize: 15, color: AppColors.textMuted),
                  )
                else
                  for (final name in names)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC9CAD1),
                          letterSpacing: -0.15,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FixRow extends StatelessWidget {
  final String text;

  const _FixRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface3,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFC9CAD1),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
