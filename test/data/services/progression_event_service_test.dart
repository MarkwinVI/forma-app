import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/exercise_progress_model.dart';
import 'package:forma_app/data/models/progression_event_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/services/exercise_progression_service.dart';
import 'package:forma_app/data/services/progression_event_service.dart';

void main() {
  group('ExerciseProgressionService.buildSessionEvents', () {
    late Exercise first;
    late String secondId;
    late Exercise repExercise;

    setUpAll(() {
      final core = SkillCategoryCatalog.findById(SkillCategoryCatalog.coreId)!;
      final path = core.pathFor('l_sit');
      first = ExerciseCatalog.findById(path.first)!;
      secondId = path[1];
      repExercise = ExerciseCatalog.all().firstWhere(
        (exercise) => !ExerciseProgressionService.isTimedExercise(exercise),
      );
    });

    test('a target increase carries before and after values', () {
      final results = [
        SessionExerciseResult(
          exercise: repExercise,
          volume: 21,
          trackId: 'vertical_pull',
        ),
      ];
      final rows = {
        repExercise.id: ExerciseProgress(
          exerciseId: repExercise.id,
          status: ExerciseStatus.active,
          updatedAt: DateTime(2026),
          currentTargetSets: 3,
          currentTargetValue: 7,
        ),
      };
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: results,
        progressRows: rows,
      );

      final events = ExerciseProgressionService.buildSessionEvents(
        outcome: outcome,
        results: results,
        progressRows: rows,
      );

      expect(events, hasLength(1));
      final event = events.single;
      expect(event.kind, ProgressionEventKind.targetIncrease);
      expect(event.exerciseId, repExercise.id);
      expect(event.trackId, 'vertical_pull');
      expect(event.valueFrom, 7);
      expect(event.valueTo, 8);
      expect(event.targetSets, 3);
    });

    test(
        'mastery produces a mastered event and an activation event linked '
        'to it', () {
      final masteryVolume = ExerciseProgressionService.masteryTargetForExercise(
        first,
      ).volume;
      final results = [
        SessionExerciseResult(
          exercise: first,
          volume: masteryVolume,
          trackId: 'core',
        ),
      ];
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: results,
        progressRows: const {},
      );

      final events = ExerciseProgressionService.buildSessionEvents(
        outcome: outcome,
        results: results,
        progressRows: const {},
      );

      expect(events, hasLength(2));

      final mastered = events.firstWhere(
        (event) => event.kind == ProgressionEventKind.mastered,
      );
      expect(mastered.exerciseId, first.id);
      expect(mastered.trackId, 'core');
      expect(
        mastered.valueTo,
        ExerciseProgressionService.masteryValueForExercise(
          first,
          const MasteryTargetSettings(),
        ),
      );

      final activated = events.firstWhere(
        (event) => event.kind == ProgressionEventKind.activated,
      );
      expect(activated.exerciseId, secondId);
      expect(activated.relatedExerciseId, first.id);
      expect(activated.trackId, 'core');
      final next = ExerciseCatalog.findById(secondId)!;
      expect(
        activated.valueTo,
        ExerciseProgressionService.initialTargetValueForExercise(next),
      );
      expect(activated.targetSets, 3);
    });

    test('a session with no changes produces no events', () {
      final results = [
        SessionExerciseResult(exercise: repExercise, volume: 1),
      ];
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: results,
        progressRows: const {},
      );

      final events = ExerciseProgressionService.buildSessionEvents(
        outcome: outcome,
        results: results,
        progressRows: const {},
      );

      expect(events, isEmpty);
    });

    test('manual fast-forward records skipped nodes and changed exercise', () {
      final category = SkillCategoryCatalog.findById(
        SkillCategoryCatalog.pushupsId,
      )!;
      final path = category.pathFor('one_arm');
      final activeId = path[1];
      final destination = ExerciseCatalog.findById(path[3])!;
      final rows = {
        activeId: ExerciseProgress(
          exerciseId: activeId,
          status: ExerciseStatus.active,
          updatedAt: DateTime(2026),
        ),
      };
      final results = [
        SessionExerciseResult(
          exercise: destination,
          volume: 18,
          trackId: 'horizontal_push',
          wasManuallyAdded: true,
          sets: const [
            SessionSetResult(value: 6),
            SessionSetResult(value: 6),
            SessionSetResult(value: 6),
          ],
        ),
      ];
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: results,
        progressRows: rows,
        activeBranchByCategory: {category.id: 'one_arm'},
      );

      final events = ExerciseProgressionService.buildSessionEvents(
        outcome: outcome,
        results: results,
        progressRows: rows,
      );

      final skipped = events
          .where((event) => event.kind == ProgressionEventKind.skipped)
          .toList();
      expect(skipped, hasLength(2));
      expect(skipped.first.valueFrom, ExerciseStatus.active.index);
      expect(skipped.first.trackId, 'horizontal_push');

      final activated = events.singleWhere(
        (event) => event.kind == ProgressionEventKind.activated,
      );
      expect(activated.exerciseId, destination.id);
      expect(activated.relatedExerciseId, activeId);
      expect(activated.valueFrom, 6);
      expect(activated.valueTo, 6);
    });
  });

  group('deletion rollback', () {
    ProgressionEvent event({
      required String exerciseId,
      required ProgressionEventKind kind,
      String? trackId,
      int? valueFrom,
      int? valueTo,
      int? targetSets,
    }) {
      return ProgressionEvent(
        id: 'evt-$exerciseId-${kind.name}',
        exerciseId: exerciseId,
        kind: kind,
        createdAt: DateTime(2026),
        trackId: trackId,
        valueFrom: valueFrom,
        valueTo: valueTo,
        targetSets: targetSets,
      );
    }

    test('events in a blocked track are preserved, others reverse', () {
      final blockedIncrease = event(
        exerciseId: 'pullups_pull_up',
        kind: ProgressionEventKind.targetIncrease,
        trackId: 'vertical_pull',
        valueFrom: 6,
        valueTo: 7,
      );
      final freeMastery = event(
        exerciseId: 'box_pistol',
        kind: ProgressionEventKind.mastered,
        trackId: 'squat',
        valueTo: 8,
      );

      final assessment = ExerciseProgressionService.splitReversibleEvents(
        events: [blockedIncrease, freeMastery],
        isBlocked: (candidate) => candidate.trackId == 'vertical_pull',
      );

      expect(assessment.preserved, [blockedIncrease]);
      expect(assessment.reversible, [freeMastery]);
      expect(assessment.hasProgression, isTrue);
    });

    test('rollback actions restore targets and statuses, and skip the rest',
        () {
      final actions = ExerciseProgressionService.rollbackActionsFor([
        event(
          exerciseId: 'pushups_push_up',
          kind: ProgressionEventKind.targetIncrease,
          valueFrom: 6,
          valueTo: 7,
          targetSets: 3,
        ),
        event(exerciseId: 'chin_up', kind: ProgressionEventKind.mastered),
        event(exerciseId: 'muscle_up', kind: ProgressionEventKind.activated),
        event(exerciseId: 'row', kind: ProgressionEventKind.personalBest),
        event(
            exerciseId: 'pullups_pull_up',
            kind: ProgressionEventKind.branchChoice),
        // A legacy increase without a before-value can't be restored.
        event(
          exerciseId: 'dip',
          kind: ProgressionEventKind.targetIncrease,
          valueTo: 9,
        ),
      ]);

      expect(actions, hasLength(3));

      final target = actions[0];
      expect(target.exerciseId, 'pushups_push_up');
      expect(target.targetSets, 3);
      expect(target.targetValue, 6);
      expect(target.status, isNull);

      final unmaster = actions[1];
      expect(unmaster.exerciseId, 'chin_up');
      expect(unmaster.status, ExerciseStatus.active);

      final deactivate = actions[2];
      expect(deactivate.exerciseId, 'muscle_up');
      expect(deactivate.status, ExerciseStatus.inactive);
    });

    test('shortcut rollback restores skipped and directly mastered statuses',
        () {
      final actions = ExerciseProgressionService.rollbackActionsFor([
        event(
          exerciseId: 'pushups_incline_push_up',
          kind: ProgressionEventKind.skipped,
          valueFrom: ExerciseStatus.active.index,
        ),
        event(
          exerciseId: 'pushups_diamond_push_up',
          kind: ProgressionEventKind.mastered,
          valueFrom: ExerciseStatus.inactive.index,
        ),
      ]);

      expect(actions, hasLength(2));
      expect(actions[0].status, ExerciseStatus.active);
      expect(actions[1].status, ExerciseStatus.inactive);
    });
  });

  group('ProgressionEventService.computePersonalBests', () {
    test('a higher best set with history is a personal best', () {
      final events = ProgressionEventService.computePersonalBests(
        candidates: const [
          PersonalBestCandidate(
            exerciseId: 'pullups_pull_up',
            trackId: 'vertical_pull',
            bestSetValue: 9,
          ),
        ],
        previousBests: const {'pullups_pull_up': 8},
      );

      expect(events, hasLength(1));
      expect(events.single.kind, ProgressionEventKind.personalBest);
      expect(events.single.valueFrom, 8);
      expect(events.single.valueTo, 9);
    });

    test('no history means no personal best on a first-ever log', () {
      final events = ProgressionEventService.computePersonalBests(
        candidates: const [
          PersonalBestCandidate(exerciseId: 'pullups_pull_up', bestSetValue: 9),
        ],
        previousBests: const {},
      );

      expect(events, isEmpty);
    });

    test('matching the previous best is not a personal best', () {
      final events = ProgressionEventService.computePersonalBests(
        candidates: const [
          PersonalBestCandidate(exerciseId: 'pullups_pull_up', bestSetValue: 8),
        ],
        previousBests: const {'pullups_pull_up': 8},
      );

      expect(events, isEmpty);
    });
  });
}
