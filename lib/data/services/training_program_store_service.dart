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
  }) async {
    final data = await _client
        .from('user_training_programs')
        .insert({
          'user_id': userId,
          'program_type': programType.dbValue,
          'schedule_variant': _defaultScheduleVariant(programType),
          'frequency_per_week': _defaultFrequencyPerWeek,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return UserTrainingProgram.fromMap(data);
  }

  Future<UserTrainingProgram> _updateProgram(
    UserTrainingProgram program,
    TrainingProgramType programType,
  ) async {
    final data = await _client
        .from('user_training_programs')
        .update({
          'program_type': programType.dbValue,
          'schedule_variant': _defaultScheduleVariant(programType),
          'frequency_per_week': _defaultFrequencyPerWeek,
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
  }) async {
    final existingState = await _fetchProgramState(programId);

    if (existingState == null) {
      return _createProgramState(
        userId: userId,
        programId: programId,
        programType: programType,
      );
    }

    final data = await _client
        .from('user_training_program_state')
        .update({
          'next_step_index': 0,
          'next_session_type': _defaultSessionType(programType).dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', existingState.id)
        .select()
        .single();

    return UserTrainingProgramState.fromMap(data);
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
}
