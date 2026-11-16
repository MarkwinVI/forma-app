import 'package:flutter/material.dart';

import '../../core/format/dates.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../core/widgets/type_led.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/dev_clock_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/progression_event_service.dart';
import '../../data/services/skill_track_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../../data/services/training_schedule_service.dart';
import '../exercises/exercise_detail_view.dart';
import 'home_dashboard_metrics.dart';
import 'live_workout_view.dart';
import 'quick_session_intro_view.dart';
import 'quick_sessions.dart';
import 'quick_sessions_view.dart';
import 'session_overview_view.dart';
import 'weekly_quota.dart';
import 'widgets/program_day_card.dart';
import 'widgets/program_workout_sheet.dart';
import 'widgets/quick_sessions_section.dart';
import 'widgets/today_workout_card.dart';
import 'widgets/week_widgets.dart';
import '../data/past_workout_detail_view.dart';

/// Train tab — today's workout as a performance list (planned exercises with
/// last result and change vs the previous attempt) plus a coaching tip.
class HomeView extends StatefulWidget {
  final bool isActive;

  const HomeView({
    super.key,
    this.isActive = false,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final _progressService = ProgressService();
  final _devClockService = DevClockService();
  final _exerciseLogService = ExerciseLogService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();
  final _trainingScheduleService = TrainingScheduleService();
  final _skillTrackService = SkillTrackService();
  final _progressionEventService = ProgressionEventService();

  bool _loading = true;
  Map<String, ExerciseStatus> _progressMap = {};
  Map<String, ExerciseProgress> _progressEntries = {};
  List<PastWorkout> _pastWorkouts = const [];

  /// Exercises the program moved the user onto that have not been trained
  /// since — they carry a "Lvl up" or "New" tag in today's list.
  Map<String, TodayRowTag> _rowTags = const {};

  /// True from a workout being saved until the tab has re-read itself.
  bool _refreshingAfterWorkout = false;

  /// The day the tab last read itself on, to notice a new one on resume.
  DateTime? _loadedOn;

  List<SkillTrack> _skillTracks = const [];
  TrainingProgramLogicSnapshot? _logicSnapshot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    workoutSavedSignal.addListener(_onWorkoutSaved);
    _loadHomeData();
  }

  /// Back in the foreground on a later day than the tab last read itself:
  /// what it shows as today is yesterday. Come back to today and re-read.
  /// The same day is left alone — a selected day stays selected.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final loadedOn = _loadedOn;
    if (loadedOn == null) return;
    final today = TrainingScheduleService.dateOnly(_devClockService.now());
    if (TrainingScheduleService.daysBetween(loadedOn, today) == 0) return;
    _loadHomeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    workoutSavedSignal.removeListener(_onWorkoutSaved);
    super.dispose();
  }

  /// A workout was saved — the finish screens are still up. Come back to
  /// today and re-read now, so the tab is already the finished day when the
  /// user returns to it. Until the read lands, the loader stands in for a
  /// day that is about to be wrong.
  void _onWorkoutSaved() {
    if (!mounted) return;
    setState(() => _refreshingAfterWorkout = true);
    _loadHomeData().whenComplete(() {
      if (mounted) setState(() => _refreshingAfterWorkout = false);
    });
  }

  @override
  void didUpdateWidget(covariant HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The shell keeps tabs alive in an IndexedStack, so re-fetch whenever
    // this tab becomes active — a workout logged or the program edited on
    // another tab would otherwise leave the day stale.
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
      _loadedOn = TrainingScheduleService.dateOnly(_devClockService.now());
      final results = await Future.wait([
        _progressService.fetchAll(userId),
        _trainingProgramStoreService.fetchProgramLogic(userId),
        _exerciseLogService.fetchPastWorkouts(userId),
      ]);
      final pastWorkouts = results[2] as List<PastWorkout>;

      // Which of today's exercises are freshly levelled up. Best effort: a
      // failed lookup just means no tags this time round.
      var rowTags = const <String, TodayRowTag>{};
      try {
        rowTags = TodayWorkoutContent.rowTags(
          activations: await _progressionEventService.fetchActivations(userId),
          pastWorkouts: pastWorkouts,
        );
      } catch (error, stackTrace) {
        debugPrint('Failed to load level-ups: $error\n$stackTrace');
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
        _pastWorkouts = pastWorkouts;
        _rowTags = rowTags;
        _skillTracks = skillTracks;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load home data: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _loading = false);
      // With an older read still on screen, the day stays up and the
      // failure is a passing note with a way to try again; with nothing to
      // show, the body itself becomes the error state (see build).
      if (_logicSnapshot != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Couldn't refresh your training data."),
            action: SnackBarAction(label: 'Retry', onPressed: _retryLoad),
          ),
        );
      }
    }
  }

  void _retryLoad() {
    if (!mounted) return;
    setState(() => _loading = true);
    _loadHomeData();
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
    final today = TrainingScheduleService.dateOnly(now);
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
    // The program's rhythm from today: its sessions in order, with the
    // days off its spacing puts between them. The tab reads it as a
    // suggestion — which session is next, whether today is a day off —
    // and never as a commitment: nothing in it can be missed.
    final rhythm = _trainingScheduleService.buildWindow(
      programType: programType,
      frequencyPerWeek: snapshot.program.frequencyPerWeek,
      dayMask: dayMask,
      currentStepIndex: snapshot.state.nextStepIndex,
      currentSessionType: snapshot.state.nextSessionType,
      lastPlannedWorkoutAt: anchorDate,
      lastCompletedSessionType: anchorSessionType,
      completedSessions: completedSessions,
      daysBeforeToday: 0,
      daysAfterToday: 20,
      now: now,
    );
    final trainedToday = _workoutForDate(today, plannedOnly: true);
    final lineUp = [
      for (final day in rhythm.days)
        if (!day.isRestDay &&
            !day.isCompleted &&
            !(day.isToday && trainedToday != null))
          day,
    ];
    final next = lineUp.isEmpty
        ? PlannedScheduleDay(
            date: today,
            sessionType: snapshot.state.nextSessionType,
            stepIndex: snapshot.state.nextStepIndex,
          )
        : lineUp.first;
    final schedule = HomeScheduleResolution(
      effectiveStepIndex: next.stepIndex,
      effectiveSessionType: next.sessionType,
      todayPosition: scheduleWindow.days.indexWhere((day) => day.isToday),
      completedToday: trainedToday != null,
    );
    // Planned for today whichever day the rhythm had it on: started
    // today is where it is trained.
    final recommendation = _trainingProgramService.buildToday(
      progressMap: _progressMap,
      programType: programType,
      sessionType: next.sessionType,
      branchSelections: branchSelections,
      sessionItemsConfig: sessionItemsConfig,
      skillTracks: _skillTracks,
      equipment: programEquipment(snapshot.program.variationRules),
      plannedDate: today,
      plannedStepIndex: next.stepIndex,
    );
    final masterySettings = MasteryTargetSettings.fromVariationRules(
      snapshot.program.variationRules,
    );

    final programWorkouts = [
      for (final workout in _pastWorkouts)
        if (workout.affectsSchedule) workout,
    ]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final quota = WeeklyQuota.resolve(
      sessionDates: [for (final workout in programWorkouts) workout.loggedAt],
      target: snapshot.program.frequencyPerWeek,
      now: now,
    );
    final loggedThisWeek = [
      for (final workout in programWorkouts)
        if (WeeklyQuota.weekStartOf(workout.loggedAt)
            .isAtSameMomentAs(quota.weekStart))
          workout,
    ];
    // Sessions counted here that were trained last week, past its count.
    final carried = quota.done - loggedThisWeek.length;
    final before = [
      for (final workout in programWorkouts)
        if (workout.loggedAt.isBefore(quota.weekStart)) workout,
    ];
    final doneThisWeek = [
      if (carried > 0)
        ...before.skip(before.length > carried ? before.length - carried : 0),
      ...loggedThisWeek,
    ];
    final sunday = TrainingScheduleService.addDays(quota.weekStart, 6);

    return _TrainSnapshot(
      recommendation: recommendation,
      quota: quota,
      trainedToday: trainedToday,
      restToday: trainedToday == null && rhythm.today.isRestDay,
      nextInDays: lineUp.isEmpty
          ? null
          : TrainingScheduleService.daysBetween(today, lineUp.first.date),
      doneThisWeek: doneThisWeek,
      weekAhead: [
        for (final day in rhythm.days)
          if (!day.date.isAfter(sunday) &&
              !day.isCompleted &&
              !(day.isToday && trainedToday != null))
            day,
      ],
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
        completedWorkout: trainedToday,
        now: now,
        masterySettings: masterySettings,
      ),
      now: now,
    );
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

  Future<void> _startWorkout(DailyTrainingRecommendation recommendation) async {
    final openedAt = _devClockService.now();
    // SessionOverviewView is stateless, so its screen view is captured here;
    // LiveWorkoutView reports its own.
    if (recommendation.isRestDay) AnalyticsService.screen('session_overview');
    // The workout flow takes over the whole screen, above the tab bar.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => recommendation.isRestDay
            ? SessionOverviewView(recommendation: recommendation)
            : LiveWorkoutView(recommendation: recommendation),
      ),
    );
    // A saved workout already re-read the tab and brought it back to today,
    // from the finish screen. Anything else that happened in there — a
    // discarded session, a rest-day overview — still deserves a re-read.
    final finished = _pastWorkouts.any(
      (workout) => workout.loggedAt.isAfter(openedAt),
    );
    if (!finished) await _loadHomeData();
  }

  /// The program session ready to be started, by name — what a quick
  /// session's intro promises is untouched — or null once today's is
  /// logged or the week is complete.
  String? _plannedTodayTitle(_TrainSnapshot snapshot) {
    if (snapshot.trainedToday != null || snapshot.quota.isComplete) {
      return null;
    }
    return snapshot.metrics.today.sessionTitle;
  }

  /// A quick session's intro, over the whole screen.
  Future<void> _openSession(
    _TrainSnapshot snapshot,
    QuickSession session,
  ) {
    return showQuickSessionIntro(
      context,
      session: session,
      plannedToday: _plannedTodayTitle(snapshot),
      source: 'train',
    );
  }

  /// "See all": every quick session, and the blank workout under them. It
  /// stays inside the tab, under the tab bar.
  Future<void> _openSessions(_TrainSnapshot snapshot) async {
    AnalyticsService.screen('quick_sessions');
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuickSessionsView(
          plannedToday: _plannedTodayTitle(snapshot),
          onBlankWorkout: () => _startBlankWorkout(snapshot.recommendation),
        ),
      ),
    );
    // A workout may have been logged from there — re-fetch.
    await _loadHomeData();
  }

  /// An empty workout to fill in as it goes. It runs above the tab bar, as
  /// every workout does, and never moves the program's schedule.
  Future<void> _startBlankWorkout(DailyTrainingRecommendation recommendation) {
    final sessionType = recommendation.sessionType == TrainingSessionType.rest
        ? TrainingSessionType.fullBody
        : recommendation.sessionType;
    AnalyticsService.capture('blank_workout_started', properties: {
      'source': 'sessions',
    });
    return Navigator.of(context, rootNavigator: true).push(
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
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _loading ? null : _buildSnapshot();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: _loading || _refreshingAfterWorkout
            ? const Center(child: LoadingIndicator())
            // No day to draw: the read failed, or came back without the
            // program the entry gate saw — either way, Retry.
            : snapshot == null
                ? _LoadFailedState(onRetry: _retryLoad)
                : _buildTab(snapshot),
      ),
    );
  }

  /// The tab: how the week stands across the top, then the next session
  /// in its card, then the quick sessions. One scrolling page with nothing
  /// pinned — the session's actions live in its card.
  Widget _buildTab(_TrainSnapshot snapshot) {
    // No pull-to-refresh: the tab re-reads itself after every workout and
    // every edit.
    return SingleChildScrollView(
      // Attached to the shell's per-tab controller, so re-tapping the tab
      // scrolls back to the top.
      primary: true,
      padding: EdgeInsets.only(top: 4, bottom: _tabBarInset + _tabBarGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: WeekHeader(
              quota: snapshot.quota,
              onSeeUpcoming: () => _openWeekSheet(snapshot),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: _weekCard(snapshot),
          ),
          QuickSessionsSection(
            sessions: QuickSessions.featured,
            onOpen: (session) => _openSession(snapshot, session),
            onSeeAll: () => _openSessions(snapshot),
          ),
        ],
      ),
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

  /// The card under the week: the next session and its Start, a day off
  /// with the next session still within reach, or — with nothing to
  /// start — what was done. Nothing here is ever missed; the week is the
  /// only thing being counted.
  Widget _weekCard(_TrainSnapshot snapshot) {
    final quota = snapshot.quota;
    final trained = snapshot.trainedToday;
    final nextTitle = snapshot.metrics.today.sessionTitle;

    if (trained != null) {
      final left = quota.remaining;
      return RestDayHeight(
        child: ProgramDayCard(
          fillBody: true,
          body: WeekDoneBody(
            fill: true,
            title: 'Done for today',
            line: quota.isComplete
                ? '${trained.title} is logged. That’s the week complete.'
                : '${trained.title} is logged. '
                    '${left == 1 ? 'One more session' : '$left more sessions'} '
                    'this week.',
          ),
          actions: ProgramCardActions(
            label: 'View completed workout',
            quiet: true,
            onPrimary: () => _openPastWorkout(trained),
          ),
        ),
      );
    }

    if (quota.isComplete) {
      final all = quota.target == 1
          ? 'Your session is done.'
          : 'All ${quota.target} sessions done.';
      return RestDayHeight(
        child: ProgramDayCard(
          fillBody: true,
          body: WeekDoneBody(
            fill: true,
            title: 'Week complete',
            line: '$all A new week starts Monday.',
          ),
          actions: ProgramCardActions(
            label: 'Start $nextTitle early',
            quiet: true,
            onPrimary: () {
              AnalyticsService.capture('next_week_started_early');
              _startWorkout(snapshot.recommendation);
            },
          ),
        ),
      );
    }

    if (snapshot.restToday) {
      final days = snapshot.nextInDays;
      return RestDayCard(
        nextTitle: nextTitle,
        nextWhen: days == null || days < 1
            ? null
            : days == 1
                ? 'tomorrow'
                : 'in $days days',
        onStartToday: () {
          AnalyticsService.capture('rest_day_started_next');
          _startWorkout(snapshot.recommendation);
        },
      );
    }

    final rows = _todayRows(snapshot.metrics);
    return ProgramDayCard(
      kicker: 'UP NEXT',
      title: nextTitle,
      body: ProgramPreviewList(rows: rows),
      actions: ProgramCardActions(
        label: 'Start',
        onPrimary: () => _startWorkout(snapshot.recommendation),
        onList: rows.isEmpty ? null : () => _openWorkoutSheet(snapshot),
      ),
    );
  }

  /// "7 exercises · about 35 min".
  String _sessionMeta(HomeTodaySummary summary) {
    final count = summary.exerciseCount;
    return [
      '$count ${count == 1 ? 'exercise' : 'exercises'}',
      if (summary.estimatedDurationMinutes > 0)
        'about ${summary.estimatedDurationMinutes} min',
    ].join(' · ');
  }

  /// The whole of the next session, numbered, with Start at the bottom.
  void _openWorkoutSheet(_TrainSnapshot snapshot) {
    final summary = snapshot.metrics.today;
    final rows = _todayRows(snapshot.metrics);
    showProgramWorkoutSheet(
      context,
      kicker: 'YOUR PROGRAM · UP NEXT',
      title: summary.sessionTitle,
      meta: _sessionMeta(summary),
      rows: [
        for (var i = 0; i < summary.plannedExercises.length; i++)
          ProgramSheetRow(
            exerciseId: summary.plannedExercises[i].exerciseId,
            name: summary.plannedExercises[i].name,
            target: summary.plannedExercises[i].targetLabel,
            tag: i < rows.length ? rows[i].tag : null,
          ),
      ],
      startLabel: 'Start',
      onStart: () => _startWorkout(snapshot.recommendation),
      onRowTap: _openSheetExercise,
    );
  }

  /// "TODAY", "TOMORROW", then the weekday.
  String _dayWord(DateTime date, DateTime today) {
    final distance = TrainingScheduleService.daysBetween(today, date);
    if (distance == 0) return 'TODAY';
    if (distance == 1) return 'TOMORROW';
    return FormaDates.weekdayLong(context, date).toUpperCase();
  }

  /// "See upcoming": the week in order — the sessions done, then the days
  /// still ahead as the program's rhythm lays them out, days off
  /// included.
  void _openWeekSheet(_TrainSnapshot snapshot) {
    AnalyticsService.capture('week_sheet_opened');
    final quota = snapshot.quota;
    final today = TrainingScheduleService.dateOnly(snapshot.now);
    final canStart = snapshot.trainedToday == null;
    var number = 0;
    var nextShown = false;

    final rows = <WeekSessionRow>[
      for (final workout in snapshot.doneThisWeek)
        WeekSessionRow(
          label: workout.loggedAt.isBefore(quota.weekStart)
              ? 'DONE EARLY'
              : 'DONE · '
                  '${FormaDates.weekdayLong(context, workout.loggedAt).toUpperCase()}',
          name: workout.title,
          state: WeekSessionState.done,
          number: ++number,
          onTap: () => _openPastWorkout(workout),
        ),
    ];
    for (final day in snapshot.weekAhead) {
      final word = _dayWord(day.date, today);
      if (day.isRestDay) {
        rows.add(WeekSessionRow(
          label: word,
          name: 'Rest day',
          state: WeekSessionState.rest,
        ));
        continue;
      }
      final isNext = !nextShown;
      nextShown = true;
      rows.add(WeekSessionRow(
        label: isNext ? '$word · UP NEXT' : word,
        name: _sessionTitle(day.sessionType),
        state: isNext ? WeekSessionState.next : WeekSessionState.upcoming,
        number: ++number,
        onTap: isNext && canStart ? () => _openWorkoutSheet(snapshot) : null,
      ));
    }
    // The next session falls past Sunday: it still gets its line.
    if (!nextShown) {
      rows.add(WeekSessionRow(
        label: 'NEXT WEEK',
        name: snapshot.metrics.today.sessionTitle,
        state: WeekSessionState.upcoming,
        number: ++number,
        onTap: canStart ? () => _openWorkoutSheet(snapshot) : null,
      ));
    }

    showWeekSheet(context, quota: quota, rows: rows);
  }

  void _openSheetExercise(ProgramSheetRow row) {
    final exercise = ExerciseCatalog.findById(row.exerciseId);
    if (exercise == null) return;
    openExerciseDetailView<void>(
      context,
      exercise: exercise,
      skillCategoryId:
          exercise.skillCategoryId.isEmpty ? null : exercise.skillCategoryId,
    );
  }

  List<TodayWorkoutRow> _todayRows(HomeDashboardMetrics metrics) {
    return TodayWorkoutContent.rows(
      metrics,
      rowTags: _rowTags,
    );
  }

  Future<void> _openPastWorkout(PastWorkout workout) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PastWorkoutDetailView(workout: workout),
      ),
    );
    await _loadHomeData();
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

/// The tab when today could not be read and there is no older day to fall
/// back on: it says so in the tab's own voice, and Retry re-runs the read.
class _LoadFailedState extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadFailedState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Text('TODAY', style: monoStyle(letterSpacing: 1.6)),
          ),
          const TypeTitle(
            "Couldn't load today",
            sub: 'Your program and history did not come through. '
                'Check your connection and try again.',
          ),
          const SizedBox(height: 24),
          PillButton(label: 'Retry', onTap: onRetry, tonal: true, radius: 14),
        ],
      ),
    );
  }
}

class _TrainSnapshot {
  /// The session next in line, built as it would be trained today.
  final DailyTrainingRecommendation recommendation;
  final HomeDashboardMetrics metrics;

  /// Where the week stands against the program's session count.
  final WeeklyQuota quota;

  /// The program session logged today, if there is one.
  final PastWorkout? trainedToday;

  /// The program's rhythm has today as a day off, and nothing is logged.
  final bool restToday;

  /// How many days off the next session is in that rhythm; 0 when it is
  /// today's.
  final int? nextInDays;

  /// The sessions counted toward this week, oldest first — the ones
  /// logged in it, and before them any started early last week.
  final List<PastWorkout> doneThisWeek;

  /// The rest of this week as the program's rhythm lays it out, today
  /// first: sessions and the days off between them. A suggestion — any
  /// day can be trained.
  final List<PlannedScheduleDay> weekAhead;

  final DateTime now;

  const _TrainSnapshot({
    required this.recommendation,
    required this.metrics,
    required this.quota,
    required this.trainedToday,
    required this.restToday,
    required this.nextInDays,
    required this.doneThisWeek,
    required this.weekAhead,
    required this.now,
  });
}
