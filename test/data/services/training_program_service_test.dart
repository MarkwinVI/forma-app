import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/services/training_program_service.dart';

void main() {
  final service = TrainingProgramService();

  group('branchSelectionsForGoals', () {
    test('each goal claims its branch on the track that offers it', () {
      final selections =
          service.branchSelectionsForGoals(const ['pistol', 'frontlever']);

      expect(selections[TrainingTrack.squat], 'squat:pistol');
      expect(selections[TrainingTrack.horizontalPull], 'rows:front_lever');
    });

    test('goals disagreeing about one track leave it on the default', () {
      final selections =
          service.branchSelectionsForGoals(const ['pistol', 'shrimp']);

      expect(selections.containsKey(TrainingTrack.squat), isFalse);
    });

    test('goals without a lane branch are ignored', () {
      expect(service.branchSelectionsForGoals(const ['muscleup']), isEmpty);
    });

    test('every mapped goal branch exists in the branch universe', () {
      final optionIds =
          service.allBranchOptions().map((option) => option.id).toSet();
      for (final branchId in TrainingProgramService.goalBranchIds.values) {
        expect(
          optionIds,
          contains(branchId),
          reason: '$branchId is not an offered branch option',
        );
      }
    });
  });

  group('TrainingRecommendationItem.isProgression', () {
    test('lane-built items carry their progression path', () {
      final recommendation = service.buildToday(progressMap: const {});

      expect(recommendation.items, isNotEmpty);
      for (final item in recommendation.items) {
        expect(
          item.isProgression,
          isTrue,
          reason: '${item.exercise.id} came from a skill-tree lane',
        );
        expect(item.progressionExerciseIds, contains(item.exercise.id));
      }
    });

    test('configured progression items carry their path, singles do not', () {
      final recommendation = service.buildToday(
        progressMap: const {},
        sessionItemsConfig: {
          'full_body': {
            'skill': [
              {
                'kind': 'progression',
                'skill_category_id': 'core',
                'branch_id': 'l_sit',
              },
            ],
            'strength': [
              {
                'kind': 'exercise',
                'exercise_id': 'push_up',
              },
              {
                'kind': 'exercise',
                'name': 'Farmer carry',
              },
            ],
          },
        },
      );

      expect(recommendation.items, hasLength(3));

      final progressionItem = recommendation.items.first;
      expect(progressionItem.isProgression, isTrue);
      expect(
        progressionItem.progressionExerciseIds,
        contains(progressionItem.exercise.id),
      );

      for (final standalone in recommendation.items.skip(1)) {
        expect(
          standalone.isProgression,
          isFalse,
          reason: '${standalone.exercise.id} is a standalone exercise',
        );
      }
    });

    test('configured progression picks the current exercise from the path',
        () {
      final recommendation = service.buildToday(
        progressMap: const {},
        sessionItemsConfig: {
          'full_body': {
            'skill': [
              {
                'kind': 'progression',
                'skill_category_id': 'core',
                'branch_id': 'l_sit',
              },
            ],
          },
        },
      );

      final item = recommendation.items.single;
      // No progress yet: the current exercise is the first in the path.
      expect(item.exercise.id, item.progressionExerciseIds.first);
      expect(item.status, ExerciseStatus.inactive);
    });
  });
}
