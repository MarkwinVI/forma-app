import 'dart:math' as math;

import '../catalog/exercise_catalog.dart';
import '../catalog/skill_category_catalog.dart';
import '../models/exercise_model.dart';
import '../models/exercise_progress_model.dart';
import '../models/progression_event_model.dart';
import '../models/training_program_model.dart';
import 'progress_service.dart';
import 'progression_event_service.dart';
import 'training_program_service.dart';
import 'training_program_store_service.dart';

/// One exercise's outcome in a saved workout session: the exercise as it was
/// logged (program section intact, so targets match what the user saw) and
/// the total volume achieved across all sets (reps, or seconds when timed).
class SessionExerciseResult {
  final Exercise exercise;
  final int volume;

  /// Progression track the exercise was trained under (TrainingTrack
  /// dbValue); recorded on the events this result produces.
  final String? trackId;

  const SessionExerciseResult({
    required this.exercise,
    required this.volume,
    this.trackId,
  });
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

  /// Branch selections chosen by goal-driven fork resolution, to be saved
  /// so future workouts follow the new branch.
  final Map<TrainingTrack, String> branchSelectionsToPersist;

  /// Exercises mastered at a fork that neither the user's selections, goals,
  /// nor defaults decide — the user must pick the branch themselves.
  final List<String> branchChoicesNeeded;

  const SessionProgressionOutcome({
    required this.statusChanges,
    required this.targetChanges,
    this.activationsByMastered = const {},
    this.branchSelectionsToPersist = const {},
    this.branchChoicesNeeded = const [],
  });

  bool get isEmpty =>
      statusChanges.isEmpty &&
      targetChanges.isEmpty &&
      branchChoicesNeeded.isEmpty;
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
  final _storeService = TrainingProgramStoreService();

  /// Ladder start: 3 × 6 reps, or 3 × 10s for timed exercises.
  static const int initialTargetSets = 3;
  static const int initialTargetReps = 6;
  static const int initialTargetSeconds = 10;

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
  /// For each result (mastered exercises are skipped, so a session can never
  /// be applied to them again):
  /// 1. Mastery first: volume ≥ sets × mastery value masters the exercise —
  ///    overshooting the current target masters early — and activates the
  ///    next move in its skill path (fork resolution below).
  /// 2. Otherwise, volume ≥ the current target's volume raises the target by
  ///    one increment, capped at the mastery value.
  /// 3. Otherwise nothing changes: the target holds and no progress is lost.
  ///
  /// At a fork — the mastered exercise has different successors on different
  /// branches — the next move is decided in order by:
  /// 1. the user's explicitly selected branch ([branchSelections]),
  /// 2. the branch a goal skill points at ([goalSkillIds]) — which is then
  ///    returned in [SessionProgressionOutcome.branchSelectionsToPersist];
  ///    goals pointing at different branches never auto-pick,
  /// 3. the configured default branch ([defaultBranchSelections]),
  /// 4. otherwise the fork is reported in `branchChoicesNeeded` for the user
  ///    to decide.
  static SessionProgressionOutcome computeSessionOutcome({
    required List<SessionExerciseResult> results,
    required Map<String, ExerciseProgress> progressRows,
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
    List<TrainingBranchOption> branchOptions = const [],
    Map<TrainingTrack, String> branchSelections = const {},
    Map<TrainingTrack, String> defaultBranchSelections = const {},
    List<String> goalSkillIds = const [],
  }) {
    final statusChanges = <String, ExerciseStatus>{};
    final targetChanges = <String, ExerciseTarget>{};
    final activationsByMastered = <String, String>{};
    final branchSelectionsToPersist = <TrainingTrack, String>{};
    final branchChoicesNeeded = <String>[];

    ExerciseStatus statusOf(String id) =>
        statusChanges[id] ??
        progressRows[id]?.status ??
        ExerciseStatus.inactive;

    for (final result in results) {
      final exercise = result.exercise;
      if (statusOf(exercise.id) == ExerciseStatus.mastered) continue;

      final current = currentTargetForExercise(
        exercise,
        progress: progressRows[exercise.id],
        masterySettings: masterySettings,
      );
      final masteryValue = masteryValueForExercise(exercise, masterySettings);
      final masteryVolume = current.sets * masteryValue;

      if (result.volume >= masteryVolume) {
        statusChanges[exercise.id] = ExerciseStatus.mastered;

        final resolution = _resolveSuccessor(
          exercise,
          branchOptions: branchOptions,
          branchSelections: branchSelections,
          defaultBranchSelections: defaultBranchSelections,
          goalSkillIds: goalSkillIds,
        );
        if (resolution.choiceNeeded) {
          branchChoicesNeeded.add(exercise.id);
        } else if (resolution.nextExerciseId != null &&
            statusOf(resolution.nextExerciseId!) == ExerciseStatus.inactive) {
          statusChanges[resolution.nextExerciseId!] = ExerciseStatus.active;
          activationsByMastered[exercise.id] = resolution.nextExerciseId!;
          if (resolution.persistTrack != null &&
              resolution.persistBranchId != null) {
            branchSelectionsToPersist[resolution.persistTrack!] =
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
      branchSelectionsToPersist: branchSelectionsToPersist,
      branchChoicesNeeded: branchChoicesNeeded,
    );
  }

  /// The move that follows [exercise], honoring the fork-resolution order in
  /// [computeSessionOutcome]. Falls back to the catalog-wide unique-successor
  /// scan for paths that aren't exposed as branch options (e.g. muscle-up).
  static _SuccessorResolution _resolveSuccessor(
    Exercise exercise, {
    required List<TrainingBranchOption> branchOptions,
    required Map<TrainingTrack, String> branchSelections,
    required Map<TrainingTrack, String> defaultBranchSelections,
    required List<String> goalSkillIds,
  }) {
    final candidates = <({TrainingBranchOption option, String nextId})>[];
    for (final option in branchOptions) {
      final index = option.exerciseIds.indexOf(exercise.id);
      if (index >= 0 && index + 1 < option.exerciseIds.length) {
        candidates.add(
          (option: option, nextId: option.exerciseIds[index + 1]),
        );
      }
    }

    if (candidates.isEmpty) {
      final next = _nextExerciseInPath(exercise);
      return next == null
          ? const _SuccessorResolution.none()
          : _SuccessorResolution(nextExerciseId: next.id);
    }

    final distinctNexts = {for (final c in candidates) c.nextId};
    if (distinctNexts.length == 1) {
      return _SuccessorResolution(nextExerciseId: distinctNexts.first);
    }

    // 1. The user's explicitly selected branch continues.
    final selectedNexts = {
      for (final c in candidates)
        if (branchSelections[c.option.track] == c.option.id) c.nextId,
    };
    if (selectedNexts.length == 1) {
      return _SuccessorResolution(nextExerciseId: selectedNexts.first);
    }
    if (selectedNexts.length > 1) {
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
        if (goalBranchIds.contains(c.option.id)) c,
    ];
    final goalNexts = {for (final c in goalCandidates) c.nextId};
    if (goalNexts.length == 1) {
      final chosen = goalCandidates.first;
      return _SuccessorResolution(
        nextExerciseId: chosen.nextId,
        persistTrack: chosen.option.track,
        persistBranchId: chosen.option.id,
      );
    }
    if (goalNexts.length > 1) {
      return const _SuccessorResolution.choice();
    }

    // 3. The configured default branch.
    final defaultNexts = {
      for (final c in candidates)
        if (defaultBranchSelections[c.option.track] == c.option.id) c.nextId,
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
    List<TrainingBranchOption> branchOptions = const [],
    Map<TrainingTrack, String> branchSelections = const {},
    Map<TrainingTrack, String> defaultBranchSelections = const {},
    List<String> goalSkillIds = const [],
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
      branchOptions: branchOptions,
      branchSelections: branchSelections,
      defaultBranchSelections: defaultBranchSelections,
      goalSkillIds: goalSkillIds,
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
    if (outcome.branchSelectionsToPersist.isNotEmpty) {
      try {
        await _storeService.upsertBranchSelections(
          userId,
          outcome.branchSelectionsToPersist,
        );
      } catch (_) {
        // Non-fatal: the successor is already active, so the program shows
        // the right exercise; only the stored branch preference lags.
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
          trackId: trackByExercise[exerciseId],
          kind: ProgressionEventKind.mastered,
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

  /// The move that follows [exercise] across every training path it appears
  /// in. An exercise's own skillCategoryId/branchId don't identify the path
  /// being trained (paths share prefix exercises), so all catalog paths are
  /// scanned. Used as the fallback for paths that aren't exposed as branch
  /// options; at a branch point — multiple distinct successors — nothing is
  /// picked.
  static Exercise? _nextExerciseInPath(Exercise exercise) {
    final successors = <String>{};
    for (final category in SkillCategoryCatalog.all()) {
      for (final path in category.trainingPaths.values) {
        final index = path.indexOf(exercise.id);
        if (index >= 0 && index + 1 < path.length) {
          successors.add(path[index + 1]);
        }
      }
    }
    if (successors.length != 1) return null;
    return ExerciseCatalog.findById(successors.first);
  }
}

/// How a mastered exercise's fork was decided: a successor to activate
/// (optionally with a branch selection to persist), a user choice to
/// request, or nothing (end of path).
class _SuccessorResolution {
  final String? nextExerciseId;
  final TrainingTrack? persistTrack;
  final String? persistBranchId;
  final bool choiceNeeded;

  const _SuccessorResolution({
    required this.nextExerciseId,
    this.persistTrack,
    this.persistBranchId,
  }) : choiceNeeded = false;

  const _SuccessorResolution.none()
      : nextExerciseId = null,
        persistTrack = null,
        persistBranchId = null,
        choiceNeeded = false;

  const _SuccessorResolution.choice()
      : nextExerciseId = null,
        persistTrack = null,
        persistBranchId = null,
        choiceNeeded = true;
}
