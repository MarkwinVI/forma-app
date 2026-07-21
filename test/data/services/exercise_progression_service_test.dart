import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/exercise_progress_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/services/exercise_progression_service.dart';
import 'package:forma_app/data/services/training_program_service.dart';

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

    test('is clamped to a lowered mastery target without touching storage',
        () {
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

    test('reaching the mastery target masters and activates the next move',
        () {
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

    test('a lowered mastery target only masters through a workout result',
        () {
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

    test('a branch point without context masters but activates nothing', () {
      // pull_up has different successors per branch (weighted, close grip,
      // l-sit, one arm), so no single next move can be chosen without
      // branch options.
      final pullUp = ExerciseCatalog.findById('pull_up')!;
      final masteryVolume = ExerciseProgressionService.masteryTargetForExercise(
        pullUp,
      ).volume;

      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(exercise: pullUp, volume: masteryVolume),
        ],
        progressRows: const {},
      );

      expect(outcome.statusChanges, {pullUp.id: ExerciseStatus.mastered});
      expect(outcome.branchChoicesNeeded, isEmpty);
    });

    group('fork resolution', () {
      final service = TrainingProgramService();
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
        pullUp = ExerciseCatalog.findById('pull_up')!;
        masteryVolume = ExerciseProgressionService.masteryTargetForExercise(
          pullUp,
        ).volume;
        weightedNext = successorIn('weighted');
        oneArmNext = successorIn('one_arm');
        expect(weightedNext, isNot(oneArmNext));
      });

      SessionProgressionOutcome resolve({
        Map<TrainingTrack, String> branchSelections = const {},
        Map<TrainingTrack, String> defaults = const {},
        List<String> goals = const [],
      }) {
        return ExerciseProgressionService.computeSessionOutcome(
          results: [
            SessionExerciseResult(exercise: pullUp, volume: masteryVolume),
          ],
          progressRows: const {},
          branchOptions: service.allBranchOptions(),
          branchSelections: branchSelections,
          defaultBranchSelections: defaults,
          goalSkillIds: goals,
        );
      }

      test('the explicitly selected branch continues past the fork', () {
        final outcome = resolve(
          branchSelections: {TrainingTrack.verticalPull: 'pullups:weighted'},
        );

        expect(outcome.statusChanges[weightedNext], ExerciseStatus.active);
        expect(outcome.activationsByMastered[pullUp.id], weightedNext);
        expect(outcome.branchSelectionsToPersist, isEmpty);
        expect(outcome.branchChoicesNeeded, isEmpty);
      });

      test('a goal skill decides the fork and the branch is persisted', () {
        final outcome = resolve(goals: ['oap']);

        expect(outcome.statusChanges[oneArmNext], ExerciseStatus.active);
        expect(
          outcome.branchSelectionsToPersist,
          {TrainingTrack.verticalPull: 'pullups:one_arm'},
        );
        expect(outcome.branchChoicesNeeded, isEmpty);
      });

      test('goals pointing at different branches ask the user instead', () {
        final outcome = resolve(goals: ['oap', 'lsitpull']);

        expect(outcome.statusChanges, {pullUp.id: ExerciseStatus.mastered});
        expect(outcome.branchChoicesNeeded, [pullUp.id]);
        expect(outcome.branchSelectionsToPersist, isEmpty);
      });

      test('with no selection or goal, the default branch decides', () {
        final outcome = resolve(defaults: service.defaultBranchSelections());

        expect(outcome.statusChanges[weightedNext], ExerciseStatus.active);
        expect(outcome.branchSelectionsToPersist, isEmpty);
      });

      test('nothing decides the fork: the user is asked', () {
        final outcome = resolve();

        expect(outcome.statusChanges, {pullUp.id: ExerciseStatus.mastered});
        expect(outcome.branchChoicesNeeded, [pullUp.id]);
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
}
