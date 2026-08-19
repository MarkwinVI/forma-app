import 'dart:async';

import '../models/training_program_model.dart';
import 'supabase_service.dart';
import 'training_schedule_service.dart';

class TrainingProgramStoreService {
  static const _defaultFrequencyPerWeek = 3;
  final _client = SupabaseService.client;

  /// Session cache of [fetchProgramLogic], keyed by user id. Every write in
  /// this service clears it (see [_write]), so a hit can only serve a
  /// snapshot no local write has touched. The shell's landing-tab check and
  /// each tab's load then share one fetch instead of repeating the same
  /// query chain back to back.
  static final _logicCache = <String, Future<TrainingProgramLogicSnapshot?>>{};

  /// For writers that touch the program tables without going through this
  /// service (dev tools reset).
  static void invalidateLogicCache() => _logicCache.clear();

  /// Runs a write and clears the logic cache when it settles — including a
  /// fetch that was cached mid-write — so no snapshot outlives the data it
  /// was read from.
  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await body();
    } finally {
      _logicCache.clear();
    }
  }

  Future<UserTrainingProgramSnapshot> getOrCreateActiveProgram(
    String userId,
  ) {
    return _write(() async {
      var program = await _fetchActiveProgram(userId);
      program ??= await _createProgram(
        userId: userId,
        programType: TrainingProgramType.fullBody,
      );

      var state = await _fetchProgramState(program.id);
      state ??= await _createProgramState(
        userId: userId,
        programId: program.id,
        programType: program.programType,
      );

      return UserTrainingProgramSnapshot(program: program, state: state);
    });
  }

  /// Fetch-only variant of [getOrCreateProgramLogic]: returns null when the
  /// user has not created a training program yet, so callers can show a
  /// first-run state instead of silently creating a default program.
  Future<TrainingProgramLogicSnapshot?> fetchProgramLogic(String userId) {
    return _logicCache[userId] ??= () {
      final future = _loadProgramLogic(userId);
      // A failed load must not stick around, or every retry would replay
      // the same error for the rest of the session.
      future.then<void>((_) {}, onError: (Object _) {
        if (identical(_logicCache[userId], future)) {
          _logicCache.remove(userId);
        }
      });
      return future;
    }();
  }

  Future<TrainingProgramLogicSnapshot?> _loadProgramLogic(
    String userId,
  ) async {
    // Branch selections only need the user id, so they ride alongside the
    // program row instead of queueing behind it.
    final (program, branchSelections) = await (
      _fetchActiveProgram(userId),
      _fetchBranchSelections(userId),
    ).wait;
    if (program == null) return null;

    var state = await _fetchProgramState(program.id);
    state ??= await _createProgramState(
      userId: userId,
      programId: program.id,
      programType: program.programType,
    );

    return TrainingProgramLogicSnapshot(
      program: program,
      state: state,
      branchSelections: branchSelections,
      repGoalProfile: _repGoalProfileFor(program),
      masteryTargets:
          MasteryTargetSettings.fromVariationRules(program.variationRules),
    );
  }

  Future<TrainingProgramLogicSnapshot> getOrCreateProgramLogic(
    String userId,
  ) async {
    final snapshot = await getOrCreateActiveProgram(userId);
    final branchSelections = await _fetchBranchSelections(userId);

    return TrainingProgramLogicSnapshot(
      program: snapshot.program,
      state: snapshot.state,
      branchSelections: branchSelections,
      repGoalProfile: _repGoalProfileFor(snapshot.program),
      masteryTargets: MasteryTargetSettings.fromVariationRules(
        snapshot.program.variationRules,
      ),
    );
  }

  /// Updates the live global mastery targets. Only the settings values
  /// change: no progress rows, stored targets, or mastered statuses are
  /// touched, and no past workouts are re-evaluated.
  Future<void> updateMasteryTargets({
    required String userId,
    required MasteryTargetSettings targets,
  }) {
    return _write(() async {
      final program = await _fetchActiveProgram(userId);
      if (program == null) return;

      await _client.from('user_training_programs').update({
        'variation_rules': {
          ...program.variationRules,
          ...targets.toVariationRules(),
        },
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', program.id);
    });
  }

  Future<UserTrainingProgramSnapshot> updateProgramType({
    required String userId,
    required TrainingProgramType programType,
  }) {
    return _write(() async {
      final existingProgram = await _fetchActiveProgram(userId);

      final program = existingProgram == null
          ? await _createProgram(userId: userId, programType: programType)
          : await _updateProgram(existingProgram, programType);

      final state = await _upsertProgramState(
        userId: userId,
        programId: program.id,
        programType: programType,
        frequencyPerWeek: program.frequencyPerWeek,
      );

      return UserTrainingProgramSnapshot(program: program, state: state);
    });
  }

  Future<UserTrainingProgram> updateGoalSkills({
    required String userId,
    required List<String> goalSkillIds,
  }) {
    return _write(() async {
      var program = await _fetchActiveProgram(userId);
      program ??= await _createProgram(
        userId: userId,
        programType: TrainingProgramType.fullBody,
      );

      final data = await _client
          .from('user_training_programs')
          .update({
            'goal_skills': goalSkillIds,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', program.id)
          .select()
          .single();

      return UserTrainingProgram.fromMap(data);
    });
  }

  Future<TrainingProgramLogicSnapshot> updateProgramLogic({
    required String userId,
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required RepGoalProfile repGoalProfile,
    required Map<String, dynamic> sessionItemsConfig,
    int? frequencyPerWeek,
    Map<String, dynamic>? setupAnswers,
  }) {
    return _write(() async {
      final existingProgram = await _fetchActiveProgram(userId);
      final variationRules = <String, dynamic>{
        ...?existingProgram?.variationRules,
        'rep_goal_profile': repGoalProfile.dbValue,
        'session_items_v1': sessionItemsConfig,
        if (setupAnswers != null) 'program_setup_v1': setupAnswers,
      };

      final program = existingProgram == null
          ? await _createProgram(
              userId: userId,
              programType: programType,
              variationRules: variationRules,
              frequencyPerWeek: frequencyPerWeek,
            )
          : await _updateProgram(
              existingProgram,
              programType,
              variationRules: variationRules,
              frequencyPerWeek: frequencyPerWeek,
            );

      final state = await _upsertProgramState(
        userId: userId,
        programId: program.id,
        programType: programType,
        previousProgramType: existingProgram?.programType,
        frequencyPerWeek: program.frequencyPerWeek,
      );

      await _upsertBranchSelections(userId, branchSelections);

      return TrainingProgramLogicSnapshot(
        program: program,
        state: state,
        branchSelections: branchSelections,
        repGoalProfile: repGoalProfile,
        masteryTargets:
            MasteryTargetSettings.fromVariationRules(program.variationRules),
      );
    });
  }

  /// Moves the program pointer one step along the schedule cycle. Called when
  /// a workout is saved (once per local day), so the stored state always
  /// means "the session after the last completed workout". Rest days are not
  /// advanced here — the dashboard rolls past them by date at display time.
  Future<void> advanceProgramStateAfterWorkout(String userId) {
    return _write(() async {
      final program = await _fetchActiveProgram(userId);
      if (program == null) return;

      final state = await _fetchProgramState(program.id);
      if (state == null) return;

      final cycle = scheduleCycleFor(
        programType: program.programType,
        frequencyPerWeek: program.frequencyPerWeek,
        dayMask: TrainingScheduleService.dayMaskFrom(program.variationRules),
      );
      if (cycle.isEmpty) return;

      var index = state.nextStepIndex;
      if (index < 0 ||
          index >= cycle.length ||
          cycle[index] != state.nextSessionType) {
        final matched = cycle.indexOf(state.nextSessionType);
        index = matched >= 0 ? matched : 0;
      }
      final nextIndex = (index + 1) % cycle.length;

      await _client.from('user_training_program_state').update({
        'next_step_index': nextIndex,
        'next_session_type': cycle[nextIndex].dbValue,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', state.id);
    });
  }

  /// Records the planned schedule step that was completed without advancing
  /// the pointer immediately. The dashboard resolves the next step from the
  /// local date, so today's completed state remains visible until tomorrow.
  Future<void> markProgramStepCompleted({
    required String userId,
    required TrainingSessionType sessionType,
    required DateTime completedAt,
    int? stepIndex,
    DateTime? plannedDate,
    String? workoutSessionId,
  }) {
    return _write(() async {
      final program = await _fetchActiveProgram(userId);
      if (program == null) return;

      final state = await _fetchProgramState(program.id);
      if (state == null) return;

      final cycle = scheduleCycleFor(
        programType: program.programType,
        frequencyPerWeek: program.frequencyPerWeek,
        dayMask: TrainingScheduleService.dayMaskFrom(program.variationRules),
      );
      if (cycle.isEmpty) return;

      final resolvedStepIndex = stepIndex == null ||
              stepIndex < 0 ||
              stepIndex >= cycle.length ||
              cycle[stepIndex] != sessionType
          ? _stepIndexForSessionType(
              programType: program.programType,
              sessionType: sessionType,
              frequencyPerWeek: program.frequencyPerWeek,
              dayMask:
                  TrainingScheduleService.dayMaskFrom(program.variationRules),
            )
          : stepIndex;

      await _client.from('user_training_program_state').update({
        'next_step_index': resolvedStepIndex,
        'next_session_type': sessionType.dbValue,
        'last_session_type': sessionType.dbValue,
        'last_completed_at': completedAt.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', state.id);

      await _client.from('user_training_session_events').insert({
        'program_id': program.id,
        'user_id': userId,
        'schedule_index': resolvedStepIndex,
        'session_type': sessionType.dbValue,
        'action': 'completed',
        'planned_date': TrainingScheduleService.dateOnly(
          plannedDate ?? completedAt,
        ).toIso8601String(),
        if (workoutSessionId != null) 'workout_session_id': workoutSessionId,
        'occurred_at': completedAt.toUtc().toIso8601String(),
      });
    });
  }

  /// Undoes one [advanceProgramStateAfterWorkout] step. Called when the only
  /// workout of a local day is deleted, so the slot it consumed in the split
  /// becomes due again.
  Future<void> rewindProgramStateAfterWorkoutDeletion(String userId) {
    return _write(() async {
      final program = await _fetchActiveProgram(userId);
      if (program == null) return;

      final state = await _fetchProgramState(program.id);
      if (state == null) return;

      final cycle = scheduleCycleFor(
        programType: program.programType,
        frequencyPerWeek: program.frequencyPerWeek,
        dayMask: TrainingScheduleService.dayMaskFrom(program.variationRules),
      );
      if (cycle.isEmpty) return;

      var index = state.nextStepIndex;
      if (index < 0 ||
          index >= cycle.length ||
          cycle[index] != state.nextSessionType) {
        final matched = cycle.indexOf(state.nextSessionType);
        index = matched >= 0 ? matched : 0;
      }
      final previousIndex = (index - 1 + cycle.length) % cycle.length;

      await _client.from('user_training_program_state').update({
        'next_step_index': previousIndex,
        'next_session_type': cycle[previousIndex].dbValue,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', state.id);
    });
  }

  /// Rebuilds the stored current-step marker from the newest remaining
  /// planned workout. Used after workout deletion because schedule state no
  /// longer advances blindly on save.
  Future<void> syncProgramStateToLatestPlannedWorkout(String userId) {
    return _write(() async {
      final program = await _fetchActiveProgram(userId);
      if (program == null) return;

      final state = await _fetchProgramState(program.id);
      if (state == null) return;

      final latest = await _client
          .from('workout_sessions')
          .select('session_type, finished_at, planned_step_index')
          .eq('user_id', userId)
          .neq('schedule_source', 'ad_hoc')
          .order('finished_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final TrainingSessionType sessionType;
      final int stepIndex;
      final DateTime? completedAt;
      if (latest == null) {
        sessionType = _defaultSessionType(program.programType);
        stepIndex = 0;
        completedAt = null;
      } else {
        sessionType = TrainingSessionTypeX.fromDbValue(
          latest['session_type'] as String,
        );
        stepIndex = latest['planned_step_index'] as int? ??
            _stepIndexForSessionType(
              programType: program.programType,
              sessionType: sessionType,
              frequencyPerWeek: program.frequencyPerWeek,
            );
        completedAt = DateTime.parse(latest['finished_at'] as String);
      }

      await _client.from('user_training_program_state').update({
        'next_step_index': stepIndex,
        'next_session_type': sessionType.dbValue,
        'last_session_type': latest == null ? null : sessionType.dbValue,
        'last_completed_at': completedAt?.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', state.id);
    });
  }

  Future<UserTrainingProgram?> _fetchActiveProgram(String userId) async {
    final data = await _client
        .from('user_training_programs')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();

    if (data == null) return null;
    return UserTrainingProgram.fromMap(data);
  }

  Future<UserTrainingProgramState?> _fetchProgramState(String programId) async {
    final data = await _client
        .from('user_training_program_state')
        .select()
        .eq('program_id', programId)
        .maybeSingle();

    if (data == null) return null;
    return UserTrainingProgramState.fromMap(data);
  }

  Future<UserTrainingProgram> _createProgram({
    required String userId,
    required TrainingProgramType programType,
    Map<String, dynamic> variationRules = const {},
    int? frequencyPerWeek,
  }) async {
    final data = await _client
        .from('user_training_programs')
        .insert({
          'user_id': userId,
          'program_type': programType.dbValue,
          'schedule_variant': _defaultScheduleVariant(programType),
          'frequency_per_week': frequencyPerWeek ?? _defaultFrequencyPerWeek,
          'variation_rules': variationRules,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return UserTrainingProgram.fromMap(data);
  }

  Future<UserTrainingProgram> _updateProgram(
      UserTrainingProgram program, TrainingProgramType programType,
      {Map<String, dynamic>? variationRules, int? frequencyPerWeek}) async {
    final data = await _client
        .from('user_training_programs')
        .update({
          'program_type': programType.dbValue,
          'schedule_variant': _defaultScheduleVariant(programType),
          // Keep the frequency chosen during program setup unless the caller
          // is explicitly changing it.
          'frequency_per_week': frequencyPerWeek ?? program.frequencyPerWeek,
          if (variationRules != null) 'variation_rules': variationRules,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', program.id)
        .select()
        .single();

    return UserTrainingProgram.fromMap(data);
  }

  Future<UserTrainingProgramState> _createProgramState({
    required String userId,
    required String programId,
    required TrainingProgramType programType,
  }) async {
    final data = await _client
        .from('user_training_program_state')
        .insert({
          'program_id': programId,
          'user_id': userId,
          'next_step_index': 0,
          'next_session_type': _defaultSessionType(programType).dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return UserTrainingProgramState.fromMap(data);
  }

  Future<UserTrainingProgramState> _upsertProgramState({
    required String userId,
    required String programId,
    required TrainingProgramType programType,
    int frequencyPerWeek = 3,
    TrainingProgramType? previousProgramType,
  }) async {
    final existingState = await _fetchProgramState(programId);

    if (existingState == null) {
      return _createProgramState(
        userId: userId,
        programId: programId,
        programType: programType,
      );
    }

    final sameProgramType =
        previousProgramType == null || previousProgramType == programType;
    final nextSessionType = sameProgramType
        ? existingState.nextSessionType
        : _remapSessionType(
            current: existingState.nextSessionType,
            programType: programType,
            frequencyPerWeek: frequencyPerWeek,
          );
    final nextStepIndex = sameProgramType
        ? existingState.nextStepIndex
        : _stepIndexForSessionType(
            programType: programType,
            sessionType: nextSessionType,
            frequencyPerWeek: frequencyPerWeek,
          );

    final data = await _client
        .from('user_training_program_state')
        .update({
          'next_step_index': nextStepIndex,
          'next_session_type': nextSessionType.dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', existingState.id)
        .select()
        .single();

    return UserTrainingProgramState.fromMap(data);
  }

  /// Saves branch selections for individual tracks — used by goal-driven
  /// fork resolution when mastery switches a track onto a goal's branch.
  Future<void> upsertBranchSelections(
    String userId,
    Map<TrainingTrack, String> selections,
  ) {
    return _write(() => _upsertBranchSelections(userId, selections));
  }

  Future<Map<TrainingTrack, String>> _fetchBranchSelections(
    String userId,
  ) async {
    final data = await _client
        .from('user_progression_branches')
        .select('track_id, branch_id')
        .eq('user_id', userId);

    return {
      for (final row in data)
        TrainingTrackX.fromDbValue(row['track_id'] as String):
            row['branch_id'] as String,
    };
  }

  Future<void> _upsertBranchSelections(
    String userId,
    Map<TrainingTrack, String> branchSelections,
  ) async {
    if (branchSelections.isEmpty) return;

    await _client.from('user_progression_branches').upsert(
      [
        for (final entry in branchSelections.entries)
          {
            'user_id': userId,
            'track_id': entry.key.dbValue,
            'branch_id': entry.value,
            'updated_at': DateTime.now().toIso8601String(),
          },
      ],
      onConflict: 'user_id,track_id',
    );
  }

  RepGoalProfile _repGoalProfileFor(UserTrainingProgram program) {
    return RepGoalProfileX.fromDbValue(
      program.variationRules['rep_goal_profile'] as String?,
    );
  }

  String _defaultScheduleVariant(TrainingProgramType programType) {
    switch (programType) {
      case TrainingProgramType.fullBody:
        return 'full_body_3x';
      case TrainingProgramType.pushPull:
        return 'push_rest_pull_rest_push_pull_rest';
      case TrainingProgramType.upperLower:
        return 'upper_rest_lower_rest_upper_lower_rest';
    }
  }

  TrainingSessionType _defaultSessionType(TrainingProgramType programType) {
    switch (programType) {
      case TrainingProgramType.fullBody:
        return TrainingSessionType.fullBody;
      case TrainingProgramType.pushPull:
        return TrainingSessionType.push;
      case TrainingProgramType.upperLower:
        return TrainingSessionType.upper;
    }
  }

  TrainingSessionType _remapSessionType({
    required TrainingSessionType current,
    required TrainingProgramType programType,
    int frequencyPerWeek = 3,
    List<int>? dayMask,
  }) {
    final cycle = scheduleCycleFor(
      programType: programType,
      frequencyPerWeek: frequencyPerWeek,
      dayMask: dayMask,
    );
    if (cycle.contains(current)) {
      return current;
    }
    if (current == TrainingSessionType.rest) {
      return TrainingSessionType.rest;
    }
    return _defaultSessionType(programType);
  }

  int _stepIndexForSessionType({
    required TrainingProgramType programType,
    required TrainingSessionType sessionType,
    int frequencyPerWeek = 3,
    List<int>? dayMask,
  }) {
    final cycle = scheduleCycleFor(
      programType: programType,
      frequencyPerWeek: frequencyPerWeek,
      dayMask: dayMask,
    );
    final index = cycle.indexOf(sessionType);
    return index >= 0 ? index : 0;
  }

  List<TrainingSessionType> scheduleCycleFor({
    required TrainingProgramType programType,
    int frequencyPerWeek = 3,
    List<int>? dayMask,
  }) {
    return TrainingScheduleService().cycleFor(
      programType: programType,
      frequencyPerWeek: frequencyPerWeek,
      dayMask: dayMask,
    );
  }
}
