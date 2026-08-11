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
    Map<String, ExerciseStatus> progress = const {},
  }) {
    return ProgramStartPlanner.planFor(
      hasGym: hasGym,
      goalSkillIds: goals,
      startingStrength: strength,
      existingProgress: progress,
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
    test('without a gym: upper trees, squat, Nordic curls, and core', () {
      expect(planFor().tracks, {
        SkillCategoryCatalog.pushupsId: 'planche',
        SkillCategoryCatalog.dipsId: 'weighted',
        SkillCategoryCatalog.rowsId: 'front_lever',
        SkillCategoryCatalog.pullupsId: 'weighted',
        SkillCategoryCatalog.squatId: 'pistol',
        SkillCategoryCatalog.hingeId: 'nordic',
        SkillCategoryCatalog.coreId: 'l_sit',
      });
    });

    test('with a gym: the barbell squat and the Romanian deadlift', () {
      final tracks = planFor(hasGym: true).tracks;

      expect(tracks[SkillCategoryCatalog.barbellSquatId], 'main');
      expect(tracks.containsKey(SkillCategoryCatalog.squatId), isFalse);
      expect(tracks[SkillCategoryCatalog.hingeId], 'rdl');
      expect(tracks[SkillCategoryCatalog.coreId], 'l_sit');
    });

    test('a squat goal takes the knee-dominant slot back from the barbell', () {
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
      final tracks = planFor(
        goals: ['lsit', 'hspu'],
        progress: {'pushups_diamond_push_up': ExerciseStatus.mastered},
      ).tracks;

      expect(tracks[SkillCategoryCatalog.coreId], 'l_sit');
      expect(tracks[SkillCategoryCatalog.handstandPushupsId], 'main');
    });

    test('a gated goal is dropped while its tree is still locked', () {
      final tracks = planFor(goals: ['hspu']).tracks;

      expect(
        tracks.containsKey(SkillCategoryCatalog.handstandPushupsId),
        isFalse,
      );
    });

    test('a step skipped at setup unlocks a gated goal like mastery does', () {
      final tracks = planFor(
        goals: ['hspu'],
        progress: {'pushups_diamond_push_up': ExerciseStatus.skipped},
      ).tracks;

      expect(tracks[SkillCategoryCatalog.handstandPushupsId], 'main');
    });

    test('core is included even when no goal asks for it', () {
      expect(planFor().tracks[SkillCategoryCatalog.coreId], 'l_sit');
    });
  });

  group('where the program starts', () {
    test('no reps starts at the beginner node', () {
      final plan = planFor(strength: {'pushups': 0});

      expect(plan.statuses['pushups_wall_push_up'], ExerciseStatus.active);
      expect(plan.statuses.containsKey('pushups_incline_push_up'), isFalse);
    });

    test('an unknown answer also starts at the beginner node', () {
      final plan = planFor(strength: {'pushups': null});

      expect(plan.statuses['pushups_wall_push_up'], ExerciseStatus.active);
    });

    test('1–9 reps start two steps before the exercise they answer for', () {
      final plan = planFor(
        strength: {'pushups': 5, 'pullups': 3, 'dips': 1, 'squat_bw': 9},
      );

      expect(plan.statuses['pullups_pull_up_negative'], ExerciseStatus.active);
      // Dips have two steps before the parallel-bar dip, so two back is the
      // first one.
      expect(plan.statuses['dips_bench_dips'], ExerciseStatus.active);
      // Push-ups and squats have exactly two steps of run-up, so the step
      // back clamps onto the beginner node.
      expect(plan.statuses['pushups_wall_push_up'], ExerciseStatus.active);
      expect(plan.statuses['squat_assisted_squat'], ExerciseStatus.active);
    });

    test('10+ reps start on the exercise the answer was about', () {
      final plan = planFor(
        strength: {'pushups': 12, 'pullups': 10, 'dips': 30, 'squat_bw': 40},
      );

      expect(plan.statuses['pushups_push_up'], ExerciseStatus.active);
      expect(plan.statuses['pullups_pull_up'], ExerciseStatus.active);
      expect(plan.statuses['dips_parallel_bar_dips'], ExerciseStatus.active);
      expect(plan.statuses['squat_squat'], ExerciseStatus.active);
    });

    test('everything behind the starting node is skipped, never mastered', () {
      final plan = planFor(strength: {'pushups': 12, 'pullups': 10});

      expect(
        [
          for (final id in const [
            'pushups_wall_push_up',
            'pushups_incline_push_up',
            'pullups_scapular_pull',
            'pullups_pull_up_negative',
            'pullups_assisted_pull_up',
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

      expect(plan.statuses['rows_vertical_rows'], ExerciseStatus.active);
      expect(
        plan.statuses.keys.where((id) => id.contains('rows')).length,
        1,
      );
    });

    test('the barbell squat opens at 3 × 5 on the reported 5-rep weight', () {
      final plan = planFor(hasGym: true, strength: {'squat': 100});
      final target = plan.targets['barbell_squat_barbell_squat']!;

      expect(target.sets, 3);
      expect(target.value, 5);
      expect(target.weightKg, 100);
    });

    test('the opening barbell weight is rounded to a loadable 2.5 kg', () {
      expect(ProgramStartPlanner.barbellSquatStartKg(104), 102.5);
      expect(ProgramStartPlanner.barbellSquatStartKg(1), 2.5);
      expect(ProgramStartPlanner.barbellSquatStartKg(null), isNull);
    });

    test('the Romanian deadlift opens light and the Nordic curl at 3 × 5', () {
      final rdl = planFor(hasGym: true).targets['hinge_romanian_deadlift']!;
      expect(
        (rdl.sets, rdl.value, rdl.weightKg),
        (3, 5, ProgramStartPlanner.romanianDeadliftStartKg),
      );

      final nordic = planFor().targets['hinge_nordic_nordic_curl']!;
      expect((nordic.sets, nordic.value, nordic.weightKg), (3, 5, null));
    });
  });

  group('the sessions a planned program builds', () {
    final service = TrainingProgramService();

    List<String> exerciseIdsOf({
      required ProgramStartPlan plan,
      required TrainingProgramType programType,
      required TrainingSessionType sessionType,
      required bool hasGym,
    }) {
      return service
          .buildToday(
            progressMap: plan.statuses,
            programType: programType,
            sessionType: sessionType,
            skillTracks: tracksOf(plan),
            hasGym: hasGym,
          )
          .items
          .map((item) => item.exercise.id)
          .toList();
    }

    test('full body alternates pull and push, then legs, hinge, and core', () {
      final plan = planFor(hasGym: true);
      expect(
        exerciseIdsOf(
          plan: plan,
          programType: TrainingProgramType.fullBody,
          sessionType: TrainingSessionType.fullBody,
          hasGym: true,
        ),
        [
          'pullups_scapular_pull',
          'dips_bench_dips',
          'rows_vertical_rows',
          'pushups_wall_push_up',
          'barbell_squat_barbell_squat',
          'hinge_romanian_deadlift',
          'core_foot_supported_l_sit',
        ],
      );
    });

    test('gym push and pull days include their accessories in final position',
        () {
      final plan = planFor(hasGym: true);

      expect(
        exerciseIdsOf(
          plan: plan,
          programType: TrainingProgramType.pushPull,
          sessionType: TrainingSessionType.push,
          hasGym: true,
        ),
        [
          'dips_bench_dips',
          'pushups_wall_push_up',
          'barbell_squat_barbell_squat',
          'core_foot_supported_l_sit',
          'lateral_raise_dumbbell',
        ],
      );
      expect(
        exerciseIdsOf(
          plan: plan,
          programType: TrainingProgramType.pushPull,
          sessionType: TrainingSessionType.pull,
          hasGym: true,
        ),
        [
          'pullups_scapular_pull',
          'rows_vertical_rows',
          'hinge_romanian_deadlift',
          'face_pull',
        ],
      );
    });

    test('upper alternates push and pull; lower ends with core and calves', () {
      final plan = planFor(hasGym: true);

      expect(
        exerciseIdsOf(
          plan: plan,
          programType: TrainingProgramType.upperLower,
          sessionType: TrainingSessionType.upper,
          hasGym: true,
        ),
        [
          'dips_bench_dips',
          'pullups_scapular_pull',
          'pushups_wall_push_up',
          'rows_vertical_rows',
        ],
      );
      expect(
        exerciseIdsOf(
          plan: plan,
          programType: TrainingProgramType.upperLower,
          sessionType: TrainingSessionType.lower,
          hasGym: true,
        ),
        [
          'barbell_squat_barbell_squat',
          'hinge_romanian_deadlift',
          'core_foot_supported_l_sit',
          'standing_calf_raise',
        ],
      );
    });

    test('no-gym sessions omit accessories', () {
      final plan = planFor();

      expect(
        exerciseIdsOf(
          plan: plan,
          programType: TrainingProgramType.pushPull,
          sessionType: TrainingSessionType.push,
          hasGym: false,
        ),
        [
          'dips_bench_dips',
          'pushups_wall_push_up',
          'squat_assisted_squat',
          'core_foot_supported_l_sit',
        ],
      );
      expect(
        exerciseIdsOf(
          plan: plan,
          programType: TrainingProgramType.pushPull,
          sessionType: TrainingSessionType.pull,
          hasGym: false,
        ),
        [
          'pullups_scapular_pull',
          'rows_vertical_rows',
          'hinge_nordic_nordic_curl',
        ],
      );
      expect(
        exerciseIdsOf(
          plan: plan,
          programType: TrainingProgramType.upperLower,
          sessionType: TrainingSessionType.lower,
          hasGym: false,
        ),
        [
          'squat_assisted_squat',
          'hinge_nordic_nordic_curl',
          'core_foot_supported_l_sit',
        ],
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
            hasGym: false,
          )
          .items
          .map((item) => item.exercise.id)
          .toList();

      expect(items, contains('pushups_push_up'));
      expect(items, contains('pullups_pull_up_negative'));
      expect(items, isNot(contains('pushups_wall_push_up')));
    });
  });

  group('a skipped step is cleared, not claimed', () {
    test('logging the mastery target masters it for real', () {
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(
            exercise: ExerciseCatalog.findById('pushups_push_up')!,
            volume: 24, // 3 × 8, the default mastery target.
          ),
        ],
        progressRows: {
          'pushups_push_up': ExerciseProgress(
            exerciseId: 'pushups_push_up',
            status: ExerciseStatus.skipped,
            updatedAt: DateTime(2026, 7, 28),
          ),
        },
      );

      expect(outcome.statusChanges['pushups_push_up'], ExerciseStatus.mastered);
    });

    test('falling short of the target leaves it skipped', () {
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(
            exercise: ExerciseCatalog.findById('pushups_push_up')!,
            volume: 9,
          ),
        ],
        progressRows: {
          'pushups_push_up': ExerciseProgress(
            exerciseId: 'pushups_push_up',
            status: ExerciseStatus.skipped,
            updatedAt: DateTime(2026, 7, 28),
          ),
        },
      );

      expect(outcome.statusChanges, isEmpty);
    });
  });

  group('the rows applyPlan writes', () {
    test('status and target arrive joined, as one position per exercise', () {
      final plan = ProgramStartPlanner.planFor(
        hasGym: true,
        goalSkillIds: const [],
        // Ten push-ups: starts on the push-up itself, skipping the steps
        // behind it — so the plan carries both targets and skipped statuses.
        startingStrength: const {'squat': 100, 'pushups': 10},
      );

      final positions = ProgramStartService.startingPositionsFor(
        plan,
        existing: const {},
      );

      final squat = positions['barbell_squat_barbell_squat']!;
      expect(squat.status, ExerciseStatus.active);
      expect(squat.targetSets, ProgramStartPlanner.loadedLiftSets);
      expect(squat.targetValue, ProgramStartPlanner.loadedLiftStartReps);
      expect(squat.targetWeightKg, 100);

      // A step with no special opening target still carries its status —
      // null target means the standard ladder target.
      final skipped = positions.entries
          .firstWhere((entry) => entry.value.status == ExerciseStatus.skipped);
      expect(skipped.value.targetSets, isNull);
    });

    test('an exercise the user already has a row for is left alone', () {
      final plan = ProgramStartPlanner.planFor(
        hasGym: true,
        goalSkillIds: const [],
        startingStrength: const {'squat': 100},
      );

      final positions = ProgramStartService.startingPositionsFor(
        plan,
        existing: {'barbell_squat_barbell_squat'},
      );

      expect(positions.containsKey('barbell_squat_barbell_squat'), isFalse);
      expect(positions, isNotEmpty, reason: 'the rest is still written');
    });
  });
}
