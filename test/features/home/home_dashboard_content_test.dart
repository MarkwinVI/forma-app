import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/home_dashboard_content.dart';
import 'package:forma_app/features/home/home_dashboard_metrics.dart';
import 'package:forma_app/features/home/alternate_workout_options_view.dart';
import 'package:forma_app/features/home/journey_skill_detail_view.dart';
import 'package:forma_app/features/home/live_workout_view.dart';
import 'package:forma_app/features/home/program_overview_view.dart';
import 'package:forma_app/features/home/program_workout_editor_view.dart';
import 'package:forma_app/features/settings/settings_view.dart';
import 'package:forma_app/features/skills/skill_tree_view.dart';
import 'package:forma_app/data/services/training_program_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZSI6ImFub24iLCJpYXQiOjE1MTYyMzkwMjJ9.c2lnbmVk',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders home sections in the new order', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeDashboardContent(
            todaySummary: _todaySummary(),
            streak: _streakData(),
            programLabel: 'Push / Pull · 3-day split',
            journeySnapshot: _journeySnapshot(),
            activeSkillPaths: [_activeSkillPath()],
            exercisePerformance: const [],
            goalSkills: const [],
            nodesClearedThisMonth: 0,
            onViewExercises: () {},
            onEditGoals: () {},
            onOpenGoalSkill: (_) {},
            onPrimaryAction: () {},
            onSecondaryAction: () {},
            onOpenSettings: () {},
            onOpenProgramSettings: () {},
            onOpenJourneySkill: (_) {},
            onOpenSkillPath: (_) {},
          ),
        ),
      ),
    );

    final streak = tester.getTopLeft(find.text('2-week streak'));
    final hero = tester.getTopLeft(find.text('Pull Day'));
    final programRow = tester.getTopLeft(find.text('Your program'));
    final progress = tester.getTopLeft(find.text('Your skill trees'));
    expect(find.text('THIS WEEK'), findsNothing);
    expect(find.text('JOURNEY SNAPSHOT'), findsNothing);
    expect(find.text('SKILL PATHS'), findsNothing);
    expect(find.textContaining('sessions done'), findsNothing);
    // The v3 dashboard drops the week calendar in favour of the streak strip.
    expect(find.text('Rest'), findsNothing);
    expect(find.text('UP NEXT · TODAY'), findsOneWidget);
    expect(streak.dy, lessThan(hero.dy));
    expect(hero.dy, lessThan(programRow.dy));
    expect(programRow.dy, lessThan(progress.dy));
  });

  testWidgets('start workout CTA can open LiveWorkoutView', (tester) async {
    final recommendation = _recommendation();
    Widget? destination;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: destination ??
                  HomeDashboardContent(
                    todaySummary: _todaySummary(),
                    streak: _streakData(),
                    programLabel: 'Push / Pull · 3-day split',
                    journeySnapshot: _journeySnapshot(),
                    activeSkillPaths: [_activeSkillPath()],
                    exercisePerformance: const [],
                    goalSkills: const [],
                    nodesClearedThisMonth: 0,
                    onViewExercises: () {},
                    onEditGoals: () {},
                    onOpenGoalSkill: (_) {},
                    onPrimaryAction: () {
                      setState(
                        () => destination = LiveWorkoutView(
                          recommendation: recommendation,
                        ),
                      );
                    },
                    onSecondaryAction: () {},
                    onOpenSettings: () {},
                    onOpenProgramSettings: () {},
                    onOpenJourneySkill: (_) {},
                    onOpenSkillPath: (_) {},
                  ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(find.byType(LiveWorkoutView), findsOneWidget);
  });

  testWidgets('secondary CTA can open alternate workout options',
      (tester) async {
    Widget? destination;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: destination ??
                  HomeDashboardContent(
                    todaySummary: _todaySummary(),
                    streak: _streakData(),
                    programLabel: 'Push / Pull · 3-day split',
                    journeySnapshot: _journeySnapshot(),
                    activeSkillPaths: [_activeSkillPath()],
                    exercisePerformance: const [],
                    goalSkills: const [],
                    nodesClearedThisMonth: 0,
                    onViewExercises: () {},
                    onEditGoals: () {},
                    onOpenGoalSkill: (_) {},
                    onPrimaryAction: () {},
                    onSecondaryAction: () {
                      setState(
                        () => destination = AlternateWorkoutOptionsView(
                          onOpenBlankWorkout: () {},
                        ),
                      );
                    },
                    onOpenSettings: () {},
                    onOpenProgramSettings: () {},
                    onOpenJourneySkill: (_) {},
                    onOpenSkillPath: (_) {},
                  ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Train something else'));
    await tester.pump();

    expect(find.byType(AlternateWorkoutOptionsView), findsOneWidget);
  });

  testWidgets('workout card shows meta line and action rows', (tester) async {
    var viewedExercises = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeDashboardContent(
            todaySummary: _todaySummary(),
            streak: _streakData(),
            programLabel: 'Push / Pull · 3-day split',
            journeySnapshot: _journeySnapshot(),
            activeSkillPaths: [_activeSkillPath()],
            exercisePerformance: const [],
            goalSkills: const [],
            nodesClearedThisMonth: 0,
            onViewExercises: () => viewedExercises = true,
            onEditGoals: () {},
            onOpenGoalSkill: (_) {},
            onPrimaryAction: () {},
            onSecondaryAction: () {},
            onOpenSettings: () {},
            onOpenProgramSettings: () {},
            onOpenJourneySkill: (_) {},
            onOpenSkillPath: (_) {},
          ),
        ),
      ),
    );

    // The compact hero shows the duration/count meta line and two
    // divider-separated action rows; the exercise list lives behind
    // "View exercises" now, so no exercise names render on the card.
    expect(find.text('45 min · 5 exercises'), findsOneWidget);
    expect(find.text('View exercises'), findsOneWidget);
    expect(find.text('Train something else'), findsOneWidget);
    expect(find.text('Pull Ups'), findsNothing);
    expect(find.text('Hammer Curls'), findsNothing);

    await tester.tap(find.text('View exercises'));
    await tester.pump();

    expect(viewedExercises, isTrue);
  });

  testWidgets('active skill paths render grouped comparison stats',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeSkillPathsSection(
            paths: [_activeSkillPath()],
            onOpenSkillPath: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Scapular Pulls'), findsOneWidget);
    expect(find.text('Weighted Pullups'), findsWidgets);
    expect(find.text('Best 12 reps'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('your progress card expands inline and can collapse',
      (tester) async {
    // The collapsed card shows three skills, so a fourth is needed to make
    // the show-all toggle appear.
    final base = _journeySnapshot();
    final snapshot = JourneySnapshotData(
      totalLevel: base.totalLevel,
      maxLevel: base.maxLevel,
      averageSkillLevel: base.averageSkillLevel,
      tierLabel: base.tierLabel,
      unlockedSkillTrees: base.unlockedSkillTrees,
      totalSkillTrees: base.totalSkillTrees,
      nextTierLabel: base.nextTierLabel,
      levelsToNextTier: base.levelsToNextTier,
      closestSkills: [
        ...base.closestSkills,
        const JourneySkillProgressData(
          track: TrainingTrack.horizontalPull,
          skillCategoryId: 'rows',
          branchId: 'front_lever',
          motionLabel: 'Rows',
          skillTitle: 'Front Lever Rows',
          currentExerciseName: 'Ring Rows',
          nextExerciseName: 'Tuck Front Lever',
          targetVolume: 30,
          lastSessionVolume: 10,
          targetLabel: '30 reps',
          lastLabel: '10 reps',
          lastSessionDeltaLabel: 'no change',
          lastSessionTrend: JourneySkillTrend.flat,
          progressPercent: 0.33,
          stages: [],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeDashboardContent(
            todaySummary: _todaySummary(),
            streak: _streakData(),
            programLabel: 'Push / Pull · 3-day split',
            journeySnapshot: snapshot,
            activeSkillPaths: [_activeSkillPath()],
            exercisePerformance: const [],
            goalSkills: const [],
            nodesClearedThisMonth: 0,
            onViewExercises: () {},
            onEditGoals: () {},
            onOpenGoalSkill: (_) {},
            onPrimaryAction: () {},
            onSecondaryAction: () {},
            onOpenSettings: () {},
            onOpenProgramSettings: () {},
            onOpenJourneySkill: (_) {},
            onOpenSkillPath: (_) {},
          ),
        ),
      ),
    );

    // Collapsed card shows the three closest skills; the fourth is hidden.
    expect(find.text('Diamond Pushups'), findsOneWidget);
    expect(find.text('Front Lever Rows'), findsNothing);

    await tester.ensureVisible(find.text('Show all 4 skills'));
    await tester.tap(find.text('Show all 4 skills'));
    await tester.pump();

    expect(find.text('Diamond Pushups'), findsOneWidget);
    expect(find.text('Front Lever Rows'), findsOneWidget);
    expect(find.text('Show fewer'), findsOneWidget);

    await tester.ensureVisible(find.text('Show fewer'));
    await tester.tap(find.text('Show fewer'));
    await tester.pump();

    expect(find.text('Front Lever Rows'), findsNothing);
    expect(find.text('Show all 4 skills'), findsOneWidget);
  });

  testWidgets('tapping a progress skill can open JourneySkillDetailView',
      (tester) async {
    final skill = _journeySnapshot().closestSkills.first;
    Widget? destination;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: destination ??
                  HomeDashboardContent(
                    todaySummary: _todaySummary(),
                    streak: _streakData(),
                    programLabel: 'Push / Pull · 3-day split',
                    journeySnapshot: _journeySnapshot(),
                    activeSkillPaths: [_activeSkillPath()],
                    exercisePerformance: const [],
                    goalSkills: const [],
                    nodesClearedThisMonth: 0,
                    onViewExercises: () {},
                    onEditGoals: () {},
                    onOpenGoalSkill: (_) {},
                    onPrimaryAction: () {},
                    onSecondaryAction: () {},
                    onOpenSettings: () {},
                    onOpenProgramSettings: () {},
                    onOpenJourneySkill: (data) {
                      setState(
                        () => destination = JourneySkillDetailView(skill: data),
                      );
                    },
                    onOpenSkillPath: (_) {},
                  ),
            );
          },
        ),
      ),
    );

    await tester.ensureVisible(find.text(skill.skillTitle));
    await tester.tap(find.text(skill.skillTitle));
    await tester.pump();

    expect(find.byType(JourneySkillDetailView), findsOneWidget);
  });

  testWidgets(
      'progress detail shows stages in natural order and exercise name opens preview sheet',
      (tester) async {
    final skill = _journeySnapshot().closestSkills.first;

    await tester.pumpWidget(
      MaterialApp(
        home: JourneySkillDetailView(skill: skill),
      ),
    );

    final firstTop = tester.getTopLeft(find.text('Scapular Pulls')).dy;
    final secondTop = tester.getTopLeft(find.text('Negative Pull Up')).dy;

    expect(firstTop, lessThan(secondTop));
    expect(find.text('Difficulty 1/5 · Goal 24 reps'), findsOneWidget);

    await tester.tap(find.text('Scapular Pulls'));
    await tester.pumpAndSettle();

    expect(find.text('Learn more'), findsOneWidget);
    // The sheet previews the exercise — difficulty in words, no status chips.
    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('STATUS'), findsNothing);
  });

  testWidgets('progress detail chart fits when history reaches the goal',
      (tester) async {
    // A bar at 100%+ of goal must still leave room for its value label
    // (regression: the chart overflowed by ~8px).
    final skill = JourneySkillProgressData(
      track: TrainingTrack.verticalPull,
      skillCategoryId: 'pullups',
      branchId: 'weighted',
      motionLabel: 'Pullups',
      skillTitle: 'Weighted Pullups',
      currentExerciseName: 'Scapular Pulls',
      nextExerciseName: 'Negative Pull Up',
      targetVolume: 24,
      lastSessionVolume: 26,
      targetLabel: '24 reps',
      lastLabel: '26 reps',
      lastSessionDeltaLabel: '+2 reps',
      lastSessionTrend: JourneySkillTrend.up,
      progressPercent: 1,
      stages: [
        JourneySkillStageData(
          exerciseId: 'pullups_scapular_pull',
          exerciseName: 'Scapular Pulls',
          status: JourneySkillStageStatus.inProgress,
          targetVolume: 24,
          targetLabel: '24 reps',
          history: [
            JourneySkillStageHistoryPoint(
              value: 24,
              loggedAt: DateTime(2026, 6, 10),
            ),
            JourneySkillStageHistoryPoint(
              value: 26,
              loggedAt: DateTime(2026, 6, 17),
            ),
          ],
          unlockRequirementName: null,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: JourneySkillDetailView(skill: skill)),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('program overview button can open ProgramOverviewView',
      (tester) async {
    final service = TrainingProgramService();
    Widget? destination;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: destination ??
                  HomeDashboardContent(
                    todaySummary: _todaySummary(),
                    streak: _streakData(),
                    programLabel: 'Push / Pull · 3-day split',
                    journeySnapshot: _journeySnapshot(),
                    activeSkillPaths: [_activeSkillPath()],
                    exercisePerformance: const [],
                    goalSkills: const [],
                    nodesClearedThisMonth: 0,
                    onViewExercises: () {},
                    onEditGoals: () {},
                    onOpenGoalSkill: (_) {},
                    onPrimaryAction: () {},
                    onSecondaryAction: () {},
                    onOpenSettings: () {},
                    onOpenJourneySkill: (_) {},
                    onOpenProgramSettings: () {
                      setState(
                        () => destination = ProgramOverviewView(
                          initialLogic: TrainingProgramLogicSnapshot(
                            program: const UserTrainingProgram(
                              id: 'local',
                              userId: 'user',
                              programType: TrainingProgramType.pushPull,
                              scheduleVariant: null,
                              frequencyPerWeek: 3,
                              variationRules: {},
                              isActive: true,
                            ),
                            state: const UserTrainingProgramState(
                              id: 'state',
                              programId: 'local',
                              userId: 'user',
                              nextStepIndex: 0,
                              nextSessionType: TrainingSessionType.push,
                            ),
                            branchSelections: service.defaultBranchSelections(),
                            repGoalProfile: RepGoalProfile.balanced,
                          ),
                          progressMap: const {},
                          onSave: ({
                            required programType,
                            required branchSelections,
                            required repGoalProfile,
                            required sessionItemsConfig,
                            frequencyPerWeek,
                            setupAnswers,
                          }) async {
                            return TrainingProgramLogicSnapshot(
                              program: const UserTrainingProgram(
                                id: 'local',
                                userId: 'user',
                                programType: TrainingProgramType.pushPull,
                                scheduleVariant: null,
                                frequencyPerWeek: 3,
                                variationRules: {},
                                isActive: true,
                              ),
                              state: const UserTrainingProgramState(
                                id: 'state',
                                programId: 'local',
                                userId: 'user',
                                nextStepIndex: 0,
                                nextSessionType: TrainingSessionType.push,
                              ),
                              branchSelections:
                                  service.defaultBranchSelections(),
                              repGoalProfile: RepGoalProfile.balanced,
                            );
                          },
                        ),
                      );
                    },
                    onOpenSkillPath: (_) {},
                  ),
            );
          },
        ),
      ),
    );

    await tester.ensureVisible(find.text('Your program'));
    await tester.tap(find.text('Your program'));
    await tester.pump();

    expect(find.byType(ProgramOverviewView), findsOneWidget);
  });

  testWidgets('top gear can open SettingsView', (tester) async {
    Widget? destination;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: destination ??
                  HomeDashboardContent(
                    todaySummary: _todaySummary(),
                    streak: _streakData(),
                    programLabel: 'Push / Pull · 3-day split',
                    journeySnapshot: _journeySnapshot(),
                    activeSkillPaths: [_activeSkillPath()],
                    exercisePerformance: const [],
                    goalSkills: const [],
                    nodesClearedThisMonth: 0,
                    onViewExercises: () {},
                    onEditGoals: () {},
                    onOpenGoalSkill: (_) {},
                    onPrimaryAction: () {},
                    onSecondaryAction: () {},
                    onOpenSettings: () {
                      setState(() => destination = const SettingsView());
                    },
                    onOpenProgramSettings: () {},
                    onOpenJourneySkill: (_) {},
                    onOpenSkillPath: (_) {},
                  ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();

    expect(find.byType(SettingsView), findsOneWidget);
  });

  testWidgets('tapping a workout type opens ProgramWorkoutEditorView',
      (tester) async {
    final service = TrainingProgramService();

    await tester.pumpWidget(
      MaterialApp(
        home: ProgramOverviewView(
          initialLogic: TrainingProgramLogicSnapshot(
            program: const UserTrainingProgram(
              id: 'local',
              userId: 'user',
              programType: TrainingProgramType.pushPull,
              scheduleVariant: null,
              frequencyPerWeek: 3,
              variationRules: {},
              isActive: true,
            ),
            state: const UserTrainingProgramState(
              id: 'state',
              programId: 'local',
              userId: 'user',
              nextStepIndex: 0,
              nextSessionType: TrainingSessionType.push,
            ),
            branchSelections: service.defaultBranchSelections(),
            repGoalProfile: RepGoalProfile.balanced,
          ),
          progressMap: const {},
          onSave: ({
            required programType,
            required branchSelections,
            required repGoalProfile,
            required sessionItemsConfig,
            frequencyPerWeek,
            setupAnswers,
          }) async {
            return TrainingProgramLogicSnapshot(
              program: const UserTrainingProgram(
                id: 'local',
                userId: 'user',
                programType: TrainingProgramType.pushPull,
                scheduleVariant: null,
                frequencyPerWeek: 3,
                variationRules: {},
                isActive: true,
              ),
              state: const UserTrainingProgramState(
                id: 'state',
                programId: 'local',
                userId: 'user',
                nextStepIndex: 0,
                nextSessionType: TrainingSessionType.push,
              ),
              branchSelections: service.defaultBranchSelections(),
              repGoalProfile: RepGoalProfile.balanced,
            );
          },
        ),
      ),
    );

    // Workouts are listed per type — one row per session, its days read off
    // the strip above: Mon/Wed/Fri alternating push · pull · push.
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('Pull'), findsOneWidget);

    // The hero pushes the workout rows below the test surface.
    await tester.ensureVisible(find.text('Push'));
    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();

    expect(find.byType(ProgramWorkoutEditorView), findsOneWidget);
  });

  testWidgets('tapping an active skill path can open SkillTreeView',
      (tester) async {
    final skillPath = _activeSkillPath();
    Widget? destination;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: destination ??
                  HomeSkillPathsSection(
                    paths: [skillPath],
                    onOpenSkillPath: (path) {
                      setState(
                        () => destination = SkillTreeView(
                          skillCategoryId: path.skillCategoryId,
                          progressMap: const {},
                          onProgressChanged: (_, __) {},
                        ),
                      );
                    },
                  ),
            );
          },
        ),
      ),
    );

    await tester.ensureVisible(find.text(skillPath.currentExerciseName));
    await tester.tap(find.text(skillPath.currentExerciseName));
    await tester.pump();

    expect(find.byType(SkillTreeView), findsOneWidget);
  });
}

HomeTodaySummary _todaySummary() {
  return const HomeTodaySummary(
    sessionTitle: 'Pull Day',
    ctaLabel: 'Start Pull Day',
    isRestDay: false,
    exerciseCount: 5,
    estimatedDurationMinutes: 45,
    focusTags: [
      'Pull Ups',
      'Rows',
      'Hanging Leg Raise',
      'Face Pulls',
      'Hammer Curls',
    ],
    plannedExercises: [
      HomePlannedExerciseSummary(name: 'Pull Ups', targetLabel: '4 × 8'),
      HomePlannedExerciseSummary(name: 'Rows', targetLabel: '3 × 12'),
      HomePlannedExerciseSummary(
        name: 'Hanging Leg Raise',
        targetLabel: '3 × 15',
      ),
      HomePlannedExerciseSummary(name: 'Face Pulls', targetLabel: '3 × 12'),
      HomePlannedExerciseSummary(name: 'Hammer Curls', targetLabel: '3 × 12'),
    ],
    mixSegments: [
      HomeTodayMixSegment(label: 'Pull', percentage: 50),
      HomeTodayMixSegment(label: 'Core', percentage: 25),
      HomeTodayMixSegment(label: 'Skill', percentage: 25),
    ],
    supportingText:
        'Built from your current program state and ready to start immediately.',
  );
}

HomeStreakData _streakData() {
  return const HomeStreakData(
    streakWeeks: 2,
    completedThisWeek: 3,
    plannedPerWeek: 5,
    hasWorkouts: true,
  );
}

JourneySnapshotData _journeySnapshot() {
  return JourneySnapshotData(
    totalLevel: 12,
    maxLevel: 100,
    averageSkillLevel: 1.2,
    tierLabel: 'Beginner',
    unlockedSkillTrees: 2,
    totalSkillTrees: 10,
    nextTierLabel: 'Intermediate',
    levelsToNextTier: 23,
    closestSkills: [
      JourneySkillProgressData(
        track: TrainingTrack.verticalPull,
        skillCategoryId: 'pullups',
        branchId: 'weighted',
        motionLabel: 'Pullups',
        skillTitle: 'Weighted Pullups',
        currentExerciseName: 'Scapular Pulls',
        nextExerciseName: 'Negative Pull Up',
        targetVolume: 24,
        lastSessionVolume: 18,
        targetLabel: '24 reps',
        lastLabel: '18 reps',
        lastSessionDeltaLabel: '+6 reps',
        lastSessionTrend: JourneySkillTrend.up,
        progressPercent: 0.75,
        stages: [
          JourneySkillStageData(
            exerciseId: 'pullups_scapular_pull',
            exerciseName: 'Scapular Pulls',
            status: JourneySkillStageStatus.inProgress,
            targetVolume: 24,
            targetLabel: '24 reps',
            history: [
              JourneySkillStageHistoryPoint(
                value: 12,
                loggedAt: DateTime(2026, 6, 10),
              ),
              JourneySkillStageHistoryPoint(
                value: 18,
                loggedAt: DateTime(2026, 6, 17),
              ),
            ],
            unlockRequirementName: null,
          ),
          const JourneySkillStageData(
            exerciseId: 'pullups_pull_up_negative',
            exerciseName: 'Negative Pull Up',
            status: JourneySkillStageStatus.locked,
            targetVolume: 36,
            targetLabel: '36 reps',
            history: [],
            unlockRequirementName: 'Scapular Pulls',
          ),
        ],
      ),
      JourneySkillProgressData(
        track: TrainingTrack.core,
        skillCategoryId: 'core',
        branchId: 'l_sit',
        motionLabel: 'Core',
        skillTitle: 'L-Sit / V-Sit',
        currentExerciseName: 'Tuck L-sit',
        nextExerciseName: 'One Leg L-sit',
        targetVolume: 60,
        lastSessionVolume: 40,
        targetLabel: '60s',
        lastLabel: '40s',
        lastSessionDeltaLabel: 'no change',
        lastSessionTrend: JourneySkillTrend.flat,
        progressPercent: 0.67,
        stages: [
          JourneySkillStageData(
            exerciseId: 'tuck_l_sit',
            exerciseName: 'Tuck L-sit',
            status: JourneySkillStageStatus.inProgress,
            targetVolume: 60,
            targetLabel: '60s',
            history: [
              JourneySkillStageHistoryPoint(
                value: 32,
                loggedAt: DateTime(2026, 6, 12),
              ),
              JourneySkillStageHistoryPoint(
                value: 40,
                loggedAt: DateTime(2026, 6, 19),
              ),
            ],
            unlockRequirementName: null,
          ),
        ],
      ),
      JourneySkillProgressData(
        track: TrainingTrack.horizontalPush,
        skillCategoryId: 'pushups',
        branchId: 'diamond',
        motionLabel: 'Pushups',
        skillTitle: 'Diamond Pushups',
        currentExerciseName: 'Diamond Push-up',
        nextExerciseName: 'Archer Push-up',
        targetVolume: 24,
        lastSessionVolume: 12,
        targetLabel: '24 reps',
        lastLabel: '12 reps',
        lastSessionDeltaLabel: '-6 reps',
        lastSessionTrend: JourneySkillTrend.down,
        progressPercent: 0.5,
        stages: [
          JourneySkillStageData(
            exerciseId: 'diamond_pushup',
            exerciseName: 'Diamond Push-up',
            status: JourneySkillStageStatus.inProgress,
            targetVolume: 24,
            targetLabel: '24 reps',
            history: [
              JourneySkillStageHistoryPoint(
                value: 18,
                loggedAt: DateTime(2026, 6, 8),
              ),
              JourneySkillStageHistoryPoint(
                value: 12,
                loggedAt: DateTime(2026, 6, 21),
              ),
            ],
            unlockRequirementName: null,
          ),
        ],
      ),
    ],
  );
}

ActiveSkillPathData _activeSkillPath() {
  return const ActiveSkillPathData(
    track: TrainingTrack.verticalPull,
    skillCategoryId: 'pullups',
    branchId: 'weighted',
    trackLabel: 'Vertical Pull',
    skillTitle: 'Weighted Pullups',
    currentExerciseName: 'Scapular Pulls',
    level: 3,
    progressPercent: 30,
    momentum: HomeSkillMomentum.steady,
    note: 'Best set is flat across both 14-day windows',
    personalBestLabel: 'Best 12 reps',
    deltaLabel: '0',
    isTimed: false,
  );
}

DailyTrainingRecommendation _recommendation() {
  final exercise = ExerciseCatalog.findById('pullups_scapular_pull')!;
  return DailyTrainingRecommendation(
    programType: TrainingProgramType.pushPull,
    sessionType: TrainingSessionType.pull,
    sessionLabel: 'Pull Day',
    isRestDay: false,
    items: [
      TrainingRecommendationItem(
        track: TrainingTrack.verticalPull,
        exercise: exercise,
        status: ExerciseStatus.active,
        sourceCategory: exercise.category,
        sourceSkillCategoryId: exercise.skillCategoryId,
      ),
    ],
  );
}
