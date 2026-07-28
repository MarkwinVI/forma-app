import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/exercise_progress_model.dart';
import 'package:forma_app/data/models/skill_track_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/services/exercise_progression_service.dart';
import 'package:forma_app/data/services/program_start_service.dart';
import 'package:forma_app/data/services/training_program_service.dart';

void main() {
  ProgramStartPlan planFor({
    bool hasGym = false,
    List<String> goals = const [],
    Map<String, int?> strength = const {},
  }) {
    return ProgramStartPlanner.planFor(
      hasGym: hasGym,
      goalSkillIds: goals,
      startingStrength: strength,
    );
  }

  List<SkillTrack> tracksOf(ProgramStartPlan plan) => [
        for (final entry in plan.tracks.entries)
          SkillTrack(
            skillCategoryId: entry.key,
            branchId: entry.value,
            included: true,
            updatedAt: DateTime(2026, 7, 28),
          ),
      ];

  group('what a new program trains', () {
    test('without a gym: four upper trees, the squat tree and Nordic curls',
        () {
      expect(planFor().tracks, {
        SkillCategoryCatalog.pushupsId: 'planche',
        SkillCategoryCatalog.dipsId: 'weighted',
        SkillCategoryCatalog.rowsId: 'front_lever',
        SkillCategoryCatalog.pullupsId: 'weighted',
        SkillCategoryCatalog.squatId: 'pistol',
        SkillCategoryCatalog.hingeId: 'nordic',
      });
    });

    test('with a gym: the barbell squat and the Romanian deadlift', () {
      final tracks = planFor(hasGym: true).tracks;

      expect(tracks[SkillCategoryCatalog.barbellSquatId], 'main');
      expect(tracks.containsKey(SkillCategoryCatalog.squatId), isFalse);
      expect(tracks[SkillCategoryCatalog.hingeId], 'rdl');
    });

    test('a squat goal takes the knee-dominant slot back from the barbell',
        () {
      final tracks = planFor(hasGym: true, goals: ['pistol']).tracks;

      expect(tracks[SkillCategoryCatalog.squatId], 'pistol');
      expect(tracks.containsKey(SkillCategoryCatalog.barbellSquatId), isFalse);
    });

    test('a goal replaces the default branch of its own tree', () {
      final tracks = planFor(goals: ['oapu', 'oarow']).tracks;

      expect(tracks[SkillCategoryCatalog.pushupsId], 'one_arm');
      expect(tracks[SkillCategoryCatalog.rowsId], 'one_arm');
    });

    test('a goal for a movement the six do not cover adds its own track', () {
      final tracks = planFor(goals: ['lsit', 'hspu']).tracks;

      expect(tracks[SkillCategoryCatalog.coreId], 'l_sit');
      expect(tracks[SkillCategoryCatalog.handstandPushupsId], 'main');
    });

    test('no core track unless a goal asks for one', () {
      expect(planFor().tracks.containsKey(SkillCategoryCatalog.coreId), isFalse);
    });
  });

  group('where the program starts', () {
    test('no reps starts at the beginner node', () {
      final plan = planFor(strength: {'pushups': 0});

      expect(plan.statuses['wall_push_up'], ExerciseStatus.active);
      expect(plan.statuses.containsKey('incline_push_up'), isFalse);
    });

    test('an unknown answer also starts at the beginner node', () {
      final plan = planFor(strength: {'pushups': null});

      expect(plan.statuses['wall_push_up'], ExerciseStatus.active);
    });

    test('1–9 reps start two steps before the last foundation step', () {
      final plan = planFor(
        strength: {'pushups': 5, 'pullups': 3, 'dips': 1, 'squat_bw': 9},
      );

      expect(plan.statuses['elbows_in_push_up'], ExerciseStatus.active);
      expect(plan.statuses['pull_up_negative'], ExerciseStatus.active);
      // Dips have a three-step foundation, so two steps back is the first.
      expect(plan.statuses['bench_dips'], ExerciseStatus.active);
      expect(plan.statuses['squat'], ExerciseStatus.active);
    });

    test('10+ reps start on the last foundation step', () {
      final plan = planFor(
        strength: {'pushups': 12, 'pullups': 10, 'dips': 30, 'squat_bw': 40},
      );

      expect(plan.statuses['diamond_push_up'], ExerciseStatus.active);
      expect(plan.statuses['pull_up'], ExerciseStatus.active);
      expect(plan.statuses['parallel_bar_dips'], ExerciseStatus.active);
      expect(plan.statuses['bulgarian_split_squat'], ExerciseStatus.active);
    });

    test('everything behind the starting node is skipped, never mastered', () {
      final plan = planFor(strength: {'pushups': 12});

      expect(
        [
          for (final id in const [
            'wall_push_up',
            'incline_push_up',
            'push_up',
            'elbows_in_push_up',
            'decline_push_up',
          ])
            plan.statuses[id],
        ],
        everyElement(ExerciseStatus.skipped),
      );
      expect(
        plan.statuses.values.contains(ExerciseStatus.mastered),
        isFalse,
      );
    });

    test('rows always start at the first step', () {
      final plan = planFor(strength: {'pushups': 30, 'pullups': 20});

      expect(plan.statuses['vertical_rows'], ExerciseStatus.active);
      expect(
        plan.statuses.keys.where((id) => id.contains('rows')).length,
        1,
      );
    });

    test('the barbell squat opens at 3 × 5 on 70% of the reported 1RM', () {
      final plan = planFor(hasGym: true, strength: {'squat': 100});
      final target = plan.targets['barbell_squat']!;

      expect(target.sets, 3);
      expect(target.value, 5);
      expect(target.weightKg, 70);
    });

    test('the opening barbell weight is rounded to a loadable 2.5 kg', () {
      expect(ProgramStartPlanner.barbellSquatStartKg(105), 72.5);
      expect(ProgramStartPlanner.barbellSquatStartKg(1), 2.5);
      expect(ProgramStartPlanner.barbellSquatStartKg(null), isNull);
    });

    test('the Romanian deadlift opens light and the Nordic curl at 3 × 5', () {
      expect(
        planFor(hasGym: true).targets['romanian_deadlift']!.weightKg,
        ProgramStartPlanner.romanianDeadliftStartKg,
      );

      final nordic = planFor().targets['nordic_curl']!;
      expect((nordic.sets, nordic.value, nordic.weightKg), (3, 5, null));
    });
  });

  group('the sessions a planned program builds', () {
    final service = TrainingProgramService();

    Set<String> categoriesOf({
      required ProgramStartPlan plan,
      required TrainingProgramType programType,
      required TrainingSessionType sessionType,
    }) {
      return service
          .buildToday(
            progressMap: plan.statuses,
            programType: programType,
            sessionType: sessionType,
            skillTracks: tracksOf(plan),
          )
          .items
          .map((item) => item.sourceSkillCategoryId)
          .toSet();
    }

    test('full body trains all six movements', () {
      expect(
        categoriesOf(
          plan: planFor(hasGym: true),
          programType: TrainingProgramType.fullBody,
          sessionType: TrainingSessionType.fullBody,
        ),
        {
          SkillCategoryCatalog.pushupsId,
          SkillCategoryCatalog.dipsId,
          SkillCategoryCatalog.rowsId,
          SkillCategoryCatalog.pullupsId,
          SkillCategoryCatalog.barbellSquatId,
          SkillCategoryCatalog.hingeId,
        },
      );
    });

    test('push days press and squat, pull days pull and hinge', () {
      final plan = planFor();

      expect(
        categoriesOf(
          plan: plan,
          programType: TrainingProgramType.pushPull,
          sessionType: TrainingSessionType.push,
        ),
        {
          SkillCategoryCatalog.pushupsId,
          SkillCategoryCatalog.dipsId,
          SkillCategoryCatalog.squatId,
        },
      );
      expect(
        categoriesOf(
          plan: plan,
          programType: TrainingProgramType.pushPull,
          sessionType: TrainingSessionType.pull,
        ),
        {
          SkillCategoryCatalog.rowsId,
          SkillCategoryCatalog.pullupsId,
          SkillCategoryCatalog.hingeId,
        },
      );
    });

    test('upper days take the four upper trees, lower days the two legs', () {
      final plan = planFor(hasGym: true);

      expect(
        categoriesOf(
          plan: plan,
          programType: TrainingProgramType.upperLower,
          sessionType: TrainingSessionType.upper,
        ),
        {
          SkillCategoryCatalog.pushupsId,
          SkillCategoryCatalog.dipsId,
          SkillCategoryCatalog.rowsId,
          SkillCategoryCatalog.pullupsId,
        },
      );
      expect(
        categoriesOf(
          plan: plan,
          programType: TrainingProgramType.upperLower,
          sessionType: TrainingSessionType.lower,
        ),
        {
          SkillCategoryCatalog.barbellSquatId,
          SkillCategoryCatalog.hingeId,
        },
      );
    });

    test('sessions open on the starting node the answers placed', () {
      final plan = planFor(strength: {'pushups': 12, 'pullups': 3});
      final items = service
          .buildToday(
            progressMap: plan.statuses,
            programType: TrainingProgramType.fullBody,
            sessionType: TrainingSessionType.fullBody,
            skillTracks: tracksOf(plan),
          )
          .items
          .map((item) => item.exercise.id)
          .toList();

      expect(items, contains('diamond_push_up'));
      expect(items, contains('pull_up_negative'));
      expect(items, isNot(contains('wall_push_up')));
    });
  });

  group('a skipped step is cleared, not claimed', () {
    test('logging the mastery target masters it for real', () {
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(
            exercise: ExerciseCatalog.findById('push_up')!,
            volume: 24, // 3 × 8, the default mastery target.
          ),
        ],
        progressRows: {
          'push_up': ExerciseProgress(
            exerciseId: 'push_up',
            status: ExerciseStatus.skipped,
            updatedAt: DateTime(2026, 7, 28),
          ),
        },
      );

      expect(outcome.statusChanges['push_up'], ExerciseStatus.mastered);
    });

    test('falling short of the target leaves it skipped', () {
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(
            exercise: ExerciseCatalog.findById('push_up')!,
            volume: 9,
          ),
        ],
        progressRows: {
          'push_up': ExerciseProgress(
            exerciseId: 'push_up',
            status: ExerciseStatus.skipped,
            updatedAt: DateTime(2026, 7, 28),
          ),
        },
      );

      expect(outcome.statusChanges, isEmpty);
    });
  });
}
