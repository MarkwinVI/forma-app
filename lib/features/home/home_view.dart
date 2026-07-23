import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/progression_event_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/progression_event_service.dart';
import '../../data/services/skill_track_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../settings/settings_view.dart';
import 'alternate_workout_options_view.dart';
import 'home_dashboard_metrics.dart';
import 'home_empty_state.dart';
import 'live_workout_view.dart';
import 'program_setup_view.dart';
import 'session_overview_view.dart';
import 'widgets/rest_day_view.dart';
import 'widgets/today_workout_card.dart';
import 'widgets/week_strip.dart';
import 'widgets/what_changed_card.dart';

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
  final _exerciseLogService = ExerciseLogService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();
  final _progressionEventService = ProgressionEventService();
  final _skillTrackService = SkillTrackService();

  bool _loading = true;
  bool _hasProgram = true;
  Map<String, ExerciseStatus> _progressMap = {};
  Map<String, ExerciseProgress> _progressEntries = {};
  List<PastWorkout> _pastWorkouts = const [];
  List<ProgressionEvent> _whatChanged = const [];
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
    // Lane view bridges skill tracks into lane-keyed consumers (dashboards,
    // config fallback); the actual session items come from the tracks.
    final branchSelections = {
      ..._trainingProgramService.defaultBranchSelections(),
      ...snapshot.branchSelections,
      ..._trainingProgramService.laneSelectionsFromTracks(_skillTracks),
    };
    final sessionItemsConfig = _sessionItemsConfigFor(snapshot.program);
    final schedule = HomeDashboardMetricsCalculator.resolveSchedule(
      cycle: _trainingProgramService.scheduleCycleFor(
        programType: programType,
        scheduleVariant: scheduleVariant,
      ),
      nextStepIndex: snapshot.state.nextStepIndex,
      nextSessionType: snapshot.state.nextSessionType,
      lastWorkoutAt:
          _pastWorkouts.isEmpty ? null : _pastWorkouts.first.loggedAt,
    );
    final recommendation = _trainingProgramService.buildToday(
      progressMap: _progressMap,
      programType: programType,
      sessionType: schedule.effectiveSessionType,
      branchSelections: branchSelections,
      sessionItemsConfig: sessionItemsConfig,
      skillTracks: _skillTracks,
    );

    return _TrainSnapshot(
      recommendation: recommendation,
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
        goalSkillIds: snapshot.program.goalSkillIds,
        frequencyPerWeek: snapshot.program.frequencyPerWeek,
        masterySettings: MasteryTargetSettings.fromVariationRules(
          snapshot.program.variationRules,
        ),
      ),
    );
  }

  Map<String, dynamic> _sessionItemsConfigFor(UserTrainingProgram program) {
    final raw = program.variationRules['session_items_v1'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
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

    await _trainingProgramStoreService.updateProgramLogic(
      userId: userId,
      programType: result.split,
      // Goal skills pick their branch from day one; every other track
      // starts on its default.
      branchSelections: {
        ..._trainingProgramService.defaultBranchSelections(),
        ..._trainingProgramService.branchSelectionsForGoals(result.skillIds),
      },
      repGoalProfile: RepGoalProfile.balanced,
      sessionItemsConfig: const {},
      frequencyPerWeek: result.daysPerWeek,
      setupAnswers: result.toMap(),
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

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsView()),
    );
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
                      onOpenSettings: _openSettings,
                    ),
                  )
                : snapshot.metrics.today.isRestDay
                    // Recovery day fills the viewport and never scrolls — the
                    // illustration flexes so the footer stays above the fold.
                    ? _buildRestBody(snapshot)
                    : RefreshIndicator(
                        color: AppColors.accentPrimary,
                        backgroundColor: AppColors.surface,
                        onRefresh: _loadHomeData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                            child: _buildContent(snapshot),
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildRestBody(_TrainSnapshot snapshot) {
    final metrics = snapshot.metrics;
    final (nextTitle, nextWhen) = _nextSession(metrics.weekStrip);
    // Reserve room for the shell's floating nav bar (it extends behind the
    // body), so the "train something else" link isn't hidden by it.
    final navReserve = MediaQuery.of(context).padding.bottom + 74;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, navReserve),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WeekStrip(weekStrip: metrics.weekStrip),
          Expanded(
            child: RestDayView(
              nextTitle: nextTitle,
              nextWhen: nextWhen,
              onTrainSomethingElse: () =>
                  _openAlternateWorkoutOptions(snapshot.recommendation),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(_TrainSnapshot snapshot) {
    final metrics = snapshot.metrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WeekStrip(weekStrip: metrics.weekStrip),
        const SizedBox(height: 16),
        TodayWorkoutCard(
          summary: metrics.today,
          subtitle: TodayWorkoutContent.subtitle(metrics),
          rows: TodayWorkoutContent.rows(metrics),
          onStart: () => _startWorkout(snapshot.recommendation),
          onTrainSomethingElse: () =>
              _openAlternateWorkoutOptions(snapshot.recommendation),
        ),
        if (_whatChanged.isNotEmpty)
          TrainInsight(
            events: _whatChanged,
            volumeTrend: _volumeTrend(metrics.exercisePerformance),
          ),
      ],
    );
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

  /// Total training volume per recent session (oldest → newest), summed across
  /// today's exercises and right-aligned to the most recent session, for the
  /// insight sparkline.
  List<int> _volumeTrend(List<HomeExercisePerformance> performance) {
    var maxLen = 0;
    for (final perf in performance) {
      if (perf.history.length > maxLen) maxLen = perf.history.length;
    }
    if (maxLen < 2) return const [];

    final totals = List<int>.filled(maxLen, 0);
    for (final perf in performance) {
      final history = perf.history;
      final offset = maxLen - history.length;
      for (var i = 0; i < history.length; i++) {
        totals[offset + i] += history[i];
      }
    }
    return totals;
  }
}

class _TrainSnapshot {
  final DailyTrainingRecommendation recommendation;
  final HomeDashboardMetrics metrics;

  const _TrainSnapshot({
    required this.recommendation,
    required this.metrics,
  });
}
