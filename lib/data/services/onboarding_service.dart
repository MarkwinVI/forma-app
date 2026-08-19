import '../models/onboarding_profile_model.dart';
import 'analytics_service.dart';
import 'supabase_service.dart';

/// Reads and writes the post-signup onboarding answers
/// (`user_onboarding_profiles`, one row per user).
class OnboardingService {
  final _client = SupabaseService.client;

  /// Memoized per user so the warm-up in main() and the onboarding gate
  /// share one lookup. A cached `false` stays correct until [saveProfile]
  /// flips it, and account deletion issues a new user id, so entries never
  /// go stale.
  static final _completedCache = <String, Future<bool>>{};

  /// Whether this user has finished the onboarding flow. New accounts —
  /// including re-registrations after an account deletion — have no row
  /// and are routed through onboarding.
  Future<bool> hasCompletedOnboarding(String userId) {
    return _completedCache[userId] ??= () {
      final future = _fetchCompletedOnboarding(userId);
      // A failed lookup must not stick, or the gate's Retry would replay
      // the same error for the rest of the session.
      future.then<void>((_) {}, onError: (Object _) {
        if (identical(_completedCache[userId], future)) {
          _completedCache.remove(userId);
        }
      });
      return future;
    }();
  }

  Future<bool> _fetchCompletedOnboarding(String userId) async {
    final row = await _client
        .from('user_onboarding_profiles')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  Future<void> saveProfile(OnboardingProfileModel profile) async {
    await _client
        .from('user_onboarding_profiles')
        .upsert(profile.toMap(), onConflict: 'user_id');
    _completedCache[profile.userId] = Future.value(true);

    AnalyticsService.capture(
      'onboarding_finished',
      properties: {
        'archetype': profile.archetype,
        'radar_balanced': profile.radarBalanced,
        if (profile.radarAngleDeg != null)
          'radar_angle_deg': profile.radarAngleDeg!,
        'age': profile.age,
        if (profile.gender != null) 'gender': profile.gender!,
        if (profile.trainingFrequency != null)
          'training_frequency': profile.trainingFrequency!,
      },
      // The durable traits, kept on the person so any event can be
      // segmented by them.
      personProperties: {
        'archetype': profile.archetype,
        'age': profile.age,
        if (profile.gender != null) 'gender': profile.gender!,
        if (profile.trainingFrequency != null)
          'training_frequency': profile.trainingFrequency!,
      },
    );
  }
}
