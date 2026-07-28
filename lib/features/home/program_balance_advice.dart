import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/training_program_service.dart';
import 'program_balance_view.dart';
import 'program_day_items.dart';

/// One thing the user could do about a movement that is off target: the
/// action, and the sentence explaining it.
class BalanceAdvice {
  final String title;
  final String detail;

  const BalanceAdvice({required this.title, required this.detail});
}

/// The whole read of one movement: the heading, the sentence under it, the
/// label over the list, and the actions themselves.
class BalanceReport {
  final String headline;
  final String explanation;
  final String actionsLabel;
  final List<BalanceAdvice> advice;

  const BalanceReport({
    required this.headline,
    required this.explanation,
    required this.actionsLabel,
    required this.advice,
  });
}

/// Standalone exercises worth adding for each movement pattern, split by what
/// the user can train on. These are deliberately not catalog progressions:
/// a skill tree advances on its own, so a movement that is merely short of
/// volume wants a supporting exercise rather than a second progression.
const Map<ExerciseCategory, BalanceSuggestions> kBalanceSuggestions = {
  ExerciseCategory.horizontalPush: BalanceSuggestions(
    gym: ['Barbell bench press', 'Dumbbell bench press', 'Chest press machine'],
    minimal: ['Ring push-up', 'Feet-elevated push-up', 'Wide push-up'],
  ),
  ExerciseCategory.verticalPush: BalanceSuggestions(
    gym: [
      'Barbell overhead press',
      'Dumbbell shoulder press',
      'Shoulder press machine',
    ],
    minimal: ['Pike push-up', 'Parallel-bar dip', 'Wall handstand push-up'],
  ),
  ExerciseCategory.horizontalPull: BalanceSuggestions(
    gym: [
      'Seated cable row',
      'Chest-supported dumbbell row',
      'Barbell bent-over row',
    ],
    minimal: ['Ring row', 'Inverted row', 'Feet-elevated ring row'],
  ),
  ExerciseCategory.verticalPull: BalanceSuggestions(
    gym: [
      'Lat pulldown',
      'Assisted pull-up machine',
      'Single-arm cable pulldown',
    ],
    minimal: ['Chin-up', 'Neutral-grip pull-up', 'Scapular pull-up'],
  ),
  ExerciseCategory.squat: BalanceSuggestions(
    gym: ['Back squat', 'Leg press', 'Bulgarian split squat'],
    minimal: ['Reverse lunge', 'Bulgarian split squat', 'Step-up'],
  ),
  ExerciseCategory.hinge: BalanceSuggestions(
    gym: ['Romanian deadlift', 'Hip thrust', 'Leg curl'],
    minimal: [
      'Single-leg glute bridge',
      'Sliding hamstring curl',
      'Nordic curl'
    ],
  ),
  ExerciseCategory.core: BalanceSuggestions(
    gym: ['Cable crunch', 'Pallof press', 'Cable wood chop'],
    minimal: ['Dead bug', 'Side plank', 'Reverse crunch'],
  ),
};

class BalanceSuggestions {
  final List<String> gym;
  final List<String> minimal;

  const BalanceSuggestions({required this.gym, required this.minimal});
}

/// Reads one movement into the copy the detail page shows.
///
/// The rule behind every branch: change the split only when the split is what
/// causes the problem. Otherwise the fix is a specific exercise or
/// progression, because that is the smallest change that works.
BalanceReport balanceReportFor({
  required BalanceCategory entry,
  required List<ProgramWeekDay> week,
  required List<BalanceCategory> allCategories,
  required BalanceProgramContext context,
}) {
  final movement = entry.label;
  final blocks = entry.weeklyBlocks;

  if (entry.verdict == BalanceVerdict.overloaded) {
    return BalanceReport(
      headline: 'Too much work',
      explanation: '$movement appears $blocks times this week. Forma '
          'recommends ${entry.target} weekly sessions. Extra work may make '
          'recovery harder.',
      actionsLabel: 'WAYS TO REDUCE IT',
      advice: _tooMuch(
        entry: entry,
        week: week,
        allCategories: allCategories,
        context: context,
      ),
    );
  }

  return BalanceReport(
    headline: 'Needs more work',
    explanation: '$movement appears $blocks ${blocks == 1 ? 'time' : 'times'} '
        'this week. Aim for ${entry.target} weekly sessions.',
    actionsLabel: 'WAYS TO IMPROVE IT',
    advice: _tooLittle(entry: entry, week: week, context: context),
  );
}

// ---------------------------------------------------------------------------
// Too little
// ---------------------------------------------------------------------------

List<BalanceAdvice> _tooLittle({
  required BalanceCategory entry,
  required List<ProgramWeekDay> week,
  required BalanceProgramContext context,
}) {
  final movement = entry.label.toLowerCase();

  // Case A — nothing trains the movement at all. Adding days cannot fix a
  // week with no relevant exercise in it, so neither the schedule nor the
  // split is mentioned here.
  if (entry.weeklyBlocks == 0) {
    return [
      ..._treeAdvice(entry, context),
      _standaloneAdvice(entry, week, context),
    ];
  }

  final chances = entry.opportunities ?? kBalanceTarget.toDouble();

  // Case B — the movement is there, but the split barely comes back to it.
  // This is the one case where the schedule really is the problem.
  if (chances < kBalanceMinDays) {
    if (context.programType == TrainingProgramType.fullBody) {
      return const [
        BalanceAdvice(
          title: 'Add another training day',
          detail: 'Train your full-body program more frequently.',
        ),
      ];
    }
    return [
      const BalanceAdvice(
        title: 'Add another training day',
        detail: 'Increase the frequency of your current split.',
      ),
      BalanceAdvice(
        title: 'Change your split',
        detail: 'Choose a split that trains $movement at least twice per week.',
      ),
    ];
  }

  // Case C — the week offers the movement often enough; some of those days
  // are simply empty. Schedule what is already there before adding anything.
  final open = _openDayFor(entry, week);
  final existing = _mostFrequentExercise(entry);
  return [
    if (open != null && existing != null)
      BalanceAdvice(
        title: 'Add $existing to another workout',
        detail: 'Train $movement on ${kWeekdayNames[open]} to reach '
            '${entry.target} weekly sessions.',
      ),
    BalanceAdvice(
      title: 'Add another $movement exercise',
      detail: 'Add a supporting exercise to one of your applicable workouts.',
    ),
  ];
}

/// Case A's first move: a tree the user has unlocked but is not training.
/// Never a progression that is already active, never one still locked.
List<BalanceAdvice> _treeAdvice(
  BalanceCategory entry,
  BalanceProgramContext context,
) {
  final running = {
    for (final track in context.skillTracks)
      if (track.included) track.skillCategoryId,
  };

  for (final category in SkillCategoryCatalog.browsable()) {
    if (!entry.group.categories.contains(category.track)) continue;
    if (running.contains(category.id)) continue;
    if (category.isLockedFor(context.progressMap)) continue;

    final goal = _goalOf(category);
    return [
      BalanceAdvice(
        title: 'Add a ${category.title} progression',
        detail: 'Start training towards $goal and add its current exercise to '
            'suitable workouts.',
      ),
    ];
  }

  return const [];
}

/// Case A's second move, and Case C's fallback: a supporting exercise the
/// program does not already run, matched to the user's equipment.
BalanceAdvice _standaloneAdvice(
  BalanceCategory entry,
  List<ProgramWeekDay> week,
  BalanceProgramContext context,
) {
  final movement = entry.label.toLowerCase();
  final picks = _suggestionsFor(entry.group, week, context);

  return BalanceAdvice(
    title: 'Add a $movement exercise',
    detail: picks.isEmpty
        ? 'Add a supporting exercise to one of your applicable workouts.'
        : 'Add a supporting exercise such as ${_orList(picks)}.',
  );
}

/// Up to three suggestions for the group, drawn a pattern at a time so the
/// Legs group offers both a knee-dominant and a hip-dominant option, with
/// anything already in the week filtered out.
List<String> _suggestionsFor(
  BalanceGroup group,
  List<ProgramWeekDay> week,
  BalanceProgramContext context,
) {
  final scheduled = {
    for (final day in week)
      for (final item in day.items) _normalize(item.name),
  };
  final byCategory = [
    for (final category in group.categories)
      if (kBalanceSuggestions[category] case final suggestions?)
        (context.hasGym ? suggestions.gym : suggestions.minimal),
  ];

  final picks = <String>[];
  final seen = <String>{};
  for (var rank = 0; picks.length < 3 && rank < 3; rank++) {
    for (final list in byCategory) {
      if (rank >= list.length || picks.length >= 3) continue;
      final name = list[rank];
      if (scheduled.contains(_normalize(name))) continue;
      if (!seen.add(_normalize(name))) continue;
      picks.add(name);
    }
  }
  return picks;
}

// ---------------------------------------------------------------------------
// Too much
// ---------------------------------------------------------------------------

List<BalanceAdvice> _tooMuch({
  required BalanceCategory entry,
  required List<ProgramWeekDay> week,
  required List<BalanceCategory> allCategories,
  required BalanceProgramContext context,
}) {
  final movement = entry.label.toLowerCase();
  final advice = <BalanceAdvice>[];

  // Case A — spread over too many days. Thin the movement out of a session
  // rather than dropping a whole training day.
  if (entry.times > entry.target) {
    final busiest = _mostFrequentExercise(entry);
    advice.add(
      BalanceAdvice(
        title: 'Reduce $movement frequency',
        detail: 'Remove ${busiest ?? 'an exercise'} from one or more workouts '
            'while keeping it active in your program.',
      ),
    );

    // Only when the schedule is what overtrains the user — several movements
    // over at once — is the schedule itself worth touching.
    final overloaded = allCategories
        .where((other) => other.verdict == BalanceVerdict.overloaded)
        .length;
    if (overloaded > 1) {
      advice.addAll(const [
        BalanceAdvice(
          title: 'Reduce your training days',
          detail: 'Keep your current split but train fewer days per week.',
        ),
        BalanceAdvice(
          title: 'Change your split',
          detail: 'Choose a split that gives your movements more recovery '
              'between sessions.',
        ),
      ]);
    }
  }

  // Case B — several blocks land in the same session. Supporting exercises
  // go before progressions, since a progression is the thing being trained.
  final doubled = _doubledUpItems(entry);
  final spare = doubled
      .where((item) => item.kind != ProgramDayItemKind.progression)
      .firstOrNull;
  if (spare != null) {
    advice.addAll([
      BalanceAdvice(
        title: 'Remove ${spare.name}',
        detail: 'Remove a supporting exercise that overlaps with your active '
            'progression.',
      ),
      BalanceAdvice(
        title: 'Replace ${spare.name}',
        detail: 'Replace it with a movement your program currently needs '
            'more of.',
      ),
    ]);
  }

  // Case C — two progressions feeding one movement, still over once the
  // supporting exercises are set aside. Pause, never remove: the tree keeps
  // everything it has earned.
  final pausable = _lowerPriorityTree(entry, context);
  if (pausable != null) {
    final progressionBlocks = entry.blocks
        .where((block) => block.item.kind == ProgramDayItemKind.progression)
        .length;
    if (progressionBlocks > entry.target) {
      advice.add(
        BalanceAdvice(
          title: 'Pause ${pausable.title}',
          detail: 'Pause the lower-priority progression while keeping its '
              'progress saved.',
        ),
      );
    }
  }

  if (advice.isEmpty) {
    final busiest = _mostFrequentExercise(entry);
    advice.add(
      BalanceAdvice(
        title: 'Reduce $movement frequency',
        detail: 'Remove ${busiest ?? 'an exercise'} from one or more workouts '
            'while keeping it active in your program.',
      ),
    );
  }
  return advice;
}

/// Items of this movement that share a day with another block of it.
List<ProgramDayItem> _doubledUpItems(BalanceCategory entry) {
  final byDay = <int, List<ProgramDayItem>>{};
  for (final block in entry.blocks) {
    (byDay[block.weekday] ??= []).add(block.item);
  }
  return [
    for (final items in byDay.values)
      if (items.length > 1) ...items,
  ];
}

/// Of the trees feeding this movement, the one to pause: never a tree behind
/// a goal the user chose, and of the rest the one added last.
SkillCategory? _lowerPriorityTree(
  BalanceCategory entry,
  BalanceProgramContext context,
) {
  final ids = <String>{
    for (final block in entry.blocks)
      if (block.item.kind == ProgramDayItemKind.progression &&
          block.item.skillCategoryId != null)
        block.item.skillCategoryId!,
  };
  if (ids.length < 2) return null;

  final candidates = [
    for (final track in context.skillTracks)
      if (ids.contains(track.skillCategoryId) &&
          !context.goalSkillCategoryIds.contains(track.skillCategoryId))
        track,
  ]..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));

  final pick = candidates.lastOrNull;
  if (pick == null) return null;
  return SkillCategoryCatalog.findById(pick.skillCategoryId);
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// A training day the split lets this movement run on, but which currently
/// holds none of it.
int? _openDayFor(BalanceCategory entry, List<ProgramWeekDay> week) {
  for (final day in week) {
    final applicable =
        TrainingProgramService.patternsForSession(day.sessionType)
            .any(entry.group.categories.contains);
    if (!applicable) continue;
    if (day.items.any(entry.covers)) continue;
    return day.weekday;
  }
  return null;
}

/// The exercise carrying the movement — the one that runs on the most days,
/// and so the one worth scheduling again or thinning out.
String? _mostFrequentExercise(BalanceCategory entry) {
  final days = entry.exerciseDays;
  if (days.isEmpty) return null;

  var best = days.entries.first;
  for (final candidate in days.entries) {
    if (candidate.value.length > best.value.length) best = candidate;
  }
  return best.key;
}

/// What a tree is training towards: the last step of its default branch.
String _goalOf(SkillCategory category) {
  final path = category.pathFor(category.defaultTrainingPathId);
  if (path.isEmpty) return category.title;
  return ExerciseCatalog.findById(path.last)?.name ?? category.title;
}

String _orList(List<String> names) {
  if (names.length < 2) return names.join();
  return '${names.take(names.length - 1).join(', ')}, or ${names.last}';
}

String _normalize(String name) =>
    name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
