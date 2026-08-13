import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/skill_track_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/services/program_start_service.dart';
import 'package:forma_app/data/services/training_program_service.dart';

void main() {
  ProgramStartPlan planFor({
    bool hasGym = false,
    List<String> goals = const [],
    Map<String, int?> strength = const {},
    double? bodyweightKg = 80,
    Map<String, ExerciseStatus> progress = const {},
  }) {
    return ProgramStartPlanner.planFor(
      hasGym: hasGym,
      goalSkillIds: goals,
      startingStrength: strength,
      bodyweightKg: bodyweightKg,
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
        SkillCategoryCatalog.hingeId: 'nordic_curls',
        SkillCategoryCatalog.coreId: 'l_sit',
      });
    });

    test('with a gym: the weighted squat branch and the Romanian deadlift',
        () {
      final tracks = planFor(hasGym: true).tracks;

      expect(tracks[SkillCategoryCatalog.squatId], 'weighted');
      expect(tracks.containsKey(SkillCategoryCatalog.barbellSquatId), isFalse);
      expect(tracks[SkillCategoryCatalog.hingeId], 'weighted');
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

    test('a step placement mastered unlocks a gated goal', () {
      final tracks = planFor(
        goals: ['hspu'],
        progress: {'pushups_diamond_push_up': ExerciseStatus.mastered},
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

    test('everything behind the starting node is mastered', () {
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
        everyElement(ExerciseStatus.mastered),
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

    test('the weighted squat starts on the deepest rung inside 80% of the '
        'reported max', () {
      // 80% of a 100 kg max is 80 kg; at 80 kg bodyweight the +100% rung
      // asks for exactly that, and the +125% rung is past it.
      final plan = planFor(
        hasGym: true,
        strength: {'squat': 100},
        bodyweightKg: 80,
      );

      expect(plan.statuses['squat_barbell_plus_100'], ExerciseStatus.active);
      expect(
        [
          for (final id in const [
            'squat_assisted_squat',
            'squat_deep_assisted_squat',
            'squat_squat',
            'squat_deep_squat',
            'squat_barbell_squat',
            'squat_barbell_plus_25',
            'squat_barbell_plus_50',
            'squat_barbell_plus_75',
          ])
            plan.statuses[id],
        ],
        everyElement(ExerciseStatus.mastered),
      );
      expect(plan.statuses.containsKey('squat_barbell_plus_125'), isFalse);
    });

    test('a max between two rungs rounds down to the lighter one', () {
      // 80% of 90 kg is 72 kg: past the +75% rung's 60 kg, short of the
      // +100% rung's 80 kg.
      final plan = planFor(
        hasGym: true,
        strength: {'squat': 90},
        bodyweightKg: 80,
      );

      expect(plan.statuses['squat_barbell_plus_75'], ExerciseStatus.active);
    });

    test('a blank squat answer starts on the empty bar', () {
      final plan = planFor(hasGym: true);

      expect(plan.statuses['squat_barbell_squat'], ExerciseStatus.active);
      expect(plan.statuses['squat_deep_squat'], ExerciseStatus.mastered);
    });

    test('without a bodyweight the rung loads cannot resolve — the bar again',
        () {
      final plan = planFor(
        hasGym: true,
        strength: {'squat': 200},
        bodyweightKg: null,
      );

      expect(plan.statuses['squat_barbell_squat'], ExerciseStatus.active);
    });

    test('the weighted hinge places its rung from 80% of the RDL max', () {
      // 80% of a 100 kg max is 80 kg — the +100% bodyweight rung exactly.
      final plan = planFor(
        hasGym: true,
        strength: {'rdl': 100},
        bodyweightKg: 80,
      );

      expect(plan.statuses['hinge_rdl_100_bw'], ExerciseStatus.active);
      expect(
        [
          for (final id in const [
            'hinge_romanian_deadlift_bodyweight',
            'hinge_romanian_deadlift_barbell',
            'hinge_rdl_25_bw',
            'hinge_rdl_50_bw',
            'hinge_rdl_75_bw',
          ])
            plan.statuses[id],
        ],
        everyElement(ExerciseStatus.mastered),
      );
      expect(plan.statuses.containsKey('hinge_rdl_125_bw'), isFalse);
    });

    test('a blank RDL answer starts the hinge on its first step', () {
      final plan = planFor(hasGym: true);

      expect(
        plan.statuses['hinge_romanian_deadlift_bodyweight'],
        ExerciseStatus.active,
      );
      expect(
        plan.statuses.containsKey('hinge_romanian_deadlift_barbell'),
        isFalse,
      );
    });

    test('without a gym the hinge runs the Nordic curls from the start', () {
      final plan = planFor();

      expect(
        plan.statuses['hinge_romanian_deadlift_bodyweight'],
        ExerciseStatus.active,
      );
      expect(plan.tracks[SkillCategoryCatalog.hingeId], 'nordic_curls');
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
          'squat_barbell_squat',
          'hinge_romanian_deadlift_bodyweight',
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
          'squat_barbell_squat',
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
          'hinge_romanian_deadlift_bodyweight',
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
          'squat_barbell_squat',
          'hinge_romanian_deadlift_bodyweight',
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
          'hinge_romanian_deadlift_bodyweight',
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
          'hinge_romanian_deadlift_bodyweight',
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

  group('the rows applyPlan writes', () {
    test('status and target arrive joined, as one position per exercise', () {
      // The planner itself no longer sets opening targets — every rung's
      // load comes from its own formula — but the write path still has to
      // join a status with a target when a plan carries both.
      const plan = ProgramStartPlan(
        tracks: {},
        statuses: {
          'hinge_romanian_deadlift_barbell': ExerciseStatus.active,
          'hinge_romanian_deadlift_bodyweight': ExerciseStatus.mastered,
        },
        targets: {
          'hinge_romanian_deadlift_barbell':
              ProgramStartTarget(sets: 3, value: 5, weightKg: 60),
        },
      );

      final positions = ProgramStartService.startingPositionsFor(
        plan,
        existing: const {},
      );

      final rdl = positions['hinge_romanian_deadlift_barbell']!;
      expect(rdl.status, ExerciseStatus.active);
      expect(rdl.targetSets, 3);
      expect(rdl.targetValue, 5);
      expect(rdl.targetWeightKg, 60);

      // A step with no special opening target still carries its status —
      // null target means the standard ladder target.
      final behind = positions['hinge_romanian_deadlift_bodyweight']!;
      expect(behind.status, ExerciseStatus.mastered);
      expect(behind.targetSets, isNull);
    });

    test('a weighted rung placed by setup has no special opening target — '
        'its load comes from the rung formula', () {
      final plan = ProgramStartPlanner.planFor(
        hasGym: true,
        goalSkillIds: const [],
        startingStrength: const {'squat': 100, 'rdl': 100},
        bodyweightKg: 80,
      );

      expect(plan.targets, isEmpty);

      final positions = ProgramStartService.startingPositionsFor(
        plan,
        existing: const {},
      );
      final squat = positions['squat_barbell_plus_100']!;
      expect(squat.status, ExerciseStatus.active);
      expect(squat.targetSets, isNull);
      expect(squat.targetWeightKg, isNull);
    });

    test('an exercise the user already has a row for is left alone', () {
      final plan = ProgramStartPlanner.planFor(
        hasGym: true,
        goalSkillIds: const [],
        startingStrength: const {'squat': 100},
        bodyweightKg: 80,
      );

      final positions = ProgramStartService.startingPositionsFor(
        plan,
        existing: {'squat_barbell_plus_100'},
      );

      expect(positions.containsKey('squat_barbell_plus_100'), isFalse);
      expect(positions, isNotEmpty, reason: 'the rest is still written');
    });
  });
}
