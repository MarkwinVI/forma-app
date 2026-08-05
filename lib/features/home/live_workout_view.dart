import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/reorder_exercises_page.dart';
import '../../core/widgets/type_led.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_log_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/dev_clock_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/exercise_progression_service.dart';
import '../../data/services/live_activity_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../../data/services/workout_notification_service.dart';
import '../../data/services/workout_rest_preferences_service.dart';
import '../exercises/exercise_detail_view.dart';
import '../exercises/exercise_picker_view.dart';
import 'completed_workout_model.dart';
import 'finished_workout_view.dart';
import 'program_day_items.dart';

const _workoutDanger = Color(0xFFF2564A);

/// Side padding of the workout list. A logged set's tint bleeds back out by
/// exactly this much so it reaches the edge of the screen.
const _workoutSidePadding = 22.0;

/// Shown in the LAST column when the exercise has never been logged.
const _noPreviousLabel = '–';

/// The rest bar's own height, above the safe area: its progress track, its
/// padding and the controls. The list keeps this much clear at its foot so
/// the last set is never parked underneath it.
const _restBarProgressHeight = 3.0;
const _restBarControlHeight = 40.0;
const _restBarHeight = _restBarProgressHeight + 20 + _restBarControlHeight;

/// Set fields take a number off the keypad and nothing else. Left to itself
/// iOS offers Paste and Scan Text on a tap, and pointing a camera at a rep
/// count is not a thing anybody is doing mid-set.
Widget _noContextMenu(BuildContext context, EditableTextState state) =>
    const SizedBox.shrink();

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
  final _devClockService = DevClockService();
  final _restPreferencesService = WorkoutRestPreferencesService();
  final _liveActivityService = LiveActivityService.instance;
  final _programService = TrainingProgramService();
  final _programStoreService = TrainingProgramStoreService();
  final _exerciseLogService = ExerciseLogService();

  late final DateTime _startedAt;
  late List<TrainingRecommendationItem> _sessionItems;
  late Map<String, List<_WorkoutSetDraft>> _setDrafts;
  late Map<String, int> _restSecondsByExercise;
  Map<String, ExerciseStatus> _progressMap = {};
  Map<String, ExerciseProgress> _progressRows = {};

  /// Sets logged the last time each exercise was trained, keyed by exercise
  /// id. Fills the LAST column and pre-fills the kg field.
  Map<String, List<ExerciseSet>> _lastSets = {};
  MasteryTargetSettings _masterySettings = MasteryTargetSettings.defaults;
  _ActiveRestTimer? _activeRestTimer;
  Timer? _ticker;
  Duration _pausedDuration = Duration.zero;
  Duration? _pausedRestRemaining;
  DateTime? _pausedAt;
  bool _isRunning = true;

  /// Number of reps fields currently focused; drives the hide-keyboard button.
  int _repFocusCount = 0;

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
    _devClockService.loadOffset();
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
    _loadLastSessions();
    // Ask once, up front — the first background rest alert must not be the
    // moment we discover notifications were never allowed.
    WorkoutNotificationService.instance.requestPermission();
    _liveActivityService.onAction = _handleLiveActivityAction;
    _liveActivityService
        .start(widget.recommendation.sessionLabel, _liveActivityState())
        .then((_) {
      // Re-sync once started: picks up rest preferences and progression
      // targets that load async, and kicks off the first thumbnail fetch.
      if (mounted) _syncLiveActivity();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final shouldClearRest = _isRunning &&
          _activeRestTimer != null &&
          _activeRestRemainingSeconds() <= 0;
      if (!_isRunning && !shouldClearRest) return;
      if (shouldClearRest &&
          !WorkoutNotificationService.instance.soundHandledByNotification) {
        SystemSound.play(SystemSoundType.alert);
      }
      setState(() {
        if (shouldClearRest) {
          _activeRestTimer = null;
          _pausedRestRemaining = null;
        }
      });
      if (shouldClearRest) _syncWorkoutPresence();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _toastTimer?.cancel();
    WorkoutNotificationService.instance.cancelRestOver();
    _liveActivityService.onAction = null;
    _liveActivityService.end();
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

  /// What each exercise was last done with. Arrives after the first frame, so
  /// any row the user has not touched yet is rebuilt with its history: the
  /// LAST column fills in and a loaded lift's kg field takes last session's
  /// weight the way reps take the prescribed target.
  Future<void> _loadLastSessions() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    try {
      final lastSets = await _exerciseLogService.lastSetsForExercises(
        userId,
        _sessionItems.map((item) => item.exercise.id).toList(),
      );
      if (!mounted || lastSets.isEmpty) return;

      setState(() {
        _lastSets = lastSets;
        _setDrafts = {
          for (final item in _sessionItems)
            item.exercise.id:
                (_setDrafts[item.exercise.id]?.any((set) => set.hasData) ??
                        false)
                    ? _setDrafts[item.exercise.id]!
                    : _initialSetDrafts(item),
        };
      });
    } catch (error, stackTrace) {
      // The workout is still perfectly loggable without last session's
      // numbers — the LAST column simply keeps its dash.
      debugPrint('Failed to load last sessions: $error\n$stackTrace');
    }
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
              item.exercise.id:
                  (_setDrafts[item.exercise.id]?.any((set) => set.hasData) ??
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

  /// How much of the rest is left, 0–1, for the bar's own progress track.
  double _restProgress() {
    final timer = _activeRestTimer;
    if (timer == null || timer.totalSeconds <= 0) return 0;
    final fraction = _activeRestRemainingSeconds() / timer.totalSeconds;
    return fraction.clamp(0.0, 1.0);
  }

  /// Adds or takes back [deltaSeconds] of rest. Taking back more than is left
  /// ends the rest rather than running it negative — the point of −15 with
  /// ten seconds on the clock is to get on with the set.
  void _adjustRestTimer(int deltaSeconds) {
    final timer = _activeRestTimer;
    if (timer == null) return;

    final remaining = _activeRestRemainingSeconds() + deltaSeconds;
    if (remaining <= 0) {
      _clearActiveRestTimer();
      return;
    }

    // The total has to cover what is left, or the track would read past full.
    final total = timer.totalSeconds + deltaSeconds;
    setState(() {
      _activeRestTimer = timer.copyWith(
        endsAt: DateTime.now().add(Duration(seconds: remaining)),
        totalSeconds: total < remaining ? remaining : total,
      );
      if (_pausedRestRemaining != null) {
        _pausedRestRemaining = Duration(seconds: remaining);
      }
    });
    _syncWorkoutPresence();
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
    final startedAt = _devClockService.now().subtract(_elapsedDuration());
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

  /// Last session's set at [index], or its final set once this session has run
  /// longer than that one did — an extra set carries the load you finished on
  /// rather than dropping back to nothing.
  ExerciseSet? _lastSetFor(TrainingRecommendationItem item, int index) {
    final sets = _lastSets[item.exercise.id];
    if (sets == null || sets.isEmpty) return null;
    return sets[index.clamp(0, sets.length - 1)];
  }

  List<_WorkoutSetDraft> _initialSetDrafts(TrainingRecommendationItem item) {
    final target = _prescribedTargetFor(item);
    // The set count the user last saved for this exercise on this day wins;
    // reps still come from where they are on the progression.
    return List.generate(
      item.plannedSets ?? target.sets,
      (index) {
        final last = _lastSetFor(item, index);
        return _WorkoutSetDraft(
          number: index + 1,
          target: target.value,
          weightKg: item.exercise.isWeighted ? (last?.weightKg ?? 0) : 0,
          previousLabel: previousSetLabel(item.exercise, last),
        );
      },
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
    // Every set edit funnels through here, so the Live Activity's set count
    // and rep goal stay honest without per-call-site plumbing.
    _syncLiveActivity();
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
    _syncWorkoutPresence();
  }

  void _toggleSet(TrainingRecommendationItem item, int number) {
    // Ticking a set is the end of typing it: drop the keyboard so the row you
    // just logged is visible instead of sitting behind it.
    FocusManager.instance.primaryFocus?.unfocus();

    final currentSet = _setsFor(item).firstWhere((set) => set.number == number);
    final shouldComplete = !currentSet.completed;

    // A set landing is the one moment in a workout worth feeling — you are
    // often not looking at the phone when you tick it.
    if (shouldComplete) HapticFeedback.lightImpact();
    final sets = _setsFor(item)
        .map(
          (set) => set.number == number
              ? set.copyWith(completed: shouldComplete)
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

  /// Reps fields report focus so the "hide keyboard" button can appear only
  /// while one is being edited. Counting avoids a flicker when focus jumps
  /// straight from one field to another.
  void _onRepFocusChanged(bool focused) {
    setState(() {
      _repFocusCount =
          focused ? _repFocusCount + 1 : (_repFocusCount - 1).clamp(0, 999);
    });
  }

  /// Applies a reps (or seconds, for timed exercises) value typed inline on
  /// a set row. Marks the set edited so it counts toward the logged session.
  void _setSetValue(
    TrainingRecommendationItem item,
    int number,
    int value,
  ) {
    final isTimed = _isTimedExercise(item.exercise);
    final clamped = value.clamp(0, isTimed ? 3600 : 999);

    final sets = _setsFor(item)
        .map(
          (set) => set.number == number
              ? set.copyWith(target: clamped, isEdited: true)
              : set,
        )
        .toList();

    _replaceSets(item, sets);
  }

  /// Applies a load typed into a set's kg field. Like reps, typing marks the
  /// set edited so it counts toward the logged session.
  void _setSetWeight(
    TrainingRecommendationItem item,
    int number,
    double weightKg,
  ) {
    final clamped = weightKg.clamp(0.0, 999.0);

    final sets = _setsFor(item)
        .map(
          (set) => set.number == number
              ? set.copyWith(weightKg: clamped, isEdited: true)
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
          // A set added mid-workout keeps the load you are already lifting.
          weightKg: sets.isEmpty ? 0 : sets.last.weightKg,
          previousLabel: previousSetLabel(
            item.exercise,
            _lastSetFor(item, sets.length),
          ),
        ),
      ],
    );
  }

  void _removeSet(TrainingRecommendationItem item, int number) {
    final sets = _setsFor(item);
    if (sets.length <= 1) return;

    final remaining = sets.where((set) => set.number != number).toList();
    _planEdited = true;
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
    _syncLiveActivity();
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
    _syncLiveActivity();
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
    _syncWorkoutPresence();
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
    _syncWorkoutPresence();
  }

  void _clearActiveRestTimer() {
    setState(() {
      _activeRestTimer = null;
      _pausedRestRemaining = null;
    });
    _syncWorkoutPresence();
  }

  /// Everything the phone shows about this workout outside the app — the
  /// scheduled rest-over notification and the Live Activity — refreshed
  /// together after any state change that affects either.
  void _syncWorkoutPresence() {
    _syncRestNotification();
    _syncLiveActivity();
  }

  /// Keeps the scheduled rest-over notification in step with the rest timer:
  /// one pending notification while rest is running, none otherwise. Uses a
  /// fixed id, so rescheduling simply replaces the previous one.
  void _syncRestNotification() {
    final timer = _activeRestTimer;
    if (_isRunning && timer != null && _activeRestRemainingSeconds() > 0) {
      WorkoutNotificationService.instance.scheduleRestOver(
        endsAt: timer.endsAt,
        exerciseName: _exerciseNameById(timer.exerciseId) ?? 'your exercise',
      );
    } else {
      WorkoutNotificationService.instance.cancelRestOver();
    }
  }

  String? _exerciseNameById(String id) {
    for (final item in _sessionItems) {
      if (item.exercise.id == id) return item.exercise.name;
    }
    return null;
  }

  // ── Live Activity ─────────────────────────────────────────────────

  void _syncLiveActivity() {
    _liveActivityService.update(_liveActivityState());
  }

  /// The exercise the Live Activity is about: the one being rested from
  /// while its sets are unfinished, otherwise the first exercise (in the
  /// order the list shows) with a set still open, otherwise the final one.
  TrainingRecommendationItem? _currentItemForActivity() {
    final restId = _activeRestTimer?.exerciseId;
    if (restId != null) {
      for (final item in _sessionItems) {
        if (item.exercise.id == restId &&
            _setsFor(item).any((set) => !set.completed)) {
          return item;
        }
      }
    }
    for (final section in _sectionOrder) {
      for (final item in _itemsForSection(section)) {
        if (_setsFor(item).any((set) => !set.completed)) return item;
      }
    }
    for (final section in _sectionOrder.reversed) {
      final items = _itemsForSection(section);
      if (items.isNotEmpty) return items.last;
    }
    return null;
  }

  LiveWorkoutActivityState _liveActivityState() {
    final item = _currentItemForActivity();
    final sets =
        item == null ? const <_WorkoutSetDraft>[] : _setsFor(item);
    _WorkoutSetDraft? openSet;
    for (final set in sets) {
      if (!set.completed) {
        openSet = set;
        break;
      }
    }
    final setNumber = openSet?.number ?? (sets.isEmpty ? 1 : sets.length);
    final target = openSet?.target ?? (sets.isEmpty ? 0 : sets.last.target);
    final isTimed = item != null && _isTimedExercise(item.exercise);

    // While paused the rest countdown cannot tick honestly on the lock
    // screen, so rest is simply not shown until the session resumes.
    final restTimer = _activeRestTimer;
    final resting = _isRunning && _hasActiveRestTimer;

    return LiveWorkoutActivityState(
      exerciseName: item?.exercise.name ?? widget.recommendation.sessionLabel,
      setNumber: setNumber,
      totalSets: sets.length,
      repGoalLabel: isTimed ? '${target}s' : '$target reps',
      workoutStartedAt: DateTime.now().subtract(_elapsedDuration()),
      isPaused: !_isRunning,
      pausedElapsedLabel: _isRunning ? null : _formatElapsed(),
      restStartedAt: resting
          ? restTimer!.endsAt
              .subtract(Duration(seconds: restTimer.totalSeconds))
          : null,
      restEndsAt: resting ? restTimer!.endsAt : null,
    );
  }

  void _handleLiveActivityAction(String action) {
    if (!mounted) return;
    switch (action) {
      case 'completeSet':
        final item = _currentItemForActivity();
        if (item == null) return;
        for (final set in _setsFor(item)) {
          if (!set.completed) {
            _toggleSet(item, set.number);
            return;
          }
        }
      case 'restPlus10':
        _adjustRestTimer(10);
      case 'restMinus10':
        _adjustRestTimer(-10);
      case 'skipRest':
        _clearActiveRestTimer();
    }
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
    _syncWorkoutPresence();
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
              weightKg: item.exercise.isWeighted ? set.weightKg : 0,
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
      startedAt: _devClockService.now().subtract(_elapsedDuration()),
      finishedAt: _devClockService.now(),
      exercises: exercises,
      plannedDate: widget.recommendation.plannedDate,
      plannedStepIndex: widget.recommendation.plannedStepIndex,
      affectsSchedule: widget.recommendation.affectsSchedule,
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

    // The workout is over as far as the lock screen is concerned.
    _liveActivityService.end();
    WorkoutNotificationService.instance.cancelRestOver();

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

    final plannedDate = widget.recommendation.plannedDate;
    final dayTitle = plannedDate == null
        ? programDayTitle(widget.recommendation.sessionType)
        : kWeekdayNames[plannedDate.weekday - 1];
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
    // Plans belong to the workout type, so the changes land on every day
    // running this session — one list, however many days share it.
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

    writeProgramDayConfig(
      config,
      sessionType,
      ProgramSessionPlan.serializeDay(updated),
    );

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

    final order = await Navigator.of(context).push<List<List<String>>>(
      MaterialPageRoute(
        builder: (_) => ReorderExercisesPage(
          sections: [
            for (final entry in sections)
              ReorderExercisesSection(
                title: entry.section.label,
                entries: [
                  for (final item in entry.items)
                    ReorderExerciseEntry(
                      id: item.exercise.id,
                      name: item.exercise.name,
                      subtitle: item.track.label,
                      icon: programPatternIcon(item.exercise.category),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
    if (order == null || !mounted) return;

    final byId = {
      for (final entry in sections)
        for (final item in entry.items) item.exercise.id: item,
    };
    _applyReorderedSections({
      for (var i = 0; i < sections.length; i++)
        sections[i].section: [
          for (final id in order[i])
            if (byId[id] != null) byId[id]!,
        ],
    });
  }

  /// Replacing goes straight to the search — the same page adding uses, and
  /// the same one the program editor and the library open. There is no
  /// progression-or-exercise question first: the results already mark the
  /// steps that continue a path you're on.
  Future<void> _openReplaceExercise(TrainingRecommendationItem item) async {
    final replacement = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ExercisePickerView(
          excludedIds: {item.exercise.id},
          progressMap: _progressMap,
          singlePick: true,
          title: 'Switch exercise',
          subtitle: 'Replaces ${item.exercise.name}',
        ),
      ),
    );
    if (replacement == null || replacement.isEmpty || !mounted) return;
    _replaceExerciseInSession(item, replacement.first);
  }

  Future<void> _openAddExercise() async {
    final existingIds = _sessionItems.map((item) => item.exercise.id).toSet();
    final picked = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ExercisePickerView(
          excludedIds: existingIds,
          progressMap: _progressMap,
          subtitle: 'Added to the end of today’s session',
        ),
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    for (final exercise in picked) {
      _addExerciseToSession(exercise);
    }
    // Each add toasts its own name; a multi-pick would only leave the last
    // one standing, so say how many landed instead.
    if (picked.length > 1) {
      _showToast('${picked.length} exercises added');
    }
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
    final weightLabel = ExerciseProgressionService.weightLabelFor(
      _progressRows[item.exercise.id],
    );
    final target = '${sets.length} × $valueLabel'
        '${weightLabel == null ? '' : ' @ $weightLabel'}';
    return '${item.track.label} · $target';
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

    // The session isn't saved until the user finishes, so an iOS edge-swipe
    // or Android back must not silently drop it. Intercept the pop and route
    // to the same leave confirmation as the header's collapse button.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmLeaveWorkout();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _WorkoutHeader(
                    title: widget.recommendation.sessionLabel,
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
                        _workoutSidePadding,
                        0,
                        _workoutSidePadding,
                        _hasActiveRestTimer
                            ? _restBarHeight + 24 + bottomSafePadding
                            : 40,
                      ),
                      children: [
                        if (visibleSections.isEmpty)
                          _EmptyWorkoutState(onAddExercise: _openAddExercise)
                        else
                          // No section headings: the sets under each name
                          // already separate one exercise from the next, and
                          // grouping them said nothing you act on.
                          for (final entry in visibleSections)
                            for (var i = 0; i < entry.items.length; i++) ...[
                              if (i > 0 || entry != visibleSections.first)
                                const Padding(
                                  padding: EdgeInsets.only(top: 26),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColors.divider,
                                  ),
                                ),
                              const SizedBox(height: 24),
                              _WorkoutExerciseCard(
                                key: ValueKey(entry.items[i].exercise.id),
                                item: entry.items[i],
                                sets: _setsFor(entry.items[i]),
                                isTimed:
                                    _isTimedExercise(entry.items[i].exercise),
                                goalValue: entry.items[i].isProgression
                                    ? _prescribedTargetFor(entry.items[i]).value
                                    : null,
                                goalWeightKg: _progressRows[
                                        entry.items[i].exercise.id]
                                    ?.currentTargetWeightKg,
                                restSeconds: _restSecondsByExercise[
                                        entry.items[i].exercise.id] ??
                                    0,
                                onToggleSet: (number) =>
                                    _toggleSet(entry.items[i], number),
                                onValueChanged: (number, value) =>
                                    _setSetValue(entry.items[i], number, value),
                                onWeightChanged: (number, weightKg) =>
                                    _setSetWeight(
                                  entry.items[i],
                                  number,
                                  weightKg,
                                ),
                                onRemoveSet: (number) =>
                                    _removeSet(entry.items[i], number),
                                onRepFocusChanged: _onRepFocusChanged,
                                onAddSet: () => _addSet(entry.items[i]),
                                onRestTap: () =>
                                    _pickRestInterval(entry.items[i]),
                                onMenu: () =>
                                    _openExerciseActions(entry.items[i]),
                                onOpenDetail: () =>
                                    _openExerciseDetail(entry.items[i]),
                              ),
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
                  bottom: 0,
                  child: _RestTimerBar(
                    label: _formatCountdownLabel(restRemaining),
                    progress: _restProgress(),
                    onAdjust: _adjustRestTimer,
                    onSkip: _clearActiveRestTimer,
                  ),
                ),
              Positioned(
                left: 20,
                right: 20,
                top: 74,
                child: IgnorePointer(
                  child: AnimatedSlide(
                    offset:
                        _toast == null ? const Offset(0, -0.3) : Offset.zero,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: _toast == null ? 0 : 1,
                      duration: const Duration(milliseconds: 240),
                      child:
                          Center(child: _WorkoutToast(message: _toast ?? '')),
                    ),
                  ),
                ),
              ),
              // Floats just above the keyboard while a reps field is focused.
              if (_repFocusCount > 0)
                Positioned(
                  right: 16,
                  // Clears the rest bar when one is up, rather than sitting
                  // on top of the skip button.
                  bottom: _hasActiveRestTimer
                      ? _restBarHeight + 12 + bottomSafePadding
                      : 12,
                  child: _HideKeyboardButton(
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
            ],
          ),
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

/// Inline, editable reps/seconds cell for a set row. Owns its controller and
/// focus node so the numeric keyboard can stay docked and the whole set list
/// stays visible while typing — and so the once-a-second workout-timer
/// rebuilds of the parent never reset the cursor or clobber what's typed.
///
/// Until the set is logged (typed into or checked off), the prescribed value
/// shows as a faded placeholder and the field is empty — so typing replaces
/// it rather than appending. Once logged, the value renders fully white.
class _RepField extends StatefulWidget {
  final int value;
  final bool completed;
  final bool isEdited;
  final ValueChanged<int> onChanged;
  final ValueChanged<bool> onFocusChanged;

  const _RepField({
    super.key,
    required this.value,
    required this.completed,
    required this.isEdited,
    required this.onChanged,
    required this.onFocusChanged,
  });

  @override
  State<_RepField> createState() => _RepFieldState();
}

class _RepFieldState extends State<_RepField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  /// A logged set (edited or checked) shows a real, white value; an untouched
  /// set shows its default as a faded placeholder with an empty field.
  bool get _showsValue => widget.completed || widget.isEdited;

  String get _desiredText => _showsValue ? '${widget.value}' : '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _desiredText);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_RepField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reflect external changes (progression target on load, add-set copy, or
    // logging a default via the checkmark) — but never while the user types.
    if (!_focusNode.hasFocus) _syncText();
  }

  void _syncText() {
    if (_controller.text != _desiredText) {
      _controller.value = TextEditingValue(
        text: _desiredText,
        selection: TextSelection.collapsed(offset: _desiredText.length),
      );
    }
  }

  void _onFocusChange() {
    widget.onFocusChanged(_focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      // Select any existing value so the first keystroke replaces it.
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      // Left blank or unlogged — fall back to the model's text.
      _syncText();
    }
  }

  void _handleChanged(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed != null) widget.onChanged(parsed);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The value you type is the loudest thing in the row on its own: no box,
    // no rule, just the number.
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      onChanged: _handleChanged,
      contextMenuBuilder: _noContextMenu,
      cursorColor: AppColors.accentPrimary,
      style: monoStyle(
        size: 16,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        hintText: '${widget.value}',
        hintStyle: monoStyle(size: 16, letterSpacing: 0),
      ),
    );
  }
}

/// The kg cell of a reps-and-weight row. Behaves exactly like [_RepField] —
/// its own controller so the workout timer's rebuilds cannot clobber what is
/// being typed, and the value shows as a faded placeholder until the set is
/// logged. What it starts on is last session's load for the same set, so the
/// common case is checking the set off without touching the field at all.
class _WeightField extends StatefulWidget {
  final double weightKg;
  final bool completed;
  final bool isEdited;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool> onFocusChanged;

  const _WeightField({
    super.key,
    required this.weightKg,
    required this.completed,
    required this.isEdited,
    required this.onChanged,
    required this.onFocusChanged,
  });

  @override
  State<_WeightField> createState() => _WeightFieldState();
}

class _WeightFieldState extends State<_WeightField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  bool get _showsValue => widget.completed || widget.isEdited;

  /// With nothing logged before, the field rests on zero rather than a dash —
  /// a load is a number you adjust up from, not a blank.
  String get _hintText => widget.weightKg > 0 ? _kgText(widget.weightKg) : '0';

  String get _desiredText =>
      _showsValue && widget.weightKg > 0 ? _kgText(widget.weightKg) : '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _desiredText);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_WeightField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) _syncText();
  }

  void _syncText() {
    if (_controller.text != _desiredText) {
      _controller.value = TextEditingValue(
        text: _desiredText,
        selection: TextSelection.collapsed(offset: _desiredText.length),
      );
    }
  }

  void _onFocusChange() {
    widget.onFocusChanged(_focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _syncText();
    }
  }

  void _handleChanged(String text) {
    final parsed = double.tryParse(text.trim().replaceAll(',', '.'));
    if (parsed != null) widget.onChanged(parsed);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      onChanged: _handleChanged,
      contextMenuBuilder: _noContextMenu,
      cursorColor: AppColors.accentPrimary,
      style: monoStyle(
        size: 16,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        hintText: _hintText,
        hintStyle: monoStyle(size: 16, letterSpacing: 0),
      ),
    );
  }
}

/// Floating "hide keyboard" button shown above the keyboard while a rep field
/// is focused (matches the Hevy-style dismiss control).
class _HideKeyboardButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HideKeyboardButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.keyboard_hide_rounded,
          size: 22,
          color: Color(0xFF1C1C20),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────

class _WorkoutHeader extends StatelessWidget {
  final String title;
  final String elapsed;
  final bool isRunning;
  final double progress;
  final VoidCallback onToggleRunning;
  final VoidCallback onFinish;
  final VoidCallback onCollapse;

  const _WorkoutHeader({
    required this.title,
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
                  child: Text(
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

  /// Per-set goal from the progression ladder; null for standalone
  /// exercises, which drop the GOAL column altogether.
  final int? goalValue;

  /// Load the ladder prescribes alongside [goalValue] on a weighted lift.
  final double? goalWeightKg;
  final int restSeconds;
  final void Function(int number) onToggleSet;
  final void Function(int number, int value) onValueChanged;
  final void Function(int number, double weightKg) onWeightChanged;
  final void Function(int number) onRemoveSet;
  final ValueChanged<bool> onRepFocusChanged;
  final VoidCallback onAddSet;
  final VoidCallback onRestTap;
  final VoidCallback onMenu;
  final VoidCallback onOpenDetail;

  const _WorkoutExerciseCard({
    super.key,
    required this.item,
    required this.sets,
    required this.isTimed,
    required this.goalValue,
    required this.goalWeightKg,
    required this.restSeconds,
    required this.onToggleSet,
    required this.onValueChanged,
    required this.onWeightChanged,
    required this.onRemoveSet,
    required this.onRepFocusChanged,
    required this.onAddSet,
    required this.onRestTap,
    required this.onMenu,
    required this.onOpenDetail,
  });

  /// A reps-and-weight lift logs a load alongside its reps, so the grid takes
  /// its kg column and the LAST column reads "60kg x 8".
  bool get isWeighted => item.exercise.isWeighted;

  /// The prescribed set, written the way the set itself is: a loaded lift
  /// carries its weight — "60kg x 8" — where an unloaded one is a count.
  /// Null when there is no ladder behind this exercise, and the column goes.
  String? get _goalLabel {
    if (goalValue == null) return null;
    final value = '$goalValue${isTimed ? 's' : ''}';
    return isWeighted ? '${_kgText(goalWeightKg ?? 0)}kg x $value' : value;
  }

  /// LAST and GOAL both spell out a load on a weighted row, and two of those
  /// beside a kg field is more than a phone's width — so they set smaller.
  TextStyle get _historyStyle => monoStyle(
        size: isWeighted ? 11.5 : 14,
        weight: FontWeight.w500,
        letterSpacing: 0,
        color: AppColors.textSecondary,
      );

  int get _doneCount => sets.where((set) => set.completed).length;
  bool get _allDone => sets.isNotEmpty && _doneCount == sets.length;

  @override
  Widget build(BuildContext context) {
    // No card: the exercise is its name, the sets are a table of numbers, and
    // nothing is drawn around either.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Pressable(
                onTap: onOpenDetail,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.exercise.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.42,
                          height: 1.15,
                        ),
                      ),
                    ),
                    if (_allDone) ...[
                      const SizedBox(width: 9),
                      const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: AppColors.green,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Pressable(
              onTap: onMenu,
              child: const Padding(
                padding: EdgeInsets.only(top: 3, left: 4),
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        // Rest stays a line of its own — it is the one thing here you set
        // rather than log.
        Pressable(
          onTap: onRestTap,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Text(
                  'Rest timer',
                  style: monoStyle(size: 11, letterSpacing: 1.5),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatRestLabel(restSeconds).toUpperCase(),
                  style: monoStyle(
                    size: 11,
                    letterSpacing: 1.5,
                    color: restSeconds > 0
                        ? AppColors.accentPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        // Column heads
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
          child: _SetGridRow(
            leading: _columnHead('SET'),
            middle: _columnHead('LAST'),
            goal: _goalLabel == null ? null : _columnHead('GOAL'),
            weight: isWeighted ? _columnHead('KG') : null,
            value: _columnHead(isTimed ? 'TIME' : 'REPS'),
            trailing: const SizedBox.shrink(),
          ),
        ),
        for (final set in sets) _buildSetRow(context, set),
        Pressable(
          onTap: onAddSet,
          child: const Padding(
            padding: EdgeInsets.only(top: 14, bottom: 2),
            child: Text(
              '+  Add set',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static final _columnLabelStyle = monoStyle(size: 10, letterSpacing: 1.4);

  /// A column head, kept to one line. Tracked-out mono is wider than it looks
  /// — SET alone is 22.2pt — and a head that wraps reads as a broken row
  /// rather than a narrow column.
  static Widget _columnHead(String label) => Text(
        label,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: _columnLabelStyle,
      );

  Widget _buildSetRow(BuildContext context, _WorkoutSetDraft set) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      child: _SetGridRow(
        leading: Text(
          '${set.number}',
          textAlign: TextAlign.center,
          style: monoStyle(
            size: 14,
            letterSpacing: 0,
            color: AppColors.textPrimary,
          ),
        ),
        middle: Text(
          set.previousLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: set.previousLabel == _noPreviousLabel
              ? _historyStyle.copyWith(color: AppColors.textMuted)
              : _historyStyle,
        ),
        goal: _goalLabel == null
            ? null
            : Text(
                _goalLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _historyStyle,
              ),
        weight: isWeighted
            ? _WeightField(
                key: ValueKey('kg-${item.exercise.id}-${set.number}'),
                weightKg: set.weightKg,
                completed: set.completed,
                isEdited: set.isEdited,
                onChanged: (value) => onWeightChanged(set.number, value),
                onFocusChanged: onRepFocusChanged,
              )
            : null,
        value: _RepField(
          key: ValueKey('rep-${item.exercise.id}-${set.number}'),
          value: set.target,
          completed: set.completed,
          isEdited: set.isEdited,
          onChanged: (value) => onValueChanged(set.number, value),
          onFocusChanged: onRepFocusChanged,
        ),
        trailing: Align(
          alignment: Alignment.centerRight,
          child: Pressable(
            onTap: () => onToggleSet(set.number),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: set.completed ? AppColors.green : Colors.transparent,
                shape: BoxShape.circle,
                border: set.completed
                    ? null
                    : Border.all(color: AppColors.surface3, width: 1.5),
              ),
              alignment: Alignment.center,
              // The tick is always there — gray while the set waits, dark on
              // green once it is logged, the way every other done-state tick
              // in the app is drawn.
              child: Icon(
                Icons.check_rounded,
                size: 14,
                color: set.completed ? AppColors.bg : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );

    // A logged set is tinted across every column — the whole line is done,
    // not just the tick at the end of it. The tint bleeds back out over the
    // list's side padding so it runs edge to edge, and squares off: a fill
    // that reaches the screen has no corners to round. It replaces the
    // hairline rather than sitting under it.
    final row = set.completed
        ? Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                top: 0,
                bottom: 0,
                left: -_workoutSidePadding,
                right: -_workoutSidePadding,
                child: ColoredBox(color: AppColors.greenSoft),
              ),
              content,
            ],
          )
        : DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.cardHighlight)),
            ),
            child: content,
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
}

/// Shared grid used by the set header and set rows:
/// set number · last session · [goal] · [kg] · value · check.
///
/// Both middle columns are optional. A lift with no prescribed target drops
/// GOAL rather than filling it with a dash, and a loaded lift takes a KG
/// column — where every column tightens to make room, since the row still
/// has to fit a phone.
class _SetGridRow extends StatelessWidget {
  final Widget leading;
  final Widget middle;
  final Widget? goal;
  final Widget? weight;
  final Widget value;
  final Widget trailing;

  const _SetGridRow({
    required this.leading,
    required this.middle,
    this.goal,
    this.weight,
    required this.value,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final loaded = weight != null;
    final gap = SizedBox(width: loaded ? 6 : 10);

    return Row(
      children: [
        // Wide enough for the word SET, which at this tracking is 22.2pt and
        // wraps its T onto a second line in anything narrower.
        SizedBox(width: loaded ? 26 : 30, child: leading),
        gap,
        Expanded(child: middle),
        if (goal != null) ...[
          gap,
          // A loaded goal reads "60kg x 8", so it needs the room a bare rep
          // count does not.
          SizedBox(width: loaded ? 70 : 52, child: goal),
        ],
        if (loaded) ...[
          gap,
          SizedBox(width: 50, child: weight),
        ],
        gap,
        SizedBox(width: loaded ? 42 : 70, child: value),
        gap,
        SizedBox(width: 26, child: trailing),
      ],
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

/// Rest, across the foot of the workout. It sits over the list rather than
/// floating above it because rest is the state the screen is in, not a
/// notice about it — and while it is up, the two things you might want are
/// more rest or less, so they are a thumb's reach from the clock.
class _RestTimerBar extends StatelessWidget {
  final String label;

  /// Rest still to run, 0–1. Drains left to right along the top edge.
  final double progress;
  final ValueChanged<int> onAdjust;
  final VoidCallback onSkip;

  const _RestTimerBar({
    required this.label,
    required this.progress,
    required this.onAdjust,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        border: Border(top: BorderSide(color: AppColors.cardHighlight)),
        boxShadow: [
          BoxShadow(
            color: Color(0x8C000000),
            offset: Offset(0, -8),
            blurRadius: 28,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The clock read as a line: how much rest is left, without doing
          // arithmetic on the digits.
          SizedBox(
            height: _restBarProgressHeight,
            width: double.infinity,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: const ColoredBox(color: AppColors.accentPrimary),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  _RestAdjustButton(
                    label: '−10',
                    onTap: () => onAdjust(-10),
                  ),
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  _RestAdjustButton(
                    label: '+10',
                    onTap: () => onAdjust(10),
                  ),
                  const SizedBox(width: 10),
                  Pressable(
                    onTap: onSkip,
                    child: Container(
                      height: _restBarControlHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.bg,
                        ),
                      ),
                    ),
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

class _RestAdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RestAdjustButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: _restBarControlHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
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

// ── Drafts & helpers ──────────────────────────────────────────────────

class _WorkoutSetDraft {
  final int number;
  final int target;

  /// Load for this set, on a reps-and-weight lift. Seeded from the last
  /// session's matching set, the way [target] is seeded from the prescribed
  /// progression, and 0 on everything that isn't loaded.
  final double weightKg;
  final String previousLabel;
  final bool completed;
  final bool isEdited;

  const _WorkoutSetDraft({
    required this.number,
    required this.target,
    this.weightKg = 0,
    required this.previousLabel,
    this.completed = false,
    this.isEdited = false,
  });

  bool get hasData => (completed || isEdited) && target > 0;

  _WorkoutSetDraft copyWith({
    int? number,
    int? target,
    double? weightKg,
    String? previousLabel,
    bool? completed,
    bool? isEdited,
  }) {
    return _WorkoutSetDraft(
      number: number ?? this.number,
      target: target ?? this.target,
      weightKg: weightKg ?? this.weightKg,
      previousLabel: previousLabel ?? this.previousLabel,
      completed: completed ?? this.completed,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}

/// A load as the app writes it inside a row: whole numbers stay whole, halves
/// keep their decimal. No unit — the column is already headed KG.
String _kgText(double weightKg) {
  final rounded = (weightKg * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? '${rounded.round()}'
      : '$rounded';
}

/// What the last session's matching set read as, for the LAST column. Reps
/// are a count and holds are seconds; anything carrying load leads with it —
/// "60kg x 8", or "20kg x 30s" for a loaded hold.
String previousSetLabel(Exercise exercise, ExerciseSet? set) {
  if (set == null) return _noPreviousLabel;
  final load = exercise.isWeighted ? '${_kgText(set.weightKg)}kg x ' : '';

  if (exercise.isTimed) {
    return set.durationSeconds > 0
        ? '$load${set.durationSeconds}s'
        : _noPreviousLabel;
  }
  return set.reps > 0 ? '$load${set.reps}' : _noPreviousLabel;
}

String _formatRestLabel(int seconds) {
  if (seconds <= 0) return 'Off';
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  if (remainder == 0) return '$minutes min';
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

/// The rest clock, always mm:ss — the minutes are padded too, so the digits
/// do not shift under the eye as the count passes a minute.
String _formatCountdownLabel(int seconds) {
  final safeSeconds = seconds.clamp(0, 59 * 60 + 59);
  final minutes = safeSeconds ~/ 60;
  final remainder = safeSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainder.toString().padLeft(2, '0')}';
}

// Timed detection lives in ExerciseProgressionService so the targets shown
// in a workout are exactly the targets that advance progression.
bool _isTimedExercise(Exercise exercise) =>
    ExerciseProgressionService.isTimedExercise(exercise);

TrainingTrack _trackForExercise(Exercise exercise) {
  switch (exercise.category) {
    case ExerciseCategory.skill:
    case ExerciseCategory.other:
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
