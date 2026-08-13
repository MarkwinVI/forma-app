import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_schedule_service.dart';
import 'program_balance_advice.dart';
import 'program_day_items.dart';

/// One training day of the week as the program currently stands.
class ProgramWeekDay {
  /// Monday-first weekday index.
  final int weekday;

  /// What the split makes this day — which movements it can hold at all.
  final TrainingSessionType sessionType;
  final List<ProgramDayItem> items;

  const ProgramWeekDay({
    required this.weekday,
    required this.sessionType,
    required this.items,
  });
}

/// The program facts the balance copy needs beyond the week itself: what the
/// split is, what equipment the user has, and which trees they already run.
class BalanceProgramContext {
  final TrainingProgramType programType;
  final int trainingDaysPerWeek;
  final bool hasGym;
  final List<SkillTrack> skillTracks;
  final Map<String, ExerciseStatus> progressMap;

  /// Skill categories behind the goals the user picked at setup. A goal tree
  /// is never the one we suggest pausing.
  final Set<String> goalSkillCategoryIds;

  const BalanceProgramContext({
    required this.programType,
    required this.trainingDaysPerWeek,
    this.hasGym = true,
    this.skillTracks = const [],
    this.progressMap = const {},
    this.goalSkillCategoryIds = const {},
  });
}

/// One scheduled block: an exercise of the movement on a given day. Two
/// blocks can land on the same day — that is what makes a movement doubled
/// up rather than simply frequent.
class BalanceBlock {
  final int weekday;
  final ProgramDayItem item;

  const BalanceBlock({required this.weekday, required this.item});
}

/// The weekly block count a primary category is recommended to sit at.
///
/// The same benchmark whatever the split. A split that only reaches horizontal
/// pull twice a week does not lower what horizontal pull needs — it is the
/// split that has to give.
const int kBalanceMinBlocks = 3;

/// Below this many weekly-equivalent chances, the split itself is what holds
/// a movement back — the advice reaches for the schedule instead of an
/// exercise.
const int kBalanceMinDays = 2;

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

/// The six primary categories, then the two optional ones. Knee-dominant and
/// hip-dominant leg work are judged apart: squats cannot stand in for a week
/// with no hinge in it.
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
    label: 'Squats & lunges',
    categories: {ExerciseCategory.squat},
  ),
  BalanceGroup(
    label: 'Glutes & hamstrings',
    categories: {ExerciseCategory.hinge},
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

/// Where a category sits, read straight off its weekly blocks:
/// 0 missing, 1 low, 2 good, 3 recommended, 4 and up high.
enum BalanceVerdict {
  missing,
  low,
  good,
  recommended,
  high,
  optional,
}

extension BalanceVerdictX on BalanceVerdict {
  String get label {
    switch (this) {
      case BalanceVerdict.missing:
        return 'Missing';
      case BalanceVerdict.low:
        return 'Low';
      case BalanceVerdict.good:
        return 'Good';
      case BalanceVerdict.recommended:
        return 'Recommended';
      case BalanceVerdict.high:
        return 'High';
      case BalanceVerdict.optional:
        return 'Optional';
    }
  }

  /// Whether the settings row counts this as fine: enough weekly work
  /// without tipping into too much.
  bool get onTarget =>
      this == BalanceVerdict.good ||
      this == BalanceVerdict.recommended ||
      this == BalanceVerdict.optional;

  /// How the settings row counts this verdict: "2 areas undertrained",
  /// where "Low" would read as one area speaking for two.
  String get summaryWord {
    switch (this) {
      case BalanceVerdict.missing:
        return 'missing';
      case BalanceVerdict.low:
        return 'undertrained';
      case BalanceVerdict.high:
        return 'overtrained';
      case BalanceVerdict.good:
      case BalanceVerdict.recommended:
        return 'balanced';
      case BalanceVerdict.optional:
        return 'optional';
    }
  }

  Color get color {
    switch (this) {
      case BalanceVerdict.missing:
      case BalanceVerdict.low:
        return AppColors.red;
      // Both are cautions rather than faults: good is short of the
      // recommendation, high is past it.
      case BalanceVerdict.good:
      case BalanceVerdict.high:
        return AppColors.amber;
      case BalanceVerdict.recommended:
        return AppColors.green;
      case BalanceVerdict.optional:
        return AppColors.textMuted;
    }
  }
}

/// One group measured against the week: which exercises train it, on which
/// days, and how that reads against its target.
class BalanceCategory {
  final BalanceGroup group;

  /// Every scheduled block of this movement, in week order.
  final List<BalanceBlock> blocks;

  /// How many days a week the split could train this movement. Fractional on
  /// purpose: a three-day upper/lower split runs each session an average of
  /// 1.5 times a week. Null when the week was read without program context.
  final double? opportunities;

  const BalanceCategory({
    required this.group,
    required this.blocks,
    this.opportunities,
  });

  String get label => group.label;
  bool covers(ProgramDayItem item) => group.categories.contains(item.category);

  /// Exercise name → the weekdays it runs on, in the order the week lists it.
  Map<String, List<int>> get exerciseDays {
    final days = <String, List<int>>{};
    for (final block in blocks) {
      (days[block.item.name] ??= []).add(block.weekday);
    }
    return days;
  }

  /// Every scheduled block, however they fall across the week. Two exercises
  /// of this movement in one session are two blocks but one day.
  int get weeklyBlocks => blocks.length;

  /// How many training days a week this category comes up on. Two exercises
  /// of the same category in one session are one go at that pattern, not two.
  int get times => {for (final block in blocks) block.weekday}.length;

  /// Blocks alone decide the read — every category held to the same scale.
  BalanceVerdict get verdict {
    if (!group.primary) return BalanceVerdict.optional;
    return switch (weeklyBlocks) {
      0 => BalanceVerdict.missing,
      1 => BalanceVerdict.low,
      2 => BalanceVerdict.good,
      3 => BalanceVerdict.recommended,
      _ => BalanceVerdict.high,
    };
  }
}

/// The sentence the detail page shows under the week: what the current
/// weekly exposure means for progress.
String balanceStatusCopy(BalanceCategory entry) {
  final label = entry.label;
  switch (entry.verdict) {
    case BalanceVerdict.missing:
      return 'You’re not currently training $label. Add it to keep your '
          'program balanced.';
    case BalanceVerdict.low:
      return 'You’re training $label once per week. Increasing it to at '
          'least twice per week should support more consistent progress.';
    case BalanceVerdict.good:
      return 'You’re training $label twice per week. That’s enough to make '
          'solid progress, though training it 3 times per week may help you '
          'progress faster.';
    case BalanceVerdict.recommended:
      return 'You’re training $label 3 times per week — a strong frequency '
          'for progressing efficiently.';
    case BalanceVerdict.high:
      return 'You’re training $label frequently. This can work well, but '
          'make sure you’re recovering well and not overtraining.';
    case BalanceVerdict.optional:
      return '$label backs up the primary categories rather than being '
          'judged alongside them — train it as much or as little as suits '
          'you.';
  }
}

/// Reads the week into one entry per group. The verdict is the same either
/// way — pass [context] so the advice knows how many chances the split gives
/// a movement, which is what decides whether the split is the thing to change.
List<BalanceCategory> balanceFromWeek(
  List<ProgramWeekDay> week, {
  BalanceProgramContext? context,
}) {
  return [
    for (final group in kBalanceGroups)
      BalanceCategory(
        group: group,
        opportunities:
            context == null ? null : _opportunitiesFor(group, context),
        blocks: [
          for (final day in week)
            for (final item in day.items)
              if (group.categories.contains(item.category))
                BalanceBlock(weekday: day.weekday, item: item),
        ],
      ),
  ];
}

/// Weekly-equivalent chances the split gives a movement: the training days a
/// week, times the share of the split's rotation that can hold it. Three days
/// of upper/lower is 1.5 upper days a week, not 2 — the week the Program tab
/// draws just happens to start on whichever session comes first.
double _opportunitiesFor(BalanceGroup group, BalanceProgramContext context) {
  final sequence =
      TrainingScheduleService().trainingSequenceFor(context.programType);
  if (sequence.isEmpty) return 0;

  final covering = sequence
      .where(
        (session) => TrainingProgramService.patternsForSession(session)
            .any(group.categories.contains),
      )
      .length;
  return context.trainingDaysPerWeek * covering / sequence.length;
}

/// "2 areas undertrained", "1 area overtrained" — or all clear.
/// The value the Program tab shows against "Weekly balance" — a settings-row
/// value, so it counts the areas that are off rather than naming them.
String balanceSummary(List<BalanceCategory> categories) {
  final off = [
    for (final entry in categories)
      if (entry.group.primary && !entry.verdict.onTarget) entry.verdict,
  ];
  if (off.isEmpty) return 'Balanced';

  final noun = off.length == 1 ? 'area' : 'areas';
  final kinds = off.toSet();
  if (kinds.length == 1) {
    return '${off.length} $noun ${kinds.first.summaryWord}';
  }
  return '${off.length} $noun off target';
}

/// Full-page read of how often each movement category comes up in the week.
class ProgramBalanceView extends StatelessWidget {
  final List<ProgramWeekDay> week;
  final BalanceProgramContext program;

  const ProgramBalanceView({
    super.key,
    required this.week,
    required this.program,
  });

  @override
  Widget build(BuildContext context) {
    final categories = balanceFromWeek(week, context: program);

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
                            program: program,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Why one category reads the way it does: the week day by day, what the
/// current exposure means — and, only when it is missing or low, the
/// concrete ways to improve it.
class _CategoryDetailView extends StatelessWidget {
  final BalanceCategory entry;
  final List<ProgramWeekDay> week;
  final BalanceProgramContext program;

  const _CategoryDetailView({
    required this.entry,
    required this.week,
    required this.program,
  });

  @override
  Widget build(BuildContext context) {
    final verdict = entry.verdict;
    final times = entry.times;
    final blocks = entry.weeklyBlocks;
    final advice = verdict == BalanceVerdict.missing ||
            verdict == BalanceVerdict.low
        ? balanceImprovementAdvice(entry: entry, week: week, context: program)
        : const <BalanceAdvice>[];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              title: entry.label,
              // Blocks, not days — a movement can sit on three days and
              // still be doubled up on one of them.
              sub: verdict == BalanceVerdict.optional
                  ? 'Optional · $times ${times == 1 ? 'day' : 'days'} a week'
                  : '$blocks ${blocks == 1 ? 'block' : 'blocks'} a week',
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
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Text(
                      balanceStatusCopy(entry),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  if (advice.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 26, bottom: 2),
                      child: Text(
                        'WAYS TO IMPROVE IT',
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1.65,
                        ),
                      ),
                    ),
                    for (final fix in advice) _FixRow(fix),
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

/// One suggested action: what to do, then why, so the list reads as choices
/// rather than a wall of sentences.
class _FixRow extends StatelessWidget {
  final BalanceAdvice advice;

  const _FixRow(this.advice);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advice.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  advice.detail,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
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
