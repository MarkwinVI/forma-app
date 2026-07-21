import '../models/progression_event_model.dart';
import 'supabase_service.dart';

/// Best single-set value an exercise reached in the session being saved,
/// used to detect personal bests against earlier history.
class PersonalBestCandidate {
  final String exerciseId;
  final String? trackId;
  final int bestSetValue;

  const PersonalBestCandidate({
    required this.exerciseId,
    required this.bestSetValue,
    this.trackId,
  });
}

class ProgressionEventService {
  final _client = SupabaseService.client;

  /// Whether progression events were already recorded for this session —
  /// the idempotency guard that keeps one workout result from being applied
  /// more than once.
  Future<bool> hasEventsForSession(String userId, String sessionId) async {
    final data = await _client
        .from('progression_events')
        .select('id')
        .eq('user_id', userId)
        .eq('workout_session_id', sessionId)
        .limit(1);

    return (data as List).isNotEmpty;
  }

  Future<void> insertAll(
    String userId,
    String? sessionId,
    List<ProgressionEventInput> events,
  ) async {
    if (events.isEmpty) return;

    await _client.from('progression_events').insert([
      for (final event in events)
        {
          'user_id': userId,
          'workout_session_id': sessionId,
          'exercise_id': event.exerciseId,
          'track_id': event.trackId,
          'kind': event.kind.dbValue,
          'value_from': event.valueFrom,
          'value_to': event.valueTo,
          'target_sets': event.targetSets,
          'related_exercise_id': event.relatedExerciseId,
        },
    ]);
  }

  /// Newest events first.
  Future<List<ProgressionEvent>> fetchRecent(
    String userId, {
    int limit = 50,
  }) async {
    final data = await _client
        .from('progression_events')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return _eventsFromRows(data);
  }

  /// Events the user has not been shown yet, oldest first so the feed reads
  /// in the order things happened.
  Future<List<ProgressionEvent>> fetchUnseen(String userId) async {
    final data = await _client
        .from('progression_events')
        .select()
        .eq('user_id', userId)
        .isFilter('seen_at', null)
        .order('created_at', ascending: true);

    return _eventsFromRows(data);
  }

  Future<List<ProgressionEvent>> fetchForSession(
    String userId,
    String sessionId,
  ) async {
    final data = await _client
        .from('progression_events')
        .select()
        .eq('user_id', userId)
        .eq('workout_session_id', sessionId)
        .order('created_at', ascending: true);

    return _eventsFromRows(data);
  }

  Future<void> markSeen(String userId, List<String> eventIds) async {
    if (eventIds.isEmpty) return;

    await _client
        .from('progression_events')
        .update({'seen_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', userId)
        .inFilter('id', eventIds);
  }

  /// Pure PB rule, separated from persistence so it is testable: a personal
  /// best needs earlier history (no PB on an exercise's first-ever log) and
  /// a strictly higher best single-set value than that history.
  static List<ProgressionEventInput> computePersonalBests({
    required List<PersonalBestCandidate> candidates,
    required Map<String, int> previousBests,
  }) {
    final events = <ProgressionEventInput>[];

    for (final candidate in candidates) {
      final previous = previousBests[candidate.exerciseId] ?? 0;
      if (previous <= 0 || candidate.bestSetValue <= previous) continue;

      events.add(
        ProgressionEventInput(
          exerciseId: candidate.exerciseId,
          trackId: candidate.trackId,
          kind: ProgressionEventKind.personalBest,
          valueFrom: previous,
          valueTo: candidate.bestSetValue,
        ),
      );
    }

    return events;
  }

  List<ProgressionEvent> _eventsFromRows(dynamic data) {
    return (data as List)
        .map((row) => ProgressionEvent.fromMap(row as Map<String, dynamic>))
        .whereType<ProgressionEvent>()
        .toList();
  }
}
