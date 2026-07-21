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

    test('mastery produces a mastered event and an activation event linked '
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
  });

  group('ProgressionEventService.computePersonalBests', () {
    test('a higher best set with history is a personal best', () {
      final events = ProgressionEventService.computePersonalBests(
        candidates: const [
          PersonalBestCandidate(
            exerciseId: 'pull_up',
            trackId: 'vertical_pull',
            bestSetValue: 9,
          ),
        ],
        previousBests: const {'pull_up': 8},
      );

      expect(events, hasLength(1));
      expect(events.single.kind, ProgressionEventKind.personalBest);
      expect(events.single.valueFrom, 8);
      expect(events.single.valueTo, 9);
    });

    test('no history means no personal best on a first-ever log', () {
      final events = ProgressionEventService.computePersonalBests(
        candidates: const [
          PersonalBestCandidate(exerciseId: 'pull_up', bestSetValue: 9),
        ],
        previousBests: const {},
      );

      expect(events, isEmpty);
    });

    test('matching the previous best is not a personal best', () {
      final events = ProgressionEventService.computePersonalBests(
        candidates: const [
          PersonalBestCandidate(exerciseId: 'pull_up', bestSetValue: 8),
        ],
        previousBests: const {'pull_up': 8},
      );

      expect(events, isEmpty);
    });
  });
}
