import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/type_led.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/progression_event_model.dart';
import '../../data/models/progression_suggestion_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/dev_clock_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/exercise_progression_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/progression_event_service.dart';
import '../../data/services/skill_track_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../../data/services/training_schedule_service.dart';
import 'alternate_workout_options_view.dart';
import 'home_dashboard_metrics.dart';
import 'home_empty_state.dart';
import 'live_workout_view.dart';
import 'program_setup_completion.dart';
import 'program_setup_view.dart';
import 'session_overview_view.dart';
import 'widgets/needs_approval_card.dart';
import 'train_day_view.dart';
import 'widgets/day_ribbon.dart';
import 'widgets/day_state_views.dart';
import 'widgets/rest_day_view.dart';
import 'widgets/today_workout_card.dart';
import 'widgets/what_changed_card.dart';
import 'widgets/workout_done_view.dart';
import '../data/past_workout_detail_view.dart';

/// Train tab — today's workout as a performance list (planned exercises with
/// last result and change vs the previous attempt) plus a coaching tip.
class HomeView extends StatefulWidget {
  final bool isActive;

  /// Switches the shell to the Program tab — used by the no-program state
  /// to send the user to where setup lives.
  final VoidCallback? onGoToProgram;

  const HomeView({
    super.key,
    this.isActive = false,
    this.onGoToProgram,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _progressService = ProgressService();
  final _devClockService = DevClockService();
  final _exerciseLogService = ExerciseLogService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();
  final _trainingScheduleService = TrainingScheduleService();
  final _progressionEventService = ProgressionEventService();
  final _progressionService = ExerciseProgressionService();
  final _skillTrackService = SkillTrackService();

  bool _loading = true;
  bool _hasProgram = true;
  Map<String, ExerciseStatus> _progressMap = {};
  Map<String, ExerciseProgress> _progressEntries = {};
  List<PastWorkout> _pastWorkouts = const [];
  List<ProgressionEvent> _whatChanged = const [];

  /// Loaded-lift changes the program has proposed and is waiting on.
  List<ProgressionSuggestion> _needsApproval = const [];

  /// What each past session changed, once a logged day has been opened —
  /// the newest session's changes already live in [_whatChanged].
  final Map<String, List<ProgressionEvent>> _eventsBySession = {};

  /// The day the tab is looking at, or null while it is looking at today.
  /// Selecting a day never leaves the tab: the same screen re-reads itself
  /// for that day and says plainly what it can and cannot know about it.
  DateTime? _selectedDate;
  List<SkillTrack> _skillTracks = const [];
  TrainingProgramLogicSnapshot? _logicSnapshot;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  @override
  void didUpdateWidget(covariant HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The shell keeps tabs alive in an IndexedStack, so re-fetch whenever
    // this tab becomes active — e.g. after a dev reset from Settings the
    // card would otherwise keep showing the deleted program.
    if (!oldWidget.isActive && widget.isActive) {
      _loadHomeData();
    }
  }

  Future<void> _loadHomeData() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      await _devClockService.loadOffset();
      final results = await Future.wait([
        _progressService.fetchAll(userId),
        _trainingProgramStoreService.fetchProgramLogic(userId),
        _exerciseLogService.fetchPastWorkouts(userId),
      ]);
      final pastWorkouts = results[2] as List<PastWorkout>;
      // The insight reflects only the most recently finished session (past
      // workouts come back newest first). It clears once a newer workout is
      // logged — that session becomes the source, and if it produced no
      // changes there's simply nothing to show.
      var whatChanged = const <ProgressionEvent>[];
      final latestSessionId =
          pastWorkouts.isEmpty ? null : pastWorkouts.first.id;
      if (latestSessionId != null) {
        try {
          whatChanged = (await _progressionEventService.fetchForSession(
                  userId, latestSessionId))
              .where((event) => event.kind != ProgressionEventKind.personalBest)
              .toList();
        } catch (error, stackTrace) {
          debugPrint('Failed to load progression feed: $error\n$stackTrace');
        }
      }

      // Waiting on the user, and not tied to the latest session: a proposal
      // stands until it is approved or turned down.
      var needsApproval = const <ProgressionSuggestion>[];
      try {
        needsApproval = await _progressionService.fetchOpenSuggestions(userId);
      } catch (error, stackTrace) {
        debugPrint('Failed to load pending approvals: $error\n$stackTrace');
      }

      final logic = results[1] as TrainingProgramLogicSnapshot?;
      // Skills-as-tracks: seeded on first use from the legacy lane
      // selections + goals, so existing users keep what they trained.
      var skillTracks = const <SkillTrack>[];
      if (logic != null) {
        try {
          skillTracks = await _skillTrackService.getOrSeed(
            userId,
            laneSelections: {
              ..._trainingProgramService.defaultBranchSelections(),
              ...logic.branchSelections,
            },
            goalSkillIds: logic.program.setupGoalIds,
          );
        } catch (error, stackTrace) {
          debugPrint('Failed to load skill tracks: $error\n$stackTrace');
        }
      }

      if (!mounted) return;
      final progress = results[0] as List<ExerciseProgress>;
      setState(() {
        _progressEntries = {
          for (final item in progress) item.exerciseId: item,
        };
        _progressMap = {
          for (final item in progress) item.exerciseId: item.status,
        };
        _logicSnapshot = logic;
        _hasProgram = _logicSnapshot != null;
        _pastWorkouts = pastWorkouts;
        _whatChanged = whatChanged;
        _needsApproval = needsApproval;
        _skillTracks = skillTracks;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load home data: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't load your training data. Pull down to retry.",
          ),
        ),
      );
    }
  }

  _TrainSnapshot? _buildSnapshot() {
    final snapshot = _logicSnapshot;
    if (snapshot == null) return null;

    final programType = snapshot.program.programType;
    final scheduleVariant = snapshot.program.scheduleVariant;
    final now = _devClockService.now();
    // Lane view bridges skill tracks into lane-keyed consumers (dashboards,
    // config fallback); the actual session items come from the tracks.
    final branchSelections = {
      ..._trainingProgramService.defaultBranchSelections(),
      ...snapshot.branchSelections,
      ..._trainingProgramService.laneSelectionsFromTracks(_skillTracks),
    };
    final sessionItemsConfig = _sessionItemsConfigFor(snapshot.program);
    final lastPlannedWorkout = _latestPlannedWorkout();
    // The plan is anchored on the stored program pointer, not on workout
    // history, so deleting an older session leaves the schedule alone —
    // history only fills in which days already have a workout on them.
    // History is the fallback for the case where the pointer was never
    // written (a failed save on the very first session).
    final anchorDate =
        snapshot.state.lastCompletedAt ?? lastPlannedWorkout?.loggedAt;
    final anchorSessionType = snapshot.state.lastSessionType ??
        (lastPlannedWorkout == null
            ? null
            : TrainingSessionTypeX.fromDbValue(lastPlannedWorkout.sessionType));
    final completedSessions = {
      for (final workout in _pastWorkouts)
        if (workout.affectsSchedule)
          TrainingScheduleService.dateOnly(workout.loggedAt):
              TrainingSessionTypeX.fromDbValue(workout.sessionType),
    };
    final dayMask =
        TrainingScheduleService.dayMaskFrom(snapshot.program.variationRules);
    final scheduleWindow = _trainingScheduleService.buildWindow(
      programType: programType,
      frequencyPerWeek: snapshot.program.frequencyPerWeek,
      dayMask: dayMask,
      currentStepIndex: snapshot.state.nextStepIndex,
      currentSessionType: snapshot.state.nextSessionType,
      lastPlannedWorkoutAt: anchorDate,
      lastCompletedSessionType: anchorSessionType,
      completedSessions: completedSessions,
      now: now,
    );
    // The ribbon starts at today and runs a week ahead. There is nothing
    // behind today to scroll back to: the tab is for the session you are
    // about to do and the ones lining up behind it, and the schedule screen
    // is where a finished week is read. The day the ribbon has selected is
    // what the whole screen reads from.
    final ribbonWindow = _trainingScheduleService.buildWindow(
      programType: programType,
      frequencyPerWeek: snapshot.program.frequencyPerWeek,
      dayMask: dayMask,
      currentStepIndex: snapshot.state.nextStepIndex,
      currentSessionType: snapshot.state.nextSessionType,
      lastPlannedWorkoutAt: anchorDate,
      lastCompletedSessionType: anchorSessionType,
      completedSessions: completedSessions,
      selectedDate: _selectedDate,
      daysBeforeToday: 0,
      // Two weeks exactly: the row you land on, and the one a scroll brings.
      daysAfterToday: DayRibbon.daysPerPage * 2 - 1,
      now: now,
    );
    final selectedDay = ribbonWindow.selectedDay;
    final schedule = HomeScheduleResolution(
      effectiveStepIndex: selectedDay.stepIndex,
      effectiveSessionType: selectedDay.sessionType,
      todayPosition: scheduleWindow.days.indexWhere((day) => day.isToday),
      completedToday: selectedDay.isCompleted,
    );
    final recommendation = _trainingProgramService.buildToday(
      progressMap: _progressMap,
      programType: programType,
      sessionType: schedule.effectiveSessionType,
      branchSelections: branchSelections,
      sessionItemsConfig: sessionItemsConfig,
      skillTracks: _skillTracks,
      plannedDate: selectedDay.date,
      plannedStepIndex: selectedDay.stepIndex,
      affectsSchedule: !selectedDay.isRestDay,
    );
    final completedWorkout = selectedDay.isCompleted
        ? _workoutForDate(selectedDay.date, plannedOnly: true)
        : null;
    final masterySettings = MasteryTargetSettings.fromVariationRules(
      snapshot.program.variationRules,
    );
    return _TrainSnapshot(
      recommendation: recommendation,
      selectedDay: selectedDay,
      ribbonDays: _calendarDaysForWindow(ribbonWindow),
      rescheduledTo: selectedDay.isMissed
          ? _rescheduledDateFor(ribbonWindow, selectedDay)
          : null,
      metrics: HomeDashboardMetricsCalculator.build(
        recommendation: recommendation,
        trainingProgramService: _trainingProgramService,
        programType: programType,
        scheduleVariant: scheduleVariant,
        schedule: schedule,
        branchSelections: branchSelections,
        sessionItemsConfig: sessionItemsConfig,
        progressMap: _progressMap,
        progressEntries: _progressEntries,
        workouts: _pastWorkouts,
        skillTracks: _skillTracks,
        goalSkillIds: snapshot.program.goalSkillIds,
        frequencyPerWeek: snapshot.program.frequencyPerWeek,
        dayMask: dayMask,
        scheduleWindow: scheduleWindow,
        completedWorkout: completedWorkout,
        now: now,
        masterySettings: masterySettings,
      ),
      now: now,
    );
  }

  /// Where a missed day's session ended up. The plan does not drop a missed
  /// session — it stays next in line and everything after it slides — so the
  /// answer is the next day still carrying that session.
  DateTime? _rescheduledDateFor(
    TrainingScheduleWindow window,
    PlannedScheduleDay missed,
  ) {
    for (final day in window.days) {
      if (!day.date.isAfter(missed.date)) continue;
      if (day.isRestDay || day.isMissed) continue;
      if (day.sessionType != missed.sessionType) continue;
      return day.date;
    }
    return null;
  }

  List<HomeWeekStripDay> _calendarDaysForWindow(
    TrainingScheduleWindow scheduleWindow,
  ) {
    return [
      for (final day in scheduleWindow.days)
        HomeWeekStripDay(
          date: day.date,
          sessionType: day.sessionType,
          isCurrent: day.isToday,
          isSelected: day.isSelected,
          isCompleted: day.isCompleted ||
              _workoutForDate(day.date, plannedOnly: true) != null,
          isMissed: day.isMissed,
          stepIndex: day.stepIndex,
        ),
    ];
  }

  Map<String, dynamic> _sessionItemsConfigFor(UserTrainingProgram program) {
    final raw = program.variationRules['session_items_v1'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  PastWorkout? _latestPlannedWorkout() {
    for (final workout in _pastWorkouts) {
      if (workout.affectsSchedule) return workout;
    }
    return null;
  }

  PastWorkout? _workoutForDate(DateTime date, {bool plannedOnly = false}) {
    final target = TrainingScheduleService.dateOnly(date);
    for (final workout in _pastWorkouts) {
      if (plannedOnly && !workout.affectsSchedule) continue;
      if (TrainingScheduleService.dateOnly(workout.loggedAt)
          .isAtSameMomentAs(target)) {
        return workout;
      }
    }
    return null;
  }

  Future<void> _openProgramSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramSetupView(
          onComplete: _completeProgramSetup,
        ),
      ),
    );
    // Re-fetch so the tab reflects the freshly created program even if the
    // user abandoned the wizard midway on a stale state.
    await _loadHomeData();
  }

  Future<void> _completeProgramSetup(ProgramSetupResult result) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    await completeProgramSetup(
      userId: userId,
      result: result,
      trainingProgramService: _trainingProgramService,
      storeService: _trainingProgramStoreService,
    );
    await _loadHomeData();
  }

  Future<void> _startWorkout(DailyTrainingRecommendation recommendation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => recommendation.isRestDay
            ? SessionOverviewView(recommendation: recommendation)
            : LiveWorkoutView(recommendation: recommendation),
      ),
    );
    // A finished workout changes today's card — re-fetch.
    await _loadHomeData();
  }

  Future<void> _openAlternateWorkoutOptions(
    DailyTrainingRecommendation recommendation,
  ) async {
    final sessionType = recommendation.sessionType == TrainingSessionType.rest
        ? TrainingSessionType.fullBody
        : recommendation.sessionType;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlternateWorkoutOptionsView(
          onOpenBlankWorkout: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LiveWorkoutView(
                  recommendation: DailyTrainingRecommendation(
                    programType: recommendation.programType,
                    sessionType: sessionType,
                    sessionLabel: 'Blank Workout',
                    isRestDay: false,
                    items: const [],
                    affectsSchedule: false,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    // A workout may have been logged from here — re-fetch.
    await _loadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _loading ? null : _buildSnapshot();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: LoadingIndicator())
            : !_hasProgram || snapshot == null
                ? RefreshIndicator(
                    color: AppColors.accentPrimary,
                    backgroundColor: AppColors.surface,
                    onRefresh: _loadHomeData,
                    child: HomeEmptyState(
                      onGoToProgram: widget.onGoToProgram ?? _openProgramSetup,
                    ),
                  )
                : _buildTab(snapshot),
      ),
    );
  }

  /// The tab, whichever day it is reading: the ribbon fixed at the top, the
  /// day under it, and the actions sitting directly on the tab bar. Only the
  /// middle changes as you move across the week, so the screen never
  /// re-shuffles itself under your thumb.
  Widget _buildTab(_TrainSnapshot snapshot) {
    final presentation = _presentationFor(snapshot);
    final workout = _workoutForDate(
      snapshot.selectedDay.date,
      plannedOnly: true,
    );
    final actions = _actionsFor(snapshot, presentation);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
          child: _ribbon(snapshot),
        ),
        Expanded(
          child: Padding(
            // With nothing pinned under it, the body itself has to clear the
            // tab bar.
            padding: EdgeInsets.only(
              bottom: actions == null ? _tabBarInset + _tabBarGap : 0,
            ),
            child: _bodyFor(snapshot, presentation, workout),
          ),
        ),
        if (actions != null)
          Padding(
            padding: EdgeInsets.fromLTRB(22, 10, 22, _tabBarInset + _tabBarGap),
            child: actions,
          ),
      ],
    );
  }

  /// How the selected day reads.
  TrainDayPresentation _presentationFor(_TrainSnapshot snapshot) {
    final day = snapshot.selectedDay;
    final workout = _workoutForDate(day.date, plannedOnly: true);
    return TrainDayViewResolver.resolve(
      date: day.date,
      today: TrainingScheduleService.dateOnly(snapshot.now),
      isCompleted: day.isCompleted || workout != null,
      isMissed: day.isMissed,
      isRestDay: day.isRestDay,
      rescheduledTo: snapshot.rescheduledTo,
    );
  }

  /// What the page has to keep clear at the bottom.
  ///
  /// The shell's body extends behind the floating tab bar, and Flutter
  /// already reports that bar's height as this page's bottom padding — so
  /// this is the tab bar, home indicator and all. Adding a nav-bar height on
  /// top of it (as this did) counts the bar twice and floats whatever is
  /// pinned a bar's height above where it belongs.
  double get _tabBarInset => MediaQuery.of(context).padding.bottom;

  /// Breathing room between the last thing on the page and the tab bar. The
  /// quiet text actions sit right at the bottom edge of their block, so
  /// without it they read as part of the bar rather than of the page.
  static const double _tabBarGap = 20;

  Widget _bodyFor(
    _TrainSnapshot snapshot,
    TrainDayPresentation presentation,
    PastWorkout? workout,
  ) {
    // A rest day never scrolls: the illustration flexes so the copy under it
    // stays above the fold.
    if (presentation.view == TrainDayView.rest ||
        (presentation.isToday && snapshot.metrics.today.isRestDay)) {
      return _restBody(snapshot, presentation);
    }

    return RefreshIndicator(
      color: AppColors.accentPrimary,
      backgroundColor: AppColors.surface,
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        // Attached to the shell's per-tab controller, so re-tapping the tab
        // scrolls back to the top.
        primary: true,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (presentation.eyebrow != null)
                DayEyebrow(
                  text: presentation.eyebrow!,
                  color: presentation.view == TrainDayView.missed
                      ? AppColors.red
                      : AppColors.textMuted,
                ),
              if (presentation.isToday)
                _buildContent(snapshot)
              else
                ..._dayContent(snapshot, presentation, workout),
            ],
          ),
        ),
      ),
    );
  }

  /// Recovery, on today or on a day you are looking ahead to. What differs is
  /// only what can be said around it: today explains why it is resting and
  /// offers a way to train anyway; a day ahead simply says one is planned.
  Widget _restBody(
    _TrainSnapshot snapshot,
    TrainDayPresentation presentation,
  ) {
    final isToday = presentation.isToday;
    // What comes after a rest day only matters on the rest day itself. Read
    // from next week it is a second date on a screen whose whole point is
    // that there is nothing to do on the one you are looking at.
    final (nextTitle, nextWhen) =
        isToday ? _nextSession(snapshot.metrics.weekStrip) : (null, null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (presentation.eyebrow != null)
            DayEyebrow(text: presentation.eyebrow!),
          Expanded(
            child: RestDayView(
              title: isToday ? 'Nothing to do today' : 'Rest day planned',
              showReason: isToday,
              nextTitle: nextTitle,
              nextWhen: nextWhen,
              onTrainSomethingElse: isToday
                  ? () => _openAlternateWorkoutOptions(snapshot.recommendation)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// What the tab pins on the tab bar for this day, or null when the day
  /// asks nothing of you.
  Widget? _actionsFor(
    _TrainSnapshot snapshot,
    TrainDayPresentation presentation,
  ) {
    if (presentation.isToday) {
      if (snapshot.metrics.today.isRestDay) return null;
      if (snapshot.metrics.today.completed != null) return null;
      return TodayWorkoutActions(
        summary: snapshot.metrics.today,
        onStart: () => _startWorkout(snapshot.recommendation),
        onTrainSomethingElse: () =>
            _openAlternateWorkoutOptions(snapshot.recommendation),
      );
    }
    return _dayActions(snapshot, presentation);
  }

  /// The next training day after [date], and how far past it that falls —
  /// read from the day being looked at, not from today.
  (String?, String?) _nextSessionAfter(
    DateTime date,
    List<HomeWeekStripDay> days,
  ) {
    for (final day in days) {
      final distance = TrainDayViewResolver.daysBetween(date, day.date);
      if (distance <= 0) continue;
      if (day.sessionType == TrainingSessionType.rest) continue;
      return (
        _sessionTitle(day.sessionType),
        distance == 1 ? 'the next day' : 'in $distance days',
      );
    }
    return (null, null);
  }

  /// The body of a day, by what is known about it: real numbers for a day
  /// close enough to have them, the shape of the day beyond that, bare names
  /// for a day where nothing was logged and nothing is prescribed.
  List<Widget> _dayContent(
    _TrainSnapshot snapshot,
    TrainDayPresentation presentation,
    PastWorkout? workout,
  ) {
    final summary = snapshot.metrics.today;
    final note = presentation.note;

    switch (presentation.view) {
      case TrainDayView.soon:
        return [
          TodayWorkoutCard(
            summary: summary,
            rows: TodayWorkoutContent.rows(snapshot.metrics),
            // The note takes the slot the UPDATED line has on today, so a
            // day only ever carries one band of explanation.
            updatedLine: note == null ? null : DayNoteBand(note: note),
          ),
        ];
      case TrainDayView.distant:
        final rows = _patternRowsFor(snapshot.recommendation);
        return [
          TypeTitle(
            summary.sessionTitle,
            sub: 'Built the morning of · '
                '${_spelledCount(rows.length)} '
                '${rows.length == 1 ? 'slot' : 'slots'} from your program',
          ),
          if (note != null) DayNoteBand(note: note),
          const SizedBox(height: 8),
          DayPatternList(rows: rows),
        ];
      case TrainDayView.missed:
        final names = [
          for (final item in snapshot.recommendation.items) item.exercise.name,
        ];
        return [
          TypeTitle(
            summary.sessionTitle,
            sub: '${_spelledCount(names.length)} '
                '${names.length == 1 ? 'exercise' : 'exercises'} · '
                'nothing was logged',
          ),
          if (note != null)
            DayNoteBand(note: note, tagColor: AppColors.accentPrimary),
          DayNameList(names: names),
        ];
      case TrainDayView.logged:
        if (workout == null) {
          return [
            TypeTitle(summary.sessionTitle, sub: 'Logged'),
          ];
        }
        final (nextTitle, nextWhen) = _nextSessionAfter(
          snapshot.selectedDay.date,
          snapshot.ribbonDays,
        );
        final changes = _changesFor(workout);
        // The same screen the day itself ended on: the burst, the way into
        // the record, and what the session moved.
        return [
          WorkoutDoneView(
            nextTitle: nextTitle,
            nextWhen: nextWhen,
            onViewWorkout: () => _openPastWorkout(workout),
          ),
          if (changes.isNotEmpty) TrainInsight(events: changes),
        ];
      case TrainDayView.rest:
      case TrainDayView.today:
        // Both are rendered by their own body, not by this list.
        return const [];
    }
  }

  Widget _dayActions(
    _TrainSnapshot snapshot,
    TrainDayPresentation presentation,
  ) {
    switch (presentation.view) {
      case TrainDayView.soon:
        return DayActions(
          primaryLabel: 'Start this early',
          onPrimary: () => _startWorkout(snapshot.recommendation),
          secondaryLabel: 'Back to today',
          onSecondary: _backToToday,
        );
      // The finished screen carries its own way into the record, so the only
      // thing pinned under it is the way back.
      case TrainDayView.logged:
      // A missed day is read, not acted on: the band already says where its
      // session went, so the only thing left to do here is leave.
      case TrainDayView.missed:
      case TrainDayView.distant:
      case TrainDayView.rest:
      case TrainDayView.today:
        return DayActions(
          secondaryLabel: 'Back to today',
          onSecondary: _backToToday,
        );
    }
  }

  /// What a day trains when which exercises it trains is not settled: the
  /// movements it covers and how many slots each one gets.
  List<DayPatternRow> _patternRowsFor(DailyTrainingRecommendation plan) {
    const order = ['Push', 'Pull', 'Legs', 'Core', 'Skill work', 'Other'];
    final counts = <String, int>{};

    for (final item in plan.items) {
      final group = switch (item.exercise.category) {
        ExerciseCategory.verticalPush ||
        ExerciseCategory.horizontalPush =>
          'Push',
        ExerciseCategory.verticalPull ||
        ExerciseCategory.horizontalPull =>
          'Pull',
        ExerciseCategory.squat || ExerciseCategory.hinge => 'Legs',
        ExerciseCategory.core => 'Core',
        ExerciseCategory.skill => 'Skill work',
        ExerciseCategory.other => 'Other',
      };
      counts[group] = (counts[group] ?? 0) + 1;
    }

    return [
      for (final group in order)
        if (counts[group] case final count?)
          DayPatternRow(
            movement: group,
            slots: '${_spelledCount(count)} '
                '${count == 1 ? 'exercise' : 'exercises'}',
          ),
    ];
  }

  static String _spelledCount(int count) {
    const words = [
      'No',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
    ];
    return count >= 0 && count < words.length ? words[count] : '$count';
  }

  /// The dated ribbon, shared by every state of the tab. Tapping a day never
  /// leaves the tab — the screen re-reads itself for that day.
  Widget _ribbon(_TrainSnapshot snapshot) {
    return DayRibbon(
      days: snapshot.ribbonDays,
      selectedDate: snapshot.selectedDay.date,
      today: TrainingScheduleService.dateOnly(snapshot.now),
      onDayTap: _selectDay,
      onBackToToday: _backToToday,
    );
  }

  Future<void> _selectDay(HomeWeekStripDay day) async {
    final date = TrainingScheduleService.dateOnly(day.date);
    setState(() => _selectedDate = date);

    // A logged day reads back as the session-complete screen, receipt and
    // all — which means fetching what that session changed, unless it is the
    // newest one (already loaded) or has been opened before.
    final workout = _workoutForDate(date, plannedOnly: true);
    if (workout == null || _eventsBySession.containsKey(workout.id)) return;
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    try {
      final events = (await _progressionEventService.fetchForSession(
        userId,
        workout.id,
      ))
          .where((event) => event.kind != ProgressionEventKind.personalBest)
          .toList();
      if (!mounted) return;
      setState(() => _eventsBySession[workout.id] = events);
    } catch (error, stackTrace) {
      debugPrint('Failed to load session changes: $error\n$stackTrace');
    }
  }

  /// What a finished session changed, from whichever source already has it.
  List<ProgressionEvent> _changesFor(PastWorkout workout) {
    if (_pastWorkouts.isNotEmpty && _pastWorkouts.first.id == workout.id) {
      return _whatChanged;
    }
    return _eventsBySession[workout.id] ?? const [];
  }

  void _backToToday() => setState(() => _selectedDate = null);

  Widget _buildContent(_TrainSnapshot snapshot) {
    final metrics = snapshot.metrics;
    final completed = metrics.today.completed;
    final (nextTitle, nextWhen) = _nextSession(metrics.weekStrip);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (completed != null) ...[
          WorkoutDoneView(
            nextTitle: nextTitle,
            nextWhen: nextWhen,
            onViewWorkout:
                _pastWorkouts.isEmpty ? null : _openSelectedWorkoutDetail,
          ),
          // Finished: the changes read as a receipt under the session, with
          // anything still waiting on the user above it.
          if (_needsApproval.isNotEmpty)
            NeedsApprovalLine(
              suggestions: _needsApproval,
              onTap: _openNeedsApproval,
            ),
          if (_whatChanged.isNotEmpty) TrainInsight(events: _whatChanged),
        ] else ...[
          // No spacer: the eyebrow sets the gap above the title, the same
          // gap every other day of the week gets.
          TodayWorkoutCard(
            summary: metrics.today,
            rows: TodayWorkoutContent.rows(metrics),
            // Still to train: the same changes compress to one line, so they
            // never become a second list beside today's. A pending approval
            // outranks a report of what already happened — it is the only
            // one of the two the user has to answer.
            updatedLine: _needsApproval.isNotEmpty
                ? NeedsApprovalLine(
                    suggestions: _needsApproval,
                    onTap: _openNeedsApproval,
                  )
                : _whatChanged.isEmpty
                    ? null
                    : WhatChangedLine(
                        events: _whatChanged,
                        onTap: () =>
                            showWhatChangedSheet(context, _whatChanged),
                      ),
          ),
        ],
      ],
    );
  }

  Future<void> _openNeedsApproval() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    await showNeedsApprovalSheet(
      context,
      _needsApproval,
      onApprove: (suggestion) => _progressionService.approveSuggestion(
        userId: userId,
        suggestion: suggestion,
      ),
      onDismiss: (suggestion) => _progressionService.dismissSuggestion(
        userId: userId,
        suggestion: suggestion,
      ),
    );
    if (!mounted) return;
    // Approving rewrites the lift's target, so today's card has to be rebuilt
    // from fresh progress rows either way.
    await _loadHomeData();
  }

  Future<void> _openPastWorkout(PastWorkout workout) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PastWorkoutDetailView(workout: workout),
      ),
    );
    await _loadHomeData();
  }

  Future<void> _openSelectedWorkoutDetail() async {
    final workout = _workoutForDate(_devClockService.now()) ??
        (_pastWorkouts.isEmpty ? null : _pastWorkouts.first);
    if (workout == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PastWorkoutDetailView(workout: workout),
      ),
    );
    await _loadHomeData();
  }

  /// The next training session after today and how far off it is, walking the
  /// program cycle forward from today (wrapping into the next cycle). Returns
  /// (null, null) when the cycle has no training day.
  (String?, String?) _nextSession(HomeWeekStripData weekStrip) {
    final days = weekStrip.days;
    final currentIndex = days.indexWhere((day) => day.isCurrent);
    if (currentIndex < 0) return (null, null);

    for (var offset = 1; offset <= days.length; offset++) {
      final day = days[(currentIndex + offset) % days.length];
      if (day.sessionType == TrainingSessionType.rest) continue;
      final title = _sessionTitle(day.sessionType);
      final when = offset == 1 ? 'tomorrow' : 'in $offset days';
      return (title, when);
    }
    return (null, null);
  }

  String _sessionTitle(TrainingSessionType type) {
    switch (type) {
      case TrainingSessionType.fullBody:
        return 'Full Body';
      case TrainingSessionType.push:
        return 'Push Day';
      case TrainingSessionType.pull:
        return 'Pull Day';
      case TrainingSessionType.upper:
        return 'Upper Day';
      case TrainingSessionType.lower:
        return 'Lower Day';
      case TrainingSessionType.rest:
        return 'Recovery';
    }
  }
}

class _TrainSnapshot {
  final DailyTrainingRecommendation recommendation;
  final HomeDashboardMetrics metrics;

  /// The day the tab is reading, resolved in the ribbon's window.
  final PlannedScheduleDay selectedDay;

  /// The dated run of days across the top.
  final List<HomeWeekStripDay> ribbonDays;

  /// Where a missed selected day's session now sits, when the plan says.
  final DateTime? rescheduledTo;

  final DateTime now;

  const _TrainSnapshot({
    required this.recommendation,
    required this.metrics,
    required this.selectedDay,
    required this.ribbonDays,
    this.rescheduledTo,
    required this.now,
  });

  bool get isViewingToday => selectedDay.isToday;
}
