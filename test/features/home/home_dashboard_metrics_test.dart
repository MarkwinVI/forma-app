import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/models/workout_history_model.dart';
import 'package:forma_app/data/services/training_program_service.dart';
import 'package:forma_app/features/home/home_dashboard_metrics.dart';

void main() {
  group('HomeDashboardMetricsCalculator', () {
    test('active path options show each skill category at most once', () {
      final service = TrainingProgramService();
      final categoriesById = {
        for (final category in SkillCategoryCatalog.browsable())
          category.id: category,
      };

      // Default lanes put a core branch on both the skill-work lane
      // (l-sit) and the core lane (ab-wheel) — the tree must not show twice.
      final options = HomeDashboardMetricsCalculator.resolveActivePathOptions(
        trainingProgramService: service,
        programType: TrainingProgramType.fullBody,
        sessionItemsConfig: const {},
        branchSelections: service.defaultBranchSelections(),
        categoriesById: categoriesById,
      );

      final categoryIds =
          options.map((option) => option.sourceSkillCategoryId).toList();
      expect(categoryIds.length, categoryIds.toSet().length);
    });

    test('tree level is zero when a skill tree is untouched', () {
      final level = HomeDashboardMetricsCalculator.treeLevelForCategory(
        SkillCategoryCatalog.pullups,
        const {},
      );

      expect(level, 0);
    });

    test('tree level awards mastered steps and the current active step', () {
      final progressMap = {
        'scapular_pull': ExerciseStatus.mastered,
        'arch_hang': ExerciseStatus.mastered,
        'pull_up_negative': ExerciseStatus.active,
      };

      final level = HomeDashboardMetricsCalculator.treeLevelForCategory(
        SkillCategoryCatalog.pullups,
        progressMap,
      );
      final expected = SkillCategoryCatalog.pullups.trainingPaths.values
          .map(
            (path) =>
                HomeDashboardMetricsCalculator.branchScoreForExerciseIds(
                  path,
                  progressMap,
                ) *
                10,
          )
          .reduce((best, value) => value > best ? value : best);

      expect(level, closeTo(expected, 0.0001));
    });

    test('tree level uses the strongest branch in a multi-branch tree', () {
      final progressMap = {
        'scapular_pull': ExerciseStatus.mastered,
        'arch_hang': ExerciseStatus.mastered,
        'pull_up_negative': ExerciseStatus.mastered,
        'assisted_pull_up': ExerciseStatus.mastered,
        'pull_up': ExerciseStatus.mastered,
        'weighted_pull_up_115': ExerciseStatus.active,
      };

      final level = HomeDashboardMetricsCalculator.treeLevelForCategory(
        SkillCategoryCatalog.pullups,
        progressMap,
      );
      final expected = SkillCategoryCatalog.pullups.trainingPaths.values
          .map(
            (path) =>
                HomeDashboardMetricsCalculator.branchScoreForExerciseIds(
                  path,
                  progressMap,
                ) *
                10,
          )
          .reduce((best, value) => value > best ? value : best);

      expect(level, closeTo(expected, 0.0001));
    });

    test('journey snapshot includes untouched skill trees as zero', () {
      final service = TrainingProgramService();
      final snapshot = HomeDashboardMetricsCalculator.buildJourneySnapshotData(
        trainingProgramService: service,
        programType: TrainingProgramType.fullBody,
        branchSelections: service.defaultBranchSelections(),
        sessionItemsConfig: const {},
        progressMap: const {
          'scapular_pull': ExerciseStatus.active,
        },
        workouts: const [],
      );

      const expectedPullupsLevel = (0.6 / 12) * 10;
      final treeCount = SkillCategoryCatalog.browsable().length;
      final expectedAverage =
          double.parse((expectedPullupsLevel / treeCount).toStringAsFixed(1));

      expect(snapshot.totalSkillTrees, treeCount);
      expect(snapshot.unlockedSkillTrees, 1);
      expect(snapshot.averageSkillLevel, expectedAverage);
    });

    test('journey progress skills are ordered by closest to target volume', () {
      final service = TrainingProgramService();

      final snapshot = HomeDashboardMetricsCalculator.buildJourneySnapshotData(
        trainingProgramService: service,
        programType: TrainingProgramType.fullBody,
        branchSelections: service.defaultBranchSelections(),
        sessionItemsConfig: const {
          'full_body': {
            'skill': [
              {
                'id': 'skill-1',
                'kind': 'progression',
                'name': 'L-sit',
                'skill_category_id': 'core',
                'branch_id': 'l_sit',
              },
            ],
            'strength': [
              {
                'id': 'strength-1',
                'kind': 'progression',
                'name': 'Weighted Pull-up',
                'skill_category_id': 'pullups',
                'branch_id': 'weighted',
              },
            ],
          },
        },
        progressMap: const {},
        workouts: [
          _workout(
            'pull',
            'scapular_pull',
            [6, 6, 6],
            loggedAt: DateTime(2026, 6, 18),
          ),
          _workout(
            'core',
            'foot_supported_l_sit',
            [12, 12, 12],
            loggedAt: DateTime(2026, 6, 17),
            isTimed: true,
          ),
        ],
        now: DateTime(2026, 6, 20),
      );

      expect(snapshot.closestSkills, isNotEmpty);
      // The pull-up path (18 of 24 reps) is closer to its level-up volume
      // than the L-sit path (36 of 60 seconds), so it sorts first.
      expect(snapshot.closestSkills.first.skillCategoryId, 'pullups');

      final core = snapshot.closestSkills
          .firstWhere((skill) => skill.skillCategoryId == 'core');
      expect(core.motionLabel, 'Core');
      expect(core.skillTitle, 'L-Sit / V-Sit');
      // Level-up goal is the timed mastery volume: 3 sets × 20s.
      expect(core.targetLabel, '60s');
      expect(core.lastLabel, '36s');
    });

    test(
        'journey progress falls back to selected branches when the '
        'session-items config is empty (freshly set-up program)', () {
      final service = TrainingProgramService();

      final snapshot = HomeDashboardMetricsCalculator.buildJourneySnapshotData(
        trainingProgramService: service,
        programType: TrainingProgramType.fullBody,
        branchSelections: service.defaultBranchSelections(),
        sessionItemsConfig: const {},
        progressMap: const {},
        workouts: const [],
      );

      expect(snapshot.closestSkills, isNotEmpty);
    });

    test('active skill paths exclude non-browsable tracks like hinge', () {
      final service = TrainingProgramService();

      final rows = HomeDashboardMetricsCalculator.buildActiveSkillPathData(
        trainingProgramService: service,
        programType: TrainingProgramType.fullBody,
        branchSelections: service.defaultBranchSelections(),
        sessionItemsConfig: const {},
        progressMap: const {},
        progressEntries: const {},
        workouts: const [],
      );

      expect(rows.any((row) => row.track == TrainingTrack.hinge), isFalse);
      expect(
        rows.every(
          (row) => SkillCategoryCatalog.isBrowsableId(row.skillCategoryId),
        ),
        isTrue,
      );
    });

    test(
        'active skill paths only include progressions present in the training program',
        () {
      final service = TrainingProgramService();

      final rows = HomeDashboardMetricsCalculator.buildActiveSkillPathData(
        trainingProgramService: service,
        programType: TrainingProgramType.fullBody,
        branchSelections: service.defaultBranchSelections(),
        sessionItemsConfig: const {
          'full_body': {
            'skill': [
              {
                'id': 'skill-1',
                'kind': 'progression',
                'name': 'L-sit',
                'skill_category_id': 'core',
                'branch_id': 'l_sit',
              },
            ],
            'strength': [
              {
                'id': 'strength-1',
                'kind': 'progression',
                'name': 'Weighted Pull-up',
                'skill_category_id': 'pullups',
                'branch_id': 'weighted',
              },
              {
                'id': 'strength-2',
                'kind': 'exercise',
                'name': 'Romanian Deadlift',
                'exercise_id': 'single_leg_rdl',
              },
            ],
          },
        },
        progressMap: const {},
        progressEntries: const {},
        workouts: const [],
      );

      expect(rows.map((row) => row.skillCategoryId).toSet(), {
        'core',
        'pullups',
      });
      expect(
        rows.map((row) => '${row.skillCategoryId}:${row.branchId}').toSet(),
        {
          'core:l_sit',
          'pullups:weighted',
        },
      );
    });

    test(
        'active skill path momentum is improving when the last 14 days beat the previous 14',
        () {
      final service = TrainingProgramService();

      final rows = HomeDashboardMetricsCalculator.buildActiveSkillPathData(
        trainingProgramService: service,
        programType: TrainingProgramType.fullBody,
        branchSelections: service.defaultBranchSelections(),
        sessionItemsConfig: const {},
        progressMap: const {},
        progressEntries: const {},
        workouts: [
          _workout(
            'w1',
            'scapular_pull',
            [6],
            loggedAt: DateTime(2026, 6, 1),
          ),
          _workout(
            'w2',
            'scapular_pull',
            [8],
            loggedAt: DateTime(2026, 6, 15),
          ),
        ],
        now: DateTime(2026, 6, 19),
      );

      final verticalPull = rows.firstWhere(
        (row) => row.track == TrainingTrack.verticalPull,
      );
      expect(verticalPull.momentum, HomeSkillMomentum.improving);
      expect(verticalPull.personalBestLabel, 'Best 8 reps');
      expect(verticalPull.deltaLabel, '+2');
    });

    test(
        'active skill path momentum is stalled when the last 14 days trail the previous 14',
        () {
      final service = TrainingProgramService();

      final rows = HomeDashboardMetricsCalculator.buildActiveSkillPathData(
        trainingProgramService: service,
        programType: TrainingProgramType.fullBody,
        branchSelections: service.defaultBranchSelections(),
        sessionItemsConfig: const {},
        progressMap: const {},
        progressEntries: const {},
        workouts: [
          _workout(
            'w1',
            'scapular_pull',
            [8],
            loggedAt: DateTime(2026, 6, 1),
          ),
          _workout(
            'w2',
            'scapular_pull',
            [5],
            loggedAt: DateTime(2026, 6, 15),
          ),
        ],
        now: DateTime(2026, 6, 19),
      );

      final verticalPull = rows.firstWhere(
        (row) => row.track == TrainingTrack.verticalPull,
      );
      expect(verticalPull.momentum, HomeSkillMomentum.stalled);
      expect(verticalPull.personalBestLabel, 'Best 8 reps');
      expect(verticalPull.deltaLabel, '-3');
    });

    test('active skill path momentum is steady when both 14-day windows tie',
        () {
      final service = TrainingProgramService();

      final rows = HomeDashboardMetricsCalculator.buildActiveSkillPathData(
        trainingProgramService: service,
        programType: TrainingProgramType.fullBody,
        branchSelections: service.defaultBranchSelections(),
        sessionItemsConfig: const {},
        progressMap: const {},
        progressEntries: const {},
        workouts: [
          _workout(
            'w1',
            'scapular_pull',
            [6],
            loggedAt: DateTime(2026, 6, 1),
          ),
          _workout(
            'w2',
            'scapular_pull',
            [6],
            loggedAt: DateTime(2026, 6, 15),
          ),
        ],
        now: DateTime(2026, 6, 19),
      );

      final verticalPull = rows.firstWhere(
        (row) => row.track == TrainingTrack.verticalPull,
      );
      expect(verticalPull.momentum, HomeSkillMomentum.steady);
      expect(verticalPull.personalBestLabel, 'Best 6 reps');
      expect(verticalPull.deltaLabel, '0');
    });

    test('week strip resolves full body, push pull, and upper lower cycles',
        () {
      final service = TrainingProgramService();

      final fullBody = HomeDashboardMetricsCalculator.buildWeekStripData(
        cycle: service.scheduleCycleFor(
          programType: TrainingProgramType.fullBody,
          scheduleVariant: null,
        ),
        todayPosition: 2,
        completedToday: false,
        now: DateTime(2026, 6, 16),
      );
      final pushPull = HomeDashboardMetricsCalculator.buildWeekStripData(
        cycle: service.scheduleCycleFor(
          programType: TrainingProgramType.pushPull,
          scheduleVariant: null,
        ),
        todayPosition: 2,
        completedToday: false,
        now: DateTime(2026, 6, 16),
      );
      final upperLower = HomeDashboardMetricsCalculator.buildWeekStripData(
        cycle: service.scheduleCycleFor(
          programType: TrainingProgramType.upperLower,
          scheduleVariant: null,
        ),
        todayPosition: 2,
        completedToday: false,
        now: DateTime(2026, 6, 16),
      );

      expect(fullBody.days.length, 7);
      expect(pushPull.days[2].isCurrent, isTrue);
      expect(pushPull.days[2].sessionType, TrainingSessionType.pull);
      expect(upperLower.days[2].sessionType, TrainingSessionType.lower);
    });

    test('week strip marks today completed after a finished workout', () {
      final strip = HomeDashboardMetricsCalculator.buildWeekStripData(
        cycle: TrainingProgramService().scheduleCycleFor(
          programType: TrainingProgramType.pushPull,
          scheduleVariant: null,
        ),
        todayPosition: 0,
        completedToday: true,
        now: DateTime(2026, 6, 16),
      );

      expect(strip.days[0].isCurrent, isTrue);
      expect(strip.days[0].isCompleted, isTrue);
      expect(strip.completedSessions, 1);
    });
  });

  group('resolveSchedule', () {
    // Push/Pull cycle: [push, rest, pull, rest, push, pull, rest]
    final cycle = TrainingProgramService().scheduleCycleFor(
      programType: TrainingProgramType.pushPull,
      scheduleVariant: null,
    );

    test('marks today complete when the last workout finished today', () {
      // Workout done today; stored state already advanced to the rest step.
      final resolution = HomeDashboardMetricsCalculator.resolveSchedule(
        cycle: cycle,
        nextStepIndex: 1,
        nextSessionType: TrainingSessionType.rest,
        lastWorkoutAt: DateTime(2026, 6, 15, 18, 30),
        now: DateTime(2026, 6, 15, 21),
      );

      expect(resolution.completedToday, isTrue);
      expect(resolution.todayPosition, 0);
      expect(resolution.effectiveStepIndex, 1);
      expect(resolution.effectiveSessionType, TrainingSessionType.rest);
    });

    test('shows the rest day on the day after a completed workout', () {
      final resolution = HomeDashboardMetricsCalculator.resolveSchedule(
        cycle: cycle,
        nextStepIndex: 1,
        nextSessionType: TrainingSessionType.rest,
        lastWorkoutAt: DateTime(2026, 6, 15, 18, 30),
        now: DateTime(2026, 6, 16, 9),
      );

      expect(resolution.completedToday, isFalse);
      expect(resolution.todayPosition, 1);
      expect(resolution.effectiveSessionType, TrainingSessionType.rest);
    });

    test('rolls past an elapsed rest day to the next training day', () {
      final resolution = HomeDashboardMetricsCalculator.resolveSchedule(
        cycle: cycle,
        nextStepIndex: 1,
        nextSessionType: TrainingSessionType.rest,
        lastWorkoutAt: DateTime(2026, 6, 15, 18, 30),
        now: DateTime(2026, 6, 17, 9),
      );

      expect(resolution.completedToday, isFalse);
      expect(resolution.effectiveStepIndex, 2);
      expect(resolution.effectiveSessionType, TrainingSessionType.pull);
    });

    test('a missed training day stays current instead of rolling', () {
      // Pull was due two days ago but never done — it remains today's session.
      final resolution = HomeDashboardMetricsCalculator.resolveSchedule(
        cycle: cycle,
        nextStepIndex: 2,
        nextSessionType: TrainingSessionType.pull,
        lastWorkoutAt: DateTime(2026, 6, 13, 18, 30),
        now: DateTime(2026, 6, 17, 9),
      );

      expect(resolution.completedToday, isFalse);
      expect(resolution.effectiveSessionType, TrainingSessionType.pull);
      expect(resolution.todayPosition, 2);
    });

    test('rolls through consecutive rest days', () {
      // Full-body cycle ends with two rest days: [fb, r, fb, r, fb, r, r].
      final fullBodyCycle = TrainingProgramService().scheduleCycleFor(
        programType: TrainingProgramType.fullBody,
        scheduleVariant: null,
      );

      final resolution = HomeDashboardMetricsCalculator.resolveSchedule(
        cycle: fullBodyCycle,
        nextStepIndex: 5,
        nextSessionType: TrainingSessionType.rest,
        lastWorkoutAt: DateTime(2026, 6, 15, 18, 30),
        now: DateTime(2026, 6, 18, 9),
      );

      expect(resolution.effectiveStepIndex, 0);
      expect(resolution.effectiveSessionType, TrainingSessionType.fullBody);
    });

    test('without any workouts the stored step is shown as-is', () {
      final resolution = HomeDashboardMetricsCalculator.resolveSchedule(
        cycle: cycle,
        nextStepIndex: 0,
        nextSessionType: TrainingSessionType.push,
        lastWorkoutAt: null,
        now: DateTime(2026, 6, 17, 9),
      );

      expect(resolution.completedToday, isFalse);
      expect(resolution.effectiveSessionType, TrainingSessionType.push);
      expect(resolution.todayPosition, 0);
    });
  });
}

PastWorkout _workout(
  String id,
  String exerciseId,
  List<int> values, {
  required DateTime loggedAt,
  bool isTimed = false,
}) {
  return PastWorkout(
    id: id,
    title: 'Workout $id',
    sessionType: 'pull',
    startedAt: loggedAt,
    loggedAt: loggedAt,
    exercises: [
      PastWorkoutExercise(
        exerciseId: exerciseId,
        exerciseName: exerciseId,
        setCount: values.length,
        totalReps: isTimed ? 0 : values.fold(0, (sum, value) => sum + value),
        totalTimedSeconds:
            isTimed ? values.fold(0, (sum, value) => sum + value) : 0,
        sets: [
          for (var index = 0; index < values.length; index++)
            PastWorkoutSet(
              number: index + 1,
              value: values[index],
              isTimed: isTimed,
            ),
        ],
      ),
    ],
  );
}
