import '../models/training_program_model.dart';
import 'supabase_service.dart';

class TrainingProgramStoreService {
  static const _defaultFrequencyPerWeek = 3;
  final _client = SupabaseService.client;

  Future<UserTrainingProgramSnapshot> getOrCreateActiveProgram(
    String userId,
  ) async {
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
    );
  }

  Future<UserTrainingProgramSnapshot> updateProgramType({
    required String userId,
    required TrainingProgramType programType,
  }) async {
    final existingProgram = await _fetchActiveProgram(userId);

    final program = existingProgram == null
        ? await _createProgram(userId: userId, programType: programType)
        : await _updateProgram(existingProgram, programType);

    final state = await _upsertProgramState(
      userId: userId,
      programId: program.id,
      programType: programType,
    );

    return UserTrainingProgramSnapshot(program: program, state: state);
  }

  Future<TrainingProgramLogicSnapshot> updateProgramLogic({
    required String userId,
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required RepGoalProfile repGoalProfile,
    required Map<String, dynamic> sessionItemsConfig,
  }) async {
    final existingProgram = await _fetchActiveProgram(userId);
    final variationRules = <String, dynamic>{
      ...?existingProgram?.variationRules,
      'rep_goal_profile': repGoalProfile.dbValue,
      'session_items_v1': sessionItemsConfig,
    };

    final program = existingProgram == null
        ? await _createProgram(
            userId: userId,
            programType: programType,
            variationRules: variationRules,
          )
        : await _updateProgram(
            existingProgram,
            programType,
            variationRules: variationRules,
          );

    final state = await _upsertProgramState(
      userId: userId,
      programId: program.id,
      programType: programType,
      previousProgramType: existingProgram?.programType,
    );

    await _upsertBranchSelections(userId, branchSelections);

    return TrainingProgramLogicSnapshot(
      program: program,
      state: state,
      branchSelections: branchSelections,
      repGoalProfile: repGoalProfile,
    );
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
  }) async {
    final data = await _client
        .from('user_training_programs')
        .insert({
          'user_id': userId,
          'program_type': programType.dbValue,
          'schedule_variant': _defaultScheduleVariant(programType),
          'frequency_per_week': _defaultFrequencyPerWeek,
          'variation_rules': variationRules,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return UserTrainingProgram.fromMap(data);
  }

  Future<UserTrainingProgram> _updateProgram(
      UserTrainingProgram program, TrainingProgramType programType,
      {Map<String, dynamic>? variationRules}) async {
    final data = await _client
        .from('user_training_programs')
        .update({
          'program_type': programType.dbValue,
          'schedule_variant': _defaultScheduleVariant(programType),
          'frequency_per_week': _defaultFrequencyPerWeek,
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
          );
    final nextStepIndex = sameProgramType
        ? existingState.nextStepIndex
        : _stepIndexForSessionType(
            programType: programType,
            sessionType: nextSessionType,
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
  }) {
    final cycle = scheduleCycleFor(programType: programType);
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
  }) {
    final cycle = scheduleCycleFor(programType: programType);
    final index = cycle.indexOf(sessionType);
    return index >= 0 ? index : 0;
  }

  List<TrainingSessionType> scheduleCycleFor({
    required TrainingProgramType programType,
  }) {
    switch (programType) {
      case TrainingProgramType.fullBody:
        return const [
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.rest,
        ];
      case TrainingProgramType.pushPull:
        return const [
          TrainingSessionType.push,
          TrainingSessionType.rest,
          TrainingSessionType.pull,
          TrainingSessionType.rest,
          TrainingSessionType.push,
          TrainingSessionType.pull,
          TrainingSessionType.rest,
        ];
      case TrainingProgramType.upperLower:
        return const [
          TrainingSessionType.upper,
          TrainingSessionType.rest,
          TrainingSessionType.lower,
          TrainingSessionType.rest,
          TrainingSessionType.upper,
          TrainingSessionType.lower,
          TrainingSessionType.rest,
        ];
    }
  }
}
