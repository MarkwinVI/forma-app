import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/workout_rest_preferences_service.dart';
import '../exercises/exercise_detail_view.dart';
import 'completed_workout_model.dart';
import 'exercise_switch_selector.dart';
import 'finished_workout_view.dart';

const _workoutBg = Color(0xFF000000);
const _workoutCard = Color(0xFF1C1C1E);
const _workoutSurface = Color(0x3D767680);
const _workoutSurfaceBorder = Color(0x80545458);
const _workoutPrimaryText = Color(0xFFFFFFFF);
const _workoutSecondaryText = Color(0x99EBEBF5);
const _workoutTertiaryText = Color(0x4DEBEBF5);
const _workoutAccent = Color(0xFFFF9F0A);
const _workoutAccentSoft = Color(0x29FF9F0A);
const _workoutDone = Color(0xFF30D158);
const _workoutDanger = Color(0xFFFF453A);

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
  static final _restOptions = <int>[
    0,
    for (var seconds = 5; seconds <= 300; seconds += 5) seconds,
  ];
  final _progressService = ProgressService();
  final _restPreferencesService = WorkoutRestPreferencesService();

  late final DateTime _startedAt;
  late List<TrainingRecommendationItem> _sessionItems;
  late Map<String, List<_WorkoutSetDraft>> _setDrafts;
  late Map<String, int> _restSecondsByExercise;
  Map<String, ExerciseStatus> _progressMap = {};
  _ActiveRestTimer? _activeRestTimer;
  Timer? _ticker;
  Duration _pausedDuration = Duration.zero;
  Duration? _pausedRestRemaining;
  DateTime? _pausedAt;
  bool _isRunning = true;

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
      if (!mounted) return;

      setState(() {
        _progressMap = {
          for (final item in progress) item.exerciseId: item.status,
        };
      });
    } catch (error, stackTrace) {
      // Keep replacement usable with local fallbacks if progress can't load.
      debugPrint('Failed to load exercise progress: $error\n$stackTrace');
    }
  }

  String _formatElapsed() {
    final elapsed = _elapsedDuration();
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }

    final totalMinutes = elapsed.inMinutes;
    return '${twoDigits(totalMinutes)}:${twoDigits(seconds)}';
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

  double get _activeRestProgress {
    final activeRestTimer = _activeRestTimer;
    if (activeRestTimer == null || activeRestTimer.totalSeconds <= 0) {
      return 0;
    }

    return (_activeRestRemainingSeconds() / activeRestTimer.totalSeconds).clamp(
      0.0,
      1.0,
    );
  }

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
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final startedAt = _startedAt;
    final dayLabel = weekdays[startedAt.weekday - 1];
    final monthLabel = months[startedAt.month - 1];
    return '$dayLabel, $monthLabel ${startedAt.day}';
  }

  List<TrainingRecommendationItem> _itemsForSection(
    ExerciseProgramSection section,
  ) {
    return _sessionItems
        .where((item) => item.exercise.programSection == section)
        .toList();
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
              ? set.copyWith(
                  completed: shouldComplete,
                )
              : set,
        )
        .toList();

    _replaceSets(item, sets);
    if (shouldComplete) {
      _startRestTimer(item);
    } else if (_activeRestTimer?.exerciseId == item.exercise.id) {
      _clearActiveRestTimer();
    }
  }

  void _changeSetTarget(
    TrainingRecommendationItem item,
    int number,
    int? target,
  ) {
    final sets = _setsFor(item)
        .map(
          (set) => set.number == number
              ? set.copyWith(
                  target: target ?? 0,
                  isEdited: target != null && target > 0,
                )
              : set,
        )
        .toList();

    _replaceSets(item, sets);
  }

  void _addSet(TrainingRecommendationItem item) {
    final sets = _setsFor(item);
    final target = sets.isEmpty ? _defaultTarget(item) : sets.last.target;

    _replaceSets(
      item,
      [
        ...sets,
        _WorkoutSetDraft(
          number: sets.length + 1,
          target: target,
          previousLabel: '-',
        ),
      ],
    );
  }

  void _removeSet(TrainingRecommendationItem item, int number) {
    final sets = _setsFor(item);
    if (sets.length <= 1) return;

    final remaining = sets.where((set) => set.number != number).toList();
    _replaceSets(
      item,
      [
        for (var index = 0; index < remaining.length; index++)
          remaining[index].copyWith(number: index + 1),
      ],
    );
  }

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
  }

  void _removeExerciseFromSession(TrainingRecommendationItem item) {
    _replaceSessionItems(
      _sessionItems
          .where((candidate) => candidate.exercise.id != item.exercise.id)
          .toList(),
    );
    if (_activeRestTimer?.exerciseId == item.exercise.id) {
      _clearActiveRestTimer();
    }
  }

  void _replaceItemInSession(
    TrainingRecommendationItem currentItem,
    TrainingRecommendationItem nextItem,
  ) {
    final replacementId = nextItem.exercise.id;

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

    _replaceItemInSession(currentItem, nextItem);
  }

  void _reorderSectionItems(
    ExerciseProgramSection section,
    List<TrainingRecommendationItem> reorderedSectionItems,
  ) {
    final reordered = <TrainingRecommendationItem>[];
    var sectionCursor = 0;

    for (final item in _sessionItems) {
      if (item.exercise.programSection == section) {
        reordered.add(reorderedSectionItems[sectionCursor]);
        sectionCursor += 1;
      } else {
        reordered.add(item);
      }
    }

    _replaceSessionItems(reordered);
  }

  void _completeTimedSet(
    TrainingRecommendationItem item,
    int number,
    int seconds,
  ) {
    final sets = _setsFor(item)
        .map(
          (set) => set.number == number
              ? set.copyWith(
                  target: seconds,
                  completed: true,
                )
              : set,
        )
        .toList();

    _replaceSets(item, sets);
    _startRestTimer(item);
  }

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

      exercises.add(
        CompletedWorkoutExercise(
          item: item,
          sets: completedSets,
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

  void _finishWorkout() {
    final workout = _buildCompletedWorkout();

    if (workout.exercises.isEmpty) {
      _showNoDataDialog();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FinishedWorkoutView(workout: workout),
      ),
    );
  }

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

  void _adjustActiveRestTimer(int deltaSeconds) {
    final activeRestTimer = _activeRestTimer;
    if (activeRestTimer == null) return;

    final nextSeconds = (_activeRestRemainingSeconds() + deltaSeconds).clamp(
      0,
      15 * 60,
    );
    if (nextSeconds <= 0) {
      _clearActiveRestTimer();
      return;
    }

    setState(() {
      final nextTotalSeconds =
          (activeRestTimer.totalSeconds + deltaSeconds).clamp(
        nextSeconds,
        15 * 60,
      );
      _activeRestTimer = activeRestTimer.copyWith(
        endsAt: DateTime.now().add(Duration(seconds: nextSeconds)),
        totalSeconds: nextTotalSeconds,
      );
      _pausedRestRemaining = _isRunning ? null : Duration(seconds: nextSeconds);
    });
  }

  Future<void> _pickRestInterval(TrainingRecommendationItem item) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final current = _restSecondsByExercise[item.exercise.id] ?? 0;
        return _RestPickerSheet(
          currentValue: current,
          options: _restOptions,
        );
      },
    );

    if (selected == null) return;

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
    await _restPreferencesService.saveRestInterval(item.exercise.id, selected);
  }

  Future<void> _showNoDataDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _workoutCard,
          surfaceTintColor: _workoutCard,
          title: const Text(
            'No data entered',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _workoutPrimaryText,
            ),
          ),
          content: const Text(
            'Add at least one completed set before finishing, or discard this workout.',
            style: TextStyle(
              fontSize: 14,
              color: _workoutSecondaryText,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Return',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _workoutPrimaryText,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.popUntil((route) => route.isFirst);
              },
              child: const Text(
                'Discard workout',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _workoutDanger,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openExerciseDetail(
    TrainingRecommendationItem item,
    Color sectionColor,
  ) {
    openExerciseDetailView<void>(
      context,
      exercise: item.exercise,
      accentColor: sectionColor,
      skillCategoryId: item.sourceSkillCategoryId,
      focusChips: [
        item.sourceCategory.label,
        item.track.label,
        _difficultyLabel(item.exercise.difficulty),
      ],
    );
  }

  Future<void> _openExerciseHistory(TrainingRecommendationItem item) async {
    await openExerciseDetailView<void>(
      context,
      exercise: item.exercise,
      accentColor: _sectionColor(item.exercise.programSection),
      skillCategoryId: item.sourceSkillCategoryId,
      focusChips: [
        item.sourceCategory.label,
        item.track.label,
        _difficultyLabel(item.exercise.difficulty),
      ],
      autoScrollToProgress: true,
    );
  }

  Future<void> _openReorderExercises(ExerciseProgramSection section) async {
    final sectionItems = _itemsForSection(section);
    if (sectionItems.length < 2) return;

    final reordered =
        await showModalBottomSheet<List<TrainingRecommendationItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReorderExercisesSheet(items: sectionItems),
    );
    if (reordered == null || reordered.length != sectionItems.length) return;
    _reorderSectionItems(section, reordered);
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
        builder: (_) => _ReplaceSingleExerciseView(
          currentExerciseId: item.exercise.id,
          section: item.exercise.programSection,
        ),
      ),
    );
    if (replacement == null) return;
    _replaceExerciseInSession(item, replacement);
  }

  Future<void> _openAddExercise() async {
    final addition = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _ReplaceSingleExerciseView(
          currentExerciseId: '',
          section: ExerciseProgramSection.mainExercises,
        ),
      ),
    );
    if (addition == null) return;
    _addExerciseToSession(addition);
  }

  Future<void> _openExerciseActions(
    TrainingRecommendationItem item,
    ExerciseProgramSection section,
    Color sectionColor,
  ) async {
    final action = await showModalBottomSheet<_ExerciseAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseActionSheet(
        exerciseName: item.exercise.name,
        canReorder: _itemsForSection(section).length > 1,
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _ExerciseAction.howToPerform:
        _openExerciseDetail(item, sectionColor);
        break;
      case _ExerciseAction.history:
        await _openExerciseHistory(item);
        break;
      case _ExerciseAction.reorderExercises:
        await _openReorderExercises(section);
        break;
      case _ExerciseAction.replaceExercise:
        await _openReplaceExercise(item);
        break;
      case _ExerciseAction.removeExercise:
        _removeExerciseFromSession(item);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;
    final visibleSections = _sectionOrder
        .map((section) => (section: section, items: _itemsForSection(section)))
        .where((entry) => entry.items.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: _workoutBg,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: keyboardOpen
            ? const _HideKeyboardButton()
            : const SizedBox.shrink(),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _LiveWorkoutTopBar(
                  title: widget.recommendation.sessionLabel,
                  subtitle: _formatSessionSubtitle(),
                  elapsed: _formatElapsed(),
                  isRunning: _isRunning,
                  completedSets: _completedSetCount,
                  totalSets: _totalSetCount,
                  onToggleRunning: _toggleSessionRunning,
                  onFinish: _finishWorkout,
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      8,
                      0,
                      _hasActiveRestTimer ? 120 + bottomSafePadding : 28,
                    ),
                    children: [
                      if (visibleSections.isEmpty)
                        _EmptyWorkoutState(onAddExercise: _openAddExercise)
                      else
                        ...visibleSections.map(
                          (entry) => _LiveSectionBlock(
                            section: entry.section,
                            items: entry.items,
                            setsFor: _setsFor,
                            onToggleSet: _toggleSet,
                            onTargetChanged: _changeSetTarget,
                            onAddSet: _addSet,
                            onRemoveSet: _removeSet,
                            onTimedSetCompleted: _completeTimedSet,
                            restSecondsFor: (item) =>
                                _restSecondsByExercise[item.exercise.id] ?? 0,
                            onRestTap: _pickRestInterval,
                            onOpenActions: _openExerciseActions,
                            onOpenDetail: _openExerciseDetail,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_hasActiveRestTimer)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StickyRestIndicator(
                  remainingSeconds: _activeRestRemainingSeconds(),
                  progress: _activeRestProgress,
                  onSkip: _clearActiveRestTimer,
                  onAdd: () => _adjustActiveRestTimer(15),
                  onSubtract: () => _adjustActiveRestTimer(-15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HideKeyboardButton extends StatelessWidget {
  const _HideKeyboardButton();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'hide-workout-keyboard',
      onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
      backgroundColor: _workoutAccent,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.keyboard_hide_rounded, size: 18),
      label: const Text(
        'Hide keyboard',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LiveWorkoutTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final String elapsed;
  final bool isRunning;
  final int completedSets;
  final int totalSets;
  final VoidCallback onToggleRunning;
  final VoidCallback onFinish;

  const _LiveWorkoutTopBar({
    required this.title,
    required this.subtitle,
    required this.elapsed,
    required this.isRunning,
    required this.completedSets,
    required this.totalSets,
    required this.onToggleRunning,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProgressRing(
            completed: completedSets,
            total: totalSets,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _workoutPrimaryText,
                      letterSpacing: -0.45,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$subtitle · $completedSets/$totalSets sets',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _workoutSecondaryText,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _TimerPill(
            elapsed: elapsed,
            isRunning: isRunning,
            onPressed: onToggleRunning,
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onFinish,
            style: TextButton.styleFrom(
              foregroundColor: _workoutAccent,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            child: const Text(
              'Finish',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _workoutAccent,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  final String elapsed;
  final bool isRunning;
  final VoidCallback onPressed;

  const _TimerPill({
    required this.elapsed,
    required this.isRunning,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: _workoutSurface,
        foregroundColor: _workoutPrimaryText,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isRunning ? _workoutAccent : _workoutTertiaryText,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            elapsed,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _workoutPrimaryText,
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final int completed;
  final int total;

  const _ProgressRing({
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    final ringColor = progress >= 1 ? _workoutDone : _workoutAccent;

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CircularProgressIndicator(
            value: 1,
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(_workoutSurface),
          ),
          CircularProgressIndicator(
            value: progress.clamp(0, 1),
            strokeWidth: 3,
            strokeCap: StrokeCap.round,
            valueColor: AlwaysStoppedAnimation(ringColor),
            backgroundColor: Colors.transparent,
          ),
          Text(
            progress >= 1 ? '✓' : completed.toString(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: progress >= 1 ? _workoutDone : _workoutPrimaryText,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveSectionBlock extends StatelessWidget {
  final ExerciseProgramSection section;
  final List<TrainingRecommendationItem> items;
  final List<_WorkoutSetDraft> Function(TrainingRecommendationItem item)
      setsFor;
  final int Function(TrainingRecommendationItem item) restSecondsFor;
  final void Function(TrainingRecommendationItem item, int number) onToggleSet;
  final void Function(TrainingRecommendationItem item, int number, int? target)
      onTargetChanged;
  final void Function(TrainingRecommendationItem item) onAddSet;
  final void Function(TrainingRecommendationItem item, int number) onRemoveSet;
  final void Function(TrainingRecommendationItem item, int number, int seconds)
      onTimedSetCompleted;
  final Future<void> Function(TrainingRecommendationItem item) onRestTap;
  final void Function(TrainingRecommendationItem item, Color sectionColor)
      onOpenDetail;
  final Future<void> Function(
    TrainingRecommendationItem item,
    ExerciseProgramSection section,
    Color sectionColor,
  ) onOpenActions;

  const _LiveSectionBlock({
    required this.section,
    required this.items,
    required this.setsFor,
    required this.restSecondsFor,
    required this.onToggleSet,
    required this.onTargetChanged,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onTimedSetCompleted,
    required this.onRestTap,
    required this.onOpenDetail,
    required this.onOpenActions,
  });

  @override
  Widget build(BuildContext context) {
    final sectionColor = _sectionColor(section);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  decoration: BoxDecoration(
                    color: sectionColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  section.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _workoutPrimaryText,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '${items.length} ${items.length == 1 ? 'exercise' : 'exercises'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _workoutSecondaryText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const SizedBox(height: 14),
                _LiveExerciseCard(
                  key: ValueKey(items[index].exercise.id),
                  item: items[index],
                  sets: setsFor(items[index]),
                  restSeconds: restSecondsFor(items[index]),
                  sectionColor: sectionColor,
                  onToggleSet: (number) => onToggleSet(
                    items[index],
                    number,
                  ),
                  onTargetChanged: (number, target) => onTargetChanged(
                    items[index],
                    number,
                    target,
                  ),
                  onAddSet: () => onAddSet(items[index]),
                  onRemoveSet: (number) => onRemoveSet(
                    items[index],
                    number,
                  ),
                  onTimedSetCompleted: (number, seconds) => onTimedSetCompleted(
                    items[index],
                    number,
                    seconds,
                  ),
                  onRestTap: () => onRestTap(items[index]),
                  onOpenActions: () => onOpenActions(
                    items[index],
                    section,
                    sectionColor,
                  ),
                  onOpenDetail: () => onOpenDetail(
                    items[index],
                    sectionColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveExerciseCard extends StatefulWidget {
  final TrainingRecommendationItem item;
  final List<_WorkoutSetDraft> sets;
  final int restSeconds;
  final Color sectionColor;
  final void Function(int number) onToggleSet;
  final void Function(int number, int? target) onTargetChanged;
  final VoidCallback onAddSet;
  final void Function(int number) onRemoveSet;
  final void Function(int number, int seconds) onTimedSetCompleted;
  final VoidCallback onRestTap;
  final VoidCallback onOpenActions;
  final VoidCallback onOpenDetail;

  const _LiveExerciseCard({
    super.key,
    required this.item,
    required this.sets,
    required this.restSeconds,
    required this.sectionColor,
    required this.onToggleSet,
    required this.onTargetChanged,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onTimedSetCompleted,
    required this.onRestTap,
    required this.onOpenActions,
    required this.onOpenDetail,
  });

  @override
  State<_LiveExerciseCard> createState() => _LiveExerciseCardState();
}

class _LiveExerciseCardState extends State<_LiveExerciseCard> {
  bool get _isTimed => _isTimedExercise(widget.item.exercise);
  int get _completedCount => widget.sets.where((set) => set.completed).length;
  bool get _allDone =>
      widget.sets.isNotEmpty && _completedCount == widget.sets.length;

  Future<void> _openTimedSetTimer(_WorkoutSetDraft set) async {
    final seconds = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimedSetTimerSheet(
        accentColor: widget.sectionColor,
        exerciseName: widget.item.exercise.name,
        initialTarget: set.target,
        setNumber: set.number,
      ),
    );

    if (seconds == null || !mounted) return;

    widget.onTimedSetCompleted(set.number, seconds);
  }

  String _targetSummary() {
    if (widget.sets.isEmpty) {
      return widget.item.track.label;
    }

    final setTarget = widget.sets.first.target;
    final valueLabel = _isTimed ? '${setTarget}s' : '$setTarget reps';
    return '${widget.item.track.label} · ${widget.sets.length} × $valueLabel';
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.item.exercise;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _workoutCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _allDone
              ? _workoutDone.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onOpenDetail,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
              child: Row(
                children: [
                  _ExerciseTypeBadge(
                    color: widget.sectionColor,
                    isTimed: _isTimed,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _workoutPrimaryText,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _targetSummary(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _workoutSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_completedCount > 0) ...[
                    _ExerciseCompletionPill(
                      completed: _completedCount,
                      total: widget.sets.length,
                      allDone: _allDone,
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    onPressed: widget.onOpenActions,
                    style: IconButton.styleFrom(
                      fixedSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      side: BorderSide(
                        color: _workoutTertiaryText.withValues(alpha: 0.35),
                      ),
                    ),
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: _workoutSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _WorkoutHairline(inset: 16),
          _RestIntervalRow(
            restSeconds: widget.restSeconds,
            onTap: widget.onRestTap,
          ),
          const _WorkoutHairline(inset: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Column(
              children: [
                _SetHeader(
                  label: _isTimed ? 'Seconds' : 'Reps',
                ),
                const _WorkoutHairline(inset: 0),
                for (var i = 0; i < widget.sets.length; i++) ...[
                  Builder(
                    builder: (context) {
                      final set = widget.sets[i];
                      final row = _SetRow(
                        key: ValueKey('${exercise.id}-${set.number}'),
                        set: set,
                        hasTimer: _isTimed,
                        timerColor: widget.sectionColor,
                        onOpenTimer:
                            _isTimed ? () => _openTimedSetTimer(set) : null,
                        onTargetChanged: (target) =>
                            widget.onTargetChanged(set.number, target),
                        onToggle: () => widget.onToggleSet(set.number),
                      );

                      if (widget.sets.length <= 1) {
                        return row;
                      }

                      return Dismissible(
                        key: ValueKey('dismiss-${exercise.id}-${set.number}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _workoutDanger.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) => widget.onRemoveSet(set.number),
                        child: row,
                      );
                    },
                  ),
                  if (i < widget.sets.length - 1)
                    const _WorkoutHairline(inset: 18),
                ],
                const _WorkoutHairline(inset: 0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: widget.onAddSet,
                    style: TextButton.styleFrom(
                      foregroundColor: _workoutAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Add Set',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTypeBadge extends StatelessWidget {
  final Color color;
  final bool isTimed;

  const _ExerciseTypeBadge({
    required this.color,
    required this.isTimed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isTimed ? Icons.timer_outlined : Icons.bar_chart_rounded,
        size: 15,
        color: color,
      ),
    );
  }
}

class _ExerciseCompletionPill extends StatelessWidget {
  final int completed;
  final int total;
  final bool allDone;

  const _ExerciseCompletionPill({
    required this.completed,
    required this.total,
    required this.allDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: allDone ? _workoutDone.withValues(alpha: 0.14) : _workoutSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$completed/$total',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: allDone ? _workoutDone : _workoutSecondaryText,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _WorkoutHairline extends StatelessWidget {
  final double inset;

  const _WorkoutHairline({
    required this.inset,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: inset,
      endIndent: 0,
      color: _workoutSurfaceBorder,
    );
  }
}

class _RestIntervalRow extends StatelessWidget {
  final int restSeconds;
  final VoidCallback onTap;

  const _RestIntervalRow({
    required this.restSeconds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _workoutPrimaryText,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 15,
            color: _workoutSecondaryText,
          ),
          const SizedBox(width: 8),
          const Text(
            'Rest timer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _workoutSecondaryText,
            ),
          ),
          const Spacer(),
          Text(
            _formatRestLabel(restSeconds),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  restSeconds > 0 ? _workoutPrimaryText : _workoutTertiaryText,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestPickerSheet extends StatefulWidget {
  final int currentValue;
  final List<int> options;

  const _RestPickerSheet({
    required this.currentValue,
    required this.options,
  });

  @override
  State<_RestPickerSheet> createState() => _RestPickerSheetState();
}

class _RestPickerSheetState extends State<_RestPickerSheet> {
  late final FixedExtentScrollController _controller;
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.options.indexOf(widget.currentValue);
    _selectedValue =
        initialIndex >= 0 ? widget.options[initialIndex] : widget.options.first;
    _controller = FixedExtentScrollController(
      initialItem: initialIndex >= 0 ? initialIndex : 0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _workoutCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: _workoutSurfaceBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _workoutSecondaryText,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Rest Interval',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _workoutPrimaryText,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(_selectedValue),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _workoutAccent,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 216,
                child: CupertinoTheme(
                  data: const CupertinoThemeData(brightness: Brightness.dark),
                  child: CupertinoPicker(
                    scrollController: _controller,
                    itemExtent: 40,
                    useMagnifier: true,
                    magnification: 1.08,
                    squeeze: 1.15,
                    selectionOverlay:
                        const CupertinoPickerDefaultSelectionOverlay(
                      background: _workoutSurface,
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedValue = widget.options[index];
                      });
                    },
                    children: [
                      for (final option in widget.options)
                        Center(
                          child: Text(
                            _formatRestLabel(option),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: _workoutPrimaryText,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyRestIndicator extends StatelessWidget {
  final int remainingSeconds;
  final double progress;
  final VoidCallback onSkip;
  final VoidCallback onAdd;
  final VoidCallback onSubtract;

  const _StickyRestIndicator({
    required this.remainingSeconds,
    required this.progress,
    required this.onSkip,
    required this.onAdd,
    required this.onSubtract,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottomPadding),
        decoration: BoxDecoration(
          color: _workoutCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: _workoutSurfaceBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rest',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _workoutSecondaryText,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCountdownLabel(remainingSeconds),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _workoutPrimaryText,
                          fontFeatures: [FontFeature.tabularFigures()],
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    _RestActionChip(
                      label: 'Skip',
                      onTap: onSkip,
                    ),
                    _RestActionChip(
                      label: '+15s',
                      onTap: onAdd,
                    ),
                    _RestActionChip(
                      label: '-15s',
                      onTap: onSubtract,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: _workoutSurface,
                valueColor: const AlwaysStoppedAnimation(_workoutAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RestActionChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: _workoutSurface,
        foregroundColor: _workoutPrimaryText,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _workoutPrimaryText,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class _ExerciseActionSheet extends StatelessWidget {
  final String exerciseName;
  final bool canReorder;

  const _ExerciseActionSheet({
    required this.exerciseName,
    required this.canReorder,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionSheetScaffold(
      title: exerciseName,
      children: [
        _ActionSheetGroup(
          children: [
            _ActionSheetRow(
              label: 'How to perform',
              onTap: () =>
                  Navigator.of(context).pop(_ExerciseAction.howToPerform),
            ),
            const _ActionSheetDivider(),
            _ActionSheetRow(
              label: 'History',
              onTap: () => Navigator.of(context).pop(_ExerciseAction.history),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ActionSheetGroup(
          children: [
            _ActionSheetRow(
              label: 'Reorder exercises',
              enabled: canReorder,
              onTap: () =>
                  Navigator.of(context).pop(_ExerciseAction.reorderExercises),
            ),
            const _ActionSheetDivider(),
            _ActionSheetRow(
              label: 'Replace exercise',
              onTap: () =>
                  Navigator.of(context).pop(_ExerciseAction.replaceExercise),
            ),
            const _ActionSheetDivider(),
            _ActionSheetRow(
              label: 'Remove exercise',
              destructive: true,
              onTap: () =>
                  Navigator.of(context).pop(_ExerciseAction.removeExercise),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReorderExercisesSheet extends StatefulWidget {
  final List<TrainingRecommendationItem> items;

  const _ReorderExercisesSheet({
    required this.items,
  });

  @override
  State<_ReorderExercisesSheet> createState() => _ReorderExercisesSheetState();
}

class _ReorderExercisesSheetState extends State<_ReorderExercisesSheet> {
  late List<TrainingRecommendationItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    return _ActionSheetScaffold(
      title: 'Reorder exercises',
      trailing: TextButton(
        onPressed: () => Navigator.of(context).pop(_items),
        child: const Text(
          'Done',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _workoutAccent,
          ),
        ),
      ),
      children: [
        SizedBox(
          height: 360,
          child: ReorderableListView.builder(
            itemCount: _items.length,
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _items.removeAt(oldIndex);
                _items.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final item = _items[index];
              return Container(
                key: ValueKey(item.exercise.id),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: _workoutSurfaceBorder),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    item.exercise.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _workoutPrimaryText,
                    ),
                  ),
                  subtitle: Text(
                    item.track.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _workoutSecondaryText,
                    ),
                  ),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(
                      Icons.drag_handle_rounded,
                      color: _workoutTertiaryText,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReplaceSingleExerciseView extends StatefulWidget {
  final String currentExerciseId;
  final ExerciseProgramSection section;

  const _ReplaceSingleExerciseView({
    required this.currentExerciseId,
    required this.section,
  });

  @override
  State<_ReplaceSingleExerciseView> createState() =>
      _ReplaceSingleExerciseViewState();
}

class _ReplaceSingleExerciseViewState
    extends State<_ReplaceSingleExerciseView> {
  final _controller = TextEditingController();
  late final List<Exercise> _candidates;

  @override
  void initState() {
    super.initState();
    _candidates = ExerciseCatalog.browsable()
        .where(
          (exercise) =>
              exercise.programSection == widget.section &&
              exercise.id != widget.currentExerciseId,
        )
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final results = query.isEmpty
        ? _candidates
        : _candidates
            .where((exercise) => exercise.name.toLowerCase().contains(query))
            .toList();

    return Scaffold(
      backgroundColor: _workoutBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.section.label.toUpperCase(),
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            letterSpacing: 1.8,
                            color: _workoutSecondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Switch Exercise',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: _workoutPrimaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _workoutSecondaryText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: _workoutSecondaryText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          letterSpacing: 1.3,
                          color: _workoutPrimaryText,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'SEARCH EXERCISES…',
                          hintStyle: GoogleFonts.robotoMono(
                            fontSize: 12,
                            letterSpacing: 1.3,
                            color: _workoutTertiaryText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: _ActionSheetMessage(
                          title: 'No exercises found.',
                          body: 'Try another search term.',
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final exercise = results[index];
                        return _ReplaceSingleExerciseOptionTile(
                          title: exercise.name,
                          subtitle: 'Single exercise',
                          onTap: () => Navigator.of(context).pop(exercise),
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

class _ReplaceSingleExerciseOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReplaceSingleExerciseOptionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: _workoutDanger.withValues(alpha: 0.22)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.18,
                      color: _workoutPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _workoutSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.add_rounded,
              size: 18,
              color: _workoutDanger,
            ),
          ],
        ),
      ),
    );
  }
}

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
      backgroundColor: _workoutBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _showBranches
                              ? '${category.title.toUpperCase()} · STEP 2 OF 2'
                              : 'STEP 1 OF 2',
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            letterSpacing: 1.8,
                            color: _workoutSecondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showBranches ? 'Pick Branch' : 'Pick Progression',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: _workoutPrimaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _workoutSecondaryText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _showBranches
                    ? 'Each branch is a different path through the ${category.title.toLowerCase()} tree.'
                    : 'Choose the skill tree you want this item to follow.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: _workoutSecondaryText,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _showBranches
                    ? _ProgressionBranchList(
                        category: category,
                        selectedBranchId: _selectedBranchId,
                        onSelect: (branchId) =>
                            setState(() => _selectedBranchId = branchId),
                      )
                    : ListView.separated(
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _categories[index];
                          return _ReplaceSingleExerciseOptionTile(
                            title: item.title,
                            subtitle:
                                '${_selectableBranches(item).length} branches · ${item.track.label}',
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = item.id;
                                _selectedBranchId = null;
                                _showBranches = true;
                              });
                            },
                          );
                        },
                      ),
              ),
              if (_showBranches) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _showBranches = false;
                          _selectedBranchId = null;
                        }),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Back',
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.8,
                            color: _workoutPrimaryText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _selectedBranchId == null
                            ? null
                            : () => Navigator.of(context).pop(
                                  _progressionReplacement(
                                    widget.currentItem,
                                    category,
                                    _selectedBranchId!,
                                    widget.progressMap,
                                  ),
                                ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _workoutAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Set Progression',
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
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

class _ProgressionBranchList extends StatelessWidget {
  final SkillCategory category;
  final String? selectedBranchId;
  final ValueChanged<String> onSelect;

  const _ProgressionBranchList({
    required this.category,
    required this.selectedBranchId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final branches = category.branches
        .where(
          (branch) => category.pathFor(branch.id).isNotEmpty,
        )
        .toList();

    return ListView.separated(
      itemCount: branches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final branch = branches[index];
        return InkWell(
          onTap: () => onSelect(branch.id),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedBranchId == branch.id
                    ? _workoutAccent.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              borderRadius: BorderRadius.circular(14),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.18,
                          color: _workoutPrimaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _branchRange(category, branch.id),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _workoutSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selectedBranchId == branch.id
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 18,
                  color: selectedBranchId == branch.id
                      ? _workoutAccent
                      : _workoutTertiaryText,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionSheetScaffold extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _ActionSheetScaffold({
    required this.title,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _workoutBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: _workoutSurfaceBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const SizedBox(width: 52),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _workoutPrimaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 52, child: trailing),
                ],
              ),
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionSheetGroup extends StatelessWidget {
  final List<Widget> children;

  const _ActionSheetGroup({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _workoutCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _ActionSheetDivider extends StatelessWidget {
  const _ActionSheetDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: _workoutSurfaceBorder,
      indent: 16,
      endIndent: 16,
    );
  }
}

class _ActionSheetRow extends StatelessWidget {
  final String label;
  final bool destructive;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionSheetRow({
    required this.label,
    this.destructive = false,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? _workoutDanger
        : enabled
            ? _workoutPrimaryText
            : _workoutTertiaryText;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              const Icon(
                Icons.chevron_right_rounded,
                color: _workoutTertiaryText,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionSheetMessage extends StatelessWidget {
  final String title;
  final String body;

  const _ActionSheetMessage({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _workoutCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _workoutPrimaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: _workoutSecondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetHeader extends StatelessWidget {
  final String label;

  const _SetHeader({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: _setHeaderStyle(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Last',
                style: _setHeaderStyle(),
              ),
            ),
          ),
          Text(
            label.toUpperCase(),
            style: _setHeaderStyle(),
          ),
          const SizedBox(width: 72),
        ],
      ),
    );
  }

  static TextStyle _setHeaderStyle() {
    return const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: _workoutTertiaryText,
      letterSpacing: 0.6,
    );
  }
}

class _SetRow extends StatefulWidget {
  final _WorkoutSetDraft set;
  final bool hasTimer;
  final Color timerColor;
  final VoidCallback? onOpenTimer;
  final ValueChanged<int?> onTargetChanged;
  final VoidCallback onToggle;

  const _SetRow({
    super.key,
    required this.set,
    required this.hasTimer,
    required this.timerColor,
    this.onOpenTimer,
    required this.onTargetChanged,
    required this.onToggle,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.set.target <= 0 ? '' : widget.set.target.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextText = widget.set.target <= 0 ? '' : widget.set.target.toString();
    if (nextText != _controller.text) {
      _controller.text = nextText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.set.completed;

    return Opacity(
      opacity: completed ? 0.72 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                widget.set.number.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: completed ? _workoutDone : _workoutSecondaryText,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  widget.set.previousLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _workoutTertiaryText,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 68,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  widget.onTargetChanged(parsed);
                },
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: _workoutPrimaryText,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: completed ? _workoutAccentSoft : _workoutSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: completed ? _workoutAccent : Colors.transparent,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _workoutAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: widget.hasTimer ? 84 : 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.hasTimer) ...[
                    IconButton(
                      onPressed: widget.onOpenTimer,
                      tooltip: 'Open timer',
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            widget.timerColor.withValues(alpha: 0.12),
                        fixedSize: const Size(28, 28),
                        padding: EdgeInsets.zero,
                      ),
                      icon: Icon(
                        Icons.timer_outlined,
                        size: 15,
                        color: widget.timerColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    onPressed: widget.onToggle,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          completed ? _workoutDone : Colors.transparent,
                      side: completed
                          ? null
                          : const BorderSide(color: _workoutTertiaryText),
                      fixedSize: const Size(28, 28),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: completed ? Colors.white : Colors.transparent,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TimedSetTimerSheet extends StatefulWidget {
  final Color accentColor;
  final String exerciseName;
  final int initialTarget;
  final int setNumber;

  const _TimedSetTimerSheet({
    required this.accentColor,
    required this.exerciseName,
    required this.initialTarget,
    required this.setNumber,
  });

  @override
  State<_TimedSetTimerSheet> createState() => _TimedSetTimerSheetState();
}

class _TimedSetTimerSheetState extends State<_TimedSetTimerSheet> {
  Timer? _ticker;
  int _countdown = 3;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        if (_countdown > 1) {
          _countdown -= 1;
        } else if (_countdown == 1) {
          _countdown = 0;
        } else {
          _elapsedSeconds += 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatElapsed() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final countdownActive = _countdown > 0;

    return Container(
      decoration: const BoxDecoration(
        color: _workoutBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: _workoutSurfaceBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _workoutPrimaryText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target ${widget.initialTarget} sec',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _workoutSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: _workoutSurface,
                      fixedSize: const Size(36, 36),
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: _workoutPrimaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: countdownActive
                    ? Text(
                        _countdown.toString(),
                        key: ValueKey(_countdown),
                        style: TextStyle(
                          fontSize: 86,
                          fontWeight: FontWeight.w900,
                          color: widget.accentColor,
                          height: 1,
                        ),
                      )
                    : Text(
                        _formatElapsed(),
                        key: const ValueKey('elapsed'),
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: _workoutPrimaryText,
                          fontFeatures: [FontFeature.tabularFigures()],
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: countdownActive
                      ? null
                      : () => Navigator.of(context).pop(_elapsedSeconds),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.black,
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.35),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWorkoutState extends StatelessWidget {
  final VoidCallback onAddExercise;

  const _EmptyWorkoutState({
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _workoutCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No exercises queued for this session.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _workoutSecondaryText,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAddExercise,
            style: OutlinedButton.styleFrom(
              foregroundColor: _workoutAccent,
              side: const BorderSide(color: _workoutSurfaceBorder),
              minimumSize: const Size(0, 44),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Add exercise',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

List<_WorkoutSetDraft> _initialSetDrafts(TrainingRecommendationItem item) {
  return List.generate(
    _defaultSetCount(item),
    (index) => _WorkoutSetDraft(
      number: index + 1,
      target: _defaultTarget(item),
      previousLabel: '-',
    ),
  );
}

Color _sectionColor(ExerciseProgramSection section) {
  switch (section) {
    case ExerciseProgramSection.warmup:
      return const Color(0xFF4ECDC4);
    case ExerciseProgramSection.skillWork:
      return const Color(0xFFA78BFA);
    case ExerciseProgramSection.mainExercises:
      return _workoutAccent;
    case ExerciseProgramSection.coolDown:
      return const Color(0xFF34D399);
  }
}

String _formatRestLabel(int seconds) {
  if (seconds <= 0) return 'Off';
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '${minutes}m ${remainder}s';
}

String _formatCountdownLabel(int seconds) {
  final safeSeconds = seconds.clamp(0, 59 * 60 + 59);
  final minutes = safeSeconds ~/ 60;
  final remainder = safeSeconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

bool _isTimedExercise(Exercise exercise) {
  final name = exercise.name.toLowerCase();
  final description = exercise.description.toLowerCase();

  return name.contains('hold') ||
      name.contains('hang') ||
      name.contains('plank') ||
      name.contains('lever') ||
      name.contains('handstand') ||
      description.contains('for time');
}

int _defaultSetCount(TrainingRecommendationItem item) {
  switch (item.exercise.programSection) {
    case ExerciseProgramSection.warmup:
      return 2;
    case ExerciseProgramSection.skillWork:
      return 3;
    case ExerciseProgramSection.mainExercises:
      return item.exercise.difficulty >= 4 ? 4 : 3;
    case ExerciseProgramSection.coolDown:
      return 2;
  }
}

int _defaultTarget(TrainingRecommendationItem item) {
  if (_isTimedExercise(item.exercise)) {
    if (item.exercise.difficulty <= 1) return 30;
    if (item.exercise.difficulty <= 3) return 20;
    return 12;
  }

  if (item.exercise.difficulty <= 1) return 12;
  if (item.exercise.difficulty <= 3) return 8;
  return 5;
}

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
  return '$first -> $last';
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
