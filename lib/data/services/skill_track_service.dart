import '../catalog/skill_category_catalog.dart';
import '../models/skill_track_model.dart';
import '../models/training_program_model.dart';
import 'supabase_service.dart';
import 'training_program_service.dart';

/// Persistence for skills-as-independent-tracks: which skill trees the user
/// runs, on which branch, and whether each is currently included in the
/// program (included = false pauses a track without losing anything).
class SkillTrackService {
  final _client = SupabaseService.client;

  Future<List<SkillTrack>> fetchAll(String userId) async {
    final data = await _client
        .from('user_skill_tracks')
        .select()
        .eq('user_id', userId);

    return (data as List)
        .map((row) => SkillTrack.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the user's skill tracks, seeding them on first use from the
  /// legacy per-lane branch selections plus goal skills — so existing users
  /// keep training exactly what they were training, and goals that had no
  /// lane (e.g. handstand push-ups next to dips) become their own tracks.
  Future<List<SkillTrack>> getOrSeed(
    String userId, {
    Map<TrainingTrack, String> laneSelections = const {},
    List<String> goalSkillIds = const [],
  }) async {
    final existing = await fetchAll(userId);
    if (existing.isNotEmpty) return existing;

    final seeds = seedTracksFrom(
      laneSelections: laneSelections,
      goalSkillIds: goalSkillIds,
    );
    if (seeds.isEmpty) return const [];

    await _client.from('user_skill_tracks').upsert(
      [
        for (final entry in seeds.entries)
          {
            'user_id': userId,
            'skill_category_id': entry.key,
            'branch_id': entry.value,
            'included': true,
            'updated_at': DateTime.now().toIso8601String(),
          },
      ],
      onConflict: 'user_id,skill_category_id',
    );
    return fetchAll(userId);
  }

  /// Pure seed rule: one track per skill category referenced by the lane
  /// selections, plus goal-mapped branches for categories no lane covered.
  /// A category referenced twice keeps the first branch (lane order wins).
  static Map<String, String> seedTracksFrom({
    required Map<TrainingTrack, String> laneSelections,
    required List<String> goalSkillIds,
  }) {
    final seeds = <String, String>{};

    void claim(String branchOptionId) {
      final parts = branchOptionId.split(':');
      if (parts.length != 2) return;
      final category = SkillCategoryCatalog.findById(parts[0]);
      if (category == null) return;
      if (!category.trainingPaths.containsKey(parts[1])) return;
      seeds.putIfAbsent(parts[0], () => parts[1]);
    }

    for (final track in TrainingTrack.values) {
      final selection = laneSelections[track];
      if (selection != null) claim(selection);
    }
    for (final goalId in goalSkillIds) {
      final branchId = TrainingProgramService.goalBranchIds[goalId];
      if (branchId != null) claim(branchId);
    }

    return seeds;
  }

  /// Creates or updates a track. Used when adding a skill tree to the
  /// program and by goal-driven fork resolution.
  Future<void> upsertTrack(
    String userId, {
    required String skillCategoryId,
    required String branchId,
    bool included = true,
  }) async {
    await _client.from('user_skill_tracks').upsert(
      {
        'user_id': userId,
        'skill_category_id': skillCategoryId,
        'branch_id': branchId,
        'included': included,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,skill_category_id',
    );
  }

  /// Pauses (false) or resumes (true) a track. Branch and exercise state are
  /// untouched, so resuming continues exactly where the track left off.
  Future<void> setIncluded(
    String userId,
    String skillCategoryId, {
    required bool included,
  }) async {
    await _client
        .from('user_skill_tracks')
        .update({
          'included': included,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('skill_category_id', skillCategoryId);
  }

  /// Switches a track's active branch. Mastery and per-exercise targets are
  /// global state, so the previous branch's progress is retained and the new
  /// branch resumes from whatever was already earned on it.
  Future<void> setBranch(
    String userId,
    String skillCategoryId, {
    required String branchId,
  }) async {
    await _client
        .from('user_skill_tracks')
        .update({
          'branch_id': branchId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('skill_category_id', skillCategoryId);
  }
}
