import 'dart:math' as math;

import '../catalog/exercise_catalog.dart';
import '../catalog/skill_category_catalog.dart';
import '../models/exercise_model.dart';
import '../models/exercise_progress_model.dart';
import '../models/progression_event_model.dart';
import '../models/progression_suggestion_model.dart';
import '../models/training_program_model.dart';
import 'exercise_log_service.dart';
import 'progress_service.dart';
import 'weight_unit_service.dart';
import 'progression_event_service.dart';
import 'progression_suggestion_service.dart';
import 'skill_track_service.dart';
import 'training_program_service.dart';

/// One exercise's outcome in a saved workout session: the exercise as it was
/// logged (program section intact, so targets match what the user saw) and
/// the total volume achieved across all sets (reps, or seconds when timed).
class SessionExerciseResult {
  final Exercise exercise;
  final int volume;
  final List<SessionSetResult> sets;
  final bool wasManuallyAdded;

  /// Progression track the exercise was trained under (TrainingTrack
  /// dbValue); recorded on the events this result produces.
  final String? trackId;

  const SessionExerciseResult({
    required this.exercise,
    required this.volume,
    this.sets = const [],
    this.wasManuallyAdded = false,
    this.trackId,
  });
}

/// One completed set, retained for rules that must be met set-by-set rather
/// than by total volume (manual skill-tree fast-forwarding in particular).
class SessionSetResult {
  final int value;
  final double weightKg;

  const SessionSetResult({required this.value, this.weightKg = 0});
}

/// A resolved sets × value target (reps, or seconds when timed).
class ExerciseTarget {
  final int sets;
  final int value;

  const ExerciseTarget({required this.sets, required this.value});

  /// Total volume the target requires. Reaching a target is evaluated on
  /// total volume: 18 total reps satisfies 3 × 6 regardless of how the reps
  /// were distributed across sets.
  int get volume => sets * value;
}

/// The progression changes one saved session earns: status transitions
/// (mastered / newly activated), incremental target increases, branch
/// selections implied by fork resolution, and forks the user must decide.
class SessionProgressionOutcome {
  final Map<String, ExerciseStatus> statusChanges;
  final Map<String, ExerciseTarget> targetChanges;

  /// mastered exercise id → the exercise its mastery activated.
  final Map<String, String> activationsByMastered;

  /// A manually logged exercise can move the active node without mastering
  /// the old one. This maps the node being left to the newly active node.
  final Map<String, String> shortcutActivationsBySource;

  /// Statuses before an out-of-band change — a manual shortcut, or the
  /// backfill that masters a jumped-over step when its destination masters —
  /// used to write reversible ledger events.
  final Map<String, ExerciseStatus> previousStatuses;

  /// Branches chosen by goal-driven fork resolution (skill category id →
  /// branch id), to be saved so future workouts follow the new branch.
  final Map<String, String> branchesToPersist;

  /// Exercises mastered at a fork that neither the user's selections, goals,
  /// nor defaults decide — the user must pick the branch themselves.
  final List<String> branchChoicesNeeded;

  /// Changes to loaded lifts the program wants to make but will not make on
  /// its own — the user approves these on the Train tab.
  final List<ProgressionSuggestion> suggestions;

  const SessionProgressionOutcome({
    required this.statusChanges,
    required this.targetChanges,
    this.activationsByMastered = const {},
    this.shortcutActivationsBySource = const {},
    this.previousStatuses = const {},
    this.branchesToPersist = const {},
    this.branchChoicesNeeded = const [],
    this.suggestions = const [],
  });

  bool get isEmpty =>
      statusChanges.isEmpty &&
      targetChanges.isEmpty &&
      branchChoicesNeeded.isEmpty &&
      suggestions.isEmpty;
}

/// Advances skill-path progress after a workout is saved.
///
/// Each progression exercise carries an incremental target that climbs from
/// an initial 3 × 6 (3 × 10s timed) toward the live global mastery target:
/// reaching the current target raises it by one increment for the next
/// workout, and reaching the mastery target — checked first, so overshooting
/// masters early — marks the exercise mastered and activates the next move in
/// its skill path. Failing a target changes nothing.
///
/// The mastery target is read from [MasteryTargetSettings] at evaluation
/// time, never snapshotted, so changing the global setting applies to active
/// and future exercises but never removes mastery or resets stored targets.
class ExerciseProgressionService {
  final _progressService = ProgressService();
  final _eventService = ProgressionEventService();
  final _skillTrackService = SkillTrackService();
  final _logService = ExerciseLogService();
  final _suggestionService = ProgressionSuggestionService();

  /// Ladder start: 3 × 6 reps, or 3 × 10s for timed exercises.
  static const int initialTargetSets = 3;
  static const int initialTargetReps = 6;
  static const int initialTargetSeconds = 10;

  /// Where a loaded lift's reps drop back to when its weight goes up.
  static const int loadedLiftBottomReps = 5;

  /// How much weight a loaded lift adds once it tops out its rep range.
  static const double loadedLiftIncrementKg = 10;

  /// Per-set increase when the current target is reached.
  static const int targetIncrementReps = 1;
  static const int targetIncrementSeconds = 5;

  /// Timed detection reads the explicit catalog flag. The old name heuristic
  /// ("hold"/"hang"/"lever"…) both missed isometrics like L-sits and wrongly
  /// timed rep movements like handstand push-ups and hanging leg raises.
  static bool isTimedExercise(Exercise exercise) => exercise.isTimed;

  /// Initial per-set ladder value for an exercise that was never advanced.
  static int initialTargetValueForExercise(Exercise exercise) {
    return isTimedExercise(exercise) ? initialTargetSeconds : initialTargetReps;
  }

  /// Per-set increase applied when the current target is reached.
  static int targetIncrementForExercise(Exercise exercise) {
    return isTimedExercise(exercise)
        ? targetIncrementSeconds
        : targetIncrementReps;
  }

  /// Per-set value the exercise must reach (as total volume) to be mastered,
  /// from the live global settings.
  static int masteryValueForExercise(
    Exercise exercise,
    MasteryTargetSettings settings,
  ) {
    return isTimedExercise(exercise)
        ? settings.secondsPerSet
        : settings.repsPerSet;
  }

  /// The user's current incremental target for a progression exercise:
  /// stored state when present, the initial ladder target otherwise. The
  /// value is clamped to the live mastery target so users are never shown a
  /// goal harder than mastery requires; the stored value stays untouched, so
  /// raising the setting back restores it.
  static ExerciseTarget currentTargetForExercise(
    Exercise exercise, {
    ExerciseProgress? progress,
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
  }) {
    final storedValue =
        progress?.currentTargetValue ?? initialTargetValueForExercise(exercise);

    return ExerciseTarget(
      sets: progress?.currentTargetSets ?? initialTargetSets,
      value: math.min(
        storedValue,
        masteryValueForExercise(exercise, masterySettings),
      ),
    );
  }

  /// The target that masters the exercise, at the user's current set count.
  static ExerciseTarget masteryTargetForExercise(
    Exercise exercise, {
    ExerciseProgress? progress,
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
  }) {
    return ExerciseTarget(
      sets: progress?.currentTargetSets ?? initialTargetSets,
      value: masteryValueForExercise(exercise, masterySettings),
    );
  }

  /// The working weight to show next to a target, or null for the bodyweight
  /// exercises that make up almost everything. Only the loaded lifts (barbell
  /// squat, Romanian deadlift) carry one, set when the program is built.
  static String? weightLabelFor(ExerciseProgress? progress) {
    final weightKg = progress?.currentTargetWeightKg;
    if (weightKg == null || weightKg <= 0) return null;
    return '${WeightUnitService.displayText(weightKg)} '
        '${WeightUnitService.unit.suffix}';
  }

  /// Per-set target for standalone (non-progression) exercises, derived from
  /// the catalog. Progression exercises use [currentTargetForExercise].
  static int targetValueForExercise(Exercise exercise) {
    if (isTimedExercise(exercise)) {
      if (exercise.difficulty <= 1) return 30;
      if (exercise.difficulty <= 3) return 20;
      return 12;
    }

    if (exercise.difficulty <= 1) return 12;
    if (exercise.difficulty <= 3) return 8;
    return 5;
  }

  /// Prescribed set count for standalone (non-progression) exercises.
  static int setCountForExercise(Exercise exercise) {
    return switch (exercise.programSection) {
      ExerciseProgramSection.warmup => 2,
      ExerciseProgramSection.skillWork => 3,
      ExerciseProgramSection.mainExercises => exercise.difficulty >= 4 ? 4 : 3,
      ExerciseProgramSection.coolDown => 2,
    };
  }

  /// Pure progression rule, separated from persistence so it is testable.
  ///
  /// For each result (mastered exercises are left out, so a session can never
  /// be applied to them again):
  /// 1. Mastery first: volume ≥ sets × mastery value masters the exercise —
  ///    overshooting the current target masters early — and activates the
  ///    next move in its skill path (fork resolution below). Mastery also
  ///    masters every step still uncleared earlier on the exercise's path:
  ///    a manual jump leaves the steps it cleared past locked, and mastering
  ///    the jumped-to exercise is what proves them.
  /// 2. Otherwise, volume ≥ the current target's volume raises the target by
  ///    one increment, capped at the mastery value.
  /// 3. Otherwise nothing changes: the target holds and no progress is lost.
  ///
  /// At a fork — the mastered exercise has different successors on different
  /// branches — the next move is decided in order by:
  /// 1. the track's active branch ([activeBranchByCategory]),
  /// 2. the branch a goal skill points at ([goalSkillIds]) — which is then
  ///    returned in [SessionProgressionOutcome.branchesToPersist]; goals
  ///    pointing at different branches never auto-pick,
  /// 3. the category's default branch,
  /// 4. otherwise the fork is reported in `branchChoicesNeeded` for the user
  ///    to decide.
  static SessionProgressionOutcome computeSessionOutcome({
    required List<SessionExerciseResult> results,
    required Map<String, ExerciseProgress> progressRows,
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
    Map<String, String> activeBranchByCategory = const {},
    List<String> goalSkillIds = const [],
    double? bodyweightKg,
  }) {
    final statusChanges = <String, ExerciseStatus>{};
    final targetChanges = <String, ExerciseTarget>{};
    final activationsByMastered = <String, String>{};
    final shortcutActivationsBySource = <String, String>{};
    final previousStatuses = <String, ExerciseStatus>{};
    final branchesToPersist = <String, String>{};
    final branchChoicesNeeded = <String>[];
    final suggestions = <ProgressionSuggestion>[];

    ExerciseStatus statusOf(String id) =>
        statusChanges[id] ??
        progressRows[id]?.status ??
        ExerciseStatus.inactive;

    for (final result in results) {
      final exercise = result.exercise;
      if (statusOf(exercise.id) == ExerciseStatus.mastered) continue;

      if (result.wasManuallyAdded &&
          _applyManualShortcut(
            result: result,
            progressRows: progressRows,
            statusChanges: statusChanges,
            shortcutActivationsBySource: shortcutActivationsBySource,
            previousStatuses: previousStatuses,
            branchesToPersist: branchesToPersist,
            activeBranchByCategory: activeBranchByCategory,
            masterySettings: masterySettings,
            bodyweightKg: bodyweightKg,
          )) {
        continue;
      }

      // A manually added inactive node only changes progression when it
      // qualifies for the explicit shortcut above. Manually adding the
      // already-active node still uses the ordinary ladder rules below.
      if (result.wasManuallyAdded &&
          statusOf(exercise.id) == ExerciseStatus.inactive) {
        continue;
      }

      final current = currentTargetForExercise(
        exercise,
        progress: progressRows[exercise.id],
        masterySettings: masterySettings,
      );
      final masteryValue = masteryValueForExercise(exercise, masterySettings);
      final masteryVolume = current.sets * masteryValue;

      // A loaded lift never advances on its own and is never mastered: it
      // asks.
      if (exercise.isLoaded) {
        final suggestion = suggestionForLoadedLift(
          exercise: exercise,
          progress: progressRows[exercise.id],
          volume: result.volume,
          masterySettings: masterySettings,
        );
        if (suggestion != null) suggestions.add(suggestion);
        continue;
      }

      if (result.volume >= masteryVolume) {
        statusChanges[exercise.id] = ExerciseStatus.mastered;

        // Mastering proves the whole route here: steps a manual jump left
        // locked earlier on this path master along with it. On an ordinary
        // mastery everything earlier is already cleared, so nothing changes.
        for (final id in _unclearedPredecessors(
          exercise,
          statusOf: statusOf,
          activeBranchByCategory: activeBranchByCategory,
        )) {
          previousStatuses.putIfAbsent(id, () => statusOf(id));
          statusChanges[id] = ExerciseStatus.mastered;
        }

        final resolution = _resolveSuccessor(
          exercise,
          activeBranchByCategory: activeBranchByCategory,
          goalSkillIds: goalSkillIds,
        );
        if (resolution.choiceNeeded) {
          branchChoicesNeeded.add(exercise.id);
        } else if (resolution.nextExerciseId != null &&
            statusOf(resolution.nextExerciseId!) == ExerciseStatus.inactive) {
          statusChanges[resolution.nextExerciseId!] = ExerciseStatus.active;
          activationsByMastered[exercise.id] = resolution.nextExerciseId!;
          if (resolution.persistCategoryId != null &&
              resolution.persistBranchId != null) {
            branchesToPersist[resolution.persistCategoryId!] =
                resolution.persistBranchId!;
          }
        }
      } else if (result.volume >= current.volume) {
        targetChanges[exercise.id] = ExerciseTarget(
          sets: current.sets,
          value: math.min(
            current.value + targetIncrementForExercise(exercise),
            masteryValue,
          ),
        );
      }
    }

    return SessionProgressionOutcome(
      statusChanges: statusChanges,
      targetChanges: targetChanges,
      activationsByMastered: activationsByMastered,
      shortcutActivationsBySource: shortcutActivationsBySource,
      previousStatuses: previousStatuses,
      branchesToPersist: branchesToPersist,
      branchChoicesNeeded: branchChoicesNeeded,
      suggestions: suggestions,
    );
  }

  /// Added load required by a weighted skill rung, straight from the
  /// catalog's formula: `user_bodyweight * factor` (or bare `user_bodyweight`)
  /// is the external load itself, and a `0…` setting ("0", "0kg, just the
  /// bar") means the movement is done unloaded — the empty bar for a barbell
  /// step.
  static double? requiredExternalWeightKg(
    Exercise exercise,
    double? bodyweightKg,
  ) {
    if (!exercise.isWeighted) return 0;
    final formula = exercise.weightFormula?.replaceAll(' ', '');
    if (formula == null) return null;
    if (formula.startsWith('0')) return 0;

    final match = RegExp(
      r'^user_bodyweight(?:\*([0-9]+(?:\.[0-9]+)?))?$',
    ).firstMatch(formula);
    if (match == null) return null;
    final factor = match.group(1);
    if (bodyweightKg == null || bodyweightKg <= 0) return null;
    return bodyweightKg * (factor == null ? 1 : double.parse(factor));
  }

  static bool _meetsManualShortcutMinimum(
    SessionExerciseResult result,
    double? bodyweightKg,
  ) {
    final minimumValue =
        result.exercise.isTimed ? initialTargetSeconds : initialTargetReps;
    final requiredWeight = requiredExternalWeightKg(
      result.exercise,
      bodyweightKg,
    );
    if (result.exercise.isWeighted && requiredWeight == null) return false;

    return result.sets
            .where(
              (set) =>
                  set.value >= minimumValue &&
                  (!result.exercise.isWeighted ||
                      set.weightKg + 0.001 >= requiredWeight!),
            )
            .length >=
        initialTargetSets;
  }

  static bool _applyManualShortcut({
    required SessionExerciseResult result,
    required Map<String, ExerciseProgress> progressRows,
    required Map<String, ExerciseStatus> statusChanges,
    required Map<String, String> shortcutActivationsBySource,
    required Map<String, ExerciseStatus> previousStatuses,
    required Map<String, String> branchesToPersist,
    required Map<String, String> activeBranchByCategory,
    required MasteryTargetSettings masterySettings,
    required double? bodyweightKg,
  }) {
    final destination = result.exercise;
    if (destination.skillCategoryId.isEmpty ||
        !_meetsManualShortcutMinimum(result, bodyweightKg)) {
      return false;
    }
    final category = SkillCategoryCatalog.findById(destination.skillCategoryId);
    if (category == null || category.trainingPaths.isEmpty) return false;

    ExerciseStatus originalStatus(String id) =>
        progressRows[id]?.status ?? ExerciseStatus.inactive;
    ExerciseStatus currentStatus(String id) =>
        statusChanges[id] ?? originalStatus(id);

    final selectedPathId =
        activeBranchByCategory[category.id] ?? category.defaultTrainingPathId;
    final selectedPath = category.pathFor(selectedPathId);
    String? activeId;
    for (final id in selectedPath) {
      if (currentStatus(id) == ExerciseStatus.active) {
        activeId = id;
        break;
      }
    }
    if (activeId == null) {
      for (final path in category.trainingPaths.values) {
        for (final id in path) {
          if (currentStatus(id) == ExerciseStatus.active) {
            activeId = id;
            break;
          }
        }
        if (activeId != null) break;
      }
    }
    if (activeId == null || activeId == destination.id) return false;
    if (currentStatus(destination.id) != ExerciseStatus.inactive) return false;

    String? destinationPathId;
    final declaredPath = category.trainingPaths[destination.branchId];
    if (declaredPath?.contains(destination.id) ?? false) {
      destinationPathId = destination.branchId;
    } else if (selectedPath.contains(destination.id)) {
      destinationPathId = selectedPathId;
    } else {
      for (final entry in category.trainingPaths.entries) {
        if (entry.value.contains(destination.id)) {
          destinationPathId = entry.key;
          break;
        }
      }
    }
    if (destinationPathId == null) return false;
    final destinationPath = category.pathFor(destinationPathId);
    final destinationIndex = destinationPath.indexOf(destination.id);
    final activeOnDestinationIndex = destinationPath.indexOf(activeId);

    var switchedFromFoundation = false;
    if (activeOnDestinationIndex >= 0 &&
        destinationIndex > activeOnDestinationIndex) {
      if (destinationPathId != selectedPathId) {
        final commonLength = _commonPrefixLength(selectedPath, destinationPath);
        switchedFromFoundation = activeOnDestinationIndex < commonLength;
      }
    } else {
      // Different post-foundation branch: the jump is only valid forward of
      // the shared foundation on both sides.
      final commonLength = _commonPrefixLength(selectedPath, destinationPath);
      if (!selectedPath.contains(activeId) ||
          selectedPath.indexOf(activeId) < commonLength ||
          destinationIndex < commonLength) {
        return false;
      }
    }

    void changeStatus(String id, ExerciseStatus status) {
      final before = currentStatus(id);
      if (before == status) return;
      previousStatuses.putIfAbsent(id, () => before);
      statusChanges[id] = status;
    }

    // One tree trains one exercise: the step being left stops being active.
    // The steps jumped over are not touched — they stay locked until the
    // destination is mastered, which masters them too.
    changeStatus(activeId, ExerciseStatus.inactive);

    final mastery = masteryTargetForExercise(
      destination,
      progress: progressRows[destination.id],
      masterySettings: masterySettings,
    );
    final mastered = result.volume >= mastery.volume;
    if (mastered) {
      changeStatus(destination.id, ExerciseStatus.mastered);
      // Mastering the destination proves the whole route to it: everything
      // still uncleared earlier on its path masters along with it.
      for (final id in destinationPath.sublist(0, destinationIndex)) {
        if (!currentStatus(id).isCleared) {
          changeStatus(id, ExerciseStatus.mastered);
        }
      }
      if (destinationIndex + 1 < destinationPath.length) {
        final successorId = destinationPath[destinationIndex + 1];
        if (currentStatus(successorId) == ExerciseStatus.inactive) {
          changeStatus(successorId, ExerciseStatus.active);
          shortcutActivationsBySource[destination.id] = successorId;
        }
      }
    } else {
      changeStatus(destination.id, ExerciseStatus.active);
      shortcutActivationsBySource[activeId] = destination.id;
    }

    if (switchedFromFoundation) {
      branchesToPersist[category.id] = destinationPathId;
    }
    return true;
  }

  /// Steps earlier on [exercise]'s path that are not yet cleared — the debt a
  /// manual jump leaves behind, settled when the jumped-to exercise masters.
  ///
  /// The path is resolved the way the manual shortcut resolves a destination:
  /// the exercise's own branch when it declares one that contains it, the
  /// track's active branch otherwise, any path containing it as a last
  /// resort. Sibling branches are never touched — only the route to the
  /// exercise itself.
  static List<String> _unclearedPredecessors(
    Exercise exercise, {
    required ExerciseStatus Function(String id) statusOf,
    required Map<String, String> activeBranchByCategory,
  }) {
    if (exercise.skillCategoryId.isEmpty) return const [];
    final category = SkillCategoryCatalog.findById(exercise.skillCategoryId);
    if (category == null) return const [];

    List<String>? path;
    final declared = category.trainingPaths[exercise.branchId];
    if (declared?.contains(exercise.id) ?? false) {
      path = declared;
    } else {
      final selectedId = activeBranchByCategory[category.id] ??
          category.defaultTrainingPathId;
      final selected = category.pathFor(selectedId);
      if (selected.contains(exercise.id)) {
        path = selected;
      } else {
        for (final candidate in category.trainingPaths.values) {
          if (candidate.contains(exercise.id)) {
            path = candidate;
            break;
          }
        }
      }
    }
    if (path == null) return const [];

    return [
      for (final id in path.sublist(0, path.indexOf(exercise.id)))
        if (!statusOf(id).isCleared) id,
    ];
  }

  static int _commonPrefixLength(List<String> a, List<String> b) {
    var length = 0;
    while (length < a.length && length < b.length && a[length] == b[length]) {
      length++;
    }
    return length;
  }

  /// What a loaded lift should do next, or null when the session did not
  /// reach its target — in which case it repeats, unchanged.
  ///
  /// Reps first, then load: 3 × 5 becomes 3 × 6, and 3 × 6 becomes 3 × 7,
  /// up to the top of the rep range (the global mastery target, 8 by
  /// default). Reaching the top adds [loadedLiftIncrementKg] and drops the
  /// reps back to [loadedLiftBottomReps], so the lift starts the climb again
  /// on a heavier bar.
  ///
  /// Nothing here is applied. The user approves it, because only they know
  /// whether the last session was heavy enough to be worth loading.
  static ProgressionSuggestion? suggestionForLoadedLift({
    required Exercise exercise,
    required ExerciseProgress? progress,
    required int volume,
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
  }) {
    final current = currentTargetForExercise(
      exercise,
      progress: progress,
      masterySettings: masterySettings,
    );
    if (volume < current.volume) return null;

    final topReps = masteryValueForExercise(exercise, masterySettings);
    final weightKg = progress?.currentTargetWeightKg;

    // A hold has nowhere to put a plate: it goes forward on seconds, and once
    // it is at the top of its seconds there is nothing to suggest.
    if (isTimedExercise(exercise)) {
      if (current.value >= topReps) return null;
      return ProgressionSuggestion(
        exerciseId: exercise.id,
        kind: ProgressionSuggestionKind.repIncrease,
        sets: current.sets,
        fromValue: current.value,
        toValue: math.min(
          current.value + targetIncrementForExercise(exercise),
          topReps,
        ),
        fromWeightKg: weightKg,
        toWeightKg: weightKg,
      );
    }

    if (current.value >= topReps) {
      return ProgressionSuggestion(
        exerciseId: exercise.id,
        kind: ProgressionSuggestionKind.loadIncrease,
        sets: current.sets,
        fromValue: current.value,
        toValue: math.min(loadedLiftBottomReps, topReps),
        fromWeightKg: weightKg,
        toWeightKg: weightKg == null ? null : weightKg + loadedLiftIncrementKg,
      );
    }

    return ProgressionSuggestion(
      exerciseId: exercise.id,
      kind: ProgressionSuggestionKind.repIncrease,
      sets: current.sets,
      fromValue: current.value,
      toValue: math.min(
          current.value + targetIncrementForExercise(exercise), topReps),
      fromWeightKg: weightKg,
      toWeightKg: weightKg,
    );
  }

  /// The move that follows [exercise], honoring the fork-resolution order in
  /// [computeSessionOutcome]. Candidates come from every training path in
  /// the catalog, so single-path categories (muscle-up, planche) resolve
  /// like any other.
  static _SuccessorResolution _resolveSuccessor(
    Exercise exercise, {
    required Map<String, String> activeBranchByCategory,
    required List<String> goalSkillIds,
  }) {
    final candidates = <({String categoryId, String pathId, String nextId})>[];
    for (final category in SkillCategoryCatalog.all()) {
      for (final entry in category.trainingPaths.entries) {
        final index = entry.value.indexOf(exercise.id);
        if (index >= 0 && index + 1 < entry.value.length) {
          candidates.add((
            categoryId: category.id,
            pathId: entry.key,
            nextId: entry.value[index + 1],
          ));
        }
      }
    }

    if (candidates.isEmpty) {
      return const _SuccessorResolution.none();
    }

    final distinctNexts = {for (final c in candidates) c.nextId};
    if (distinctNexts.length == 1) {
      return _SuccessorResolution(nextExerciseId: distinctNexts.first);
    }

    // 1. The track's active branch continues.
    final activeNexts = {
      for (final c in candidates)
        if (activeBranchByCategory[c.categoryId] == c.pathId) c.nextId,
    };
    if (activeNexts.length == 1) {
      return _SuccessorResolution(nextExerciseId: activeNexts.first);
    }
    if (activeNexts.length > 1) {
      return const _SuccessorResolution.choice();
    }

    // 2. A branch the user's goals point at — persisted so future workouts
    //    follow it. Conflicting goals never auto-pick.
    final goalBranchIds = {
      for (final goalId in goalSkillIds)
        if (TrainingProgramService.goalBranchIds[goalId] case final id?) id,
    };
    final goalCandidates = [
      for (final c in candidates)
        if (goalBranchIds.contains('${c.categoryId}:${c.pathId}')) c,
    ];
    final goalNexts = {for (final c in goalCandidates) c.nextId};
    if (goalNexts.length == 1) {
      final chosen = goalCandidates.first;
      return _SuccessorResolution(
        nextExerciseId: chosen.nextId,
        persistCategoryId: chosen.categoryId,
        persistBranchId: chosen.pathId,
      );
    }
    if (goalNexts.length > 1) {
      return const _SuccessorResolution.choice();
    }

    // 3. The category's default branch.
    final defaultNexts = {
      for (final c in candidates)
        if (SkillCategoryCatalog.findById(c.categoryId)
                ?.defaultTrainingPathId ==
            c.pathId)
          c.nextId,
    };
    if (defaultNexts.length == 1) {
      return _SuccessorResolution(nextExerciseId: defaultNexts.first);
    }

    // 4. Nothing decides the fork — the user does.
    return const _SuccessorResolution.choice();
  }

  /// Applies [computeSessionOutcome], persists every change for [userId],
  /// and records the changes as progression events tied to [sessionId].
  /// Returns the outcome so callers can update their in-memory state.
  ///
  /// Idempotent per session: when events for [sessionId] already exist the
  /// result was applied before, so nothing is evaluated or written again.
  Future<SessionProgressionOutcome> applySessionResults({
    required String userId,
    required String sessionId,
    required List<SessionExerciseResult> results,
    required Map<String, ExerciseProgress> progressRows,
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
    Map<String, String> activeBranchByCategory = const {},
    List<String> goalSkillIds = const [],
    double? bodyweightKg,
  }) async {
    if (await _eventService.hasEventsForSession(userId, sessionId)) {
      return const SessionProgressionOutcome(
        statusChanges: {},
        targetChanges: {},
      );
    }

    final outcome = computeSessionOutcome(
      results: results,
      progressRows: progressRows,
      masterySettings: masterySettings,
      activeBranchByCategory: activeBranchByCategory,
      goalSkillIds: goalSkillIds,
      bodyweightKg: bodyweightKg,
    );
    for (final entry in outcome.statusChanges.entries) {
      await _progressService.upsert(userId, entry.key, entry.value);
    }
    for (final entry in outcome.targetChanges.entries) {
      await _progressService.upsertTarget(
        userId,
        entry.key,
        targetSets: entry.value.sets,
        targetValue: entry.value.value,
      );
    }
    for (final entry in outcome.branchesToPersist.entries) {
      try {
        // A goal decided the fork: the skill track follows the goal's
        // branch from now on (created if the category wasn't tracked yet).
        await _skillTrackService.upsertTrack(
          userId,
          skillCategoryId: entry.key,
          branchId: entry.value,
        );
      } catch (_) {
        // Non-fatal: the successor is already active, so the program shows
        // the right exercise; only the stored branch preference lags.
      }
    }
    if (outcome.suggestions.isNotEmpty) {
      try {
        // Proposals only — nothing about the loaded lift changes until the
        // user approves them on the Train tab.
        await _suggestionService.replaceOpen(
          userId,
          [
            for (final suggestion in outcome.suggestions)
              suggestion.copyWith(workoutSessionId: sessionId),
          ],
        );
      } catch (_) {
        // Non-fatal: the lift simply repeats its current target until the
        // next session earns the suggestion again.
      }
    }
    await _eventService.insertAll(
      userId,
      sessionId,
      buildSessionEvents(
        outcome: outcome,
        results: results,
        progressRows: progressRows,
        masterySettings: masterySettings,
      ),
    );
    return outcome;
  }

  /// The changes a loaded lift is waiting on the user for.
  Future<List<ProgressionSuggestion>> fetchOpenSuggestions(String userId) {
    return _suggestionService.fetchOpen(userId);
  }

  /// Approves [suggestion]: writes the proposed target and working weight,
  /// records what happened in the ledger, and closes the suggestion.
  ///
  /// The event is not tied to a workout session — the user made this call,
  /// days after the session that earned it, so deleting that workout must
  /// not quietly undo their decision.
  Future<void> approveSuggestion({
    required String userId,
    required ProgressionSuggestion suggestion,
  }) async {
    await _progressService.upsertTarget(
      userId,
      suggestion.exerciseId,
      targetSets: suggestion.sets,
      targetValue: suggestion.toValue,
      targetWeightKg: suggestion.toWeightKg,
    );
    await _eventService.insertAll(userId, null, [
      ProgressionEventInput(
        exerciseId: suggestion.exerciseId,
        kind: switch (suggestion.kind) {
          ProgressionSuggestionKind.repIncrease =>
            ProgressionEventKind.targetIncrease,
          ProgressionSuggestionKind.loadIncrease =>
            ProgressionEventKind.loadIncrease,
        },
        valueFrom: suggestion.fromValue,
        valueTo: suggestion.toValue,
        targetSets: suggestion.sets,
        weightFrom: suggestion.fromWeightKg,
        weightTo: suggestion.toWeightKg,
      ),
    ]);
    final id = suggestion.id;
    if (id != null) {
      await _suggestionService.resolve(userId, id, approved: true);
    }
  }

  /// Turns a suggestion down: the lift keeps its current target and weight,
  /// and asks again the next time it reaches them.
  Future<void> dismissSuggestion({
    required String userId,
    required ProgressionSuggestion suggestion,
  }) async {
    final id = suggestion.id;
    if (id == null) return;
    await _suggestionService.resolve(userId, id, approved: false);
  }

  /// Pure translation of a session outcome into ledger events, using the
  /// pre-apply [progressRows] to reconstruct before-values:
  /// - target increases carry the old and new per-set value;
  /// - masteries carry the mastery target that was met;
  /// - activations carry the mastered exercise that unlocked them and the
  ///   starting target of the new move.
  static List<ProgressionEventInput> buildSessionEvents({
    required SessionProgressionOutcome outcome,
    required List<SessionExerciseResult> results,
    required Map<String, ExerciseProgress> progressRows,
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
  }) {
    final trackByExercise = {
      for (final result in results)
        if (result.trackId != null) result.exercise.id: result.trackId,
    };
    final trackByCategory = {
      for (final result in results)
        if (result.trackId != null &&
            result.exercise.skillCategoryId.isNotEmpty)
          result.exercise.skillCategoryId: result.trackId,
    };
    final events = <ProgressionEventInput>[];

    for (final entry in outcome.targetChanges.entries) {
      final exercise = ExerciseCatalog.findById(entry.key);
      if (exercise == null) continue;

      final before = currentTargetForExercise(
        exercise,
        progress: progressRows[entry.key],
        masterySettings: masterySettings,
      );
      events.add(
        ProgressionEventInput(
          exerciseId: entry.key,
          trackId: trackByExercise[entry.key],
          kind: ProgressionEventKind.targetIncrease,
          valueFrom: before.value,
          valueTo: entry.value.value,
          targetSets: entry.value.sets,
        ),
      );
    }

    final masteredIds = [
      for (final entry in outcome.statusChanges.entries)
        if (entry.value == ExerciseStatus.mastered) entry.key,
    ];
    for (final exerciseId in masteredIds) {
      final exercise = ExerciseCatalog.findById(exerciseId);
      if (exercise == null) continue;

      final mastery = masteryTargetForExercise(
        exercise,
        progress: progressRows[exerciseId],
        masterySettings: masterySettings,
      );
      events.add(
        ProgressionEventInput(
          exerciseId: exerciseId,
          // Backfilled masteries (steps a jump left behind) were not in the
          // session's results, so their track comes from their category.
          trackId: trackByExercise[exerciseId] ??
              trackByCategory[exercise.skillCategoryId],
          kind: ProgressionEventKind.mastered,
          valueFrom: outcome.previousStatuses[exerciseId]?.index,
          valueTo: mastery.value,
          targetSets: mastery.sets,
        ),
      );

      // The activation this mastery caused, if any.
      final nextId = outcome.activationsByMastered[exerciseId];
      final next = nextId == null ? null : ExerciseCatalog.findById(nextId);
      if (next != null) {
        events.add(
          ProgressionEventInput(
            exerciseId: next.id,
            trackId: trackByExercise[exerciseId],
            kind: ProgressionEventKind.activated,
            relatedExerciseId: exerciseId,
            valueTo: initialTargetValueForExercise(next),
            targetSets: initialTargetSets,
          ),
        );
      }
    }

    // Manual fast-forwards activate a destination without the ordinary
    // adjacent mastery relationship. valueFrom marks this as an exercise
    // change for the post-workout animation and carries the old target.
    for (final entry in outcome.shortcutActivationsBySource.entries) {
      final next = ExerciseCatalog.findById(entry.value);
      final source = ExerciseCatalog.findById(entry.key);
      if (next == null || source == null) continue;
      final sourceTarget = currentTargetForExercise(
        source,
        progress: progressRows[source.id],
        masterySettings: masterySettings,
      );
      events.add(
        ProgressionEventInput(
          exerciseId: next.id,
          trackId: trackByExercise[next.id] ?? trackByExercise[source.id],
          kind: ProgressionEventKind.activated,
          relatedExerciseId: source.id,
          valueFrom: sourceTarget.value,
          valueTo: initialTargetValueForExercise(next),
          targetSets: initialTargetSets,
        ),
      );
    }

    // Forks the user has to decide, surfaced in the what-changed feed.
    for (final exerciseId in outcome.branchChoicesNeeded) {
      events.add(
        ProgressionEventInput(
          exerciseId: exerciseId,
          trackId: trackByExercise[exerciseId],
          kind: ProgressionEventKind.branchChoice,
        ),
      );
    }

    return events;
  }

  // ── Deletion rollback ─────────────────────────────────────────────
  //
  // Workout history and progression state are related but not the same:
  // deleting a session only reverses its progression effects when it is the
  // most recent progression result of its track. A later result in the same
  // track preserves everything — deleting an old workout must never relock
  // exercises or rewrite later sessions.

  /// Splits a deleted session's events into reversible and preserved, by
  /// checking each event's track (or its exercise, for legacy events without
  /// a track) for later progression results. Fetch this BEFORE deleting the
  /// session — its events cascade away with it.
  Future<SessionRollbackAssessment> assessSessionRollback({
    required String userId,
    required String sessionId,
    required DateTime sessionFinishedAt,
  }) async {
    final events = await _eventService.fetchForSession(userId, sessionId);
    final progressionEvents = [
      for (final event in events)
        if (event.kind == ProgressionEventKind.targetIncrease ||
            event.kind == ProgressionEventKind.mastered ||
            event.kind == ProgressionEventKind.activated)
          event,
    ];
    if (progressionEvents.isEmpty) {
      return const SessionRollbackAssessment(
        reversible: [],
        preserved: [],
      );
    }

    // One later-result check per track (or per exercise when no track).
    final blockedKeys = <String>{};
    final checkedKeys = <String>{};
    for (final event in progressionEvents) {
      final key = _rollbackScopeKey(event);
      if (!checkedKeys.add(key)) continue;

      final hasLater = await _logService.hasLaterProgressionResult(
        userId,
        trackId: event.trackId,
        exerciseId: event.trackId == null ? event.exerciseId : null,
        after: sessionFinishedAt,
        excludeSessionId: sessionId,
      );
      if (hasLater) blockedKeys.add(key);
    }

    return splitReversibleEvents(
      events: progressionEvents,
      isBlocked: (event) => blockedKeys.contains(_rollbackScopeKey(event)),
    );
  }

  /// Pure partition of a session's progression events by a blocked test —
  /// separated from the queries so the rule is testable.
  static SessionRollbackAssessment splitReversibleEvents({
    required List<ProgressionEvent> events,
    required bool Function(ProgressionEvent event) isBlocked,
  }) {
    final reversible = <ProgressionEvent>[];
    final preserved = <ProgressionEvent>[];
    for (final event in events) {
      (isBlocked(event) ? preserved : reversible).add(event);
    }
    return SessionRollbackAssessment(
      reversible: reversible,
      preserved: preserved,
    );
  }

  /// What undoing each event means:
  /// - a target increase restores the target to its before-value;
  /// - a mastery restores the status it replaced — active for an ordinary
  ///   mastery (the stored target was untouched by mastering, so it resumes
  ///   where it was), inactive for a step a jump's mastery backfilled;
  /// - an activation returns the unlocked exercise to inactive, removing it
  ///   from future workouts.
  static List<RollbackAction> rollbackActionsFor(
    List<ProgressionEvent> events,
  ) {
    final actions = <RollbackAction>[];
    for (final event in events) {
      switch (event.kind) {
        case ProgressionEventKind.targetIncrease:
          if (event.valueFrom != null) {
            actions.add(RollbackAction.target(
              exerciseId: event.exerciseId,
              targetSets: event.targetSets ?? initialTargetSets,
              targetValue: event.valueFrom!,
            ));
          }
        case ProgressionEventKind.mastered:
          actions.add(RollbackAction.status(
            exerciseId: event.exerciseId,
            status: event.valueFrom != null &&
                    event.valueFrom! >= 0 &&
                    event.valueFrom! < ExerciseStatus.values.length
                ? ExerciseStatus.values[event.valueFrom!]
                : ExerciseStatus.active,
          ));
        case ProgressionEventKind.activated:
          actions.add(RollbackAction.status(
            exerciseId: event.exerciseId,
            status: ExerciseStatus.inactive,
          ));
        case ProgressionEventKind.personalBest:
        case ProgressionEventKind.branchChoice:
          break; // Nothing was written to progression state.
        case ProgressionEventKind.loadIncrease:
          // Approved by the user, never by a session, so no workout carries
          // it and deleting one cannot reach it.
          break;
      }
    }
    return actions;
  }

  /// Applies the reversals for [events]. Call after the session was deleted.
  Future<void> reverseSessionEvents({
    required String userId,
    required List<ProgressionEvent> events,
  }) async {
    for (final action in rollbackActionsFor(events)) {
      if (action.status != null) {
        await _progressService.upsert(
          userId,
          action.exerciseId,
          action.status!,
        );
      }
      if (action.targetValue != null) {
        await _progressService.upsertTarget(
          userId,
          action.exerciseId,
          targetSets: action.targetSets!,
          targetValue: action.targetValue!,
        );
      }
    }
  }

  static String _rollbackScopeKey(ProgressionEvent event) =>
      event.trackId ?? 'exercise:${event.exerciseId}';
}

/// A deleted session's progression events split by rollback eligibility:
/// [reversible] events get undone; [preserved] events stay because later
/// workouts in their track depend on them.
class SessionRollbackAssessment {
  final List<ProgressionEvent> reversible;
  final List<ProgressionEvent> preserved;

  const SessionRollbackAssessment({
    required this.reversible,
    required this.preserved,
  });

  bool get hasProgression => reversible.isNotEmpty || preserved.isNotEmpty;
}

/// One reversal step: a status restore, a target restore, or both.
class RollbackAction {
  final String exerciseId;
  final ExerciseStatus? status;
  final int? targetSets;
  final int? targetValue;

  const RollbackAction.status({
    required this.exerciseId,
    required ExerciseStatus this.status,
  })  : targetSets = null,
        targetValue = null;

  const RollbackAction.target({
    required this.exerciseId,
    required int this.targetSets,
    required int this.targetValue,
  }) : status = null;
}

/// How a mastered exercise's fork was decided: a successor to activate
/// (optionally with a branch to persist on its skill track), a user choice
/// to request, or nothing (end of path).
class _SuccessorResolution {
  final String? nextExerciseId;
  final String? persistCategoryId;
  final String? persistBranchId;
  final bool choiceNeeded;

  const _SuccessorResolution({
    required this.nextExerciseId,
    this.persistCategoryId,
    this.persistBranchId,
  }) : choiceNeeded = false;

  const _SuccessorResolution.none()
      : nextExerciseId = null,
        persistCategoryId = null,
        persistBranchId = null,
        choiceNeeded = false;

  const _SuccessorResolution.choice()
      : nextExerciseId = null,
        persistCategoryId = null,
        persistBranchId = null,
        choiceNeeded = true;
}
