import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/exercise_progress_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/services/exercise_progression_service.dart';

void main() {
  // Use real path exercises from the catalog so the rules are tested against
  // the data the app actually ships.
  late Exercise first;
  late String secondId;
  late Exercise repExercise;
  late Exercise timedExercise;

  ExerciseProgress progressWith({
    required String exerciseId,
    ExerciseStatus status = ExerciseStatus.active,
    int? targetSets,
    int? targetValue,
  }) {
    return ExerciseProgress(
      exerciseId: exerciseId,
      status: status,
      updatedAt: DateTime(2026),
      currentTargetSets: targetSets,
      currentTargetValue: targetValue,
    );
  }

  setUpAll(() {
    final core = SkillCategoryCatalog.findById(SkillCategoryCatalog.coreId)!;
    final path = core.pathFor('l_sit');
    expect(path.length, greaterThan(1));
    first = ExerciseCatalog.findById(path.first)!;
    secondId = path[1];

    repExercise = ExerciseCatalog.all().firstWhere(
      (exercise) => !ExerciseProgressionService.isTimedExercise(exercise),
    );
    timedExercise = ExerciseCatalog.all().firstWhere(
      (exercise) => ExerciseProgressionService.isTimedExercise(exercise),
    );
  });

  group('currentTargetForExercise', () {
    test('starts the ladder at 3 × 6 reps / 3 × 10s timed', () {
      final rep = ExerciseProgressionService.currentTargetForExercise(
        repExercise,
      );
      expect(rep.sets, 3);
      expect(rep.value, 6);

      final timed = ExerciseProgressionService.currentTargetForExercise(
        timedExercise,
      );
      expect(timed.sets, 3);
      expect(timed.value, 10);
    });

    test('resumes from the stored target when one exists', () {
      final target = ExerciseProgressionService.currentTargetForExercise(
        repExercise,
        progress: progressWith(
          exerciseId: repExercise.id,
          targetSets: 3,
          targetValue: 7,
        ),
      );
      expect(target.value, 7);
    });

    test('is clamped to a lowered mastery target without touching storage', () {
      final target = ExerciseProgressionService.currentTargetForExercise(
        repExercise,
        progress: progressWith(
          exerciseId: repExercise.id,
          targetSets: 3,
          targetValue: 10,
        ),
        masterySettings: const MasteryTargetSettings(repsPerSet: 8),
      );
      // Shown goal is never harder than mastery requires; the stored 10
      // stays intact so raising the setting back restores it.
      expect(target.value, 8);
    });
  });

  group('computeSessionOutcome', () {
    test('reaching the current target raises it by one rep per set', () {
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          // 3 × 6 = 18 total reps: total volume counts, regardless of
          // per-set distribution.
          SessionExerciseResult(exercise: repExercise, volume: 18),
        ],
        progressRows: const {},
      );

      expect(outcome.statusChanges, isEmpty);
      expect(outcome.targetChanges[repExercise.id]?.sets, 3);
      expect(outcome.targetChanges[repExercise.id]?.value, 7);
    });

    test('timed exercises climb by five seconds per set', () {
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          // Current 3 × 10s = 30s; mastery 3 × 20s = 60s.
          SessionExerciseResult(exercise: timedExercise, volume: 30),
        ],
        progressRows: const {},
      );

      expect(outcome.statusChanges, isEmpty);
      expect(outcome.targetChanges[timedExercise.id]?.value, 15);
    });

    test('failing the current target changes nothing', () {
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(exercise: repExercise, volume: 17),
        ],
        progressRows: const {},
      );

      expect(outcome.isEmpty, isTrue);
    });

    test('the target never climbs past the mastery target', () {
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          // Current 3 × 7 = 21 < mastery 3 × 8 = 24 → increment, capped.
          SessionExerciseResult(exercise: repExercise, volume: 21),
        ],
        progressRows: {
          repExercise.id: progressWith(
            exerciseId: repExercise.id,
            targetSets: 3,
            targetValue: 7,
          ),
        },
      );

      expect(outcome.targetChanges[repExercise.id]?.value, 8);
    });

    test('reaching the mastery target masters and activates the next move', () {
      final masteryVolume = ExerciseProgressionService.masteryTargetForExercise(
        first,
      ).volume;

      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(exercise: first, volume: masteryVolume),
        ],
        progressRows: const {},
      );

      expect(outcome.statusChanges[first.id], ExerciseStatus.mastered);
      expect(outcome.statusChanges[secondId], ExerciseStatus.active);
      expect(outcome.targetChanges, isEmpty);
    });

    test('overshooting the current target masters early', () {
      // Current target is still the initial 3 × 6, but the session already
      // meets mastery volume (3 × 8 = 24) — no intermediate workouts needed.
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(exercise: repExercise, volume: 24),
        ],
        progressRows: const {},
      );

      expect(
        outcome.statusChanges[repExercise.id],
        ExerciseStatus.mastered,
      );
      expect(outcome.targetChanges, isEmpty);
    });

    test('a raised mastery target extends the ladder of an active exercise',
        () {
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          // 3 × 8 = 24 would master under default settings, but mastery was
          // raised to 10 — so it's a normal target increase instead.
          SessionExerciseResult(exercise: repExercise, volume: 24),
        ],
        progressRows: {
          repExercise.id: progressWith(
            exerciseId: repExercise.id,
            targetSets: 3,
            targetValue: 8,
          ),
        },
        masterySettings: const MasteryTargetSettings(repsPerSet: 10),
      );

      expect(outcome.statusChanges, isEmpty);
      expect(outcome.targetChanges[repExercise.id]?.value, 9);
    });

    test('a lowered mastery target only masters through a workout result', () {
      // Stored target 3 × 10 with mastery lowered to 8: nothing happens
      // until a session actually reaches 3 × 8 = 24 total.
      final rows = {
        repExercise.id: progressWith(
          exerciseId: repExercise.id,
          targetSets: 3,
          targetValue: 10,
        ),
      };
      const settings = MasteryTargetSettings(repsPerSet: 8);

      final failing = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(exercise: repExercise, volume: 23),
        ],
        progressRows: rows,
        masterySettings: settings,
      );
      expect(failing.isEmpty, isTrue);

      final mastering = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(exercise: repExercise, volume: 24),
        ],
        progressRows: rows,
        masterySettings: settings,
      );
      expect(
        mastering.statusChanges[repExercise.id],
        ExerciseStatus.mastered,
      );
    });

    test('an already-mastered exercise is never progressed again', () {
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(exercise: repExercise, volume: 100),
        ],
        progressRows: {
          repExercise.id: progressWith(
            exerciseId: repExercise.id,
            status: ExerciseStatus.mastered,
          ),
        },
      );

      expect(outcome.isEmpty, isTrue);
    });

    test('a branch point without context falls back to the category default',
        () {
      // pull_up has different successors per branch (weighted, close grip,
      // l-sit, one arm); with no active branch or goal, the pullups
      // category's default branch (weighted) decides.
      final pullUp = ExerciseCatalog.findById('pullups_pull_up')!;
      final masteryVolume = ExerciseProgressionService.masteryTargetForExercise(
        pullUp,
      ).volume;
      final weightedPath = SkillCategoryCatalog.findById(
        SkillCategoryCatalog.pullupsId,
      )!
          .pathFor('weighted');
      final weightedNext = weightedPath[weightedPath.indexOf(pullUp.id) + 1];

      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(exercise: pullUp, volume: masteryVolume),
        ],
        progressRows: const {},
      );

      expect(outcome.statusChanges[pullUp.id], ExerciseStatus.mastered);
      expect(outcome.statusChanges[weightedNext], ExerciseStatus.active);
      expect(outcome.branchChoicesNeeded, isEmpty);
    });

    group('fork resolution', () {
      late Exercise pullUp;
      late int masteryVolume;
      late String weightedNext;
      late String oneArmNext;

      String successorIn(String pathId) {
        final path = SkillCategoryCatalog.findById(
          SkillCategoryCatalog.pullupsId,
        )!
            .pathFor(pathId);
        return path[path.indexOf(pullUp.id) + 1];
      }

      setUpAll(() {
        pullUp = ExerciseCatalog.findById('pullups_pull_up')!;
        masteryVolume = ExerciseProgressionService.masteryTargetForExercise(
          pullUp,
        ).volume;
        weightedNext = successorIn('weighted');
        oneArmNext = successorIn('one_arm');
        expect(weightedNext, isNot(oneArmNext));
      });

      SessionProgressionOutcome resolve({
        Map<String, String> activeBranches = const {},
        List<String> goals = const [],
      }) {
        return ExerciseProgressionService.computeSessionOutcome(
          results: [
            SessionExerciseResult(exercise: pullUp, volume: masteryVolume),
          ],
          progressRows: const {},
          activeBranchByCategory: activeBranches,
          goalSkillIds: goals,
        );
      }

      test('the track\'s active branch continues past the fork', () {
        final outcome = resolve(activeBranches: {'pullups': 'one_arm'});

        expect(outcome.statusChanges[oneArmNext], ExerciseStatus.active);
        expect(outcome.activationsByMastered[pullUp.id], oneArmNext);
        expect(outcome.branchesToPersist, isEmpty);
        expect(outcome.branchChoicesNeeded, isEmpty);
      });

      test('a goal skill decides the fork and the branch is persisted', () {
        final outcome = resolve(goals: ['oap']);

        expect(outcome.statusChanges[oneArmNext], ExerciseStatus.active);
        expect(outcome.branchesToPersist, {'pullups': 'one_arm'});
        expect(outcome.branchChoicesNeeded, isEmpty);
      });

      test('goals pointing at different branches ask the user instead', () {
        final outcome = resolve(goals: ['oap', 'lsitpull']);

        expect(outcome.statusChanges[pullUp.id], ExerciseStatus.mastered);
        // The fork stays undecided: nothing new starts training.
        expect(
          outcome.statusChanges.values.contains(ExerciseStatus.active),
          isFalse,
        );
        expect(outcome.branchChoicesNeeded, [pullUp.id]);
        expect(outcome.branchesToPersist, isEmpty);
      });

      test('with no active branch or goal, the category default decides', () {
        final outcome = resolve();

        expect(outcome.statusChanges[weightedNext], ExerciseStatus.active);
        expect(outcome.branchesToPersist, isEmpty);
      });

      test('the active branch outranks a conflicting goal', () {
        final outcome = resolve(
          activeBranches: {'pullups': 'weighted'},
          goals: ['oap'],
        );

        expect(outcome.statusChanges[weightedNext], ExerciseStatus.active);
        expect(outcome.branchesToPersist, isEmpty);
      });
    });

    test('an already-active next exercise is not re-written', () {
      final masteryVolume = ExerciseProgressionService.masteryTargetForExercise(
        first,
      ).volume;

      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(exercise: first, volume: masteryVolume),
        ],
        progressRows: {
          secondId: progressWith(exerciseId: secondId),
        },
      );

      expect(outcome.statusChanges[first.id], ExerciseStatus.mastered);
      expect(outcome.statusChanges.containsKey(secondId), isFalse);
    });
  });

  group('manual skill-tree fast-forward', () {
    SessionExerciseResult manualResult(
      Exercise exercise, {
      int value = 6,
      double weightKg = 0,
    }) {
      return SessionExerciseResult(
        exercise: exercise,
        volume: value * 3,
        wasManuallyAdded: true,
        sets: [
          for (var i = 0; i < 3; i++)
            SessionSetResult(value: value, weightKg: weightKg),
        ],
      );
    }

    test('manually adding the current active node still advances its target',
        () {
      final category = SkillCategoryCatalog.findById(
        SkillCategoryCatalog.pushupsId,
      )!;
      final active = ExerciseCatalog.findById(category.pathFor('one_arm')[1])!;

      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [manualResult(active)],
        progressRows: {active.id: progressWith(exerciseId: active.id)},
        activeBranchByCategory: {category.id: 'one_arm'},
      );

      expect(outcome.targetChanges[active.id]?.value, 7);
      expect(outcome.statusChanges, isEmpty);
    });

    test('a jump retires the active node, leaves the rest locked, and '
        'activates the destination', () {
      final category = SkillCategoryCatalog.findById(
        SkillCategoryCatalog.pushupsId,
      )!;
      final path = category.pathFor('one_arm');
      final active = path[1];
      final destination = ExerciseCatalog.findById(path[4])!;

      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [manualResult(destination)],
        progressRows: {
          active: progressWith(exerciseId: active),
        },
        activeBranchByCategory: {category.id: 'one_arm'},
      );

      expect(outcome.statusChanges[active], ExerciseStatus.inactive);
      // The jumped-over steps are untouched: still locked until the
      // destination is mastered.
      for (final id in path.sublist(2, 4)) {
        expect(outcome.statusChanges.containsKey(id), isFalse);
      }
      expect(outcome.statusChanges[destination.id], ExerciseStatus.active);
      expect(outcome.shortcutActivationsBySource[active], destination.id);
      expect(outcome.branchesToPersist, isEmpty);
    });

    test('a foundation shortcut switches to the destination branch', () {
      final category = SkillCategoryCatalog.findById(
        SkillCategoryCatalog.pullupsId,
      )!;
      final selectedPath = category.pathFor('weighted');
      final destinationPath = category.pathFor('one_arm');
      final active = selectedPath[2];
      final destination = ExerciseCatalog.findById(destinationPath[5])!;

      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [manualResult(destination)],
        progressRows: {active: progressWith(exerciseId: active)},
        activeBranchByCategory: {category.id: 'weighted'},
      );

      expect(outcome.statusChanges[active], ExerciseStatus.inactive);
      expect(outcome.statusChanges[destination.id], ExerciseStatus.active);
      expect(outcome.branchesToPersist, {category.id: 'one_arm'});
    });

    test('a cross-branch shortcut leaves the selected branch unchanged', () {
      final category = SkillCategoryCatalog.findById(
        SkillCategoryCatalog.pullupsId,
      )!;
      final selectedPath = category.pathFor('weighted');
      final destinationPath = category.pathFor('one_arm');
      final active = selectedPath[4];
      final destination = ExerciseCatalog.findById(destinationPath[6])!;

      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [manualResult(destination)],
        progressRows: {active: progressWith(exerciseId: active)},
        activeBranchByCategory: {category.id: 'weighted'},
      );

      expect(outcome.statusChanges[active], ExerciseStatus.inactive);
      expect(
        outcome.statusChanges.containsKey(destinationPath[4]),
        isFalse,
      );
      expect(
        outcome.statusChanges.containsKey(destinationPath[5]),
        isFalse,
      );
      expect(outcome.statusChanges[destination.id], ExerciseStatus.active);
      expect(outcome.branchesToPersist, isEmpty);
    });

    test('mastering the manual destination masters the route to it and '
        'activates its successor', () {
      final category = SkillCategoryCatalog.findById(
        SkillCategoryCatalog.pushupsId,
      )!;
      final path = category.pathFor('one_arm');
      final active = path[0];
      final destination = ExerciseCatalog.findById(path[2])!;

      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [manualResult(destination, value: 8)],
        progressRows: {active: progressWith(exerciseId: active)},
        activeBranchByCategory: {category.id: 'one_arm'},
      );

      expect(outcome.statusChanges[destination.id], ExerciseStatus.mastered);
      // The steps the jump cleared past are proven along with it.
      expect(outcome.statusChanges[path[0]], ExerciseStatus.mastered);
      expect(outcome.statusChanges[path[1]], ExerciseStatus.mastered);
      expect(outcome.previousStatuses[path[0]], ExerciseStatus.active);
      expect(outcome.previousStatuses[path[1]], ExerciseStatus.inactive);
      expect(outcome.statusChanges[path[3]], ExerciseStatus.active);
      expect(
        outcome.shortcutActivationsBySource[destination.id],
        path[3],
      );
    });

    test('mastering a jumped-to node later masters the steps it left locked',
        () {
      final category = SkillCategoryCatalog.findById(
        SkillCategoryCatalog.pushupsId,
      )!;
      final path = category.pathFor('one_arm');
      // A jump already happened: path[3] is being trained, path[0..2] were
      // never cleared. The session now reaches the mastery target through
      // the ordinary ladder (not manually added).
      final destination = ExerciseCatalog.findById(path[3])!;
      final masteryVolume = 3 *
          ExerciseProgressionService.masteryValueForExercise(
            destination,
            MasteryTargetSettings.defaults,
          );

      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(exercise: destination, volume: masteryVolume),
        ],
        progressRows: {
          destination.id: progressWith(
            exerciseId: destination.id,
            status: ExerciseStatus.active,
          ),
        },
        activeBranchByCategory: {category.id: 'one_arm'},
      );

      expect(outcome.statusChanges[destination.id], ExerciseStatus.mastered);
      for (final id in path.sublist(0, 3)) {
        expect(outcome.statusChanges[id], ExerciseStatus.mastered);
        expect(outcome.previousStatuses[id], ExerciseStatus.inactive);
      }
      expect(outcome.statusChanges[path[4]], ExerciseStatus.active);
    });

    test('timed nodes require three sets of at least ten seconds', () {
      final category = SkillCategoryCatalog.findById(
        SkillCategoryCatalog.plancheId,
      )!;
      final path = category.pathFor('main');
      final active = path[0];
      final destination = ExerciseCatalog.findById(path[2])!;
      expect(destination.isTimed, isTrue);
      final rows = {active: progressWith(exerciseId: active)};

      final below = ExerciseProgressionService.computeSessionOutcome(
        results: [manualResult(destination, value: 9)],
        progressRows: rows,
        activeBranchByCategory: {category.id: 'main'},
      );
      expect(below.isEmpty, isTrue);

      final met = ExerciseProgressionService.computeSessionOutcome(
        results: [manualResult(destination, value: 10)],
        progressRows: rows,
        activeBranchByCategory: {category.id: 'main'},
      );
      expect(met.statusChanges[destination.id], ExerciseStatus.active);
    });

    test('weighted nodes require the bodyweight-derived external load', () {
      final category = SkillCategoryCatalog.findById(
        SkillCategoryCatalog.pullupsId,
      )!;
      final path = category.pathFor('weighted');
      final active = path[3];
      final destination = ExerciseCatalog.findById(path[4])!;
      expect(
        ExerciseProgressionService.requiredExternalWeightKg(destination, 80),
        closeTo(12, 0.001),
      );
      final rows = {active: progressWith(exerciseId: active)};

      final below = ExerciseProgressionService.computeSessionOutcome(
        results: [manualResult(destination, weightKg: 11.5)],
        progressRows: rows,
        activeBranchByCategory: {category.id: 'weighted'},
        bodyweightKg: 80,
      );
      expect(below.isEmpty, isTrue);

      final met = ExerciseProgressionService.computeSessionOutcome(
        results: [manualResult(destination, weightKg: 12)],
        progressRows: rows,
        activeBranchByCategory: {category.id: 'weighted'},
        bodyweightKg: 80,
      );
      expect(met.statusChanges[destination.id], ExerciseStatus.active);
    });
  });
}
