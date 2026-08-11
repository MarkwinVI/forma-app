import '../catalog/skill_category_catalog.dart';
import '../models/exercise_model.dart';
import '../models/skill_category_model.dart';
import 'progress_service.dart';
import 'skill_track_service.dart';
import 'training_program_service.dart';

/// Where one exercise starts: the prescribed sets × value, and the working
/// weight for the loaded lifts (null for everything trained at bodyweight).
class ProgramStartTarget {
  final int sets;
  final int value;
  final double? weightKg;

  const ProgramStartTarget({
    required this.sets,
    required this.value,
    this.weightKg,
  });
}

/// The opening position of a freshly built program: which skill tracks it
/// runs, where each one starts, and what the starting exercises prescribe.
class ProgramStartPlan {
  /// skill category id → active branch id.
  final Map<String, String> tracks;

  /// exercise id → status. Only starting nodes ([ExerciseStatus.active]) and
  /// the steps setup jumped over ([ExerciseStatus.skipped]) appear.
  final Map<String, ExerciseStatus> statuses;

  /// exercise id → opening target, for exercises that do not start on the
  /// standard ladder target.
  final Map<String, ProgramStartTarget> targets;

  const ProgramStartPlan({
    required this.tracks,
    required this.statuses,
    required this.targets,
  });
}

/// Turns program-setup answers into a starting position.
///
/// Two rules, both pure:
///
/// 1. **What the program trains.** Every split is built from seven movements
///    — push-ups, dips, rows, pull-ups, one knee-dominant, one hinge, and
///    core — and the split itself decides which of them a given day runs.
///    The two leg slots depend on equipment: with a gym the knee-dominant
///    slot is a barbell squat and the hinge slot a Romanian deadlift; without
///    one they are the squat progression and the Nordic curl. A goal skill
///    replaces the default tree for its movement (a pistol-squat goal takes
///    the knee-dominant slot back from the barbell) and adds a track of its
///    own for movements the seven do not cover.
///
/// 2. **Where it starts.** The reported one-set maximum places the starting
///    node on the push-up, pull-up, dip and bodyweight-squat trees, read
///    against the exercise the answer was about — the plain push-up,
///    pull-up, parallel-bar dip or bodyweight squat, not the last step of
///    the shared foundation. Nothing starts at the beginner node, ten or
///    more reps start on that named step, and 1–9 reps start two steps
///    before it. Everything behind the starting node is marked skipped, not
///    mastered — it was never trained here. Rows always start at the first
///    step, and the loaded lifts start from the reported 1RM (70% for
///    3 × 5) or a deliberately light 20 kg.
class ProgramStartPlanner {
  ProgramStartPlanner._();

  /// Reps at or above this count start on the answer's own exercise.
  static const int repThreshold = 10;

  /// Steps back from the answer's own exercise for a 1–9 rep answer.
  static const int partialRepStepBack = 2;

  /// Loaded lifts open at 3 × 5 working sets and climb from there.
  static const int loadedLiftSets = 3;
  static const int loadedLiftStartReps = 5;

  /// Deliberately light opening load for the Romanian deadlift: the hinge is
  /// there to balance the knee-dominant work, not to be tested on day one.
  static const double romanianDeadliftStartKg = 20;

  /// Nordic curls open at 3 × 5, assisted as much as it takes.
  static const int nordicCurlSets = 3;
  static const int nordicCurlReps = 5;

  /// Barbell weights are rounded to something loadable.
  static const double barbellIncrementKg = 2.5;

  /// Per tree: the setup answer that places the starting node, and the step
  /// that answer is about. "Ten push-ups" means ten of the exercise called
  /// Push-up, so that step — not whatever step happens to end the shared
  /// foundation — is what the count is measured against.
  static const Map<String, _RepGate> _repGates = {
    SkillCategoryCatalog.pushupsId: _RepGate('pushups', 'pushups_push_up'),
    SkillCategoryCatalog.pullupsId: _RepGate('pullups', 'pullups_pull_up'),
    SkillCategoryCatalog.dipsId: _RepGate('dips', 'dips_parallel_bar_dips'),
    SkillCategoryCatalog.squatId: _RepGate('squat_bw', 'squat_squat'),
  };

  static ProgramStartPlan planFor({
    required bool hasGym,
    required List<String> goalSkillIds,
    required Map<String, int?> startingStrength,
    Map<String, ExerciseStatus> existingProgress = const {},
  }) {
    // A gated goal (handstand push-ups, planche, muscle-up) only becomes a
    // track once the tree behind it is open. The wizard already refuses the
    // pick; this is the rule itself, so no caller can plan a locked tree.
    final unlockedGoalIds = [
      for (final goalId in goalSkillIds)
        if (TrainingProgramService.lockedGoal(goalId, existingProgress) ==
            null)
          goalId,
    ];
    final goalBranches = _goalBranchesByCategory(unlockedGoalIds);
    final tracks = <String, String>{};

    void addTrack(String categoryId, String branchId) {
      tracks.putIfAbsent(categoryId, () => goalBranches[categoryId] ?? branchId);
    }

    // The four upper-body progressions every split trains.
    for (final category in [
      SkillCategoryCatalog.pushups,
      SkillCategoryCatalog.dips,
      SkillCategoryCatalog.rows,
      SkillCategoryCatalog.pullups,
    ]) {
      addTrack(category.id, category.defaultTrainingPathId);
    }

    // Knee-dominant: the barbell owns the slot only when a gym is available
    // and no goal points at the squat tree.
    final squatGoalBranch = goalBranches[SkillCategoryCatalog.squatId];
    if (hasGym && squatGoalBranch == null) {
      addTrack(SkillCategoryCatalog.barbellSquatId, 'main');
    } else {
      addTrack(
        SkillCategoryCatalog.squatId,
        SkillCategoryCatalog.squat.defaultTrainingPathId,
      );
    }

    // Hinge: loaded when there is a bar to load, bodyweight otherwise.
    addTrack(SkillCategoryCatalog.hingeId, hasGym ? 'rdl' : 'nordic');

    // Direct core work belongs in every program. The split schedules it at
    // the end of full-body, push, and lower sessions.
    addTrack(
      SkillCategoryCatalog.coreId,
      SkillCategoryCatalog.core.defaultTrainingPathId,
    );

    // Goals for movements the seven defaults do not cover get their own track.
    for (final entry in goalBranches.entries) {
      addTrack(entry.key, entry.value);
    }

    final statuses = <String, ExerciseStatus>{};
    final targets = <String, ProgramStartTarget>{};

    for (final entry in tracks.entries) {
      final category = SkillCategoryCatalog.findById(entry.key);
      if (category == null) continue;

      final start = _startingPositionFor(
        category: category,
        branchId: entry.value,
        hasGym: hasGym,
        startingStrength: startingStrength,
      );
      statuses.addAll(start.statuses);
      targets.addAll(start.targets);
    }

    return ProgramStartPlan(
      tracks: tracks,
      statuses: statuses,
      targets: targets,
    );
  }

  /// Branch each goal skill points at, keyed by skill category. Two goals on
  /// one category keep the first, matching how tracks are seeded elsewhere.
  static Map<String, String> _goalBranchesByCategory(List<String> goalSkillIds) {
    final branches = <String, String>{};

    for (final goalId in goalSkillIds) {
      final branchId = TrainingProgramService.goalBranchIds[goalId];
      if (branchId == null) continue;
      final parts = branchId.split(':');
      if (parts.length != 2) continue;
      final category = SkillCategoryCatalog.findById(parts[0]);
      if (category == null || !category.trainingPaths.containsKey(parts[1])) {
        continue;
      }
      branches.putIfAbsent(parts[0], () => parts[1]);
    }

    return branches;
  }

  static _StartingPosition _startingPositionFor({
    required SkillCategory category,
    required String branchId,
    required bool hasGym,
    required Map<String, int?> startingStrength,
  }) {
    switch (category.id) {
      case SkillCategoryCatalog.barbellSquatId:
        return _StartingPosition(
          statuses: const {'barbell_squat_barbell_squat': ExerciseStatus.active},
          targets: {
            'barbell_squat_barbell_squat': ProgramStartTarget(
              sets: loadedLiftSets,
              value: loadedLiftStartReps,
              weightKg: barbellSquatStartKg(startingStrength['squat']),
            ),
          },
        );
      case SkillCategoryCatalog.hingeId:
        return _hingeStartingPosition(branchId);
    }

    final path = category.pathFor(branchId);
    if (path.isEmpty) return const _StartingPosition.empty();

    // Rows have no rep gate: everyone starts at the first step, because the
    // opening steps are about body angle rather than strength.
    final gate = _repGates[category.id];
    final startIndex = gate == null
        ? 0
        : startIndexFor(
            path: path,
            referenceExerciseId: gate.referenceExerciseId,
            reps: startingStrength[gate.answerKey],
          );

    return _StartingPosition(
      statuses: {
        for (var index = 0; index < startIndex; index++)
          path[index]: ExerciseStatus.skipped,
        path[startIndex]: ExerciseStatus.active,
      },
      targets: const {},
    );
  }

  static _StartingPosition _hingeStartingPosition(String branchId) {
    switch (branchId) {
      case 'rdl':
        return const _StartingPosition(
          statuses: {'hinge_romanian_deadlift': ExerciseStatus.active},
          targets: {
            // Same 3 × 5 the barbell squat opens on, so both loaded lifts
            // run the same climb; the load is what is set low here.
            'hinge_romanian_deadlift': ProgramStartTarget(
              sets: loadedLiftSets,
              value: loadedLiftStartReps,
              weightKg: romanianDeadliftStartKg,
            ),
          },
        );
      case 'nordic':
        return const _StartingPosition(
          statuses: {'hinge_nordic_nordic_curl': ExerciseStatus.active},
          targets: {
            'hinge_nordic_nordic_curl': ProgramStartTarget(
              sets: nordicCurlSets,
              value: nordicCurlReps,
            ),
          },
        );
      default:
        return const _StartingPosition(
          statuses: {'single_leg_rdl': ExerciseStatus.active},
          targets: {},
        );
    }
  }

  /// Index of the starting node along [path] for a reported one-set maximum
  /// of [referenceExerciseId]. Ten or more reps start on that exercise, 1–9
  /// two steps before it, and an unknown answer starts at the beginner node
  /// — the first session finds out where the user actually is.
  ///
  /// The step-back clamps at the start of the path, so on a short run-up
  /// (push-ups and squats have two steps before their named exercise) 1–9
  /// reps land on the beginner node, same as no reps at all.
  static int startIndexFor({
    required List<String> path,
    required String referenceExerciseId,
    required int? reps,
  }) {
    if (reps == null || reps <= 0) return 0;

    final referenceIndex = path.indexOf(referenceExerciseId);
    if (referenceIndex < 0) return 0;
    if (reps >= repThreshold) return referenceIndex;
    return (referenceIndex - partialRepStepBack).clamp(0, referenceIndex);
  }

  /// Opening barbell squat weight: the setup answer is the bar weight the
  /// user can squat for five reps, which IS a working weight for the 3 × 5
  /// opening sets — it just gets rounded down to a loadable 2.5 kg. Null
  /// when the user left the answer blank.
  static double? barbellSquatStartKg(int? fiveRepWeightKg) {
    if (fiveRepWeightKg == null || fiveRepWeightKg <= 0) return null;

    final rounded =
        (fiveRepWeightKg / barbellIncrementKg).floor() * barbellIncrementKg;
    return rounded < barbellIncrementKg ? barbellIncrementKg : rounded;
  }
}

/// A tree's rep gate: the setup answer, and the step it is an answer about.
class _RepGate {
  final String answerKey;
  final String referenceExerciseId;

  const _RepGate(this.answerKey, this.referenceExerciseId);
}

class _StartingPosition {
  final Map<String, ExerciseStatus> statuses;
  final Map<String, ProgramStartTarget> targets;

  const _StartingPosition({required this.statuses, required this.targets});

  const _StartingPosition.empty()
      : statuses = const {},
        targets = const {};
}

/// Persists the starting position a freshly built program implies.
class ProgramStartService {
  final SkillTrackService _skillTrackService;
  final ProgressService _progressService;

  ProgramStartService({
    SkillTrackService? skillTrackService,
    ProgressService? progressService,
  })  : _skillTrackService = skillTrackService ?? SkillTrackService(),
        _progressService = progressService ?? ProgressService();

  /// Writes [plan]: the tracks the program runs, and the starting position of
  /// every exercise the user has no progress for yet. Exercises with an
  /// existing progress row are left alone, so rebuilding a program never
  /// overwrites work that was actually done.
  Future<void> applyPlan({
    required String userId,
    required ProgramStartPlan plan,
  }) async {
    for (final entry in plan.tracks.entries) {
      await _skillTrackService.upsertTrack(
        userId,
        skillCategoryId: entry.key,
        branchId: entry.value,
      );
    }

    // Exercises the user already has a row for are left alone: setup places
    // a starting position, it does not stomp progress that exists.
    final existing = {
      for (final progress in await _progressService.fetchAll(userId))
        progress.exerciseId,
    };

    await _progressService.upsertStartingPositions(
      userId,
      startingPositionsFor(plan, existing: existing),
    );
  }

  /// The rows [applyPlan] writes: each new exercise's status joined with its
  /// target, everything the user already has a row for left out.
  ///
  /// Status and target go together in a single write on purpose. Written as
  /// two passes, a failure between them stranded half a starting position —
  /// and the retry, seeing rows exist, skipped the rest of it for good.
  static Map<String, StartingPosition> startingPositionsFor(
    ProgramStartPlan plan, {
    required Set<String> existing,
  }) {
    final positions = <String, StartingPosition>{};
    for (final entry in plan.statuses.entries) {
      if (existing.contains(entry.key)) continue;
      final target = plan.targets[entry.key];
      positions[entry.key] = (
        status: entry.value,
        targetSets: target?.sets,
        targetValue: target?.value,
        targetWeightKg: target?.weightKg,
      );
    }
    for (final entry in plan.targets.entries) {
      if (existing.contains(entry.key) || positions.containsKey(entry.key)) {
        continue;
      }
      // A target with no planned status starts inactive, as a fresh row
      // would have defaulted to anyway.
      positions[entry.key] = (
        status: ExerciseStatus.inactive,
        targetSets: entry.value.sets,
        targetValue: entry.value.value,
        targetWeightKg: entry.value.weightKg,
      );
    }
    return positions;
  }
}
