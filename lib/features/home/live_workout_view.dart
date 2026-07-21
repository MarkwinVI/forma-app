import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_progression_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../../data/services/workout_rest_preferences_service.dart';
import '../exercises/exercise_detail_view.dart';
import 'completed_workout_model.dart';
import 'exercise_switch_selector.dart';
import 'finished_workout_view.dart';
import 'program_day_items.dart';

const _workoutDanger = Color(0xFFF2564A);

/// Rest presets offered by the rest sheet (seconds). "0" means off.
const _restOptions = <int>[0, 30, 60, 90, 120, 150, 180];

class LiveWorkoutView extends StatefulWidget {
  final DailyTrainingRecommendation recommendation;

  const LiveWorkoutView({
    super.key,
    required this.recommendation,
  });

  @override
  State<LiveWorkoutView> createState() => _LiveWorkoutViewState();
}

class _LiveWorkoutViewState extends State<LiveWorkoutView>
    with WidgetsBindingObserver {
  static const _sectionOrder = [
    ExerciseProgramSection.warmup,
    ExerciseProgramSection.skillWork,
    ExerciseProgramSection.mainExercises,
    ExerciseProgramSection.coolDown,
  ];
  final _progressService = ProgressService();
  final _restPreferencesService = WorkoutRestPreferencesService();
  final _programService = TrainingProgramService();
  final _programStoreService = TrainingProgramStoreService();

  late final DateTime _startedAt;
  late List<TrainingRecommendationItem> _sessionItems;
  late Map<String, List<_WorkoutSetDraft>> _setDrafts;
  late Map<String, int> _restSecondsByExercise;
  Map<String, ExerciseStatus> _progressMap = {};
  Map<String, ExerciseProgress> _progressRows = {};
  MasteryTargetSettings _masterySettings = MasteryTargetSettings.defaults;
  _ActiveRestTimer? _activeRestTimer;
  Timer? _ticker;
  Duration _pausedDuration = Duration.zero;
  Duration? _pausedRestRemaining;
  DateTime? _pausedAt;
  bool _isRunning = true;

  /// Inline reps/duration stepper open for one set at a time.
  _OpenStep? _openStep;

  /// Set when the session's exercises or sets no longer match the planned day
  /// — used to offer updating the program plan on finish. Rest-timer changes
  /// deliberately do NOT set this: rest is a standalone per-exercise
  /// preference, saved immediately, and never part of the plan-update prompt.
  bool _planEdited = false;

  /// Exercises added or swapped in as standalone lifts this session; they are
  /// written to the plan as single exercises, not skill-path progressions.
  final Set<String> _singleExerciseIds = {};

  String? _toast;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startedAt = DateTime.now();
    _sessionItems = List.of(widget.recommendation.items);
    _setDrafts = {
      for (final item in _sessionItems)
        item.exercise.id: _initialSetDrafts(item),
    };
    _restSecondsByExercise = {
      for (final item in _sessionItems) item.exercise.id: 0,
    };
    _loadProgressMap();
    _loadRestPreferences();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final shouldClearRest = _isRunning &&
          _activeRestTimer != null &&
          _activeRestRemainingSeconds() <= 0;
      if (!_isRunning && !shouldClearRest) return;
      if (shouldClearRest) {
        SystemSound.play(SystemSoundType.alert);
      }
      setState(() {
        if (shouldClearRest) {
          _activeRestTimer = null;
          _pausedRestRemaining = null;
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  Future<void> _loadRestPreferences() async {
    final stored = await _restPreferencesService.loadRestIntervals();
    if (!mounted) return;

    setState(() {
      _restSecondsByExercise = {
        for (final item in _sessionItems)
          item.exercise.id: stored[item.exercise.id] ?? 0,
      };
    });
  }

  Future<void> _loadProgressMap() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    try {
      final progress = await _progressService.fetchAll(userId);
      MasteryTargetSettings masteryTargets = MasteryTargetSettings.defaults;
      try {
        masteryTargets = (await _programStoreService.fetchProgramLogic(userId))
                ?.masteryTargets ??
            MasteryTargetSettings.defaults;
      } catch (_) {
        // Defaults are fine; targets are still coherent, just unpersonalized.
      }
      if (!mounted) return;

      setState(() {
        _progressRows = {
          for (final item in progress) item.exerciseId: item,
        };
        _progressMap = {
          for (final item in progress) item.exerciseId: item.status,
        };
        _masterySettings = masteryTargets;
        // Ladder targets arrived after the initial drafts were built from
        // defaults — rebuild any exercise the user hasn't logged or edited
        // yet so the shown targets match their stored progression state.
        if (!_planEdited) {
          _setDrafts = {
            for (final item in _sessionItems)
              item.exercise.id: (_setDrafts[item.exercise.id]
                          ?.any((set) => set.hasData) ??
                      false)
                  ? _setDrafts[item.exercise.id]!
                  : _initialSetDrafts(item),
          };
        }
      });
    } catch (error, stackTrace) {
      // Keep replacement usable with local fallbacks if progress can't load.
      debugPrint('Failed to load exercise progress: $error\n$stackTrace');
    }
  }

  // ── Session clock ─────────────────────────────────────────────────

  String _formatElapsed() {
    final elapsed = _elapsedDuration();
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }

    return '${elapsed.inMinutes}:${twoDigits(seconds)}';
  }

  Duration _elapsedDuration() {
    final end = _isRunning ? DateTime.now() : (_pausedAt ?? DateTime.now());
    return end.difference(_startedAt) - _pausedDuration;
  }

  int _activeRestRemainingSeconds() {
    final activeRestTimer = _activeRestTimer;
    if (activeRestTimer == null) return 0;
    if (!_isRunning && _pausedRestRemaining != null) {
      return _pausedRestRemaining!.inSeconds;
    }

    final remainingMs =
        activeRestTimer.endsAt.difference(DateTime.now()).inMilliseconds;
    if (remainingMs <= 0) return 0;
    return (remainingMs + 999) ~/ 1000;
  }

  bool get _hasActiveRestTimer =>
      _activeRestTimer != null && _activeRestRemainingSeconds() > 0;

  int get _totalSetCount => _sessionItems.fold(
        0,
        (sum, item) => sum + _setsFor(item).length,
      );

  int get _completedSetCount => _sessionItems.fold(
        0,
        (sum, item) =>
            sum + _setsFor(item).where((set) => set.completed).length,
      );

  String _formatSessionSubtitle() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final startedAt = _startedAt;
    return '${weekdays[startedAt.weekday - 1]}, '
        '${months[startedAt.month - 1]} ${startedAt.day}';
  }

  // ── Set drafts ────────────────────────────────────────────────────

  List<TrainingRecommendationItem> _itemsForSection(
    ExerciseProgramSection section,
  ) {
    return _sessionItems
        .where((item) => item.exercise.programSection == section)
        .toList();
  }

  /// Prescribed target for an item: the progression ladder target (stored
  /// state, else 3 × 6 / 3 × 10s, clamped to the live mastery target) for
  /// progression items, the catalog formula for standalone exercises.
  ExerciseTarget _prescribedTargetFor(TrainingRecommendationItem item) {
    if (item.isProgression) {
      return ExerciseProgressionService.currentTargetForExercise(
        item.exercise,
        progress: _progressRows[item.exercise.id],
        masterySettings: _masterySettings,
      );
    }
    return ExerciseTarget(
      sets: ExerciseProgressionService.setCountForExercise(item.exercise),
      value: ExerciseProgressionService.targetValueForExercise(item.exercise),
    );
  }

  List<_WorkoutSetDraft> _initialSetDrafts(TrainingRecommendationItem item) {
    final target = _prescribedTargetFor(item);
    return List.generate(
      target.sets,
      (index) => _WorkoutSetDraft(
        number: index + 1,
        target: target.value,
        previousLabel: '–',
      ),
    );
  }

  List<_WorkoutSetDraft> _setsFor(TrainingRecommendationItem item) {
    return _setDrafts[item.exercise.id] ?? _initialSetDrafts(item);
  }

  void _replaceSets(
    TrainingRecommendationItem item,
    List<_WorkoutSetDraft> sets,
  ) {
    setState(() {
      _setDrafts = {
        ..._setDrafts,
        item.exercise.id: sets,
      };
    });
  }

  void _toggleSessionRunning() {
    setState(() {
      if (_isRunning) {
        _pausedAt = DateTime.now();
        if (_activeRestTimer != null) {
          _pausedRestRemaining =
              Duration(seconds: _activeRestRemainingSeconds());
        }
        _isRunning = false;
        return;
      }

      if (_pausedAt != null) {
        _pausedDuration += DateTime.now().difference(_pausedAt!);
      }
      if (_activeRestTimer != null && _pausedRestRemaining != null) {
        _activeRestTimer = _activeRestTimer!.copyWith(
          endsAt: DateTime.now().add(_pausedRestRemaining!),
        );
        _pausedRestRemaining = null;
      }
      _pausedAt = null;
      _isRunning = true;
    });
  }

  void _toggleSet(TrainingRecommendationItem item, int number) {
    final currentSet = _setsFor(item).firstWhere((set) => set.number == number);
    final shouldComplete = !currentSet.completed;
    final sets = _setsFor(item)
        .map(
          (set) => set.number == number
              ? set.copyWith(completed: shouldComplete)
              : set,
        )
        .toList();

    _replaceSets(item, sets);
    if (shouldComplete) {
      setState(() => _openStep = null);
      _startRestTimer(item);
    } else if (_activeRestTimer?.exerciseId == item.exercise.id) {
      _clearActiveRestTimer();
    }
  }

  void _toggleStepFor(TrainingRecommendationItem item, int number) {
    final set = _setsFor(item).firstWhere((set) => set.number == number);
    if (set.completed) return;

    setState(() {
      final current = _openStep;
      _openStep = current != null &&
              current.exerciseId == item.exercise.id &&
              current.number == number
          ? null
          : _OpenStep(exerciseId: item.exercise.id, number: number);
    });
  }

  void _stepSetTarget(TrainingRecommendationItem item, int number, int delta) {
    final isTimed = _isTimedExercise(item.exercise);
    final step = isTimed ? 5 : 1;
    final low = isTimed ? 5 : 1;
    final high = isTimed ? 600 : 99;

    final sets = _setsFor(item)
        .map(
          (set) => set.number == number
              ? set.copyWith(
                  target: (set.target + delta * step).clamp(low, high),
                  isEdited: true,
                )
              : set,
        )
        .toList();

    _replaceSets(item, sets);
  }

  void _addSet(TrainingRecommendationItem item) {
    final sets = _setsFor(item);
    final target =
        sets.isEmpty ? _prescribedTargetFor(item).value : sets.last.target;

    _planEdited = true;
    _replaceSets(
      item,
      [
        ...sets,
        _WorkoutSetDraft(
          number: sets.length + 1,
          target: target,
          previousLabel: '–',
        ),
      ],
    );
  }

  void _removeSet(TrainingRecommendationItem item, int number) {
    final sets = _setsFor(item);
    if (sets.length <= 1) return;

    final remaining = sets.where((set) => set.number != number).toList();
    _planEdited = true;
    setState(() => _openStep = null);
    _replaceSets(
      item,
      [
        for (var index = 0; index < remaining.length; index++)
          remaining[index].copyWith(number: index + 1),
      ],
    );
  }

  // ── Session roster ────────────────────────────────────────────────

  void _replaceSessionItems(List<TrainingRecommendationItem> items) {
    setState(() {
      _sessionItems = items;
    });
  }

  void _addExerciseToSession(Exercise exercise) {
    final nextItem = TrainingRecommendationItem(
      track: _trackForExercise(exercise),
      exercise: exercise,
      status: _progressMap[exercise.id] ?? ExerciseStatus.inactive,
      sourceCategory: exercise.category,
      sourceSkillCategoryId: exercise.skillCategoryId,
    );

    _planEdited = true;
    _singleExerciseIds.add(exercise.id);
    setState(() {
      _sessionItems = [..._sessionItems, nextItem];
      _setDrafts = {
        ..._setDrafts,
        nextItem.exercise.id:
            _setDrafts[nextItem.exercise.id] ?? _initialSetDrafts(nextItem),
      };
      _restSecondsByExercise = {
        ..._restSecondsByExercise,
        nextItem.exercise.id: _restSecondsByExercise[nextItem.exercise.id] ?? 0,
      };
    });
    _showToast('${exercise.name} added');
  }

  void _removeExerciseFromSession(TrainingRecommendationItem item) {
    _planEdited = true;
    _replaceSessionItems(
      _sessionItems
          .where((candidate) => candidate.exercise.id != item.exercise.id)
          .toList(),
    );
    if (_activeRestTimer?.exerciseId == item.exercise.id) {
      _clearActiveRestTimer();
    }
    _showToast('${item.exercise.name} removed');
  }

  void _replaceItemInSession(
    TrainingRecommendationItem currentItem,
    TrainingRecommendationItem nextItem,
  ) {
    final replacementId = nextItem.exercise.id;

    _planEdited = true;
    setState(() {
      _sessionItems = [
        for (final item in _sessionItems)
          if (item.exercise.id == currentItem.exercise.id) nextItem else item,
      ];
      _setDrafts = {
        ..._setDrafts,
        replacementId: _setDrafts[replacementId] ?? _initialSetDrafts(nextItem),
      };
      _restSecondsByExercise = {
        ..._restSecondsByExercise,
        replacementId: _restSecondsByExercise[replacementId] ?? 0,
      };
      if (_activeRestTimer?.exerciseId == currentItem.exercise.id) {
        _activeRestTimer = null;
        _pausedRestRemaining = null;
      }
    });
  }

  void _replaceExerciseInSession(
    TrainingRecommendationItem currentItem,
    Exercise replacement,
  ) {
    final nextItem = TrainingRecommendationItem(
      track: _trackForExercise(replacement),
      exercise: replacement,
      status: currentItem.status,
      sourceCategory: replacement.category,
      sourceSkillCategoryId: replacement.skillCategoryId,
    );

    _singleExerciseIds.add(replacement.id);
    _replaceItemInSession(currentItem, nextItem);
  }

  void _applyReorderedSections(
    Map<ExerciseProgramSection, List<TrainingRecommendationItem>> reordered,
  ) {
    final next = <TrainingRecommendationItem>[];
    for (final section in _sectionOrder) {
      next.addAll(reordered[section] ?? _itemsForSection(section));
    }
    _planEdited = true;
    _replaceSessionItems(next);
    _showToast('Order updated');
  }

  // ── Rest timer ────────────────────────────────────────────────────

  void _startRestTimer(TrainingRecommendationItem item) {
    final restSeconds = _restSecondsByExercise[item.exercise.id] ?? 0;
    if (restSeconds <= 0) return;

    setState(() {
      _activeRestTimer = _ActiveRestTimer(
        exerciseId: item.exercise.id,
        endsAt: DateTime.now().add(Duration(seconds: restSeconds)),
        totalSeconds: restSeconds,
      );
      _pausedRestRemaining = null;
    });
  }

  void _clearActiveRestTimer() {
    setState(() {
      _activeRestTimer = null;
      _pausedRestRemaining = null;
    });
  }

  Future<void> _pickRestInterval(TrainingRecommendationItem item) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RestPickerSheet(
        exerciseName: item.exercise.name,
        currentValue: _restSecondsByExercise[item.exercise.id] ?? 0,
      ),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _restSecondsByExercise = {
        ..._restSecondsByExercise,
        item.exercise.id: selected,
      };
      if (selected <= 0 && _activeRestTimer?.exerciseId == item.exercise.id) {
        _activeRestTimer = null;
        _pausedRestRemaining = null;
      }
    });
    // Persist the rest duration for this exercise right away — it sticks
    // regardless of whether the workout is ever saved, and it never marks the
    // session as plan-edited, so it won't trigger the "update your plan" prompt.
    await _restPreferencesService.saveRestInterval(item.exercise.id, selected);
  }

  // ── Toast ─────────────────────────────────────────────────────────

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toast = message);
    _toastTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _toast = null);
    });
  }

  // ── Finish flow ───────────────────────────────────────────────────

  CompletedWorkout _buildCompletedWorkout() {
    final exercises = <CompletedWorkoutExercise>[];

    for (final item in _sessionItems) {
      final isTimed = _isTimedExercise(item.exercise);
      final completedSets = _setsFor(item)
          .where((set) => set.hasData)
          .map(
            (set) => CompletedWorkoutSet(
              number: set.number,
              value: set.target,
              isTimed: isTimed,
            ),
          )
          .toList();

      if (completedSets.isEmpty) continue;

      final prescribed = _prescribedTargetFor(item);
      exercises.add(
        CompletedWorkoutExercise(
          item: item,
          sets: completedSets,
          targetSets: prescribed.sets,
          targetValue: prescribed.value,
        ),
      );
    }

    return CompletedWorkout(
      sessionLabel: widget.recommendation.sessionLabel,
      sessionType: widget.recommendation.sessionType,
      startedAt: _startedAt,
      finishedAt: DateTime.now(),
      exercises: exercises,
    );
  }

  Future<void> _finishWorkout() async {
    final workout = _buildCompletedWorkout();

    if (workout.exercises.isEmpty) {
      await _showNoDataSheet();
      return;
    }

    final save = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FinishWorkoutSheet(
        title: widget.recommendation.sessionLabel,
        dateLabel: _formatSessionSubtitle(),
        elapsedLabel: _formatElapsed(),
        completedSets: _completedSetCount,
        totalSets: _totalSetCount,
        exerciseCount: _sessionItems.length,
      ),
    );
    if (save != true || !mounted) return;

    await _maybeUpdateDayPlan();
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FinishedWorkoutView(workout: workout),
      ),
    );
  }

  /// When the session drifted from the planned day (sets added or removed,
  /// exercises added, removed, replaced, or reordered), offer to write the
  /// changes back to the program plan for this day.
  Future<void> _maybeUpdateDayPlan() async {
    if (!_planEdited) return;
    if (widget.recommendation.isRestDay) return;
    // Blank workouts don't come from a planned day — nothing to update.
    if (widget.recommendation.items.isEmpty) return;

    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    TrainingProgramLogicSnapshot? logic;
    try {
      logic = await _programStoreService.fetchProgramLogic(userId);
    } catch (error, stackTrace) {
      debugPrint('Failed to load program for plan update: $error\n$stackTrace');
      return;
    }
    if (logic == null || !mounted) return;

    final dayTitle = programDayTitle(widget.recommendation.sessionType);
    final update = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _UpdateDayPlanSheet(dayTitle: dayTitle),
    );
    if (update != true || !mounted) return;

    try {
      await _saveDayPlan(userId, logic);
      if (mounted) _showToast('$dayTitle day plan updated');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update $dayTitle day: $error')),
      );
    }
  }

  Future<void> _saveDayPlan(
    String userId,
    TrainingProgramLogicSnapshot logic,
  ) async {
    final sessionType = widget.recommendation.sessionType;
    final config = Map<String, dynamic>.from(
      logic.program.variationRules['session_items_v1'] as Map? ?? const {},
    );
    final planItems = ProgramSessionPlan.loadDay(
      service: _programService,
      sessionItemsConfig: config,
      programType: logic.program.programType,
      sessionType: sessionType,
      branchSelections: logic.branchSelections,
      progressMap: _progressMap,
    );

    final unmatched = List.of(planItems);
    ProgramDayItem? takeMatch(TrainingRecommendationItem item) {
      var index = unmatched.indexWhere(
        (plan) => plan.exerciseId == item.exercise.id,
      );
      if (index < 0 && item.sourceSkillCategoryId.isNotEmpty) {
        index = unmatched.indexWhere(
          (plan) =>
              plan.kind == ProgramDayItemKind.progression &&
              plan.skillCategoryId == item.sourceSkillCategoryId,
        );
      }
      if (index < 0) return null;
      return unmatched.removeAt(index);
    }

    final updated = <ProgramDayItem>[];
    for (final item in _sessionItems) {
      final sets = _setsFor(item).length;
      final match = takeMatch(item);
      if (match != null) {
        updated.add(match.copyWith(sets: sets));
        continue;
      }

      final asProgression = !_singleExerciseIds.contains(item.exercise.id) &&
          item.exercise.skillCategoryId.isNotEmpty &&
          SkillCategoryCatalog.findById(item.sourceSkillCategoryId) != null;
      updated.add(
        ProgramDayItem(
          id: newProgramItemId(),
          kind: asProgression
              ? ProgramDayItemKind.progression
              : ProgramDayItemKind.exercise,
          name: item.exercise.name,
          skillCategoryId: asProgression ? item.sourceSkillCategoryId : null,
          branchId: asProgression ? item.exercise.branchId : null,
          exerciseId: item.exercise.id,
          sets: sets,
        ),
      );
    }

    config[sessionType.dbValue] = ProgramSessionPlan.serializeDay(updated);

    await _programStoreService.updateProgramLogic(
      userId: userId,
      programType: logic.program.programType,
      branchSelections: logic.branchSelections,
      repGoalProfile: logic.repGoalProfile,
      sessionItemsConfig: config,
    );
  }

  Future<void> _showNoDataSheet() async {
    final discard = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ConfirmSheet(
        title: 'No sets logged yet',
        message: 'Log at least one set before finishing, '
            'or discard this workout.',
        confirmLabel: 'Discard workout',
        cancelLabel: 'Keep training',
      ),
    );
    if (discard != true || !mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _confirmLeaveWorkout() async {
    final discard = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ConfirmSheet(
        title: 'Leave workout?',
        message: 'This session isn’t saved yet — leaving now discards '
            'everything you logged.',
        confirmLabel: 'Discard workout',
        cancelLabel: 'Keep training',
      ),
    );
    if (discard != true || !mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── Exercise actions ──────────────────────────────────────────────

  void _openExerciseDetail(TrainingRecommendationItem item) {
    openExerciseDetailView<void>(
      context,
      exercise: item.exercise,
      skillCategoryId: item.sourceSkillCategoryId,
    );
  }

  Future<void> _openExerciseHistory(TrainingRecommendationItem item) async {
    await openExerciseDetailView<void>(
      context,
      exercise: item.exercise,
      skillCategoryId: item.sourceSkillCategoryId,
      initialTab: ExerciseDetailTab.history,
    );
  }

  Future<void> _openReorderExercises() async {
    final sections = _visibleSections();
    if (sections.fold<int>(0, (sum, entry) => sum + entry.items.length) < 2) {
      return;
    }

    final reordered = await Navigator.of(context).push<
        Map<ExerciseProgramSection, List<TrainingRecommendationItem>>>(
      MaterialPageRoute(
        builder: (_) => _ReorderExercisesPage(sections: sections),
      ),
    );
    if (reordered == null || !mounted) return;
    _applyReorderedSections(reordered);
  }

  Future<void> _openReplaceExercise(TrainingRecommendationItem item) async {
    final selection = await Navigator.of(context).push<ExerciseSwitchChoice>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ExerciseSwitchChooserPage(
          title: 'Switch Item',
          description:
              'Replace this item with a progression path or a standalone exercise.',
        ),
      ),
    );
    if (!mounted || selection == null) return;

    if (selection == ExerciseSwitchChoice.progression) {
      final replacement =
          await Navigator.of(context).push<TrainingRecommendationItem>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _ReplaceProgressionView(
            currentItem: item,
            progressMap: _progressMap,
          ),
        ),
      );
      if (replacement == null || !mounted) return;
      _replaceItemInSession(item, replacement);
      return;
    }

    if (selection != ExerciseSwitchChoice.exercise) return;

    final replacement = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ExercisePickerPage(
          title: 'Switch exercise',
          subtitle: 'Replaces ${item.exercise.name}',
          excludedIds: {item.exercise.id},
        ),
      ),
    );
    if (replacement == null || !mounted) return;
    _replaceExerciseInSession(item, replacement);
  }

  Future<void> _openAddExercise() async {
    final existingIds = _sessionItems.map((item) => item.exercise.id).toSet();
    final addition = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ExercisePickerPage(
          title: 'Add exercise',
          subtitle: 'Added to the end of today’s session',
          excludedIds: existingIds,
        ),
      ),
    );
    if (addition == null || !mounted) return;
    _addExerciseToSession(addition);
  }

  Future<void> _openExerciseActions(TrainingRecommendationItem item) async {
    final canReorder = _sessionItems.length > 1;
    final action = await showModalBottomSheet<_ExerciseAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseMenuSheet(
        item: item,
        targetLabel: _targetSummary(item),
        canReorder: canReorder,
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _ExerciseAction.howToPerform:
        _openExerciseDetail(item);
        break;
      case _ExerciseAction.history:
        await _openExerciseHistory(item);
        break;
      case _ExerciseAction.reorderExercises:
        await _openReorderExercises();
        break;
      case _ExerciseAction.replaceExercise:
        await _openReplaceExercise(item);
        break;
      case _ExerciseAction.removeExercise:
        _removeExerciseFromSession(item);
        break;
    }
  }

  String _targetSummary(TrainingRecommendationItem item) {
    final sets = _setsFor(item);
    if (sets.isEmpty) return item.track.label;
    final isTimed = _isTimedExercise(item.exercise);
    final value = sets.first.target;
    final valueLabel = isTimed ? '${value}s hold' : '$value reps';
    return '${item.track.label} · ${sets.length} × $valueLabel';
  }

  List<_SectionEntry> _visibleSections() {
    return _sectionOrder
        .map(
          (section) =>
              _SectionEntry(section: section, items: _itemsForSection(section)),
        )
        .where((entry) => entry.items.isNotEmpty)
        .toList();
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;
    final visibleSections = _visibleSections();
    final restRemaining = _activeRestRemainingSeconds();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _WorkoutHeader(
                  title: widget.recommendation.sessionLabel,
                  subtitle:
                      '${_formatSessionSubtitle()} · $_completedSetCount/$_totalSetCount sets',
                  elapsed: _formatElapsed(),
                  isRunning: _isRunning,
                  progress: _totalSetCount == 0
                      ? 0
                      : _completedSetCount / _totalSetCount,
                  onToggleRunning: _toggleSessionRunning,
                  onFinish: _finishWorkout,
                  onCollapse: _confirmLeaveWorkout,
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      _hasActiveRestTimer ? 110 + bottomSafePadding : 40,
                    ),
                    children: [
                      if (visibleSections.isEmpty)
                        _EmptyWorkoutState(onAddExercise: _openAddExercise)
                      else
                        for (final entry in visibleSections) ...[
                          SectionHeader(
                            title: entry.section.label,
                            sub: '${entry.items.length} '
                                'exercise${entry.items.length == 1 ? '' : 's'}',
                          ),
                          for (var i = 0; i < entry.items.length; i++) ...[
                            if (i > 0) const SizedBox(height: 14),
                            _WorkoutExerciseCard(
                              key: ValueKey(entry.items[i].exercise.id),
                              item: entry.items[i],
                              sets: _setsFor(entry.items[i]),
                              isTimed: _isTimedExercise(entry.items[i].exercise),
                              targetLabel: _targetSummary(entry.items[i]),
                              restSeconds: _restSecondsByExercise[
                                      entry.items[i].exercise.id] ??
                                  0,
                              openStepNumber: _openStep?.exerciseId ==
                                      entry.items[i].exercise.id
                                  ? _openStep!.number
                                  : null,
                              onToggleSet: (number) =>
                                  _toggleSet(entry.items[i], number),
                              onToggleStep: (number) =>
                                  _toggleStepFor(entry.items[i], number),
                              onStepTarget: (number, delta) =>
                                  _stepSetTarget(entry.items[i], number, delta),
                              onRemoveSet: (number) =>
                                  _removeSet(entry.items[i], number),
                              onAddSet: () => _addSet(entry.items[i]),
                              onRestTap: () => _pickRestInterval(entry.items[i]),
                              onMenu: () => _openExerciseActions(entry.items[i]),
                              onOpenDetail: () =>
                                  _openExerciseDetail(entry.items[i]),
                            ),
                          ],
                        ],
                      if (visibleSections.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _AddExerciseButton(onTap: _openAddExercise),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_hasActiveRestTimer)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24 + bottomSafePadding,
                child: Center(
                  child: _RestCountdownPill(
                    label: _formatCountdownLabel(restRemaining),
                    onSkip: _clearActiveRestTimer,
                  ),
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              top: 74,
              child: IgnorePointer(
                child: AnimatedSlide(
                  offset: _toast == null ? const Offset(0, -0.3) : Offset.zero,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: _toast == null ? 0 : 1,
                    duration: const Duration(milliseconds: 240),
                    child: Center(child: _WorkoutToast(message: _toast ?? '')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionEntry {
  final ExerciseProgramSection section;
  final List<TrainingRecommendationItem> items;

  const _SectionEntry({required this.section, required this.items});
}

class _OpenStep {
  final String exerciseId;
  final int number;

  const _OpenStep({required this.exerciseId, required this.number});
}

// ── Header ────────────────────────────────────────────────────────────

class _WorkoutHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String elapsed;
  final bool isRunning;
  final double progress;
  final VoidCallback onToggleRunning;
  final VoidCallback onFinish;
  final VoidCallback onCollapse;

  const _WorkoutHeader({
    required this.title,
    required this.subtitle,
    required this.elapsed,
    required this.isRunning,
    required this.progress,
    required this.onToggleRunning,
    required this.onFinish,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
            child: Row(
              children: [
                Pressable(
                  onTap: onCollapse,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Pressable(
                  onTap: onToggleRunning,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PulsingDot(active: isRunning),
                        const SizedBox(width: 7),
                        Text(
                          elapsed,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  onTap: onFinish,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Finish',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 2,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.05)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                    color: AppColors.accentPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final bool active;

  const _PulsingDot({required this.active});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
      lowerBound: 0.3,
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.active ? AppColors.accentPrimary : AppColors.textMuted,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Exercise card ─────────────────────────────────────────────────────

class _WorkoutExerciseCard extends StatelessWidget {
  final TrainingRecommendationItem item;
  final List<_WorkoutSetDraft> sets;
  final bool isTimed;
  final String targetLabel;
  final int restSeconds;
  final int? openStepNumber;
  final void Function(int number) onToggleSet;
  final void Function(int number) onToggleStep;
  final void Function(int number, int delta) onStepTarget;
  final void Function(int number) onRemoveSet;
  final VoidCallback onAddSet;
  final VoidCallback onRestTap;
  final VoidCallback onMenu;
  final VoidCallback onOpenDetail;

  const _WorkoutExerciseCard({
    super.key,
    required this.item,
    required this.sets,
    required this.isTimed,
    required this.targetLabel,
    required this.restSeconds,
    required this.openStepNumber,
    required this.onToggleSet,
    required this.onToggleStep,
    required this.onStepTarget,
    required this.onRemoveSet,
    required this.onAddSet,
    required this.onRestTap,
    required this.onMenu,
    required this.onOpenDetail,
  });

  int get _doneCount => sets.where((set) => set.completed).length;
  bool get _allDone => sets.isNotEmpty && _doneCount == sets.length;

  String _valueLabel(_WorkoutSetDraft set) =>
      isTimed ? '${set.target}s' : '${set.target}';

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      clip: true,
      child: Column(
        children: [
          Pressable(
            onTap: onOpenDetail,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 14, 13),
              child: Row(
                children: [
                  IconTile(
                    icon: programPatternIcon(item.exercise.category),
                    size: 42,
                    tint: _doneCount > 0,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.exercise.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.16,
                                ),
                              ),
                            ),
                            if (_allDone) ...[
                              const SizedBox(width: 7),
                              Container(
                                width: 17,
                                height: 17,
                                decoration: const BoxDecoration(
                                  color: AppColors.greenSoft,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 11,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          targetLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pressable(
                    onTap: onMenu,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.surface2,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        size: 17,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Rest timer row
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Pressable(
              onTap: onRestTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 11, 14, 11),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 15,
                      color: restSeconds > 0
                          ? AppColors.accentPrimary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Rest timer',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      _formatRestLabel(restSeconds),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: restSeconds > 0
                            ? AppColors.accentPrimary
                            : AppColors.textMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 17,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Column labels
          Container(
            height: 32,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: _SetGridRow(
              leading: const Text('SET', style: _columnLabelStyle),
              middle: const Text('LAST', style: _columnLabelStyle),
              value: Center(
                child: Text(
                  isTimed ? 'TIME' : 'REPS',
                  style: _columnLabelStyle,
                ),
              ),
              trailing: const SizedBox.shrink(),
            ),
          ),
          // Set rows
          for (final set in sets) ...[
            _buildSetRow(context, set),
            if (openStepNumber == set.number && !set.completed)
              _buildStepper(set),
          ],
          // Add set
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Pressable(
              onTap: onAddSet,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 19,
                      height: 19,
                      decoration: const BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add_rounded,
                        size: 13,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Add set',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _columnLabelStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 1.1,
  );

  Widget _buildSetRow(BuildContext context, _WorkoutSetDraft set) {
    final open = openStepNumber == set.number && !set.completed;

    final row = Container(
      height: 52,
      decoration: BoxDecoration(
        color: open ? AppColors.cardHighlight : Colors.transparent,
        border: const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: _SetGridRow(
        leading: Text(
          '${set.number}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: set.completed ? AppColors.textMuted : AppColors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        middle: Text(
          set.previousLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        value: Pressable(
          onTap: () => onToggleStep(set.number),
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: set.completed ? AppColors.accentSoft : AppColors.surface2,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: open ? AppColors.accentPrimary : Colors.transparent,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _valueLabel(set),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: set.completed
                    ? AppColors.accentPrimary
                    : AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        trailing: Align(
          alignment: Alignment.centerRight,
          child: Pressable(
            onTap: () => onToggleSet(set.number),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color:
                    set.completed ? AppColors.accentPrimary : Colors.transparent,
                shape: BoxShape.circle,
                border: set.completed
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                        width: 2,
                      ),
              ),
              alignment: Alignment.center,
              child: set.completed
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );

    if (sets.length <= 1) return row;

    return Dismissible(
      key: ValueKey('dismiss-${item.exercise.id}-${set.number}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: _workoutDanger.withValues(alpha: 0.9),
        child: const Icon(
          Icons.delete_outline_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onRemoveSet(set.number),
      child: row,
    );
  }

  Widget _buildStepper(_WorkoutSetDraft set) {
    Widget stepButton(IconData icon, VoidCallback onTap) {
      return Pressable(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.surface2,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: AppColors.textPrimary),
        ),
      );
    }

    return Container(
      color: AppColors.cardHighlight,
      padding: const EdgeInsets.fromLTRB(52, 2, 58, 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isTimed ? 'Adjust duration' : 'Adjust reps',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            children: [
              stepButton(
                Icons.remove_rounded,
                () => onStepTarget(set.number, -1),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  _valueLabel(set),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              stepButton(
                Icons.add_rounded,
                () => onStepTarget(set.number, 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shared 4-column grid used by the set header and set rows:
/// set number · last session · value · check.
class _SetGridRow extends StatelessWidget {
  final Widget leading;
  final Widget middle;
  final Widget value;
  final Widget trailing;

  const _SetGridRow({
    required this.leading,
    required this.middle,
    required this.value,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 16, 0),
      child: Row(
        children: [
          SizedBox(width: 30, child: leading),
          const SizedBox(width: 10),
          Expanded(child: middle),
          const SizedBox(width: 10),
          SizedBox(width: 64, child: value),
          const SizedBox(width: 10),
          SizedBox(width: 32, child: trailing),
        ],
      ),
    );
  }
}

// ── Add exercise ──────────────────────────────────────────────────────

class _AddExerciseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddExerciseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.09),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 21,
              height: 21,
              decoration: const BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 14,
                color: AppColors.accentPrimary,
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              'Add exercise',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-page single-exercise picker — same pattern as the program day
/// editor's lift picker. Pops with the chosen [Exercise].
class _ExercisePickerPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final Set<String> excludedIds;

  const _ExercisePickerPage({
    required this.title,
    required this.subtitle,
    required this.excludedIds,
  });

  @override
  State<_ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<_ExercisePickerPage> {
  String _query = '';

  /// Lowercase and drop separators so "pullup" matches "Pull-Up" / "Pull Up".
  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  List<Exercise> get _results {
    final tokens = _query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map(_normalize)
        .where((token) => token.isNotEmpty)
        .toList();

    final exercises = ExerciseCatalog.all().where((exercise) {
      if (widget.excludedIds.contains(exercise.id)) return false;
      if (tokens.isEmpty) return true;
      final haystack = _normalize(
        '${exercise.name} ${programPatternLabel(exercise.category)}',
      );
      return tokens.every(haystack.contains);
    }).toList();

    final queryNorm = _normalize(_query);
    int rank(Exercise exercise) =>
        queryNorm.isNotEmpty && _normalize(exercise.name).startsWith(queryNorm)
            ? 0
            : 1;
    exercises.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return a.name.compareTo(b.name);
    });
    return exercises;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 30,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              widget.subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => _query = value),
                        autofocus: false,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        cursorColor: AppColors.accentPrimary,
                        decoration: const InputDecoration(
                          hintText: 'Search exercises…',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          _query.trim().isEmpty
                              ? 'Everything from the library is already in '
                                  'this workout.'
                              : 'No exercises match “${_query.trim()}”.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final exercise = results[index];
                        return Pressable(
                          onTap: () => Navigator.of(context).pop(exercise),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                IconTile(
                                  icon: programPatternIcon(exercise.category),
                                  size: 40,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          letterSpacing: -0.15,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        '${programPatternLabel(exercise.category)}'
                                        ' · ${_difficultyLabel(exercise.difficulty)}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 15,
                                    color: AppColors.accentPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheets ────────────────────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  final List<Widget> children;

  const _SheetShell({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final bool danger;
  final bool enabled;
  final bool withDivider;
  final VoidCallback onTap;

  const _SheetRow({
    required this.label,
    this.danger = false,
    this.enabled = true,
    this.withDivider = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Container(
        decoration: BoxDecoration(
          border: withDivider
              ? const Border(top: BorderSide(color: AppColors.divider))
              : null,
        ),
        child: Pressable(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: danger ? _workoutDanger : AppColors.textPrimary,
                      letterSpacing: -0.15,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseMenuSheet extends StatelessWidget {
  final TrainingRecommendationItem item;
  final String targetLabel;
  final bool canReorder;

  const _ExerciseMenuSheet({
    required this.item,
    required this.targetLabel,
    required this.canReorder,
  });

  @override
  Widget build(BuildContext context) {
    void pick(_ExerciseAction action) => Navigator.of(context).pop(action);

    return _SheetShell(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
          child: Row(
            children: [
              IconTile(
                icon: programPatternIcon(item.exercise.category),
                size: 42,
                tint: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.17,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      targetLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.surface2,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SurfaceCard(
          clip: true,
          child: Column(
            children: [
              _SheetRow(
                label: 'How to perform',
                onTap: () => pick(_ExerciseAction.howToPerform),
              ),
              _SheetRow(
                label: 'History',
                withDivider: true,
                onTap: () => pick(_ExerciseAction.history),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          clip: true,
          child: Column(
            children: [
              _SheetRow(
                label: 'Reorder exercises',
                enabled: canReorder,
                onTap: () => pick(_ExerciseAction.reorderExercises),
              ),
              _SheetRow(
                label: 'Replace exercise',
                withDivider: true,
                onTap: () => pick(_ExerciseAction.replaceExercise),
              ),
              _SheetRow(
                label: 'Remove exercise',
                danger: true,
                withDivider: true,
                onTap: () => pick(_ExerciseAction.removeExercise),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RestPickerSheet extends StatelessWidget {
  final String exerciseName;
  final int currentValue;

  const _RestPickerSheet({
    required this.exerciseName,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    final options = List<int>.from(_restOptions);
    if (!options.contains(currentValue)) {
      options
        ..add(currentValue)
        ..sort();
    }

    return _SheetShell(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rest timer',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.17,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$exerciseName · starts after each logged set',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SurfaceCard(
          clip: true,
          child: Column(
            children: [
              for (var i = 0; i < options.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i > 0
                        ? const Border(
                            top: BorderSide(color: AppColors.divider),
                          )
                        : null,
                  ),
                  child: Pressable(
                    onTap: () => Navigator.of(context).pop(options[i]),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 15,
                            color: options[i] == 0
                                ? AppColors.textMuted
                                : options[i] == currentValue
                                    ? AppColors.accentPrimary
                                    : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatRestLabel(options[i]),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: options[i] == currentValue
                                    ? AppColors.accentPrimary
                                    : AppColors.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          if (options[i] == currentValue)
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.accentPrimary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinishWorkoutSheet extends StatelessWidget {
  final String title;
  final String dateLabel;
  final String elapsedLabel;
  final int completedSets;
  final int totalSets;
  final int exerciseCount;

  const _FinishWorkoutSheet({
    required this.title,
    required this.dateLabel,
    required this.elapsedLabel,
    required this.completedSets,
    required this.totalSets,
    required this.exerciseCount,
  });

  @override
  Widget build(BuildContext context) {
    final missing = totalSets - completedSets;

    return _SheetShell(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Finish workout?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.38,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$title · $dateLabel',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: _SheetStat(label: 'DURATION', value: elapsedLabel),
              ),
              Expanded(
                child: _SheetStat(
                  label: 'SETS',
                  value: '$completedSets/$totalSets',
                ),
              ),
              Expanded(
                child: _SheetStat(label: 'EXERCISES', value: '$exerciseCount'),
              ),
            ],
          ),
        ),
        if (missing > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
            child: Text(
              '$missing set${missing == 1 ? ' isn’t' : 's aren’t'} '
              'logged yet — unlogged sets won’t count toward your '
              'progress.',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.amber,
                height: 1.5,
              ),
            ),
          ),
        const SizedBox(height: 16),
        PillButton(
          label: 'Save workout',
          onTap: () => Navigator.of(context).pop(true),
        ),
        Center(
          child: Pressable(
            onTap: () => Navigator.of(context).pop(false),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 15, 20, 2),
              child: Text(
                'Keep training',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetStat extends StatelessWidget {
  final String label;
  final String value;

  const _SheetStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.19,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _UpdateDayPlanSheet extends StatelessWidget {
  final String dayTitle;

  const _UpdateDayPlanSheet({required this.dayTitle});

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update your $dayTitle day?',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.38,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You changed the exercises or sets this session. Apply the '
                'same changes to your plan so every $dayTitle day matches.',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PillButton(
          label: 'Update $dayTitle day',
          onTap: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: 10),
        PillButton(
          label: 'Keep current plan',
          tonal: true,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.38,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Pressable(
          onTap: () => Navigator.of(context).pop(true),
          child: Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _workoutDanger,
              borderRadius: BorderRadius.circular(26),
            ),
            alignment: Alignment.center,
            child: Text(
              confirmLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
        Center(
          child: Pressable(
            onTap: () => Navigator.of(context).pop(false),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 2),
              child: Text(
                cancelLabel,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Rest countdown & toast ────────────────────────────────────────────

class _RestCountdownPill extends StatelessWidget {
  final String label;
  final VoidCallback onSkip;

  const _RestCountdownPill({
    required this.label,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 9, 10, 9),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x8C000000),
            offset: Offset(0, 12),
            blurRadius: 32,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 15,
            color: AppColors.accentPrimary,
          ),
          const SizedBox(width: 10),
          Text(
            'Rest · $label',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          Pressable(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutToast extends StatelessWidget {
  final String message;

  const _WorkoutToast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            offset: Offset(0, 12),
            blurRadius: 32,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 15, color: AppColors.green),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reorder page ──────────────────────────────────────────────────────

class _ReorderExercisesPage extends StatefulWidget {
  final List<_SectionEntry> sections;

  const _ReorderExercisesPage({required this.sections});

  @override
  State<_ReorderExercisesPage> createState() => _ReorderExercisesPageState();
}

class _ReorderExercisesPageState extends State<_ReorderExercisesPage> {
  late final Map<ExerciseProgramSection, List<TrainingRecommendationItem>>
      _items;

  @override
  void initState() {
    super.initState();
    _items = {
      for (final entry in widget.sections)
        entry.section: List.of(entry.items),
    };
  }

  bool get _dirty {
    for (final entry in widget.sections) {
      final current = _items[entry.section]!;
      for (var i = 0; i < current.length; i++) {
        if (current[i].exercise.id != entry.items[i].exercise.id) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _dirty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 30,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reorder exercises',
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Drag ≡ to change the order',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  for (final entry in widget.sections) ...[
                    SectionHeader(title: entry.section.label),
                    SurfaceCard(
                      clip: true,
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: _items[entry.section]!.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final list = _items[entry.section]!;
                            final item = list.removeAt(oldIndex);
                            list.insert(newIndex, item);
                          });
                        },
                        proxyDecorator: (child, _, __) => Material(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(14),
                          child: child,
                        ),
                        itemBuilder: (context, index) {
                          final item = _items[entry.section]![index];
                          return Container(
                            key: ValueKey(item.exercise.id),
                            height: 60,
                            decoration: BoxDecoration(
                              border: index > 0
                                  ? const Border(
                                      top:
                                          BorderSide(color: AppColors.divider),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                IconTile(
                                  icon: programPatternIcon(
                                    item.exercise.category,
                                  ),
                                  size: 38,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.exercise.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          letterSpacing: -0.15,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        item.track.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      size: 19,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.fromLTRB(2, 14, 2, 0),
                    child: Text(
                      'Exercises stay inside their block — skill work always '
                      'comes before the main lifts.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: PillButton(
                label: dirty ? 'Save order' : 'No changes yet',
                onTap: dirty ? () => Navigator.of(context).pop(_items) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────

class _EmptyWorkoutState extends StatelessWidget {
  final VoidCallback onAddExercise;

  const _EmptyWorkoutState({
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: SurfaceCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No exercises queued for this session.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            PillButton(
              label: 'Add exercise',
              icon: Icons.add_rounded,
              onTap: onAddExercise,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Replace with progression (two-step picker) ────────────────────────

class _ReplaceProgressionView extends StatefulWidget {
  final TrainingRecommendationItem currentItem;
  final Map<String, ExerciseStatus> progressMap;

  const _ReplaceProgressionView({
    required this.currentItem,
    required this.progressMap,
  });

  @override
  State<_ReplaceProgressionView> createState() =>
      _ReplaceProgressionViewState();
}

class _ReplaceProgressionViewState extends State<_ReplaceProgressionView> {
  late final List<SkillCategory> _categories;
  late String _selectedCategoryId;
  String? _selectedBranchId;
  bool _showBranches = false;

  @override
  void initState() {
    super.initState();
    final currentCategory = SkillCategoryCatalog.findById(
      widget.currentItem.sourceSkillCategoryId,
    );
    final trackCategories = SkillCategoryCatalog.forTrack(
      widget.currentItem.sourceCategory,
    );
    _categories = _orderedCategories(trackCategories, currentCategory);
    _selectedCategoryId = _categories.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final category = _categories.firstWhere(
      (item) => item.id == _selectedCategoryId,
      orElse: () => _categories.first,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 30,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (_showBranches) {
              setState(() {
                _showBranches = false;
                _selectedBranchId = null;
              });
              return;
            }
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _showBranches ? 'Pick a branch' : 'Pick a progression',
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              _showBranches
                  ? '${category.title} · step 2 of 2'
                  : 'Step 1 of 2',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _showBranches
                    ? 'Each branch is a different path through the '
                        '${category.title.toLowerCase()} tree.'
                    : 'Choose the skill tree you want this item to follow.',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _showBranches
                    ? _buildBranchList(category)
                    : _buildCategoryList(),
              ),
              if (_showBranches) ...[
                const SizedBox(height: 12),
                PillButton(
                  label: 'Set progression',
                  onTap: _selectedBranchId == null
                      ? null
                      : () => Navigator.of(context).pop(
                            _progressionReplacement(
                              widget.currentItem,
                              category,
                              _selectedBranchId!,
                              widget.progressMap,
                            ),
                          ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final item = _categories[index];
        return Pressable(
          onTap: () {
            setState(() {
              _selectedCategoryId = item.id;
              _selectedBranchId = null;
              _showBranches = true;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectableBranches(item).length} branches · '
                        '${item.track.label}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBranchList(SkillCategory category) {
    final branches = _selectableBranches(category);

    return ListView.builder(
      itemCount: branches.length,
      itemBuilder: (context, index) {
        final branch = branches[index];
        final selected = _selectedBranchId == branch.id;
        return Pressable(
          onTap: () => setState(() => _selectedBranchId = branch.id),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.accentSoft : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    selected ? AppColors.accentPrimary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _branchTitle(category, branch.id),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _branchRange(category, branch.id),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 20,
                  color: selected
                      ? AppColors.accentPrimary
                      : AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<SkillCategory> _orderedCategories(
    List<SkillCategory> trackCategories,
    SkillCategory? currentCategory,
  ) {
    final categories = <SkillCategory>[
      if (currentCategory != null) currentCategory,
      ...trackCategories.where((item) => item.id != currentCategory?.id),
    ];

    if (categories.isNotEmpty) return categories;

    return [
      currentCategory ??
          SkillCategoryCatalog.defaultForTrack(
              widget.currentItem.sourceCategory),
    ];
  }

  List<SkillCategoryBranch> _selectableBranches(SkillCategory category) {
    return category.branches
        .where(
          (branch) => category.pathFor(branch.id).isNotEmpty,
        )
        .toList();
  }
}

// ── Drafts & helpers ──────────────────────────────────────────────────

class _WorkoutSetDraft {
  final int number;
  final int target;
  final String previousLabel;
  final bool completed;
  final bool isEdited;

  const _WorkoutSetDraft({
    required this.number,
    required this.target,
    required this.previousLabel,
    this.completed = false,
    this.isEdited = false,
  });

  bool get hasData => (completed || isEdited) && target > 0;

  _WorkoutSetDraft copyWith({
    int? number,
    int? target,
    String? previousLabel,
    bool? completed,
    bool? isEdited,
  }) {
    return _WorkoutSetDraft(
      number: number ?? this.number,
      target: target ?? this.target,
      previousLabel: previousLabel ?? this.previousLabel,
      completed: completed ?? this.completed,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}

String _formatRestLabel(int seconds) {
  if (seconds <= 0) return 'Off';
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  if (remainder == 0) return '$minutes min';
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

String _formatCountdownLabel(int seconds) {
  final safeSeconds = seconds.clamp(0, 59 * 60 + 59);
  final minutes = safeSeconds ~/ 60;
  final remainder = safeSeconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

// Timed detection lives in ExerciseProgressionService so the targets shown
// in a workout are exactly the targets that advance progression.
bool _isTimedExercise(Exercise exercise) =>
    ExerciseProgressionService.isTimedExercise(exercise);

String _difficultyLabel(int difficulty) {
  if (difficulty <= 1) return 'Beginner';
  if (difficulty <= 3) return 'Intermediate';
  return 'Advanced';
}

TrainingTrack _trackForExercise(Exercise exercise) {
  switch (exercise.category) {
    case ExerciseCategory.skill:
      return TrainingTrack.skillWork;
    case ExerciseCategory.verticalPush:
      return TrainingTrack.verticalPush;
    case ExerciseCategory.horizontalPush:
      return TrainingTrack.horizontalPush;
    case ExerciseCategory.verticalPull:
      return TrainingTrack.verticalPull;
    case ExerciseCategory.horizontalPull:
      return TrainingTrack.horizontalPull;
    case ExerciseCategory.core:
      return TrainingTrack.core;
    case ExerciseCategory.squat:
      return TrainingTrack.squat;
    case ExerciseCategory.hinge:
      return TrainingTrack.hinge;
  }
}

TrainingRecommendationItem _progressionReplacement(
  TrainingRecommendationItem currentItem,
  SkillCategory category,
  String branchId,
  Map<String, ExerciseStatus> progressMap,
) {
  final exercise = _currentExerciseForProgression(
        skillCategoryId: category.id,
        branchId: branchId,
        progressMap: progressMap,
        programSection: currentItem.exercise.programSection,
      ) ??
      _copyExerciseForSection(
        _firstExerciseForBranch(category, branchId) ?? currentItem.exercise,
        programSection: currentItem.exercise.programSection,
      );

  return TrainingRecommendationItem(
    track: _trackForExercise(exercise),
    exercise: exercise,
    status: progressMap[exercise.id] ?? ExerciseStatus.inactive,
    sourceCategory: category.track,
    sourceSkillCategoryId: category.id,
    progressionExerciseIds: category.pathFor(branchId),
  );
}

Exercise? _currentExerciseForProgression({
  required String skillCategoryId,
  required String branchId,
  required Map<String, ExerciseStatus> progressMap,
  required ExerciseProgramSection programSection,
}) {
  final category = SkillCategoryCatalog.findById(skillCategoryId);
  final exerciseIds = category?.pathFor(branchId) ?? const <String>[];
  final exercises =
      exerciseIds.map(ExerciseCatalog.findById).whereType<Exercise>().toList();

  if (exercises.isEmpty) return null;

  for (final exercise in exercises) {
    if (progressMap[exercise.id] == ExerciseStatus.active) {
      return _copyExerciseForSection(
        exercise,
        programSection: programSection,
      );
    }
  }

  for (final exercise in exercises) {
    if (progressMap[exercise.id] != ExerciseStatus.mastered) {
      return _copyExerciseForSection(
        exercise,
        programSection: programSection,
      );
    }
  }

  return _copyExerciseForSection(
    exercises.last,
    programSection: programSection,
  );
}

Exercise? _firstExerciseForBranch(SkillCategory category, String branchId) {
  final exerciseIds = category.pathFor(branchId);
  for (final exerciseId in exerciseIds) {
    final exercise = ExerciseCatalog.findById(exerciseId);
    if (exercise != null) return exercise;
  }
  return null;
}

Exercise _copyExerciseForSection(
  Exercise exercise, {
  required ExerciseProgramSection programSection,
}) {
  return Exercise(
    id: exercise.id,
    category: exercise.category,
    skillCategoryId: exercise.skillCategoryId,
    branchId: exercise.branchId,
    name: exercise.name,
    description: exercise.description,
    difficulty: exercise.difficulty,
    treeOrder: exercise.treeOrder,
    prerequisiteIds: exercise.prerequisiteIds,
    programSection: programSection,
    imageUrl: exercise.imageUrl,
  );
}

String _branchTitle(SkillCategory category, String pathId) {
  final label = _pathLabel(category, pathId);
  if (label.toLowerCase() == 'main') {
    return category.title;
  }
  return '$label ${category.title}';
}

String _pathLabel(SkillCategory category, String pathId) {
  for (final branch in category.branches) {
    if (branch.id == pathId) return branch.label;
  }

  return pathId
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _branchRange(SkillCategory category, String branchId) {
  final steps = category.pathFor(branchId);
  if (steps.isEmpty) return 'No steps';
  final first = ExerciseCatalog.findById(steps.first)?.name ?? steps.first;
  final last = ExerciseCatalog.findById(steps.last)?.name ?? steps.last;
  return '$first → $last';
}

enum _ExerciseAction {
  howToPerform,
  history,
  reorderExercises,
  replaceExercise,
  removeExercise,
}

class _ActiveRestTimer {
  final String exerciseId;
  final DateTime endsAt;
  final int totalSeconds;

  const _ActiveRestTimer({
    required this.exerciseId,
    required this.endsAt,
    required this.totalSeconds,
  });

  _ActiveRestTimer copyWith({
    String? exerciseId,
    DateTime? endsAt,
    int? totalSeconds,
  }) {
    return _ActiveRestTimer(
      exerciseId: exerciseId ?? this.exerciseId,
      endsAt: endsAt ?? this.endsAt,
      totalSeconds: totalSeconds ?? this.totalSeconds,
    );
  }
}
