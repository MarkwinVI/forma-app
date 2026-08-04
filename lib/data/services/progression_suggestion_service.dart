import '../models/progression_suggestion_model.dart';
import 'supabase_service.dart';

/// Storage for the changes a loaded lift is waiting on the user to approve.
///
/// A suggestion is open until it is resolved; one open suggestion per
/// exercise at a time (the database enforces it), so a lift that keeps
/// hitting its target does not stack up a queue of stale proposals — the
/// newest one replaces the last.
class ProgressionSuggestionService {
  final _client = SupabaseService.client;

  /// Everything still waiting on the user, oldest first.
  Future<List<ProgressionSuggestion>> fetchOpen(String userId) async {
    final data = await _client
        .from('user_progression_suggestions')
        .select()
        .eq('user_id', userId)
        .isFilter('resolved_at', null)
        .order('created_at', ascending: true);

    return [
      for (final row in data as List)
        if (ProgressionSuggestion.fromMap(row as Map<String, dynamic>)
            case final suggestion?)
          suggestion,
    ];
  }

  /// Records [suggestions], replacing whatever those exercises were already
  /// proposing — a lift that hits its target twice before the user gets to it
  /// should ask once, for the newer thing. Nothing else is written: the
  /// target only moves on approval.
  Future<void> replaceOpen(
    String userId,
    List<ProgressionSuggestion> suggestions,
  ) async {
    if (suggestions.isEmpty) return;

    await _client
        .from('user_progression_suggestions')
        .delete()
        .eq('user_id', userId)
        .isFilter('resolved_at', null)
        .inFilter(
          'exercise_id',
          [for (final suggestion in suggestions) suggestion.exerciseId],
        );

    await _client.from('user_progression_suggestions').insert(
          [for (final suggestion in suggestions) suggestion.toRow(userId)],
        );
  }

  Future<void> resolve(
    String userId,
    String suggestionId, {
    required bool approved,
  }) async {
    await _client
        .from('user_progression_suggestions')
        .update({
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
          'resolution': approved ? 'approved' : 'dismissed',
        })
        .eq('user_id', userId)
        .eq('id', suggestionId);
  }
}
