import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_log_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/progression_event_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/exercise_progression_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/progression_event_service.dart';
import '../../data/services/skill_track_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../../data/services/training_schedule_service.dart';
import '../../data/services/user_profile_service.dart';
import 'completed_workout_model.dart';

/// Post-workout celebration flow: a summary step that saves the session,
/// followed by one step per progression change the session earned — target
/// level-ups, masteries, and newly unlocked exercises — Duolingo-style.
class FinishedWorkoutView extends StatefulWidget {
  final CompletedWorkout workout;

  const FinishedWorkoutView({
    super.key,
    required this.workout,
  });

  @override
  State<FinishedWorkoutView> createState() => _FinishedWorkoutViewState();
}

class _FinishedWorkoutViewState extends State<FinishedWorkoutView>
    with SingleTickerProviderStateMixin {
  final _exerciseLogService = ExerciseLogService();
  late final AnimationController _confettiController;

  bool _saving = true;
  bool _saveFailed = false;

  /// A failed save can be retried, and a retry that gets further than the
  /// last attempt would otherwise report the same workout twice.
  bool _analyticsCaptured = false;
  int _stepIndex = 0;
  List<_CelebrationStep> _steps = const [_CelebrationStep.summary()];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _saveWorkout();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
      return;
    }

    setState(() {
      _saving = true;
      _saveFailed = false;
    });

    try {
      final sessionId = await _exerciseLogService.saveWorkoutSession(
        userId: userId,
        title: widget.workout.historyTitle,
        sessionType: widget.workout.sessionType.dbValue,
        startedAt: widget.workout.startedAt,
        finishedAt: widget.workout.finishedAt,
        scheduleSource: widget.workout.affectsSchedule
            ? widget.workout.plannedDate != null &&
                    !TrainingScheduleService.dateOnly(
                            widget.workout.plannedDate!)
                        .isAtSameMomentAs(
                      TrainingScheduleService.dateOnly(
                        widget.workout.finishedAt,
                      ),
                    )
                ? 'future_planned'
                : 'planned'
            : 'ad_hoc',
        plannedDate: widget.workout.plannedDate,
        plannedStepIndex: widget.workout.plannedStepIndex,
        exercises: widget.workout.exercises.map((exerciseEntry) {
          final sets = exerciseEntry.sets
              .map(
                (set) => ExerciseSet(
                  reps: set.isTimed ? 0 : set.value,
                  durationSeconds: set.isTimed ? set.value : 0,
                  weightKg: set.weightKg,
                ),
              )
              .toList();

          return WorkoutExerciseLogInput(
            exerciseId: exerciseEntry.exercise.id,
            sets: sets,
            isProgression: exerciseEntry.item.hasProgressionContext,
            trackId: exerciseEntry.track.dbValue,
            targetSets: exerciseEntry.targetSets ??
                ExerciseProgressionService.setCountForExercise(
                  exerciseEntry.exercise,
                ),
            targetValue: exerciseEntry.targetValue ??
                ExerciseProgressionService.targetValueForExercise(
                  exerciseEntry.exercise,
                ),
          );
        }).toList(),
      );

      if (widget.workout.affectsSchedule) {
        try {
          await TrainingProgramStoreService().markProgramStepCompleted(
            userId: userId,
            sessionType: widget.workout.sessionType,
            stepIndex: widget.workout.plannedStepIndex,
            plannedDate: widget.workout.plannedDate,
            completedAt: widget.workout.finishedAt,
            workoutSessionId: sessionId,
          );
        } catch (error, stackTrace) {
          // The workout itself is saved. If this write fails, the next reload
          // falls back to workout history and keeps the plan usable.
          debugPrint(
              'Failed to mark program step complete: $error\n$stackTrace');
        }
      }

      var events = const <ProgressionEvent>[];
      if (sessionId != null) {
        // Auto-progression: progression exercises whose logged volume reached
        // their current target climb the ladder, and reaching the live
        // mastery target masters them and unlocks the next move in their
        // skill path. Standalone/custom exercises are never auto-progressed.
        try {
          final progress = await ProgressService().fetchAll(userId);
          final logic =
              await TrainingProgramStoreService().fetchProgramLogic(userId);
          final goalIds = logic?.program.setupGoalIds ?? const <String>[];
          final tracks = await SkillTrackService().getOrSeed(
            userId,
            laneSelections: {
              ...TrainingProgramService().defaultBranchSelections(),
              ...?logic?.branchSelections,
            },
            goalSkillIds: goalIds,
          );
          double? bodyweightKg;
          try {
            bodyweightKg = await UserProfileService().fetchBodyweightKg(userId);
          } catch (_) {
            // Rep and timed shortcuts still work; weighted ones safely wait
            // until the profile value can be read.
          }
          await ExerciseProgressionService().applySessionResults(
            userId: userId,
            sessionId: sessionId,
            progressRows: {
              for (final entry in progress) entry.exerciseId: entry,
            },
            masterySettings:
                logic?.masteryTargets ?? MasteryTargetSettings.defaults,
            activeBranchByCategory: {
              for (final track in tracks) track.skillCategoryId: track.branchId,
            },
            goalSkillIds: goalIds,
            bodyweightKg: bodyweightKg,
            results: [
              for (final exerciseEntry in widget.workout.exercises)
                if (exerciseEntry.item.hasProgressionContext)
                  SessionExerciseResult(
                    exercise: exerciseEntry.exercise,
                    volume: exerciseEntry.sets
                        .fold<int>(0, (sum, set) => sum + set.value),
                    trackId: exerciseEntry.track.dbValue,
                    wasManuallyAdded:
                        exerciseEntry.item.isManualSkillTreeExercise,
                    sets: [
                      for (final set in exerciseEntry.sets)
                        SessionSetResult(
                          value: set.value,
                          weightKg: set.weightKg,
                        ),
                    ],
                  ),
            ],
          );
        } catch (error, stackTrace) {
          // Non-fatal: the user can still master the exercise manually from
          // the skill tree, and the next met target re-runs this.
          debugPrint(
              'Failed to apply exercise progression: $error\n$stackTrace');
        }

        // Personal bests: compare this session's best single-set values
        // against earlier history (any exercise, progression or standalone).
        try {
          await _recordPersonalBests(userId, sessionId);
        } catch (error, stackTrace) {
          // Non-fatal: PBs are informational; the workout itself is saved.
          debugPrint('Failed to record personal bests: $error\n$stackTrace');
        }

        try {
          events = await ProgressionEventService()
              .fetchForSession(userId, sessionId);
        } catch (error, stackTrace) {
          // Non-fatal: without events the flow simply ends at the summary.
          debugPrint('Failed to load progression events: $error\n$stackTrace');
        }
      }

      if (!_analyticsCaptured) {
        _analyticsCaptured = true;
        _captureWorkoutAnalytics(sessionId, events);
      }

      if (!mounted) return;
      setState(() {
        _saving = false;
        _steps = _buildSteps(events);
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to save workout: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
    }
  }

  /// One `workout_finished` for the session, then one `exercise_progressed`
  /// per ladder move it earned: a raised rep target is a rep progression, a
  /// mastery is a level-up (the follow-up `activated` event is the same
  /// level-up seen from the new exercise, so it is not reported again).
  void _captureWorkoutAnalytics(
      String? sessionId, List<ProgressionEvent> events) {
    var plannedSets = 0;
    var plannedReps = 0;
    for (final exerciseEntry in widget.workout.exercises) {
      final sets = exerciseEntry.targetSets ??
          ExerciseProgressionService.setCountForExercise(
              exerciseEntry.exercise);
      final value = exerciseEntry.targetValue ??
          ExerciseProgressionService.targetValueForExercise(
            exerciseEntry.exercise,
          );
      plannedSets += sets;
      if (!exerciseEntry.isTimed) plannedReps += sets * value;
    }

    AnalyticsService.capture('workout_finished', properties: {
      if (sessionId != null) 'workout_id': sessionId,
      if (widget.workout.analyticsId != null)
        'workout_client_id': widget.workout.analyticsId!,
      'session_type': widget.workout.sessionType.dbValue,
      'duration_seconds': widget.workout.totalDuration.inSeconds,
      'exercise_count': widget.workout.exercises.length,
      'completed_sets': widget.workout.totalSets,
      'planned_sets': plannedSets,
      'completed_reps': widget.workout.totalReps,
      'planned_reps': plannedReps,
      if (widget.workout.totalTimedSeconds > 0)
        'completed_timed_seconds': widget.workout.totalTimedSeconds,
    });

    for (final event in events) {
      final progressionType = switch (event.kind) {
        ProgressionEventKind.targetIncrease => 'rep_progression',
        ProgressionEventKind.mastered => 'level_up',
        _ => null,
      };
      if (progressionType == null) continue;
      final skillTreeId =
          ExerciseCatalog.findById(event.exerciseId)?.skillCategoryId;
      AnalyticsService.capture('exercise_progressed', properties: {
        if (sessionId != null) 'workout_id': sessionId,
        'exercise_id': event.exerciseId,
        'progression_type': progressionType,
        if (skillTreeId != null && skillTreeId.isNotEmpty)
          'skill_tree_id': skillTreeId,
        if (event.trackId != null) 'track_id': event.trackId!,
        if (event.valueFrom != null) 'value_from': event.valueFrom!,
        if (event.valueTo != null) 'value_to': event.valueTo!,
      });
    }
  }

  Future<void> _recordPersonalBests(String userId, String sessionId) async {
    final candidates = [
      for (final exerciseEntry in widget.workout.exercises)
        if (exerciseEntry.sets.isNotEmpty)
          PersonalBestCandidate(
            exerciseId: exerciseEntry.exercise.id,
            trackId: exerciseEntry.item.hasProgressionContext
                ? exerciseEntry.track.dbValue
                : null,
            bestSetValue: exerciseEntry.sets
                .fold<int>(0, (best, set) => math.max(best, set.value)),
          ),
    ];
    if (candidates.isEmpty) return;

    final previousBests = await _exerciseLogService.bestSetValues(
      userId,
      {for (final candidate in candidates) candidate.exerciseId},
      excludeSessionId: sessionId,
    );
    await ProgressionEventService().insertAll(
      userId,
      sessionId,
      ProgressionEventService.computePersonalBests(
        candidates: candidates,
        previousBests: previousBests,
      ),
    );
  }

  /// Summary first, then level-ups, standalone masteries, and unlocks —
  /// the order the story reads best in. PBs live on the Progress tab.
  List<_CelebrationStep> _buildSteps(List<ProgressionEvent> events) {
    final activatedByRelated = {
      for (final event in events)
        if (event.kind == ProgressionEventKind.activated &&
            event.relatedExerciseId != null)
          event.relatedExerciseId!: event,
    };
    final masteredById = {
      for (final event in events)
        if (event.kind == ProgressionEventKind.mastered)
          event.exerciseId: event,
    };

    final steps = <_CelebrationStep>[const _CelebrationStep.summary()];

    for (final event in events) {
      if (event.kind != ProgressionEventKind.targetIncrease) continue;
      final exercise = ExerciseCatalog.findById(event.exerciseId);
      if (exercise == null) continue;
      steps.add(_CelebrationStep.levelUp(_LevelUpData(
        exercise: exercise,
        sets: event.targetSets ?? 3,
        from: event.valueFrom ?? 0,
        to: event.valueTo ?? 0,
      )));
    }

    // Masteries without an unlock (branch points, completed paths).
    for (final event in events) {
      if (event.kind != ProgressionEventKind.mastered) continue;
      if (activatedByRelated.containsKey(event.exerciseId)) continue;
      final exercise = ExerciseCatalog.findById(event.exerciseId);
      if (exercise == null) continue;
      steps.add(_CelebrationStep.mastered(_MasteredData(
        exercise: exercise,
        sets: event.targetSets ?? 3,
        value: event.valueTo ?? 0,
      )));
    }

    for (final event in events) {
      if (event.kind != ProgressionEventKind.activated) continue;
      final unlock = _resolveUnlock(event, masteredById);
      if (unlock != null) steps.add(_CelebrationStep.unlock(unlock));
    }

    return steps;
  }

  _UnlockData? _resolveUnlock(
    ProgressionEvent event,
    Map<String, ProgressionEvent> masteredById,
  ) {
    final newExercise = ExerciseCatalog.findById(event.exerciseId);
    final mastered = event.relatedExerciseId == null
        ? null
        : ExerciseCatalog.findById(event.relatedExerciseId!);
    if (newExercise == null || mastered == null) return null;

    // A valueFrom on an activation is the ledger marker for a manual
    // fast-forward. It can cross several nodes (or branches), so render the
    // existing exercise-change animation around its source and destination
    // instead of requiring adjacency.
    if (event.valueFrom != null) {
      for (final category in SkillCategoryCatalog.all()) {
        for (final entry in category.trainingPaths.entries) {
          if (!entry.value.contains(newExercise.id)) continue;
          return _UnlockData(
            newExercise: newExercise,
            mastered: mastered,
            startSets: event.targetSets ?? 3,
            startValue: event.valueTo ??
                ExerciseProgressionService.initialTargetValueForExercise(
                  newExercise,
                ),
            masterySets: 3,
            masteryValue: event.valueFrom!,
            treeTitle: category.title,
            branchLabel: _branchLabel(category, entry.key),
            nodeNames: [mastered.name, newExercise.name],
            clearedIndex: 0,
            isShortcut: true,
          );
        }
      }
    }

    // The path this unlock happened on: mastered followed by the new move.
    for (final category in SkillCategoryCatalog.all()) {
      for (final entry in category.trainingPaths.entries) {
        final path = entry.value;
        final index = path.indexOf(mastered.id);
        if (index < 0 ||
            index + 1 >= path.length ||
            path[index + 1] != newExercise.id) {
          continue;
        }

        // Window of up to five nodes around the cleared one.
        final start = math.max(0, index - 2);
        final end = math.min(path.length, index + 3);
        final masteredEvent = masteredById[mastered.id];

        return _UnlockData(
          newExercise: newExercise,
          mastered: mastered,
          startSets: event.targetSets ?? 3,
          startValue: event.valueTo ??
              ExerciseProgressionService.initialTargetValueForExercise(
                newExercise,
              ),
          masterySets: masteredEvent?.targetSets ?? 3,
          masteryValue: masteredEvent?.valueTo ?? 0,
          treeTitle: category.title,
          branchLabel: _branchLabel(category, entry.key),
          nodeNames: [
            for (final id in path.sublist(start, end))
              ExerciseCatalog.findById(id)?.name ?? id,
          ],
          clearedIndex: index - start,
          isShortcut: false,
        );
      }
    }
    return null;
  }

  String _branchLabel(SkillCategory category, String pathId) {
    for (final branch in category.branches) {
      if (branch.id == pathId) return branch.label;
    }
    return pathId == 'main' ? 'Main line' : pathId;
  }

  void _advance() {
    if (_stepIndex >= _steps.length - 1) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _stepIndex += 1);
  }

  void _skip() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String get _ctaLabel {
    if (_saving) return 'Saving';
    if (_saveFailed) return 'Try again';
    if (_stepIndex == _steps.length - 1) return 'Nice work';
    return _stepIndex == 0 ? "See what's new" : 'Continue';
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _saving) return;
        if (_saveFailed) {
          // Nothing was saved — back returns to the workout to retry.
          Navigator.of(context).pop();
        } else {
          // Saved: leaving the flow means done, never back into the
          // finished workout where a second save could be triggered.
          _skip();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            if (_stepIndex == 0)
              AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    painter:
                        _ConfettiPainter(progress: _confettiController.value),
                    size: Size.infinite,
                  );
                },
              ),
            SafeArea(
              child: Column(
                children: [
                  // Progress bars + skip. The row keeps its full height and
                  // the close button's slot from the first frame — while the
                  // save is running the button is merely invisible — so
                  // nothing below moves when the save lands. The bars
                  // themselves crossfade from the lone placeholder to the
                  // real set rather than snapping.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: SizedBox(
                      height: 30,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Row(
                                key: ValueKey(_steps.length),
                                children: [
                                  for (var i = 0; i < _steps.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 350),
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: i <= _stepIndex
                                              ? AppColors.accentPrimary
                                              : Colors.white
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IgnorePointer(
                            ignoring: _saving || _saveFailed,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: _saving || _saveFailed ? 0 : 1,
                              child: Pressable(
                                onTap: _skip,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: AppColors.surface,
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: switch (step) {
                      _SummaryStep() => _SummaryContent(
                          workout: widget.workout,
                          hasNext: _steps.length > 1,
                        ),
                      _LevelUpStep(data: final data) => _LevelUpContent(
                          key: ValueKey(data.exercise.id), data: data),
                      _MasteredStep(data: final data) => _MasteredContent(
                          key: ValueKey(data.exercise.id), data: data),
                      _UnlockStep(data: final data) => _UnlockContent(
                          key: ValueKey(data.newExercise.id), data: data),
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: PillButton(
                      label: _ctaLabel,
                      onTap: _saving
                          ? null
                          : _saveFailed
                              ? _saveWorkout
                              : _advance,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Steps ─────────────────────────────────────────────────────────────

sealed class _CelebrationStep {
  const _CelebrationStep();

  const factory _CelebrationStep.summary() = _SummaryStep;
  const factory _CelebrationStep.levelUp(_LevelUpData data) = _LevelUpStep;
  const factory _CelebrationStep.mastered(_MasteredData data) = _MasteredStep;
  const factory _CelebrationStep.unlock(_UnlockData data) = _UnlockStep;
}

class _SummaryStep extends _CelebrationStep {
  const _SummaryStep();
}

class _LevelUpStep extends _CelebrationStep {
  final _LevelUpData data;
  const _LevelUpStep(this.data);
}

class _MasteredStep extends _CelebrationStep {
  final _MasteredData data;
  const _MasteredStep(this.data);
}

class _UnlockStep extends _CelebrationStep {
  final _UnlockData data;
  const _UnlockStep(this.data);
}

class _LevelUpData {
  final Exercise exercise;
  final int sets;
  final int from;
  final int to;

  const _LevelUpData({
    required this.exercise,
    required this.sets,
    required this.from,
    required this.to,
  });
}

class _MasteredData {
  final Exercise exercise;
  final int sets;
  final int value;

  const _MasteredData({
    required this.exercise,
    required this.sets,
    required this.value,
  });
}

class _UnlockData {
  final Exercise newExercise;
  final Exercise mastered;
  final int startSets;
  final int startValue;
  final int masterySets;
  final int masteryValue;
  final String treeTitle;
  final String branchLabel;
  final List<String> nodeNames;
  final int clearedIndex;
  final bool isShortcut;

  const _UnlockData({
    required this.newExercise,
    required this.mastered,
    required this.startSets,
    required this.startValue,
    required this.masterySets,
    required this.masteryValue,
    required this.treeTitle,
    required this.branchLabel,
    required this.nodeNames,
    required this.clearedIndex,
    required this.isShortcut,
  });
}

// ── Summary step ──────────────────────────────────────────────────────

class _SummaryContent extends StatelessWidget {
  final CompletedWorkout workout;
  final bool hasNext;

  const _SummaryContent({
    required this.workout,
    required this.hasNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 26, 30, 12),
      child: Column(
        children: [
          const _RiseIn(
            delay: Duration.zero,
            child: _CelebrationBadge(
              color: AppColors.green,
              size: 84,
              child: Icon(
                Icons.check_rounded,
                size: 40,
                color: AppColors.green,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _RiseIn(
            delay: Duration(milliseconds: 40),
            child: Text(
              'Workout complete',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _RiseIn(
            delay: const Duration(milliseconds: 80),
            child: Text(
              '${workout.historyTitle} · '
              '${_formatFinishedAt(workout.finishedAt)}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _RiseIn(
            delay: const Duration(milliseconds: 120),
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: 'DURATION',
                      value: _formatDuration(workout.totalDuration),
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: 'SETS',
                      value: '${workout.totalSets}',
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: 'EXERCISES',
                      value: '${workout.exercises.length}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _RiseIn(
            delay: const Duration(milliseconds: 160),
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < workout.exercises.length; i++)
                    Container(
                      decoration: i > 0
                          ? const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.divider),
                              ),
                            )
                          : null,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              workout.exercises[i].exercise.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _setsSummary(workout.exercises[i]),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (hasNext) ...[
            const SizedBox(height: 18),
            const _RiseIn(
              delay: Duration(milliseconds: 220),
              child: Text(
                "There's more — keep going.",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _setsSummary(CompletedWorkoutExercise exercise) {
    return exercise.sets
        .map((set) => set.isTimed ? '${set.value}s' : '${set.value}')
        .join(' · ');
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

// ── Level-up step ─────────────────────────────────────────────────────

class _LevelUpContent extends StatelessWidget {
  final _LevelUpData data;

  const _LevelUpContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final suffix = data.exercise.isTimed ? 's' : '';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _CelebrationTag(color: AppColors.amber, label: 'Level up'),
            const SizedBox(height: 8),
            _RiseIn(
              delay: const Duration(milliseconds: 80),
              child: Text(
                data.exercise.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _RiseIn(
              delay: const Duration(milliseconds: 160),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${data.sets} ×',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 9),
                  _RollingValue(
                    from: '${data.from}$suffix',
                    to: '${data.to}$suffix',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _RiseIn(
              delay: const Duration(milliseconds: 650),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  'You hit the target goal of ${data.sets} × '
                  '${data.from}$suffix. Your target has been raised.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
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

// ── Mastered step (branch point / completed path) ─────────────────────

class _MasteredContent extends StatelessWidget {
  final _MasteredData data;

  const _MasteredContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final suffix = data.exercise.isTimed ? 's' : '';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _CelebrationTag(color: AppColors.green, label: 'Mastered'),
            const SizedBox(height: 8),
            _RiseIn(
              delay: const Duration(milliseconds: 80),
              child: Text(
                data.exercise.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _RiseIn(
              delay: const Duration(milliseconds: 160),
              child: Text(
                '${data.sets} × ${data.value}$suffix',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _RiseIn(
              delay: const Duration(milliseconds: 280),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  'You cleared the mastery target — '
                  '${data.exercise.name} is yours now.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
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

// ── Unlock step ───────────────────────────────────────────────────────

/// The previous exercise's bar fills to its mastery target, then the title
/// swaps to the newly unlocked exercise and the tree spine below clears the
/// working node and activates the next one.
class _UnlockContent extends StatefulWidget {
  final _UnlockData data;

  const _UnlockContent({super.key, required this.data});

  @override
  State<_UnlockContent> createState() => _UnlockContentState();
}

class _UnlockContentState extends State<_UnlockContent> {
  bool _fill = false;
  bool _swapped = false;
  Timer? _fillTimer;
  Timer? _swapTimer;

  @override
  void initState() {
    super.initState();
    _fillTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _fill = true);
    });
    _swapTimer = Timer(const Duration(milliseconds: 2150), () {
      if (mounted) {
        setState(() {
          _swapped = true;
          _fill = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _fillTimer?.cancel();
    _swapTimer?.cancel();
    super.dispose();
  }

  _NodeState _nodeState(int index) {
    final cleared = widget.data.clearedIndex;
    if (index < cleared) return _NodeState.done;
    if (index == cleared) {
      return _swapped ? _NodeState.done : _NodeState.current;
    }
    if (index == cleared + 1 && _swapped) return _NodeState.current;
    return _NodeState.locked;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final title = _swapped ? data.newExercise.name : data.mastered.name;
    final targetLabel = _swapped
        ? '${data.startSets} × ${data.startValue}'
            '${data.newExercise.isTimed ? 's' : ''}'
        : '${data.masterySets} × ${data.masteryValue}'
            '${data.mastered.isTimed ? 's' : ''}';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CelebrationTag(
              color: AppColors.accentPrimary,
              label: data.isShortcut
                  ? 'Exercise changed'
                  : 'New exercise unlocked',
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                title,
                key: ValueKey(title),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _RiseIn(
              delay: const Duration(milliseconds: 80),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _swapped
                              ? 'STARTING TARGET'
                              : data.isShortcut
                                  ? 'CURRENT TARGET'
                                  : 'PREREQUISITE',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.9,
                          ),
                        ),
                        Text(
                          targetLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _swapped
                                ? AppColors.textSecondary
                                : AppColors.accentPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: SizedBox(
                        height: 10,
                        child: Stack(
                          children: [
                            Container(color: AppColors.surface2),
                            AnimatedFractionallySizedBox(
                              duration: _fill
                                  ? const Duration(milliseconds: 1250)
                                  : Duration.zero,
                              curve: Curves.easeOutCubic,
                              widthFactor: _fill ? 1 : 0,
                              alignment: Alignment.centerLeft,
                              child: Container(color: AppColors.accentPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _RiseIn(
              delay: const Duration(milliseconds: 140),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${data.treeTitle.toUpperCase()} TREE',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentPrimary,
                            letterSpacing: 1.05,
                          ),
                        ),
                        Text(
                          data.branchLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    for (var i = 0; i < data.nodeNames.length; i++)
                      _TreeNode(
                        state: _nodeState(i),
                        name: data.nodeNames[i],
                        last: i == data.nodeNames.length - 1,
                        isNew: _swapped && i == data.clearedIndex + 1,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _swapped ? 1 : 0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: Text(
                  data.isShortcut
                      ? 'Your logged result moves your active exercise to '
                          '${data.newExercise.name}.'
                      : 'Clearing ${data.mastered.name} at '
                          '${data.masterySets} × ${data.masteryValue}'
                          '${data.mastered.isTimed ? 's' : ''} opens '
                          '${data.newExercise.name} — your next move on this '
                          'path.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.55,
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

enum _NodeState { done, current, locked }

class _TreeNode extends StatelessWidget {
  final _NodeState state;
  final String name;
  final bool last;
  final bool isNew;

  const _TreeNode({
    required this.state,
    required this.name,
    required this.last,
    required this.isNew,
  });

  static const _currentBlue = Color(0xFF4A8CFF);

  Color get _dotColor {
    switch (state) {
      case _NodeState.done:
        return AppColors.green;
      case _NodeState.current:
        return _currentBlue;
      case _NodeState.locked:
        return Colors.white.withValues(alpha: 0.16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state == _NodeState.locked
                        ? Colors.transparent
                        : _dotColor,
                    border: state == _NodeState.locked
                        ? Border.all(color: _dotColor, width: 2)
                        : null,
                    boxShadow: state == _NodeState.locked
                        ? null
                        : [
                            BoxShadow(
                              color: _dotColor.withValues(alpha: 0.18),
                              spreadRadius: 3.5,
                            ),
                          ],
                  ),
                ),
                if (!last)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: state == _NodeState.done
                            ? AppColors.green
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 18 / 13.5,
                        fontWeight: state == _NodeState.locked
                            ? FontWeight.w600
                            : FontWeight.w700,
                        color: switch (state) {
                          _NodeState.locked => AppColors.textMuted,
                          _NodeState.current => AppColors.textPrimary,
                          _NodeState.done => AppColors.textSecondary,
                        },
                      ),
                    ),
                  ),
                  if (isNew) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared celebration primitives ─────────────────────────────────────

class _CelebrationBadge extends StatelessWidget {
  final Color color;
  final double size;
  final Widget child;

  const _CelebrationBadge({
    required this.color,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 26,
            offset: const Offset(0, 12),
            spreadRadius: -8,
          ),
          const BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _CelebrationTag extends StatelessWidget {
  final Color color;
  final String label;

  const _CelebrationTag({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide-up + fade-in entrance, staggered by [delay].
class _RiseIn extends StatefulWidget {
  final Duration delay;
  final Widget child;

  const _RiseIn({
    required this.delay,
    required this.child,
  });

  @override
  State<_RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<_RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.32, 0.72, 0, 1),
    );

    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// Old value rolls up and out while the new value rolls in, odometer-style.
class _RollingValue extends StatefulWidget {
  final String from;
  final String to;

  const _RollingValue({
    required this.from,
    required this.to,
  });

  @override
  State<_RollingValue> createState() => _RollingValueState();
}

class _RollingValueState extends State<_RollingValue> {
  bool _rolled = false;
  Timer? _timer;

  static const _height = 38.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _rolled = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      height: _height / 32,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    // IntrinsicWidth pins the box to the text width, giving the OverflowBox a
    // bounded width constraint. Without it the surrounding Row hands down an
    // unbounded width and the OverflowBox (which sizes to the max constraint)
    // resolves to an infinite width, crashing layout.
    return ClipRect(
      child: IntrinsicWidth(
        child: SizedBox(
          height: _height,
          // The two stacked values are twice the visible height; OverflowBox
          // lets them lay out at full size so the slide can roll between them
          // without tripping the vertical-overflow error.
          child: OverflowBox(
            maxHeight: _height * 2,
            alignment: Alignment.topCenter,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 700),
              curve: const Cubic(0.65, 0, 0.35, 1),
              offset: _rolled ? const Offset(0, -0.5) : Offset.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.from,
                    style: style.copyWith(color: AppColors.textMuted),
                  ),
                  Text(
                    widget.to,
                    style: style.copyWith(color: AppColors.amber),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Confetti ──────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double progress;

  const _ConfettiPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(18);
    const colors = [
      AppColors.accentPrimary,
      AppColors.amber,
      AppColors.green,
    ];

    // One loop of the controller must land every piece exactly where it
    // started, or the wrap reads as the whole sky jumping. So each piece
    // falls a whole number of laps of the wrap distance per loop — the
    // speed variety comes from how many laps.
    final lap = size.height + 70;
    for (var i = 0; i < 54; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * lap;
      final laps = 1 + random.nextInt(2);
      final sway = math.sin((progress * math.pi * 2) + i) * 16;
      final x = baseX + sway;
      final y = ((baseY + progress * lap * laps) % lap) - 35;
      final width = 4 + random.nextDouble() * 3;
      final height = 9 + random.nextDouble() * 6;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.4);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * 2 + random.nextDouble() * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: width,
            height: height,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Formatting ────────────────────────────────────────────────────────

String _formatFinishedAt(DateTime dateTime) {
  final now = DateTime.now();
  final sameDay = now.year == dateTime.year &&
      now.month == dateTime.month &&
      now.day == dateTime.day;
  final datePrefix =
      sameDay ? 'Today' : '${dateTime.month}/${dateTime.day}/${dateTime.year}';

  return '$datePrefix at ${_formatTime(dateTime)}';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;

  return '$displayHour:$minute $suffix';
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  String twoDigits(int value) => value.toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  return '$minutes:${twoDigits(seconds)}';
}
