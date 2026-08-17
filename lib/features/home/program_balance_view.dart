import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_schedule_service.dart';
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
/// blocks can land on the same day, and the balance counts that day once —
/// a second horizontal push in the same session is more volume, not more
/// frequency.
class BalanceBlock {
  final int weekday;
  final ProgramDayItem item;

  const BalanceBlock({required this.weekday, required this.item});
}

/// The most weekly sessions of one movement a program is asked for. A split
/// that could reach a movement five times a week does not make five the
/// target — past three, the extra days stop paying for themselves.
const int kBalanceMaxTarget = 3;

/// What a split asks for however few days it is run on. Full body trains
/// everything every session, so it asks for three whatever the week holds; a
/// two-session split asks for two. Training fewer days than that does not
/// lower what the movement needs — it is the schedule that has to give.
int kBalanceMinTarget(TrainingProgramType programType) =>
    programType == TrainingProgramType.fullBody ? 3 : 2;

/// One line of the weekly balance: the movement patterns it covers.
class BalanceGroup {
  final String label;
  final Set<ExerciseCategory> categories;

  const BalanceGroup({required this.label, required this.categories});
}

/// The six categories the program is judged on. Core and skill work support
/// them rather than being measured alongside them, so neither is listed.
/// Knee-dominant and hip-dominant leg work are judged apart: squats cannot
/// stand in for a week with no hinge in it.
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
];

/// Where a category sits: 0 days missing, 1 low, 5 and up very high, and
/// everything between read against what the split recommends — short of the
/// target is adequate, on it recommended, past it high.
enum BalanceVerdict {
  missing,
  low,
  adequate,
  recommended,
  high,
  veryHigh,
}

extension BalanceVerdictX on BalanceVerdict {
  String get label {
    switch (this) {
      case BalanceVerdict.missing:
        return 'Missing';
      case BalanceVerdict.low:
        return 'Low';
      case BalanceVerdict.adequate:
        return 'Adequate';
      case BalanceVerdict.recommended:
        return 'Recommended';
      case BalanceVerdict.high:
        return 'High';
      case BalanceVerdict.veryHigh:
        return 'Very high';
    }
  }

  /// Whether the settings row counts this as fine: enough weekly work
  /// without tipping into too much. Adequate and high are cautions rather
  /// than faults, so neither calls the program unbalanced.
  bool get onTarget =>
      this == BalanceVerdict.adequate ||
      this == BalanceVerdict.recommended ||
      this == BalanceVerdict.high;

  /// How the settings row counts this verdict: "2 areas undertrained",
  /// where "Low" would read as one area speaking for two.
  String get summaryWord {
    switch (this) {
      case BalanceVerdict.missing:
        return 'missing';
      case BalanceVerdict.low:
        return 'undertrained';
      case BalanceVerdict.veryHigh:
        return 'overtrained';
      case BalanceVerdict.adequate:
      case BalanceVerdict.recommended:
      case BalanceVerdict.high:
        return 'balanced';
    }
  }

  Color get color {
    switch (this) {
      case BalanceVerdict.missing:
      case BalanceVerdict.low:
      case BalanceVerdict.veryHigh:
        return AppColors.red;
      // Both are cautions rather than faults: adequate is short of the
      // recommendation, high is past it.
      case BalanceVerdict.adequate:
      case BalanceVerdict.high:
        return AppColors.amber;
      case BalanceVerdict.recommended:
        return AppColors.green;
    }
  }
}

/// One group measured against the week: which exercises train it, on which
/// days, and how that reads against its target.
class BalanceCategory {
  final BalanceGroup group;

  /// Every scheduled block of this movement, in week order.
  final List<BalanceBlock> blocks;

  /// The days a week the program recommends this movement: what the split
  /// gives it, never below what the split asks for and never above three.
  /// Full body recommends three; both four-day splits come back to a
  /// movement twice a week, so twice is what they recommend.
  final int target;

  /// The days this week whose session trains the movement at all — what the
  /// generated program would cover before any exercise was added or taken
  /// away. Three days of push/pull is two push days and one pull day, so
  /// pull movements are expected once that week and push movements twice.
  final int expected;

  const BalanceCategory({
    required this.group,
    required this.blocks,
    required this.expected,
    this.target = kBalanceMaxTarget,
  });

  String get label => group.label;
  bool covers(ProgramDayItem item) => group.categories.contains(item.category);

  /// Every scheduled exercise of this movement, however they fall across the
  /// week — the volume behind the frequency.
  int get weeklyBlocks => blocks.length;

  /// How many training days a week this category comes up on. Two exercises
  /// of the same category in one session are one go at that pattern, not two.
  int get times => {for (final block in blocks) block.weekday}.length;

  /// Days decide the read, against the target the split sets. Nothing at all
  /// and a single day are off wherever the split lands, and so is a movement
  /// trained five days a week.
  BalanceVerdict get verdict {
    if (times == 0) return BalanceVerdict.missing;
    if (times == 1) return BalanceVerdict.low;
    if (times > 4) return BalanceVerdict.veryHigh;
    if (times < target) return BalanceVerdict.adequate;
    if (times == target) return BalanceVerdict.recommended;
    return BalanceVerdict.high;
  }

  /// A movement the week does not train often enough to leave alone. Two days
  /// against a target of three is a nudge, not a fault, so it is not counted
  /// here — only nothing at all, or a single day.
  bool get isShort =>
      verdict == BalanceVerdict.missing || verdict == BalanceVerdict.low;

  /// The week trains this movement less often than the generated program
  /// would have: exercises were taken out of workouts, or moved onto days
  /// that already trained it.
  bool get shortOfProgram => times < expected;

  /// The program itself cannot reach the recommended frequency — whatever
  /// the workouts hold, this split on these days does not come back to the
  /// movement often enough.
  bool get shortOfSplit => expected < target;
}

/// The sentence the detail page shows under the week: what the current
/// weekly exposure means for progress.
String balanceStatusCopy(BalanceCategory entry) {
  final label = entry.label;
  final movement = label.toLowerCase();
  switch (entry.verdict) {
    case BalanceVerdict.missing:
      return 'You’re not currently training $movement. Add a $movement '
          'exercise to one of your workouts.';
    case BalanceVerdict.low:
      return 'You’re training $movement once per week. Add a $movement '
          'exercise to another workout to train it more consistently.';
    case BalanceVerdict.adequate:
      return 'You’re training $movement twice per week. That’s enough to '
          'make solid progress, but adding it to one more workout would '
          'match the recommended frequency for your program.';
    case BalanceVerdict.recommended:
      return 'You’re training $movement at the recommended frequency for '
          'your program.';
    case BalanceVerdict.high:
      return 'You’re training $movement more often than your program '
          'requires. This can work well if your training volume and recovery '
          'are appropriate.';
    case BalanceVerdict.veryHigh:
      return 'You’re training $movement very frequently. Consider removing '
          'it from one or more workout days if recovery or performance '
          'becomes an issue.';
  }
}

/// Reads the week into one entry per group. Pass [context] so each entry
/// knows how many chances the split gives its movement — that is what the
/// verdict is measured against.
List<BalanceCategory> balanceFromWeek(
  List<ProgramWeekDay> week, {
  BalanceProgramContext? context,
}) {
  return [
    for (final group in kBalanceGroups)
      BalanceCategory(
        group: group,
        target: context == null ? kBalanceMaxTarget : _targetFor(group, context),
        expected: week
            .where(
              (day) => TrainingProgramService.patternsForSession(day.sessionType)
                  .any(group.categories.contains),
            )
            .length,
        blocks: [
          for (final day in week)
            for (final item in day.items)
              if (group.categories.contains(item.category))
                BalanceBlock(weekday: day.weekday, item: item),
        ],
      ),
  ];
}

/// The days a week the program recommends a movement: what the split gives
/// it, held between what the split asks for and three. Six days of full body
/// could reach a movement six times, and still recommends three.
int _targetFor(BalanceGroup group, BalanceProgramContext context) {
  return _opportunitiesFor(group, context).floor().clamp(
        kBalanceMinTarget(context.programType),
        kBalanceMaxTarget,
      );
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

/// Why the week reads the way it does, once every movement has been placed
/// against both what the program would have covered and what the split can
/// reach. The distinction is what makes the top-level fix the right one:
/// another training day does nothing for a movement the user deleted, and
/// putting exercises back does nothing for a split that never comes round.
enum BalanceCause {
  balanced,

  /// The split on these days cannot reach the recommendation, whatever the
  /// workouts hold.
  schedule,

  /// The generated program covered it; edits to the workouts took it away.
  workoutEdits,

  /// Both, and they compound.
  mixed,

  /// Nothing is short, but something is trained near daily.
  veryHigh,
}

/// The read of the whole week, shown above the movement rows: what is wrong,
/// and the highest-level thing that would fix it.
class BalanceBanner {
  final BalanceCause cause;

  /// What the week is doing, in one sentence.
  final String headline;

  /// What to do about it.
  final String detail;

  const BalanceBanner({
    required this.cause,
    required this.headline,
    required this.detail,
  });
}

/// Reads the whole week: which movements fall short, and whether the split or
/// the workouts put them there.
BalanceBanner balanceBannerFor(
  List<BalanceCategory> categories,
  BalanceProgramContext context,
) {
  final short = [
    for (final entry in categories)
      if (entry.isShort) entry,
  ];

  if (short.isEmpty) {
    if (categories.any((entry) => entry.verdict == BalanceVerdict.veryHigh)) {
      return const BalanceBanner(
        cause: BalanceCause.veryHigh,
        headline: 'Some movement patterns are being trained very frequently.',
        detail: 'Review the areas below and reduce training frequency if '
            'recovery or performance becomes an issue.',
      );
    }
    return const BalanceBanner(
      cause: BalanceCause.balanced,
      headline: 'Your weekly balance looks good.',
      detail: 'Your main movement patterns are being trained at the '
          'recommended frequency for your program.',
    );
  }

  final fromSplit = short.any((entry) => entry.shortOfSplit);
  final fromEdits = short.any((entry) => entry.shortOfProgram);

  if (fromSplit && fromEdits) {
    return const BalanceBanner(
      cause: BalanceCause.mixed,
      headline: 'Your weekly balance is affected by both your training '
          'schedule and changes to your workouts.',
      detail: 'Restore the missing movement patterns first. You can then '
          'adjust your training days or split to improve the remaining '
          'low-frequency areas.',
    );
  }

  if (fromSplit) {
    return BalanceBanner(
      cause: BalanceCause.schedule,
      headline: 'Your weekly balance is uneven because you’re training '
          '${_routineName(context.programType)} '
          '${context.trainingDaysPerWeek} days per week.',
      detail: _scheduleFix(context),
    );
  }

  // Nothing about the split explains it: the program covered these movements
  // and the workouts no longer do.
  return const BalanceBanner(
    cause: BalanceCause.workoutEdits,
    headline: 'Some movement patterns are missing or trained less often '
        'because of changes to your workouts.',
    detail: 'Add exercises back to the affected workouts or add standalone '
        'exercises to the areas below.',
  );
}

/// "a Push / Pull routine" — the split named as the user picked it, so the
/// banner and the Split row read as the same thing.
String _routineName(TrainingProgramType programType) {
  final label = programType.label;
  final article = 'AEIOU'.contains(label[0]) ? 'an' : 'a';
  return '$article $label routine';
}

/// The way out of a schedule-caused imbalance: a fourth day is what makes a
/// two-session split even, so it leads — unless the program is already there,
/// or is full body, which has no other split to move to.
String _scheduleFix(BalanceProgramContext context) {
  if (context.programType == TrainingProgramType.fullBody) {
    return 'Add another training day, or add standalone exercises to the '
        'low-frequency areas below.';
  }
  if (context.trainingDaysPerWeek < 4) {
    return 'Increase to 4 training days, switch to Full Body, or add '
        'standalone exercises to the low-frequency areas below.';
  }
  return 'Add another training day, switch to Full Body, or add standalone '
      'exercises to the low-frequency areas below.';
}

/// "2 areas undertrained", "1 area overtrained" — or all clear.
/// The value the Program tab shows against "Weekly balance" — a settings-row
/// value, so it counts the areas that are off rather than naming them.
String balanceSummary(List<BalanceCategory> categories) {
  final off = [
    for (final entry in categories)
      if (!entry.verdict.onTarget) entry.verdict,
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
                  _BannerCard(balanceBannerFor(categories, program)),
                  for (final entry in categories)
                    _CategoryRow(
                      entry: entry,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              _CategoryDetailView(entry: entry, week: week),
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

/// Why one category reads the way it does: the week day by day, and what the
/// current exposure means.
class _CategoryDetailView extends StatelessWidget {
  final BalanceCategory entry;
  final List<ProgramWeekDay> week;

  const _CategoryDetailView({required this.entry, required this.week});

  @override
  Widget build(BuildContext context) {
    final verdict = entry.verdict;
    final days = entry.times;
    final blocks = entry.weeklyBlocks;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(title: entry.label),
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
                    padding: const EdgeInsets.only(top: 24),
                    child: Text.rich(
                      TextSpan(
                        // Volume and frequency kept apart: the exercises are
                        // the blocks, the days are what the verdict reads.
                        text: '$blocks ${blocks == 1 ? 'block' : 'blocks'} '
                            'across $days ${days == 1 ? 'day' : 'days'} · ',
                        children: [
                          TextSpan(
                            text: verdict.label,
                            style: TextStyle(color: verdict.color),
                          ),
                        ],
                      ),
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
                      balanceStatusCopy(entry),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.6,
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

/// Back chevron over a display title, shared by both balance pages.
class _PageHeader extends StatelessWidget {
  final String title;

  const _PageHeader({required this.title});

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
        ],
      ),
    );
  }
}

/// The whole-week read, above the movement rows: what is off, and the fix
/// that actually addresses it.
class _BannerCard extends StatelessWidget {
  final BalanceBanner banner;

  const _BannerCard(this.banner);

  Color get _accent {
    switch (banner.cause) {
      case BalanceCause.balanced:
        return AppColors.green;
      case BalanceCause.veryHigh:
        return AppColors.amber;
      case BalanceCause.schedule:
      case BalanceCause.workoutEdits:
      case BalanceCause.mixed:
        return AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 10),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.headline,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  banner.detail,
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
